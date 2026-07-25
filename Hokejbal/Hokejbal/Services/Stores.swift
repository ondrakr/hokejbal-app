import Foundation
import UserNotifications
import UIKit

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var teamIDs: Set<String>
    @Published private(set) var playerIDs: Set<String>
    @Published private(set) var matchIDs: Set<String>
    /// Oblíbené soutěže podle `slug` (napříč ročníky).
    @Published private(set) var competitionSlugs: Set<String>

    private let defaults = UserDefaults.standard
    private let teamsKey = "hb.fav.teams"
    private let playersKey = "hb.fav.players"
    private let matchesKey = "hb.fav.matches"
    private let competitionsKey = "hb.fav.competitions"

    init() {
        // Prázdné výchozí — mock ID (hostivar…) v Supabase neexistují.
        if defaults.object(forKey: teamsKey) == nil {
            teamIDs = []
            playerIDs = []
            matchIDs = []
            competitionSlugs = []
        } else {
            teamIDs = Set(defaults.stringArray(forKey: teamsKey) ?? [])
            playerIDs = Set(defaults.stringArray(forKey: playersKey) ?? [])
            matchIDs = Set(defaults.stringArray(forKey: matchesKey) ?? [])
            competitionSlugs = Set(defaults.stringArray(forKey: competitionsKey) ?? [])
        }
    }

    func isFavorite(team id: String) -> Bool { teamIDs.contains(id) }
    func isFavorite(player id: String) -> Bool { playerIDs.contains(id) }
    func isFavorite(match id: String) -> Bool { matchIDs.contains(id) }
    func isFavorite(competitionSlug slug: String) -> Bool { competitionSlugs.contains(slug) }
    func isFavorite(competition: Competition) -> Bool { competitionSlugs.contains(competition.slug) }

    func toggleTeam(_ id: String) {
        if teamIDs.contains(id) { teamIDs.remove(id) } else { teamIDs.insert(id) }
        persist()
        Task { await syncFavoriteChange(kind: "team", targetId: id, isFavorite: teamIDs.contains(id)) }
    }

    func addTeam(_ id: String) {
        guard !teamIDs.contains(id) else { return }
        teamIDs.insert(id)
        persist()
        Task { await syncFavoriteChange(kind: "team", targetId: id, isFavorite: true) }
    }

    func togglePlayer(_ id: String) {
        if playerIDs.contains(id) { playerIDs.remove(id) } else { playerIDs.insert(id) }
        persist()
        Task { await syncFavoriteChange(kind: "player", targetId: id, isFavorite: playerIDs.contains(id)) }
    }

    func toggleMatch(_ id: String) {
        if matchIDs.contains(id) { matchIDs.remove(id) } else { matchIDs.insert(id) }
        persist()
        Task { await syncFavoriteChange(kind: "match", targetId: id, isFavorite: matchIDs.contains(id)) }
    }

    func toggleCompetition(slug: String) {
        if competitionSlugs.contains(slug) { competitionSlugs.remove(slug) } else { competitionSlugs.insert(slug) }
        persist()
        Task { await syncFavoriteChange(kind: "competition", targetId: slug, isFavorite: competitionSlugs.contains(slug)) }
    }

    func toggleCompetition(_ competition: Competition) {
        toggleCompetition(slug: competition.slug)
    }

    /// Načte oblíbené z DB po přihlášení a sloučí s lokálními.
    func syncFromRemote(using auth: AuthStore) async {
        guard auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let rows = try await auth.authAPI.fetchFavorites(accessToken: token)
            var teams = teamIDs
            var players = playerIDs
            var matches = matchIDs
            var comps = competitionSlugs
            for row in rows {
                switch row.kind {
                case "team": teams.insert(row.targetId)
                case "player": players.insert(row.targetId)
                case "match": matches.insert(row.targetId)
                case "competition": comps.insert(row.targetId)
                default: break
                }
            }
            // Push local-only items up.
            for id in teamIDs where !rows.contains(where: { $0.kind == "team" && $0.targetId == id }) {
                try? await auth.authAPI.upsertFavorite(kind: "team", targetId: id, userId: userId, accessToken: token)
            }
            for id in playerIDs where !rows.contains(where: { $0.kind == "player" && $0.targetId == id }) {
                try? await auth.authAPI.upsertFavorite(kind: "player", targetId: id, userId: userId, accessToken: token)
            }
            for id in matchIDs where !rows.contains(where: { $0.kind == "match" && $0.targetId == id }) {
                try? await auth.authAPI.upsertFavorite(kind: "match", targetId: id, userId: userId, accessToken: token)
            }
            for id in competitionSlugs where !rows.contains(where: { $0.kind == "competition" && $0.targetId == id }) {
                try? await auth.authAPI.upsertFavorite(kind: "competition", targetId: id, userId: userId, accessToken: token)
            }
            teamIDs = teams
            playerIDs = players
            matchIDs = matches
            competitionSlugs = comps
            persist()
        } catch {
            // Soft-fail — lokální oblíbené zůstanou.
        }
    }

    func clearLocalOnLogout() {
        // Po odhlášení necháme lokální cache — uživatel může zůstat guest bez sync.
    }

    private func syncFavoriteChange(kind: String, targetId: String, isFavorite: Bool) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            if isFavorite {
                try await auth.authAPI.upsertFavorite(kind: kind, targetId: targetId, userId: userId, accessToken: token)
            } else {
                try await auth.authAPI.deleteFavorite(kind: kind, targetId: targetId, accessToken: token)
            }
        } catch { /* soft */ }
    }

    private func persist() {
        defaults.set(Array(teamIDs), forKey: teamsKey)
        defaults.set(Array(playerIDs), forKey: playersKey)
        defaults.set(Array(matchIDs), forKey: matchesKey)
        defaults.set(Array(competitionSlugs), forKey: competitionsKey)
    }
}

/// Slabá vazba na AuthStore pro sync z FavoritesStore.
enum AuthAccess {
    @MainActor static weak var store: AuthStore?
}

/// Notifikace na úrovni jednoho zápasu — výchozí zapnuto, lze vypnout celé.
@MainActor
final class MatchAlertsStore: ObservableObject {
    /// Zápasy s vypnutými oznámeními.
    @Published private(set) var mutedMatchIDs: Set<String> = []

    private let defaults = UserDefaults.standard
    private let key = "hb.match.alerts.muted"

    init() {
        mutedMatchIDs = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func isEnabled(matchId: String) -> Bool {
        !mutedMatchIDs.contains(matchId)
    }

    func toggle(matchId: String) {
        var next = mutedMatchIDs
        if next.contains(matchId) {
            next.remove(matchId)
        } else {
            next.insert(matchId)
        }
        mutedMatchIDs = next
        persist()
    }

    private func persist() {
        defaults.set(Array(mutedMatchIDs), forKey: key)
    }
}

/// Soutěže a týmy zobrazené ve slideru Zápasů na Domů.
@MainActor
final class HomeMatchFeedStore: ObservableObject {
    @Published private(set) var competitionSlugs: Set<String>
    @Published private(set) var teamIDs: Set<String>

    private let defaults = UserDefaults.standard
    private let competitionsKey = "hb.home.feed.competitions"
    private let teamsKey = "hb.home.feed.teams"
    private let seededKey = "hb.home.feed.seeded"

    var hasSelection: Bool {
        !competitionSlugs.isEmpty || !teamIDs.isEmpty
    }

    var selectionSummary: String {
        var parts: [String] = []
        if !competitionSlugs.isEmpty {
            parts.append("\(competitionSlugs.count) soutěží")
        }
        if !teamIDs.isEmpty {
            parts.append("\(teamIDs.count) týmů")
        }
        return parts.isEmpty ? "Nic nevybráno" : parts.joined(separator: " · ")
    }

    init() {
        competitionSlugs = Set(defaults.stringArray(forKey: competitionsKey) ?? [])
        teamIDs = Set(defaults.stringArray(forKey: teamsKey) ?? [])
    }

    func includes(match: Match, catalog: CatalogStore) -> Bool {
        guard hasSelection else { return false }
        if teamIDs.contains(match.homeTeamId) || teamIDs.contains(match.awayTeamId) {
            return true
        }
        if let slug = catalog.competitions.first(where: { $0.id == match.competitionId })?.slug,
           competitionSlugs.contains(slug) {
            return true
        }
        return false
    }

    func isCompetitionSelected(_ competition: Competition) -> Bool {
        competitionSlugs.contains(competition.slug)
    }

    func isTeamSelected(_ teamId: String) -> Bool {
        teamIDs.contains(teamId)
    }

    func toggleCompetition(_ competition: Competition) {
        if competitionSlugs.contains(competition.slug) {
            competitionSlugs.remove(competition.slug)
        } else {
            competitionSlugs.insert(competition.slug)
        }
        persist()
    }

    func toggleTeam(_ teamId: String) {
        if teamIDs.contains(teamId) {
            teamIDs.remove(teamId)
        } else {
            teamIDs.insert(teamId)
        }
        persist()
    }

    func selectAllCompetitions(_ competitions: [Competition]) {
        competitionSlugs = Set(competitions.map(\.slug))
        persist()
    }

    func clearCompetitions() {
        competitionSlugs = []
        persist()
    }

    func clearTeams() {
        teamIDs = []
        persist()
    }

    func clearAll() {
        competitionSlugs = []
        teamIDs = []
        persist()
    }

    /// Při první instalaci předvybere Extraligu (nebo první soutěž).
    func seedDefaultsIfNeeded(competitions: [Competition]) {
        guard !defaults.bool(forKey: seededKey) else { return }
        defaults.set(true, forKey: seededKey)
        guard competitionSlugs.isEmpty, teamIDs.isEmpty, !competitions.isEmpty else { return }
        if let extraliga = competitions.first(where: { $0.slug == "extraliga" }) {
            competitionSlugs = [extraliga.slug]
        } else {
            competitionSlugs = [competitions[0].slug]
        }
        persist()
    }

    private func persist() {
        defaults.set(Array(competitionSlugs), forKey: competitionsKey)
        defaults.set(Array(teamIDs), forKey: teamsKey)
    }
}

/// Uživatelské pořadí soutěží (podle `slug`) — platí napříč Zápasy / LIVE / Oblíbené.
@MainActor
final class CompetitionOrderStore: ObservableObject {
    @Published private(set) var orderedSlugs: [String]

    private let defaults = UserDefaults.standard
    private let key = "hb.competition.order"

    init() {
        orderedSlugs = defaults.stringArray(forKey: key) ?? []
    }

    /// Doplní nové soutěže na konec, odstraní neplatné slugy.
    func sync(with competitions: [Competition]) {
        let available = competitions.map(\.slug)
        var next = orderedSlugs.filter { available.contains($0) }
        for slug in available where !next.contains(slug) {
            next.append(slug)
        }
        guard next != orderedSlugs else { return }
        orderedSlugs = next
        persist()
    }

    func setOrder(_ slugs: [String]) {
        orderedSlugs = slugs
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        var next = orderedSlugs
        next.move(fromOffsets: source, toOffset: destination)
        orderedSlugs = next
        persist()
    }

    func sortedCompetitions(_ competitions: [Competition]) -> [Competition] {
        competitions.sorted { a, b in
            let ia = orderedSlugs.firstIndex(of: a.slug) ?? Int.max
            let ib = orderedSlugs.firstIndex(of: b.slug) ?? Int.max
            if ia != ib { return ia < ib }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func sortedCompetitionIds(_ ids: some Collection<String>, catalog: CatalogStore) -> [String] {
        ids.sorted { a, b in
            let ia = orderIndex(competitionId: a, catalog: catalog)
            let ib = orderIndex(competitionId: b, catalog: catalog)
            if ia != ib { return ia < ib }
            return a < b
        }
    }

    func groupMatchesByCompetition(_ matches: [Match], catalog: CatalogStore) -> [(Competition?, [Match])] {
        let map = Dictionary(grouping: matches) { $0.competitionId }
        return sortedCompetitionIds(map.keys, catalog: catalog).map { id in
            (catalog.competitions.first { $0.id == id }, (map[id] ?? []).sorted { $0.scheduledAt < $1.scheduledAt })
        }
    }

    private func orderIndex(competitionId: String, catalog: CatalogStore) -> Int {
        guard let slug = catalog.competitions.first(where: { $0.id == competitionId })?.slug else {
            return Int.max
        }
        return orderedSlugs.firstIndex(of: slug) ?? Int.max
    }

    private func persist() {
        defaults.set(orderedSlugs, forKey: key)
    }
}

@MainActor
final class NotificationSettingsStore: ObservableObject {
    @Published var goalsEnabled: Bool {
        didSet { defaults.set(goalsEnabled, forKey: "hb.notif.goals") }
    }
    @Published var matchStartEnabled: Bool {
        didSet { defaults.set(matchStartEnabled, forKey: "hb.notif.start") }
    }
    @Published var finalScoreEnabled: Bool {
        didSet { defaults.set(finalScoreEnabled, forKey: "hb.notif.final") }
    }
    @Published var newsEnabled: Bool {
        didSet { defaults.set(newsEnabled, forKey: "hb.notif.news") }
    }
    @Published var onlyFavorites: Bool {
        didSet { defaults.set(onlyFavorites, forKey: "hb.notif.favoritesOnly") }
    }
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let defaults = UserDefaults.standard

    var isSystemAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    var systemStatusTitle: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "Povoleno"
        case .denied: return "Zakázáno"
        case .notDetermined: return "Nenastaveno"
        @unknown default: return "—"
        }
    }

    var systemStatusDetail: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Systémová upozornění jsou aktivní. In-app bannery fungují i bez nich."
        case .denied:
            return "Notifikace jsou v iOS vypnuté. Zapni je v Nastavení systému."
        case .notDetermined:
            return "Pro banner nahoře v appce stačí nastavení níže. Pro upozornění mimo appku povol systémová oprávnění."
        @unknown default:
            return ""
        }
    }

    var activeLiveTypesSummary: String {
        var parts: [String] = []
        if goalsEnabled { parts.append("Góly") }
        if matchStartEnabled { parts.append("Začátky") }
        if finalScoreEnabled { parts.append("Konce") }
        if parts.isEmpty { return "Vypnuto" }
        return parts.joined(separator: " · ")
    }

    init() {
        goalsEnabled = defaults.object(forKey: "hb.notif.goals") as? Bool ?? true
        matchStartEnabled = defaults.object(forKey: "hb.notif.start") as? Bool ?? true
        finalScoreEnabled = defaults.object(forKey: "hb.notif.final") as? Bool ?? true
        newsEnabled = defaults.object(forKey: "hb.notif.news") as? Bool ?? false
        onlyFavorites = defaults.object(forKey: "hb.notif.favoritesOnly") as? Bool ?? true
    }

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorization()
            return granted
        } catch {
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Lokální demo notifikace (při napojení API nahradí push z backendu).
    func scheduleDemoGoalNotification(home: String, away: String, score: String, matchId: String? = nil) {
        guard goalsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "GÓL!"
        content.body = "\(home) – \(away) \(score)"
        content.sound = .default
        if let matchId {
            content.userInfo = ["matchId": matchId, "kind": "goal"]
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDemoFinalNotification(home: String, away: String, score: String, matchId: String? = nil) {
        guard finalScoreEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "KONEC"
        content.body = "\(home) – \(away) \(score)"
        content.sound = .default
        if let matchId {
            content.userInfo = ["matchId": matchId, "kind": "final"]
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Má se pro daný zápas posílat upozornění (gól / konec)?
    func shouldNotify(
        match: Match,
        matchAlerts: MatchAlertsStore,
        favorites: FavoritesStore
    ) -> Bool {
        let favMatch = favorites.isFavorite(match: match.id)
        let favTeam = favorites.isFavorite(team: match.homeTeamId)
            || favorites.isFavorite(team: match.awayTeamId)
        let matchAlertOn = matchAlerts.isEnabled(matchId: match.id)

        // Ztlumený zápas (zvonek) → nikdy neposílat.
        guard matchAlertOn else { return false }
        if onlyFavorites {
            return favTeam || favMatch
        }
        return true
    }
}

/// App-wide katalog týmů/hráčů pro rychlé lookupy v UI.
@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var teamsById: [String: Team] = [:]
    @Published private(set) var playersById: [String: Player] = [:]
    @Published private(set) var competitions: [Competition] = []
    @Published private(set) var isLoaded = false
    @Published private(set) var arePlayersLoaded = false

    private var playersLoadTask: Task<Void, Never>?

    /// Načte soutěže + týmy pro zvolenou sezónu.
    func load(using api: any HokejbalAPI, seasonId: String?) async {
        do {
            async let comps = api.competitions(seasonId: seasonId)
            let competitionList = try await comps
            competitions = competitionList

            // Paralelní načtení týmů ze všech soutěží (místo N+1 sekvenčně).
            var teams: [Team] = []
            await withTaskGroup(of: [Team].self) { group in
                for comp in competitionList {
                    group.addTask {
                        (try? await api.teams(competitionId: comp.id)) ?? []
                    }
                }
                for await batch in group {
                    teams.append(contentsOf: batch)
                }
            }
            var unique: [String: Team] = [:]
            for t in teams { unique[t.id] = t }
            teamsById = unique
            isLoaded = true
            arePlayersLoaded = false
            playersById = [:]
        } catch {
            // I při chybě uvolníme splash — UI ukáže prázdné stavy.
            isLoaded = true
        }
    }

    func loadPlayersIfNeeded(using api: any HokejbalAPI, seasonId: String?) async {
        guard !arePlayersLoaded else { return }
        if let playersLoadTask {
            await playersLoadTask.value
            return
        }
        let task = Task { @MainActor in
            do {
                let p = try await api.players(teamId: nil, seasonId: seasonId, competitionId: nil)
                // Odolné vůči duplicitním id (data mohou vracet kolize slugů) — nepadáme.
                playersById = Dictionary(p.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                arePlayersLoaded = true
            } catch {
                // Necháme arePlayersLoaded = false → další pokus.
            }
        }
        playersLoadTask = task
        await task.value
        playersLoadTask = nil
    }

    func team(_ id: String) -> Team? { teamsById[id] }
    func player(_ id: String) -> Player? { playersById[id] }

    func upsertTeam(_ team: Team) {
        var copy = teamsById
        copy[team.id] = team
        teamsById = copy
    }
}

/// Globální výběr ročníku (2024/25, 2025/26…).
@MainActor
final class SeasonStore: ObservableObject {
    @Published private(set) var seasons: [Season] = []
    @Published var selectedSeasonId: String? {
        didSet {
            if let selectedSeasonId {
                UserDefaults.standard.set(selectedSeasonId, forKey: "hb.selectedSeason")
            }
        }
    }

    var selectedSeason: Season? {
        seasons.first { $0.id == selectedSeasonId }
    }

    var selectedLabel: String {
        selectedSeason?.label ?? "Sezóna"
    }

    func load(using api: any HokejbalAPI) async {
        do {
            let list = try await api.seasons()
            seasons = list.sorted { $0.sortOrder > $1.sortOrder }
            if selectedSeasonId == nil || !seasons.contains(where: { $0.id == selectedSeasonId }) {
                let saved = UserDefaults.standard.string(forKey: "hb.selectedSeason")
                if let saved, seasons.contains(where: { $0.id == saved }) {
                    selectedSeasonId = saved
                } else {
                    selectedSeasonId = seasons.first(where: \.isCurrent)?.id ?? seasons.first?.id
                }
            }
        } catch {
            seasons = []
        }
    }
}

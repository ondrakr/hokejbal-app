import Foundation
import UserNotifications

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
        teamIDs = Set(defaults.stringArray(forKey: teamsKey) ?? ["hostivar", "letohrad"])
        playerIDs = Set(defaults.stringArray(forKey: playersKey) ?? ["cejka"])
        matchIDs = Set(defaults.stringArray(forKey: matchesKey) ?? [])
        competitionSlugs = Set(defaults.stringArray(forKey: competitionsKey) ?? [])
    }

    func isFavorite(team id: String) -> Bool { teamIDs.contains(id) }
    func isFavorite(player id: String) -> Bool { playerIDs.contains(id) }
    func isFavorite(match id: String) -> Bool { matchIDs.contains(id) }
    func isFavorite(competitionSlug slug: String) -> Bool { competitionSlugs.contains(slug) }
    func isFavorite(competition: Competition) -> Bool { competitionSlugs.contains(competition.slug) }

    func toggleTeam(_ id: String) {
        if teamIDs.contains(id) { teamIDs.remove(id) } else { teamIDs.insert(id) }
        persist()
    }

    func togglePlayer(_ id: String) {
        if playerIDs.contains(id) { playerIDs.remove(id) } else { playerIDs.insert(id) }
        persist()
    }

    func toggleMatch(_ id: String) {
        if matchIDs.contains(id) { matchIDs.remove(id) } else { matchIDs.insert(id) }
        persist()
    }

    func toggleCompetition(slug: String) {
        if competitionSlugs.contains(slug) { competitionSlugs.remove(slug) } else { competitionSlugs.insert(slug) }
        persist()
    }

    func toggleCompetition(_ competition: Competition) {
        toggleCompetition(slug: competition.slug)
    }

    private func persist() {
        defaults.set(Array(teamIDs), forKey: teamsKey)
        defaults.set(Array(playerIDs), forKey: playersKey)
        defaults.set(Array(matchIDs), forKey: matchesKey)
        defaults.set(Array(competitionSlugs), forKey: competitionsKey)
    }
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

    /// Lokální demo notifikace (při napojení API nahradí push z backendu).
    func scheduleDemoGoalNotification(home: String, away: String, score: String) {
        guard goalsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "GÓL!"
        content.body = "\(home) – \(away) \(score)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
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

            // Týmy ze všech soutěží aktuální sezóny (dedupe podle club id).
            var teams: [Team] = []
            for comp in competitionList {
                let t = try await api.teams(competitionId: comp.id)
                teams.append(contentsOf: t)
            }
            var unique: [String: Team] = [:]
            for t in teams { unique[t.id] = t }
            teamsById = unique
            isLoaded = true
            arePlayersLoaded = false
            playersById = [:]
        } catch {
            isLoaded = false
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
                playersById = Dictionary(uniqueKeysWithValues: p.map { ($0.id, $0) })
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

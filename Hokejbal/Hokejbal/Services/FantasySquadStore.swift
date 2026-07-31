import Foundation
import SwiftUI

// MARK: - Slots (Extraliga: 1 B + 2 O + 3 Ú)

enum FantasySlot: String, CaseIterable, Identifiable, Hashable, Sendable {
    case goalie
    case defense1
    case defense2
    case forward1
    case forward2
    case forward3

    var id: String { rawValue }

    var position: PlayerPosition {
        switch self {
        case .goalie: return .goalie
        case .defense1, .defense2: return .defenseman
        case .forward1, .forward2, .forward3: return .forward
        }
    }

    var title: String {
        switch self {
        case .goalie: return "Brankář"
        case .defense1: return "Obránce 1"
        case .defense2: return "Obránce 2"
        case .forward1: return "Útočník 1"
        case .forward2: return "Útočník 2"
        case .forward3: return "Útočník 3"
        }
    }

    var shortTitle: String {
        switch self {
        case .goalie: return "B"
        case .defense1, .defense2: return "O"
        case .forward1, .forward2, .forward3: return "Ú"
        }
    }
}

enum FantasyCardTier: String, Sendable {
    case bronze
    case silver
    case gold
    case elite

    var gradient: [Color] {
        switch self {
        case .bronze:
            return [Color(red: 0.55, green: 0.32, blue: 0.16), Color(red: 0.35, green: 0.18, blue: 0.08)]
        case .silver:
            return [Color(red: 0.72, green: 0.74, blue: 0.78), Color(red: 0.42, green: 0.45, blue: 0.50)]
        case .gold:
            return [Color(red: 0.95, green: 0.78, blue: 0.28), Color(red: 0.72, green: 0.48, blue: 0.08)]
        case .elite:
            return [Color(red: 0.18, green: 0.14, blue: 0.28), Color(red: 0.55, green: 0.35, blue: 0.08)]
        }
    }

    var accent: Color {
        switch self {
        case .bronze: return Color(red: 0.90, green: 0.70, blue: 0.45)
        case .silver: return Color.white
        case .gold: return Color(red: 1.0, green: 0.92, blue: 0.55)
        case .elite: return Color(red: 1.0, green: 0.84, blue: 0.30)
        }
    }

    var label: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .elite: return "Elite"
        }
    }
}

// MARK: - Deadline / kola (sobota 10:00 Praha)

enum FantasyDeadline {
    static let prague = TimeZone(identifier: "Europe/Prague") ?? .current
    /// První sobota sezóny Fantasy (deadline GW1).
    static let seasonAnchor = date(year: 2025, month: 9, day: 6, hour: 10, minute: 0)

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = prague
        return cal
    }

    static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return calendar.date(from: comps) ?? Date()
    }

    /// Nejbližší sobota 10:00 (pokud je dnes sobota před 10:00 → dnes, jinak příští sobota).
    static func upcomingDeadline(from now: Date = Date()) -> Date {
        let cal = calendar
        let weekday = cal.component(.weekday, from: now) // 1 = neděle … 7 = sobota
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let startOfToday = cal.startOfDay(for: now)
        guard var saturday = cal.date(byAdding: .day, value: daysUntilSaturday, to: startOfDay(of: now) ?? startOfToday) else {
            return now
        }
        saturday = cal.date(bySettingHour: 10, minute: 0, second: 0, of: saturday) ?? saturday

        if daysUntilSaturday == 0, now >= saturday {
            // Sobota po 10:00 → další sobota
            saturday = cal.date(byAdding: .day, value: 7, to: saturday) ?? saturday
        }
        return saturday
    }

    /// Deadline aktuálně hraného / právě uzamčeného kola (sobota 10:00 tohoto týdne, pokud už prošla).
    static func activeDeadline(from now: Date = Date()) -> Date {
        let next = upcomingDeadline(from: now)
        return calendar.date(byAdding: .day, value: -7, to: next) ?? next
    }

    /// Číslo kola od anchor soboty (min. 1).
    static func gameweek(from now: Date = Date()) -> Int {
        let deadline = upcomingDeadline(from: now)
        let seconds = deadline.timeIntervalSince(seasonAnchor)
        let weeks = Int(floor(seconds / (7 * 24 * 3600)))
        return max(1, weeks + 1)
    }

    /// Sestava pro `gameweek` se dá měnit, dokud `now < deadline` toho kola.
    static func deadline(forGameweek gw: Int) -> Date {
        calendar.date(byAdding: .day, value: (gw - 1) * 7, to: seasonAnchor) ?? seasonAnchor
    }

    static func isEditable(gameweek: Int, at now: Date = Date()) -> Bool {
        now < deadline(forGameweek: gameweek)
    }

    static func countdown(to deadline: Date, from now: Date = Date()) -> String {
        let p = countdownParts(to: deadline, from: now)
        if p.days > 0 { return "\(p.days)d \(p.hours)h" }
        if p.hours > 0 { return "\(p.hours)h \(p.minutes)m" }
        return "\(p.minutes)m \(p.seconds)s"
    }

    static func countdownParts(to deadline: Date, from now: Date = Date()) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = max(0, Int(deadline.timeIntervalSince(now)))
        let days = interval / 86_400
        let hours = (interval % 86_400) / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        return (days, hours, minutes, seconds)
    }

    private static func startOfDay(of date: Date) -> Date? {
        calendar.startOfDay(for: date)
    }
}

// MARK: - Rules

enum FantasyRules {
    static let competitionSlug = "extraliga"
    static let budgetCredits = 100
    static let maxFromSameClub = 2
    static let squadSize = FantasySlot.allCases.count
    static let startingWallet = 0

    static func isExtraligaPlayer(_ player: Player, teamsById: [String: Team], competitionsById: [String: Competition]) -> Bool {
        if let competitionId = player.competitionId,
           let competition = competitionsById[competitionId],
           competition.slug == competitionSlug {
            return true
        }
        guard let team = teamsById[player.teamId] else { return false }
        guard let competition = competitionsById[team.competitionId] else {
            return team.competitionId.contains("extraliga")
        }
        return competition.slug == competitionSlug
    }

    /// Snapshot FIFA parametrů podle playerId (plní `FantasyAttributesStore` na main threadu).
    /// Když hráč parametry má, OVR se počítá z nich; jinak fallback ze statistik.
    static var attributesByPlayerId: [String: PlayerAttributes] = [:]

    /// FIFA-like OVR. Z parametrů (až 99), jinak fallback ze sezónních statistik (55…94).
    static func rating(for player: Player) -> Int {
        if let attrs = attributesByPlayerId[player.id],
           let ovr = attrs.computedOverall(position: player.position) {
            return ovr
        }
        return statRating(for: player)
    }

    /// OVR jen ze sezónních statistik (fallback, když nejsou parametry).
    static func statRating(for player: Player) -> Int {
        let value: Double
        switch player.position {
        case .goalie:
            let save = player.savePercentage ?? 88
            let gaa = player.goalsAgainstAverage ?? 3.2
            value = 62 + (save - 86) * 2.2 + Double(player.games) * 0.35 - (gaa - 2.5) * 3
        case .defenseman:
            let ppg = player.games > 0 ? Double(player.points) / Double(player.games) : 0
            value = 58 + ppg * 18 + Double(player.goals) * 0.8 + Double(player.games) * 0.25
        case .forward:
            let ppg = player.games > 0 ? Double(player.points) / Double(player.games) : 0
            value = 58 + ppg * 20 + Double(player.goals) * 1.1 + Double(player.games) * 0.2
        }
        return Int(min(94, max(55, value.rounded())))
    }

    static func tier(for rating: Int) -> FantasyCardTier {
        switch rating {
        case ..<65: return .bronze
        case ..<75: return .silver
        case ..<85: return .gold
        default: return .elite
        }
    }

    /// Cena v kreditech podle ratingu (4…15). Čím vyšší OVR, tím dražší.
    static func priceCredits(for player: Player) -> Int {
        let r = rating(for: player)
        // 55 → 4, 94 → 15
        let raw = 4.0 + Double(r - 55) * (11.0 / 39.0)
        return Int(min(15, max(4, raw.rounded())))
    }

    /// Kompatibilita se starším UI (Double).
    static func price(for player: Player) -> Double {
        Double(priceCredits(for: player))
    }

    static func fantasyPoints(for player: Player) -> Int {
        switch player.position {
        case .goalie:
            let saveBonus = Int(((player.savePercentage ?? 88) - 85) * 2)
            return max(0, player.games * 2 + saveBonus - player.penaltyMinutes / 4)
        case .defenseman, .forward:
            return max(0, player.goals * 3 + player.assists * 2 + player.games / 2 - player.penaltyMinutes / 5)
        }
    }

    static func roundRewardCredits(squadPoints: Int) -> Int {
        10 + min(40, squadPoints / 3)
    }

    static func nextFixture(for teamId: String, in matches: [Match], after date: Date = Date()) -> Match? {
        matches
            .filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
            .filter { $0.status == .scheduled || $0.status == .live }
            .filter { $0.scheduledAt >= date.addingTimeInterval(-3 * 3600) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    /// Zápasy patřící do daného kola (víkend po deadlinu sobota 10:00).
    static func matches(inGameweek gameweek: Int, from matches: [Match]) -> [Match] {
        let start = FantasyDeadline.deadline(forGameweek: gameweek)
        let end = FantasyDeadline.deadline(forGameweek: gameweek + 1)
        return matches.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
    }

    /// Body hráče za KOLO z reálného výkonu (odehrané zápasy kola).
    /// Hráči do pole: gól 3 · asistence 2. Brankáři: výhra 3 · čisté konto 5 · jinak dle inkasovaných.
    static func weeklyFantasyPoints(for player: Player, in gameweekMatches: [Match]) -> Int {
        let played = gameweekMatches.filter {
            $0.isFinished && ($0.homeTeamId == player.teamId || $0.awayTeamId == player.teamId)
        }
        guard !played.isEmpty else { return 0 }

        switch player.position {
        case .forward, .defenseman:
            var pts = 0
            for match in played {
                for event in match.events where event.kind == .goal {
                    if event.playerId == player.id { pts += 3 }
                    if event.assistIds.contains(player.id) { pts += 2 }
                }
            }
            return pts
        case .goalie:
            // Bez rozpisu brankářů heuristika podle výsledku týmu (drž 1 brankáře v sestavě).
            var pts = 0
            for match in played {
                let isHome = match.homeTeamId == player.teamId
                let goalsFor = isHome ? match.homeScore : match.awayScore
                let goalsAgainst = isHome ? match.awayScore : match.homeScore
                if goalsFor > goalsAgainst { pts += 3 }
                pts += goalsAgainst == 0 ? 5 : max(0, 4 - goalsAgainst)
            }
            return pts
        }
    }
}

// MARK: - Store

@MainActor
final class FantasySquadStore: ObservableObject {
    @Published var teamName: String {
        didSet { defaults.set(teamName, forKey: Keys.teamName) }
    }

    /// Sestavy po kolech: gameweek → slot → playerId
    @Published private(set) var lineupsByGameweek: [Int: [FantasySlot: String]] {
        didSet { persistLineups() }
    }

    @Published private(set) var activeGameweek: Int {
        didSet { defaults.set(activeGameweek, forKey: Keys.activeGW) }
    }

    @Published private(set) var wallet: Int {
        didSet { defaults.set(wallet, forKey: Keys.wallet) }
    }

    @Published private(set) var seasonPoints: Int {
        didSet { defaults.set(seasonPoints, forKey: Keys.seasonPoints) }
    }

    @Published private(set) var scoredGameweeks: Set<Int> {
        didSet {
            defaults.set(Array(scoredGameweeks), forKey: Keys.scored)
        }
    }

    /// Prohlížené kolo (šipky v hubu) — editace jen když == activeGameweek a není lock.
    @Published var viewingGameweek: Int = 1

    @Published private(set) var freeTransfers: Int {
        didSet { defaults.set(freeTransfers, forKey: Keys.freeTransfers) }
    }

    @Published private(set) var savedLineupsByGameweek: [Int: [FantasySlot: String]] {
        didSet { persistSaved() }
    }

    @Published var showPriceOnPitch: Bool {
        didSet { defaults.set(showPriceOnPitch, forKey: Keys.showPrice) }
    }
    @Published var showPointsOnPitch: Bool {
        didSet { defaults.set(showPointsOnPitch, forKey: Keys.showPoints) }
    }
    @Published var showOpponentOnPitch: Bool {
        didSet { defaults.set(showOpponentOnPitch, forKey: Keys.showOpponent) }
    }

    @Published private(set) var lastSaveMessage: String?

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let teamName = "hb.fantasy.v3.teamName"
        static let lineups = "hb.fantasy.v3.lineups"
        static let saved = "hb.fantasy.v3.saved"
        static let activeGW = "hb.fantasy.v3.activeGW"
        static let wallet = "hb.fantasy.v3.wallet"
        static let seasonPoints = "hb.fantasy.v3.points"
        static let scored = "hb.fantasy.v3.scored"
        static let freeTransfers = "hb.fantasy.v3.ft"
        static let showPrice = "hb.fantasy.v3.ui.price"
        static let showPoints = "hb.fantasy.v3.ui.points"
        static let showOpponent = "hb.fantasy.v3.ui.opp"
        static let legacyV2Slots = "hb.fantasy.v2.slots"
        static let legacyV1Slots = "hb.fantasy.slots"
    }

    init() {
        let defaults = UserDefaults.standard

        teamName = defaults.string(forKey: Keys.teamName)
            ?? defaults.string(forKey: "hb.fantasy.v2.teamName")
            ?? defaults.string(forKey: "hb.fantasy.teamName")
            ?? "Můj Fantasy tým"

        if defaults.object(forKey: Keys.wallet) != nil {
            wallet = defaults.integer(forKey: Keys.wallet)
        } else if defaults.object(forKey: "hb.fantasy.v2.wallet") != nil {
            wallet = defaults.integer(forKey: "hb.fantasy.v2.wallet")
        } else {
            wallet = FantasyRules.startingWallet
        }

        let v3Points = defaults.integer(forKey: Keys.seasonPoints)
        seasonPoints = v3Points != 0 ? v3Points : defaults.integer(forKey: "hb.fantasy.v2.points")

        let scoredRaw = defaults.array(forKey: Keys.scored) as? [Int] ?? []
        scoredGameweeks = Set(scoredRaw)

        let computedGW = FantasyDeadline.gameweek()
        if defaults.object(forKey: Keys.activeGW) != nil {
            activeGameweek = max(1, defaults.integer(forKey: Keys.activeGW))
        } else {
            activeGameweek = computedGW
        }

        let loadedLineups = Self.loadLineups(from: defaults)
        let loadedSaved = Self.loadLineups(from: defaults, key: Keys.saved)
        lineupsByGameweek = loadedLineups
        savedLineupsByGameweek = loadedSaved.isEmpty ? loadedLineups : loadedSaved

        if defaults.object(forKey: Keys.freeTransfers) != nil {
            freeTransfers = defaults.integer(forKey: Keys.freeTransfers)
        } else {
            freeTransfers = 99 // neomezené do prvního deadlinu sezóny
        }

        showPriceOnPitch = defaults.object(forKey: Keys.showPrice) as? Bool ?? false
        showPointsOnPitch = defaults.object(forKey: Keys.showPoints) as? Bool ?? false
        showOpponentOnPitch = defaults.object(forKey: Keys.showOpponent) as? Bool ?? true
        lastSaveMessage = nil
        viewingGameweek = activeGameweek

        migrateLegacyIfNeeded()
        syncGameweekIfNeeded()
        viewingGameweek = activeGameweek
    }

    // MARK: Computed for active / viewing GW

    var deadline: Date { FantasyDeadline.deadline(forGameweek: activeGameweek) }
    var viewingDeadline: Date { FantasyDeadline.deadline(forGameweek: viewingGameweek) }
    var isLocked: Bool { !FantasyDeadline.isEditable(gameweek: activeGameweek) }
    var isViewingEditable: Bool {
        viewingGameweek == activeGameweek && !isLocked
    }
    var countdownText: String { FantasyDeadline.countdown(to: deadline) }
    var countdownParts: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        FantasyDeadline.countdownParts(to: deadline)
    }

    var slotPlayerIds: [FantasySlot: String] {
        lineupsByGameweek[viewingGameweek] ?? lineupsByGameweek[activeGameweek] ?? [:]
    }

    var filledCount: Int { slotPlayerIds.count }
    var isComplete: Bool { filledCount == FantasyRules.squadSize }
    var selectedPlayerIds: Set<String> { Set(slotPlayerIds.values) }

    var hasUnsavedChanges: Bool {
        let draft = lineupsByGameweek[activeGameweek] ?? [:]
        let saved = savedLineupsByGameweek[activeGameweek] ?? [:]
        return draft != saved
    }

    var transfersLabel: String {
        if freeTransfers >= 99 { return "∞" }
        return "\(freeTransfers)"
    }

    /// Orientační pořadí z bodů (lokální demo).
    var overallRank: Int {
        max(1, 12_000 - seasonPoints * 17)
    }

    var roundRank: Int {
        max(1, 8_500 - squadPoints(playersById: [:]) * 11)
    }

    func playerId(for slot: FantasySlot) -> String? { slotPlayerIds[slot] }

    func slotContaining(playerId: String) -> FantasySlot? {
        slotPlayerIds.first { $0.value == playerId }?.key
    }

    func spentCredits(playersById: [String: Player]) -> Int {
        slotPlayerIds.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.priceCredits(for: $1) }
    }

    func remainingBudget(playersById: [String: Player]) -> Int {
        FantasyRules.budgetCredits - spentCredits(playersById: playersById)
    }

    /// Kompatibilita
    func spent(playersById: [String: Player]) -> Double {
        Double(spentCredits(playersById: playersById))
    }

    func squadPoints(playersById: [String: Player]) -> Int {
        slotPlayerIds.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.fantasyPoints(for: $1) }
    }

    func shiftViewingGameweek(by delta: Int) {
        viewingGameweek = max(1, viewingGameweek + delta)
    }

    /// Reálný žebříček fantasy ze serveru (fallback: lokální demo v UI).
    @Published private(set) var remoteLeaderboard: [FantasyLeaderRow] = []

    /// Uloží draft aktivního kola (jako „ULOŽIT SESTAVU“). Po přihlášení pushne na server.
    @discardableResult
    func saveLineup() -> String? {
        guard !isLocked else { return "Deadline prošlo — sestavu už nelze uložit." }
        guard isComplete else { return "Doplň celou sestavu (1B · 2O · 3Ú)." }
        var saved = savedLineupsByGameweek
        saved[activeGameweek] = lineupsByGameweek[activeGameweek] ?? [:]
        savedLineupsByGameweek = saved
        lastSaveMessage = "Sestava GW \(activeGameweek) uložena"
        let gw = activeGameweek
        Task { await pushSquad(gameweek: gw) }
        return nil
    }

    /// Posune aktivní kolo podle kalendáře a připraví draft (bez bodování).
    /// Uzavřená kola vyhodnocuje `scorePendingGameweeks` (potřebuje odehrané zápasy).
    func syncGameweekIfNeeded(now: Date = Date()) {
        let gw = FantasyDeadline.gameweek(from: now)

        if gw > activeGameweek {
            let old = activeGameweek
            if lineupsByGameweek[gw] == nil {
                var copy = lineupsByGameweek
                copy[gw] = savedLineupsByGameweek[old] ?? lineupsByGameweek[old] ?? [:]
                lineupsByGameweek = copy
            }
            activeGameweek = gw
            viewingGameweek = gw
            freeTransfers = min(2, freeTransfers + 1)
            if freeTransfers < 1 { freeTransfers = 1 }
        } else if lineupsByGameweek[gw] == nil, let previous = lineupsByGameweek[gw - 1] {
            var copy = lineupsByGameweek
            copy[gw] = previous
            lineupsByGameweek = copy
        } else if lineupsByGameweek[gw] == nil {
            var copy = lineupsByGameweek
            copy[gw] = [:]
            lineupsByGameweek = copy
        }

        if viewingGameweek < 1 { viewingGameweek = activeGameweek }
    }

    /// Vyhodnotí uzavřená kola z reálného víkendového výkonu. Vrací přírůstek bodů (0 = nic nového).
    @discardableResult
    func scorePendingGameweeks(playersById: [String: Player], matches allMatches: [Match]) -> Int {
        guard !allMatches.isEmpty, activeGameweek > 1 else { return 0 }
        var gained = 0
        for gw in 1..<activeGameweek where !scoredGameweeks.contains(gw) {
            let slots = savedLineupsByGameweek[gw] ?? lineupsByGameweek[gw] ?? [:]
            guard slots.count == FantasyRules.squadSize else { continue }
            let gwMatches = FantasyRules.matches(inGameweek: gw, from: allMatches)
            guard gwMatches.contains(where: { $0.isFinished }) else { continue }
            let points = slots.values
                .compactMap { playersById[$0] }
                .reduce(0) { $0 + FantasyRules.weeklyFantasyPoints(for: $1, in: gwMatches) }
            let credits = FantasyRules.roundRewardCredits(squadPoints: points)
            seasonPoints += points
            wallet += credits
            scoredGameweeks.insert(gw)
            gained += points
            Task { await pushScore(gameweek: gw, points: points, credits: credits) }
        }
        return gained
    }

    // MARK: - Server sync (Supabase)

    /// Po přihlášení natáhne sestavy + skóre ze serveru (server je zdroj pravdy).
    func loadRemote() async {
        guard !FantasyMock.enabled else { return }
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let squads = try await auth.authAPI.fetchFantasySquads(userId: userId, accessToken: token)
            let scores = try await auth.authAPI.fetchFantasyScores(userId: userId, accessToken: token)
            applyRemote(squads: squads, scores: scores)
        } catch { /* soft */ }
    }

    /// Reálný žebříček (veřejný, i pro nepřihlášené).
    func loadLeaderboard() async {
        guard !FantasyMock.enabled else { return }
        guard let api = AuthAccess.store?.authAPI else { return }
        do { remoteLeaderboard = try await api.fetchFantasyLeaderboard() }
        catch { /* soft */ }
    }

    private func applyRemote(squads: [FantasySquadRow], scores: [FantasyScoreRow]) {
        if !squads.isEmpty {
            var lineups = lineupsByGameweek
            var saved = savedLineupsByGameweek
            for row in squads {
                var map: [FantasySlot: String] = [:]
                for slot in FantasySlot.allCases where row.slots[slot.rawValue] != nil {
                    map[slot] = row.slots[slot.rawValue]
                }
                lineups[row.gameweek] = map
                saved[row.gameweek] = map
                if row.gameweek == activeGameweek, !row.teamName.isEmpty {
                    teamName = row.teamName
                }
            }
            lineupsByGameweek = lineups
            savedLineupsByGameweek = saved
        }
        if !scores.isEmpty {
            seasonPoints = scores.reduce(0) { $0 + $1.points }
            wallet = scores.reduce(FantasyRules.startingWallet) { $0 + $1.credits }
            scoredGameweeks = Set(scores.map(\.gameweek))
        }
    }

    private func pushSquad(gameweek: Int) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        let slots = (savedLineupsByGameweek[gameweek] ?? [:])
            .reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertFantasySquad(
                userId: userId, gameweek: gameweek, teamName: teamName, slots: slots, accessToken: token
            )
        } catch { /* soft */ }
    }

    private func pushScore(gameweek: Int, points: Int, credits: Int) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertFantasyScore(
                userId: userId, gameweek: gameweek, points: points, credits: credits, accessToken: token
            )
        } catch { /* soft */ }
    }

    @discardableResult
    func assign(_ player: Player, to targetSlot: FantasySlot, playersById: [String: Player]) -> String? {
        guard isViewingEditable else {
            return "Toto kolo nejde upravovat (deadline sobota 10:00)."
        }
        guard player.position == targetSlot.position else {
            return "Hráč neodpovídá pozici \(targetSlot.title)."
        }

        let movingFromOther = slotContaining(playerId: player.id)
        var next = slotPlayerIds
        if let movingFromOther, movingFromOther != targetSlot {
            next[movingFromOther] = nil
        }
        next[targetSlot] = nil

        let currentSpent = next.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.priceCredits(for: $1) }
        let price = FantasyRules.priceCredits(for: player)
        if currentSpent + price > FantasyRules.budgetCredits {
            return "Překročíš rozpočet \(FantasyRules.budgetCredits) kreditů."
        }

        var clubCounts = Dictionary(grouping: next.values.compactMap { playersById[$0]?.teamId }, by: { $0 })
            .mapValues(\.count)
        clubCounts[player.teamId, default: 0] += 1
        if clubCounts[player.teamId, default: 0] > FantasyRules.maxFromSameClub {
            return "Max. \(FantasyRules.maxFromSameClub) hráči z jednoho klubu."
        }

        next[targetSlot] = player.id
        var all = lineupsByGameweek
        all[activeGameweek] = next
        lineupsByGameweek = all
        return nil
    }

    func clear(slot: FantasySlot) {
        guard isViewingEditable else { return }
        var next = slotPlayerIds
        next[slot] = nil
        var all = lineupsByGameweek
        all[activeGameweek] = next
        lineupsByGameweek = all
    }

    func clearAll() {
        guard isViewingEditable else { return }
        var all = lineupsByGameweek
        all[activeGameweek] = [:]
        lineupsByGameweek = all
    }

    /// Manuální vyhodnocení uzavřených kol (např. po sobotě 10:00). Vrací přírůstek bodů.
    @discardableResult
    func claimRoundReward(playersById: [String: Player], matches: [Match]) -> Int {
        scorePendingGameweeks(playersById: playersById, matches: matches)
    }

    // MARK: Persistence

    private func persistLineups() {
        persist(lineupsByGameweek, key: Keys.lineups)
    }

    private func persistSaved() {
        persist(savedLineupsByGameweek, key: Keys.saved)
    }

    private func persist(_ map: [Int: [FantasySlot: String]], key: String) {
        var encoded: [String: [String: String]] = [:]
        for (gw, slots) in map {
            var dict: [String: String] = [:]
            for (slot, id) in slots {
                dict[slot.rawValue] = id
            }
            encoded["\(gw)"] = dict
        }
        defaults.set(encoded, forKey: key)
    }

    private static func loadLineups(from defaults: UserDefaults, key: String = Keys.lineups) -> [Int: [FantasySlot: String]] {
        guard let raw = defaults.dictionary(forKey: key) as? [String: [String: String]] else {
            return [:]
        }
        var result: [Int: [FantasySlot: String]] = [:]
        for (gwKey, slots) in raw {
            guard let gw = Int(gwKey) else { continue }
            var map: [FantasySlot: String] = [:]
            for slot in FantasySlot.allCases {
                if let id = slots[slot.rawValue] {
                    map[slot] = id
                }
            }
            result[gw] = map
        }
        return result
    }

    private func migrateLegacyIfNeeded() {
        guard lineupsByGameweek.isEmpty else { return }
        let legacy = (defaults.dictionary(forKey: Keys.legacyV2Slots) as? [String: String])
            ?? (defaults.dictionary(forKey: Keys.legacyV1Slots) as? [String: String])
            ?? [:]
        guard !legacy.isEmpty else { return }
        var map: [FantasySlot: String] = [:]
        for slot in FantasySlot.allCases {
            if let id = legacy[slot.rawValue] {
                map[slot] = id
            }
        }
        lineupsByGameweek = [activeGameweek: map]
    }
}

import Foundation
import SwiftUI

// MARK: - Slots (Extraliga: 1 goalie + 2 defensemen + 3 forwards)

/// A position in the fantasy lineup.
///
/// The lineup has six fixed spots — one goalie, two defensemen, three forwards —
/// and a player only fits a slot matching their position.
enum FantasySlot: String, CaseIterable, Identifiable, Hashable, Sendable {
    case goalie
    case defense1
    case defense2
    case forward1
    case forward2
    case forward3

    var id: String { rawValue }

    /// The player position this slot requires.
    var position: PlayerPosition {
        switch self {
        case .goalie: return .goalie
        case .defense1, .defense2: return .defenseman
        case .forward1, .forward2, .forward3: return .forward
        }
    }

    /// Slot name for the UI ("Obránce 1").
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

    /// Short position code shown on the card (B / O / Ú).
    var shortTitle: String {
        switch self {
        case .goalie: return "B"
        case .defense1, .defense2: return "O"
        case .forward1, .forward2, .forward3: return "Ú"
        }
    }
}

/// Card tier by rating — the better the player, the rarer the card.
///
/// Thresholds live in `FantasyRules.tier(for:)`.
enum FantasyCardTier: String, Sendable {
    case bronze
    case silver
    case gold
    case elite

    /// Card background colours.
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

    /// Text and border colour on the card.
    var accent: Color {
        switch self {
        case .bronze: return Color(red: 0.90, green: 0.70, blue: 0.45)
        case .silver: return Color.white
        case .gold: return Color(red: 1.0, green: 0.92, blue: 0.55)
        case .elite: return Color(red: 1.0, green: 0.84, blue: 0.30)
        }
    }

    /// Tier name shown in the scout sheet.
    var label: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .elite: return "Elite"
        }
    }
}

// MARK: - Deadlines / gameweeks (Saturday 10:00 Prague)

/// The fantasy gameweek calendar.
///
/// The season is split into weekly gameweeks, each opening with a deadline
/// **on Saturday at 10:00 Prague time**. Until then the lineup can be changed;
/// afterwards it locks and plays as saved.
///
/// Gameweeks are counted from `seasonAnchor` — the first Saturday of the season.
enum FantasyDeadline {
    /// Time zone the deadlines are expressed in (the same for everyone).
    static let prague = TimeZone(identifier: "Europe/Prague") ?? .current
    /// First Saturday of the fantasy season (the GW1 deadline).
    static let seasonAnchor = date(year: 2025, month: 9, day: 6, hour: 10, minute: 0)

    /// Gregorian calendar in Prague time.
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = prague
        return cal
    }

    /// Builds a date in Prague time from its components.
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

    /// Next Saturday 10:00 (today if it is Saturday before 10:00, otherwise next week).
    static func upcomingDeadline(from now: Date = Date()) -> Date {
        let cal = calendar
        let weekday = cal.component(.weekday, from: now) // 1 = Sunday … 7 = Saturday
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let startOfToday = cal.startOfDay(for: now)
        guard var saturday = cal.date(byAdding: .day, value: daysUntilSaturday, to: startOfDay(of: now) ?? startOfToday) else {
            return now
        }
        saturday = cal.date(bySettingHour: 10, minute: 0, second: 0, of: saturday) ?? saturday

        if daysUntilSaturday == 0, now >= saturday {
            // Saturday past 10:00 → roll to next week
            saturday = cal.date(byAdding: .day, value: 7, to: saturday) ?? saturday
        }
        return saturday
    }

    /// Deadline of the gameweek being played (this Saturday 10:00 once it has passed).
    static func activeDeadline(from now: Date = Date()) -> Date {
        let next = upcomingDeadline(from: now)
        return calendar.date(byAdding: .day, value: -7, to: next) ?? next
    }

    /// Gameweek number counted from the anchor Saturday (at least 1).
    static func gameweek(from now: Date = Date()) -> Int {
        let deadline = upcomingDeadline(from: now)
        let seconds = deadline.timeIntervalSince(seasonAnchor)
        let weeks = Int(floor(seconds / (7 * 24 * 3600)))
        return max(1, weeks + 1)
    }

    /// The lineup for `gameweek` stays editable while `now < deadline` of that week.
    static func deadline(forGameweek gw: Int) -> Date {
        calendar.date(byAdding: .day, value: (gw - 1) * 7, to: seasonAnchor) ?? seasonAnchor
    }

    /// Can the lineup for this gameweek still be changed?
    ///
    /// - Parameters:
    ///   - gameweek: Gameweek number.
    ///   - now: Point in time to check against.
    /// - Returns: `true` until that gameweek's deadline has passed.
    static func isEditable(gameweek: Int, at now: Date = Date()) -> Bool {
        now < deadline(forGameweek: gameweek)
    }

    /// Time left until the deadline as short text ("2d 5h").
    static func countdown(to deadline: Date, from now: Date = Date()) -> String {
        let p = countdownParts(to: deadline, from: now)
        if p.days > 0 { return "\(p.days)d \(p.hours)h" }
        if p.hours > 0 { return "\(p.hours)h \(p.minutes)m" }
        return "\(p.minutes)m \(p.seconds)s"
    }

    /// Time left split into days/hours/minutes/seconds — for the countdown UI.
    static func countdownParts(to deadline: Date, from now: Date = Date()) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = max(0, Int(deadline.timeIntervalSince(now)))
        let days = interval / 86_400
        let hours = (interval % 86_400) / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        return (days, hours, minutes, seconds)
    }

    /// Midnight of the given day in Prague time.
    private static func startOfDay(of date: Date) -> Date? {
        calendar.startOfDay(for: date)
    }
}

// MARK: - Rules

/// Game rules — budget, prices, player ratings and scoring.
///
/// All stateless so it can be called from anywhere in the UI.
enum FantasyRules {
    /// The competition players can be picked from.
    static let competitionSlug = "extraliga"

    /// Budget for the whole lineup, in credits.
    ///
    /// - Warning: See the note on `priceCredits(for:)` — with a price cap of 15
    ///   per player and six slots, this budget is currently unreachable.
    static let budgetCredits = 100

    /// How many players one club may supply (stops stacking a single team).
    static let maxFromSameClub = 2

    /// Number of lineup spots (1 goalie + 2 defensemen + 3 forwards).
    static let squadSize = FantasySlot.allCases.count

    /// Credits a player starts the season with.
    static let startingWallet = 0

    /// Is the player in Extraliga, and therefore signable?
    ///
    /// Goes by the player's competition first; falls back to their team's.
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

    /// Shared attribute table that `rating(for:)` reads from.
    ///
    /// Filled by `FantasyAttributesStore` (from the server or the mock). Global
    /// state on purpose: the rating is computed in dozens of UI spots — sorting
    /// the market, drawing cards, pricing players — and threading the store
    /// through all of those calls would only clutter them.
    ///
    /// - Warning: Written from a `@MainActor` store and read from the UI (also
    ///   main thread). If ratings ever move off the main thread, this needs to
    ///   become properly isolated state.
    static var attributesByPlayerId: [String: PlayerAttributes] = [:]

    /// The player's overall — the number on the card.
    ///
    /// Coach-supplied attributes win (`PlayerAttributes`, up to 99). Without
    /// them the rating is derived from season statistics
    /// (`statRating(for:)`, 55–94), so every player still gets a card.
    ///
    /// - Parameter player: The player.
    /// - Returns: OVR 1–99.
    static func rating(for player: Player) -> Int {
        if let attrs = attributesByPlayerId[player.id],
           let ovr = attrs.computedOverall(position: player.position) {
            return ovr
        }
        return statRating(for: player)
    }

    /// Overall estimated from season statistics — the fallback without attributes.
    ///
    /// Each position is judged differently: goalies on save percentage and goals
    /// against average, skaters on points per game, goals and games played
    /// (which rewards regulars in the lineup).
    ///
    /// The result is deliberately capped at **55–94** so a stats-derived rating
    /// never outranks a player with hand-filled attributes.
    ///
    /// - Parameter player: A player with season statistics.
    /// - Returns: OVR 55–94.
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

    /// Card tier by rating (bronze → silver → gold → elite).
    ///
    /// - Parameter rating: The player's overall.
    /// - Returns: The tier driving the card's gradient and border.
    static func tier(for rating: Int) -> FantasyCardTier {
        switch rating {
        case ..<65: return .bronze
        case ..<75: return .silver
        case ..<85: return .gold
        default: return .elite
        }
    }

    /// Player price in credits, derived linearly from their overall.
    ///
    /// A 55 costs 4 credits, a 94 and above costs fifteen — the cap.
    ///
    /// - Parameter player: The player.
    /// - Returns: A price between 4 and 15 credits.
    ///
    /// - Warning: The cap of 15 means a full lineup (6 players) tops out at 90
    ///   credits while the budget is `budgetCredits` = 100 — so the budget
    ///   constrains nobody today. Before Fantasy goes live, either lower the
    ///   budget or widen the price range.
    static func priceCredits(for player: Player) -> Int {
        let r = rating(for: player)
        // 55 → 4, 94 → 15
        let raw = 4.0 + Double(r - 55) * (11.0 / 39.0)
        return Int(min(15, max(4, raw.rounded())))
    }

    /// Price as a `Double` — legacy UI only, prefer `priceCredits(for:)`.
    static func price(for player: Player) -> Double {
        Double(priceCredits(for: player))
    }

    /// Rough points a player contributes across the **whole season**.
    ///
    /// Used as a hint in the market and the scout sheet ("roughly how much does
    /// this player rack up"), **not** to award real gameweek points — that is
    /// je `weeklyFantasyPoints(for:in:)`.
    ///
    /// - Parameter player: A player with season statistics.
    /// - Returns: Points, never negative.
    static func fantasyPoints(for player: Player) -> Int {
        switch player.position {
        case .goalie:
            let saveBonus = Int(((player.savePercentage ?? 88) - 85) * 2)
            return max(0, player.games * 2 + saveBonus - player.penaltyMinutes / 4)
        case .defenseman, .forward:
            return max(0, player.goals * 3 + player.assists * 2 + player.games / 2 - player.penaltyMinutes / 5)
        }
    }

    /// Credits awarded for a completed gameweek.
    ///
    /// Everyone with a saved lineup gets a base of 10, plus a third of the
    /// points scored — capped at 40, so one great week cannot decide the
    /// whole season.
    ///
    /// - Parameter squadPoints: Lineup points for that gameweek.
    /// - Returns: Between 10 and 50 credits.
    static func roundRewardCredits(squadPoints: Int) -> Int {
        10 + min(40, squadPoints / 3)
    }

    /// A team's next match — powers the "vs Opponent" label on cards and scout.
    ///
    /// A live match counts too, and a three-hour grace period keeps the label
    /// from flipping the moment the game starts.
    ///
    /// - Parameters:
    ///   - teamId: The team whose match we want.
    ///   - matches: Matches to search through.
    ///   - date: Point to search from (defaults to now).
    /// - Returns: The next match, or `nil` when none are left.
    static func nextFixture(for teamId: String, in matches: [Match], after date: Date = Date()) -> Match? {
        matches
            .filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
            .filter { $0.status == .scheduled || $0.status == .live }
            .filter { $0.scheduledAt >= date.addingTimeInterval(-3 * 3600) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    /// Matches belonging to a given gameweek.
    ///
    /// A gameweek is the window between two deadlines (Saturday 10:00 → the next
    /// Saturday 10:00), so a match belongs to the lineup it was played under.
    ///
    /// - Parameters:
    ///   - gameweek: Gameweek number.
    ///   - matches: Matches to pick from.
    /// - Returns: Matches played within that gameweek's window.
    static func matches(inGameweek gameweek: Int, from matches: [Match]) -> [Match] {
        let start = FantasyDeadline.deadline(forGameweek: gameweek)
        let end = FantasyDeadline.deadline(forGameweek: gameweek + 1)
        return matches.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
    }

    /// A player's points for one gameweek, based on how their weekend went.
    ///
    /// This is the heart of Fantasy — these points drive the leaderboard.
    /// Only **finished** matches of that gameweek count; if the player's team has
    /// not played yet this returns zero (the week is scored later).
    ///
    /// ## Scoring
    ///
    /// **Skaters** — from the match's goal events:
    /// - goal scored: 3 points
    /// - asistence: 2 body
    ///
    /// **Goalies** — from the team result, since the data omits who played:
    /// - win: 3 points
    /// - clean sheet: 5 points
    /// - otherwise by goals against: `4 − goals conceded` (never below 0)
    ///
    /// - Parameters:
    ///   - player: A player from the lineup.
    ///   - gameweekMatches: That week's matches (see `matches(inGameweek:from:)`).
    /// - Returns: Gameweek points, never negative.
    ///
    /// - Note: Goalie points are an estimate — until the data says who started,
    ///   the rostered goalie scores whether or not they actually played.
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
            // Without goalie sheets, approximate from the team result.
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

/// One user's fantasy team state.
///
/// Holds lineups per gameweek, points, credits and display settings. Data
/// lives in `UserDefaults` and mirrors to Supabase once signed in, so a team
/// survives a reinstall or a move to another device.
///
/// ## How the pieces fit
///
/// 1. `syncGameweekIfNeeded(now:)` advances the week once the deadline passes
/// 2. the user builds a lineup via `assign(_:to:playersById:)`
/// 3. `saveLineup()` confirms it and pushes it to the server
/// 4. `scorePendingGameweeks(playersById:matches:)` awards points once played
@MainActor
final class FantasySquadStore: ObservableObject {
    /// Team name shown on the leaderboard.
    @Published var teamName: String {
        didSet { defaults.set(teamName, forKey: Keys.teamName) }
    }

    /// Working draft lineups per gameweek: gameweek → slot → player ID.
    @Published private(set) var lineupsByGameweek: [Int: [FantasySlot: String]] {
        didSet { persistLineups() }
    }

    /// The gameweek being played (its lineup is editable until the deadline).
    @Published private(set) var activeGameweek: Int {
        didSet { defaults.set(activeGameweek, forKey: Keys.activeGW) }
    }

    /// Credits collected from completed gameweeks.
    @Published private(set) var wallet: Int {
        didSet { defaults.set(wallet, forKey: Keys.wallet) }
    }

    /// Season points total — what the leaderboard ranks by.
    @Published private(set) var seasonPoints: Int {
        didSet { defaults.set(seasonPoints, forKey: Keys.seasonPoints) }
    }

    /// Gameweeks already scored (guards against double counting).
    @Published private(set) var scoredGameweeks: Set<Int> {
        didSet {
            defaults.set(Array(scoredGameweeks), forKey: Keys.scored)
        }
    }

    /// Gameweek being viewed (hub arrows) — editable only when it is the active one and unlocked.
    @Published var viewingGameweek: Int = 1

    /// Free transfers left (99 = unlimited before the first deadline).
    @Published private(set) var freeTransfers: Int {
        didSet { defaults.set(freeTransfers, forKey: Keys.freeTransfers) }
    }

    /// Confirmed lineups per gameweek — these are what scoring uses.
    ///
    /// Distinct from `lineupsByGameweek`, which is the working draft; only what
    /// the user confirmed with the save button counts towards points.
    @Published private(set) var savedLineupsByGameweek: [Int: [FantasySlot: String]] {
        didSet { persistSaved() }
    }

    /// Show the player price on lineup cards.
    @Published var showPriceOnPitch: Bool {
        didSet { defaults.set(showPriceOnPitch, forKey: Keys.showPrice) }
    }
    /// Show gameweek points on lineup cards.
    @Published var showPointsOnPitch: Bool {
        didSet { defaults.set(showPointsOnPitch, forKey: Keys.showPoints) }
    }
    /// Show the next opponent on lineup cards.
    @Published var showOpponentOnPitch: Bool {
        didSet { defaults.set(showOpponentOnPitch, forKey: Keys.showOpponent) }
    }

    /// Last lineup-save message (for the confirmation in the UI).
    @Published private(set) var lastSaveMessage: String?

    private let defaults = UserDefaults.standard

    /// `UserDefaults` keys. Version `v3` because of migrations from older formats.
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

    // MARK: Computed for the active / viewed gameweek

    /// Deadline of the active gameweek.
    var deadline: Date { FantasyDeadline.deadline(forGameweek: activeGameweek) }
    /// Deadline of the gameweek being viewed.
    var viewingDeadline: Date { FantasyDeadline.deadline(forGameweek: viewingGameweek) }
    /// Has the active gameweek's deadline passed?
    var isLocked: Bool { !FantasyDeadline.isEditable(gameweek: activeGameweek) }
    /// Is the viewed lineup editable? (Only the active week before its deadline.)
    var isViewingEditable: Bool {
        viewingGameweek == activeGameweek && !isLocked
    }
    /// Countdown to the deadline as text.
    var countdownText: String { FantasyDeadline.countdown(to: deadline) }

    /// Countdown split into components — for the UI counter.
    var countdownParts: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        FantasyDeadline.countdownParts(to: deadline)
    }

    /// Slot assignments in the viewed gameweek (slot → player ID).
    var slotPlayerIds: [FantasySlot: String] {
        lineupsByGameweek[viewingGameweek] ?? lineupsByGameweek[activeGameweek] ?? [:]
    }

    /// How many slots are filled.
    var filledCount: Int { slotPlayerIds.count }
    /// Is the lineup complete (all six slots)?
    var isComplete: Bool { filledCount == FantasyRules.squadSize }
    /// IDs already in the lineup (so nobody can be picked twice).
    var selectedPlayerIds: Set<String> { Set(slotPlayerIds.values) }

    /// Does the working lineup differ from the confirmed one?
    var hasUnsavedChanges: Bool {
        let draft = lineupsByGameweek[activeGameweek] ?? [:]
        let saved = savedLineupsByGameweek[activeGameweek] ?? [:]
        return draft != saved
    }

    /// Transfer count for the UI ("∞" before the first deadline).
    var transfersLabel: String {
        if freeTransfers >= 99 { return "∞" }
        return "\(freeTransfers)"
    }

    /// Rough rank derived from points (local demo).
    var overallRank: Int {
        max(1, 12_000 - seasonPoints * 17)
    }

    /// Rough gameweek rank (local demo until the real leaderboard arrives).
    var roundRank: Int {
        max(1, 8_500 - squadPoints(playersById: [:]) * 11)
    }

    /// The player occupying a slot.
    func playerId(for slot: FantasySlot) -> String? { slotPlayerIds[slot] }

    /// Which slot a player sits in, if any.
    func slotContaining(playerId: String) -> FantasySlot? {
        slotPlayerIds.first { $0.value == playerId }?.key
    }

    /// What the current lineup costs in credits.
    func spentCredits(playersById: [String: Player]) -> Int {
        slotPlayerIds.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.priceCredits(for: $1) }
    }

    /// How many budget credits are left.
    func remainingBudget(playersById: [String: Player]) -> Int {
        FantasyRules.budgetCredits - spentCredits(playersById: playersById)
    }

    /// Legacy alias for `spentCredits(playersById:)`.
    func spent(playersById: [String: Player]) -> Double {
        Double(spentCredits(playersById: playersById))
    }

    /// Rough lineup total from season stats (a preview, not real points).
    func squadPoints(playersById: [String: Player]) -> Int {
        slotPlayerIds.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.fantasyPoints(for: $1) }
    }

    /// Moves the viewed gameweek via the hub arrows.
    func shiftViewingGameweek(by delta: Int) {
        viewingGameweek = max(1, viewingGameweek + delta)
    }

    /// Real fantasy leaderboard from the server (falls back to the local demo).
    @Published private(set) var remoteLeaderboard: [FantasyLeaderRow] = []

    /// Confirms the active gameweek's draft. Pushes to the server once signed in.
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

    /// Advances the active gameweek and prepares its lineup for editing.
    ///
    /// Called on launch and when Fantasy opens. If a deadline passed in the
    /// meantime, it switches to the new week, carries the last saved lineup over
    /// as a starting point and grants a free transfer.
    ///
    /// Awards **no** points — that is `scorePendingGameweeks(playersById:matches:)`,
    /// which needs finished matches.
    ///
    /// - Parameter now: Point in time the gameweek is derived from (injectable for tests).
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

    /// Scores every closed gameweek that has not been settled yet.
    ///
    /// Walks the weeks from the start of the season to the current one and sums
    /// the saved lineup's performance. A week is skipped when:
    /// - the lineup was not saved in full (1 goalie, 2 defensemen, 3 forwards), or
    /// - not a single match of that week has finished yet (settled next time).
    ///
    /// A settled week is recorded in `scoredGameweeks`, so points can never be
    /// awarded twice, and the result is sent to the server.
    ///
    /// - Parameters:
    ///   - playersById: Players by ID — must cover everyone in the lineups.
    ///   - allMatches: Season matches the performance is computed from.
    /// - Returns: Points just awarded (0 = nothing new to settle).
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

    /// Pulls saved lineups and points from the server — the server is the truth.
    ///
    /// Overwrites local state so the user sees their team after a reinstall or
    /// on another device. Does nothing when signed out or in demo mode.
    /// Errors are swallowed — the app carries on with local data.
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

    /// Loads the overall fantasy leaderboard.
    ///
    /// Reads the public `fantasy_leaderboard` view, so it works without signing
    /// in. On failure (or in demo mode) it stays empty and the UI shows the
    /// local demo with bots.
    func loadLeaderboard() async {
        guard !FantasyMock.enabled else { return }
        guard let api = AuthAccess.store?.authAPI else { return }
        do { remoteLeaderboard = try await api.fetchFantasyLeaderboard() }
        catch { /* soft */ }
    }

    /// Replaces local state with server data.
    ///
    /// Lineups land in both the draft and the confirmed map (the server only
    /// stores confirmed ones); points and credits are summed across weeks.
    ///
    /// - Parameters:
    ///   - squads: Saved lineups per gameweek.
    ///   - scores: Settled gameweeks with points and credits.
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

    /// Pushes a gameweek's saved lineup to the server.
    ///
    /// - Parameter gameweek: The gameweek whose lineup is saved.
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

    /// Writes a settled gameweek to the server (feeds the leaderboard).
    ///
    /// - Parameters:
    ///   - gameweek: The settled gameweek.
    ///   - points: Body sestavy za kolo.
    ///   - credits: Credits awarded.
    private func pushScore(gameweek: Int, points: Int, credits: Int) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertFantasyScore(
                userId: userId, gameweek: gameweek, points: points, credits: credits, accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Places a player into a lineup slot.
    ///
    /// Checks every rule in turn: the week is editable, the position matches, the
    /// budget holds and the per-club limit is respected. A player already in the
    /// lineup elsewhere is moved rather than duplicated.
    ///
    /// - Parameters:
    ///   - player: The chosen player.
    ///   - targetSlot: The slot to place them in.
    ///   - playersById: Players by ID (for prices and clubs already rostered).
    /// - Returns: `nil` on success, otherwise a message naming the broken rule.
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

    /// Clears a single lineup slot.
    func clear(slot: FantasySlot) {
        guard isViewingEditable else { return }
        var next = slotPlayerIds
        next[slot] = nil
        var all = lineupsByGameweek
        all[activeGameweek] = next
        lineupsByGameweek = all
    }

    /// Clears the whole lineup of the active gameweek.
    func clearAll() {
        guard isViewingEditable else { return }
        var all = lineupsByGameweek
        all[activeGameweek] = [:]
        lineupsByGameweek = all
    }

    /// Manually settles closed gameweeks (e.g. after Saturday 10:00). Returns points gained.
    @discardableResult
    func claimRoundReward(playersById: [String: Player], matches: [Match]) -> Int {
        scorePendingGameweeks(playersById: playersById, matches: matches)
    }

    // MARK: Persistence

    /// Persists the draft lineups to `UserDefaults`.
    private func persistLineups() {
        persist(lineupsByGameweek, key: Keys.lineups)
    }

    /// Persists the confirmed lineups to `UserDefaults`.
    private func persistSaved() {
        persist(savedLineupsByGameweek, key: Keys.saved)
    }

    /// Writes lineups per gameweek under a key (dictionaries serialise to strings).
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

    /// Reads lineups per gameweek from `UserDefaults`; ignores corrupted data.
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

    /// Carries a lineup over from older storage (v1/v2) when v3 is still empty.
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

import Foundation
import SwiftUI

/// Who the player backed in a winner tip. Draws are not predicted.
enum MatchTipPick: String, Codable, Hashable, Sendable {
    case home
    case away

    /// Display label for the UI.
    var label: String {
        switch self {
        case .home: return "Domácí"
        case .away: return "Hosté"
        }
    }
}

/// A winner prediction — **public**, unlike the exact-score tip.
///
/// These feed the community favourite percentages everyone can see.
struct MatchTip: Codable, Hashable, Sendable {
    /// The match this tip belongs to.
    var matchId: String
    /// Who the player backed.
    var pick: MatchTipPick
    /// When the tip was placed.
    var createdAt: Date
    /// The match is over and the tip has been settled.
    var resolved: Bool
    /// Did the player get the winner right? Only valid once settled.
    var isCorrect: Bool?
    /// Points earned (3 for a hit, otherwise 0).
    var pointsAwarded: Int
}

/// An exact-score prediction — **private**, unlike the winner tip.
///
/// Nobody sees anyone else's (enforced by RLS on `match_score_tips`); only
/// the points total reaches the leaderboard. Scored by `FantasyScoring`.
struct MatchScoreTip: Codable, Hashable, Sendable {
    /// The match this tip belongs to.
    var matchId: String
    /// Predicted home goals.
    var homeScore: Int
    /// Predicted away goals.
    var awayScore: Int
    /// The player called overtime or a shootout.
    var predictedOvertime: Bool
    /// The match is over and points have been computed.
    var resolved: Bool
    /// Points earned (only valid once `resolved == true`).
    var pointsAwarded: Int
}

/// Community tip split for one match — powers the favourite bar.
struct MatchTipVotes: Codable, Hashable, Sendable {
    /// The match being voted on.
    var matchId: String
    /// How many people back the home team.
    var homeCount: Int
    /// How many people back the away team.
    var awayCount: Int

    /// Total votes; at least 1 to avoid dividing by zero.
    var total: Int { max(1, homeCount + awayCount) }
    /// Share of home tips, in percent.
    var homePercent: Int { Int((Double(homeCount) / Double(total) * 100).rounded()) }
    /// The remainder to 100 — keeps the bar adding up exactly.
    var awayPercent: Int { max(0, 100 - homePercent) }
}

/// A row of the tipping leaderboard.
struct TipLeaderboardEntry: Identifiable, Hashable, Sendable {
    /// User ID (or a bot in demo mode).
    let id: String
    /// Name shown on the leaderboard.
    let name: String
    /// Total points — winner and score tips combined.
    let points: Int
    /// How many tips were correct.
    let correct: Int
    /// How many tips were settled in total.
    let total: Int
    /// Is this the signed-in user? (The row is then highlighted.)
    let isCurrentUser: Bool

    /// Accuracy in percent.
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}

/// One user's tipping state.
///
/// Manages two kinds of prediction on Extraliga matches:
/// - **winner tip** — public, feeds the community favourite percentages
/// - **score tip** — private, invisible to others, only worth points
///
/// Tips are stored locally and, once signed in, on the server too. When a
/// match ends they are settled (`resolve(matches:)`,
/// `resolveScoreTips(matches:)`) and the points feed the leaderboard.
@MainActor
final class MatchTipStore: ObservableObject {
    /// Points for correctly picking the winner.
    static let pointsPerCorrectTip = 3
    /// The competition predictions are open for.
    static let competitionSlug = "extraliga"

    /// Nickname shown on the leaderboard.
    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    /// My winner tips by match ID.
    @Published private(set) var tips: [String: MatchTip] = [:] {
        didSet { persistTips() }
    }

    /// Community tip splits by match ID.
    @Published private(set) var votes: [String: MatchTipVotes] = [:] {
        didSet { persistVotes() }
    }

    /// Exact-score tips (private) — keyed by match ID.
    @Published private(set) var scoreTips: [String: MatchScoreTip] = [:] {
        didSet { persistScoreTips() }
    }

    /// Made-up rivals for the demo leaderboard until server data arrives.
    @Published private(set) var botEntries: [TipLeaderboardEntry] = []

    /// Real leaderboard from the server (`tip_leaderboard`). Empty = fall back to bots.
    @Published private(set) var remoteLeaderboard: [TipLeaderboardEntry] = []

    private let defaults = UserDefaults.standard
    private let userId = "local-user"

    /// `UserDefaults` keys.
    private enum Keys {
        static let displayName = "hb.tips.v1.name"
        static let tips = "hb.tips.v1.tips"
        static let votes = "hb.tips.v1.votes"
        static let bots = "hb.tips.v1.bots"
        static let scoreTips = "hb.tips.v1.scoreTips"
    }

    init() {
        displayName = defaults.string(forKey: Keys.displayName) ?? "Tipér"
        tips = Self.loadTips(from: defaults)
        votes = Self.loadVotes(from: defaults)
        scoreTips = Self.loadScoreTips(from: defaults)
        botEntries = Self.loadBots(from: defaults)
        if botEntries.isEmpty {
            botEntries = Self.makeBots()
            persistBots()
        }
    }

    // MARK: - Rules

    /// Is this an Extraliga match? Other competitions are not open for tips.
    func isExtraliga(_ match: Match, competitions: [Competition]) -> Bool {
        if let comp = competitions.first(where: { $0.id == match.competitionId }) {
            return comp.slug == Self.competitionSlug
        }
        return match.competitionId.contains("extraliga")
    }

    /// Can this match still be tipped? (Scheduled and before puck drop only.)
    func canTip(_ match: Match) -> Bool {
        match.status == .scheduled && Date() < match.scheduledAt
    }

    /// My winner tip on a given match.
    func tip(for matchId: String) -> MatchTip? { tips[matchId] }

    /// Read-only — never mutates when read from a view body.
    func votes(for matchId: String) -> MatchTipVotes {
        votes[matchId] ?? seedVotes(matchId: matchId)
    }

    /// Seeds community votes — call from onAppear / placeTip, not from a body.
    func ensureVotes(matchId: String) {
        if votes[matchId] == nil {
            votes[matchId] = seedVotes(matchId: matchId)
        }
        Task { await refreshVotesFromRemote(matchId: matchId) }
    }

    /// Refreshes community tip counts from the server.
    ///
    /// Takes the max of the local seed and the server so the bar never jumps
    /// down before real tips accumulate.
    func refreshVotesFromRemote(matchId: String) async {
        guard let auth = AuthAccess.store else { return }
        do {
            let remote = try await auth.authAPI.fetchTipVotes(matchId: matchId)
            let seed = seedVotes(matchId: matchId)
            votes[matchId] = MatchTipVotes(
                matchId: matchId,
                homeCount: max(seed.homeCount, remote.home),
                awayCount: max(seed.awayCount, remote.away)
            )
        } catch { /* keep local */ }
    }

    /// Pulls my winner tips from the server; leaves local ones alone.
    func syncMyTipsFromRemote() async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let rows = try await auth.authAPI.fetchMyTips(userId: userId, accessToken: token)
            for row in rows {
                guard let pick = MatchTipPick(rawValue: row.pick) else { continue }
                if tips[row.matchId] == nil {
                    tips[row.matchId] = MatchTip(
                        matchId: row.matchId,
                        pick: pick,
                        createdAt: row.createdAt ?? Date(),
                        resolved: false,
                        isCorrect: nil,
                        pointsAwarded: 0
                    )
                }
            }
            if let name = auth.profile?.username, !name.isEmpty {
                displayName = name
            }
        } catch { /* soft */ }
    }

    /// Places or changes a winner tip.
    ///
    /// Also rebalances the community vote — on a change the old vote is removed
    /// and the new one added, keeping the percentages honest.
    ///
    /// - Parameters:
    ///   - match: The match being predicted.
    ///   - pick: Home or away.
    ///   - competitions: Competition catalogue (to verify Extraliga).
    /// - Returns: `nil` on success, otherwise a message for the user.
    @discardableResult
    func placeTip(match: Match, pick: MatchTipPick, competitions: [Competition]) -> String? {
        guard FantasyMock.enabled || AuthAccess.store?.isAuthenticated == true else {
            AuthAccess.store?.presentLogin()
            return "Pro tipování se musíš přihlásit."
        }
        guard isExtraliga(match, competitions: competitions) else {
            return "Tipovat lze jen zápasy Extraligy."
        }
        guard canTip(match) else {
            return "Tipování je uzavřené (zápas už začal)."
        }

        ensureVotes(matchId: match.id)
        var tally = votes[match.id]!

        if let existing = tips[match.id] {
            if existing.pick == pick { return nil }
            // move the vote across
            if existing.pick == .home { tally.homeCount = max(0, tally.homeCount - 1) }
            else { tally.awayCount = max(0, tally.awayCount - 1) }
        }

        if pick == .home { tally.homeCount += 1 }
        else { tally.awayCount += 1 }
        votes[match.id] = tally

        tips[match.id] = MatchTip(
            matchId: match.id,
            pick: pick,
            createdAt: Date(),
            resolved: false,
            isCorrect: nil,
            pointsAwarded: 0
        )

        Task { await pushTipToRemote(matchId: match.id, pick: pick) }
        return nil
    }

    /// Pushes a winner tip to the server and refreshes the vote counts.
    private func pushTipToRemote(matchId: String, pick: MatchTipPick) async {
        guard let auth = AuthAccess.store, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertTip(
                userId: userId,
                matchId: matchId,
                pick: pick.rawValue,
                accessToken: token
            )
            await refreshVotesFromRemote(matchId: matchId)
        } catch { /* soft */ }
    }

    // MARK: - Exact-score tips (private)

    /// My score tip on a given match.
    ///
    /// - Parameter matchId: The match ID.
    /// - Returns: The tip, or `nil` when no score was predicted.
    func scoreTip(for matchId: String) -> MatchScoreTip? { scoreTips[matchId] }

    /// Places or replaces an exact-score prediction.
    ///
    /// Verifies the match is Extraliga, has not started, and that the user is
    /// signed in (not required in demo mode). Clamps the score to 0–30 goals and
    /// drops the overtime flag unless the margin is exactly one goal. The tip is
    /// pushed to the server afterwards.
    ///
    /// - Parameters:
    ///   - match: The match being predicted.
    ///   - home: Predicted home goals.
    ///   - away: Predicted away goals.
    ///   - overtime: The player called overtime/shootout.
    ///   - competitions: Competition catalogue (to verify Extraliga).
    /// - Returns: `nil` on success, otherwise a message explaining the rejection.
    @discardableResult
    func placeScoreTip(match: Match, home: Int, away: Int, overtime: Bool, competitions: [Competition]) -> String? {
        guard FantasyMock.enabled || AuthAccess.store?.isAuthenticated == true else {
            AuthAccess.store?.presentLogin()
            return "Pro tipování se musíš přihlásit."
        }
        guard isExtraliga(match, competitions: competitions) else {
            return "Tipovat lze jen zápasy Extraligy."
        }
        guard canTip(match) else {
            return "Tipování je uzavřené (zápas už začal)."
        }
        let h = max(0, min(30, home))
        let a = max(0, min(30, away))
        let ot = overtime && FantasyScoring.canPredictOvertime(predHome: h, predAway: a)
        scoreTips[match.id] = MatchScoreTip(
            matchId: match.id, homeScore: h, awayScore: a,
            predictedOvertime: ot, resolved: false, pointsAwarded: 0
        )
        Task { await pushScoreTip(matchId: match.id) }
        return nil
    }

    /// Scores exact-score tips on matches that have finished.
    ///
    /// Each tip is settled once (`resolved`), so points are never counted
    /// repeatedly. The result is written to the server too.
    ///
    /// - Parameter matches: Matches to check; unfinished ones are ignored.
    func resolveScoreTips(matches: [Match]) {
        var changed = false
        for match in matches where match.status == .finished {
            guard var tip = scoreTips[match.id], !tip.resolved else { continue }
            tip.pointsAwarded = FantasyScoring.scorePoints(
                predHome: tip.homeScore, predAway: tip.awayScore,
                resHome: match.homeScore, resAway: match.awayScore,
                predictedOvertime: tip.predictedOvertime,
                decidedInOvertime: match.decidedInOvertime
            )
            tip.resolved = true
            scoreTips[match.id] = tip
            changed = true
            Task { await pushScoreTip(matchId: match.id) }
        }
        if changed { objectWillChange.send() }
    }

    /// Pushes a score tip to the server (inserting or replacing it).
    ///
    /// - Parameter matchId: The match whose tip is sent.
    private func pushScoreTip(matchId: String) async {
        guard let auth = AuthAccess.store, let userId = auth.userId, let tip = scoreTips[matchId] else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertScoreTip(
                userId: userId, matchId: matchId,
                homeScore: tip.homeScore, awayScore: tip.awayScore,
                predictedOvertime: tip.predictedOvertime,
                pointsAwarded: tip.resolved ? tip.pointsAwarded : nil,
                accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Pulls my score tips from the server (e.g. after reinstalling the app).
    ///
    /// Leaves local tips alone — only adopts the ones missing on this device, so
    /// work in progress is never overwritten. Does nothing in demo mode.
    func syncScoreTipsFromRemote() async {
        guard !FantasyMock.enabled else { return }
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let rows = try await auth.authAPI.fetchMyScoreTips(userId: userId, accessToken: token)
            for row in rows where scoreTips[row.matchId] == nil {
                scoreTips[row.matchId] = MatchScoreTip(
                    matchId: row.matchId, homeScore: row.homeScore, awayScore: row.awayScore,
                    predictedOvertime: row.predictedOvertime,
                    resolved: row.pointsAwarded != nil,
                    pointsAwarded: row.pointsAwarded ?? 0
                )
            }
        } catch { /* soft */ }
    }

    // MARK: - Server leaderboard

    /// Loads the shared tipping leaderboard.
    ///
    /// The `tip_leaderboard` view sums winner and score tips together but never
    /// exposes individual tips, so privacy holds. On failure (or in demo mode)
    /// the UI falls back to the local demo with bots.
    func loadLeaderboard() async {
        guard !FantasyMock.enabled else { return }
        guard let api = AuthAccess.store?.authAPI else { return }
        do {
            let rows = try await api.fetchTipLeaderboard()
            let myId = AuthAccess.store?.userId
            remoteLeaderboard = rows.map { row in
                TipLeaderboardEntry(
                    id: row.userId,
                    name: row.displayName ?? row.username ?? "Tipér",
                    points: row.totalPoints,
                    correct: 0,
                    total: row.tipsCount ?? 0,
                    isCurrentUser: row.userId == myId
                )
            }
        } catch { /* soft */ }
    }

    /// Writes winner-tip points to the server (feeds the leaderboard).
    ///
    /// - Parameter matchId: The match whose tip was just settled.
    private func pushWinnerPoints(matchId: String) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId,
              let tip = tips[matchId], tip.resolved else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.setWinnerTipPoints(
                userId: userId, matchId: matchId, points: tip.pointsAwarded, accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Settles winner tips on matches that have finished.
    ///
    /// A draw counts as a miss (no winner was predicted). Each tip is settled
    /// once and the result is pushed to the server.
    ///
    /// - Parameter matches: Matches to check; unfinished ones are ignored.
    func resolve(matches: [Match]) {
        var changed = false
        for match in matches where match.status == .finished {
            guard var tip = tips[match.id], !tip.resolved else { continue }
            guard match.homeScore != match.awayScore else {
                tip.resolved = true
                tip.isCorrect = false
                tip.pointsAwarded = 0
                tips[match.id] = tip
                changed = true
                Task { await pushWinnerPoints(matchId: match.id) }
                continue
            }
            let winner: MatchTipPick = match.homeScore > match.awayScore ? .home : .away
            let correct = tip.pick == winner
            tip.resolved = true
            tip.isCorrect = correct
            tip.pointsAwarded = correct ? Self.pointsPerCorrectTip : 0
            tips[match.id] = tip
            changed = true
            Task { await pushWinnerPoints(matchId: match.id) }
        }
        if changed { objectWillChange.send() }
    }

    // MARK: - Stats / leaderboard

    /// All of my winner tips.
    var myTips: [MatchTip] { Array(tips.values) }

    /// Number of winner tips placed.
    var totalTips: Int { tips.count }
    /// Number of tips already settled.
    var resolvedTips: Int { tips.values.filter(\.resolved).count }
    /// Number of correct tips.
    var correctTips: Int { tips.values.filter { $0.isCorrect == true }.count }
    /// Tips waiting for their match to finish.
    var openTips: Int { tips.values.filter { !$0.resolved }.count }
    /// Points from winner tips only.
    var seasonPoints: Int { tips.values.reduce(0) { $0 + $1.pointsAwarded } }

    /// Points from exact-score tips only.
    var scoreTipPoints: Int { scoreTips.values.reduce(0) { $0 + $1.pointsAwarded } }

    /// Total leaderboard points — winner and score tips combined.
    var combinedPoints: Int { seasonPoints + scoreTipPoints }

    /// Score tips waiting for their match to finish.
    var openScoreTips: Int { scoreTips.values.filter { !$0.resolved }.count }

    /// Winner-tip accuracy in percent.
    var accuracy: Double {
        guard resolvedTips > 0 else { return 0 }
        return Double(correctTips) / Double(resolvedTips) * 100
    }

    /// My leaderboard row, assembled from local data.
    var myLeaderboardEntry: TipLeaderboardEntry {
        TipLeaderboardEntry(
            id: AuthAccess.store?.userId ?? userId,
            name: displayName,
            points: combinedPoints,
            correct: correctTips,
            total: resolvedTips,
            isCurrentUser: true
        )
    }

    /// Leaderboard to display — real from the server, otherwise the local demo.
    var leaderboard: [TipLeaderboardEntry] {
        let sortRule: (TipLeaderboardEntry, TipLeaderboardEntry) -> Bool = {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.correct != $1.correct { return $0.correct > $1.correct }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        // Server leaderboard wins; otherwise fall back to the local demo with bots.
        if !remoteLeaderboard.isEmpty {
            var rows = remoteLeaderboard
            if AuthAccess.store?.isAuthenticated == true, !rows.contains(where: \.isCurrentUser) {
                rows.append(myLeaderboardEntry)
            }
            return rows.sorted(by: sortRule)
        }
        return (botEntries + [myLeaderboardEntry]).sorted(by: sortRule)
    }

    /// My leaderboard rank (1 = first).
    var myRank: Int {
        leaderboard.firstIndex(where: \.isCurrentUser).map { $0 + 1 } ?? leaderboard.count
    }

    // MARK: - Private

    /// Builds a believable baseline of community votes before real tips arrive.
    ///
    /// Derived from the match ID, so it stays identical for a match — otherwise
    /// the percentages would jump on every open.
    private func seedVotes(matchId: String) -> MatchTipVotes {
        // Stable "community" baseline derived from the match id
        var hash: UInt64 = 5381
        for b in matchId.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(b) }
        let total = Int(80 + (hash % 220))
        let homeShare = 0.35 + Double(hash % 30) / 100.0 // 35–64 %
        let home = max(1, Int(Double(total) * homeShare))
        let away = max(1, total - home)
        return MatchTipVotes(matchId: matchId, homeCount: home, awayCount: away)
    }

    /// Persists winner tips to `UserDefaults`.
    private func persistTips() {
        if let data = try? JSONEncoder().encode(tips) {
            defaults.set(data, forKey: Keys.tips)
        }
    }

    /// Persists community vote counts.
    private func persistVotes() {
        if let data = try? JSONEncoder().encode(votes) {
            defaults.set(data, forKey: Keys.votes)
        }
    }

    /// Persists score tips to `UserDefaults`.
    private func persistScoreTips() {
        if let data = try? JSONEncoder().encode(scoreTips) {
            defaults.set(data, forKey: Keys.scoreTips)
        }
    }

    /// Reads score tips; ignores corrupted data.
    private static func loadScoreTips(from defaults: UserDefaults) -> [String: MatchScoreTip] {
        guard let data = defaults.data(forKey: Keys.scoreTips),
              let decoded = try? JSONDecoder().decode([String: MatchScoreTip].self, from: data) else { return [:] }
        return decoded
    }

    /// Persists the demo rivals.
    private func persistBots() {
        let raw = botEntries.map {
            ["id": $0.id, "name": $0.name, "points": "\($0.points)", "correct": "\($0.correct)", "total": "\($0.total)"]
        }
        defaults.set(raw, forKey: Keys.bots)
    }

    /// Reads winner tips.
    private static func loadTips(from defaults: UserDefaults) -> [String: MatchTip] {
        guard let data = defaults.data(forKey: Keys.tips),
              let decoded = try? JSONDecoder().decode([String: MatchTip].self, from: data) else { return [:] }
        return decoded
    }

    /// Reads community vote counts.
    private static func loadVotes(from defaults: UserDefaults) -> [String: MatchTipVotes] {
        guard let data = defaults.data(forKey: Keys.votes),
              let decoded = try? JSONDecoder().decode([String: MatchTipVotes].self, from: data) else { return [:] }
        return decoded
    }

    /// Reads the demo rivals.
    private static func loadBots(from defaults: UserDefaults) -> [TipLeaderboardEntry] {
        guard let raw = defaults.array(forKey: Keys.bots) as? [[String: String]] else { return [] }
        return raw.compactMap { row in
            guard let id = row["id"], let name = row["name"],
                  let points = Int(row["points"] ?? ""),
                  let correct = Int(row["correct"] ?? ""),
                  let total = Int(row["total"] ?? "") else { return nil }
            return TipLeaderboardEntry(id: id, name: name, points: points, correct: correct, total: total, isCurrentUser: false)
        }
    }

    /// Creates the default set of demo rivals for an empty leaderboard.
    private static func makeBots() -> [TipLeaderboardEntry] {
        let names = [
            "Extraliga Fan", "Lední šíp", "Tipovač 88", "Hokejbal Pro",
            "Gólman Tip", "Pardubický tip", "Hostivař Ultra", "Plzeňský odhad"
        ]
        return names.enumerated().map { i, name in
            let total = 18 + i * 3
            let correct = 8 + i * 2
            return TipLeaderboardEntry(
                id: "bot-\(i)",
                name: name,
                points: correct * pointsPerCorrectTip,
                correct: correct,
                total: total,
                isCurrentUser: false
            )
        }
    }
}

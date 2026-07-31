import Foundation
import SwiftUI

enum MatchTipPick: String, Codable, Hashable, Sendable {
    case home
    case away

    var label: String {
        switch self {
        case .home: return "Domácí"
        case .away: return "Hosté"
        }
    }
}

struct MatchTip: Codable, Hashable, Sendable {
    var matchId: String
    var pick: MatchTipPick
    var createdAt: Date
    var resolved: Bool
    var isCorrect: Bool?
    var pointsAwarded: Int
}

/// Tip přesného skóre (SOUKROMÝ) — jen do žebříčku za body. Bodování `FantasyScoring`.
struct MatchScoreTip: Codable, Hashable, Sendable {
    var matchId: String
    var homeScore: Int
    var awayScore: Int
    var predictedOvertime: Bool
    var resolved: Bool
    var pointsAwarded: Int
}

struct MatchTipVotes: Codable, Hashable, Sendable {
    var matchId: String
    var homeCount: Int
    var awayCount: Int

    var total: Int { max(1, homeCount + awayCount) }
    var homePercent: Int { Int((Double(homeCount) / Double(total) * 100).rounded()) }
    var awayPercent: Int { max(0, 100 - homePercent) }
}

struct TipLeaderboardEntry: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let points: Int
    let correct: Int
    let total: Int
    let isCurrentUser: Bool

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}

@MainActor
final class MatchTipStore: ObservableObject {
    static let pointsPerCorrectTip = 3
    static let competitionSlug = "extraliga"

    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    @Published private(set) var tips: [String: MatchTip] = [:] {
        didSet { persistTips() }
    }

    @Published private(set) var votes: [String: MatchTipVotes] = [:] {
        didSet { persistVotes() }
    }

    /// Tipy přesného skóre (soukromé) — klíč = matchId.
    @Published private(set) var scoreTips: [String: MatchScoreTip] = [:] {
        didSet { persistScoreTips() }
    }

    @Published private(set) var botEntries: [TipLeaderboardEntry] = []

    /// Reálný žebříček ze serveru (tip_leaderboard). Prázdný = fallback na boty.
    @Published private(set) var remoteLeaderboard: [TipLeaderboardEntry] = []

    private let defaults = UserDefaults.standard
    private let userId = "local-user"

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

    func isExtraliga(_ match: Match, competitions: [Competition]) -> Bool {
        if let comp = competitions.first(where: { $0.id == match.competitionId }) {
            return comp.slug == Self.competitionSlug
        }
        return match.competitionId.contains("extraliga")
    }

    func canTip(_ match: Match) -> Bool {
        match.status == .scheduled && Date() < match.scheduledAt
    }

    func tip(for matchId: String) -> MatchTip? { tips[matchId] }

    /// Read-only — nikdy nemutuje při čtení z View body.
    func votes(for matchId: String) -> MatchTipVotes {
        votes[matchId] ?? seedVotes(matchId: matchId)
    }

    /// Seed komunitních hlasů — volat z onAppear / placeTip, ne z body.
    func ensureVotes(matchId: String) {
        if votes[matchId] == nil {
            votes[matchId] = seedVotes(matchId: matchId)
        }
        Task { await refreshVotesFromRemote(matchId: matchId) }
    }

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
            // přesun hlasu
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

    // MARK: - Tip skóre (soukromý)

    func scoreTip(for matchId: String) -> MatchScoreTip? { scoreTips[matchId] }

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

    /// Vyhodnotí tipy skóre pro dokončené zápasy (body dle `FantasyScoring`).
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

    // MARK: - Reálný žebříček

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

    /// Vyhodnotí tipy pro dokončené zápasy.
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

    var myTips: [MatchTip] { Array(tips.values) }

    var totalTips: Int { tips.count }
    var resolvedTips: Int { tips.values.filter(\.resolved).count }
    var correctTips: Int { tips.values.filter { $0.isCorrect == true }.count }
    var openTips: Int { tips.values.filter { !$0.resolved }.count }
    var seasonPoints: Int { tips.values.reduce(0) { $0 + $1.pointsAwarded } }

    /// Body z tipů skóre (soukromé) a celkové body do žebříčku.
    var scoreTipPoints: Int { scoreTips.values.reduce(0) { $0 + $1.pointsAwarded } }
    var combinedPoints: Int { seasonPoints + scoreTipPoints }
    var openScoreTips: Int { scoreTips.values.filter { !$0.resolved }.count }

    var accuracy: Double {
        guard resolvedTips > 0 else { return 0 }
        return Double(correctTips) / Double(resolvedTips) * 100
    }

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

    var leaderboard: [TipLeaderboardEntry] {
        let sortRule: (TipLeaderboardEntry, TipLeaderboardEntry) -> Bool = {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.correct != $1.correct { return $0.correct > $1.correct }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        // Reálný žebříček ze serveru má přednost; jinak lokální demo s boty.
        if !remoteLeaderboard.isEmpty {
            var rows = remoteLeaderboard
            if AuthAccess.store?.isAuthenticated == true, !rows.contains(where: \.isCurrentUser) {
                rows.append(myLeaderboardEntry)
            }
            return rows.sorted(by: sortRule)
        }
        return (botEntries + [myLeaderboardEntry]).sorted(by: sortRule)
    }

    var myRank: Int {
        leaderboard.firstIndex(where: \.isCurrentUser).map { $0 + 1 } ?? leaderboard.count
    }

    // MARK: - Private

    private func seedVotes(matchId: String) -> MatchTipVotes {
        // Stabilní „komunitní“ základ podle id zápasu
        var hash: UInt64 = 5381
        for b in matchId.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(b) }
        let total = Int(80 + (hash % 220))
        let homeShare = 0.35 + Double(hash % 30) / 100.0 // 35–64 %
        let home = max(1, Int(Double(total) * homeShare))
        let away = max(1, total - home)
        return MatchTipVotes(matchId: matchId, homeCount: home, awayCount: away)
    }

    private func persistTips() {
        if let data = try? JSONEncoder().encode(tips) {
            defaults.set(data, forKey: Keys.tips)
        }
    }

    private func persistVotes() {
        if let data = try? JSONEncoder().encode(votes) {
            defaults.set(data, forKey: Keys.votes)
        }
    }

    private func persistScoreTips() {
        if let data = try? JSONEncoder().encode(scoreTips) {
            defaults.set(data, forKey: Keys.scoreTips)
        }
    }

    private static func loadScoreTips(from defaults: UserDefaults) -> [String: MatchScoreTip] {
        guard let data = defaults.data(forKey: Keys.scoreTips),
              let decoded = try? JSONDecoder().decode([String: MatchScoreTip].self, from: data) else { return [:] }
        return decoded
    }

    private func persistBots() {
        let raw = botEntries.map {
            ["id": $0.id, "name": $0.name, "points": "\($0.points)", "correct": "\($0.correct)", "total": "\($0.total)"]
        }
        defaults.set(raw, forKey: Keys.bots)
    }

    private static func loadTips(from defaults: UserDefaults) -> [String: MatchTip] {
        guard let data = defaults.data(forKey: Keys.tips),
              let decoded = try? JSONDecoder().decode([String: MatchTip].self, from: data) else { return [:] }
        return decoded
    }

    private static func loadVotes(from defaults: UserDefaults) -> [String: MatchTipVotes] {
        guard let data = defaults.data(forKey: Keys.votes),
              let decoded = try? JSONDecoder().decode([String: MatchTipVotes].self, from: data) else { return [:] }
        return decoded
    }

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

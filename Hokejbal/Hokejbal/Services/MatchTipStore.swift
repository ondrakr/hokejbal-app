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

    @Published private(set) var botEntries: [TipLeaderboardEntry] = []

    private let defaults = UserDefaults.standard
    private let userId = "local-user"

    private enum Keys {
        static let displayName = "hb.tips.v1.name"
        static let tips = "hb.tips.v1.tips"
        static let votes = "hb.tips.v1.votes"
        static let bots = "hb.tips.v1.bots"
    }

    init() {
        displayName = defaults.string(forKey: Keys.displayName) ?? "Tipér"
        tips = Self.loadTips(from: defaults)
        votes = Self.loadVotes(from: defaults)
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
    }

    @discardableResult
    func placeTip(match: Match, pick: MatchTipPick, competitions: [Competition]) -> String? {
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
        return nil
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
                continue
            }
            let winner: MatchTipPick = match.homeScore > match.awayScore ? .home : .away
            let correct = tip.pick == winner
            tip.resolved = true
            tip.isCorrect = correct
            tip.pointsAwarded = correct ? Self.pointsPerCorrectTip : 0
            tips[match.id] = tip
            changed = true
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

    var accuracy: Double {
        guard resolvedTips > 0 else { return 0 }
        return Double(correctTips) / Double(resolvedTips) * 100
    }

    var myLeaderboardEntry: TipLeaderboardEntry {
        TipLeaderboardEntry(
            id: userId,
            name: displayName,
            points: seasonPoints,
            correct: correctTips,
            total: resolvedTips,
            isCurrentUser: true
        )
    }

    var leaderboard: [TipLeaderboardEntry] {
        (botEntries + [myLeaderboardEntry])
            .sorted {
                if $0.points != $1.points { return $0.points > $1.points }
                if $0.correct != $1.correct { return $0.correct > $1.correct }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
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

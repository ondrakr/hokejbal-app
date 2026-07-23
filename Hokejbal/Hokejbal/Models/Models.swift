import Foundation

// MARK: - Season

struct Season: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let label: String
    let sortOrder: Int
    let isCurrent: Bool
}

// MARK: - Competition

struct Competition: Identifiable, Codable, Hashable, Sendable {
    let id: String
    /// Stabilní identifikátor typu soutěže napříč ročníky (`extraliga`, `1liga`…).
    let slug: String
    let seasonId: String
    let name: String
    let shortName: String
    /// Zobrazovaný ročník, např. `2025/26`.
    let season: String
    let logoURL: String?
    let logoInitials: String
    let iconSystemName: String
}

// MARK: - Team (klub v kontextu soutěže/sezóny)

struct Team: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let shortName: String
    let city: String
    let primaryColorHex: String
    let logoInitials: String
    let logoURL: String?
    let competitionId: String
}

// MARK: - Player

enum PlayerPosition: String, Codable, Sendable, CaseIterable {
    case forward
    case defenseman
    case goalie

    var label: String {
        switch self {
        case .forward: return "útočník"
        case .defenseman: return "obránce"
        case .goalie: return "brankář"
        }
    }
}

struct Player: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let firstName: String
    let lastName: String
    let number: Int
    let position: PlayerPosition
    let teamId: String
    let games: Int
    let goals: Int
    let assists: Int
    let points: Int
    let penaltyMinutes: Int
    let savePercentage: Double?
    let goalsAgainstAverage: Double?
    /// Sezóna, ze které pochází aktuální statistiky (pokud je známo).
    var seasonId: String? = nil
    var seasonLabel: String? = nil
    var competitionId: String? = nil

    var fullName: String { "\(firstName) \(lastName)" }
    var shortName: String { "\(firstName.prefix(1)). \(lastName)" }
}

/// Statistiky hráče v konkrétní sezóně / soutěži (historie napříč ročníky).
struct PlayerSeasonStat: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let playerId: String
    let clubId: String
    let competitionId: String
    let seasonId: String
    let seasonLabel: String
    let competitionName: String
    let number: Int
    let position: PlayerPosition
    let games: Int
    let goals: Int
    let assists: Int
    let points: Int
    let penaltyMinutes: Int
    let savePercentage: Double?
    let goalsAgainstAverage: Double?
}

/// Účast klubu v sezóně (tabulka + soutěž) — historie týmu.
struct ClubSeasonRecord: Identifiable, Hashable, Sendable {
    var id: String { competitionId }
    let seasonId: String
    let seasonLabel: String
    let competitionId: String
    let competitionName: String
    let standing: StandingRow?
}

// MARK: - Match

enum MatchStatus: String, Codable, Sendable {
    case scheduled
    case live
    case finished
    case postponed
}

enum CompetitionPhase: String, Codable, Sendable, Hashable {
    case regular = "regular"
    case playoffs = "playoffs"

    var label: String {
        switch self {
        case .regular: return "Základní část"
        case .playoffs: return "Play-off"
        }
    }
}

enum MatchPeriod: String, Codable, Sendable {
    case notStarted = ""
    case first = "1. třetina"
    case second = "2. třetina"
    case third = "3. třetina"
    case overtime = "Prodloužení"
    case shootout = "Nájezdy"
    case finished = "Konec"
    case intermission = "Přestávka"
}

struct MatchEvent: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case goal
        case penalty
        case periodStart
        case periodEnd
    }

    let id: String
    let kind: Kind
    let minute: Int
    let second: Int
    let teamId: String
    let playerId: String?
    let assistIds: [String]
    let description: String
    let period: Int
}

struct Match: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let competitionId: String
    let homeTeamId: String
    let awayTeamId: String
    let scheduledAt: Date
    var status: MatchStatus
    var period: MatchPeriod
    var clock: String?
    var phase: CompetitionPhase?
    var homeScore: Int
    var awayScore: Int
    var homePeriodScores: [Int]
    var awayPeriodScores: [Int]
    var venue: String
    var round: Int
    var events: [MatchEvent]
    var attendance: Int?
    /// URL živého vysílání (pokud se zápas streamuje).
    var streamURL: String? = nil
    /// Popisek vysílání (např. „ČT Sport“, „YouTube ČMSHb“).
    var streamLabel: String? = nil
    var homeShots: Int? = nil
    var awayShots: Int? = nil
    var homePowerplayGoals: Int? = nil
    var awayPowerplayGoals: Int? = nil
    var homeShorthandedGoals: Int? = nil
    var awayShorthandedGoals: Int? = nil
    /// Jména rozhodčích oddělená čárkou.
    var referees: String? = nil

    var scoreText: String { "\(homeScore):\(awayScore)" }
    var isLive: Bool { status == .live }
    var isFinished: Bool { status == .finished }
    var phaseOrDefault: CompetitionPhase { phase ?? .regular }
    var isBroadcast: Bool {
        if let streamURL, !streamURL.isEmpty { return true }
        return false
    }

    var homePenaltyCount: Int {
        events.filter { $0.kind == .penalty && $0.teamId == homeTeamId }.count
    }

    var awayPenaltyCount: Int {
        events.filter { $0.kind == .penalty && $0.teamId == awayTeamId }.count
    }

    /// Přesilovky = vyloučení soupeře.
    var homePowerplayCount: Int { awayPenaltyCount }
    var awayPowerplayCount: Int { homePenaltyCount }
}

// MARK: - Standing

struct StandingRow: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let rank: Int
    let teamId: String
    let played: Int
    let wins: Int
    let overtimeWins: Int
    let overtimeLosses: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let points: Int

    var goalDiff: Int { goalsFor - goalsAgainst }
    var scoreText: String { "\(goalsFor):\(goalsAgainst)" }
}

// MARK: - News

struct NewsArticle: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let category: String
    let publishedAt: Date
    let summary: String
    let imageGradientIndex: Int
}

// MARK: - API DTOs

struct LiveMatchesResponse: Codable, Sendable {
    let matches: [Match]
    let updatedAt: Date
    let cursor: String?
}

struct MatchesQuery: Sendable {
    var competitionId: String?
    var seasonId: String?
    var date: Date?
    var status: MatchStatus?
    var teamId: String?
}

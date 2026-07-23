import Foundation

/// Starý stub na oficiální REST — ponecháno jen jako reference.
/// Produkční zdroj dat je `SupabaseHokejbalAPI`.
@available(*, deprecated, message: "Použijte SupabaseHokejbalAPI")
actor RemoteHokejbalAPI: HokejbalAPI {
    static let defaultBaseURL = URL(string: "https://api.hokejbal.cz/v1")!

    func seasons() async throws -> [Season] { throw APIError.notConfigured }
    func competitions(seasonId: String?) async throws -> [Competition] { throw APIError.notConfigured }
    func teams(competitionId: String?) async throws -> [Team] { throw APIError.notConfigured }
    func players(teamId: String?) async throws -> [Player] { throw APIError.notConfigured }
    func players(teamId: String?, seasonId: String?, competitionId: String?) async throws -> [Player] { throw APIError.notConfigured }
    func matches(query: MatchesQuery) async throws -> [Match] { throw APIError.notConfigured }
    func liveMatches(since cursor: String?) async throws -> LiveMatchesResponse { throw APIError.notConfigured }
    func matchDetail(id: String) async throws -> Match { throw APIError.notFound }
    func standings(competitionId: String) async throws -> [StandingRow] { throw APIError.notConfigured }
    func news(limit: Int) async throws -> [NewsArticle] { throw APIError.notConfigured }
    func player(id: String) async throws -> Player { throw APIError.notFound }
    func team(id: String) async throws -> Team { throw APIError.notFound }
    func playerHistory(playerId: String) async throws -> [PlayerSeasonStat] { throw APIError.notConfigured }
    func clubSeasonHistory(clubId: String) async throws -> [ClubSeasonRecord] { throw APIError.notConfigured }
}

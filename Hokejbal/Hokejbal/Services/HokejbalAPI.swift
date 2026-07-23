import Foundation

/// Kontrakt datové vrstvy — Mock (offline) nebo Supabase (produkce).
protocol HokejbalAPI: Sendable {
    func seasons() async throws -> [Season]
    func competitions(seasonId: String?) async throws -> [Competition]
    func teams(competitionId: String?) async throws -> [Team]
    func players(teamId: String?) async throws -> [Player]
    func players(teamId: String?, seasonId: String?, competitionId: String?) async throws -> [Player]
    func matches(query: MatchesQuery) async throws -> [Match]
    func liveMatches(since cursor: String?) async throws -> LiveMatchesResponse
    func matchDetail(id: String) async throws -> Match
    func standings(competitionId: String) async throws -> [StandingRow]
    func news(limit: Int) async throws -> [NewsArticle]
    func player(id: String) async throws -> Player
    func team(id: String) async throws -> Team
    func playerHistory(playerId: String) async throws -> [PlayerSeasonStat]
    func clubSeasonHistory(clubId: String) async throws -> [ClubSeasonRecord]
}

enum APIError: LocalizedError {
    case notFound
    case notConfigured
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Položka nebyla nalezena."
        case .notConfigured: return "API není nakonfigurované."
        case .decoding(let error): return "Chyba dekódování: \(error.localizedDescription)"
        case .network(let error): return error.localizedDescription
        }
    }
}

enum DataSource: String, CaseIterable, Identifiable {
    case supabase
    case mock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supabase: return "Supabase (online)"
        case .mock: return "Lokální data (mock)"
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    @Published var source: DataSource {
        didSet {
            UserDefaults.standard.set(source.rawValue, forKey: "hb.dataSource")
            cachedAPI = nil
        }
    }

    private var cachedAPI: (any HokejbalAPI)?

    var api: any HokejbalAPI {
        if let cachedAPI { return cachedAPI }
        let created: any HokejbalAPI = source == .mock
            ? MockHokejbalAPI.shared
            : SupabaseHokejbalAPI()
        cachedAPI = created
        return created
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "hb.dataSource") ?? DataSource.mock.rawValue
        // Migrace ze starého „remote“
        if raw == "remote" {
            source = .supabase
        } else {
            source = DataSource(rawValue: raw) ?? .mock
        }
    }
}

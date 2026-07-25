import Foundation
import SwiftUI

/// Sdílená cache zápasů sezóny — Home / Zápasy / Oblíbené nesmí tahat stejná data 3×.
@MainActor
final class MatchListCache: ObservableObject {
    static let shared = MatchListCache()

    @Published private(set) var seasonMatches: [Match] = []

    private var cacheKey: String?
    private var inFlight: Task<[Match], Never>?
    private var competitionCache: [String: [Match]] = [:]
    private var competitionInFlight: [String: Task<[Match], Never>] = [:]

    func seasonMatches(using api: any HokejbalAPI, seasonId: String?) async -> [Match] {
        let key = "season:\(seasonId ?? "all")"
        if cacheKey == key, !seasonMatches.isEmpty {
            return seasonMatches
        }
        if let inFlight {
            return await inFlight.value
        }
        let task = Task<[Match], Never> {
            let list = (try? await api.matches(query: MatchesQuery(seasonId: seasonId))) ?? []
            return list
        }
        inFlight = task
        let list = await task.value
        seasonMatches = list
        cacheKey = key
        inFlight = nil
        return list
    }

    func matches(competitionId: String, using api: any HokejbalAPI) async -> [Match] {
        if let cached = competitionCache[competitionId] { return cached }
        if let existing = competitionInFlight[competitionId] {
            return await existing.value
        }
        let task = Task<[Match], Never> {
            (try? await api.matches(query: MatchesQuery(competitionId: competitionId))) ?? []
        }
        competitionInFlight[competitionId] = task
        let list = await task.value
        competitionCache[competitionId] = list
        competitionInFlight[competitionId] = nil
        return list
    }

    func invalidate() {
        seasonMatches = []
        cacheKey = nil
        inFlight = nil
        competitionCache = [:]
        competitionInFlight = [:]
    }
}

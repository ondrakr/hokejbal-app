import Foundation
import Combine

/// Polling live výsledků – funguje stejně pro mock i remote API.
@MainActor
final class LiveScoreService: ObservableObject {
    @Published private(set) var liveMatches: [Match] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isPolling = false
    @Published var errorMessage: String?

    private var cursor: String?
    private var task: Task<Void, Never>?
    private let interval: Duration
    private var previousScores: [String: String] = [:]

    var onGoal: ((Match) -> Void)?

    init(intervalSeconds: Double = 8) {
        self.interval = .seconds(intervalSeconds)
    }

    func start(using apiProvider: @escaping @MainActor () -> any HokejbalAPI) {
        stop()
        isPolling = true
        task = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.poll(api: apiProvider())
                try? await Task.sleep(for: self.interval)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isPolling = false
    }

    func pollOnce(using api: any HokejbalAPI) async {
        await poll(api: api)
    }

    private func poll(api: any HokejbalAPI) async {
        do {
            let response = try await api.liveMatches(since: cursor)
            detectGoals(in: response.matches)
            let sorted = response.matches.sorted { $0.scheduledAt < $1.scheduledAt }
            // Nepropisuj stejný stav — zbytečné překreslení celé appky.
            let changed = sorted.count != liveMatches.count
                || zip(sorted, liveMatches).contains { $0.id != $1.id || $0.scoreText != $1.scoreText || $0.clock != $1.clock }
            if changed {
                liveMatches = sorted
            }
            lastUpdated = response.updatedAt
            cursor = response.cursor
            errorMessage = nil
        } catch {
            // Remote zatím není – při mocku by chyba neměla nastat
            errorMessage = error.localizedDescription
            if liveMatches.isEmpty {
                // fallback: načti z matches?status=live
                if let matches = try? await api.matches(query: MatchesQuery(status: .live)) {
                    liveMatches = matches
                }
            }
        }
    }

    private func detectGoals(in matches: [Match]) {
        for match in matches {
            let key = match.scoreText
            if let previous = previousScores[match.id], previous != key {
                onGoal?(match)
            }
            previousScores[match.id] = key
        }
    }
}

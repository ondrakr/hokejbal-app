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
    private var previousScores: [String: (home: Int, away: Int)] = [:]
    private var previousStatus: [String: MatchStatus] = [:]
    private var lastKnownById: [String: Match] = [:]
    private var previouslyLiveIds: Set<String> = []
    private var finishedAnnouncedIds: Set<String> = []

    /// `(match, scoringTeamId)` — scoringTeamId je tým, který právě skóroval.
    var onGoal: ((Match, String?) -> Void)?
    var onMatchFinished: ((Match) -> Void)?

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

    /// Po změně data source — ať nevzniknou falešné góly ze starých skóre.
    func resetTrackingState() {
        previousScores = [:]
        previousStatus = [:]
        lastKnownById = [:]
        previouslyLiveIds = []
        finishedAnnouncedIds = []
        liveMatches = []
        cursor = nil
    }

    private func poll(api: any HokejbalAPI) async {
        do {
            let response = try await api.liveMatches(since: cursor)
            detectGoals(in: response.matches)
            detectFinished(in: response.matches)
            let sorted = response.matches.sorted { $0.scheduledAt < $1.scheduledAt }
            let changed = sorted.count != liveMatches.count
                || zip(sorted, liveMatches).contains {
                    $0.id != $1.id
                        || $0.scoreText != $1.scoreText
                        || $0.clock != $1.clock
                        || $0.status != $1.status
                }
            if changed {
                liveMatches = sorted
            }
            lastUpdated = response.updatedAt
            cursor = response.cursor
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            if liveMatches.isEmpty {
                if let matches = try? await api.matches(query: MatchesQuery(status: .live)) {
                    detectGoals(in: matches)
                    detectFinished(in: matches)
                    liveMatches = matches
                }
            }
        }
    }

    private func detectGoals(in matches: [Match]) {
        for match in matches {
            let current = (home: match.homeScore, away: match.awayScore)
            if let previous = previousScores[match.id], match.status == .live {
                let homeUp = current.home > previous.home
                let awayUp = current.away > previous.away
                if homeUp || awayUp {
                    var scoringId: String? = homeUp ? match.homeTeamId : match.awayTeamId
                    if homeUp && awayUp {
                        scoringId = match.events.last(where: { $0.kind == .goal })?.teamId
                    } else if let lastGoal = match.events.last(where: { $0.kind == .goal }) {
                        scoringId = lastGoal.teamId
                    }
                    onGoal?(match, scoringId)
                }
            }
            previousScores[match.id] = current
            lastKnownById[match.id] = match
            previousStatus[match.id] = match.status
        }
    }

    private func detectFinished(in matches: [Match]) {
        let currentLiveIds = Set(matches.filter { $0.status == .live }.map(\.id))

        for match in matches {
            lastKnownById[match.id] = match

            if match.status == .finished,
               !finishedAnnouncedIds.contains(match.id),
               (previousStatus[match.id] == .live || previouslyLiveIds.contains(match.id)) {
                finishedAnnouncedIds.insert(match.id)
                onMatchFinished?(match)
            }
            previousStatus[match.id] = match.status
        }

        for id in previouslyLiveIds where !currentLiveIds.contains(id) {
            guard !finishedAnnouncedIds.contains(id), var known = lastKnownById[id] else { continue }
            finishedAnnouncedIds.insert(id)
            known.status = .finished
            lastKnownById[id] = known
            onMatchFinished?(known)
        }

        previouslyLiveIds = currentLiveIds
    }
}

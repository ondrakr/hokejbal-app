import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var seasons: SeasonStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var notifications: NotificationSettingsStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @EnvironmentObject private var matchAlerts: MatchAlertsStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Domů", systemImage: "house.fill") }

            MatchesByCompetitionView()
                .tabItem { Label("Zápasy", systemImage: "sportscourt") }

            NavigationStack {
                LiveView()
            }
            .tabItem { Label("LIVE", systemImage: "dot.radiowaves.left.and.right") }

            FavoritesView()
                .tabItem { Label("Oblíbené", systemImage: "star.fill") }

            MoreView()
                .tabItem { Label("Více", systemImage: "ellipsis.circle.fill") }
        }
        .tint(HBTheme.brand)
        .toolbarBackground(HBTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            await seasons.load(using: apiClient.api)
            let currentSeasonId = seasons.seasons.first(where: \.isCurrent)?.id ?? seasons.seasons.first?.id
            seasons.selectedSeasonId = currentSeasonId
            await catalog.load(using: apiClient.api, seasonId: currentSeasonId)
            competitionOrder.sync(with: catalog.competitions)

            liveScores.onGoal = { [weak notifications, weak catalog, weak matchAlerts] match in
                guard let notifications, notifications.goalsEnabled else { return }
                guard let matchAlerts, matchAlerts.isEnabled(matchId: match.id) else { return }
                let home = catalog?.team(match.homeTeamId)?.shortName ?? "?"
                let away = catalog?.team(match.awayTeamId)?.shortName ?? "?"
                notifications.scheduleDemoGoalNotification(home: home, away: away, score: match.scoreText)
            }
            liveScores.start { apiClient.api }
            await notifications.refreshAuthorization()

            try? await Task.sleep(for: .milliseconds(800))
            await catalog.loadPlayersIfNeeded(using: apiClient.api, seasonId: currentSeasonId)
        }
        .onChange(of: apiClient.source) { _, _ in
            Task {
                await seasons.load(using: apiClient.api)
                let currentSeasonId = seasons.seasons.first(where: \.isCurrent)?.id ?? seasons.seasons.first?.id
                seasons.selectedSeasonId = currentSeasonId
                await catalog.load(using: apiClient.api, seasonId: currentSeasonId)
                competitionOrder.sync(with: catalog.competitions)
                await liveScores.pollOnce(using: apiClient.api)
                await catalog.loadPlayersIfNeeded(using: apiClient.api, seasonId: currentSeasonId)
            }
        }
        .onChange(of: catalog.competitions) { _, comps in
            competitionOrder.sync(with: comps)
        }
    }
}

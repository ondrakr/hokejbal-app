import SwiftUI

/// Přepínání spodních záložek z jiných obrazovek (např. „Vše" na Domů).
@MainActor
final class AppTabRouter: ObservableObject {
    enum Tab: Int { case home = 0, matches, live, favorites, more }
    @Published var selection: Int = Tab.home.rawValue

    func select(_ tab: Tab) { selection = tab.rawValue }
}

struct MainTabView: View {
    @EnvironmentObject private var tabRouter: AppTabRouter
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var seasons: SeasonStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var notifications: NotificationSettingsStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @EnvironmentObject private var matchAlerts: MatchAlertsStore

    var body: some View {
        TabView(selection: $tabRouter.selection) {
            HomeView()
                .tag(AppTabRouter.Tab.home.rawValue)
                .tabItem { Label("Domů", systemImage: "house.fill") }

            MatchesByCompetitionView()
                .tag(AppTabRouter.Tab.matches.rawValue)
                .tabItem { Label("Zápasy", systemImage: "sportscourt") }

            NavigationStack {
                LiveView()
            }
            .tag(AppTabRouter.Tab.live.rawValue)
            .tabItem { Label("LIVE", systemImage: "dot.radiowaves.left.and.right") }

            FavoritesView()
                .tag(AppTabRouter.Tab.favorites.rawValue)
                .tabItem { Label("Oblíbené", systemImage: "star.fill") }

            MoreView()
                .tag(AppTabRouter.Tab.more.rawValue)
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

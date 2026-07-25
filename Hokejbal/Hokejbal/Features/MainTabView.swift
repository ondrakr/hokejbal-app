import SwiftUI

/// Přepínání spodních záložek z jiných obrazovek (např. „Vše" na Domů).
@MainActor
final class AppTabRouter: ObservableObject {
    enum Tab: Int { case home = 0, matches, live, favorites, more }

    enum LiveFilter: String, CaseIterable, Hashable {
        case all = "Vše"
        case broadcasts = "Živé přenosy"
    }

    @Published var selection: Int = Tab.home.rawValue
    @Published var liveFilter: LiveFilter = .all

    func select(_ tab: Tab) { selection = tab.rawValue }

    func selectLive(filter: LiveFilter = .all) {
        liveFilter = filter
        selection = Tab.live.rawValue
    }
}

private struct InAppMatchRoute: Identifiable, Hashable {
    let id: String
}

struct MainTabView: View {
    @EnvironmentObject private var tabRouter: AppTabRouter
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var matchAlerts: MatchAlertsStore
    @EnvironmentObject private var idleTimer: IdleTimerController
    @EnvironmentObject private var banners: InAppBannerCenter
    @EnvironmentObject private var tips: MatchTipStore

    @State private var presentedMatch: InAppMatchRoute?

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
        .overlay(alignment: .top) {
            InAppBannerOverlay()
                .zIndex(1000)
        }
        .onChange(of: tabRouter.selection) { _, _ in
            idleTimer.allowSleep()
        }
        .onChange(of: banners.openMatchId) { _, matchId in
            guard let matchId else { return }
            presentedMatch = InAppMatchRoute(id: matchId)
            _ = banners.consumeOpenMatch()
        }
        .sheet(item: $presentedMatch) { route in
            NavigationStack {
                MatchDetailView(matchId: route.id)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Zavřít") { presentedMatch = nil }
                        }
                    }
            }
            .environmentObject(apiClient)
            .environmentObject(catalog)
            .environmentObject(liveScores)
            .environmentObject(matchAlerts)
            .environmentObject(favorites)
            .environmentObject(banners)
            .environmentObject(tips)
        }
    }
}

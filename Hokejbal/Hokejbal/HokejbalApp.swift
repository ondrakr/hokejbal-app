import SwiftUI

@main
struct HokejbalApp: App {
    @StateObject private var apiClient = APIClient.shared
    @StateObject private var catalog = CatalogStore()
    @StateObject private var seasons = SeasonStore()
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var notifications = NotificationSettingsStore()
    @StateObject private var liveScores = LiveScoreService()
    @StateObject private var appearanceStore = AppearanceStore()
    @StateObject private var competitionOrder = CompetitionOrderStore()
    @StateObject private var matchAlerts = MatchAlertsStore()
    @StateObject private var tabRouter = AppTabRouter()

    init() {
        HBAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(apiClient)
                .environmentObject(catalog)
                .environmentObject(seasons)
                .environmentObject(favorites)
                .environmentObject(notifications)
                .environmentObject(liveScores)
                .environmentObject(appearanceStore)
                .environmentObject(competitionOrder)
                .environmentObject(matchAlerts)
                .environmentObject(tabRouter)
                .tint(HBTheme.brand)
                .preferredColorScheme(appearanceStore.appearance.colorScheme)
                .background(HBTheme.surface)
        }
    }
}

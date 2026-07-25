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
    @StateObject private var idleTimer = IdleTimerController()
    @StateObject private var homeMatchFeed = HomeMatchFeedStore()
    @StateObject private var fantasySquad = FantasySquadStore()
    @StateObject private var amateurTournaments = AmateurTournamentStore()
    @StateObject private var matchTips = MatchTipStore()
    @StateObject private var inAppBanners = InAppBannerCenter()
    @StateObject private var auth = AuthStore()
    @StateObject private var brandStore = AppBrandStore()

    init() {
        HBAppearance.apply()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
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
                .environmentObject(idleTimer)
                .environmentObject(homeMatchFeed)
                .environmentObject(fantasySquad)
                .environmentObject(amateurTournaments)
                .environmentObject(matchTips)
                .environmentObject(inAppBanners)
                .environmentObject(auth)
                .environmentObject(brandStore)
                .tint(HBTheme.brand)
                .preferredColorScheme(appearanceStore.appearance.colorScheme)
                .background(HBTheme.canvas)
                .onAppear {
                    IdleTimerAccess.controller = idleTimer
                    AuthAccess.store = auth
                    idleTimer.allowSleep()
                }
        }
    }
}

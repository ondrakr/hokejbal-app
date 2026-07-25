import SwiftUI

/// Kořen aplikace — nejdřív logo, po načtení kritických dat MainTabView.
struct AppRootView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var seasons: SeasonStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @EnvironmentObject private var homeMatchFeed: HomeMatchFeedStore
    @EnvironmentObject private var notifications: NotificationSettingsStore
    @EnvironmentObject private var matchAlerts: MatchAlertsStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var banners: InAppBannerCenter
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var matchTips: MatchTipStore
    @EnvironmentObject private var amateurTournaments: AmateurTournamentStore
    @EnvironmentObject private var brandStore: AppBrandStore

    @State private var isReady = false
    @State private var didWireLiveHandlers = false

    var body: some View {
        ZStack {
            if isReady {
                Group {
                    switch brandStore.brand {
                    case .hokejbal:
                        MainTabView()
                    case .cmshb:
                        CMSHBBrowserShell()
                    }
                }
                .transition(.opacity)
                .id(brandStore.brand)
            } else {
                BrandLoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isReady)
        .animation(.easeInOut(duration: 0.25), value: brandStore.brand)
        .hbAuthSheet(auth, catalog: catalog)
        .task {
            await bootstrap()
        }
        .onChange(of: apiClient.source) { _, _ in
            MatchListCache.shared.invalidate()
            liveScores.resetTrackingState()
            Task { await reloadAfterSourceChange() }
        }
        .onChange(of: catalog.competitions) { _, comps in
            competitionOrder.sync(with: comps)
        }
        .onChange(of: auth.isAuthenticated) { _, loggedIn in
            Task {
                if loggedIn {
                    await favorites.syncFromRemote(using: auth)
                    await matchTips.syncMyTipsFromRemote()
                    if let club = auth.profile?.favoriteClubId {
                        favorites.addTeam(club)
                    }
                    await amateurTournaments.pullRemote(using: auth)
                }
            }
        }
    }

    @MainActor
    private func bootstrap() async {
        let started = Date()

        AuthAccess.store = auth
        await auth.bootstrap()

        await seasons.load(using: apiClient.api)
        let currentSeasonId = seasons.seasons.first(where: \.isCurrent)?.id
            ?? seasons.seasons.first?.id
        seasons.selectedSeasonId = currentSeasonId

        await catalog.load(using: apiClient.api, seasonId: currentSeasonId)
        competitionOrder.sync(with: catalog.competitions)
        homeMatchFeed.seedDefaultsIfNeeded(competitions: catalog.competitions)

        if auth.isAuthenticated {
            await favorites.syncFromRemote(using: auth)
            await matchTips.syncMyTipsFromRemote()
            if let club = auth.profile?.favoriteClubId {
                favorites.addTeam(club)
            }
        }
        await amateurTournaments.pullRemote(using: auth)

        wireLiveHandlersIfNeeded()
        liveScores.start { apiClient.api }
        await liveScores.pollOnce(using: apiClient.api)
        await notifications.refreshAuthorization()

        // Krátké minimum, ať splash neblikne.
        let elapsed = Date().timeIntervalSince(started)
        if elapsed < 0.45 {
            try? await Task.sleep(for: .milliseconds(Int((0.45 - elapsed) * 1000)))
        }

        isReady = true

        // Hráči na pozadí — hlavní UI na ně nečeká.
        Task {
            await catalog.loadPlayersIfNeeded(using: apiClient.api, seasonId: currentSeasonId)
        }
    }

    @MainActor
    private func reloadAfterSourceChange() async {
        await seasons.load(using: apiClient.api)
        let currentSeasonId = seasons.seasons.first(where: \.isCurrent)?.id
            ?? seasons.seasons.first?.id
        seasons.selectedSeasonId = currentSeasonId
        await catalog.load(using: apiClient.api, seasonId: currentSeasonId)
        competitionOrder.sync(with: catalog.competitions)
        homeMatchFeed.seedDefaultsIfNeeded(competitions: catalog.competitions)
        await liveScores.pollOnce(using: apiClient.api)
        await catalog.loadPlayersIfNeeded(using: apiClient.api, seasonId: currentSeasonId)
    }

    private func wireLiveHandlersIfNeeded() {
        guard !didWireLiveHandlers else { return }
        didWireLiveHandlers = true

        liveScores.onGoal = { [weak notifications, weak catalog, weak matchAlerts, weak favorites, weak banners] match, scoringTeamId in
            guard let notifications, let matchAlerts, let favorites, let banners else { return }
            guard !banners.isViewingMatch(match.id) else { return }
            guard notifications.goalsEnabled else { return }
            guard notifications.shouldNotify(match: match, matchAlerts: matchAlerts, favorites: favorites) else { return }
            let home = catalog?.team(match.homeTeamId)?.shortName ?? "?"
            let away = catalog?.team(match.awayTeamId)?.shortName ?? "?"
            banners.present(
                kind: .goal,
                match: match,
                homeName: home,
                awayName: away,
                scoringTeamId: scoringTeamId
            )
            notifications.scheduleDemoGoalNotification(home: home, away: away, score: match.scoreText, matchId: match.id)
        }

        liveScores.onMatchFinished = { [weak notifications, weak catalog, weak matchAlerts, weak favorites, weak banners] match in
            guard let notifications, let matchAlerts, let favorites, let banners else { return }
            guard !banners.isViewingMatch(match.id) else { return }
            guard notifications.finalScoreEnabled else { return }
            guard notifications.shouldNotify(match: match, matchAlerts: matchAlerts, favorites: favorites) else { return }
            let home = catalog?.team(match.homeTeamId)?.shortName ?? "?"
            let away = catalog?.team(match.awayTeamId)?.shortName ?? "?"
            banners.present(kind: .finalScore, match: match, homeName: home, awayName: away)
            notifications.scheduleDemoFinalNotification(home: home, away: away, score: match.scoreText, matchId: match.id)
        }
    }
}

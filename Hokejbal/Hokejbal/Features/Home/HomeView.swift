import SwiftUI

private struct HomeMatchRoute: Identifiable, Hashable {
    let id: String
}

// MARK: - Home content models

struct HomeBanner: Identifiable, Hashable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let ctaTitle: String
    let url: URL?
    let gradientIndex: Int
}

struct HomeVideo: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let dateLabel: String
    let url: URL
    let gradientIndex: Int
    var sourceLabel: String = "HOKEJBAL TV"
}

struct HomePartner: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let url: URL
}

enum HomeContent {
    static let banners: [HomeBanner] = []

    static let delniciChannelURL = URL(string: "https://www.youtube.com/@delnicihokejbalu")!

    /// Videa z YouTube kanálu Dělníci hokejbalu.
    static let worldVideos: [HomeVideo] = [
        .init(
            id: "dh019",
            title: "Doba stříbrná! Jaká byla Ostrava? MS v Bánské je za námi! | DH #019",
            dateLabel: "Dělníci hokejbalu",
            url: URL(string: "https://www.youtube.com/watch?v=MJJCSt8dr6E")!,
            gradientIndex: 0,
            sourceLabel: "DĚLNÍCI"
        ),
        .init(
            id: "dh-sipky",
            title: "Slib splněn! Kdo je teda lepší v šipkách? | DH",
            dateLabel: "Dělníci hokejbalu",
            url: URL(string: "https://www.youtube.com/watch?v=BTvWi0HxN6Q")!,
            gradientIndex: 1,
            sourceLabel: "DĚLNÍCI"
        ),
        .init(
            id: "dh-pascuzzo",
            title: "Elio Pascuzzo, prezident ISBHF | DH",
            dateLabel: "Dělníci hokejbalu",
            url: URL(string: "https://www.youtube.com/watch?v=VYGqOhzF-K0")!,
            gradientIndex: 2,
            sourceLabel: "DĚLNÍCI"
        ),
        .init(
            id: "dh-kabina",
            title: "Prohlídka kabiny s Lucií Kubinovou a Terezou Radovou | DH",
            dateLabel: "Dělníci hokejbalu",
            url: URL(string: "https://www.youtube.com/watch?v=BzUQc9Ju_DA")!,
            gradientIndex: 3,
            sourceLabel: "DĚLNÍCI"
        ),
        .init(
            id: "dh-wrobel",
            title: "Tomáš Wróbel a jeho poslední MS? | DH",
            dateLabel: "Dělníci hokejbalu",
            url: URL(string: "https://www.youtube.com/watch?v=p76vKGaC4Bs")!,
            gradientIndex: 0,
            sourceLabel: "DĚLNÍCI"
        ),
        .init(
            id: "dh-bydleni",
            title: "Jak bydlí naši reprezentanti? Pojďte se s námi podívat! | DH",
            dateLabel: "Dělníci hokejbalu",
            url: URL(string: "https://www.youtube.com/watch?v=mJaKifAmi9w")!,
            gradientIndex: 1,
            sourceLabel: "DĚLNÍCI"
        )
    ]

    /// Kompatibilita se starším MediaView.
    static var videos: [HomeVideo] { worldVideos }

    static let partners: [HomePartner] = [
        .init(id: "p1", name: "ČMSHb", url: URL(string: "https://www.hokejbal.cz")!),
        .init(id: "p2", name: "Fantasy", url: URL(string: "https://hokejbal-fantasy.cz")!),
        .init(id: "p3", name: "Hokejbal TV", url: URL(string: "https://www.youtube.com/@hokejbal")!),
        .init(id: "p4", name: "Dělníci hokejbalu", url: delniciChannelURL),
        .init(id: "p5", name: "Partneři", url: URL(string: "https://www.hokejbal.cz/partneri")!)
    ]

    static let gradients: [[Color]] = [
        [HBTheme.brand, HBTheme.brandDark],
        [Color(red: 0.12, green: 0.28, blue: 0.52), Color(red: 0.06, green: 0.14, blue: 0.28)],
        [Color(red: 0.12, green: 0.42, blue: 0.32), Color(red: 0.05, green: 0.22, blue: 0.18)],
        [Color(red: 0.48, green: 0.22, blue: 0.12), Color(red: 0.28, green: 0.1, blue: 0.06)]
    ]
}

/// Domovská stránka — hub ČMSHb: zápasy, bannery, novinky, videa, partneři.
struct HomeView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var seasons: SeasonStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var tabRouter: AppTabRouter
    @EnvironmentObject private var homeMatchFeed: HomeMatchFeedStore

    @State private var articles: [NewsArticle] = []
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var newsPage = 0
    @State private var selectedArticle: NewsArticle?
    @State private var selectedMatch: HomeMatchRoute?
    @State private var showSiteSwitch = false

    private var sliderMatches: [Match] {
        let filtered = matches.filter { homeMatchFeed.includes(match: $0, catalog: catalog) }
        let live = liveScores.liveMatches.filter { homeMatchFeed.includes(match: $0, catalog: catalog) }
        let liveIds = Set(live.map(\.id))
        let upcoming = filtered
            .filter { $0.status == .scheduled && !liveIds.contains($0.id) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
        let finished = filtered
            .filter { $0.status == .finished && !liveIds.contains($0.id) }
            .sorted { $0.scheduledAt > $1.scheduledAt }
        return Array((live + upcoming.prefix(8) + finished.prefix(6)).prefix(16))
    }

    private var featuredNews: [NewsArticle] {
        Array(articles.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    newsSection
                    liveStreamsSection
                    matchSliderSection
                    representationSection
                    worldVideosSection
                    partnersSection
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.35), value: featuredNews.isEmpty)
                .animation(.easeInOut(duration: 0.35), value: sliderMatches.isEmpty)
                .animation(.easeInOut(duration: 0.35), value: isLoading)
            }
            .background(HBTheme.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSiteSwitch = true
                    } label: {
                        Image("BrandLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Přepnout web")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        CatalogSearchView(isPresentedAsSheet: false)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                    }
                    .accessibilityLabel("Hledat")

                    ProfileEntryLink()
                }
            }
            .sheet(isPresented: $showSiteSwitch) {
                SiteSwitchSheet()
            }
            .hbNavigationStyle()
            .allowScreenSleepWhileVisible()
            .onAppear { IdleTimerAccess.allowSleep() }
            .task { await load() }
            .refreshable { await load() }
            .navigationDestination(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
            .navigationDestination(item: $selectedMatch) { route in
                MatchDetailView(matchId: route.id)
            }
        }
    }

    // MARK: - Match slider

    private var matchSliderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HBSectionHeader(title: "Zápasy") {
                Button {
                    tabRouter.select(.matches)
                } label: {
                    HStack(spacing: 3) {
                        Text("Vše")
                            .font(.hbMontserrat(size: 13, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(HBTheme.brand)
                }
                .buttonStyle(.plain)
            } titleAccessory: {
                NavigationLink {
                    HomeMatchFeedSettingsView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HBTheme.brand)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Nastavit zápasy na Domů")
            }

            if !homeMatchFeed.hasSelection {
                NavigationLink {
                    HomeMatchFeedSettingsView()
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vyberte soutěže nebo týmy")
                            .font(.hbMontserrat(size: 15, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                        Text("Slider Zápasů ukáže jen to, co si nastavíte.")
                            .font(.hbMontserrat(size: 13, weight: .medium))
                            .foregroundStyle(HBTheme.textSecondary)
                        Text("Nastavit")
                            .font(.hbMontserrat(size: 13, weight: .bold))
                            .foregroundStyle(HBTheme.brand)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, HBTheme.screenPadding)
            } else if sliderMatches.isEmpty {
                if isLoading {
                    MatchSliderSkeleton()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    Text("Pro vybrané soutěže a týmy teď nejsou zápasy.")
                        .font(.hbMontserrat(size: 13, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .padding(.horizontal, HBTheme.screenPadding)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sliderMatches) { match in
                            Button {
                                selectedMatch = HomeMatchRoute(id: match.id)
                            } label: {
                                MatchRowView(
                                    match: match,
                                    home: catalog.team(match.homeTeamId),
                                    away: catalog.team(match.awayTeamId),
                                    showCompetition: true,
                                    competitionName: catalog.competitions.first { $0.id == match.competitionId }?.shortName,
                                    embedded: true
                                )
                                .frame(width: 250)
                                .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
                                .hbCard(cornerRadius: HBTheme.radiusMd)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.vertical, 2)
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Reprezentace / ISBHF

    private static let isbhfBlue = Color(red: 0 / 255, green: 89 / 255, blue: 143 / 255) // #00598F

    private var representationSection: some View {
        Button {
            ISBHFLauncher.open()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reprezentace")
                        .font(.hbDisplay(size: 22, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("Výsledky, soupisky a MS v oficiální aplikaci.")
                        .font(.hbMontserrat(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 8)

                    HStack(spacing: 6) {
                        Text("Otevřít aplikaci")
                            .font(.hbMontserrat(size: 12, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.18), in: Capsule())
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image("ISBHFLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128)
                    .accessibilityHidden(true)
            }
            .padding(.leading, 18)
            .padding(.trailing, 6)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
            .background(Self.isbhfBlue)
            .overlay(alignment: .topTrailing) {
                HBSkew(dx: 18)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 46)
                    .padding(.trailing, 72)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous))
            .hbCard(cornerRadius: HBTheme.radiusLg)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HBTheme.screenPadding)
        .accessibilityLabel("Reprezentace, otevřít aplikaci ISBHF")
    }

    // MARK: - News

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Novinky") {
                NewsView()
            }

            if featuredNews.isEmpty {
                if isLoading {
                    FeaturedNewsSkeleton()
                        .frame(height: 230, alignment: .top)
                        .transition(.opacity)
                } else {
                    Text("Momentálně nejsou novinky k zobrazení.")
                        .font(.hbMontserrat(size: 13, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .padding(.horizontal, HBTheme.screenPadding)
                        .frame(height: 180, alignment: .top)
                }
            } else {
                TabView(selection: $newsPage) {
                    ForEach(Array(featuredNews.enumerated()), id: \.element.id) { index, article in
                        Button {
                            selectedArticle = article
                        } label: {
                            featuredArticleCard(article)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, HBTheme.screenPadding)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 230)
                .transition(.opacity)
                .onChange(of: featuredNews.map(\.id)) { _, _ in
                    newsPage = 0
                }
                .task(id: featuredNews.map(\.id)) {
                    guard featuredNews.count > 1 else { return }
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        guard !Task.isCancelled, featuredNews.count > 1 else { break }
                        withAnimation(.easeInOut(duration: 0.45)) {
                            newsPage = (newsPage + 1) % featuredNews.count
                        }
                    }
                }
            }
        }
    }

    private func featuredArticleCard(_ article: NewsArticle) -> some View {
        NewsThumbnail(article: article)
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.35),
                        .black.opacity(0.25),
                        .black.opacity(0.88),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .topLeading) {
                CategoryTag(title: article.category)
                    .padding(12)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.hbDisplay(size: 19, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(article.publishedAt.hbShortDateTime)
                        .font(.hbMontserrat(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
            .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    // MARK: - Živé přenosy

    private var liveStreamsSection: some View {
        Button {
            tabRouter.selectLive(filter: .broadcasts)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HBTheme.live.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "tv.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HBTheme.live)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Živé přenosy")
                            .font(.hbMontserrat(size: 16, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                        LiveBadge(compact: true)
                    }
                    Text("Aktuální zápasy s TV vysíláním")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(16)
            .hbCard(cornerRadius: HBTheme.radiusMd)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HBTheme.screenPadding)
    }

    // MARK: - Dělníci hokejbalu

    private var worldVideosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Dělníci hokejbalu") {
                MediaView()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HomeContent.worldVideos) { video in
                        Link(destination: video.url) {
                            videoCard(video)
                        }
                        .buttonStyle(.plain)
                    }

                    Link(destination: HomeContent.delniciChannelURL) {
                        channelPromoCard
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, HBTheme.screenPadding)
            }
        }
    }

    private var channelPromoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.28, blue: 0.52),
                                Color(red: 0.06, green: 0.14, blue: 0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 260, height: 146)

                VStack(spacing: 10) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Celý kanál Dělníci hokejbalu")
                        .font(.hbMontserrat(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }

            Text("YouTube · @delnicihokejbalu")
                .font(.hbMontserrat(size: 13, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
                .frame(width: 260, alignment: .leading)
            Text("Otevřít kanál")
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textTertiary)
        }
    }

    private func videoCard(_ video: HomeVideo) -> some View {
        let colors = HomeContent.gradients[video.gradientIndex % HomeContent.gradients.count]
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 260, height: 146)

                Text(video.sourceLabel)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(HBTheme.brand.opacity(0.9), in: RoundedRectangle(cornerRadius: 4))
                    .padding(10)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text(video.title)
                .font(.hbMontserrat(size: 13, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(2)
                .frame(width: 260, alignment: .leading)
            Text(video.dateLabel)
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textTertiary)
        }
    }

    // MARK: - Partners

    private var partnersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HBSectionHeader("Partneři", accent: HBTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HomeContent.partners) { partner in
                        Link(destination: partner.url) {
                            Text(partner.name)
                                .font(.hbMontserrat(size: 13, weight: .semibold))
                                .foregroundStyle(HBTheme.textPrimary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .hbCard(cornerRadius: HBTheme.radiusSm)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader<Destination: View>(
        _ title: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        HBSectionHeader(title: title) {
            NavigationLink(destination: destination) {
                seeAllLabel
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionHeaderButton(_ title: String, action: @escaping () -> Void) -> some View {
        HBSectionHeader(title: title) {
            Button(action: action) { seeAllLabel }
                .buttonStyle(.plain)
        }
    }

    private var seeAllLabel: some View {
        HStack(spacing: 3) {
            Text("Vše")
                .font(.hbMontserrat(size: 13, weight: .bold))
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(HBTheme.brand)
    }

    private func load() async {
        isLoading = true
        defer {
            withAnimation(.easeInOut(duration: 0.35)) {
                isLoading = false
            }
        }
        async let news = apiClient.api.news(limit: 12)
        let seasonId = seasons.selectedSeasonId
        async let allMatches = MatchListCache.shared.seasonMatches(using: apiClient.api, seasonId: seasonId)
        let loadedArticles = (try? await news) ?? []
        let loadedMatches = await allMatches
        withAnimation(.easeInOut(duration: 0.35)) {
            articles = loadedArticles
            matches = loadedMatches
        }
        await liveScores.pollOnce(using: apiClient.api)
    }
}

/// Otevře aplikaci ISBHF; pokud není nainstalovaná, web isbhf.com.
enum ISBHFLauncher {
    private static let appScheme = URL(string: "isbhf://")!
    private static let website = URL(string: "https://www.isbhf.com")!

    @MainActor
    static func open() {
        if UIApplication.shared.canOpenURL(appScheme) {
            UIApplication.shared.open(appScheme)
        } else {
            UIApplication.shared.open(website)
        }
    }
}

/// Média — obsah Dělníků hokejbalu a odkazy do hokejbalového světa.
struct MediaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Link(destination: HomeContent.delniciChannelURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "headphones")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(HBTheme.brand)
                            .frame(width: 44, height: 44)
                            .background(HBTheme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Dělníci hokejbalu")
                                .font(.hbMontserrat(size: 15, weight: .bold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text("YouTube · podcast · @delnicihokejbalu")
                                .font(.hbMontserrat(size: 12, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
                }
                .buttonStyle(.plain)

                Text("Nejnovější díly")
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(HBTheme.textTertiary)
                    .padding(.top, 4)

                ForEach(HomeContent.worldVideos) { video in
                    Link(destination: video.url) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: HomeContent.gradients[video.gradientIndex % HomeContent.gradients.count],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 96, height: 64)
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.title)
                                    .font(.hbMontserrat(size: 14, weight: .semibold))
                                    .foregroundStyle(HBTheme.textPrimary)
                                    .lineLimit(3)
                                Text(video.dateLabel)
                                    .font(.hbMontserrat(size: 12, weight: .medium))
                                    .foregroundStyle(HBTheme.textTertiary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HBTheme.textTertiary)
                        }
                        .padding(12)
                        .hbCard(cornerRadius: HBTheme.radiusMd)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(HBTheme.screenPadding)
        }
        .background(HBTheme.canvas)
        .navigationTitle("Dělníci hokejbalu")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
    }
}

/// Záložka Média s vlastní navigací.
struct MediaTabView: View {
    var body: some View {
        NavigationStack {
            MediaView()
                .hbNavTitle("Média", systemImage: "play.rectangle.fill")
        }
    }
}

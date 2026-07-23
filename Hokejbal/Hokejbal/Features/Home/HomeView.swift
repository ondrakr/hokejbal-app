import SwiftUI

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
}

struct HomePartner: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let url: URL
}

enum HomeContent {
    static let banners: [HomeBanner] = [
        .init(
            id: "ms2026",
            eyebrow: "MS V HOKEJBALU 2026",
            title: "20.–28. června · Ostravar Aréna",
            subtitle: "Mistrovství světa mužů a žen v Ostravě.",
            ctaTitle: "Kupuj vstupenky",
            url: URL(string: "https://www.hokejbal.cz"),
            gradientIndex: 0
        ),
        .init(
            id: "legends2026",
            eyebrow: "MS LEGENDS 2026",
            title: "Praha-Černošice",
            subtitle: "Legendy se vrací na domácí půdu.",
            ctaTitle: "Více informací",
            url: URL(string: "https://www.hokejbal.cz"),
            gradientIndex: 1
        )
    ]

    static let videos: [HomeVideo] = [
        .init(
            id: "v1",
            title: "Highlights Play-off Extraligy | Svítkov vs Hostivař | 4. Semifinále",
            dateLabel: "11. 5. 2026",
            url: URL(string: "https://www.hokejbal.cz")!,
            gradientIndex: 0
        ),
        .init(
            id: "v2",
            title: "Highlights Play-off Extraligy | Svítkov vs Hostivař | 3. Semifinále",
            dateLabel: "9. 5. 2026",
            url: URL(string: "https://www.hokejbal.cz")!,
            gradientIndex: 1
        ),
        .init(
            id: "v3",
            title: "Hokejbal TV · sestřih kola Extraligy",
            dateLabel: "4. 5. 2026",
            url: URL(string: "https://www.hokejbal.cz")!,
            gradientIndex: 2
        )
    ]

    static let partners: [HomePartner] = [
        .init(id: "p1", name: "ČMSHb", url: URL(string: "https://www.hokejbal.cz")!),
        .init(id: "p2", name: "Fantasy", url: URL(string: "https://hokejbal-fantasy.cz")!),
        .init(id: "p3", name: "Hokejbal TV", url: URL(string: "https://www.hokejbal.cz")!),
        .init(id: "p4", name: "Partneři", url: URL(string: "https://www.hokejbal.cz/partneri")!)
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
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var tabRouter: AppTabRouter

    @State private var articles: [NewsArticle] = []
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var bannerPage = 0

    private var sliderMatches: [Match] {
        let live = liveScores.liveMatches
        let liveIds = Set(live.map(\.id))
        let upcoming = matches
            .filter { $0.status == .scheduled && !liveIds.contains($0.id) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
        let finished = matches
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
                    matchSliderSection
                    bannersSection
                    videosSection
                    partnersSection
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(HBTheme.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                        .accessibilityLabel("Hokejbal")
                }
            }
            .hbNavigationStyle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // MARK: - Match slider

    private var matchSliderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeaderButton("Zápasy") {
                tabRouter.select(.matches)
            }

            if sliderMatches.isEmpty {
                Text(isLoading ? "Načítám zápasy…" : "Momentálně nejsou zápasy k zobrazení.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(.horizontal, HBTheme.screenPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sliderMatches) { match in
                            NavigationLink {
                                MatchDetailView(matchId: match.id)
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
            }
        }
    }

    // MARK: - Banners

    private var bannersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            TabView(selection: $bannerPage) {
                ForEach(Array(HomeContent.banners.enumerated()), id: \.element.id) { index, banner in
                    bannerCard(banner)
                        .padding(.horizontal, HBTheme.screenPadding)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 168)
        }
    }

    private func bannerCard(_ banner: HomeBanner) -> some View {
        let colors = HomeContent.gradients[banner.gradientIndex % HomeContent.gradients.count]
        let content = VStack(alignment: .leading, spacing: 8) {
            Text(banner.eyebrow)
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.6)
            Text(banner.title)
                .font(.hbMontserrat(size: 18, weight: .bold))
            Text(banner.subtitle)
                .font(.hbMontserrat(size: 13, weight: .medium))
                .opacity(0.9)
            Text(banner.ctaTitle.uppercased())
                .font(.hbMontserrat(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2), in: Capsule())
                .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            HBSkew(dx: 18)
                .fill(Color.white.opacity(0.12))
                .frame(width: 46)
                .padding(.trailing, 24)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous))

        return Group {
            if let url = banner.url {
                Link(destination: url) { content }
            } else {
                content
            }
        }
    }

    // MARK: - News

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Novinky") {
                NewsView()
            }

            if featuredNews.isEmpty {
                Text("Načítám články…")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(.horizontal, HBTheme.screenPadding)
            } else {
                if let lead = featuredNews.first {
                    NavigationLink {
                        ArticleDetailView(article: lead)
                    } label: {
                        featuredArticleCard(lead)
                            .padding(.horizontal, HBTheme.screenPadding)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(articles.dropFirst(1).prefix(5)) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        compactArticleRow(article)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, HBTheme.screenPadding)
                }
            }
        }
    }

    private func featuredArticleCard(_ article: NewsArticle) -> some View {
        NewsThumbnail(article: article)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.82)],
                    startPoint: .center,
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
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(article.publishedAt.hbShortDateTime)
                        .font(.hbMontserrat(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
            .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func compactArticleRow(_ article: NewsArticle) -> some View {
        HStack(alignment: .center, spacing: 12) {
            NewsThumbnail(article: article)
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.category.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(HBTheme.brand)
                Text(article.title)
                    .font(.hbMontserrat(size: 14, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(2)
                Text(article.publishedAt.hbShortDateTime)
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    // MARK: - Videos

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Videa") {
                MediaView()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HomeContent.videos) { video in
                        Link(destination: video.url) {
                            videoCard(video)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
            }
        }
    }

    private func videoCard(_ video: HomeVideo) -> some View {
        let colors = HomeContent.gradients[video.gradientIndex % HomeContent.gradients.count]
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 260, height: 146)

                Text("HOKEJBAL TV")
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
        defer { isLoading = false }
        async let news = apiClient.api.news(limit: 12)
        async let allMatches = apiClient.api.matches(query: MatchesQuery())
        articles = (try? await news) ?? []
        matches = (try? await allMatches) ?? []
        await liveScores.pollOnce(using: apiClient.api)
    }
}

/// Média — videa a odkazy na obsah ČMSHb.
struct MediaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(HomeContent.videos) { video in
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
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(HBTheme.screenPadding)
        }
        .background(HBTheme.surface)
        .navigationTitle("Média")
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

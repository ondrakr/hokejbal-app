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

    @State private var articles: [NewsArticle] = []
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var bannerPage = 0
    @State private var newsPage = 0

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
                VStack(alignment: .leading, spacing: 22) {
                    matchSliderSection
                    quickLinks
                    bannersSection
                    newsSection
                    videosSection
                    partnersSection
                }
                .padding(.bottom, 28)
            }
            .background(HBTheme.surface)
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
            sectionHeader("Zápasy") {
                DayMatchesView(
                    title: "Všechny zápasy",
                    competitionId: nil,
                    initialDate: Calendar.current.startOfDay(for: Date())
                )
            }

            if sliderMatches.isEmpty {
                Text(isLoading ? "Načítám zápasy…" : "Momentálně nejsou zápasy k zobrazení.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(.horizontal, HBTheme.screenPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(sliderMatches) { match in
                            NavigationLink {
                                MatchDetailView(matchId: match.id)
                            } label: {
                                HomeMatchCard(
                                    match: match,
                                    home: catalog.team(match.homeTeamId),
                                    away: catalog.team(match.awayTeamId),
                                    competition: catalog.competitions.first { $0.id == match.competitionId }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                }
            }
        }
    }

    // MARK: - Quick links

    private var quickLinks: some View {
        HStack(spacing: 0) {
            NavigationLink {
                if let id = catalog.competitions.first(where: { $0.slug == "extraliga" })?.id
                    ?? catalog.competitions.first?.id {
                    CompetitionDetailView(competitionId: id)
                } else {
                    CompetitionsView()
                }
            } label: {
                quickLinkLabel(title: "EXTRALIGA", systemImage: "shield.fill")
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(HBTheme.separator)
                .frame(width: 1, height: 36)

            Link(destination: URL(string: "https://www.hokejbal.cz")!) {
                quickLinkLabel(title: "REPREZENTACE", systemImage: "flag.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .background(HBTheme.secondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, HBTheme.screenPadding)
    }

    private func quickLinkLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HBTheme.brand)
            Text(title)
                .font(.hbMontserrat(size: 13, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
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
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )

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
                TabView(selection: $newsPage) {
                    ForEach(Array(featuredNews.enumerated()), id: \.element.id) { index, article in
                        featuredArticleCard(article)
                            .padding(.horizontal, HBTheme.screenPadding)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 220)

                ForEach(articles.dropFirst(min(5, articles.count)).prefix(4)) { article in
                    NavigationLink {
                        NewsView()
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
        let colors = HomeContent.gradients[article.imageGradientIndex % HomeContent.gradients.count]
        return VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 120)
                .overlay(alignment: .bottomLeading) {
                    CategoryTag(title: article.category)
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.hbMontserrat(size: 15, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(3)
                Text(article.publishedAt.hbShortDate)
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactArticleRow(_ article: NewsArticle) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: HomeContent.gradients[article.imageGradientIndex % HomeContent.gradients.count],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.category.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(HBTheme.brand)
                Text(article.title)
                    .font(.hbMontserrat(size: 14, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(2)
                Text(article.publishedAt.hbShortDate)
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
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
            Text("Partneři")
                .font(.hbMontserrat(size: 18, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .padding(.horizontal, HBTheme.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HomeContent.partners) { partner in
                        Link(destination: partner.url) {
                            Text(partner.name)
                                .font(.hbMontserrat(size: 13, weight: .semibold))
                                .foregroundStyle(HBTheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(HBTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        HStack {
            Text(title)
                .font(.hbMontserrat(size: 18, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
            Spacer()
            NavigationLink(destination: destination) {
                Text("Vše")
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, HBTheme.screenPadding)
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

// MARK: - Match slider card

private struct HomeMatchCard: View {
    let match: Match
    let home: Team?
    let away: Team?
    let competition: Competition?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(competition?.shortName.uppercased() ?? "ZÁPAS")
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(HBTheme.textTertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if match.isLive {
                    LiveBadge(compact: true)
                } else {
                    Text(match.status == .finished ? "Konec" : match.scheduledAt.hbTime)
                        .font(.hbMontserrat(size: 11, weight: .semibold))
                        .foregroundStyle(HBTheme.textSecondary)
                }
            }

            teamLine(home)
            teamLine(away)

            HStack {
                Text(match.scheduledAt.hbShortDate)
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
                Spacer()
                if match.status != .scheduled {
                    Text("\(match.homeScore):\(match.awayScore)")
                        .font(.hbMontserrat(size: 16, weight: .bold))
                        .foregroundStyle(match.isLive ? HBTheme.live : HBTheme.textPrimary)
                        .monospacedDigit()
                }
            }
        }
        .padding(14)
        .frame(width: 220, alignment: .leading)
        .background(HBTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func teamLine(_ team: Team?) -> some View {
        HStack(spacing: 8) {
            if let team {
                TeamBadge(team: team, size: 22)
                Text(team.shortName)
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
            } else {
                Text("—")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
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

import SwiftUI

struct NewsView: View {
    @EnvironmentObject private var apiClient: APIClient
    @State private var articles: [NewsArticle] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading && articles.isEmpty {
                ScrollView {
                    NewsListSkeleton(count: 4)
                }
                .scrollContentBackground(.hidden)
                .background(HBTheme.canvas)
                .transition(.opacity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(articles) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                articleCard(article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(HBTheme.screenPadding)
                }
                .scrollContentBackground(.hidden)
                .background(HBTheme.canvas)
                .refreshable { await load() }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: articles.isEmpty)
        .animation(.easeInOut(duration: 0.35), value: isLoading)
        .background(HBTheme.canvas)
        .navigationTitle("Novinky")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task { await load() }
    }

    private func articleCard(_ article: NewsArticle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NewsThumbnail(article: article, showsCategory: true)
                .frame(maxWidth: .infinity)
                .frame(height: 168)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.hbMontserrat(size: 16, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(article.summary)
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
                Text(article.publishedAt.hbShortDateTime)
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func load() async {
        isLoading = true
        defer {
            withAnimation(.easeInOut(duration: 0.35)) {
                isLoading = false
            }
        }
        let loaded = (try? await apiClient.api.news(limit: 30)) ?? []
        withAnimation(.easeInOut(duration: 0.35)) {
            articles = loaded
        }
    }
}

/// Detail článku — fotka, titulek a text načtený přímo v aplikaci.
struct ArticleDetailView: View {
    let article: NewsArticle

    @State private var bodyText: String?
    @State private var isLoadingBody = false
    @State private var loadFailed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                NewsThumbnail(article: article, showsCategory: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Text(article.category.uppercased())
                            .font(.hbMontserrat(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(HBTheme.brand, in: Capsule())
                        Spacer(minLength: 0)
                        Text(article.publishedAt.hbShortDateTime)
                            .font(.hbMontserrat(size: 12, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                    }

                    Text(article.title)
                        .font(.hbDisplay(size: 24, weight: .heavy))
                        .foregroundStyle(HBTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(HBTheme.cardStroke)
                        .frame(height: 0.75)

                    if let bodyText, !bodyText.isEmpty {
                        Text(bodyText)
                            .font(.hbMontserrat(size: 15, weight: .regular))
                            .foregroundStyle(HBTheme.textSecondary)
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    } else if isLoadingBody {
                        ArticleBodySkeleton()
                            .transition(.opacity)
                    } else {
                        Text(article.summary)
                            .font(.hbMontserrat(size: 15, weight: .regular))
                            .foregroundStyle(HBTheme.textSecondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if loadFailed {
                            Text("Text článku se nepodařilo načíst.")
                                .font(.hbMontserrat(size: 13, weight: .medium))
                                .foregroundStyle(HBTheme.textTertiary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(HBTheme.screenPadding)
                .animation(.easeInOut(duration: 0.3), value: bodyText == nil)
                .animation(.easeInOut(duration: 0.3), value: isLoadingBody)
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task(id: article.id) {
            await loadBody()
        }
    }

    private func loadBody() async {
        guard let urlString = article.articleURL, !urlString.isEmpty else {
            loadFailed = true
            return
        }
        isLoadingBody = true
        loadFailed = false
        defer {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoadingBody = false
            }
        }

        do {
            let text = try await HokejbalCzNewsClient.fetchBody(urlString: urlString)
            withAnimation(.easeInOut(duration: 0.3)) {
                bodyText = text.isEmpty ? nil : text
                loadFailed = text.isEmpty
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.3)) {
                bodyText = nil
                loadFailed = true
            }
        }
    }
}

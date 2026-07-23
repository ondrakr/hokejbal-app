import SwiftUI

struct NewsView: View {
    @EnvironmentObject private var apiClient: APIClient
    @State private var articles: [NewsArticle] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading && articles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("Novinky")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task { await load() }
    }

    private func articleCard(_ article: NewsArticle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NewsThumbnail(article: article, showsCategory: true)
                .frame(height: 168)

            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.hbMontserrat(size: 16, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(article.summary)
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .lineLimit(3)
                Text(article.publishedAt.hbShortDateTime)
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        articles = (try? await apiClient.api.news(limit: 30)) ?? []
    }
}

/// Detail článku — velká fotka, titulek, čas a text.
struct ArticleDetailView: View {
    let article: NewsArticle

    private let webURL = URL(string: "https://www.hokejbal.cz")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                NewsThumbnail(article: article, showsCategory: true)
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
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(HBTheme.cardStroke)
                        .frame(height: 0.75)

                    Text(article.summary)
                        .font(.hbMontserrat(size: 15, weight: .regular))
                        .foregroundStyle(HBTheme.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Link(destination: webURL) {
                        HStack(spacing: 8) {
                            Text("Číst celý článek na hokejbal.cz")
                                .font(.hbMontserrat(size: 14, weight: .bold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(HBTheme.brand, in: RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
                    }
                    .padding(.top, 4)
                }
                .padding(HBTheme.screenPadding)
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
    }
}

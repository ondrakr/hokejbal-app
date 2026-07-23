import SwiftUI

struct NewsView: View {
    @EnvironmentObject private var apiClient: APIClient
    @State private var articles: [NewsArticle] = []
    @State private var isLoading = false

    private let gradients: [[Color]] = HomeContent.gradients

    var body: some View {
        Group {
            if isLoading && articles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(articles) { article in
                            articleCard(article)
                        }
                    }
                    .padding(HBTheme.screenPadding)
                }
                .scrollContentBackground(.hidden)
                .background(HBTheme.surface)
                .refreshable { await load() }
            }
        }
        .background(HBTheme.surface)
        .navigationTitle("Novinky")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task { await load() }
    }

    private func articleCard(_ article: NewsArticle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradients[article.imageGradientIndex % gradients.count],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .overlay(alignment: .bottomLeading) {
                    CategoryTag(title: article.category)
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.hbMontserrat(size: 16, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(article.summary)
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .lineLimit(3)
                Text(article.publishedAt.hbShortDate)
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(.top, 12)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        articles = (try? await apiClient.api.news(limit: 30)) ?? []
    }
}

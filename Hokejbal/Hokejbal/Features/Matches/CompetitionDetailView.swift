import SwiftUI

enum CompetitionDetailSection: String, CaseIterable, Hashable {
    case matches = "Zápasy"
    case table = "Tabulka"
    case news = "Zprávy"
}

struct CompetitionDetailView: View {
    let competitionId: String

    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var activeCompetitionId: String
    @State private var competition: Competition?
    @State private var seasonOptions: [Competition] = []
    @State private var section: CompetitionDetailSection = .matches
    @State private var matches: [Match] = []
    @State private var standings: [StandingRow] = []
    @State private var articles: [NewsArticle] = []
    @State private var isLoading = false
    @State private var error: String?

    init(competitionId: String) {
        self.competitionId = competitionId
        _activeCompetitionId = State(initialValue: competitionId)
    }

    private var upcomingMatches: [Match] {
        matches
            .filter { $0.status == .scheduled || $0.status == .live }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var finishedMatches: [Match] {
        matches
            .filter { $0.status == .finished || $0.status == .postponed }
            .sorted { $0.scheduledAt > $1.scheduledAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            HBUnderlineTabs(selection: $section)

            Group {
                if isLoading && matches.isEmpty && standings.isEmpty {
                    ProgressView("Načítám…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView("Chyba", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    switch section {
                    case .matches:
                        matchesContent
                    case .table:
                        ScrollView {
                            tableContent
                                .padding(.bottom, 24)
                        }
                    case .news:
                        ScrollView {
                            newsContent
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HBTheme.surface)
        }
        .background(HBTheme.surface)
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let competition {
                    FavoriteStarButton(
                        isFavorite: favorites.isFavorite(competition: competition),
                        accessibilityLabel: "Oblíbená soutěž"
                    ) {
                        favorites.toggleCompetition(competition)
                    }
                }
            }
        }
        .task(id: activeCompetitionId) {
            await reload(for: activeCompetitionId)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                competitionLogo
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    Text(competition?.name ?? "Soutěž")
                        .font(.hbMontserrat(size: 22, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .lineLimit(2)

                    seasonMenu
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(HBTheme.surface)
    }

    private var competitionLogo: some View {
        Group {
            if let urlString = competition?.logoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        initialsBadge
                    }
                }
            } else {
                initialsBadge
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HBTheme.secondarySurface)
        )
    }

    private var initialsBadge: some View {
        Text(competition?.logoInitials ?? "?")
            .font(.hbMontserrat(size: 20, weight: .bold))
            .foregroundStyle(HBTheme.brand)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var seasonMenu: some View {
        HBSolidMenuButton(
            title: "Ročník",
            options: seasonOptions,
            selectedId: activeCompetitionId,
            optionLabel: { $0.season },
            optionDetail: { $0.shortName },
            onSelect: { activeCompetitionId = $0.id }
        ) {
            HStack(spacing: 4) {
                Text(competition?.season ?? "—")
                    .font(.hbMontserrat(size: 14, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(HBTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(HBTheme.secondarySurface)
            )
        }
    }

    // MARK: - Matches

    private var matchesContent: some View {
        Group {
            if upcomingMatches.isEmpty && finishedMatches.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "Bez zápasů",
                    message: "Pro tento ročník zatím nejsou zápasy."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !upcomingMatches.isEmpty {
                        Section {
                            ForEach(upcomingMatches) { match in
                                matchLink(match)
                            }
                        } header: {
                            Text("NADCHÁZEJÍCÍ")
                                .font(.hbMontserrat(size: 12, weight: .bold))
                                .foregroundStyle(HBTheme.textTertiary)
                        }
                    }

                    if !finishedMatches.isEmpty {
                        Section {
                            ForEach(finishedMatches) { match in
                                matchLink(match)
                            }
                        } header: {
                            Text("VÝSLEDKY")
                                .font(.hbMontserrat(size: 12, weight: .bold))
                                .foregroundStyle(HBTheme.textTertiary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func matchLink(_ match: Match) -> some View {
        NavigationLink {
            MatchDetailView(matchId: match.id)
        } label: {
            MatchRowView(
                match: match,
                home: catalog.team(match.homeTeamId),
                away: catalog.team(match.awayTeamId),
                showCompetition: false,
                competitionName: nil
            )
        }
        .buttonStyle(.plain)
        .hbHideDisclosure()
        .listRowInsets(EdgeInsets())
        .listRowBackground(HBTheme.surface)
        .listRowSeparator(.hidden)
    }

    // MARK: - Table

    private var tableContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if standings.isEmpty {
                EmptyStateView(icon: "list.number", title: "Bez tabulky", message: "Tabulka pro tento ročník není k dispozici.")
                    .padding(.top, 40)
            } else {
                HStack {
                    Text("#").frame(width: 28, alignment: .leading)
                    Text("Tým").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Z").frame(width: 28)
                    Text("B").frame(width: 32)
                    Text("Skóre").frame(width: 56, alignment: .trailing)
                }
                .font(.hbMontserrat(size: 11, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 10)

                ForEach(standings) { row in
                    standingRow(row)
                }
            }
        }
        .padding(.top, 8)
    }

    private func standingRow(_ row: StandingRow) -> some View {
        let team = catalog.team(row.teamId)
        return HStack(spacing: 8) {
            NavigationLink {
                TeamDetailView(teamId: row.teamId)
            } label: {
                HStack(spacing: 10) {
                    Text("\(row.rank)")
                        .font(.hbMontserrat(size: 13, weight: .bold))
                        .foregroundStyle(HBTheme.textSecondary)
                        .frame(width: 28, alignment: .leading)

                    if let team {
                        TeamBadge(team: team, size: 22)
                        Text(team.shortName)
                            .font(.hbMontserrat(size: 14, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text(row.teamId)
                            .font(.hbMontserrat(size: 14, weight: .medium))
                    }

                    Spacer(minLength: 0)

                    Text("\(row.played)")
                        .font(.system(size: 13).monospacedDigit())
                        .frame(width: 28)
                    Text("\(row.points)")
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundStyle(HBTheme.brand)
                        .frame(width: 32)
                    Text(row.scoreText)
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(HBTheme.textSecondary)
                        .frame(width: 56, alignment: .trailing)
                }
            }
            .buttonStyle(.plain)

            FavoriteStarButton(
                isFavorite: favorites.isFavorite(team: row.teamId),
                accessibilityLabel: "Oblíbený tým"
            ) {
                favorites.toggleTeam(row.teamId)
            }
        }
        .padding(.leading, HBTheme.screenPadding)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
    }

    // MARK: - News

    private var newsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if articles.isEmpty {
                EmptyStateView(icon: "newspaper", title: "Bez zpráv", message: "K této soutěži zatím nejsou články.")
                    .padding(.top, 40)
            } else {
                ForEach(articles.prefix(12)) { article in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(article.category.uppercased())
                            .font(.hbMontserrat(size: 11, weight: .bold))
                            .foregroundStyle(HBTheme.brand)
                        Text(article.title)
                            .font(.hbMontserrat(size: 15, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                        Text(article.publishedAt.hbShortDate)
                            .font(.hbMontserrat(size: 12, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HBTheme.secondarySurface)
                    )
                }
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.top, 14)
    }

    // MARK: - Load

    private func reload(for id: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try Task.checkCancellation()
            let all = try await apiClient.api.competitions(seasonId: nil)
            try Task.checkCancellation()

            competition = all.first(where: { $0.id == id })
            if competition == nil {
                error = "Soutěž nebyla nalezena."
                return
            }
            if let slug = competition?.slug {
                seasonOptions = all.filter { $0.slug == slug }.sorted { $0.seasonId > $1.seasonId }
            }

            async let m = apiClient.api.matches(query: MatchesQuery(competitionId: id))
            async let s = apiClient.api.standings(competitionId: id)
            async let n = apiClient.api.news(limit: 30)
            async let t = apiClient.api.teams(competitionId: id)

            matches = (try? await m) ?? []
            standings = (try? await s) ?? []
            articles = (try? await n) ?? []
            if let teams = try? await t {
                for team in teams { catalog.upsertTeam(team) }
            }
            try Task.checkCancellation()
        } catch is CancellationError {
            // Normální při rychlé navigaci / změně sezóny — neukazovat jako chybu.
        } catch {
            if Self.isCancellation(error) { return }
            self.error = error.localizedDescription
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return true }
        let message = ns.localizedDescription.lowercased()
        return message.contains("zrušeno") || message.contains("cancelled") || message.contains("canceled")
    }
}

import SwiftUI

enum TeamDetailSection: String, CaseIterable, Hashable {
    case results = "Výsledky"
    case schedule = "Program"
    case table = "Tabulka"
    case roster = "Soupiska"
    case history = "Historie"
    case news = "Zprávy"
}

struct TeamDetailView: View {
    let teamId: String

    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var team: Team?
    @State private var players: [Player] = []
    @State private var matches: [Match] = []
    @State private var articles: [NewsArticle] = []
    @State private var standing: StandingRow?
    @State private var standings: [StandingRow] = []
    @State private var seasonHistory: [ClubSeasonRecord] = []
    @State private var section: TeamDetailSection = .results

    private var finishedMatches: [Match] {
        matches.filter { $0.status == .finished || $0.status == .live }
            .sorted { $0.scheduledAt > $1.scheduledAt }
    }

    private var upcomingMatches: [Match] {
        matches.filter { $0.status == .scheduled }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var body: some View {
        Group {
            if let team {
                content(team)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteStarButton(
                    isFavorite: favorites.isFavorite(team: teamId),
                    accessibilityLabel: "Oblíbený tým"
                ) {
                    favorites.toggleTeam(teamId)
                }
            }
        }
        .task(id: teamId) { await load() }
    }

    private func content(_ team: Team) -> some View {
        VStack(spacing: 0) {
            header(team)
            HBUnderlineTabs(selection: $section)

            ScrollView {
                Group {
                    switch section {
                    case .results:
                        resultsSection(team)
                    case .schedule:
                        scheduleSection
                    case .table:
                        tableSection
                    case .roster:
                        rosterSection
                    case .history:
                        historySection
                    case .news:
                        newsSection
                    }
                }
                .padding(.bottom, 24)
            }
            .background(HBTheme.surface)
        }
        .background(HBTheme.surface)
    }

    private func header(_ team: Team) -> some View {
        HStack(alignment: .center, spacing: 14) {
            TeamBadge(team: team, size: 64)

            Text(team.shortName)
                .font(.hbMontserrat(size: 26, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(HBTheme.surface)
    }

    private func resultsSection(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            leagueHeader(team)

            if finishedMatches.isEmpty {
                EmptyStateView(icon: "flag.checkered", title: "Bez výsledků", message: "Zatím tu nejsou odehrané zápasy.")
                    .padding(.top, 40)
            } else {
                ForEach(finishedMatches) { match in
                    NavigationLink {
                        MatchDetailView(matchId: match.id)
                    } label: {
                        TeamResultRow(match: match, focusTeamId: team.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if upcomingMatches.isEmpty {
                EmptyStateView(icon: "calendar", title: "Prázdný program", message: "Žádné naplánované zápasy.")
                    .padding(.top, 40)
            } else {
                ForEach(upcomingMatches) { match in
                    NavigationLink {
                        MatchDetailView(matchId: match.id)
                    } label: {
                        MatchRowView(
                            match: match,
                            home: catalog.team(match.homeTeamId),
                            away: catalog.team(match.awayTeamId)
                        )
                    }
                    .buttonStyle(.plain)
                    .hbHideDisclosure()
                }
            }
        }
    }

    private var rosterSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(rosterGroups, id: \.0) { title, items in
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.hbMontserrat(size: 16, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .padding(.horizontal, HBTheme.screenPadding)

                    ForEach(items) { player in
                        HStack(spacing: 4) {
                            NavigationLink {
                                PlayerDetailView(playerId: player.id)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack(alignment: .bottomTrailing) {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(HBTheme.tertiarySurface)
                                            .frame(width: 48, height: 48)
                                            .overlay {
                                                Image(systemName: "person.fill")
                                                    .foregroundStyle(HBTheme.textTertiary)
                                            }

                                        Text("\(player.number)")
                                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(HBTheme.brand, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                            .offset(x: 3, y: 3)
                                    }

                                    Text(player.fullName)
                                        .font(.hbMontserrat(size: 14, weight: .medium))
                                        .foregroundStyle(HBTheme.textPrimary)

                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            FavoriteStarButton(
                                isFavorite: favorites.isFavorite(player: player.id),
                                accessibilityLabel: "Oblíbený hráč"
                            ) {
                                favorites.togglePlayer(player.id)
                            }
                        }
                        .padding(.horizontal, HBTheme.screenPadding)

                        Divider()
                            .padding(.leading, HBTheme.screenPadding + 60)
                    }
                }
            }
        }
        .padding(.top, 12)
    }

    private var rosterGroups: [(String, [Player])] {
        let order: [(String, PlayerPosition)] = [
            ("Brankáři", .goalie),
            ("Obránci", .defenseman),
            ("Útočníci", .forward)
        ]
        return order.compactMap { title, pos in
            let items = players.filter { $0.position == pos }.sorted { $0.lastName < $1.lastName }
            return items.isEmpty ? nil : (title, items)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if seasonHistory.isEmpty {
                EmptyStateView(icon: "calendar", title: "Bez historie", message: "Pro tento klub zatím nemáme starší sezóny.")
                    .padding(.top, 40)
            } else {
                ForEach(seasonHistory) { record in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.seasonLabel)
                                .font(.hbMontserrat(size: 16, weight: .bold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text(record.competitionName)
                                .font(.hbMontserrat(size: 12, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                        }
                        Spacer()
                        if let s = record.standing {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(s.rank). místo")
                                    .font(.hbMontserrat(size: 15, weight: .bold))
                                    .foregroundStyle(HBTheme.brand)
                                Text("\(s.points) b · \(s.scoreText)")
                                    .font(.hbMontserrat(size: 12, weight: .medium))
                                    .foregroundStyle(HBTheme.textSecondary)
                                Text("\(s.wins)/\(s.overtimeWins)/\(s.overtimeLosses)/\(s.losses)")
                                    .font(.system(size: 11).monospacedDigit())
                                    .foregroundStyle(HBTheme.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(HBTheme.separator).frame(height: 0.5)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if articles.isEmpty {
                EmptyStateView(icon: "newspaper", title: "Bez zpráv", message: "K tomuto týmu zatím nejsou články.")
                    .padding(.top, 40)
            } else {
                ForEach(articles.prefix(10)) { article in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(article.category.uppercased())
                            .font(.hbMontserrat(size: 10, weight: .bold))
                            .foregroundStyle(HBTheme.brand)
                        Text(article.title)
                            .font(.hbMontserrat(size: 15, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                        Text(article.publishedAt.hbShortDate)
                            .font(.caption)
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(HBTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, HBTheme.screenPadding)
                }
            }
        }
        .padding(.top, 12)
    }

    private func leagueHeader(_ team: Team) -> some View {
        let competition = catalog.competitions.first { $0.id == team.competitionId }
        return HStack(spacing: 10) {
            if let competition {
                CompetitionBadge(competition: competition, size: 28)
            }
            Text(competition?.name ?? "Soutěž")
                .font(.hbMontserrat(size: 13, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .background(HBTheme.secondarySurface)
    }

    private var tableSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if standings.isEmpty {
                EmptyStateView(icon: "list.number", title: "Bez tabulky", message: "Tabulka pro tuto soutěž není k dispozici.")
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
                    let isFocus = row.teamId == teamId
                    HStack(spacing: 10) {
                        Text("\(row.rank)")
                            .font(.hbMontserrat(size: 13, weight: .bold))
                            .foregroundStyle(isFocus ? HBTheme.brand : HBTheme.textSecondary)
                            .frame(width: 28, alignment: .leading)

                        if let t = catalog.team(row.teamId) {
                            TeamBadge(team: t, size: 22)
                            Text(t.shortName)
                                .font(.hbMontserrat(size: 14, weight: isFocus ? .bold : .semibold))
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
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.vertical, 10)
                    .background(isFocus ? HBTheme.brand.opacity(0.08) : Color.clear)
                }
            }
        }
        .padding(.top, 8)
    }

    private func load() async {
        team = try? await apiClient.api.team(id: teamId)
        if let team { catalog.upsertTeam(team) }

        players = (try? await apiClient.api.players(
            teamId: teamId,
            seasonId: nil,
            competitionId: team?.competitionId
        )) ?? []

        matches = (try? await apiClient.api.matches(query: MatchesQuery(
            competitionId: team?.competitionId,
            seasonId: nil,
            teamId: teamId
        ))) ?? []

        articles = (try? await apiClient.api.news(limit: 20)) ?? []
        if let competitionId = team?.competitionId {
            let rows = (try? await apiClient.api.standings(competitionId: competitionId)) ?? []
            standings = rows
            standing = rows.first { $0.teamId == teamId }
        } else {
            standings = []
            standing = nil
        }
        seasonHistory = (try? await apiClient.api.clubSeasonHistory(clubId: teamId)) ?? []
    }
}

/// Řádek výsledku na stránce týmu: datum | loga+názvy | stav | skóre | V/P.
struct TeamResultRow: View {
    @EnvironmentObject private var catalog: CatalogStore
    let match: Match
    let focusTeamId: String

    private var home: Team? { catalog.team(match.homeTeamId) }
    private var away: Team? { catalog.team(match.awayTeamId) }

    private var focusIsHome: Bool { match.homeTeamId == focusTeamId }
    private var focusWon: Bool {
        if match.homeScore == match.awayScore { return false }
        let focusScore = focusIsHome ? match.homeScore : match.awayScore
        let otherScore = focusIsHome ? match.awayScore : match.homeScore
        return focusScore > otherScore
    }

    private var isDraw: Bool { match.homeScore == match.awayScore }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(shortDate)
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textTertiary)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                teamLine(home, score: match.homeScore, emphasize: match.homeScore > match.awayScore)
                teamLine(away, score: match.awayScore, emphasize: match.awayScore > match.homeScore)
            }

            Spacer(minLength: 4)

            if match.isBroadcast {
                Image(systemName: "tv")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
            }

            VStack(alignment: .trailing, spacing: 6) {
                if match.isLive {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HBTheme.live)
                } else if match.period == .overtime {
                    Text("Po prodl.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(HBTheme.textTertiary)
                }

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(match.homeScore)")
                        .font(.system(size: 14, weight: match.homeScore > match.awayScore ? .bold : .semibold).monospacedDigit())
                    Text("\(match.awayScore)")
                        .font(.system(size: 14, weight: match.awayScore > match.homeScore ? .bold : .semibold).monospacedDigit())
                }
                .foregroundStyle(HBTheme.textPrimary)
            }

            resultBadge
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HBTheme.separator)
                .frame(height: 0.5)
                .padding(.horizontal, -HBTheme.screenPadding)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .contentShape(Rectangle())
    }

    private func teamLine(_ team: Team?, score: Int, emphasize: Bool) -> some View {
        HStack(spacing: 8) {
            if let team {
                TeamBadge(team: team, size: 16)
                Text(team.shortName)
                    .font(.system(size: 13, weight: emphasize ? .bold : .regular))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    private var resultBadge: some View {
        Group {
            if match.isLive {
                Text("•")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HBTheme.live)
                    .frame(width: 22, height: 22)
            } else if isDraw {
                Text("R")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            } else {
                Text(focusWon ? "V" : "P")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(
                        (focusWon ? HBTheme.win : HBTheme.loss),
                        in: RoundedRectangle(cornerRadius: 3, style: .continuous)
                    )
            }
        }
    }

    private var shortDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "dd.MM."
        return f.string(from: match.scheduledAt)
    }
}

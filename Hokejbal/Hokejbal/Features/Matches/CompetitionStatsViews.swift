import SwiftUI

enum CompetitionStatsScope: String, CaseIterable, Hashable {
    case players = "HRÁČI"
    case teams = "TÝMY"
}

/// Grid leaderů v tabu Statistiky (detail soutěže).
struct CompetitionStatsPanel: View {
    let competitionId: String
    let matches: [Match]
    let standings: [StandingRow]
    let players: [Player]
    let isLoading: Bool

    @EnvironmentObject private var catalog: CatalogStore
    @State private var scope: CompetitionStatsScope = .players

    private var playerCards: [PlayerStatLeaderCardModel] {
        CompetitionStats.playerLeaderCards(players: players) { catalog.team($0) }
    }

    private var teamCards: [TeamStatLeaderCardModel] {
        CompetitionStats.teamLeaderCards(
            standings: standings,
            matches: matches,
            teamById: { catalog.team($0) }
        )
    }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        Group {
            if isLoading && players.isEmpty && standings.isEmpty {
                ProgressView("Načítám statistiky…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        HBPillSelector(selection: $scope)

                        if scope == .players {
                            playersGrid
                        } else {
                            teamsGrid
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    @ViewBuilder
    private var playersGrid: some View {
        if players.isEmpty {
            EmptyStateView(
                icon: "person.3",
                title: "Bez statistik hráčů",
                message: "Pro tuto soutěž zatím nemáme body hráčů."
            )
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(playerCards) { card in
                    NavigationLink {
                        CompetitionStatsLeaderboardView(
                            competitionId: competitionId,
                            scope: .players,
                            metric: .player(card.metric),
                            matches: matches,
                            standings: standings,
                            players: players
                        )
                    } label: {
                        PlayerStatLeaderCardView(title: card.title, leader: card.leader)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
        }
    }

    @ViewBuilder
    private var teamsGrid: some View {
        if standings.isEmpty && teamCards.allSatisfy({ $0.leader == nil }) {
            EmptyStateView(
                icon: "shield",
                title: "Bez statistik týmů",
                message: "Tabulka soutěže zatím není k dispozici."
            )
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(teamCards) { card in
                    NavigationLink {
                        CompetitionStatsLeaderboardView(
                            competitionId: competitionId,
                            scope: .teams,
                            metric: .team(card.metric),
                            matches: matches,
                            standings: standings,
                            players: players
                        )
                    } label: {
                        TeamStatLeaderCardView(title: card.title, leader: card.leader)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
        }
    }
}

/// Statistiky hráčů týmu — stejné metriky jako soutěž, jen soupiska týmu (bez přepínače Týmy).
struct TeamStatsPanel: View {
    let teamId: String
    let competitionId: String
    let players: [Player]

    @EnvironmentObject private var catalog: CatalogStore

    private var teamPlayers: [Player] {
        players.filter { $0.teamId == teamId }
    }

    private var playerCards: [PlayerStatLeaderCardModel] {
        CompetitionStats.playerLeaderCards(players: teamPlayers) { catalog.team($0) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        Group {
            if teamPlayers.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "Bez statistik hráčů",
                    message: "Pro tento tým zatím nemáme body hráčů."
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(playerCards) { card in
                        NavigationLink {
                            CompetitionStatsLeaderboardView(
                                competitionId: competitionId,
                                scope: .players,
                                metric: .player(card.metric),
                                matches: [],
                                standings: [],
                                players: teamPlayers,
                                subtitleOverride: catalog.team(teamId)?.name
                            )
                        } label: {
                            PlayerStatLeaderCardView(title: card.title, leader: card.leader)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.top, 12)
            }
        }
    }
}

enum CompetitionStatsLeaderMetric: Hashable {
    case player(PlayerStatMetric)
    case team(TeamStatMetric)

    var title: String {
        switch self {
        case .player(let m): return m.title
        case .team(let m): return m.title
        }
    }
}

/// Plný žebříček jedné metriky (např. Kanadské body).
struct CompetitionStatsLeaderboardView: View {
    let competitionId: String
    let scope: CompetitionStatsScope
    let metric: CompetitionStatsLeaderMetric
    let matches: [Match]
    let standings: [StandingRow]
    let players: [Player]
    var subtitleOverride: String? = nil

    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var apiClient: APIClient

    @State private var competition: Competition?

    private var playerRows: [PlayerStatRow] {
        guard case .player(let m) = metric else { return [] }
        return CompetitionStats.rankPlayers(players, teamById: { catalog.team($0) }, metric: m)
    }

    private var teamRows: [TeamStatRow] {
        guard case .team(let m) = metric else { return [] }
        return CompetitionStats.rankTeams(
            standings: standings,
            matches: matches,
            teamById: { catalog.team($0) },
            metric: m
        )
    }

    private var subtitle: String? {
        subtitleOverride ?? competition?.name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let subtitle {
                    Text(subtitle)
                        .font(.hbMontserrat(size: 12, weight: .semibold))
                        .foregroundStyle(HBTheme.textSecondary)
                        .padding(.horizontal, HBTheme.screenPadding)
                }

                if scope == .players {
                    if playerRows.isEmpty {
                        EmptyStateView(icon: "list.number", title: "Prázdný žebříček", message: "Pro tuto metriku zatím nejsou data.")
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(playerRows.enumerated()), id: \.element.id) { index, row in
                            NavigationLink {
                                PlayerDetailView(playerId: row.player.id)
                            } label: {
                                PlayerLeaderboardRowView(rank: index + 1, row: row, featured: index == 0)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, HBTheme.screenPadding)
                    }
                } else if teamRows.isEmpty {
                    EmptyStateView(icon: "list.number", title: "Prázdný žebříček", message: "Pro tuto metriku zatím nejsou data.")
                        .padding(.top, 40)
                } else {
                    ForEach(Array(teamRows.enumerated()), id: \.element.id) { index, row in
                        NavigationLink {
                            TeamDetailView(teamId: row.team.id)
                        } label: {
                            TeamLeaderboardRowView(rank: index + 1, row: row, featured: index == 0)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, HBTheme.screenPadding)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(HBTheme.canvas)
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task {
            if competition == nil {
                competition = try? await apiClient.api.competitions(seasonId: nil)
                    .first(where: { $0.id == competitionId })
            }
        }
    }
}

// MARK: - Cards

private struct PlayerStatLeaderCardView: View {
    let title: String
    let leader: PlayerStatRow?

    var body: some View {
        VStack(spacing: 8) {
            if let leader {
                ZStack(alignment: .bottomTrailing) {
                    PlayerAvatar(player: leader.player, size: 56, cornerRadius: 28)
                    if let team = leader.team {
                        TeamBadge(team: team, size: 18)
                            .padding(2)
                            .background(Circle().fill(HBTheme.card))
                            .offset(x: 4, y: 4)
                    }
                }
                Text(leader.player.fullName)
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
                Text(leader.team?.shortName ?? "—")
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(leader.display)
                        .font(.hbNumber(size: 26, weight: .heavy))
                        .foregroundStyle(HBTheme.textPrimary)
                    if !leader.unit.isEmpty {
                        Text(leader.unit)
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                }
                Text(title)
                    .font(.hbMontserrat(size: 11, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text(title)
                    .font(.hbMontserrat(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
                Text("—")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 168)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .hbCard()
    }
}

private struct TeamStatLeaderCardView: View {
    let title: String
    let leader: TeamStatRow?

    var body: some View {
        VStack(spacing: 8) {
            if let leader {
                TeamBadge(team: leader.team, size: 52)
                Text(leader.team.name)
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(leader.display)
                        .font(.hbNumber(size: 26, weight: .heavy))
                        .foregroundStyle(HBTheme.textPrimary)
                    if !leader.unit.isEmpty, leader.unit != "%" {
                        Text(leader.unit)
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                }
                Text(title)
                    .font(.hbMontserrat(size: 11, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text(title)
                    .font(.hbMontserrat(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
                Text("—")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 168)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .hbCard()
    }
}

private struct PlayerLeaderboardRowView: View {
    let rank: Int
    let row: PlayerStatRow
    var featured: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank).")
                .font(.hbNumber(size: featured ? 18 : 15, weight: .heavy))
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 28, alignment: .center)

            ZStack(alignment: .bottomTrailing) {
                PlayerAvatar(player: row.player, size: featured ? 56 : 40, cornerRadius: featured ? 28 : 20)
                if let team = row.team {
                    TeamBadge(team: team, size: 14)
                        .padding(1)
                        .background(Circle().fill(HBTheme.card))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(row.player.fullName)
                    .font(.hbMontserrat(size: featured ? 16 : 14, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
                Text(row.team?.shortName ?? "—")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(row.display)
                    .font(.hbNumber(size: featured ? 22 : 17, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                Text(row.unit)
                    .font(.hbMontserrat(size: 12, weight: .bold))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, featured ? 14 : 12)
        .hbCard()
        .padding(.bottom, 8)
    }
}

private struct TeamLeaderboardRowView: View {
    let rank: Int
    let row: TeamStatRow
    var featured: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank).")
                .font(.hbNumber(size: 15, weight: .heavy))
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 28, alignment: .center)

            TeamBadge(team: row.team, size: featured ? 44 : 36)

            Text(row.team.name)
                .font(.hbMontserrat(size: 14, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(row.display)
                    .font(.hbNumber(size: 17, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                if !row.unit.isEmpty, row.unit != "%" {
                    Text(row.unit)
                        .font(.hbMontserrat(size: 12, weight: .bold))
                        .foregroundStyle(HBTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .hbCard()
        .padding(.bottom, 8)
    }
}

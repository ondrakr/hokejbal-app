import SwiftUI

enum PlayerDetailSection: String, CaseIterable, Hashable {
    case matches = "Zápasy"
    case seasons = "Sezóny"
}

struct PlayerDetailView: View {
    let playerId: String

    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var player: Player?
    @State private var history: [PlayerSeasonStat] = []
    @State private var appearances: [PlayerMatchAppearance] = []
    @State private var section: PlayerDetailSection = .matches
    @State private var selectedSeasonId: String?

    private var seasonChips: [String] {
        let ids = history.map(\.seasonId)
        return Array(Set(ids)).sorted(by: >)
    }

    private var filteredAppearances: [PlayerMatchAppearance] {
        guard let selectedSeasonId else { return appearances }
        return appearances.filter { $0.seasonId == selectedSeasonId }
    }

    var body: some View {
        Group {
            if let player {
                content(player)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteStarButton(
                    isFavorite: favorites.isFavorite(player: playerId),
                    accessibilityLabel: "Oblíbený hráč"
                ) {
                    favorites.togglePlayer(playerId)
                }
            }
        }
        .task(id: playerId) { await load() }
    }

    private func content(_ player: Player) -> some View {
        VStack(spacing: 0) {
            header(player)
            HBUnderlineTabs(selection: $section)

            Group {
                switch section {
                case .matches:
                    matchesPane(player)
                case .seasons:
                    ScrollView {
                        seasonsContent
                            .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HBTheme.surface)
        }
        .background(HBTheme.surface)
    }

    // MARK: - Header

    private func header(_ player: Player) -> some View {
        let team = catalog.team(player.teamId)
        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(HBTheme.brand.opacity(0.12))
                Text("\(player.number)")
                    .font(.hbMontserrat(size: 26, weight: .bold))
                    .foregroundStyle(HBTheme.brand)
                    .monospacedDigit()
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(player.fullName)
                    .font(.hbMontserrat(size: 22, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(2)

                Text(player.position.label.capitalized)
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)

                if let team {
                    NavigationLink {
                        TeamDetailView(teamId: team.id)
                    } label: {
                        HStack(spacing: 6) {
                            TeamBadge(team: team, size: 18)
                            Text(team.shortName)
                                .font(.hbMontserrat(size: 13, weight: .semibold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HBTheme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(HBTheme.surface)
    }

    // MARK: - Matches

    private func matchesPane(_ player: Player) -> some View {
        VStack(spacing: 0) {
            if !seasonChips.isEmpty {
                seasonChipRow
                    .padding(.top, 10)
                    .padding(.bottom, 6)
            }

            if filteredAppearances.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "Bez zápasů",
                    message: "Pro zvolený ročník zatím nemáme zápasy hráče."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredAppearances) { item in
                        NavigationLink {
                            MatchDetailView(matchId: item.match.id)
                        } label: {
                            playerMatchRow(item, focusTeamId: player.teamId)
                        }
                        .buttonStyle(.plain)
                        .hbHideDisclosure()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(HBTheme.surface)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var seasonChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(seasonChips, id: \.self) { seasonId in
                    let label = history.first(where: { $0.seasonId == seasonId })?.seasonLabel ?? seasonId
                    let selected = selectedSeasonId == seasonId
                    Button {
                        selectedSeasonId = seasonId
                    } label: {
                        Text(label)
                            .font(.hbMontserrat(size: 13, weight: .semibold))
                            .foregroundStyle(selected ? HBTheme.onBrand : HBTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected ? HBTheme.brand : HBTheme.secondarySurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
        }
    }

    private func playerMatchRow(_ item: PlayerMatchAppearance, focusTeamId: String) -> some View {
        let match = item.match
        let focusIsHome = match.homeTeamId == focusTeamId || match.homeTeamId == item.clubId
        let focusWon: Bool = {
            guard match.status == .finished else { return false }
            if match.homeScore == match.awayScore { return false }
            let focus = focusIsHome ? match.homeScore : match.awayScore
            let other = focusIsHome ? match.awayScore : match.homeScore
            return focus > other
        }()

        return VStack(spacing: 0) {
            MatchRowView(
                match: match,
                home: catalog.team(match.homeTeamId),
                away: catalog.team(match.awayTeamId),
                showCompetition: false
            )

            HStack(spacing: 12) {
                appearanceStat("G", "\(item.goals)")
                appearanceStat("A", "\(item.assists)")
                appearanceStat("KB", "\(item.points)")
                appearanceStat("TM", "\(item.penaltyMinutes)")

                Spacer(minLength: 0)

                if match.status == .finished {
                    Text(match.homeScore == match.awayScore ? "R" : (focusWon ? "V" : "P"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(width: 22, height: 22)
                        .background(
                            (match.homeScore == match.awayScore
                             ? HBTheme.draw
                             : (focusWon ? HBTheme.win : HBTheme.loss)),
                            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                        )
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 10)

            Rectangle()
                .fill(HBTheme.separator)
                .frame(height: 0.5)
        }
        .background(HBTheme.surface)
        .contentShape(Rectangle())
    }

    private func appearanceStat(_ label: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.hbMontserrat(size: 11, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(HBTheme.textPrimary)
        }
    }

    // MARK: - Seasons

    private var seasonsContent: some View {
        Group {
            if history.isEmpty {
                EmptyStateView(icon: "calendar", title: "Bez historie", message: "Zatím nemáme sezónní statistiky.")
                    .padding(.top, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(history) { row in
                        seasonRow(row)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func seasonRow(_ row: PlayerSeasonStat) -> some View {
        let team = catalog.team(row.clubId)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let team {
                    TeamBadge(team: team, size: 28)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.competitionName)
                        .font(.hbMontserrat(size: 14, weight: .semibold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .lineLimit(2)
                    Text("\(team?.shortName ?? "") · \(row.seasonLabel)")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                if row.position == .goalie {
                    seasonStat("Z", "\(row.games)")
                    seasonStat("%", String(format: "%.0f", row.savePercentage ?? 0))
                    seasonStat("GAA", String(format: "%.2f", row.goalsAgainstAverage ?? 0))
                    seasonStat("TM", "\(row.penaltyMinutes)")
                } else {
                    seasonStat("Z", "\(row.games)")
                    seasonStat("KB", "\(row.points)")
                    seasonStat("G", "\(row.goals)")
                    seasonStat("A", "\(row.assists)")
                    seasonStat("TM", "\(row.penaltyMinutes)")
                }
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
    }

    private func seasonStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.hbMontserrat(size: 10, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
            Text(value)
                .font(.hbMontserrat(size: 14, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Load

    private func load() async {
        player = try? await apiClient.api.player(id: playerId)
        history = (try? await apiClient.api.playerHistory(playerId: playerId)) ?? []
        selectedSeasonId = history.first?.seasonId ?? player?.seasonId

        var collected: [PlayerMatchAppearance] = []
        var seen = Set<String>()
        for row in history {
            let matches = (try? await apiClient.api.matches(query: MatchesQuery(competitionId: row.competitionId))) ?? []
            for match in matches {
                guard !seen.contains(match.id) else { continue }
                let goals = match.events.filter { $0.kind == .goal && $0.playerId == playerId }.count
                let assists = match.events.filter { $0.kind == .goal && $0.assistIds.contains(playerId) }.count
                let pens = match.events.filter { $0.kind == .penalty && $0.playerId == playerId }.count
                guard match.homeTeamId == row.clubId || match.awayTeamId == row.clubId else { continue }
                seen.insert(match.id)
                collected.append(
                    PlayerMatchAppearance(
                        id: match.id,
                        match: match,
                        clubId: row.clubId,
                        seasonId: row.seasonId,
                        goals: goals,
                        assists: assists,
                        points: goals + assists,
                        penaltyMinutes: pens * 2
                    )
                )
            }
        }
        appearances = collected.sorted { $0.match.scheduledAt > $1.match.scheduledAt }

        if let clubId = player?.teamId, let team = try? await apiClient.api.team(id: clubId) {
            catalog.upsertTeam(team)
        }
    }
}

struct PlayerMatchAppearance: Identifiable, Hashable {
    let id: String
    let match: Match
    let clubId: String
    let seasonId: String
    let goals: Int
    let assists: Int
    let points: Int
    let penaltyMinutes: Int
}

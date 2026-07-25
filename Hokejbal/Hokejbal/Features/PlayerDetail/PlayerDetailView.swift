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

    private var selectedSeasonStat: PlayerSeasonStat? {
        guard let selectedSeasonId else { return history.first }
        return history.first { $0.seasonId == selectedSeasonId } ?? history.first
    }

    var body: some View {
        Group {
            if let player {
                content(player)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(HBTheme.canvas)
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

            HBSwipeTabView(selection: $section) { tab in
                switch tab {
                case .matches:
                    matchesPane(player)
                case .seasons:
                    ScrollView {
                        seasonsContent
                            .padding(.bottom, 28)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HBTheme.canvas)
        }
        .background(HBTheme.canvas)
    }

    // MARK: - Header

    private func header(_ player: Player) -> some View {
        let team = catalog.team(player.teamId)
        let stats = selectedSeasonStat

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                PlayerAvatar(player: player, size: 68)

                VStack(alignment: .leading, spacing: 6) {
                    Text(player.fullName)
                        .font(.hbDisplay(size: 24, weight: .heavy))
                        .foregroundStyle(HBTheme.textPrimary)
                        .lineLimit(2)

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
                    }
                }

                Spacer(minLength: 0)
            }

            if let stats {
                playerStatsStrip(stats)
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(HBTheme.surface)
    }

    private func playerStatsStrip(_ stats: PlayerSeasonStat) -> some View {
        HStack(spacing: 0) {
            if stats.position == .goalie {
                headerStat("Z", "\(stats.games)")
                headerStat("%", String(format: "%.0f", stats.savePercentage ?? 0))
                headerStat("GAA", String(format: "%.2f", stats.goalsAgainstAverage ?? 0))
                headerStat("TM", "\(stats.penaltyMinutes)")
            } else {
                headerStat("Z", "\(stats.games)")
                headerStat("G", "\(stats.goals)")
                headerStat("A", "\(stats.assists)")
                headerStat("KB", "\(stats.points)")
                headerStat("TM", "\(stats.penaltyMinutes)")
            }
        }
        .padding(.vertical, 12)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
    }

    private func headerStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(HBTheme.textTertiary)
            Text(value)
                .font(.hbNumber(size: 16, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Matches

    private func matchesPane(_ player: Player) -> some View {
        VStack(spacing: 0) {
            if !seasonChips.isEmpty {
                seasonChipRow
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            if filteredAppearances.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "Bez zápasů",
                    message: "Pro zvolený ročník zatím nemáme zápasy hráče."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredAppearances) { item in
                            NavigationLink {
                                MatchDetailView(matchId: item.match.id)
                            } label: {
                                playerMatchRow(item, focusTeamId: player.teamId)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 28)
                }
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
                                    .fill(selected ? HBTheme.brand : HBTheme.card)
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(selected ? Color.clear : HBTheme.cardStroke, lineWidth: 1)
                            }
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
                showCompetition: false,
                embedded: true
            )

            Rectangle()
                .fill(HBTheme.cardStroke)
                .frame(height: 0.75)
                .padding(.horizontal, 14)

            HStack(spacing: 0) {
                appearanceStat("G", "\(item.goals)")
                appearanceStat("A", "\(item.assists)")
                appearanceStat("KB", "\(item.points)")
                appearanceStat("TM", "\(item.penaltyMinutes)")

                Spacer(minLength: 8)

                if match.status == .finished {
                    Text(match.homeScore == match.awayScore ? "R" : (focusWon ? "V" : "P"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(
                            (match.homeScore == match.awayScore
                             ? HBTheme.draw
                             : (focusWon ? HBTheme.win : HBTheme.loss)),
                            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                        )
                        .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
            .padding(.top, 8)
        }
        .background(HBTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    // MARK: - Seasons

    private var seasonsContent: some View {
        Group {
            if history.isEmpty {
                EmptyStateView(icon: "calendar", title: "Bez historie", message: "Zatím nemáme sezónní statistiky.")
                    .padding(.top, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(history) { row in
                        seasonCard(row)
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.top, 12)
            }
        }
    }

    private func seasonCard(_ row: PlayerSeasonStat) -> some View {
        let team = catalog.team(row.clubId)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let team {
                    TeamBadge(team: team, size: 28)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.competitionName)
                        .font(.hbMontserrat(size: 14, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .lineLimit(2)
                    Text("\(team?.shortName ?? "Tým") · \(row.seasonLabel)")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                if row.position == .goalie {
                    appearanceStat("Z", "\(row.games)")
                    appearanceStat("%", String(format: "%.0f", row.savePercentage ?? 0))
                    appearanceStat("GAA", String(format: "%.2f", row.goalsAgainstAverage ?? 0))
                    appearanceStat("TM", "\(row.penaltyMinutes)")
                } else {
                    appearanceStat("Z", "\(row.games)")
                    appearanceStat("G", "\(row.goals)")
                    appearanceStat("A", "\(row.assists)")
                    appearanceStat("KB", "\(row.points)")
                    appearanceStat("TM", "\(row.penaltyMinutes)")
                }
            }
            .padding(.vertical, 10)
            .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    /// Společná buňka statistik pro Zápasy i Sezóny.
    private func appearanceStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(HBTheme.textTertiary)
            Text(value)
                .font(.hbNumber(size: 14, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
        var matchesByCompetition: [String: [Match]] = [:]

        for row in history {
            let matches: [Match]
            if let cached = matchesByCompetition[row.competitionId] {
                matches = cached
            } else {
                let loaded = await MatchListCache.shared.matches(
                    competitionId: row.competitionId,
                    using: apiClient.api
                )
                matchesByCompetition[row.competitionId] = loaded
                matches = loaded
            }
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

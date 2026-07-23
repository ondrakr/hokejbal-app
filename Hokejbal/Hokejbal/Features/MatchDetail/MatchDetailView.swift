import SwiftUI

enum MatchDetailSection: String, CaseIterable, Hashable {
    case overview = "Přehled"
    case stats = "Statistiky"
    case lineups = "Sestavy"
    case table = "Tabulka"
}

enum MatchStatsScope: String, CaseIterable, Hashable {
    case match = "Zápas"
    case first = "1. třetina"
    case second = "2. třetina"
    case third = "3. třetina"
}

enum MatchLineupSide: String, CaseIterable, Hashable {
    case home = "Domácí"
    case away = "Hosté"
}

enum MatchTableScope: String, CaseIterable, Hashable {
    case overall = "Celkem"
    case scorers = "Střelci"
}

struct MatchDetailView: View {
    let matchId: String

    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var matchAlerts: MatchAlertsStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var match: Match?
    @State private var homePlayers: [Player] = []
    @State private var awayPlayers: [Player] = []
    @State private var standings: [StandingRow] = []
    @State private var section: MatchDetailSection = .overview
    @State private var statsScope: MatchStatsScope = .match
    @State private var lineupSide: MatchLineupSide = .home
    @State private var tableScope: MatchTableScope = .overall
    @State private var error: String?

    var body: some View {
        Group {
            if let match {
                content(match)
            } else if let error {
                ContentUnavailableView("Chyba", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    matchAlerts.toggle(matchId: matchId)
                } label: {
                    Image(systemName: matchAlerts.isEnabled(matchId: matchId) ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(matchAlerts.isEnabled(matchId: matchId) ? HBTheme.brand : HBTheme.textTertiary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    matchAlerts.isEnabled(matchId: matchId)
                        ? "Oznámení zápasu zapnuta"
                        : "Oznámení zápasu vypnuta"
                )

                FavoriteStarButton(
                    isFavorite: favorites.isFavorite(match: matchId),
                    accessibilityLabel: "Sledovat zápas"
                ) {
                    favorites.toggleMatch(matchId)
                }
            }
        }
        .task(id: matchId) { await load() }
        .onChange(of: liveScores.liveMatches) { _, live in
            if let updated = live.first(where: { $0.id == matchId }) {
                match = updated
            }
        }
    }

    private func content(_ match: Match) -> some View {
        let home = catalog.team(match.homeTeamId)
        let away = catalog.team(match.awayTeamId)
        let competition = catalog.competitions.first { $0.id == match.competitionId }

        return ScrollView {
            VStack(spacing: 16) {
                scoreCard(match: match, home: home, away: away, competition: competition)

                // Obsah v jednotném světlém panelu (v designu aplikace).
                VStack(spacing: 0) {
                    HBUnderlineTabs(selection: $section)

                    Group {
                        switch section {
                        case .overview:
                            MatchTimelineView(match: match)
                                .padding(.vertical, 14)
                        case .stats:
                            matchStats(match)
                        case .lineups:
                            lineups()
                        case .table:
                            leagueTable(match)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 640, alignment: .top)
                .padding(.top, 6)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: HBTheme.radiusLg, topTrailingRadius: HBTheme.radiusLg, style: .continuous)
                        .fill(HBTheme.surface)
                )
            }
            .padding(.top, 10)
        }
        .background(HBTheme.canvas)
        .refreshable { await load() }
    }

    // MARK: - Score card (světlá karta v designu aplikace)

    private func scoreCard(match: Match, home: Team?, away: Team?, competition: Competition?) -> some View {
        VStack(spacing: 16) {
            heroCompetition(competition, match: match)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 6) {
                heroTeam(home)
                heroCenter(match)
                    .frame(minWidth: 116)
                heroTeam(away)
            }

            if match.isBroadcast {
                broadcastLink(match)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .hbCard(cornerRadius: HBTheme.radiusLg)
        .padding(.horizontal, HBTheme.screenPadding)
    }

    @ViewBuilder
    private func heroCompetition(_ competition: Competition?, match: Match) -> some View {
        let phase = match.phaseOrDefault.label
        let title: String = {
            var parts = [(competition?.name ?? match.competitionId).uppercased()]
            if !phase.isEmpty { parts.append(phase.uppercased()) }
            if match.round > 0 { parts.append("\(match.round). KOLO") }
            return parts.joined(separator: " · ")
        }()

        let label = HStack(spacing: 8) {
            HBAccentBar(height: 16)
            if let competition { CompetitionBadge(competition: competition, size: 18) }
            Text(title)
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textSecondary)
                .lineLimit(1)
            if competition != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(HBTheme.textTertiary)
            }
        }

        if let competition {
            NavigationLink { CompetitionDetailView(competitionId: competition.id) } label: { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private func heroTeam(_ team: Team?) -> some View {
        VStack(spacing: 10) {
            if let team {
                NavigationLink { TeamDetailView(teamId: team.id) } label: {
                    VStack(spacing: 10) {
                        TeamBadge(team: team, size: 58)
                            .padding(12)
                            .background(HBTheme.cardInset, in: Circle())
                        Text(team.shortName)
                            .font(.hbMontserrat(size: 14, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func heroCenter(_ match: Match) -> some View {
        VStack(spacing: 8) {
            if match.isLive {
                LiveBadge(compact: false)
            } else {
                Text(statusLabel(match).uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(HBTheme.cardInset, in: Capsule())
            }

            if match.status == .scheduled {
                Text(match.scheduledAt.hbTime)
                    .font(.hbNumber(size: 40, weight: .heavy))
                    .foregroundStyle(HBTheme.brand)
            } else {
                Text("\(match.homeScore) : \(match.awayScore)")
                    .font(.hbNumber(size: 40, weight: .heavy))
                    .foregroundStyle(match.isLive ? HBTheme.live : HBTheme.textPrimary)
            }

            Text("\(match.scheduledAt.hbShortDate) · \(match.scheduledAt.hbTime)")
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func broadcastLink(_ match: Match) -> some View {
        let label = "ŽIVÝ PŘENOS: Hokejbal TV"
        Group {
            if let urlString = match.streamURL, let url = URL(string: urlString) {
                Link(destination: url) {
                    broadcastRow(label: label, interactive: true)
                }
            } else {
                broadcastRow(label: label, interactive: false)
            }
        }
    }

    private func broadcastRow(label: String, interactive: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "tv")
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(.hbMontserrat(size: 13, weight: .bold))
            Spacer(minLength: 0)
            if interactive {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundStyle(interactive ? Color.white : HBTheme.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous)
                .fill(interactive ? AnyShapeStyle(HBTheme.brand) : AnyShapeStyle(HBTheme.cardInset))
        )
    }

    private func statusLabel(_ match: Match) -> String {
        switch match.status {
        case .live:
            return match.period.rawValue.isEmpty ? "LIVE" : match.period.rawValue
        case .finished:
            if match.period == .overtime { return "Po prodloužení" }
            if match.period == .shootout { return "Po nájezdech" }
            return "Konec"
        case .scheduled:
            return "Začátek"
        case .postponed:
            return "Odloženo"
        }
    }

    private func lineups() -> some View {
        let players = lineupSide == .home ? homePlayers : awayPlayers

        return VStack(alignment: .leading, spacing: 0) {
            HBPillSelector(selection: $lineupSide)

            if players.isEmpty {
                EmptyStateView(icon: "person.3", title: "Bez sestavy", message: "Soupiska týmu zatím není k dispozici.")
                    .padding(.top, 24)
            } else {
                lineupHeader
                ForEach(players.sorted { $0.number < $1.number }) { player in
                    NavigationLink {
                        PlayerDetailView(playerId: player.id)
                    } label: {
                        lineupRow(player)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 16)
    }

    private var lineupHeader: some View {
        HStack(spacing: 0) {
            Text("HRÁČ")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("B").frame(width: 28, alignment: .trailing)
            Text("G").frame(width: 28, alignment: .trailing)
            Text("A").frame(width: 28, alignment: .trailing)
            Text("TM").frame(width: 36, alignment: .trailing)
        }
        .font(.hbMontserrat(size: 11, weight: .semibold))
        .foregroundStyle(HBTheme.textTertiary)
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 8)
    }

    private func lineupRow(_ player: Player) -> some View {
        HStack(spacing: 10) {
            playerAvatar(player)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.hbMontserrat(size: 14, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
                Text(player.position.label.capitalized)
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(player.points)")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(HBTheme.textPrimary)
                .frame(width: 28, alignment: .trailing)
            Text("\(player.goals)")
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 28, alignment: .trailing)
            Text("\(player.assists)")
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 28, alignment: .trailing)
            Text("\(player.penaltyMinutes)")
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
        .contentShape(Rectangle())
    }

    private func playerAvatar(_ player: Player) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(HBTheme.tertiarySurface)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HBTheme.textTertiary)
                }

            Text("\(player.number)")
                .font(.system(size: 9, weight: .bold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(HBTheme.brand, in: Circle())
                .offset(x: 2, y: 2)
        }
    }

    // MARK: - Statistiky (Livesport bars)

    private func matchStats(_ match: Match) -> some View {
        let homeShots = resolvedShots(home: true, match: match)
        let awayShots = resolvedShots(home: false, match: match)
        let homePen = match.homePenaltyCount
        let awayPen = match.awayPenaltyCount
        let homePP = match.homePowerplayCount
        let awayPP = match.awayPowerplayCount
        let homePPG = match.homePowerplayGoals ?? 0
        let awayPPG = match.awayPowerplayGoals ?? 0
        let homeSH = match.homeShorthandedGoals ?? 0
        let awaySH = match.awayShorthandedGoals ?? 0

        return VStack(alignment: .leading, spacing: 0) {
            HBPillSelector(selection: $statsScope)

            VStack(spacing: 22) {
                if statsScope == .match {
                    comparisonStat(title: "Střely", home: homeShots, away: awayShots)
                    comparisonStat(title: "Vyloučení", home: homePen, away: awayPen)
                    comparisonStat(title: "Přesilovky", home: homePP, away: awayPP)
                    comparisonStat(title: "Využití", home: homePPG, away: awayPPG)
                    comparisonStat(title: "Oslabení", home: homeSH, away: awaySH)

                    metaStat(title: "Počet diváků", value: match.attendance.map(String.init) ?? "—")
                    metaStat(title: "Rozhodčí", value: match.referees?.isEmpty == false ? (match.referees ?? "—") : "—")
                } else {
                    let periodIndex = statsScope == .first ? 0 : (statsScope == .second ? 1 : 2)
                    let homeP = periodScore(match.homePeriodScores, at: periodIndex)
                    let awayP = periodScore(match.awayPeriodScores, at: periodIndex)
                    comparisonStat(title: "Góly", home: homeP, away: awayP)
                    Text("Detailní statistiky po třetinách budou doplněny.")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 20)
        }
    }

    private func resolvedShots(home: Bool, match: Match) -> Int {
        if home, let s = match.homeShots { return s }
        if !home, let s = match.awayShots { return s }
        // Odhad, když ještě nejsou data ze systému.
        let score = home ? match.homeScore : match.awayScore
        return max(score * 7 + 10, 8)
    }

    private func periodScore(_ scores: [Int], at index: Int) -> Int {
        index < scores.count ? scores[index] : 0
    }

    private func comparisonStat(title: String, home: Int, away: Int) -> some View {
        let total = max(home + away, 1)
        let homeRatio = CGFloat(home) / CGFloat(total)
        let awayRatio = CGFloat(away) / CGFloat(total)

        return VStack(spacing: 8) {
            HStack {
                Text("\(home)")
                    .font(.hbMontserrat(size: 16, weight: .bold).monospacedDigit())
                    .foregroundStyle(HBTheme.textPrimary)
                    .frame(width: 40, alignment: .leading)

                Text(title)
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.textSecondary)
                    .frame(maxWidth: .infinity)

                Text("\(away)")
                    .font(.hbMontserrat(size: 16, weight: .bold).monospacedDigit())
                    .foregroundStyle(HBTheme.textPrimary)
                    .frame(width: 40, alignment: .trailing)
            }

            HStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .trailing) {
                        Capsule().fill(HBTheme.tertiarySurface)
                        Capsule()
                            .fill(HBTheme.brand)
                            .frame(width: max(geo.size.width * homeRatio, home > 0 ? 6 : 0))
                    }
                }
                .frame(height: 6)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(HBTheme.tertiarySurface)
                        Capsule()
                            .fill(HBTheme.textPrimary.opacity(0.75))
                            .frame(width: max(geo.size.width * awayRatio, away > 0 ? 6 : 0))
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private func metaStat(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.hbMontserrat(size: 13, weight: .semibold))
                .foregroundStyle(HBTheme.textSecondary)
            Text(value)
                .font(.hbMontserrat(size: 15, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Tabulka (Livesport)

    private func leagueTable(_ match: Match) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HBPillSelector(selection: $tableScope)

            switch tableScope {
            case .overall:
                standingsTable(highlightIds: [match.homeTeamId, match.awayTeamId])
            case .scorers:
                scorersTable
            }
        }
        .padding(.bottom, 16)
    }

    private func standingsTable(highlightIds: Set<String>) -> some View {
        Group {
            if standings.isEmpty {
                EmptyStateView(icon: "list.number", title: "Bez tabulky", message: "Tabulka pro tuto soutěž není k dispozici.")
                    .padding(.top, 24)
            } else {
                HStack(spacing: 0) {
                    Text("#").frame(width: 28, alignment: .leading)
                    Text("TÝM").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Z").frame(width: 28, alignment: .trailing)
                    Text("G").frame(width: 52, alignment: .trailing)
                    Text("B").frame(width: 28, alignment: .trailing)
                }
                .font(.hbMontserrat(size: 11, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 8)

                ForEach(standings) { row in
                    NavigationLink {
                        TeamDetailView(teamId: row.teamId)
                    } label: {
                        standingsRow(row, highlighted: highlightIds.contains(row.teamId))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func standingsRow(_ row: StandingRow, highlighted: Bool) -> some View {
        let team = catalog.team(row.teamId)
        return HStack(spacing: 8) {
            Text("\(row.rank)")
                .font(.system(size: 11, weight: .bold).monospacedDigit())
                .foregroundStyle(rankForeground(row.rank))
                .frame(width: 22, height: 22)
                .background(rankBackground(row.rank), in: Circle())

            if let team {
                TeamBadge(team: team, size: 22)
                Text(team.shortName)
                    .font(.hbMontserrat(size: 14, weight: highlighted ? .bold : .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
            } else {
                Text(row.teamId)
                    .font(.hbMontserrat(size: 14, weight: .medium))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text("\(row.played)")
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 28, alignment: .trailing)
            Text(row.scoreText)
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 52, alignment: .trailing)
            Text("\(row.points)")
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(HBTheme.textPrimary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.leading, HBTheme.screenPadding)
        .padding(.trailing, HBTheme.screenPadding)
        .padding(.vertical, 10)
        .background(highlighted ? HBTheme.brand.opacity(0.06) : Color.clear)
        .overlay(alignment: .leading) {
            if highlighted {
                Rectangle()
                    .fill(HBTheme.brand)
                    .frame(width: 3)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
        .contentShape(Rectangle())
    }

    private func rankBackground(_ rank: Int) -> Color {
        if rank <= 3 { return Color(red: 0.22, green: 0.45, blue: 0.85) }
        if rank <= 8 { return Color(red: 0.18, green: 0.55, blue: 0.72) }
        return HBTheme.tertiarySurface
    }

    private func rankForeground(_ rank: Int) -> Color {
        rank <= 8 ? .white : HBTheme.textSecondary
    }

    private var scorersTable: some View {
        let scorers = (homePlayers + awayPlayers)
            .filter { $0.position != .goalie }
            .sorted { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points }
                if lhs.goals != rhs.goals { return lhs.goals > rhs.goals }
                return lhs.lastName < rhs.lastName
            }

        return Group {
            if scorers.isEmpty {
                EmptyStateView(icon: "hockey.puck", title: "Bez střelců", message: "Statistiky hráčů zatím nejsou k dispozici.")
                    .padding(.top, 24)
            } else {
                HStack(spacing: 0) {
                    Text("#").frame(width: 28, alignment: .leading)
                    Text("HRÁČ").frame(maxWidth: .infinity, alignment: .leading)
                    Text("G").frame(width: 28, alignment: .trailing)
                    Text("A").frame(width: 28, alignment: .trailing)
                    Text("B").frame(width: 28, alignment: .trailing)
                }
                .font(.hbMontserrat(size: 11, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 8)

                ForEach(Array(scorers.enumerated()), id: \.element.id) { index, player in
                    NavigationLink {
                        PlayerDetailView(playerId: player.id)
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold).monospacedDigit())
                                .foregroundStyle(HBTheme.textSecondary)
                                .frame(width: 28, alignment: .leading)

                            if let team = catalog.team(player.teamId) {
                                TeamBadge(team: team, size: 20)
                            }
                            Text(player.fullName)
                                .font(.hbMontserrat(size: 14, weight: .semibold))
                                .foregroundStyle(HBTheme.textPrimary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(player.goals)").frame(width: 28, alignment: .trailing)
                            Text("\(player.assists)").frame(width: 28, alignment: .trailing)
                            Text("\(player.points)")
                                .fontWeight(.bold)
                                .frame(width: 28, alignment: .trailing)
                        }
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(HBTheme.textSecondary)
                        .padding(.horizontal, HBTheme.screenPadding)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load() async {
        do {
            let loaded: Match
            if let live = liveScores.liveMatches.first(where: { $0.id == matchId }) {
                loaded = live
            } else {
                loaded = try await apiClient.api.matchDetail(id: matchId)
            }
            match = loaded
            async let home = apiClient.api.players(teamId: loaded.homeTeamId)
            async let away = apiClient.api.players(teamId: loaded.awayTeamId)
            async let table = apiClient.api.standings(competitionId: loaded.competitionId)
            homePlayers = (try? await home) ?? []
            awayPlayers = (try? await away) ?? []
            standings = (try? await table) ?? []
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Timeline (Přehled) — Livesport layout

struct MatchTimelineView: View {
    @EnvironmentObject private var catalog: CatalogStore
    let match: Match

    private var timelineEvents: [MatchEvent] {
        match.events
            .filter { $0.kind == .goal || $0.kind == .penalty }
            .sorted {
                if $0.period != $1.period { return $0.period < $1.period }
                if $0.minute != $1.minute { return $0.minute < $1.minute }
                return $0.second < $1.second
            }
    }

    private var periods: [Int] {
        let fromEvents = Set(timelineEvents.map(\.period))
        let fromScores = max(match.homePeriodScores.count, match.awayPeriodScores.count)
        let all = fromEvents.union(fromScores > 0 ? Set(1...fromScores) : [])
        return all.sorted()
    }

    var body: some View {
        if timelineEvents.isEmpty && match.homePeriodScores.isEmpty {
            EmptyStateView(icon: "list.bullet.rectangle", title: "Bez událostí", message: "Až padnou góly, uvidíte je tady chronologicky.")
        } else {
            VStack(spacing: 0) {
                ForEach(periods, id: \.self) { period in
                    periodHeader(period)
                    ForEach(events(in: period)) { event in
                        eventRow(event, running: runningScore(beforeAndIncluding: event))
                    }
                }
            }
        }
    }

    private func events(in period: Int) -> [MatchEvent] {
        timelineEvents.filter { $0.period == period }
    }

    private func periodHeader(_ period: Int) -> some View {
        let homeP = period <= match.homePeriodScores.count ? match.homePeriodScores[period - 1] : 0
        let awayP = period <= match.awayPeriodScores.count ? match.awayPeriodScores[period - 1] : 0
        return HStack {
            Text(periodTitle(period))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
                .tracking(0.3)
            Spacer()
            Text("\(homeP) - \(awayP)")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 11)
        .background(HBTheme.secondarySurface)
        .frame(maxWidth: .infinity)
    }

    private func periodTitle(_ period: Int) -> String {
        switch period {
        case 1: return "1. TŘETINA"
        case 2: return "2. TŘETINA"
        case 3: return "3. TŘETINA"
        case 4: return "PRODLOUŽENÍ"
        default: return "\(period). ČÁST"
        }
    }

    private func runningScore(beforeAndIncluding event: MatchEvent) -> (Int, Int) {
        var home = 0
        var away = 0
        for e in timelineEvents {
            if e.kind == .goal {
                if e.teamId == match.homeTeamId { home += 1 }
                else if e.teamId == match.awayTeamId { away += 1 }
            }
            if e.id == event.id { break }
        }
        return (home, away)
    }

    private func eventRow(_ event: MatchEvent, running: (Int, Int)) -> some View {
        let isHome = event.teamId == match.homeTeamId
        let time = String(format: "%02d:%02d", event.minute, event.second)
        let playerName = displayName(for: event)
        let assists = event.assistIds.compactMap { catalog.playersById[$0]?.shortName }.joined(separator: " + ")
        let reason = penaltyReasonOnly(event.description)

        return HStack(alignment: .top, spacing: 0) {
            if isHome {
                homeEvent(
                    time: time,
                    event: event,
                    playerName: playerName,
                    assists: assists,
                    reason: reason,
                    running: running
                )
                Spacer(minLength: 20)
            } else {
                Spacer(minLength: 20)
                awayEvent(
                    time: time,
                    event: event,
                    playerName: playerName,
                    assists: assists,
                    reason: reason,
                    running: running
                )
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 14)
    }

    // MARK: Home (left)

    private func homeEvent(
        time: String,
        event: MatchEvent,
        playerName: String,
        assists: String,
        reason: String,
        running: (Int, Int)
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(time)
                .font(.system(size: 13, weight: .regular).monospacedDigit())
                .foregroundStyle(HBTheme.textPrimary)
                .frame(width: 42, alignment: .leading)

            eventBadge(event, running: running)

            VStack(alignment: .leading, spacing: 2) {
                playerLine(event: event, name: playerName, reason: reason, isHome: true)
                if event.kind == .goal, !assists.isEmpty {
                    Text(assists)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(HBTheme.textTertiary)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: Away (right)

    private func awayEvent(
        time: String,
        event: MatchEvent,
        playerName: String,
        assists: String,
        reason: String,
        running: (Int, Int)
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 2) {
                playerLine(event: event, name: playerName, reason: reason, isHome: false)
                if event.kind == .goal, !assists.isEmpty {
                    Text(assists)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(HBTheme.textTertiary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }

            eventBadge(event, running: running)

            Text(time)
                .font(.system(size: 13, weight: .regular).monospacedDigit())
                .foregroundStyle(HBTheme.textPrimary)
                .frame(width: 42, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func playerLine(event: MatchEvent, name: String, reason: String, isHome: Bool) -> some View {
        let nameView = Group {
            if let playerId = event.playerId {
                NavigationLink { PlayerDetailView(playerId: playerId) } label: {
                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                }
                .buttonStyle(.plain)
            } else {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
            }
        }

        if event.kind == .penalty, !reason.isEmpty {
            HStack(spacing: 4) {
                if isHome {
                    nameView
                    Text("(\(reason))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(HBTheme.textTertiary)
                } else {
                    Text("(\(reason))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(HBTheme.textTertiary)
                    nameView
                }
            }
        } else {
            nameView
        }
    }

    @ViewBuilder
    private func eventBadge(_ event: MatchEvent, running: (Int, Int)) -> some View {
        if event.kind == .goal {
            HStack(spacing: 5) {
                Image(systemName: "hockey.puck.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("\(running.0) - \(running.1)")
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(white: 0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            )
        } else {
            Text(penaltyMinutes(event.description))
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(.black)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                )
        }
    }

    private func displayName(for event: MatchEvent) -> String {
        if let id = event.playerId, let player = catalog.playersById[id] {
            return player.shortName
        }
        // Odstraní prefix typu „Gól “ / „Vyloučení…“ z popisu.
        let desc = event.description
        if let range = desc.range(of: "–") {
            let after = desc[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if let paren = after.firstIndex(of: "(") {
                return after[..<paren].trimmingCharacters(in: .whitespaces)
            }
            return after
        }
        return desc
    }

    private func penaltyReasonOnly(_ description: String) -> String {
        if let open = description.firstIndex(of: "("),
           let close = description.firstIndex(of: ")"),
           open < close {
            return String(description[description.index(after: open)..<close])
        }
        if let dash = description.range(of: "–") ?? description.range(of: "-") {
            let after = description[dash.upperBound...].trimmingCharacters(in: .whitespaces)
            // „Čejka (Hrubost)“ nebo jen „Hrubost“
            if let open = after.firstIndex(of: "("),
               let close = after.firstIndex(of: ")"),
               open < close {
                return String(after[after.index(after: open)..<close])
            }
            // Odstraň jméno před závorkou, pokud je ve formátu „Jméno důvod“
            return after
        }
        return "Vyloučení"
    }

    private func penaltyMinutes(_ description: String) -> String {
        let pattern = #"(\d+)\s*min"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: description, range: NSRange(description.startIndex..., in: description)),
           let range = Range(match.range(at: 1), in: description) {
            return String(description[range])
        }
        return "2"
    }
}

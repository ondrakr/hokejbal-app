import SwiftUI

enum MatchDetailSection: String, Hashable {
    case match = "Zápas"
    case overview = "Přehled"
    case stats = "Statistiky"
    case lineups = "Sestavy"
    case table = "Tabulka"

    /// Pořadí karet podle stavu zápasu.
    static func tabs(for status: MatchStatus) -> [MatchDetailSection] {
        switch status {
        case .scheduled, .postponed:
            return [.overview, .stats, .lineups, .table]
        case .live, .finished:
            return [.match, .stats, .lineups, .table, .overview]
        }
    }

    static func defaultSection(for status: MatchStatus) -> MatchDetailSection {
        switch status {
        case .scheduled, .postponed: return .overview
        case .live, .finished: return .match
        }
    }
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

struct MatchDetailView: View {
    let matchId: String

    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var matchAlerts: MatchAlertsStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var tips: MatchTipStore
    @EnvironmentObject private var banners: InAppBannerCenter

    @State private var match: Match?
    @State private var homePlayers: [Player] = []
    @State private var awayPlayers: [Player] = []
    @State private var standings: [StandingRow] = []
    @State private var homeForm: [TeamFormItem] = []
    @State private var awayForm: [TeamFormItem] = []
    @State private var section: MatchDetailSection = .overview
    @State private var statsScope: MatchStatsScope = .match
    @State private var lineupSide: MatchLineupSide = .home
    @State private var error: String?
    @State private var didApplyInitialSection = false

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
        .task(id: matchId) {
            banners.beginViewingMatch(matchId)
            defer { banners.endViewingMatch(matchId) }

            didApplyInitialSection = false
            await load()

            // Drží „prohlížím zápas“ dokud je obrazovka v hierarchii (i při push na hráče).
            await withTaskCancellationHandler {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3600))
                }
            } onCancel: {}
        }
        .keepScreenOnWhileVisible()
        .onChange(of: liveScores.liveMatches) { _, live in
            if let updated = live.first(where: { $0.id == matchId }) {
                applyMatchUpdate(updated)
            }
        }
    }

    private func applyMatchUpdate(_ updated: Match) {
        let previous = match?.status
        match = updated
        if let previous, (previous == .scheduled || previous == .postponed),
           (updated.status == .live || updated.status == .finished) {
            section = .match
        }
    }

    private func content(_ match: Match) -> some View {
        let home = catalog.team(match.homeTeamId)
        let away = catalog.team(match.awayTeamId)
        let competition = catalog.competitions.first { $0.id == match.competitionId }
        let tabs = MatchDetailSection.tabs(for: match.status)

        return VStack(spacing: 14) {
            scoreCard(match: match, home: home, away: away, competition: competition)
                .padding(.top, 10)

            VStack(spacing: 0) {
                HBUnderlineTabBar(
                    items: tabs.map { .init(id: $0, title: $0.rawValue) },
                    selection: $section,
                    equalWidth: false,
                    embedded: true
                )

                TabView(selection: $section) {
                    ForEach(tabs, id: \.self) { tab in
                        ScrollView(.vertical, showsIndicators: false) {
                            sectionBody(tab, match: match, home: home, away: away)
                                .padding(.vertical, 12)
                                .padding(.bottom, 16)
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                        .tag(tab)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // Page TabView jen horizontálně — vertikál nechá vnitřnímu ScrollView.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous))
            .hbCard(cornerRadius: HBTheme.radiusLg)
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 12)
        }
        .background(HBTheme.canvas)
        .refreshable { await load() }
        .onChange(of: match.status) { _, status in
            let allowed = MatchDetailSection.tabs(for: status)
            if !allowed.contains(section) {
                section = MatchDetailSection.defaultSection(for: status)
            }
        }
    }

    @ViewBuilder
    private func sectionBody(
        _ tab: MatchDetailSection,
        match: Match,
        home: Team?,
        away: Team?
    ) -> some View {
        switch tab {
        case .match:
            MatchTimelineView(match: match, home: home, away: away)
        case .overview:
            MatchOverviewView(
                match: match,
                home: home,
                away: away,
                homeForm: homeForm,
                awayForm: awayForm
            )
        case .stats:
            matchStats(match)
        case .lineups:
            lineups()
        case .table:
            leagueTable(match)
        }
    }

    // MARK: - Score card (světlá karta v designu aplikace)

    private func scoreCard(match: Match, home: Team?, away: Team?, competition: Competition?) -> some View {
        VStack(spacing: 16) {
            heroCompetition(competition, match: match)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 8) {
                heroTeam(home)
                heroCenter(match)
                    .frame(width: 118)
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
        let title: String = {
            var parts = [(competition?.name ?? match.competitionId).uppercased()]
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
        VStack(spacing: 8) {
            if let team {
                NavigationLink { TeamDetailView(teamId: team.id) } label: {
                    VStack(spacing: 8) {
                        TeamBadge(team: team, size: 48)
                        Text(team.shortName)
                            .font(.hbMontserrat(size: 13, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
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
                    .font(.hbNumber(size: 34, weight: .heavy))
                    .foregroundStyle(HBTheme.brand)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: true, vertical: false)
            } else {
                Text("\(match.homeScore) : \(match.awayScore)")
                    .font(.hbNumber(size: 34, weight: .heavy))
                    .foregroundStyle(match.isLive ? HBTheme.live : HBTheme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Text("\(match.scheduledAt.hbShortDate) · \(match.scheduledAt.hbTime)")
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 118)
    }

    @ViewBuilder
    private func broadcastLink(_ match: Match) -> some View {
        let label = "ŽIVÝ PŘENOS: Hokejbal TV"
        Group {
            if let url = HBTrustedURL.openable(match.streamURL) {
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
            PlayerAvatar(player: player, size: 40, cornerRadius: 20)

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
        let scheduled = match.status == .scheduled
        let homeShots = scheduled ? 0 : resolvedShots(home: true, match: match)
        let awayShots = scheduled ? 0 : resolvedShots(home: false, match: match)
        let homePen = scheduled ? 0 : match.homePenaltyCount
        let awayPen = scheduled ? 0 : match.awayPenaltyCount
        let homePP = scheduled ? 0 : match.homePowerplayCount
        let awayPP = scheduled ? 0 : match.awayPowerplayCount
        let homePPG = scheduled ? 0 : (match.homePowerplayGoals ?? 0)
        let awayPPG = scheduled ? 0 : (match.awayPowerplayGoals ?? 0)
        let homeSH = scheduled ? 0 : (match.homeShorthandedGoals ?? 0)
        let awaySH = scheduled ? 0 : (match.awayShorthandedGoals ?? 0)

        return VStack(alignment: .leading, spacing: 0) {
            HBPillSelector(selection: $statsScope, compact: true)

            VStack(spacing: 22) {
                if statsScope == .match {
                    comparisonStat(title: "Střely", home: homeShots, away: awayShots)
                    comparisonStat(title: "Vyloučení", home: homePen, away: awayPen)
                    comparisonStat(title: "Přesilovky", home: homePP, away: awayPP)
                    comparisonStat(title: "Využití", home: homePPG, away: awayPPG)
                    comparisonStat(title: "Oslabení", home: homeSH, away: awaySH)

                    metaStat(
                        title: "Počet diváků",
                        value: scheduled ? "0" : (match.attendance.map(String.init) ?? "—")
                    )
                } else {
                    let periodIndex = statsScope == .first ? 0 : (statsScope == .second ? 1 : 2)
                    let homeP = scheduled ? 0 : periodScore(match.homePeriodScores, at: periodIndex)
                    let awayP = scheduled ? 0 : periodScore(match.awayPeriodScores, at: periodIndex)
                    comparisonStat(title: "Góly", home: homeP, away: awayP)
                    if !scheduled {
                        Text("Detailní statistiky po třetinách budou doplněny.")
                            .font(.hbMontserrat(size: 12, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 20)
        }
    }

    private func resolvedShots(home: Bool, match: Match) -> Int {
        if match.status == .scheduled { return 0 }
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

    // MARK: - Tabulka

    private func leagueTable(_ match: Match) -> some View {
        let slug = catalog.competitions.first { $0.id == match.competitionId }?.slug
        return StandingsTableView(
            rows: standings,
            highlightTeamIds: [match.homeTeamId, match.awayTeamId],
            emptyMessage: "Tabulka pro tuto soutěž není k dispozici.",
            competitionSlug: slug
        )
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
            async let homeHistory = apiClient.api.matches(query: MatchesQuery(
                competitionId: loaded.competitionId,
                seasonId: nil,
                date: nil,
                status: .finished,
                teamId: loaded.homeTeamId
            ))
            async let awayHistory = apiClient.api.matches(query: MatchesQuery(
                competitionId: loaded.competitionId,
                seasonId: nil,
                date: nil,
                status: .finished,
                teamId: loaded.awayTeamId
            ))
            homePlayers = (try? await home) ?? []
            awayPlayers = (try? await away) ?? []
            standings = (try? await table) ?? []
            let homeMatches = (try? await homeHistory) ?? []
            let awayMatches = (try? await awayHistory) ?? []
            homeForm = TeamFormCalculator.items(
                from: homeMatches,
                teamId: loaded.homeTeamId,
                excludingMatchId: loaded.id
            )
            awayForm = TeamFormCalculator.items(
                from: awayMatches,
                teamId: loaded.awayTeamId,
                excludingMatchId: loaded.id
            )
            tips.resolve(matches: [loaded])
            if !didApplyInitialSection {
                section = MatchDetailSection.defaultSection(for: loaded.status)
                didApplyInitialSection = true
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Přehled (tipovačka, meta, forma, rozhodčí)

struct MatchOverviewView: View {
    @EnvironmentObject private var catalog: CatalogStore
    let match: Match
    var home: Team? = nil
    var away: Team? = nil
    var homeForm: [TeamFormItem] = []
    var awayForm: [TeamFormItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MatchTipCard(match: match, home: home, away: away)
                .padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 12) {
                previewRow(title: "Začátek", value: "\(match.scheduledAt.hbShortDate) · \(match.scheduledAt.hbTime)")
                if !match.venue.isEmpty {
                    previewRow(title: "Místo", value: match.venue)
                }
                if match.round > 0 {
                    previewRow(title: "Kolo", value: "\(match.round). kolo")
                }
                if let phase = match.phase {
                    previewRow(title: "Fáze", value: phase.label)
                }

                MatchFormPreview(
                    home: home ?? catalog.team(match.homeTeamId),
                    away: away ?? catalog.team(match.awayTeamId),
                    homeForm: homeForm,
                    awayForm: awayForm
                )
                .padding(.top, 4)

                previewRow(
                    title: "Rozhodčí",
                    value: match.referees?.isEmpty == false ? (match.referees ?? "—") : "—"
                )
            }
            .padding(.horizontal, 14)
        }
    }

    private func previewRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.hbMontserrat(size: 13, weight: .semibold))
                .foregroundStyle(HBTheme.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.hbMontserrat(size: 14, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))
    }
}

// MARK: - Timeline (Zápas)

struct MatchTimelineView: View {
    @EnvironmentObject private var catalog: CatalogStore
    let match: Match
    var home: Team? = nil
    var away: Team? = nil

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
        VStack(alignment: .leading, spacing: 16) {
            if timelineEvents.isEmpty && match.homePeriodScores.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "Bez událostí",
                    message: "Až padnou góly, uvidíte je tady chronologicky."
                )
                .padding(.top, 12)
            } else {
                ForEach(periods, id: \.self) { period in
                    periodBlock(period)
                }
                .padding(.horizontal, 12)
            }
        }
    }

    private func periodBlock(_ period: Int) -> some View {
        let items = events(in: period)
        return VStack(alignment: .leading, spacing: 8) {
            periodHeader(period)
            ForEach(items) { event in
                eventRow(event, running: runningScore(beforeAndIncluding: event))
            }
        }
    }

    private func events(in period: Int) -> [MatchEvent] {
        timelineEvents.filter { $0.period == period }
    }

    private func periodHeader(_ period: Int) -> some View {
        let homeP = period <= match.homePeriodScores.count ? match.homePeriodScores[period - 1] : 0
        let awayP = period <= match.awayPeriodScores.count ? match.awayPeriodScores[period - 1] : 0

        return HStack(spacing: 10) {
            Text(periodTitle(period))
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(HBTheme.textSecondary)

            Rectangle()
                .fill(HBTheme.cardStroke)
                .frame(height: 1)

            Text("\(homeP) – \(awayP)")
                .font(.hbNumber(size: 13, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(HBTheme.cardInset, in: Capsule())
        }
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
        let assists = assistEntries(for: event)
        let reason = penaltyReasonOnly(event.description)

        return HStack(alignment: .top, spacing: 8) {
            Group {
                if isHome {
                    sideContent(
                        event: event,
                        time: time,
                        playerName: playerName,
                        assists: assists,
                        reason: reason,
                        running: running,
                        alignment: .leading
                    )
                } else {
                    Color.clear.frame(height: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if !isHome {
                    sideContent(
                        event: event,
                        time: time,
                        playerName: playerName,
                        assists: assists,
                        reason: reason,
                        running: running,
                        alignment: .trailing
                    )
                } else {
                    Color.clear.frame(height: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    private func sideContent(
        event: MatchEvent,
        time: String,
        playerName: String,
        assists: [(id: String?, name: String)],
        reason: String,
        running: (Int, Int),
        alignment: HorizontalAlignment
    ) -> some View {
        let isLeading = alignment == .leading
        return VStack(alignment: alignment, spacing: 3) {
            HStack(alignment: .center, spacing: 6) {
                if isLeading {
                    Text(time)
                        .font(.hbNumber(size: 12, weight: .bold))
                        .foregroundStyle(HBTheme.textTertiary)
                        .fixedSize(horizontal: true, vertical: false)
                    eventBadge(event, running: running)
                    goalPlayerLine(event: event, name: playerName, assists: assists)
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    goalPlayerLine(event: event, name: playerName, assists: assists)
                    eventBadge(event, running: running)
                    Text(time)
                        .font(.hbNumber(size: 12, weight: .bold))
                        .foregroundStyle(HBTheme.textTertiary)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            if event.kind == .penalty, !reason.isEmpty {
                Text(reason)
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
                    .multilineTextAlignment(isLeading ? .leading : .trailing)
                    .lineLimit(1)
            }
        }
    }

    /// Střelec + asistence vždy na jednom řádku: „Novák (Čejka, Diviš)“
    private func goalPlayerLine(
        event: MatchEvent,
        name: String,
        assists: [(id: String?, name: String)]
    ) -> some View {
        HStack(alignment: .center, spacing: 0) {
            playerNameLink(id: event.playerId, name: name, bold: true)
            if event.kind == .goal, !assists.isEmpty {
                Text("\u{00A0}(")
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
                ForEach(Array(assists.enumerated()), id: \.offset) { index, assist in
                    if index > 0 {
                        Text(", ")
                            .font(.hbMontserrat(size: 11, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                    playerNameLink(id: assist.id, name: assist.name, bold: false)
                }
                Text(")")
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .minimumScaleFactor(0.6)
        .layoutPriority(-1)
    }

    @ViewBuilder
    private func playerNameLink(id: String?, name: String, bold: Bool) -> some View {
        let font: Font = bold
            ? .hbMontserrat(size: 13, weight: .bold)
            : .hbMontserrat(size: 11, weight: .semibold)
        let color = bold ? HBTheme.textPrimary : HBTheme.textSecondary

        if let id {
            NavigationLink { PlayerDetailView(playerId: id) } label: {
                Text(name)
                    .font(font)
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
        } else {
            Text(name)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func eventBadge(_ event: MatchEvent, running: (Int, Int)) -> some View {
        if event.kind == .goal {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                Text("\(running.0):\(running.1)")
                    .font(.hbNumber(size: 11, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(HBTheme.brand, in: Capsule())
            .fixedSize(horizontal: true, vertical: true)
            .layoutPriority(2)
            .accessibilityLabel("Gól \(running.0):\(running.1)")
        } else {
            Text("\(penaltyMinutes(event.description))'")
                .font(.hbNumber(size: 11, weight: .bold))
                .foregroundStyle(HBTheme.ink)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(red: 1.0, green: 0.84, blue: 0.15), in: Capsule())
                .fixedSize(horizontal: true, vertical: true)
                .layoutPriority(2)
        }
    }

    /// Skutečné asistence z API — bez pomlček a fillerů.
    private func assistEntries(for event: MatchEvent) -> [(id: String?, name: String)] {
        event.assistIds.prefix(2).compactMap { id in
            let name = catalog.playersById[id]?.shortName
            guard let name, !name.isEmpty else { return nil }
            return (id as String?, name)
        }
    }

    private func displayName(for event: MatchEvent) -> String {
        if let id = event.playerId, let player = catalog.playersById[id] {
            return player.shortName
        }
        let desc = event.description
        if let range = desc.range(of: "–") {
            let after = desc[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if let paren = after.firstIndex(of: "(") {
                return after[..<paren].trimmingCharacters(in: .whitespaces)
            }
            return after
        }
        if desc.hasPrefix("Gól ") {
            let rest = String(desc.dropFirst(4))
            if let paren = rest.firstIndex(of: "(") {
                return rest[..<paren].trimmingCharacters(in: .whitespaces)
            }
            return rest
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
            if let open = after.firstIndex(of: "("),
               let close = after.firstIndex(of: ")"),
               open < close {
                return String(after[after.index(after: open)..<close])
            }
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


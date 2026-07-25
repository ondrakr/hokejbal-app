import SwiftUI

/// Veřejný přehled amatérských turnajů (Více → Amatérské turnaje).
struct AmateurTournamentsView: View {
    @EnvironmentObject private var store: AmateurTournamentStore

    var body: some View {
        Group {
            if store.tournaments.isEmpty {
                EmptyStateView(
                    icon: "flag.checkered",
                    title: "Zatím žádné turnaje",
                    message: "V adminu (ikona nastavení) můžeš vytvořit první amatérský turnaj."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.tournaments) { tournament in
                            NavigationLink {
                                AmateurTournamentDetailView(tournamentId: tournament.id)
                            } label: {
                                AmateurTournamentCard(tournament: tournament)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(HBTheme.screenPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("Amatérské turnaje")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            Text("Lokální demo — turnaje zůstávají jen na tomto zařízení.")
                .font(.hbMontserrat(size: 12, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HBTheme.surface)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AmateurAdminHubView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HBTheme.textPrimary)
                }
                .accessibilityLabel("Správa turnajů")
            }
        }
        .hbNavigationStyle()
    }
}

struct AmateurTournamentCard: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let tournament: AmateurTournament

    private var teamCount: Int { store.teams(in: tournament.id).count }
    private var matchCount: Int { store.matches(in: tournament.id).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.hbMontserrat(size: 17, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    if !tournament.location.isEmpty {
                        Label(tournament.location, systemImage: "mappin.and.ellipse")
                            .font(.hbMontserrat(size: 12, weight: .medium))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                statusChip
            }

            HStack(spacing: 12) {
                meta(tournament.format.label, icon: "list.bullet.rectangle")
                meta("\(teamCount) týmů", icon: "person.3.fill")
                meta("\(matchCount) zápasů", icon: "sportscourt")
            }
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .contentShape(Rectangle())
    }

    private var statusChip: some View {
        Text(tournament.status.label.uppercased())
            .font(.hbMontserrat(size: 10, weight: .bold))
            .foregroundStyle(HBTheme.onBrand)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusColor, in: Capsule())
    }

    private var statusColor: Color {
        switch tournament.status {
        case .draft: return HBTheme.textTertiary
        case .active: return HBTheme.brand
        case .finished: return HBTheme.inkSoft
        }
    }

    private func meta(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.hbMontserrat(size: 11, weight: .semibold))
        }
        .foregroundStyle(HBTheme.textTertiary)
    }
}

// MARK: - Tournament detail (public)

private enum AmateurTournamentTab: String, CaseIterable, Hashable {
    case program = "Program"
    case results = "Výsledky"
    case table = "Tabulka"
    case teams = "Týmy"
}

struct AmateurTournamentDetailView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let tournamentId: String
    @State private var tab: AmateurTournamentTab = .program

    private var tournament: AmateurTournament? { store.tournament(tournamentId) }

    var body: some View {
        Group {
            if let tournament {
                content(tournament)
            } else {
                EmptyStateView(icon: "flag", title: "Turnaj nenalezen", message: "Turnaj byl smazán nebo neexistuje.")
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle(tournament?.name ?? "Turnaj")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AmateurAdminTournamentView(tournamentId: tournamentId)
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Spravovat turnaj")
            }
        }
        .hbNavigationStyle()
    }

    private func content(_ tournament: AmateurTournament) -> some View {
        VStack(spacing: 0) {
            header(tournament)
            HBUnderlineTabs(selection: $tab)
            HBSwipeTabView(selection: $tab) { selected in
                ScrollView {
                    Group {
                        switch selected {
                        case .program:
                            matchesList(store.matches(in: tournamentId).filter { $0.status != .finished })
                        case .results:
                            matchesList(store.matches(in: tournamentId).filter { $0.status == .finished }.reversed())
                        case .table:
                            standingsTable
                        case .teams:
                            teamsList
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private func header(_ tournament: AmateurTournament) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tournament.status.label)
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .foregroundStyle(HBTheme.brand)
                Spacer()
                Text(tournament.dateRangeLabel)
                    .font(.hbMontserrat(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textSecondary)
            }
            if !tournament.location.isEmpty {
                Text(tournament.location)
                    .font(.hbMontserrat(size: 14, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
            if !tournament.notes.isEmpty {
                Text(tournament.notes)
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }
        }
        .padding(HBTheme.screenPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HBTheme.surface)
    }

    private func matchesList(_ items: [AmateurMatch]) -> some View {
        Group {
            if items.isEmpty {
                EmptyStateView(icon: "sportscourt", title: "Žádné zápasy", message: "V adminu přidej program turnaje.")
                    .padding(.top, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(items) { match in
                        NavigationLink {
                            AmateurMatchDetailView(matchId: match.id)
                        } label: {
                            AmateurMatchRow(match: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(HBTheme.screenPadding)
                .padding(.top, 12)
            }
        }
    }

    private var standingsTable: some View {
        let rows = store.standings(for: tournamentId)
        return Group {
            if rows.isEmpty {
                EmptyStateView(icon: "list.number", title: "Bez tabulky", message: "Tabulka se naplní po odehraných zápasech.")
                    .padding(.top, 24)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("#").frame(width: 28, alignment: .leading)
                        Text("Tým").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Z").frame(width: 28)
                        Text("V").frame(width: 28)
                        Text("P").frame(width: 28)
                        Text("SK").frame(width: 44)
                        Text("B").frame(width: 28)
                    }
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .foregroundStyle(HBTheme.textTertiary)
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.vertical, 8)

                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        let team = store.team(row.teamId)
                        HStack {
                            Text("\(index + 1)").frame(width: 28, alignment: .leading)
                            Text(team?.shortName ?? "?")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            Text("\(row.played)").frame(width: 28)
                            Text("\(row.wins)").frame(width: 28)
                            Text("\(row.losses)").frame(width: 28)
                            Text("\(row.goalsFor):\(row.goalsAgainst)").frame(width: 44)
                            Text("\(row.points)").frame(width: 28)
                        }
                        .font(.hbMontserrat(size: 13, weight: .semibold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .padding(.horizontal, HBTheme.screenPadding)
                        .padding(.vertical, 10)
                        .background(index % 2 == 0 ? HBTheme.cardInset.opacity(0.35) : Color.clear)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var teamsList: some View {
        let items = store.teams(in: tournamentId)
        return Group {
            if items.isEmpty {
                EmptyStateView(icon: "person.3", title: "Bez týmů", message: "V adminu přidej týmy a soupisky.")
                    .padding(.top, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(items) { team in
                        NavigationLink {
                            AmateurTeamDetailView(teamId: team.id)
                        } label: {
                            HStack(spacing: 12) {
                                AmateurTeamBadge(team: team, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.hbMontserrat(size: 15, weight: .bold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                    Text("\(store.players(inTeam: team.id).count) hráčů")
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HBTheme.textTertiary)
                            }
                            .padding(12)
                            .hbCard(cornerRadius: HBTheme.radiusMd)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(HBTheme.screenPadding)
                .padding(.top, 12)
            }
        }
    }
}

struct AmateurMatchRow: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let match: AmateurMatch

    private var home: AmateurTeam? { store.team(match.homeTeamId) }
    private var away: AmateurTeam? { store.team(match.awayTeamId) }

    private var timeLabel: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.dateFormat = "E d.M. · HH:mm"
        return df.string(from: match.scheduledAt)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(match.phaseLabel.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(match.phase == .playoff ? HBTheme.brand : HBTheme.textTertiary)
                Spacer()
                Text(timeLabel)
                    .font(.hbMontserrat(size: 11, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
                Text(match.status.label.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(match.status == .live ? HBTheme.live : HBTheme.textTertiary)
            }

            HStack {
                teamSide(home, alignment: .leading)
                Text(match.status == .scheduled ? "vs" : match.scoreText)
                    .font(.hbNumber(size: 20, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                    .frame(width: 64)
                teamSide(away, alignment: .trailing)
            }
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .contentShape(Rectangle())
    }

    private func teamSide(_ team: AmateurTeam?, alignment: HorizontalAlignment) -> some View {
        HStack(spacing: 8) {
            if alignment == .trailing { Spacer(minLength: 0) }
            if alignment == .leading, let team {
                AmateurTeamBadge(team: team, size: 28)
            }
            Text(team?.shortName ?? "?")
                .font(.hbMontserrat(size: 14, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
            if alignment == .trailing, let team {
                AmateurTeamBadge(team: team, size: 28)
            }
            if alignment == .leading { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AmateurTeamBadge: View {
    let team: AmateurTeam
    var size: CGFloat = 36

    var body: some View {
        Text(team.logoInitials)
            .font(.hbMontserrat(size: size * 0.32, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: team.primaryColorHex), in: Circle())
    }
}

// MARK: - Team / Match public detail

struct AmateurTeamDetailView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let teamId: String

    private var team: AmateurTeam? { store.team(teamId) }

    var body: some View {
        Group {
            if let team {
                List {
                    Section {
                        HStack(spacing: 12) {
                            AmateurTeamBadge(team: team, size: 56)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.hbMontserrat(size: 18, weight: .bold))
                                if !team.city.isEmpty {
                                    Text(team.city)
                                        .font(.hbMontserrat(size: 13, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                }
                            }
                        }
                    }

                    Section("Soupiska") {
                        ForEach(store.players(inTeam: team.id)) { player in
                            HStack {
                                Text("\(player.number)")
                                    .font(.hbNumber(size: 14, weight: .bold))
                                    .foregroundStyle(HBTheme.brand)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.fullName)
                                        .font(.hbMontserrat(size: 14, weight: .semibold))
                                    Text(player.position.label.capitalized)
                                        .font(.hbMontserrat(size: 11, weight: .medium))
                                        .foregroundStyle(HBTheme.textTertiary)
                                }
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(icon: "person.3", title: "Tým nenalezen", message: "")
            }
        }
        .navigationTitle(team?.shortName ?? "Tým")
        .hbNavigationStyle()
    }
}

struct AmateurMatchDetailView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let matchId: String

    private var match: AmateurMatch? { store.match(matchId) }

    var body: some View {
        Group {
            if let match {
                ScrollView {
                    VStack(spacing: 16) {
                        scoreHeader(match)
                        statsRow(match)
                        eventsSection(match)
                    }
                    .padding(HBTheme.screenPadding)
                    .padding(.bottom, 28)
                }
            } else {
                EmptyStateView(icon: "sportscourt", title: "Zápas nenalezen", message: "")
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("Zápas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AmateurMatchScorerView(matchId: matchId)
                } label: {
                    Image(systemName: "pencil.and.list.clipboard")
                }
                .accessibilityLabel("Zápis zápasu")
            }
        }
        .hbNavigationStyle()
    }

    private func scoreHeader(_ match: AmateurMatch) -> some View {
        let home = store.team(match.homeTeamId)
        let away = store.team(match.awayTeamId)
        return VStack(spacing: 12) {
            Text(match.status.label.uppercased())
                .font(.hbMontserrat(size: 11, weight: .bold))
                .foregroundStyle(match.status == .live ? HBTheme.live : HBTheme.textTertiary)

            HStack {
                teamBlock(home)
                Text(match.status == .scheduled ? "–" : match.scoreText)
                    .font(.hbNumber(size: 36, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                    .frame(minWidth: 90)
                teamBlock(away)
            }
        }
        .padding(16)
        .hbCard(cornerRadius: HBTheme.radiusLg)
    }

    private func teamBlock(_ team: AmateurTeam?) -> some View {
        VStack(spacing: 8) {
            if let team {
                AmateurTeamBadge(team: team, size: 48)
                Text(team.shortName)
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statsRow(_ match: AmateurMatch) -> some View {
        HStack {
            stat("Střely", "\(match.homeShots)")
            Spacer()
            Text("STŘELY")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .foregroundStyle(HBTheme.textTertiary)
            Spacer()
            stat("Střely", "\(match.awayShots)")
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        Text(value)
            .font(.hbNumber(size: 18, weight: .heavy))
            .foregroundStyle(HBTheme.textPrimary)
    }

    private func eventsSection(_ match: AmateurMatch) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UDÁLOSTI")
                .font(.hbMontserrat(size: 12, weight: .bold))
                .foregroundStyle(HBTheme.textTertiary)

            if match.events.isEmpty {
                Text("Zatím bez zápisu.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            } else {
                ForEach(match.events) { event in
                    AmateurEventRow(event: event, match: match)
                }
            }
        }
    }
}

struct AmateurEventRow: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let event: AmateurMatchEvent
    let match: AmateurMatch

    private var isHome: Bool { event.teamId == match.homeTeamId }

    var body: some View {
        HStack(alignment: .top) {
            if isHome { eventBody; Spacer(minLength: 40) }
            else { Spacer(minLength: 40); eventBody }
        }
        .padding(12)
        .hbCard(cornerRadius: HBTheme.radiusSm)
    }

    private var eventBody: some View {
        VStack(alignment: isHome ? .leading : .trailing, spacing: 4) {
            HStack(spacing: 6) {
                Text(event.clockLabel)
                    .font(.hbNumber(size: 11, weight: .bold))
                    .foregroundStyle(HBTheme.textTertiary)
                Text(event.kind == .goal ? "GÓL" : "\(event.penaltyMinutes)'")
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(event.kind == .goal ? Color.white : HBTheme.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(event.kind == .goal ? HBTheme.brand : Color(red: 1.0, green: 0.84, blue: 0.15), in: Capsule())
            }

            Text(playerName(event.playerId) ?? "Neznámý")
                .font(.hbMontserrat(size: 14, weight: .bold))

            if event.kind == .goal {
                let assists = event.assistIds.compactMap { playerName($0) }
                if !assists.isEmpty {
                    Text("(\(assists.joined(separator: ", ")))")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                }
            } else if !event.penaltyReason.isEmpty {
                Text(event.penaltyReason)
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
    }

    private func playerName(_ id: String?) -> String? {
        guard let id, let p = store.player(id) else { return nil }
        return p.shortName
    }
}

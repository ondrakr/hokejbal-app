import SwiftUI

/// Profesionální zápis amatérského zápasu — scoreboard + rychlé akce.
struct AmateurMatchScorerView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let matchId: String

    @State private var showGoal = false
    @State private var showPenalty = false
    @State private var eventTeamIsHome = true

    private var match: AmateurMatch? { store.match(matchId) }
    private var home: AmateurTeam? { match.flatMap { store.team($0.homeTeamId) } }
    private var away: AmateurTeam? { match.flatMap { store.team($0.awayTeamId) } }

    var body: some View {
        Group {
            if let match {
                ScrollView {
                    VStack(spacing: 14) {
                        scoreboard(match)
                        statusControls(match)
                        actionGrid(match)
                        shotsCard(match)
                        eventsCard(match)
                    }
                    .padding(HBTheme.screenPadding)
                    .padding(.bottom, 28)
                }
            } else {
                EmptyStateView(icon: "sportscourt", title: "Zápas nenalezen", message: "")
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("Zápis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showGoal) {
            if let match {
                AmateurAddGoalSheet(match: match, teamIsHome: eventTeamIsHome)
            }
        }
        .sheet(isPresented: $showPenalty) {
            if let match {
                AmateurAddPenaltySheet(match: match, teamIsHome: eventTeamIsHome)
            }
        }
        .hbNavigationStyle()
    }

    private func scoreboard(_ match: AmateurMatch) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Text(match.phaseLabel.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(HBTheme.textTertiary)
                Spacer()
                Text(match.status.label.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(match.status == .live ? HBTheme.onBrand : HBTheme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        match.status == .live ? HBTheme.live : HBTheme.cardInset,
                        in: Capsule()
                    )
            }

            HStack(alignment: .center, spacing: 12) {
                teamBlock(home, alignment: .leading)
                Text(match.scoreText)
                    .font(.hbNumber(size: 36, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                    .monospacedDigit()
                    .frame(minWidth: 88)
                teamBlock(away, alignment: .trailing)
            }
        }
        .padding(16)
        .hbCard(cornerRadius: HBTheme.radiusLg)
    }

    private func teamBlock(_ team: AmateurTeam?, alignment: HorizontalAlignment) -> some View {
        VStack(spacing: 8) {
            if let team {
                AmateurTeamBadge(team: team, size: 48)
            } else {
                Circle().fill(HBTheme.cardInset).frame(width: 48, height: 48)
            }
            Text(team?.shortName ?? "—")
                .font(.hbMontserrat(size: 14, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
        }
        .frame(maxWidth: .infinity)
    }

    private func statusControls(_ match: AmateurMatch) -> some View {
        HStack(spacing: 10) {
            Button {
                store.setMatchStatus(match.id, status: .live)
            } label: {
                Label("LIVE", systemImage: "dot.radiowaves.left.and.right")
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(match.status == .live ? HBTheme.onBrand : HBTheme.live)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        match.status == .live ? AnyShapeStyle(HBTheme.live) : AnyShapeStyle(HBTheme.live.opacity(0.12)),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)

            Button {
                store.setMatchStatus(match.id, status: .finished)
            } label: {
                Label("Konec", systemImage: "flag.checkered")
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(match.status == .finished ? HBTheme.onBrand : HBTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        match.status == .finished ? AnyShapeStyle(HBTheme.ink) : AnyShapeStyle(HBTheme.card),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().strokeBorder(match.status == .finished ? Color.clear : HBTheme.cardStroke, lineWidth: 0.75)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionGrid(_ match: AmateurMatch) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RYCHLÝ ZÁPIS")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)

            HStack(spacing: 10) {
                goalButton(title: "Gól \(home?.shortName ?? "DOM")", home: true)
                goalButton(title: "Gól \(away?.shortName ?? "HOS")", home: false)
            }
            HStack(spacing: 10) {
                penaltyButton(title: "Trest \(home?.shortName ?? "DOM")", home: true)
                penaltyButton(title: "Trest \(away?.shortName ?? "HOS")", home: false)
            }
        }
    }

    private func goalButton(title: String, home: Bool) -> some View {
        Button {
            eventTeamIsHome = home
            showGoal = true
        } label: {
            HStack(spacing: 8) {
                Circle().fill(Color.white).frame(width: 8, height: 8)
                Text(title)
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(HBTheme.onBrand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(HBTheme.brandGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func penaltyButton(title: String, home: Bool) -> some View {
        Button {
            eventTeamIsHome = home
            showPenalty = true
        } label: {
            Text(title)
                .font(.hbMontserrat(size: 13, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HBTheme.cardStroke, lineWidth: 0.75)
                )
        }
        .buttonStyle(.plain)
    }

    private func shotsCard(_ match: AmateurMatch) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STŘELY")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)

            HStack(spacing: 10) {
                shotStepper(
                    title: home?.shortName ?? "DOM",
                    value: match.homeShots
                ) { store.setShots(matchId: match.id, home: $0, away: match.awayShots) }
                shotStepper(
                    title: away?.shortName ?? "HOS",
                    value: match.awayShots
                ) { store.setShots(matchId: match.id, home: match.homeShots, away: $0) }
            }
        }
    }

    private func shotStepper(title: String, value: Int, onChange: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.hbMontserrat(size: 12, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
            HStack(spacing: 14) {
                Button {
                    onChange(max(0, value - 1))
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(HBTheme.cardInset, in: Circle())
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.hbNumber(size: 24, weight: .heavy))
                    .monospacedDigit()
                    .frame(minWidth: 36)

                Button {
                    onChange(min(99, value + 1))
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(width: 36, height: 36)
                        .background(HBTheme.brand, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func eventsCard(_ match: AmateurMatch) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ZÁPIS")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)

            if match.events.isEmpty {
                Text("Zatím bez událostí — přidej gól nebo trest.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(match.events.reversed().enumerated()), id: \.element.id) { index, event in
                        eventRow(event, match: match)
                        if index < match.events.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .hbCard(cornerRadius: HBTheme.radiusMd)
            }
        }
    }

    private func eventRow(_ event: AmateurMatchEvent, match: AmateurMatch) -> some View {
        let isHome = event.teamId == match.homeTeamId
        let team = store.team(event.teamId)
        let player = event.playerId.flatMap(store.player)

        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(event.kind == .goal ? Color.white : Color(red: 1.0, green: 0.84, blue: 0.15))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().strokeBorder(event.kind == .goal ? HBTheme.brand.opacity(0.35) : Color.clear, lineWidth: 1)
                )
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(event.kind == .goal ? "Gól" : "Trest \(event.penaltyMinutes)'")
                        .font(.hbMontserrat(size: 14, weight: .bold))
                    Text("·")
                        .foregroundStyle(HBTheme.textTertiary)
                    Text(event.clockLabel)
                        .font(.hbNumber(size: 12, weight: .bold))
                        .foregroundStyle(HBTheme.textTertiary)
                }
                Text(player?.fullName ?? "Bez hráče")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                if event.kind == .penalty, !event.penaltyReason.isEmpty {
                    Text(event.penaltyReason)
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textTertiary)
                }
                Text(isHome ? (team?.shortName ?? "DOM") : (team?.shortName ?? "HOS"))
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .foregroundStyle(HBTheme.brand)
            }

            Spacer(minLength: 0)

            Button(role: .destructive) {
                store.removeEvent(matchId: match.id, eventId: event.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.loss)
                    .frame(width: 32, height: 32)
                    .background(HBTheme.loss.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }
}

// MARK: - Goal / penalty sheets

struct AmateurAddGoalSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    let match: AmateurMatch
    let teamIsHome: Bool

    @State private var scorerId = ""
    @State private var assist1 = ""
    @State private var assist2 = ""
    @State private var period = 1
    @State private var minute = 0
    @State private var second = 0

    private var teamId: String { teamIsHome ? match.homeTeamId : match.awayTeamId }
    private var roster: [AmateurPlayer] { store.players(inTeam: teamId) }
    private var team: AmateurTeam? { store.team(teamId) }
    private var matchFormat: AmateurMatchFormat {
        store.tournament(match.tournamentId)?.matchFormat ?? .standard
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerChip

                    sheetCard("Střelec") {
                        playerPicker(selection: $scorerId, exclude: [], allowEmpty: true)
                    }

                    sheetCard("Asistence") {
                        VStack(spacing: 10) {
                            playerPicker(selection: $assist1, exclude: [scorerId], allowEmpty: true, placeholder: "1. asistence")
                            playerPicker(selection: $assist2, exclude: [scorerId, assist1], allowEmpty: true, placeholder: "2. asistence")
                        }
                    }

                    sheetCard("Čas") {
                        VStack(spacing: 10) {
                            Stepper("Třetina \(period)", value: $period, in: 1...matchFormat.maxPeriodIncludingOT)
                            Stepper("Minuta \(minute)", value: $minute, in: 0...matchFormat.periodLengthMinutes)
                            Stepper("Sekunda \(second)", value: $second, in: 0...59)
                        }
                        .font(.hbMontserrat(size: 15, weight: .semibold))
                    }
                }
                .padding(HBTheme.screenPadding)
            }
            .background(HBTheme.canvas)
            .navigationTitle("Gól")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") { save() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private var headerChip: some View {
        HStack(spacing: 10) {
            if let team { AmateurTeamBadge(team: team, size: 36) }
            Text(team?.name ?? (teamIsHome ? "Domácí" : "Hosté"))
                .font(.hbMontserrat(size: 16, weight: .bold))
            Spacer()
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func sheetCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)
            content()
                .padding(14)
                .hbCard(cornerRadius: HBTheme.radiusMd)
        }
    }

    private func playerPicker(
        selection: Binding<String>,
        exclude: [String],
        allowEmpty: Bool,
        placeholder: String = "Bez hráče"
    ) -> some View {
        Picker(placeholder, selection: selection) {
            if allowEmpty { Text(placeholder).tag("") }
            ForEach(roster.filter { !exclude.contains($0.id) }) { p in
                Text("#\(p.number) \(p.fullName)").tag(p.id)
            }
        }
        .font(.hbMontserrat(size: 15, weight: .semibold))
    }

    private func save() {
        var assists: [String] = []
        if !assist1.isEmpty { assists.append(assist1) }
        if !assist2.isEmpty { assists.append(assist2) }
        store.addGoal(
            matchId: match.id,
            teamId: teamId,
            scorerId: scorerId.isEmpty ? nil : scorerId,
            assistIds: assists,
            period: period,
            minute: minute,
            second: second
        )
        dismiss()
    }
}

struct AmateurAddPenaltySheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    let match: AmateurMatch
    let teamIsHome: Bool

    @State private var playerId = ""
    @State private var minutes = 2
    @State private var reason = "Hákování"
    @State private var period = 1
    @State private var minute = 0
    @State private var second = 0

    private var teamId: String { teamIsHome ? match.homeTeamId : match.awayTeamId }
    private var roster: [AmateurPlayer] { store.players(inTeam: teamId) }
    private var team: AmateurTeam? { store.team(teamId) }
    private let reasons = ["Hákování", "Podražení", "Nedovolené bránění", "Vysoká hůl", "Drsnost", "Nesportovní chování", "Jiné"]
    private var matchFormat: AmateurMatchFormat {
        store.tournament(match.tournamentId)?.matchFormat ?? .standard
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        if let team { AmateurTeamBadge(team: team, size: 36) }
                        Text(team?.name ?? (teamIsHome ? "Domácí" : "Hosté"))
                            .font(.hbMontserrat(size: 16, weight: .bold))
                        Spacer()
                    }
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)

                    card("Hráč") {
                        Picker("Hráč", selection: $playerId) {
                            Text("Bez hráče").tag("")
                            ForEach(roster) { p in
                                Text("#\(p.number) \(p.fullName)").tag(p.id)
                            }
                        }
                        .font(.hbMontserrat(size: 15, weight: .semibold))
                    }

                    card("Trest") {
                        Picker("Minuty", selection: $minutes) {
                            Text("2 min").tag(2)
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                        }
                        .pickerStyle(.segmented)
                        Picker("Důvod", selection: $reason) {
                            ForEach(reasons, id: \.self) { Text($0).tag($0) }
                        }
                        .font(.hbMontserrat(size: 15, weight: .semibold))
                    }

                    card("Čas") {
                        VStack(spacing: 10) {
                            Stepper("Třetina \(period)", value: $period, in: 1...matchFormat.maxPeriodIncludingOT)
                            Stepper("Minuta \(minute)", value: $minute, in: 0...matchFormat.periodLengthMinutes)
                            Stepper("Sekunda \(second)", value: $second, in: 0...59)
                        }
                        .font(.hbMontserrat(size: 15, weight: .semibold))
                    }
                }
                .padding(HBTheme.screenPadding)
            }
            .background(HBTheme.canvas)
            .navigationTitle("Trest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        store.addPenalty(
                            matchId: match.id,
                            teamId: teamId,
                            playerId: playerId.isEmpty ? nil : playerId,
                            minutes: minutes,
                            reason: reason,
                            period: period,
                            minute: minute,
                            second: second
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)
            content()
                .padding(14)
                .hbCard(cornerRadius: HBTheme.radiusMd)
        }
    }
}

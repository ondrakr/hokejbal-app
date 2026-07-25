import SwiftUI
import UIKit

// MARK: - Admin hub

struct AmateurAdminHubView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @State private var showCreate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Lokální správa na tomto zařízení. Účty a práva doplníme později.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)

                Button {
                    showCreate = true
                } label: {
                    Label("Nový turnaj", systemImage: "plus")
                        .font(.hbMontserrat(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HBTheme.brandGradient, in: Capsule())
                }
                .buttonStyle(.plain)

                Text("TURNAJE")
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(HBTheme.textTertiary)
                    .padding(.top, 4)

                if store.tournaments.isEmpty {
                    Text("Zatím žádný turnaj — vytvoř první průvodcem.")
                        .font(.hbMontserrat(size: 14, weight: .medium))
                        .foregroundStyle(HBTheme.textTertiary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hbCard(cornerRadius: HBTheme.radiusMd)
                } else {
                    ForEach(store.tournaments) { tournament in
                        NavigationLink {
                            AmateurAdminTournamentView(tournamentId: tournament.id)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tournament.name)
                                        .font(.hbMontserrat(size: 16, weight: .bold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                    Text("\(tournament.status.label) · \(tournament.dateRangeLabel)")
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                    Text(tournament.format.label)
                                        .font(.hbMontserrat(size: 11, weight: .semibold))
                                        .foregroundStyle(HBTheme.brand)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HBTheme.textTertiary)
                            }
                            .padding(14)
                            .hbCard(cornerRadius: HBTheme.radiusMd)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteTournament(tournament.id)
                            } label: {
                                Label("Smazat", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(HBTheme.screenPadding)
            .padding(.bottom, 28)
        }
        .background(HBTheme.canvas)
        .navigationTitle("Správa turnajů")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Nový turnaj")
            }
        }
        .sheet(isPresented: $showCreate) {
            AmateurCreateTournamentSheet()
        }
        .hbNavigationStyle()
    }
}

// MARK: - Admin tournament

private enum AmateurAdminTab: String, CaseIterable, Hashable {
    case overview = "Přehled"
    case teams = "Týmy"
    case matches = "Zápasy"
}

struct AmateurAdminTournamentView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let tournamentId: String

    @State private var tab: AmateurAdminTab = .overview
    @State private var showAddTeam = false
    @State private var showAddMatch = false
    @State private var editTournament = false
    @State private var confirmRegenerate = false
    @State private var scheduleMessage: String?

    private var tournament: AmateurTournament? { store.tournament(tournamentId) }

    var body: some View {
        Group {
            if let tournament {
                VStack(spacing: 0) {
                    HBUnderlineTabs(selection: $tab)
                    HBSwipeTabView(selection: $tab) { selected in
                        ScrollView {
                            switch selected {
                            case .overview: overview(tournament)
                            case .teams: teamsAdmin
                            case .matches: matchesAdmin
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(icon: "flag", title: "Turnaj nenalezen", message: "")
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle(tournament?.name ?? "Turnaj")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editTournament = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showAddTeam) {
            AmateurAddTeamSheet(tournamentId: tournamentId)
        }
        .sheet(isPresented: $showAddMatch) {
            AmateurAddMatchSheet(tournamentId: tournamentId)
        }
        .sheet(isPresented: $editTournament) {
            if let tournament {
                AmateurEditTournamentSheet(tournament: tournament)
            }
        }
        .alert("Přegenerovat rozpis?", isPresented: $confirmRegenerate) {
            Button("Zrušit", role: .cancel) {}
            Button("Přegenerovat", role: .destructive) {
                if store.generateSchedule(tournamentId: tournamentId, replaceExisting: true) {
                    scheduleMessage = "Rozpis byl přegenerován."
                    tab = .matches
                }
            }
        } message: {
            Text("Stávající zápasy se smažou a vytvoří se nový rozpis podle formátu turnaje.")
        }
        .alert("Rozpis", isPresented: Binding(
            get: { scheduleMessage != nil },
            set: { if !$0 { scheduleMessage = nil } }
        )) {
            Button("OK", role: .cancel) { scheduleMessage = nil }
        } message: {
            Text(scheduleMessage ?? "")
        }
        .hbNavigationStyle()
    }

    private func overview(_ tournament: AmateurTournament) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            adminStat("Stav", tournament.status.label)
            adminStat("Formát", tournament.format.label)
            adminStat("Zápas", tournament.matchFormat.label)
            adminStat("Místo", tournament.location.isEmpty ? "—" : tournament.location)
            adminStat("Termín", tournament.dateRangeLabel)
            adminStat("Týmy", "\(store.teams(in: tournamentId).count)")
            adminStat("Zápasy", "\(store.matches(in: tournamentId).count)")
            adminStat("Rozpis", tournament.scheduleGenerated ? "Vygenerován" : "Čeká")

            Text("Rychlé akce")
                .font(.hbMontserrat(size: 12, weight: .bold))
                .foregroundStyle(HBTheme.textTertiary)
                .padding(.top, 8)

            if store.canGenerateSchedule(tournamentId: tournamentId) {
                Button {
                    if tournament.scheduleGenerated || !store.matches(in: tournamentId).isEmpty {
                        confirmRegenerate = true
                    } else if store.generateSchedule(tournamentId: tournamentId, replaceExisting: true) {
                        scheduleMessage = "Rozpis je připraven."
                        tab = .matches
                    }
                } label: {
                    adminAction(
                        tournament.scheduleGenerated ? "Přegenerovat rozpis" : "Připraveno — vygenerovat rozpis",
                        icon: "calendar.badge.clock"
                    )
                }
            }

            if tournament.format == .roundRobinAndPlayoff {
                let groupDone = store.matches(in: tournamentId)
                    .filter { $0.phase == .group }
                    .allSatisfy { $0.status == .finished }
                    && store.matches(in: tournamentId).contains { $0.phase == .group }
                let hasPlayoff = store.matches(in: tournamentId).contains { $0.phase == .playoff }
                Button {
                    if store.generatePlayoffFromStandings(tournamentId: tournamentId) {
                        scheduleMessage = "Play-off je vygenerováno z tabulky."
                        tab = .matches
                    } else {
                        scheduleMessage = "Play-off nelze vytvořit — potřeba aspoň 2 týmy v tabulce."
                    }
                } label: {
                    adminAction(
                        hasPlayoff ? "Přegenerovat play-off z tabulky" : "Vygenerovat play-off z tabulky",
                        icon: "trophy.fill"
                    )
                }
                .disabled(!groupDone && !hasPlayoff && store.standings(for: tournamentId).count < 2)

                if tournament.format.hasPlayoff {
                    Button {
                        if store.generateNextPlayoffRound(tournamentId: tournamentId) {
                            scheduleMessage = "Další kolo play-off je připravené."
                            tab = .matches
                        } else {
                            scheduleMessage = "Další kolo zatím nejde — dohraj aktuální play-off zápasy."
                        }
                    } label: {
                        adminAction("Další kolo play-off", icon: "arrow.right.circle.fill")
                    }
                }
            } else if tournament.format.hasPlayoff {
                Button {
                    if store.generateNextPlayoffRound(tournamentId: tournamentId) {
                        scheduleMessage = "Další kolo play-off je připravené."
                        tab = .matches
                    } else {
                        scheduleMessage = "Další kolo zatím nejde — dohraj aktuální play-off zápasy."
                    }
                } label: {
                    adminAction("Další kolo play-off", icon: "arrow.right.circle.fill")
                }
            }

            Button { showAddTeam = true } label: {
                adminAction("Přidat tým", icon: "person.3.fill")
            }
            Button { showAddMatch = true } label: {
                adminAction("Přidat zápas ručně", icon: "plus.circle.fill")
            }
            NavigationLink {
                AmateurTournamentDetailView(tournamentId: tournamentId)
            } label: {
                adminAction("Zobrazit veřejný přehled", icon: "eye.fill")
            }
        }
        .padding(HBTheme.screenPadding)
        .padding(.bottom, 28)
    }

    private var teamsAdmin: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showAddTeam = true } label: {
                Label("Přidat tým", systemImage: "plus")
                    .font(.hbMontserrat(size: 14, weight: .bold))
                    .foregroundStyle(HBTheme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HBTheme.brandGradient, in: Capsule())
            }
            .buttonStyle(.plain)

            ForEach(store.teams(in: tournamentId)) { team in
                NavigationLink {
                    AmateurAdminTeamView(teamId: team.id)
                } label: {
                    HStack {
                        AmateurTeamBadge(team: team, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(team.name)
                                .font(.hbMontserrat(size: 15, weight: .bold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text("\(store.players(inTeam: team.id).count) hráčů na soupisce")
                                .font(.hbMontserrat(size: 12, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                    .padding(12)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HBTheme.screenPadding)
        .padding(.bottom, 28)
    }

    private var matchesAdmin: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showAddMatch = true } label: {
                Label("Přidat zápas", systemImage: "plus")
                    .font(.hbMontserrat(size: 14, weight: .bold))
                    .foregroundStyle(HBTheme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HBTheme.brandGradient, in: Capsule())
            }
            .buttonStyle(.plain)

            ForEach(store.matches(in: tournamentId)) { match in
                VStack(alignment: .leading, spacing: 8) {
                    AmateurMatchRow(match: match)
                    HStack(spacing: 8) {
                        NavigationLink {
                            AmateurMatchScorerView(matchId: match.id)
                        } label: {
                            Label("Zápis", systemImage: "pencil.and.list.clipboard")
                                .font(.hbMontserrat(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(HBTheme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .foregroundStyle(HBTheme.brand)
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            store.deleteMatch(match.id)
                        } label: {
                            Image(systemName: "trash")
                                .frame(width: 44, height: 40)
                                .background(HBTheme.loss.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .foregroundStyle(HBTheme.loss)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(HBTheme.screenPadding)
        .padding(.bottom, 28)
    }

    private func adminStat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.hbMontserrat(size: 13, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.hbMontserrat(size: 14, weight: .bold))
        }
        .padding(12)
        .hbCard(cornerRadius: HBTheme.radiusSm)
    }

    private func adminAction(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(HBTheme.brand)
                .frame(width: 24)
            Text(title)
                .font(.hbMontserrat(size: 14, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }
}

struct AmateurEditTournamentSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    @State var tournament: AmateurTournament

    var body: some View {
        NavigationStack {
            Form {
                Section("Údaje") {
                    TextField("Název", text: $tournament.name)
                    TextField("Místo", text: $tournament.location)
                    DatePicker("Od", selection: $tournament.startDate, displayedComponents: .date)
                    DatePicker("Do", selection: $tournament.endDate, displayedComponents: .date)
                    Picker("Stav", selection: $tournament.status) {
                        ForEach(AmateurTournamentStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                }
                Section("Formát turnaje") {
                    Picker("Formát", selection: $tournament.format) {
                        ForEach(AmateurTournamentFormat.allCases, id: \.self) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    if tournament.format.hasGroupStage {
                        Toggle("Doma i venku", isOn: $tournament.homeAndAway)
                    }
                    if tournament.format == .roundRobinAndPlayoff {
                        Picker("Play-off týmů", selection: $tournament.playoffTeamCount) {
                            Text("2").tag(2)
                            Text("4").tag(4)
                            Text("8").tag(8)
                            Text("16").tag(16)
                        }
                    }
                    if tournament.format.usesSeries {
                        Picker("Série", selection: $tournament.seriesLength) {
                            Text("1 zápas").tag(1)
                            Text("Best of 3").tag(3)
                            Text("Best of 5").tag(5)
                            Text("Best of 7").tag(7)
                        }
                    }
                }
                Section("Formát zápasu") {
                    Stepper(
                        "Třetiny: \(tournament.matchFormat.periodCount)",
                        value: $tournament.matchFormat.periodCount,
                        in: 1...4
                    )
                    Stepper(
                        "Délka: \(tournament.matchFormat.periodLengthMinutes) min",
                        value: $tournament.matchFormat.periodLengthMinutes,
                        in: 5...20
                    )
                    Toggle("Prodloužení", isOn: $tournament.matchFormat.overtimeEnabled)
                }
                Section("Poznámka") {
                    TextField("Poznámka", text: $tournament.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Upravit turnaj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        store.updateTournament(tournament)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AmateurAddTeamSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentId: String

    @State private var name = ""
    @State private var shortName = ""
    @State private var city = ""
    @State private var colorHex = "C92A2A"

    private let colors = ["C92A2A", "1B4F9C", "0B3D91", "2E7D32", "111111", "D4A017", "E65100", "6A1B9A"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tým") {
                    TextField("Název", text: $name)
                    TextField("Zkratka", text: $shortName)
                    TextField("Město", text: $city)
                }
                Section("Barva") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(height: 36)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }
            }
            .navigationTitle("Nový tým")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Přidat") {
                        _ = store.addTeam(
                            tournamentId: tournamentId,
                            name: name,
                            shortName: shortName,
                            city: city,
                            colorHex: colorHex
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct AmateurAddMatchSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentId: String

    @State private var homeId = ""
    @State private var awayId = ""
    @State private var date = Date()
    @State private var round = 1
    @State private var venue = ""

    private var teams: [AmateurTeam] { store.teams(in: tournamentId) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Soupeři") {
                    Picker("Domácí", selection: $homeId) {
                        Text("Vyber tým").tag("")
                        ForEach(teams) { t in Text(t.name).tag(t.id) }
                    }
                    Picker("Hosté", selection: $awayId) {
                        Text("Vyber tým").tag("")
                        ForEach(teams) { t in Text(t.name).tag(t.id) }
                    }
                }
                Section("Termín") {
                    DatePicker("Začátek", selection: $date)
                    Stepper("Kolo \(round)", value: $round, in: 1...50)
                    TextField("Hřiště / hala", text: $venue)
                }
            }
            .navigationTitle("Nový zápas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Přidat") {
                        _ = store.addMatch(
                            tournamentId: tournamentId,
                            homeTeamId: homeId,
                            awayTeamId: awayId,
                            scheduledAt: date,
                            round: round,
                            venue: venue
                        )
                        dismiss()
                    }
                    .disabled(homeId.isEmpty || awayId.isEmpty || homeId == awayId || teams.count < 2)
                }
            }
            .onAppear {
                if homeId.isEmpty, let first = teams.first { homeId = first.id }
                if awayId.isEmpty, teams.count > 1 { awayId = teams[1].id }
            }
        }
    }
}

// MARK: - Admin team + roster

struct AmateurAdminTeamView: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    let teamId: String

    @State private var showAddPlayer = false
    @State private var editTeam = false

    private var team: AmateurTeam? { store.team(teamId) }

    var body: some View {
        List {
            if let team {
                Section {
                    HStack(spacing: 12) {
                        AmateurTeamBadge(team: team, size: 48)
                        VStack(alignment: .leading) {
                            Text(team.name).font(.hbMontserrat(size: 16, weight: .bold))
                            Text(team.city).foregroundStyle(HBTheme.textSecondary)
                        }
                    }
                    Button("Upravit tým") { editTeam = true }
                    Button("Smazat tým", role: .destructive) {
                        store.deleteTeam(team.id)
                    }
                }

                Section("Soupiska") {
                    ForEach(store.players(inTeam: team.id)) { player in
                        HStack {
                            Text("#\(player.number)")
                                .font(.hbNumber(size: 13, weight: .bold))
                                .foregroundStyle(HBTheme.brand)
                                .frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.fullName)
                                    .font(.hbMontserrat(size: 14, weight: .semibold))
                                Text(player.position.label.capitalized)
                                    .font(.hbMontserrat(size: 11, weight: .medium))
                                    .foregroundStyle(HBTheme.textTertiary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let list = store.players(inTeam: team.id)
                        for i in indexSet { store.deletePlayer(list[i].id) }
                    }

                    Button {
                        showAddPlayer = true
                    } label: {
                        Label("Přidat hráče", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle(team?.shortName ?? "Tým")
        .sheet(isPresented: $showAddPlayer) {
            AmateurAddPlayerSheet(teamId: teamId)
        }
        .sheet(isPresented: $editTeam) {
            if let team {
                AmateurEditTeamSheet(team: team)
            }
        }
        .hbNavigationStyle()
    }
}

struct AmateurEditTeamSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    @State var team: AmateurTeam

    var body: some View {
        NavigationStack {
            Form {
                TextField("Název", text: $team.name)
                TextField("Zkratka", text: $team.shortName)
                TextField("Město", text: $team.city)
                TextField("Iniciály", text: $team.logoInitials)
                TextField("Barva (HEX)", text: $team.primaryColorHex)
            }
            .navigationTitle("Upravit tým")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        store.updateTeam(team)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AmateurAddPlayerSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss
    let teamId: String

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var number = 10
    @State private var position: PlayerPosition = .forward

    var body: some View {
        NavigationStack {
            Form {
                TextField("Jméno", text: $firstName)
                TextField("Příjmení", text: $lastName)
                Stepper("Číslo \(number)", value: $number, in: 1...99)
                Picker("Pozice", selection: $position) {
                    ForEach(PlayerPosition.allCases, id: \.self) { p in
                        Text(p.label.capitalized).tag(p)
                    }
                }
            }
            .navigationTitle("Nový hráč")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Přidat") {
                        _ = store.addPlayer(
                            teamId: teamId,
                            firstName: firstName,
                            lastName: lastName,
                            number: number,
                            position: position
                        )
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
}

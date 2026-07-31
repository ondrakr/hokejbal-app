import SwiftUI

// MARK: - Hub (Centrála)

/// Fantasy Extraliga — hub ve stylu aplikace (ne kopie Chance Ligy).
struct FantasyView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var fantasy: FantasySquadStore
    @EnvironmentObject private var attributes: FantasyAttributesStore
    @EnvironmentObject private var auth: AuthStore

    @State private var players: [Player] = []
    @State private var matches: [Match] = []
    @State private var toast: String?

    private var playersById: [String: Player] {
        Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
    }

    private var roundFixtures: [Match] {
        let gw = fantasy.viewingGameweek
        let byRound = matches.filter { $0.round == gw }
        if !byRound.isEmpty { return byRound.sorted { $0.scheduledAt < $1.scheduledAt } }

        let start = FantasyDeadline.deadline(forGameweek: gw)
        let end = FantasyDeadline.deadline(forGameweek: gw + 1)
        return matches
            .filter { $0.scheduledAt >= start.addingTimeInterval(-2 * 86_400) && $0.scheduledAt < end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var body: some View {
        Group {
            if FantasyMock.enabled || auth.isAuthenticated {
                fantasyContent
            } else {
                AuthLockView(
                    title: "Fantasy je zamčené",
                    message: "Fantasy sestavu a trh odemkneš po přihlášení.",
                    systemImage: "trophy.fill"
                )
            }
        }
        .navigationTitle("Fantasy")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
    }

    private var fantasyContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Fantasy Extraliga — sestav tým z hráčů podle jejich karet a sbírej body za jejich výkony.")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hbCard(cornerRadius: HBTheme.radiusSm)

                    roundHeader
                    fixturesBlock
                    menuBlock
                    displayToggles
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.top, 12)
            }
            .background(HBTheme.canvas)

            FantasyDeadlineBar(
                canSave: fantasy.isViewingEditable && fantasy.isComplete,
                hasChanges: fantasy.hasUnsavedChanges,
                onSave: saveSquad
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Fantasy")
                        .font(.hbMontserrat(size: 16, weight: .bold))
                    Text("Extraliga")
                        .font(.hbMontserrat(size: 10, weight: .semibold))
                        .foregroundStyle(HBTheme.textTertiary)
                }
            }
        }
        .hbNavigationStyle()
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(HBTheme.ink.opacity(0.92), in: Capsule())
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task { await loadData() }
    }

    // MARK: Round

    private var roundHeader: some View {
        HStack {
            Button { fantasy.shiftViewingGameweek(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HBTheme.brand)
                    .frame(width: 36, height: 36)
                    .background(HBTheme.card, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(fantasy.viewingGameweek <= 1)
            .opacity(fantasy.viewingGameweek <= 1 ? 0.35 : 1)

            Spacer()
            Text("\(fantasy.viewingGameweek). KOLO")
                .font(.hbDisplay(size: 22, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
            Spacer()

            Button { fantasy.shiftViewingGameweek(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HBTheme.brand)
                    .frame(width: 36, height: 36)
                    .background(HBTheme.card, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var fixturesBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ZÁPASY KOLA")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(HBTheme.textTertiary)

            if roundFixtures.isEmpty {
                Text("Pro toto kolo zatím nejsou zápasy.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(roundFixtures.prefix(12)) { match in
                        FantasyFixtureChip(match: match)
                    }
                }
            }
        }
    }

    private var menuBlock: some View {
        VStack(spacing: 0) {
            menuLink("Můj tým", icon: "person.fill", destination: FantasyMyTeamView(players: $players, matches: matches))
            menuDivider
            menuLink("Hráčský trh", icon: "arrow.left.arrow.right", destination: FantasyMarketView(players: players, matches: matches))
            menuDivider
            menuLink("Žebříček", icon: "list.number", destination: FantasyLeaderboardView())
            menuDivider
            menuLink("Pravidla", icon: "book.fill", destination: FantasyRulesScreen())
        }
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func menuLink<Dest: View>(_ title: String, icon: String, destination: Dest) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
                    .frame(width: 28)
                Text(title)
                    .font(.hbMontserrat(size: 16, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(HBTheme.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 56)
    }

    private var displayToggles: some View {
        VStack(spacing: 8) {
            toggleRow("Zobrazit cenu hráčů", isOn: $fantasy.showPriceOnPitch)
            toggleRow("Zobrazit body za kolo", isOn: $fantasy.showPointsOnPitch)
            toggleRow("Zobrazit soupeře", isOn: $fantasy.showOpponentOnPitch)
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack {
                Text(title)
                    .font(.hbMontserrat(size: 14, weight: .semibold))
                    .foregroundStyle(isOn.wrappedValue ? HBTheme.onBrand : HBTheme.textPrimary)
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isOn.wrappedValue ? HBTheme.onBrand : HBTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn.wrappedValue ? HBTheme.brand : HBTheme.card)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isOn.wrappedValue ? Color.clear : HBTheme.cardStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func saveSquad() {
        if let error = fantasy.saveLineup() {
            showToast(error)
        } else {
            showToast(fantasy.lastSaveMessage ?? "Uloženo")
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }

    private func loadData() async {
        // Parametry hráčů (OVR z nich). Na mock datech je vygenerujeme, jinak ze serveru.
        if !FantasyMock.enabled {
            await attributes.loadIfNeeded()
        }

        let all = (try? await apiClient.api.players(teamId: nil)) ?? []
        for teamId in Set(all.map(\.teamId)) where catalog.team(teamId) == nil {
            if let team = try? await apiClient.api.team(id: teamId) {
                catalog.upsertTeam(team)
            }
        }
        let teams = catalog.teamsById
        let comps = Dictionary(uniqueKeysWithValues: catalog.competitions.map { ($0.id, $0) })
        let filtered = all.filter { FantasyRules.isExtraligaPlayer($0, teamsById: teams, competitionsById: comps) }
        // Mock parametry nasadit před řazením, aby OVR odpovídalo kartám.
        if FantasyMock.enabled {
            attributes.seedMock(for: filtered)
        }
        players = filtered.sorted { FantasyRules.rating(for: $0) > FantasyRules.rating(for: $1) }

        let extraligaIds = Set(catalog.competitions.filter { $0.slug == FantasyRules.competitionSlug }.map(\.id))
        if let firstId = extraligaIds.first {
            matches = (try? await apiClient.api.matches(query: MatchesQuery(competitionId: firstId))) ?? []
        } else {
            matches = ((try? await apiClient.api.matches(query: MatchesQuery())) ?? [])
                .filter { $0.competitionId.contains("extraliga") }
        }

        // Kalendář kol → server sestavy/skóre → vyhodnocení uzavřených kol → žebříček.
        fantasy.syncGameweekIfNeeded()
        await fantasy.loadRemote()
        let gained = fantasy.scorePendingGameweeks(playersById: playersById, matches: matches)
        if gained > 0 {
            showToast("Vyhodnoceno kolo · +\(gained) b")
        }
        await fantasy.loadLeaderboard()
    }
}

// MARK: - Fixture chip

private struct FantasyFixtureChip: View {
    @EnvironmentObject private var catalog: CatalogStore
    let match: Match

    private var timeLabel: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.timeZone = FantasyDeadline.prague
        df.dateFormat = "E d. MM. HH:mm"
        return df.string(from: match.scheduledAt)
    }

    var body: some View {
        HStack(spacing: 6) {
            if let home = catalog.team(match.homeTeamId) {
                TeamBadge(team: home, size: 22)
            }
            Text(timeLabel)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            if let away = catalog.team(match.awayTeamId) {
                TeamBadge(team: away, size: 22)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(HBTheme.cardStroke, lineWidth: 1)
        }
    }
}

// MARK: - Deadline bar

struct FantasyDeadlineBar: View {
    @EnvironmentObject private var fantasy: FantasySquadStore
    var canSave: Bool
    var hasChanges: Bool
    var onSave: () -> Void

    @State private var now = Date()
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var parts: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        FantasyDeadline.countdownParts(to: fantasy.deadline, from: now)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEADLINE SESTAVY")
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.7))
                HStack(spacing: 6) {
                    unit(parts.days, "DNY")
                    sep
                    unit(parts.hours, "HOD.")
                    sep
                    unit(parts.minutes, "MIN.")
                    sep
                    unit(parts.seconds, "SEK.")
                }
            }

            Button(action: onSave) {
                Text(fantasy.isLocked ? "UZAMČENO" : "ULOŽIT SESTAVU")
                    .font(.hbMontserrat(size: 12, weight: .heavy))
                    .foregroundStyle(HBTheme.ink)
                    .multilineTextAlignment(.center)
                    .frame(width: 108)
                    .padding(.vertical, 14)
                    .background(
                        Color(red: 1.0, green: 0.84, blue: 0.28).opacity(canSave ? 1 : 0.45),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [HBTheme.brand, HBTheme.brandDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .shadow(color: HBTheme.brand.opacity(0.35), radius: 16, y: -4)
        )
        .onReceive(clock) { now = $0 }
    }

    private var sep: some View {
        Text(":")
            .font(.hbNumber(size: 16, weight: .heavy))
            .foregroundStyle(.white.opacity(0.55))
    }

    private func unit(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d", value))
                .font(.hbNumber(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.hbMontserrat(size: 8, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.55))
        }
    }
}

// MARK: - Můj tým

struct FantasyMyTeamView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var fantasy: FantasySquadStore
    @Binding var players: [Player]
    var matches: [Match]

    @State private var pickingSlot: FantasySlot?
    @State private var inspectingPlayer: Player?
    @State private var errorMessage: String?
    @State private var toast: String?

    private var playersById: [String: Player] {
        Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 14) {
                    statsGrid
                    TextField("Název týmu", text: $fantasy.teamName)
                        .font(.hbMontserrat(size: 15, weight: .semibold))
                        .padding(12)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(.white)
                        .disabled(!fantasy.isViewingEditable)

                    FantasyHockeyRink(
                        playersById: playersById,
                        matches: matches,
                        cardSize: .regular,
                        interactive: true,
                        onSelectSlot: { pickingSlot = $0 },
                        onInspectPlayer: { inspectingPlayer = $0 }
                    )

                    Text(fantasy.isViewingEditable
                         ? "Klepni na slot = výběr. Na hráče = forma a soupeř. Dlouhý stisk = výměna."
                         : "Sestava je uzamčená nebo prohlížíš jiné kolo.")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Color.clear.frame(height: 110)
                }
                .padding(HBTheme.screenPadding)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.22, blue: 0.30),
                        Color(red: 0.05, green: 0.12, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            FantasyDeadlineBar(
                canSave: fantasy.isViewingEditable && fantasy.isComplete,
                hasChanges: fantasy.hasUnsavedChanges,
                onSave: {
                    if let error = fantasy.saveLineup() {
                        toast = error
                    } else {
                        toast = fantasy.lastSaveMessage
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        toast = nil
                    }
                }
            )
        }
        .navigationTitle("Můj tým")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hbNavigationStyle()
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HBTheme.ink.opacity(0.9), in: Capsule())
                    .padding(.top, 8)
            }
        }
        .sheet(item: $pickingSlot) { slot in
            FantasyPlayerPickerView(
                slot: slot,
                players: players.filter { $0.position == slot.position },
                selectedIds: fantasy.selectedPlayerIds,
                matches: matches,
                remainingBudget: fantasy.remainingBudget(playersById: playersById)
                    + (fantasy.playerId(for: slot).flatMap { playersById[$0] }.map { FantasyRules.priceCredits(for: $0) } ?? 0)
            ) { player in
                if let error = fantasy.assign(player, to: slot, playersById: playersById) {
                    errorMessage = error
                } else {
                    pickingSlot = nil
                }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $inspectingPlayer) { player in
            FantasyPlayerScoutView(
                player: player,
                team: catalog.team(player.teamId),
                matches: matches,
                canReplace: fantasy.isViewingEditable,
                onReplace: {
                    if let slot = fantasy.slotContaining(playerId: player.id) {
                        inspectingPlayer = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            pickingSlot = slot
                        }
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Nelze doplnit", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 8) {
            FantasyStatTile(title: "MOJE BODY", value: "\(fantasy.seasonPoints)", wide: true)
            HStack(spacing: 8) {
                FantasyStatTile(title: "PŘESTUPY", value: fantasy.transfersLabel)
                FantasyStatTile(title: "ROZPOČET", value: "\(fantasy.remainingBudget(playersById: playersById)) kr")
            }
            HStack(spacing: 8) {
                FantasyStatTile(title: "CELKOVÉ POŘADÍ", value: "\(fantasy.overallRank)")
                FantasyStatTile(title: "POŘADÍ ZA KOLO", value: "\(max(1, fantasy.overallRank / 2 + fantasy.squadPoints(playersById: playersById)))")
            }
        }
    }
}

private struct FantasyStatTile: View {
    let title: String
    let value: String
    var wide: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(HBTheme.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(HBTheme.brand)
            Text(value)
                .font(.hbNumber(size: wide ? 28 : 22, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(HBTheme.cardStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Rink

struct FantasyHockeyRink: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var fantasy: FantasySquadStore

    let playersById: [String: Player]
    var matches: [Match] = []
    var cardSize: FantasyCardSize = .regular
    var interactive: Bool = true
    var onSelectSlot: ((FantasySlot) -> Void)? = nil
    var onInspectPlayer: ((Player) -> Void)? = nil

    var body: some View {
        ZStack {
            rinkBackground
            VStack(spacing: cardSize == .compact ? 14 : 18) {
                lineLabel("BRANKÁŘ")
                slotRow([.goalie])
                rinkDivider
                lineLabel("OBRANA")
                slotRow([.defense1, .defense2])
                rinkDivider
                lineLabel("ÚTOK")
                slotRow([.forward1, .forward2, .forward3])
            }
            .padding(.vertical, cardSize == .compact ? 12 : 16)
            .padding(.horizontal, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 2)
        }
    }

    private var rinkBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.38, blue: 0.52),
                    Color(red: 0.08, green: 0.28, blue: 0.40),
                    Color(red: 0.06, green: 0.22, blue: 0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.5)
                .frame(width: 88, height: 88)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                .frame(width: 70, height: 36)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 28)
        }
    }

    private var rinkDivider: some View {
        Rectangle()
            .fill(HBTheme.brand.opacity(0.7))
            .frame(height: 2)
            .padding(.horizontal, 20)
    }

    private func lineLabel(_ text: String) -> some View {
        Text(text)
            .font(.hbMontserrat(size: 9, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(Color.white.opacity(0.55))
    }

    private func slotRow(_ slots: [FantasySlot]) -> some View {
        HStack(spacing: cardSize == .compact ? 8 : 12) {
            ForEach(slots) { slot in
                let player = fantasy.playerId(for: slot).flatMap { playersById[$0] }
                let team = player.flatMap { catalog.team($0.teamId) }
                let opp = player.flatMap { opponentCaption(for: $0) }

                Group {
                    if let player {
                        FantasyPlayerCard(
                            player: player,
                            team: team,
                            size: cardSize,
                            showsPrice: fantasy.showPriceOnPitch,
                            showsPoints: fantasy.showPointsOnPitch,
                            opponentLabel: fantasy.showOpponentOnPitch ? opp : nil
                        )
                        .onTapGesture {
                            guard interactive else { return }
                            onInspectPlayer?(player)
                        }
                        .onLongPressGesture {
                            guard interactive, fantasy.isViewingEditable else { return }
                            onSelectSlot?(slot)
                        }
                    } else {
                        FantasyPlayerCard(
                            player: Player(
                                id: "empty-\(slot.rawValue)",
                                firstName: "",
                                lastName: "",
                                number: 0,
                                position: slot.position,
                                teamId: "",
                                games: 0, goals: 0, assists: 0, points: 0, penaltyMinutes: 0,
                                savePercentage: nil, goalsAgainstAverage: nil
                            ),
                            size: cardSize,
                            isEmpty: true,
                            emptyTitle: fantasy.isViewingEditable ? "Přidat" : "—",
                            emptyPosition: slot.shortTitle
                        )
                        .onTapGesture {
                            guard interactive, fantasy.isViewingEditable else { return }
                            onSelectSlot?(slot)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func opponentCaption(for player: Player) -> String? {
        guard let match = FantasyRules.nextFixture(for: player.teamId, in: matches) else { return nil }
        let isHome = match.homeTeamId == player.teamId
        let oppId = isHome ? match.awayTeamId : match.homeTeamId
        let name = catalog.team(oppId)?.shortName ?? "?"
        return "\(name) (\(isHome ? "D" : "V"))"
    }
}

// MARK: - Market

struct FantasyMarketView: View {
    @EnvironmentObject private var fantasy: FantasySquadStore
    let players: [Player]
    let matches: [Match]

    @State private var slotFilter: PlayerPosition?

    private var filteredPlayers: [Player] {
        guard let slotFilter else { return players }
        return players.filter { $0.position == slotFilter }
    }

    var body: some View {
        FantasyPlayerPickerContent(
            slot: .forward1,
            players: filteredPlayers,
            selectedIds: fantasy.selectedPlayerIds,
            matches: matches,
            remainingBudget: fantasy.remainingBudget(
                playersById: Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
            ),
            marketMode: true,
            onSelect: { player in
                let playersById = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
                let slots = FantasySlot.allCases.filter { $0.position == player.position }
                let target = slots.first { fantasy.playerId(for: $0) == nil } ?? slots.first
                guard let target else { return }
                _ = fantasy.assign(player, to: target, playersById: playersById)
            }
        )
        .navigationTitle("Hráčský trh")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Všechny pozice") { slotFilter = nil }
                    Button("Brankáři") { slotFilter = .goalie }
                    Button("Obránci") { slotFilter = .defenseman }
                    Button("Útočníci") { slotFilter = .forward }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

// MARK: - Leaderboard / Rules

struct FantasyLeaderboardView: View {
    @EnvironmentObject private var fantasy: FantasySquadStore

    private struct Row: Identifiable {
        let id: String
        let rank: Int
        let name: String
        let points: Int
        let isMe: Bool
    }

    private var rows: [Row] {
        // Reálný žebříček ze serveru; jinak lokální demo s boty.
        if !fantasy.remoteLeaderboard.isEmpty {
            let myId = AuthAccess.store?.userId
            return fantasy.remoteLeaderboard.enumerated().map { index, entry in
                Row(
                    id: entry.userId,
                    rank: index + 1,
                    name: entry.displayName ?? entry.username ?? "Hráč",
                    points: entry.totalPoints,
                    isMe: entry.userId == myId
                )
            }
        }
        let me = (fantasy.teamName, fantasy.seasonPoints, true)
        let bots: [(String, Int, Bool)] = [
            ("Hostivař Ultra", max(0, fantasy.seasonPoints + 12), false),
            ("Lední žraloci", max(0, fantasy.seasonPoints + 4), false),
            ("Pardubický sen", max(0, fantasy.seasonPoints - 3), false),
            ("Plzeňský expres", max(0, fantasy.seasonPoints - 9), false),
        ]
        return ([me] + bots)
            .sorted { $0.1 > $1.1 }
            .enumerated()
            .map { index, row in Row(id: "\(row.0)-\(index)", rank: index + 1, name: row.0, points: row.1, isMe: row.2) }
    }

    var body: some View {
        List {
            if fantasy.remoteLeaderboard.isEmpty {
                Text("Zatím jen lokální demo — po prvním vyhodnocení kola se objeví reálné pořadí všech hráčů.")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .listRowBackground(HBTheme.card)
            }
            ForEach(rows) { row in
                HStack {
                    Text("\(row.rank)")
                        .font(.hbNumber(size: 16, weight: .heavy))
                        .foregroundStyle(row.isMe ? HBTheme.brand : HBTheme.textSecondary)
                        .frame(width: 28, alignment: .leading)
                    Text(row.name)
                        .font(.hbMontserrat(size: 15, weight: row.isMe ? .bold : .semibold))
                        .foregroundStyle(HBTheme.textPrimary)
                    Spacer()
                    Text("\(row.points) b")
                        .font(.hbNumber(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.textSecondary)
                }
                .listRowBackground(row.isMe ? HBTheme.brand.opacity(0.08) : HBTheme.card)
            }
        }
        .navigationTitle("Žebříček")
        .hbNavigationStyle()
        .task { await fantasy.loadLeaderboard() }
    }
}

struct FantasyRulesScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                rule("Týdenní sestava", "Každé kolo vlastní sestava 1 brankář · 2 obránci · 3 útočníci.")
                rule("Deadline", "Uzávěrka vždy v sobotu v 10:00 (Praha). Poté je sestava zamčená.")
                rule("Rozpočet", "\(FantasyRules.budgetCredits) kreditů. Cena hráče 4–15 podle ratingu (OVR).")
                rule("Kluby", "Max. \(FantasyRules.maxFromSameClub) hráči z jednoho klubu.")
                rule("Rating", "OVR z parametrů hráče (rychlost, síla, střela…). Když parametry chybí, spočítá se ze statistik.")
                rule("Body", "Podle reálného výkonu za víkend: gól 3 · asistence 2 · brankářské bonusy. Sečtou se po uzávěrce kola.")
                rule("Žebříček", "Body se sčítají za celou sezónu a porovnávají se všemi hráči.")
                rule("Uložení", "Nezapomeň klepnout ULOŽIT SESTAVU před deadlinem — jinak se do žebříčku nezapočítá.")
            }
            .padding(HBTheme.screenPadding)
        }
        .background(HBTheme.canvas)
        .navigationTitle("Pravidla")
        .hbNavigationStyle()
    }

    private func rule(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.hbMontserrat(size: 15, weight: .bold))
            Text(text)
                .font(.hbMontserrat(size: 13, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }
}

// MARK: - Picker

private enum FantasyPickerSort: String, CaseIterable, Identifiable {
    case rating, price, points, name
    var id: String { rawValue }
    var label: String {
        switch self {
        case .rating: return "OVR"
        case .price: return "Cena"
        case .points: return "Body"
        case .name: return "Jméno"
        }
    }
}

struct FantasyPlayerPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let slot: FantasySlot
    let players: [Player]
    let selectedIds: Set<String>
    let matches: [Match]
    let remainingBudget: Int
    var marketMode: Bool = false
    let onSelect: (Player) -> Void

    var body: some View {
        NavigationStack {
            FantasyPlayerPickerContent(
                slot: slot,
                players: players,
                selectedIds: selectedIds,
                matches: matches,
                remainingBudget: remainingBudget,
                marketMode: marketMode,
                onSelect: onSelect
            )
            .navigationTitle(marketMode ? "Trh" : slot.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
        }
    }
}

struct FantasyPlayerPickerContent: View {
    @EnvironmentObject private var catalog: CatalogStore

    let slot: FantasySlot
    let players: [Player]
    let selectedIds: Set<String>
    let matches: [Match]
    let remainingBudget: Int
    var marketMode: Bool = false
    let onSelect: (Player) -> Void

    @State private var query = ""
    @State private var sort: FantasyPickerSort = .rating
    @State private var clubFilter: String?
    @State private var maxPrice: Int = 15
    @State private var scoutPlayer: Player?

    private var clubs: [Team] {
        let ids = Set(players.map(\.teamId))
        return ids.compactMap { catalog.team($0) }.sorted { $0.shortName < $1.shortName }
    }

    private var filtered: [Player] {
        var list = players
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.fullName.lowercased().contains(q)
                    || (catalog.team($0.teamId)?.shortName.lowercased().contains(q) ?? false)
            }
        }
        if let clubFilter { list = list.filter { $0.teamId == clubFilter } }
        list = list.filter { FantasyRules.priceCredits(for: $0) <= maxPrice }
        switch sort {
        case .rating: list.sort { FantasyRules.rating(for: $0) > FantasyRules.rating(for: $1) }
        case .price: list.sort { FantasyRules.priceCredits(for: $0) > FantasyRules.priceCredits(for: $1) }
        case .points: list.sort { FantasyRules.fantasyPoints(for: $0) > FantasyRules.fantasyPoints(for: $1) }
        case .name: list.sort { $0.lastName < $1.lastName }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { player in
                        playerRow(player)
                    }
                }
                .padding(HBTheme.screenPadding)
                .padding(.bottom, 24)
            }
        }
        .background(HBTheme.canvas)
        .searchable(text: $query, prompt: "Hráč nebo klub")
        .sheet(item: $scoutPlayer) { player in
            FantasyPlayerScoutView(
                player: player,
                team: catalog.team(player.teamId),
                matches: matches,
                canReplace: false,
                onReplace: {}
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(marketMode ? "Extraliga" : "Rozpočet slotu: \(remainingBudget) kr")
                    .font(.hbMontserrat(size: 12, weight: .bold))
                    .foregroundStyle(HBTheme.textSecondary)
                Spacer()
                Text("Max \(maxPrice) kr")
                    .font(.hbMontserrat(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            Slider(value: Binding(get: { Double(maxPrice) }, set: { maxPrice = Int($0) }), in: 4...15, step: 1)
                .tint(HBTheme.brand)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FantasyPickerSort.allCases) { item in
                        chip(item.label, selected: sort == item) { sort = item }
                    }
                    Divider().frame(height: 20)
                    chip("Všechny kluby", selected: clubFilter == nil) { clubFilter = nil }
                    ForEach(clubs) { team in
                        chip(team.shortName, selected: clubFilter == team.id) { clubFilter = team.id }
                    }
                }
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .background(HBTheme.surface)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.hbMontserrat(size: 11, weight: .bold))
                .foregroundStyle(selected ? HBTheme.onBrand : HBTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(selected ? HBTheme.brand : HBTheme.cardInset, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func playerRow(_ player: Player) -> some View {
        let taken = selectedIds.contains(player.id)
        let price = FantasyRules.priceCredits(for: player)
        let affordable = price <= remainingBudget || taken
        let form = TeamFormCalculator.items(from: matches, teamId: player.teamId)
        let fixture = FantasyRules.nextFixture(for: player.teamId, in: matches)

        return HStack(spacing: 12) {
            Button { scoutPlayer = player } label: {
                FantasyPlayerCard(player: player, team: catalog.team(player.teamId), size: .compact, showsPrice: true)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(player.fullName)
                    .font(.hbMontserrat(size: 15, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
                Text(catalog.team(player.teamId)?.shortName ?? "Tým")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                HStack(spacing: 8) {
                    meta("OVR \(FantasyRules.rating(for: player))")
                    meta("\(price) kr")
                    meta("\(FantasyRules.fantasyPoints(for: player)) b")
                }
                HStack(spacing: 8) {
                    TeamFormBadges(items: form, size: 16)
                    if let fixture {
                        Text(fixtureLabel(fixture, teamId: player.teamId))
                            .font(.hbMontserrat(size: 10, weight: .semibold))
                            .foregroundStyle(HBTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button { scoutPlayer = player } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                        .frame(width: 36, height: 36)
                        .background(HBTheme.brand.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)

                if !marketMode {
                    Button { onSelect(player) } label: {
                        Image(systemName: taken ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(affordable ? (taken ? HBTheme.win : HBTheme.brand) : HBTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!affordable && !taken)
                }
            }
        }
        .padding(10)
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .opacity(affordable || taken || marketMode ? 1 : 0.45)
    }

    private func fixtureLabel(_ match: Match, teamId: String) -> String {
        let isHome = match.homeTeamId == teamId
        let opp = catalog.team(isHome ? match.awayTeamId : match.homeTeamId)?.shortName ?? "?"
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.dateFormat = "E d.M."
        return "\(isHome ? "vs" : "@") \(opp) · \(df.string(from: match.scheduledAt))"
    }

    private func meta(_ text: String) -> some View {
        Text(text)
            .font(.hbMontserrat(size: 10, weight: .bold))
            .foregroundStyle(HBTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(HBTheme.cardInset, in: Capsule())
    }
}

// MARK: - Scout

struct FantasyPlayerScoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var attributes: FantasyAttributesStore

    let player: Player
    let team: Team?
    let matches: [Match]
    var canReplace: Bool = false
    var onReplace: () -> Void = {}

    private var rating: Int { FantasyRules.rating(for: player) }
    private var tier: FantasyCardTier { FantasyRules.tier(for: rating) }
    private var form: [TeamFormItem] { TeamFormCalculator.items(from: matches, teamId: player.teamId) }
    private var fixture: Match? { FantasyRules.nextFixture(for: player.teamId, in: matches) }
    private var attributeRows: [(label: String, value: Int)] {
        attributes.attributes(for: player.id)?.displayRows(position: player.position) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    FantasyPlayerCard(player: player, team: team, size: .large, showsPrice: true, showsPoints: true)

                    HStack(spacing: 10) {
                        scoutStat("OVR", "\(rating)")
                        scoutStat("Cena", "\(FantasyRules.priceCredits(for: player)) kr")
                        scoutStat("Tier", tier.label)
                        scoutStat("FPTS", "\(FantasyRules.fantasyPoints(for: player))")
                    }

                    if !attributeRows.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PARAMETRY")
                                .font(.hbMontserrat(size: 11, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(HBTheme.textTertiary)
                            ForEach(attributeRows, id: \.label) { row in
                                HStack(spacing: 10) {
                                    Text(row.label)
                                        .font(.hbMontserrat(size: 12, weight: .semibold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                        .frame(width: 82, alignment: .leading)
                                    ProgressView(value: Double(row.value), total: 99)
                                        .tint(HBTheme.brand)
                                    Text("\(row.value)")
                                        .font(.hbNumber(size: 13, weight: .bold))
                                        .foregroundStyle(HBTheme.textSecondary)
                                        .frame(width: 26, alignment: .trailing)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hbCard(cornerRadius: HBTheme.radiusMd)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("FORMA KLUBU")
                            .font(.hbMontserrat(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(HBTheme.textTertiary)
                        HStack {
                            if let team {
                                TeamBadge(team: team, size: 28)
                                Text(team.shortName).font(.hbMontserrat(size: 15, weight: .bold))
                            }
                            Spacer()
                            TeamFormBadges(items: form, size: 24)
                        }
                    }
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("PŘÍŠTÍ ZÁPAS")
                            .font(.hbMontserrat(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(HBTheme.textTertiary)
                        if let fixture, let team {
                            let isHome = fixture.homeTeamId == team.id
                            let opp = catalog.team(isHome ? fixture.awayTeamId : fixture.homeTeamId)
                            HStack(spacing: 12) {
                                if let opp { TeamBadge(team: opp, size: 36) }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isHome ? "Doma vs \(opp?.shortName ?? "soupeř")" : "Venku @ \(opp?.shortName ?? "soupeř")")
                                        .font(.hbMontserrat(size: 16, weight: .bold))
                                    Text(fixtureDate(fixture.scheduledAt))
                                        .font(.hbMontserrat(size: 13, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                }
                                Spacer()
                            }
                        } else {
                            Text("Žádný nadcházející zápas.")
                                .foregroundStyle(HBTheme.textSecondary)
                        }
                    }
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)

                    if canReplace {
                        Button(action: onReplace) {
                            Text("Vyměnit hráče")
                                .font(.hbMontserrat(size: 15, weight: .bold))
                                .foregroundStyle(HBTheme.onBrand)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(HBTheme.brandGradient, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(HBTheme.screenPadding)
                .padding(.bottom, 28)
            }
            .background(HBTheme.canvas)
            .navigationTitle(player.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
        }
    }

    private func scoutStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .foregroundStyle(HBTheme.textTertiary)
            Text(value)
                .font(.hbNumber(size: 15, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func fixtureDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.timeZone = FantasyDeadline.prague
        df.dateFormat = "EEEE d. M. yyyy · HH:mm"
        return df.string(from: date)
    }
}

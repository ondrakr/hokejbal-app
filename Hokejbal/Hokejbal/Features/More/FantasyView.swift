import SwiftUI

// MARK: - Sdílené prvky

/// Nadpis sekce (KOLO, MOJE SESTAVA…).
private struct FantasySectionLabel: View {
    let text: String
    var onDark: Bool = false

    var body: some View {
        Text(text)
            .font(.hbMontserrat(size: 11, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(onDark ? Color.white.opacity(0.45) : HBTheme.textTertiary)
    }
}

/// Kompaktní dlaždice se statistikou. Na tmavém podkladu i na plátně.
private struct FantasyStatCell: View {
    let label: String
    let value: String
    var hint: String? = nil
    var onDark: Bool = true

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.hbMontserrat(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(onDark ? Color.white.opacity(0.5) : HBTheme.textTertiary)
                .lineLimit(1)
            Text(value)
                .font(.hbNumber(size: 17, weight: .heavy))
                .foregroundStyle(onDark ? Color.white : HBTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let hint {
                Text(hint)
                    .font(.hbMontserrat(size: 9, weight: .semibold))
                    .foregroundStyle(onDark ? Color.white.opacity(0.4) : HBTheme.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            onDark ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(HBTheme.card),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

/// Pruh využitého rozpočtu — zezelena přes oranžovou do červené.
private struct FantasyBudgetBar: View {
    let spent: Int
    let budget: Int
    var onDark: Bool = true

    private var ratio: Double {
        guard budget > 0 else { return 0 }
        return min(1, max(0, Double(spent) / Double(budget)))
    }

    private var color: Color {
        if ratio > 0.95 { return HBTheme.loss }
        if ratio > 0.8 { return HBTheme.draw }
        return HBTheme.win
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(onDark ? Color.white.opacity(0.15) : HBTheme.cardInset)
                Capsule().fill(color).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 6)
    }
}

/// Odpočet do uzávěrky sestavy — vlastní tik po sekundě.
private struct FantasyCountdown: View {
    let deadline: Date

    @State private var now = Date()
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let parts = FantasyDeadline.countdownParts(to: deadline, from: now)
        HStack(alignment: .bottom, spacing: 5) {
            unit(parts.days, "DNY")
            separator
            unit(parts.hours, "HOD")
            separator
            unit(parts.minutes, "MIN")
            separator
            unit(parts.seconds, "SEK")
        }
        .onReceive(clock) { now = $0 }
    }

    private var separator: some View {
        Text(":")
            .font(.hbNumber(size: 15, weight: .heavy))
            .foregroundStyle(.white.opacity(0.35))
            .padding(.bottom, 12)
    }

    /// Jedna dvojčíslí odpočtu s popiskem.
    private func unit(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d", value))
                .font(.hbNumber(size: 19, weight: .heavy))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.hbMontserrat(size: 8, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(minWidth: 38)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

/// Spodní lišta „Můj tým“ — odpočet a uložení sestavy.
struct FantasySaveBar: View {
    @EnvironmentObject private var fantasy: FantasySquadStore
    var onSave: () -> Void

    private var missing: Int { max(0, FantasyRules.squadSize - fantasy.filledCount) }
    private var canSave: Bool { fantasy.isViewingEditable && fantasy.isComplete }

    private var title: String {
        if !fantasy.isViewingEditable { return "UZAMČENO" }
        if missing == 0 { return "ULOŽIT\nSESTAVU" }
        return "CHYBÍ\n\(missing) \(Self.playerWord(missing))"
    }

    /// Skloňování „hráč“ pro počet chybějících slotů.
    private static func playerWord(_ count: Int) -> String {
        switch count {
        case 1: return "HRÁČ"
        case 2...4: return "HRÁČI"
        default: return "HRÁČŮ"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fantasy.isViewingEditable ? "DO UZÁVĚRKY SESTAVY" : "SESTAVA UZAMČENA")
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.65))
                FantasyCountdown(deadline: fantasy.deadline)
            }

            Spacer(minLength: 0)

            Button(action: onSave) {
                Text(title)
                    .font(.hbMontserrat(size: 12, weight: .heavy))
                    .foregroundStyle(HBTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
                    .frame(width: 104)
                    .padding(.vertical, 12)
                    .background(
                        Color(red: 1.0, green: 0.84, blue: 0.28).opacity(canSave ? 1 : 0.45),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [HBTheme.brand, HBTheme.brandDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .shadow(color: HBTheme.brand.opacity(0.35), radius: 16, y: -4)
        )
    }
}

// MARK: - Hub (Centrála)

/// Fantasy Extraliga — rozcestník se sestavou, trhem a žebříčkem.
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

    private var spentCredits: Int { fantasy.spentCredits(playersById: playersById) }
    private var remainingCredits: Int { FantasyRules.budgetCredits - spentCredits }

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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                squadPreview
                menuGrid
                fixturesBlock
                displayToggles

                Text("Lokální demo — body a žebříček zatím jen na tomto zařízení.")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)

                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.top, 12)
        }
        .background(HBTheme.canvas)
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
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task { await loadData() }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button { fantasy.shiftViewingGameweek(by: -1) } label: {
                    heroArrow("chevron.left")
                }
                .buttonStyle(.plain)
                .disabled(fantasy.viewingGameweek <= 1)
                .opacity(fantasy.viewingGameweek <= 1 ? 0.3 : 1)

                Spacer(minLength: 0)

                VStack(spacing: 3) {
                    Text("\(fantasy.viewingGameweek). KOLO")
                        .font(.hbDisplay(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                    if fantasy.viewingGameweek != fantasy.activeGameweek {
                        Text("ARCHIV")
                            .font(.hbMontserrat(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(Color.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }

                Spacer(minLength: 0)

                Button { fantasy.shiftViewingGameweek(by: 1) } label: {
                    heroArrow("chevron.right")
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    FantasySectionLabel(text: "DO UZÁVĚRKY", onDark: true)
                    FantasyCountdown(deadline: fantasy.deadline)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    FantasySectionLabel(text: "MOJE BODY", onDark: true)
                    Text("\(fantasy.seasonPoints)")
                        .font(.hbNumber(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.14, blue: 0.19),
                    Color(red: 0.07, green: 0.09, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    /// Kulaté tlačítko pro posun kola.
    private func heroArrow(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Color.white.opacity(0.12), in: Circle())
    }

    // MARK: Sestava

    private var squadPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom) {
                FantasySectionLabel(text: "MOJE SESTAVA")
                Spacer()
                Text("\(fantasy.filledCount)/\(FantasyRules.squadSize) · \(remainingCredits) kr zbývá")
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .foregroundStyle(HBTheme.textSecondary)
            }

            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FantasySlot.allCases) { slot in
                            if let id = fantasy.playerId(for: slot), let player = playersById[id] {
                                FantasyPlayerCard(
                                    player: player,
                                    team: catalog.team(player.teamId),
                                    size: .compact,
                                    showsPrice: true
                                )
                            } else {
                                FantasyPlayerCard(
                                    player: Player.fantasyPlaceholder(for: slot),
                                    size: .compact,
                                    isEmpty: true,
                                    emptyTitle: "Přidat",
                                    emptyPosition: slot.shortTitle,
                                    emptyTone: .light
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }

                FantasyBudgetBar(spent: spentCredits, budget: FantasyRules.budgetCredits, onDark: false)

                NavigationLink {
                    FantasyMyTeamView(players: $players, matches: matches)
                } label: {
                    Text(fantasy.isComplete ? "Upravit sestavu" : "Doplnit sestavu")
                        .font(.hbMontserrat(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(HBTheme.brandGradient, in: Capsule())
                }
                .buttonStyle(.plain)

                if fantasy.hasUnsavedChanges {
                    Text("Máš neuložené změny sestavy.")
                        .font(.hbMontserrat(size: 11, weight: .bold))
                        .foregroundStyle(HBTheme.draw)
                }
            }
            .padding(12)
            .hbCard(cornerRadius: HBTheme.radiusMd)
        }
    }

    // MARK: Rozcestník

    private var menuGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            NavigationLink {
                FantasyMyTeamView(players: $players, matches: matches)
            } label: {
                menuTile("Můj tým", subtitle: "Sestav hráče na hřišti", icon: "person.fill")
            }
            .buttonStyle(.plain)

            NavigationLink {
                FantasyMarketView(players: players, matches: matches)
            } label: {
                menuTile("Hráčský trh", subtitle: "Prohlédni si všechny karty", icon: "square.stack.3d.up.fill")
            }
            .buttonStyle(.plain)

            NavigationLink {
                FantasyLeaderboardView()
            } label: {
                menuTile("Žebříček", subtitle: "Pořadí za sezónu", icon: "list.number")
            }
            .buttonStyle(.plain)

            NavigationLink {
                FantasyRulesScreen()
            } label: {
                menuTile("Pravidla", subtitle: "Body, rozpočet, uzávěrka", icon: "book.fill")
            }
            .buttonStyle(.plain)
        }
    }

    /// Dlaždice rozcestníku.
    private func menuTile(_ title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(HBTheme.brand)
                .frame(width: 36, height: 36)
                .background(HBTheme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.hbMontserrat(size: 15, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
            Text(subtitle)
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    // MARK: Zápasy kola

    private var fixturesBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            FantasySectionLabel(text: "ZÁPASY \(fantasy.viewingGameweek). KOLA")

            if roundFixtures.isEmpty {
                Text("Pro toto kolo zatím nejsou zápasy.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
            } else {
                VStack(spacing: 0) {
                    let shown = Array(roundFixtures.prefix(12))
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, match in
                        FantasyFixtureRow(match: match)
                        if index < shown.count - 1 {
                            Rectangle()
                                .fill(HBTheme.separator.opacity(0.45))
                                .frame(height: 0.5)
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.vertical, 4)
                .hbCard(cornerRadius: HBTheme.radiusMd)
            }
        }
    }

    // MARK: Zobrazení karet

    private var displayToggles: some View {
        VStack(alignment: .leading, spacing: 10) {
            FantasySectionLabel(text: "ZOBRAZIT NA KARTÁCH")
            HStack(spacing: 8) {
                toggleChip("Cena", isOn: $fantasy.showPriceOnPitch)
                toggleChip("Body", isOn: $fantasy.showPointsOnPitch)
                toggleChip("Soupeř", isOn: $fantasy.showOpponentOnPitch)
            }
        }
    }

    /// Přepínač jednoho údaje na kartě.
    private func toggleChip(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.hbMontserrat(size: 13, weight: .semibold))
            }
            .foregroundStyle(isOn.wrappedValue ? HBTheme.onBrand : HBTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isOn.wrappedValue ? AnyShapeStyle(HBTheme.brand) : AnyShapeStyle(HBTheme.card),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isOn.wrappedValue ? Color.clear : HBTheme.cardStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Data

    /// Shows a short toast message.
    private func showToast(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }

    /// Loads players and matches, syncs the gameweek and settles finished rounds.
    private func loadData() async {
        // Player attributes drive the rating: generated in mock mode, fetched otherwise.
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
        // Seed mock attributes before sorting so the order matches the cards.
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

        // Gameweek calendar → server squads/scores → settle closed weeks → leaderboard.
        fantasy.syncGameweekIfNeeded()
        await fantasy.loadRemote()
        let gained = fantasy.scorePendingGameweeks(playersById: playersById, matches: matches)
        if gained > 0 {
            showToast("Vyhodnoceno kolo · +\(gained) b")
        }
        await fantasy.loadLeaderboard()
    }
}

// MARK: - Řádek zápasu

private struct FantasyFixtureRow: View {
    @EnvironmentObject private var catalog: CatalogStore
    let match: Match

    private var timeLabel: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.timeZone = FantasyDeadline.prague
        df.dateFormat = "E d. M. HH:mm"
        return df.string(from: match.scheduledAt)
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                if let home = catalog.team(match.homeTeamId) {
                    TeamBadge(team: home, size: 22)
                }
                Text(catalog.team(match.homeTeamId)?.shortName ?? "—")
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(timeLabel)
                .font(.hbNumber(size: 10, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(HBTheme.cardInset, in: Capsule())

            HStack(spacing: 8) {
                Text(catalog.team(match.awayTeamId)?.shortName ?? "—")
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
                if let away = catalog.team(match.awayTeamId) {
                    TeamBadge(team: away, size: 22)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Můj tým

/// Slot se svým hráčem — podklad pro akční menu nad kartou.
private struct FantasySlotSelection: Identifiable {
    let slot: FantasySlot
    let player: Player
    var id: String { slot.rawValue + player.id }
}

struct FantasyMyTeamView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var fantasy: FantasySquadStore
    @Binding var players: [Player]
    var matches: [Match]

    @State private var pickingSlot: FantasySlot?
    @State private var inspectingPlayer: Player?
    @State private var actionTarget: FantasySlotSelection?
    @State private var errorMessage: String?
    @State private var toast: String?

    private var playersById: [String: Player] {
        Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
    }

    private var spentCredits: Int { fantasy.spentCredits(playersById: playersById) }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 14) {
                    if !fantasy.isViewingEditable {
                        Text("Prohlížíš jiné kolo — sestava je jen ke čtení.")
                            .font(.hbMontserrat(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    identityCard
                    statsRow

                    FantasyHockeyRink(
                        playersById: playersById,
                        matches: matches,
                        cardSize: .regular,
                        interactive: true,
                        onSelectSlot: { pickingSlot = $0 },
                        onSelectPlayer: { slot, player in
                            actionTarget = FantasySlotSelection(slot: slot, player: player)
                        }
                    )

                    Text(fantasy.isViewingEditable
                         ? "Klepni na prázdný slot a vyber hráče. Klepnutím na kartu otevřeš detail, výměnu nebo odebrání."
                         : "Minulé kolo — změny nejsou povolené.")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Color.clear.frame(height: 100)
                }
                .padding(HBTheme.screenPadding)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.13, blue: 0.17),
                        Color(red: 0.04, green: 0.06, blue: 0.09)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            FantasySaveBar(onSave: saveSquad)
        }
        .navigationTitle("Můj tým")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hbNavigationStyle()
        .toolbar {
            if fantasy.isViewingEditable && fantasy.filledCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Vymazat", role: .destructive) { fantasy.clearAll() }
                        .font(.hbMontserrat(size: 14, weight: .semibold))
                }
            }
        }
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
        .confirmationDialog(
            actionTarget?.player.fullName ?? "",
            isPresented: Binding(
                get: { actionTarget != nil },
                set: { if !$0 { actionTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: actionTarget
        ) { target in
            Button("Detail hráče") {
                showAfterDismiss { inspectingPlayer = target.player }
            }
            if fantasy.isViewingEditable {
                Button("Vyměnit hráče") {
                    showAfterDismiss { pickingSlot = target.slot }
                }
                Button("Odebrat ze sestavy", role: .destructive) {
                    fantasy.clear(slot: target.slot)
                    flash("\(target.player.lastName) odebrán ze sestavy")
                }
            }
            Button("Zrušit", role: .cancel) {}
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
                        showAfterDismiss { pickingSlot = slot }
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

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Název týmu", text: $fantasy.teamName)
                    .font(.hbMontserrat(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .disabled(!fantasy.isViewingEditable)
                if fantasy.isViewingEditable {
                    Text("upravit")
                        .font(.hbMontserrat(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }

            HStack {
                Text("ROZPOČET")
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Spacer()
                Text("\(spentCredits) / \(FantasyRules.budgetCredits) kr")
                    .font(.hbNumber(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            FantasyBudgetBar(spent: spentCredits, budget: FantasyRules.budgetCredits)
        }
        .padding(14)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            FantasyStatCell(label: "SESTAVA", value: "\(fantasy.filledCount)/\(FantasyRules.squadSize)")
            FantasyStatCell(
                label: "ZBÝVÁ",
                value: "\(fantasy.remainingBudget(playersById: playersById))",
                hint: "kreditů"
            )
            FantasyStatCell(label: "BODY", value: "\(fantasy.seasonPoints)", hint: "sezóna")
            FantasyStatCell(
                label: "SÍLA",
                value: "\(fantasy.squadPoints(playersById: playersById))",
                hint: "sestava"
            )
        }
    }

    /// Uloží sestavu a výsledek ohlásí toastem.
    private func saveSquad() {
        if let error = fantasy.saveLineup() {
            flash(error)
        } else {
            flash(fantasy.lastSaveMessage ?? "Uloženo")
        }
    }

    /// Krátká hláška v horní části obrazovky.
    private func flash(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }

    /// Spustí akci až po zavření dialogu, jinak se sheet neotevře.
    private func showAfterDismiss(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: action)
    }
}

// MARK: - Hřiště

struct FantasyHockeyRink: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var fantasy: FantasySquadStore

    let playersById: [String: Player]
    var matches: [Match] = []
    var cardSize: FantasyCardSize = .regular
    var interactive: Bool = true
    var onSelectSlot: ((FantasySlot) -> Void)? = nil
    var onSelectPlayer: ((FantasySlot, Player) -> Void)? = nil

    private static let lines: [(label: String, slots: [FantasySlot])] = [
        ("BRANKÁŘ", [.goalie]),
        ("OBRANA", [.defense1, .defense2]),
        ("ÚTOK", [.forward1, .forward2, .forward3])
    ]

    var body: some View {
        ZStack {
            rinkBackground
            VStack(spacing: cardSize == .compact ? 10 : 12) {
                ForEach(Array(Self.lines.enumerated()), id: \.element.label) { index, line in
                    if index > 0 { rinkDivider }
                    lineLabel(line.label)
                    slotRow(line.slots)
                }
            }
            .padding(.vertical, cardSize == .compact ? 12 : 16)
            .padding(.horizontal, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    private var rinkBackground: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.36, blue: 0.50),
                        Color(red: 0.08, green: 0.23, blue: 0.32),
                        Color(red: 0.05, green: 0.16, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .strokeBorder(Color.white.opacity(0.13), lineWidth: 1.5)
                    .frame(width: 128, height: 128)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                ForEach(faceoffSpots(in: geo.size), id: \.self) { spot in
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
                        .frame(width: 54, height: 54)
                        .position(spot)
                }
            }
        }
    }

    /// Vhazovací kruhy v rozích hřiště.
    private func faceoffSpots(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: size.width * 0.14, y: size.height * 0.16),
            CGPoint(x: size.width * 0.86, y: size.height * 0.16),
            CGPoint(x: size.width * 0.14, y: size.height * 0.86),
            CGPoint(x: size.width * 0.86, y: size.height * 0.86)
        ]
    }

    /// Modrá čára mezi řadami sestavy.
    private var rinkDivider: some View {
        LinearGradient(
            colors: [
                .clear,
                Color(red: 0.55, green: 0.78, blue: 0.92).opacity(0.45),
                Color(red: 0.55, green: 0.78, blue: 0.92).opacity(0.45),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 2)
        .clipShape(Capsule())
        .padding(.horizontal, 16)
    }

    /// Popisek řady sestavy (brankář / obrana / útok).
    private func lineLabel(_ text: String) -> some View {
        Text(text)
            .font(.hbMontserrat(size: 9, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(Color.white.opacity(0.5))
    }

    /// Jedna řada slotů sestavy.
    private func slotRow(_ slots: [FantasySlot]) -> some View {
        HStack(spacing: cardSize == .compact ? 8 : 10) {
            ForEach(slots) { slot in
                let player = fantasy.playerId(for: slot).flatMap { playersById[$0] }

                if let player {
                    FantasyPlayerCard(
                        player: player,
                        team: catalog.team(player.teamId),
                        size: cardSize,
                        showsPrice: fantasy.showPriceOnPitch,
                        showsPoints: fantasy.showPointsOnPitch,
                        opponentLabel: fantasy.showOpponentOnPitch ? opponentCaption(for: player) : nil
                    )
                    .contentShape(RoundedRectangle(cornerRadius: cardSize.corner, style: .continuous))
                    .onTapGesture {
                        guard interactive else { return }
                        onSelectPlayer?(slot, player)
                    }
                } else {
                    FantasyPlayerCard(
                        player: Player.fantasyPlaceholder(for: slot),
                        size: cardSize,
                        isEmpty: true,
                        emptyTitle: fantasy.isViewingEditable ? "Přidat" : "Prázdné",
                        emptyPosition: slot.shortTitle
                    )
                    .contentShape(RoundedRectangle(cornerRadius: cardSize.corner, style: .continuous))
                    .onTapGesture {
                        guard interactive, fantasy.isViewingEditable else { return }
                        onSelectSlot?(slot)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Krátký popisek příštího soupeře na kartě.
    private func opponentCaption(for player: Player) -> String? {
        guard let match = FantasyRules.nextFixture(for: player.teamId, in: matches) else { return nil }
        let isHome = match.homeTeamId == player.teamId
        let oppId = isHome ? match.awayTeamId : match.homeTeamId
        let name = catalog.team(oppId)?.shortName ?? "?"
        return "\(isHome ? "vs" : "@") \(name)"
    }
}

extension Player {
    /// Prázdná figurína pro nevyplněný slot sestavy.
    static func fantasyPlaceholder(for slot: FantasySlot) -> Player {
        Player(
            id: "empty-\(slot.rawValue)",
            firstName: "",
            lastName: "",
            number: 0,
            position: slot.position,
            teamId: "",
            games: 0, goals: 0, assists: 0, points: 0, penaltyMinutes: 0,
            savePercentage: nil, goalsAgainstAverage: nil
        )
    }
}

// MARK: - Trh

struct FantasyMarketView: View {
    @EnvironmentObject private var fantasy: FantasySquadStore
    let players: [Player]
    let matches: [Match]

    var body: some View {
        FantasyPlayerPickerContent(
            slot: .forward1,
            players: players,
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
    }
}

// MARK: - Žebříček

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
        // Server leaderboard when available; otherwise the local demo with bots.
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

    /// Pořadí na stupních vítězů: 2. vlevo, 1. uprostřed, 3. vpravo.
    private var podium: [Row] {
        let top = Array(rows.prefix(3))
        guard top.count == 3 else { return top }
        return [top[1], top[0], top[2]]
    }

    private let podiumHeights: [CGFloat] = [58, 78, 46]
    private let podiumColors: [Color] = [
        Color(red: 0.72, green: 0.74, blue: 0.78),
        Color(red: 0.95, green: 0.78, blue: 0.28),
        Color(red: 0.79, green: 0.54, blue: 0.29)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                podiumBlock
                listBlock
            }
        }
        .background(HBTheme.canvas)
        .navigationTitle("Žebříček")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task { await fantasy.loadLeaderboard() }
    }

    private var podiumBlock: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(podium.enumerated()), id: \.element.id) { index, row in
                VStack(spacing: 8) {
                    Text("\(row.rank)")
                        .font(.hbNumber(size: 13, weight: .heavy))
                        .foregroundStyle(HBTheme.ink)
                        .frame(width: 32, height: 32)
                        .background(podiumColors[index], in: Circle())
                    Text(row.name)
                        .font(.hbMontserrat(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text("\(row.points)")
                        .font(.hbNumber(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .frame(height: podiumHeights[index], alignment: .top)
                        .background(
                            LinearGradient(
                                colors: [podiumColors[index].opacity(0.7), podiumColors[index].opacity(0.25)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                        )
                }
                .frame(width: 92)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.14, blue: 0.19), Color(red: 0.07, green: 0.09, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var listBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(HBTheme.separator.opacity(0.45))
                            .frame(height: 0.5)
                    }
                    HStack(spacing: 12) {
                        Text("\(row.rank)")
                            .font(.hbNumber(size: 16, weight: .heavy))
                            .foregroundStyle(row.isMe ? HBTheme.brand : HBTheme.textSecondary)
                            .frame(width: 26, alignment: .leading)
                        Text(row.name)
                            .font(.hbMontserrat(size: 15, weight: row.isMe ? .bold : .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .lineLimit(1)
                        if row.isMe {
                            Text("TY")
                                .font(.hbMontserrat(size: 9, weight: .bold))
                                .foregroundStyle(HBTheme.onBrand)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HBTheme.brand, in: Capsule())
                        }
                        Spacer(minLength: 8)
                        Text("\(row.points) b")
                            .font(.hbNumber(size: 15, weight: .bold))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(row.isMe ? HBTheme.brand.opacity(0.08) : Color.clear)
                }
            }
            .hbCard(cornerRadius: HBTheme.radiusMd)

            if fantasy.remoteLeaderboard.isEmpty {
                Text("Zatím lokální demo — po prvním vyhodnocení kola se objeví reálné pořadí všech hráčů.")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(HBTheme.screenPadding)
    }
}

// MARK: - Pravidla

struct FantasyRulesScreen: View {
    private var rules: [(badge: String, title: String, text: String)] {
        [
            ("1B·2O·3Ú", "Týdenní sestava", "Každé kolo máš vlastní sestavu — 1 brankář, 2 obránci a 3 útočníci."),
            ("SO 10:00", "Deadline", "Uzávěrka je vždy v sobotu v 10:00 (Praha). Poté je sestava zamčená a hraje tak, jak jsi ji uložil."),
            ("\(FantasyRules.budgetCredits) kr", "Rozpočet", "Cena hráče je 4–15 kreditů podle jeho OVR. Nesmíš rozpočet překročit."),
            ("MAX \(FantasyRules.maxFromSameClub)", "Kluby", "Z jednoho klubu můžeš mít nejvýš dva hráče."),
            ("OVR", "Rating", "OVR vychází z parametrů hráče (rychlost, síla, střela…). Když parametry chybí, spočítá se ze statistik."),
            ("3 · 2", "Body", "Gól 3 body, asistence 2 body, brankáři bonusy za výhru a čisté konto. Sčítají se po uzávěrce kola."),
            ("ULOŽIT", "Nezapomeň uložit", "Bez uložení sestavy se kolo nezapočítá do žebříčku.")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(rules, id: \.title) { rule in
                    HStack(alignment: .top, spacing: 12) {
                        Text(rule.badge)
                            .font(.hbMontserrat(size: 10, weight: .heavy))
                            .foregroundStyle(HBTheme.brand)
                            .multilineTextAlignment(.center)
                            .frame(width: 54, height: 38)
                            .background(HBTheme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.title)
                                .font(.hbMontserrat(size: 15, weight: .bold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text(rule.text)
                                .font(.hbMontserrat(size: 13, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
                }
            }
            .padding(HBTheme.screenPadding)
        }
        .background(HBTheme.canvas)
        .navigationTitle("Pravidla")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
    }
}

// MARK: - Výběr hráče

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
            .navigationTitle(marketMode ? "Hráčský trh" : slot.title)
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
    @EnvironmentObject private var fantasy: FantasySquadStore

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
    @State private var affordableOnly = false
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
                    || (catalog.team($0.teamId)?.name.lowercased().contains(q) ?? false)
            }
        }
        if let clubFilter { list = list.filter { $0.teamId == clubFilter } }
        if affordableOnly {
            list = list.filter { FantasyRules.priceCredits(for: $0) <= remainingBudget || selectedIds.contains($0.id) }
        }
        switch sort {
        case .rating: list.sort { FantasyRules.rating(for: $0) > FantasyRules.rating(for: $1) }
        case .price: list.sort { FantasyRules.priceCredits(for: $0) > FantasyRules.priceCredits(for: $1) }
        case .points: list.sort { FantasyRules.fantasyPoints(for: $0) > FantasyRules.fantasyPoints(for: $1) }
        case .name: list.sort { $0.lastName < $1.lastName }
        }
        return list
    }

    /// Skloňování počtu nalezených hráčů.
    private func playerCountLabel(_ count: Int) -> String {
        switch count {
        case 1: return "1 hráč"
        case 2...4: return "\(count) hráči"
        default: return "\(count) hráčů"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            ScrollView {
                LazyVStack(spacing: 10) {
                    if !fantasy.isViewingEditable {
                        Text("Prohlížíš jiné kolo — hráče teď nejde přidávat.")
                            .font(.hbMontserrat(size: 12, weight: .semibold))
                            .foregroundStyle(HBTheme.textSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    ForEach(filtered) { player in
                        playerRow(player)
                    }

                    if filtered.isEmpty {
                        VStack(spacing: 6) {
                            Text("Žádní hráči")
                                .font(.hbMontserrat(size: 15, weight: .semibold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text("Zkus jiný filtr, klub nebo hledaný výraz.")
                                .font(.hbMontserrat(size: 13, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    }
                }
                .padding(HBTheme.screenPadding)
                .padding(.bottom, 24)
            }
        }
        .background(HBTheme.canvas)
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

    // MARK: Filtry

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
                TextField("Hledat hráče nebo klub", text: $query)
                    .font(.hbMontserrat(size: 14, weight: .regular))
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button("Zrušit") { query = "" }
                        .font(.hbMontserrat(size: 13, weight: .bold))
                        .foregroundStyle(HBTheme.brand)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack {
                if marketMode {
                    Text("Extraliga")
                        .font(.hbMontserrat(size: 12, weight: .bold))
                        .foregroundStyle(HBTheme.textSecondary)
                } else {
                    HStack(spacing: 4) {
                        Text("Na tento slot zbývá")
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(HBTheme.textSecondary)
                        Text("\(remainingBudget) kr")
                            .font(.hbNumber(size: 12, weight: .heavy))
                            .foregroundStyle(HBTheme.textPrimary)
                    }
                }
                Spacer()
                Text(playerCountLabel(filtered.count))
                    .font(.hbMontserrat(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }

            segmentedSort

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !marketMode {
                        chip("V rozpočtu", selected: affordableOnly) { affordableOnly.toggle() }
                    }
                    chip("Všechny kluby", selected: clubFilter == nil) { clubFilter = nil }
                    ForEach(clubs) { team in
                        chip(team.shortName, selected: clubFilter == team.id) { clubFilter = team.id }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .background(HBTheme.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HBTheme.separator.opacity(0.4))
                .frame(height: 0.5)
        }
    }

    private var segmentedSort: some View {
        HStack(spacing: 2) {
            ForEach(FantasyPickerSort.allCases) { option in
                Button {
                    sort = option
                } label: {
                    Text(option.label)
                        .font(.hbMontserrat(size: 12, weight: .bold))
                        .foregroundStyle(sort == option ? HBTheme.brand : HBTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if sort == option {
                                Capsule()
                                    .fill(HBTheme.card)
                                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(HBTheme.cardInset, in: Capsule())
    }

    /// Filtrační chip v trhu.
    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.hbMontserrat(size: 12, weight: .semibold))
                .foregroundStyle(selected ? HBTheme.onBrand : HBTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? AnyShapeStyle(HBTheme.brand) : AnyShapeStyle(HBTheme.card), in: Capsule())
                .overlay {
                    if !selected {
                        Capsule().strokeBorder(HBTheme.cardStroke, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Řádek hráče

    /// Jeden hráč v trhu — karta, údaje a tlačítko pro přidání.
    private func playerRow(_ player: Player) -> some View {
        let taken = selectedIds.contains(player.id)
        let price = FantasyRules.priceCredits(for: player)
        let affordable = price <= remainingBudget || taken
        let rating = FantasyRules.rating(for: player)
        let form = TeamFormCalculator.items(from: matches, teamId: player.teamId, limit: 4)

        return HStack(spacing: 12) {
            Button { scoutPlayer = player } label: {
                FantasyPlayerCard(
                    player: player,
                    team: catalog.team(player.teamId),
                    size: .compact,
                    showsPrice: false
                )
            }
            .buttonStyle(.plain)

            Button { scoutPlayer = player } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(player.fullName)
                        .font(.hbMontserrat(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .lineLimit(1)
                    Text("\(catalog.team(player.teamId)?.shortName ?? "Tým") · \(player.position.label)")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        meta("OVR \(rating)")
                        meta("\(FantasyRules.fantasyPoints(for: player)) b")
                        FantasyTierChip(tier: FantasyRules.tier(for: rating))
                    }
                    HStack(spacing: 8) {
                        TeamFormBadges(items: form, size: 16)
                        if let caption = fixtureCaption(for: player) {
                            Text(caption)
                                .font(.hbMontserrat(size: 10, weight: .semibold))
                                .foregroundStyle(HBTheme.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text("\(price)")
                    .font(.hbNumber(size: 15, weight: .heavy))
                    .foregroundStyle(affordable ? HBTheme.textPrimary : HBTheme.loss)
                Text("KREDITŮ")
                    .font(.hbMontserrat(size: 9, weight: .bold))
                    .foregroundStyle(HBTheme.textTertiary)
                Button { onSelect(player) } label: {
                    Image(systemName: taken ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(taken ? HBTheme.win : HBTheme.brand, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!fantasy.isViewingEditable || (!affordable && !taken))
                .opacity(!fantasy.isViewingEditable || (!affordable && !taken) ? 0.3 : 1)
                .padding(.top, 2)
            }
            .frame(width: 62)
        }
        .padding(10)
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .opacity(affordable || taken || marketMode ? 1 : 0.5)
    }

    /// Krátký popisek příštího zápasu (soupeř + datum).
    private func fixtureCaption(for player: Player) -> String? {
        guard let match = FantasyRules.nextFixture(for: player.teamId, in: matches) else { return nil }
        let isHome = match.homeTeamId == player.teamId
        let opp = catalog.team(isHome ? match.awayTeamId : match.homeTeamId)?.shortName ?? "?"
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.dateFormat = "E d.M."
        return "\(isHome ? "vs" : "@") \(opp) · \(df.string(from: match.scheduledAt))"
    }

    /// Malá pilulka s hodnotou.
    private func meta(_ text: String) -> some View {
        Text(text)
            .font(.hbMontserrat(size: 10, weight: .bold))
            .foregroundStyle(HBTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
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
    /// Attribute rows to render, empty when the player has none.
    private var attributeRows: [(label: String, value: Int)] {
        attributes.attributes(for: player.id)?.displayRows(position: player.position) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    VStack(spacing: 18) {
                        statsRow
                        attributesCard
                        formCard
                        fixtureCard

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

    private var header: some View {
        VStack(spacing: 12) {
            FantasyPlayerCard(player: player, team: team, size: .large, showsPrice: true, showsPoints: true)
            VStack(spacing: 4) {
                Text(player.fullName)
                    .font(.hbMontserrat(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(team?.shortName ?? "Tým") · \(player.position.label) · #\(player.number)")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            FantasyTierChip(tier: tier)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.14, blue: 0.19), Color(red: 0.07, green: 0.09, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            scoutStat("OVR", "\(rating)")
            scoutStat("CENA", "\(FantasyRules.priceCredits(for: player)) kr")
            scoutStat("ZÁPASY", "\(player.games)")
            scoutStat("FPTS", "\(FantasyRules.fantasyPoints(for: player))")
        }
    }

    @ViewBuilder
    private var attributesCard: some View {
        if !attributeRows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                FantasySectionLabel(text: "PARAMETRY")
                ForEach(attributeRows, id: \.label) { row in
                    HStack(spacing: 10) {
                        Text(row.label)
                            .font(.hbMontserrat(size: 12, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .frame(width: 78, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(HBTheme.cardInset)
                                Capsule()
                                    .fill(row.value >= 90 ? HBTheme.win : HBTheme.brand)
                                    .frame(width: geo.size.width * (Double(row.value) / 99.0))
                            }
                        }
                        .frame(height: 6)
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
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            FantasySectionLabel(text: "FORMA KLUBU")
            HStack {
                if let team {
                    TeamBadge(team: team, size: 28)
                    Text(team.shortName)
                        .font(.hbMontserrat(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                }
                Spacer()
                TeamFormBadges(items: form, size: 22)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private var fixtureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            FantasySectionLabel(text: "PŘÍŠTÍ ZÁPAS")
            if let fixture, let team {
                let isHome = fixture.homeTeamId == team.id
                let opp = catalog.team(isHome ? fixture.awayTeamId : fixture.homeTeamId)
                HStack(spacing: 12) {
                    if let opp { TeamBadge(team: opp, size: 36) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isHome ? "Doma vs \(opp?.shortName ?? "soupeř")" : "Venku @ \(opp?.shortName ?? "soupeř")")
                            .font(.hbMontserrat(size: 16, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                        Text(fixtureDate(fixture.scheduledAt))
                            .font(.hbMontserrat(size: 13, weight: .medium))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                    Spacer()
                }
            } else {
                Text("Žádný nadcházející zápas.")
                    .font(.hbMontserrat(size: 14, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    /// Stat tile in the scout sheet.
    private func scoutStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .foregroundStyle(HBTheme.textTertiary)
            Text(value)
                .font(.hbNumber(size: 15, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// Formats the fixture date for the scout sheet.
    private func fixtureDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.timeZone = FantasyDeadline.prague
        df.dateFormat = "EEEE d. M. yyyy · HH:mm"
        return df.string(from: date)
    }
}

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var notifications: NotificationSettingsStore
    @EnvironmentObject private var appearanceStore: AppearanceStore
    @EnvironmentObject private var homeMatchFeed: HomeMatchFeedStore

    var body: some View {
        Form {
            Section {
                Picker("Vzhled", selection: $appearanceStore.appearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            } header: {
                Text("Zobrazení")
            } footer: {
                Text("Tmavý režim přizpůsobí barvy celé aplikace. Volba Podle systému sleduje nastavení iOS.")
            }

            Section {
                NavigationLink {
                    CompetitionOrderSettingsView()
                } label: {
                    Label("Pořadí soutěží", systemImage: "arrow.up.arrow.down")
                }

                NavigationLink {
                    HomeMatchFeedSettingsView()
                } label: {
                    HStack {
                        Label("Zápasy na Domů", systemImage: "sportscourt")
                        Spacer(minLength: 8)
                        Text(homeMatchFeed.selectionSummary)
                            .font(.hbMontserrat(size: 13, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            } header: {
                Text("Soutěže a Domů")
            } footer: {
                Text("Pořadí platí v Zápasech, LIVE i Oblíbených. Zápasy na Domů řídí, které soutěže a týmy uvidíte ve slideru.")
            }

            Section {
                Picker("Zdroj dat", selection: $apiClient.source) {
                    ForEach(DataSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                Text(apiClient.source == .supabase
                     ? "Data běží ze Supabase projektu Hokejbal (sezóny, historie)."
                     : "Lokální mock data — offline režim.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Aplikace je volně přístupná – bez registrace a přihlášení.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("API")
            }

            Section {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    HStack {
                        Label("Notifikace", systemImage: "bell.badge.fill")
                        Spacer(minLength: 8)
                        Text(notifications.activeLiveTypesSummary)
                            .font(.hbMontserrat(size: 13, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            } header: {
                Text("Upozornění")
            } footer: {
                Text("Góly, konce zápasů a další upozornění. In-app bannery fungují i bez systémového povolení.")
            }

            Section("O aplikaci") {
                LabeledContent("Verze", value: appVersionLabel)
                LabeledContent("Design", value: "hokejbal.cz · iOS")
                Link("hokejbal.cz", destination: URL(string: "https://www.hokejbal.cz")!)
            }
        }
        .navigationTitle("Nastavení")
        .hbNavigationStyle()
        .task { await notifications.refreshAuthorization() }
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

// MARK: - Notifikace

struct NotificationSettingsView: View {
    @EnvironmentObject private var notifications: NotificationSettingsStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            Section {
                permissionCard
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)

            Section {
                notificationToggle(
                    title: "Góly",
                    subtitle: "Banner nahoře v appce i systémové upozornění při gólu",
                    icon: "circle.fill",
                    iconColor: HBTheme.live,
                    isOn: $notifications.goalsEnabled
                )
                notificationToggle(
                    title: "Konečný výsledek",
                    subtitle: "Upozornění po skončení sledovaného zápasu",
                    icon: "flag.checkered",
                    iconColor: HBTheme.brand,
                    isOn: $notifications.finalScoreEnabled
                )
                notificationToggle(
                    title: "Začátek zápasu",
                    subtitle: "Připomenutí před výkopem",
                    icon: "clock.fill",
                    iconColor: HBTheme.inkSoft,
                    isOn: $notifications.matchStartEnabled
                )
            } header: {
                Text("Živé zápasy")
            } footer: {
                Text("Zvonek v detailu zápasu umí konkrétní utkání ztlumit. V otevřeném detailu zápasu upozornění z něj nedostaneš.")
            }

            Section {
                Toggle(isOn: $notifications.onlyFavorites) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Jen oblíbené")
                            .font(.hbMontserrat(size: 16, weight: .semibold))
                        Text(notifications.onlyFavorites
                             ? "Upozornění jen u oblíbených týmů a zápasů"
                             : "Upozornění u všech zápasů (kromě ztlumených)")
                            .font(.hbMontserrat(size: 12, weight: .medium))
                            .foregroundStyle(HBTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(HBTheme.brand)
            } header: {
                Text("Rozsah")
            } footer: {
                Text("Oblíbené nastavíš hvězdičkou u týmu nebo zápasu. Ztlumení zvonkem má vždy přednost.")
            }

            Section {
                notificationToggle(
                    title: "Novinky",
                    subtitle: "Články a důležitá oznámení ze světa hokejbalu",
                    icon: "newspaper.fill",
                    iconColor: Color(red: 0.25, green: 0.45, blue: 0.78),
                    isOn: $notifications.newsEnabled
                )
            } header: {
                Text("Obsah")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifikace")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .task { await notifications.refreshAuthorization() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await notifications.refreshAuthorization() }
            }
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(statusTint.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: statusIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(statusTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Systémová upozornění")
                        .font(.hbMontserrat(size: 13, weight: .semibold))
                        .foregroundStyle(HBTheme.textSecondary)
                    Text(notifications.systemStatusTitle)
                        .font(.hbMontserrat(size: 20, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                }

                Spacer(minLength: 0)
            }

            Text(notifications.systemStatusDetail)
                .font(.hbMontserrat(size: 13, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !notifications.isSystemAuthorized {
                Button {
                    Task {
                        if notifications.authorizationStatus == .denied {
                            notifications.openSystemSettings()
                        } else {
                            _ = await notifications.requestPermission()
                        }
                    }
                } label: {
                    Text(notifications.authorizationStatus == .denied
                          ? "Otevřít Nastavení iOS"
                          : "Povolit notifikace")
                        .font(.hbMontserrat(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HBTheme.brandGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HBTheme.card, in: RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous)
                .strokeBorder(HBTheme.cardStroke, lineWidth: 0.75)
        )
    }

    private var statusTint: Color {
        notifications.isSystemAuthorized ? HBTheme.win : (notifications.authorizationStatus == .denied ? HBTheme.loss : HBTheme.brand)
    }

    private var statusIcon: String {
        if notifications.isSystemAuthorized { return "bell.badge.fill" }
        if notifications.authorizationStatus == .denied { return "bell.slash.fill" }
        return "bell.fill"
    }

    private func notificationToggle(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.hbMontserrat(size: 16, weight: .semibold))
                        .foregroundStyle(HBTheme.textPrimary)
                    Text(subtitle)
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 2)
        }
        .tint(HBTheme.brand)
    }
}

/// Drag-and-drop pořadí soutěží.
struct CompetitionOrderSettingsView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore

    @State private var rows: [Competition] = []

    var body: some View {
        List {
            if rows.isEmpty {
                Text("Zatím nemáme načtené soutěže.")
                    .foregroundStyle(HBTheme.textSecondary)
            } else {
                ForEach(rows) { competition in
                    HStack(spacing: 12) {
                        CompetitionBadge(competition: competition, size: 32)
                        Text(competition.name)
                            .font(.hbMontserrat(size: 15, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: move)
            }
        }
        .environment(\.editMode, .constant(.active))
        .listStyle(.insetGrouped)
        .navigationTitle("Pořadí soutěží")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .onAppear { reloadRows() }
        .onChange(of: catalog.competitions) { _, _ in reloadRows() }
        .onChange(of: competitionOrder.orderedSlugs) { _, _ in
            // Po sync z katalogu srovnej UI, pokud uživatel právě nepřetahuje.
            if rows.map(\.slug) != competitionOrder.orderedSlugs {
                reloadRows()
            }
        }
    }

    private func reloadRows() {
        competitionOrder.sync(with: catalog.competitions)
        rows = competitionOrder.sortedCompetitions(catalog.competitions)
    }

    private func move(from source: IndexSet, to destination: Int) {
        rows.move(fromOffsets: source, toOffset: destination)
        competitionOrder.setOrder(rows.map(\.slug))
    }
}

/// Výběr soutěží a týmů pro slider Zápasů na Domů.
struct HomeMatchFeedSettingsView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @EnvironmentObject private var homeMatchFeed: HomeMatchFeedStore

    @State private var teamQuery = ""

    private var competitions: [Competition] {
        competitionOrder.sortedCompetitions(catalog.competitions)
    }

    private var teams: [Team] {
        let all = catalog.teamsById.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        let q = teamQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(q)
                || $0.shortName.localizedCaseInsensitiveContains(q)
                || $0.city.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Slider Zápasů na Domů")
                        .font(.hbMontserrat(size: 16, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                    Text("Zvolte soutěže a/nebo konkrétní týmy. Zápas se zobrazí, pokud patří do vybrané soutěže nebo v něm hraje vybraný tým.")
                        .font(.hbMontserrat(size: 13, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .listRowBackground(HBTheme.cardInset)
            }

            Section {
                if homeMatchFeed.hasSelection {
                    if !homeMatchFeed.competitionSlugs.isEmpty {
                        selectedCompetitionChips
                    }
                    if !homeMatchFeed.teamIDs.isEmpty {
                        selectedTeamChips
                    }
                    Button("Vymazat výběr", role: .destructive) {
                        homeMatchFeed.clearAll()
                    }
                } else {
                    Text("Zatím nic nevybráno — slider na Domů bude prázdný.")
                        .font(.hbMontserrat(size: 13, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                }
            } header: {
                Text("Aktuální výběr")
            }

            Section {
                if competitions.isEmpty {
                    Text("Soutěže se ještě načítají…")
                        .foregroundStyle(HBTheme.textSecondary)
                } else {
                    HStack {
                        Button("Vybrat vše") { homeMatchFeed.selectAllCompetitions(competitions) }
                            .font(.hbMontserrat(size: 13, weight: .bold))
                        Spacer()
                        Button("Zrušit") { homeMatchFeed.clearCompetitions() }
                            .font(.hbMontserrat(size: 13, weight: .semibold))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                    .buttonStyle(.plain)

                    ForEach(competitions) { competition in
                        Button {
                            homeMatchFeed.toggleCompetition(competition)
                        } label: {
                            HStack(spacing: 12) {
                                CompetitionBadge(competition: competition, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(competition.name)
                                        .font(.hbMontserrat(size: 15, weight: .semibold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Text(competition.shortName)
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textTertiary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: homeMatchFeed.isCompetitionSelected(competition) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(homeMatchFeed.isCompetitionSelected(competition) ? HBTheme.brand : HBTheme.textTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Soutěže")
            } footer: {
                Text("Celá soutěž ve slideru — všechny její zápasy.")
            }

            Section {
                if catalog.teamsById.isEmpty {
                    Text("Týmy se ještě načítají…")
                        .foregroundStyle(HBTheme.textSecondary)
                } else {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(HBTheme.textTertiary)
                        TextField("Hledat tým", text: $teamQuery)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !teamQuery.isEmpty {
                            Button {
                                teamQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(HBTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ForEach(teams) { team in
                        Button {
                            homeMatchFeed.toggleTeam(team.id)
                        } label: {
                            HStack(spacing: 12) {
                                TeamBadge(team: team, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.hbMontserrat(size: 15, weight: .semibold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                        .lineLimit(1)
                                    Text(team.city.isEmpty ? team.shortName : team.city)
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textTertiary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: homeMatchFeed.isTeamSelected(team.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(homeMatchFeed.isTeamSelected(team.id) ? HBTheme.brand : HBTheme.textTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Týmy")
            } footer: {
                Text("Konkrétní klub — jeho zápasy i napříč soutěžemi.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Zápasy na Domů")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .onAppear {
            homeMatchFeed.seedDefaultsIfNeeded(competitions: catalog.competitions)
        }
    }

    private var selectedCompetitionChips: some View {
        let selected = competitions.filter { homeMatchFeed.isCompetitionSelected($0) }
        return FlowSelectionRow(title: "Soutěže") {
            ForEach(selected) { competition in
                selectionChip(title: competition.shortName) {
                    homeMatchFeed.toggleCompetition(competition)
                }
            }
        }
    }

    private var selectedTeamChips: some View {
        let selected = catalog.teamsById.values
            .filter { homeMatchFeed.isTeamSelected($0.id) }
            .sorted { $0.shortName < $1.shortName }
        return FlowSelectionRow(title: "Týmy") {
            ForEach(selected) { team in
                selectionChip(title: team.shortName) {
                    homeMatchFeed.toggleTeam(team.id)
                }
            }
        }
    }

    private func selectionChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.hbMontserrat(size: 12, weight: .bold))
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(HBTheme.brand)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(HBTheme.brand.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FlowSelectionRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.hbMontserrat(size: 12, weight: .bold))
                .foregroundStyle(HBTheme.textTertiary)
            WrappingHStack(spacing: 8, content: content)
        }
        .padding(.vertical, 4)
    }
}

/// Jednoduchý wrapping layout pro chips.
private struct WrappingHStack<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        FlexibleView(spacing: spacing, content: content)
    }
}

private struct FlexibleView<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        // Fallback: horizontální scroll chips — spolehlivější než vlastní flow layout.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content()
            }
        }
    }
}

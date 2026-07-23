import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var notifications: NotificationSettingsStore
    @EnvironmentObject private var appearanceStore: AppearanceStore

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
            } header: {
                Text("Soutěže")
            } footer: {
                Text("Přetažením nastavíte pořadí soutěží v Zápasech, LIVE i Oblíbených.")
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
                statusRow
                Toggle("Góly", isOn: $notifications.goalsEnabled)
                Toggle("Začátek zápasu", isOn: $notifications.matchStartEnabled)
                Toggle("Konečný výsledek", isOn: $notifications.finalScoreEnabled)
                Toggle("Novinky", isOn: $notifications.newsEnabled)
                Toggle("Jen oblíbené týmy/hráči", isOn: $notifications.onlyFavorites)

                Button("Povolit notifikace") {
                    Task { _ = await notifications.requestPermission() }
                }
            } header: {
                Text("Notifikace")
            } footer: {
                Text("Notifikace jsou volitelné. Po napojení Hokejbal API mohou přicházet push zprávy ze serveru. Teď fungují lokální demo upozornění při gólu v mock live.")
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

    private var statusRow: some View {
        HStack {
            Text("Systémové notifikace")
            Spacer()
            Text(notificationStatusLabel)
                .foregroundStyle(notifications.authorizationStatus == .authorized ? HBTheme.win : .secondary)
        }
    }

    private var notificationStatusLabel: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "Povoleno"
        case .denied: return "Zamítnuto"
        case .notDetermined: return "Nežádáno"
        @unknown default: return "—"
        }
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
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

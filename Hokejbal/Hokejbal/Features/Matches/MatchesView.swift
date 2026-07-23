import SwiftUI

struct MatchesView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var matches: [Match] = []
    @State private var dayOffset: Int = 0
    @State private var competitionId: String = "extraliga"
    @State private var isLoading = false
    @State private var error: String?

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }

    private var grouped: [(String, [Match])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: matches) { match -> String in
            let day = cal.startOfDay(for: match.scheduledAt)
            return day.hbDayLabel
        }
        return dict.keys.sorted { a, b in
            let order = ["Včera": 0, "Dnes": 1, "Zítra": 2]
            return (order[a] ?? 10) < (order[b] ?? 10)
        }.map { ($0, dict[$0]!.sorted { $0.scheduledAt < $1.scheduledAt }) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayPicker
                competitionPicker
                content
            }
            .navigationTitle("Zápasy")
            .hbNavigationStyle()
            .navigationDestination(for: String.self) { id in
                MatchDetailView(matchId: id)
            }
            .task(id: "\(dayOffset)-\(competitionId)-\(apiClient.source.rawValue)") {
                await load()
            }
        }
    }

    private var dayPicker: some View {
        HStack {
            Button {
                dayOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(selectedDate.hbDayLabel)
                .font(.headline)
            Spacer()
            Button {
                dayOffset += 1
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(HBTheme.secondarySurface)
    }

    private var competitionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(catalog.competitions) { c in
                    Button {
                        competitionId = c.id
                    } label: {
                        Text(c.shortName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                competitionId == c.id ? HBTheme.brand : HBTheme.tertiarySurface,
                                in: Capsule()
                            )
                            .foregroundStyle(competitionId == c.id ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && matches.isEmpty {
            ProgressView("Načítám zápasy…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error {
            ContentUnavailableView("Chyba", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if matches.isEmpty {
            EmptyStateView(
                icon: "calendar",
                title: "Žádné zápasy",
                message: "Pro \(selectedDate.hbDayLabel.lowercased()) v této soutěži nejsou naplánované zápasy."
            )
        } else {
            List {
                ForEach(grouped, id: \.0) { title, items in
                    Section {
                        ForEach(items) { match in
                            NavigationLink(value: match.id) {
                                MatchRowView(
                                    match: match,
                                    home: catalog.team(match.homeTeamId),
                                    away: catalog.team(match.awayTeamId)
                                )
                            }
                            .buttonStyle(.plain)
                            .hbHideDisclosure()
                            .listRowInsets(HBTheme.matchRowInsets)
                            .listRowBackground(HBTheme.surface)
                            .listRowSeparator(.hidden)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        SectionHeaderLabel(title: title)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(HBTheme.surface)
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Pro zvolený den bereme zápasy bez status filtru; mock filtruje podle data
            var query = MatchesQuery(competitionId: competitionId, date: selectedDate)
            // Když je den „dnes“, ukážeme i live + dnes scheduled z celé soutěže v okolí
            if dayOffset == 0 {
                query.date = nil
                let all = try await apiClient.api.matches(query: MatchesQuery(competitionId: competitionId))
                let cal = Calendar.current
                matches = all.filter {
                    cal.isDateInToday($0.scheduledAt)
                        || cal.isDateInYesterday($0.scheduledAt)
                        || $0.status == .live
                }
            } else {
                matches = try await apiClient.api.matches(query: query)
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

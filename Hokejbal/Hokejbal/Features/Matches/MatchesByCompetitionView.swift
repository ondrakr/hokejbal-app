import SwiftUI

/// Tab Zápasy: kalendář + seznam soutěží dne → po výběru zápasy soutěže s kalendářem.
struct MatchesByCompetitionView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @EnvironmentObject private var apiClient: APIClient

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var allMatches: [Match] = []
    @State private var isLoading = false
    @State private var showSearch = false

    private var calendar: Calendar { .current }

    private var datesWithMatches: Set<Date> {
        Set(allMatches.map { calendar.startOfDay(for: $0.scheduledAt) })
    }

    private var matchesOnSelectedDay: [Match] {
        allMatches.filter { calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate) }
    }

    private var competitionsWithMatchesToday: [Competition] {
        let ids = Set(matchesOnSelectedDay.map(\.competitionId))
        let comps = catalog.competitions.filter { ids.contains($0.id) }
        return competitionOrder.sortedCompetitions(comps)
    }

    private var favoriteCompetitions: [Competition] {
        competitionsWithMatchesToday.filter { favorites.isFavorite(competition: $0) }
    }

    private var otherCompetitions: [Competition] {
        competitionsWithMatchesToday.filter { !favorites.isFavorite(competition: $0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && allMatches.isEmpty {
                    BrandLoadingView(message: "Načítám zápasy…")
                } else {
                    competitionPickerList
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                MatchDayStrip(selectedDate: $selectedDate, datesWithMatches: datesWithMatches)
            }
            .background(HBTheme.surface)
            .hbNavTitle("Zápasy", systemImage: "sportscourt.fill")
            .hbNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .accessibilityLabel("Hledat")
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                CatalogSearchView(isPresentedAsSheet: true)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var competitionPickerList: some View {
        List {
            Section {
                NavigationLink {
                    DayMatchesView(
                        title: "Všechny zápasy",
                        competitionId: nil,
                        initialDate: selectedDate
                    )
                } label: {
                    allMatchesRow
                }
                .buttonStyle(.plain)
                .hbHideDisclosure()
                .listRowInsets(EdgeInsets())
                .listRowBackground(HBTheme.surface)
                .listRowSeparator(.hidden)
            }

            if !favoriteCompetitions.isEmpty {
                Section {
                    ForEach(favoriteCompetitions) { competition in
                        competitionLink(competition)
                    }
                } header: {
                    sectionHeader("Oblíbené soutěže", accent: Color(red: 0.85, green: 0.65, blue: 0.15))
                }
            }

            if !otherCompetitions.isEmpty {
                Section {
                    ForEach(otherCompetitions) { competition in
                        competitionLink(competition)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HBTheme.surface)
    }

    private func competitionLink(_ competition: Competition) -> some View {
        NavigationLink {
            DayMatchesView(
                title: competition.name,
                competitionId: competition.id,
                initialDate: selectedDate
            )
        } label: {
            competitionRow(competition)
        }
        .buttonStyle(.plain)
        .hbHideDisclosure()
        .listRowInsets(EdgeInsets())
        .listRowBackground(HBTheme.surface)
        .listRowSeparator(.hidden)
    }

    private var allMatchesRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HBTheme.textSecondary)
                .frame(width: 28, height: 28)

            Text("Všechny zápasy")
                .font(.hbMontserrat(size: 15, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)

            if !matchesOnSelectedDay.isEmpty {
                Text("\(matchesOnSelectedDay.count)")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundStyle(HBTheme.onBrand)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(HBTheme.brand, in: Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
    }

    private func competitionRow(_ competition: Competition) -> some View {
        let dayCount = matchesOnSelectedDay.filter { $0.competitionId == competition.id }.count

        return HStack(spacing: 12) {
            CompetitionBadge(competition: competition, size: 28)

            Text(competition.name)
                .font(.hbMontserrat(size: 15, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)

            Text("\(dayCount)")
                .font(.system(size: 14, weight: .medium).monospacedDigit())
                .foregroundStyle(HBTheme.textSecondary)
                .frame(minWidth: 24, alignment: .trailing)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
        .contentShape(Rectangle())
    }

    private func sectionHeader(_ title: String, accent: Color) -> some View {
        Text(title.uppercased())
            .font(.hbMontserrat(size: 12, weight: .bold))
            .foregroundStyle(accent)
            .tracking(0.4)
            .padding(.top, 8)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 8, leading: HBTheme.screenPadding, bottom: 4, trailing: HBTheme.screenPadding))
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        allMatches = (try? await apiClient.api.matches(query: MatchesQuery())) ?? []
    }
}

/// Výpis zápasů pro den (všechny / jedna soutěž) — kalendář zůstává.
struct DayMatchesView: View {
    let title: String
    let competitionId: String?
    let initialDate: Date

    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore

    @State private var selectedDate: Date
    @State private var allMatches: [Match] = []
    @State private var isLoading = false
    @State private var error: String?

    private var calendar: Calendar { .current }

    init(title: String, competitionId: String?, initialDate: Date) {
        self.title = title
        self.competitionId = competitionId
        self.initialDate = initialDate
        _selectedDate = State(initialValue: Calendar.current.startOfDay(for: initialDate))
    }

    private var datesWithMatches: Set<Date> {
        Set(allMatches.map { calendar.startOfDay(for: $0.scheduledAt) })
    }

    private var filteredMatches: [Match] {
        allMatches
            .filter { calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var groupedByCompetition: [(Competition?, [Match])] {
        competitionOrder.groupMatchesByCompetition(filteredMatches, catalog: catalog)
    }

    private var selectedCompetition: Competition? {
        guard let competitionId else { return nil }
        return catalog.competitions.first { $0.id == competitionId }
    }

    var body: some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    MatchDayStrip(selectedDate: $selectedDate, datesWithMatches: datesWithMatches)
                    if let competition = selectedCompetition {
                        NavigationLink {
                            CompetitionDetailView(competitionId: competition.id)
                        } label: {
                            CompetitionNavStrip(competition: competition)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .background(HBTheme.surface)
            .navigationTitle(selectedCompetition == nil ? title : "")
            .navigationBarTitleDisplayMode(.inline)
            .hbNavigationStyle()
            .task(id: competitionId ?? "all") { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && allMatches.isEmpty {
            BrandLoadingView(message: "Načítám zápasy…")
        } else if let error, allMatches.isEmpty {
            ContentUnavailableView("Chyba", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if filteredMatches.isEmpty {
            EmptyStateView(
                icon: "sportscourt",
                title: "Žádné zápasy",
                message: "Na tento den nejsou naplánované zápasy."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if competitionId != nil {
            List {
                ForEach(filteredMatches) { match in
                    matchLink(match)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await load() }
        } else {
            List {
                ForEach(Array(groupedByCompetition.enumerated()), id: \.offset) { _, group in
                    let comp = group.0
                    let items = group.1
                    Section {
                        if let comp {
                            NavigationLink {
                                CompetitionDetailView(competitionId: comp.id)
                            } label: {
                                CompetitionNavStrip(competition: comp)
                            }
                            .buttonStyle(.plain)
                            .hbHideDisclosure()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(HBTheme.secondarySurface)
                            .listRowSeparator(.hidden)
                        }

                        ForEach(items) { match in
                            matchLink(match)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await load() }
        }
    }

    private func matchLink(_ match: Match) -> some View {
        NavigationLink {
            MatchDetailView(matchId: match.id)
        } label: {
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
    }

    private func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            allMatches = try await apiClient.api.matches(query: MatchesQuery(competitionId: competitionId))
        } catch {
            self.error = error.localizedDescription
            allMatches = []
        }
    }
}

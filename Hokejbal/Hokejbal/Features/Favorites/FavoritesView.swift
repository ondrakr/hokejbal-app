import SwiftUI

enum FavoritesTab: String, CaseIterable, Hashable {
    case matches = "Zápasy"
    case teams = "Týmy"
    case players = "Hráči"
    case competitions = "Soutěže"
}

struct FavoritesView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var seasons: SeasonStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore

    @State private var tab: FavoritesTab = .matches
    @State private var path = NavigationPath()
    @State private var allMatches: [Match] = []
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var isLoadingMatches = false
    @State private var showSearch = false

    private var calendar: Calendar { .current }

    private var favoriteTeams: [Team] {
        catalog.teamsById.values
            .filter { favorites.isFavorite(team: $0.id) }
            .sorted { $0.name < $1.name }
    }

    private var favoritePlayers: [Player] {
        catalog.playersById.values
            .filter { favorites.isFavorite(player: $0.id) }
            .sorted { $0.lastName < $1.lastName }
    }

    private var favoriteCompetitions: [Competition] {
        competitionOrder.sortedCompetitions(
            catalog.competitions.filter { favorites.isFavorite(competition: $0) }
        )
    }

    private var favoriteTeamIds: Set<String> { favorites.teamIDs }

    private var relevantMatches: [Match] {
        let favoriteSlugs = favorites.competitionSlugs
        return allMatches.filter { match in
            if favorites.isFavorite(match: match.id) { return true }
            if favoriteTeamIds.contains(match.homeTeamId) || favoriteTeamIds.contains(match.awayTeamId) {
                return true
            }
            if let slug = catalog.competitions.first(where: { $0.id == match.competitionId })?.slug,
               favoriteSlugs.contains(slug) {
                return true
            }
            return false
        }
        .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var datesWithMatches: Set<Date> {
        Set(relevantMatches.map { calendar.startOfDay(for: $0.scheduledAt) })
    }

    private var matchesForSelectedDay: [Match] {
        relevantMatches.filter { calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate) }
    }

    private var groupedByCompetition: [(Competition?, [Match])] {
        competitionOrder.groupMatchesByCompetition(matchesForSelectedDay, catalog: catalog)
    }

    private var hasAnyFavorite: Bool {
        !favorites.teamIDs.isEmpty
            || !favorites.playerIDs.isEmpty
            || !favorites.competitionSlugs.isEmpty
            || !favorites.matchIDs.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HBUnderlineTabs(selection: $tab)

                switch tab {
                case .matches: matchesContent
                case .teams: teamsContent
                case .players: playersContent
                case .competitions: competitionsContent
                }
            }
            .background(HBTheme.surface)
            .hbNavTitle("Oblíbené", systemImage: "star.fill")
            .hbNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .accessibilityLabel("Přidat přes hledání")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .match(let id): MatchDetailView(matchId: id)
                case .team(let id): TeamDetailView(teamId: id)
                case .player(let id): PlayerDetailView(playerId: id)
                case .competition(let id): CompetitionDetailView(competitionId: id)
                }
            }
            .sheet(isPresented: $showSearch) {
                CatalogSearchView(isPresentedAsSheet: true)
            }
            .task {
                await catalog.loadPlayersIfNeeded(using: apiClient.api, seasonId: seasons.selectedSeasonId)
                await loadMatches()
            }
            .onChange(of: favorites.teamIDs) { _, _ in Task { await loadMatches() } }
            .onChange(of: favorites.matchIDs) { _, _ in Task { await loadMatches() } }
            .onChange(of: favorites.competitionSlugs) { _, _ in Task { await loadMatches() } }
            .onChange(of: seasons.selectedSeasonId) { _, _ in Task { await loadMatches() } }
        }
    }

    // MARK: - Zápasy

    private var matchesContent: some View {
        Group {
            if !hasAnyFavorite {
                emptyFavorites
            } else if favoriteTeamIds.isEmpty && favorites.matchIDs.isEmpty && favorites.competitionSlugs.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "Bez zápasů oblíbených",
                    message: "Přidejte tým nebo soutěž hvězdičkou — zde uvidíte jejich zápasy."
                )
            } else if isLoadingMatches && allMatches.isEmpty {
                BrandLoadingView(message: "Načítám zápasy…")
            } else if relevantMatches.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "Žádné zápasy",
                    message: "Pro oblíbené zatím nejsou naplánované zápasy."
                )
            } else {
                VStack(spacing: 0) {
                    MatchDayStrip(selectedDate: $selectedDate, datesWithMatches: datesWithMatches)

                    if matchesForSelectedDay.isEmpty {
                        EmptyStateView(
                            icon: "calendar",
                            title: "Bez zápasů",
                            message: "Na tento den nemají oblíbené žádný zápas."
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(Array(groupedByCompetition.enumerated()), id: \.offset) { _, group in
                                let comp = group.0
                                let items = group.1
                                Section {
                                    if let comp {
                                        Button {
                                            path.append(Route.competition(comp.id))
                                        } label: {
                                            CompetitionNavStrip(competition: comp)
                                        }
                                        .buttonStyle(.plain)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(HBTheme.secondarySurface)
                                        .listRowSeparator(.hidden)
                                    }

                                    ForEach(items) { match in
                                        Button {
                                            path.append(Route.match(match.id))
                                        } label: {
                                            MatchRowView(
                                                match: match,
                                                home: catalog.team(match.homeTeamId),
                                                away: catalog.team(match.awayTeamId)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .listRowInsets(HBTheme.matchRowInsets)
                                        .listRowBackground(HBTheme.surface)
                                        .listRowSeparator(.hidden)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await loadMatches() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HBTheme.surface)
    }

    private var emptyFavorites: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                icon: "star",
                title: "Zatím nic v oblíbených",
                message: "Označte tým, hráče nebo soutěž hvězdičkou. Pak tu uvidíte přehled a zápasy."
            )
            Button {
                showSearch = true
            } label: {
                Label("Hledat a přidat", systemImage: "magnifyingglass")
                    .font(.hbMontserrat(size: 15, weight: .semibold))
                    .foregroundStyle(HBTheme.onBrand)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(HBTheme.brand, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Týmy

    private var teamsContent: some View {
        Group {
            if favoriteTeams.isEmpty {
                emptySection(
                    title: "Žádné oblíbené týmy",
                    message: "Najděte tým ve vyhledávání a klepněte na hvězdičku."
                )
            } else {
                List {
                    ForEach(favoriteTeams) { team in
                        Button {
                            path.append(Route.team(team.id))
                        } label: {
                            HStack(spacing: 12) {
                                TeamBadge(team: team, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.hbMontserrat(size: 15, weight: .semibold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                    Text(team.city)
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                }
                                Spacer(minLength: 0)
                                FavoriteStarButton(isFavorite: true) {
                                    favorites.toggleTeam(team.id)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                favorites.toggleTeam(team.id)
                            } label: {
                                Label("Odebrat", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(HBTheme.surface)
    }

    // MARK: - Hráči

    private var playersContent: some View {
        Group {
            if favoritePlayers.isEmpty {
                emptySection(
                    title: "Žádní oblíbení hráči",
                    message: "Najděte hráče ve vyhledávání a klepněte na hvězdičku."
                )
            } else {
                List {
                    ForEach(favoritePlayers) { player in
                        Button {
                            path.append(Route.player(player.id))
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(HBTheme.brand.opacity(0.12))
                                    Text("\(player.number)")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(HBTheme.brand)
                                }
                                .frame(width: 40, height: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.fullName)
                                        .font(.hbMontserrat(size: 15, weight: .semibold))
                                        .foregroundStyle(HBTheme.textPrimary)
                                    Text("\(player.position.label.capitalized) · \(catalog.team(player.teamId)?.shortName ?? "")")
                                        .font(.hbMontserrat(size: 12, weight: .medium))
                                        .foregroundStyle(HBTheme.textSecondary)
                                }
                                Spacer(minLength: 0)
                                Text("\(player.points) b")
                                    .font(.hbMontserrat(size: 13, weight: .bold).monospacedDigit())
                                    .foregroundStyle(HBTheme.brand)
                                FavoriteStarButton(isFavorite: true) {
                                    favorites.togglePlayer(player.id)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                favorites.togglePlayer(player.id)
                            } label: {
                                Label("Odebrat", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(HBTheme.surface)
    }

    // MARK: - Soutěže

    private var competitionsContent: some View {
        Group {
            if favoriteCompetitions.isEmpty {
                emptySection(
                    title: "Žádné oblíbené soutěže",
                    message: "V profilu soutěže klepněte na hvězdičku."
                )
            } else {
                List {
                    ForEach(favoriteCompetitions) { comp in
                        Button {
                            path.append(Route.competition(comp.id))
                        } label: {
                            HStack(spacing: 12) {
                                CompetitionBadge(competition: comp, size: 36)
                                Text(comp.name)
                                    .font(.hbMontserrat(size: 15, weight: .semibold))
                                    .foregroundStyle(HBTheme.textPrimary)
                                    .lineLimit(2)
                                Spacer(minLength: 0)
                                FavoriteStarButton(isFavorite: true) {
                                    favorites.toggleCompetition(comp)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                favorites.toggleCompetition(comp)
                            } label: {
                                Label("Odebrat", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(HBTheme.surface)
    }

    private func emptySection(title: String, message: String) -> some View {
        VStack(spacing: 16) {
            EmptyStateView(icon: "star", title: title, message: message)
            Button {
                showSearch = true
            } label: {
                Label("Otevřít hledání", systemImage: "magnifyingglass")
                    .font(.hbMontserrat(size: 14, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadMatches() async {
        isLoadingMatches = true
        defer { isLoadingMatches = false }
        allMatches = (try? await apiClient.api.matches(query: MatchesQuery())) ?? []
    }
}

enum Route: Hashable {
    case match(String)
    case team(String)
    case player(String)
    case competition(String)
}

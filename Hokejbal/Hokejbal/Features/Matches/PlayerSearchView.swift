import SwiftUI

/// Live vyhledávání hráčů, týmů a soutěží — input je vždy vidět nahoře.
struct CatalogSearchView: View {
    var isPresentedAsSheet: Bool = true

    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var seasons: SeasonStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var teamResults: [Team] {
        let q = normalizedQuery
        guard !q.isEmpty else { return [] }
        return catalog.teamsById.values
            .filter {
                $0.name.localizedCaseInsensitiveContains(q)
                    || $0.shortName.localizedCaseInsensitiveContains(q)
                    || $0.city.localizedCaseInsensitiveContains(q)
            }
            .sorted { $0.name < $1.name }
    }

    private var playerResults: [Player] {
        let q = normalizedQuery
        guard !q.isEmpty else { return [] }
        return catalog.playersById.values
            .filter { p in
                p.fullName.localizedCaseInsensitiveContains(q)
                    || p.lastName.localizedCaseInsensitiveContains(q)
                    || (catalog.team(p.teamId)?.shortName.localizedCaseInsensitiveContains(q) ?? false)
                    || (catalog.team(p.teamId)?.name.localizedCaseInsensitiveContains(q) ?? false)
            }
            .sorted { $0.points > $1.points }
    }

    private var competitionResults: [Competition] {
        let q = normalizedQuery
        guard !q.isEmpty else { return [] }
        let filtered = catalog.competitions.filter {
            $0.name.localizedCaseInsensitiveContains(q)
                || $0.shortName.localizedCaseInsensitiveContains(q)
        }
        return competitionOrder.sortedCompetitions(filtered)
    }

    var body: some View {
        Group {
            if isPresentedAsSheet {
                NavigationStack { searchBody }
            } else {
                searchBody
            }
        }
    }

    private var searchBody: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 10)
                .background(HBTheme.surface)

            Rectangle()
                .fill(HBTheme.separator)
                .frame(height: 0.5)

            resultsContent
        }
        .background(HBTheme.surface)
        .navigationTitle("Hledat")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .toolbar {
            if isPresentedAsSheet {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zavřít") { dismiss() }
                }
            }
        }
        .task {
            await catalog.loadPlayersIfNeeded(using: apiClient.api, seasonId: seasons.selectedSeasonId)
            isSearchFocused = true
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(HBTheme.textTertiary)

            TextField("Hráč, tým, soutěž…", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HBTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HBTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var resultsContent: some View {
        let hasResults = !teamResults.isEmpty || !playerResults.isEmpty || !competitionResults.isEmpty

        if !catalog.arePlayersLoaded && catalog.teamsById.isEmpty && catalog.competitions.isEmpty {
            ProgressView("Načítám data…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if normalizedQuery.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Live vyhledávání",
                message: "Pište jméno hráče, týmu nebo soutěže — výsledky se zobrazí hned."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !hasResults {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Nic nenalezeno",
                message: "Zkuste jiné jméno, zkratku týmu nebo soutěž."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if !competitionResults.isEmpty {
                    Section {
                        ForEach(competitionResults) { competition in
                            NavigationLink {
                                CompetitionDetailView(competitionId: competition.id)
                            } label: {
                                competitionRow(competition)
                            }
                            .buttonStyle(.plain)
                            .hbHideDisclosure()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(HBTheme.surface)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("SOUTĚŽE (\(competitionResults.count))")
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                }

                if !teamResults.isEmpty {
                    Section {
                        ForEach(teamResults) { team in
                            NavigationLink {
                                TeamDetailView(teamId: team.id)
                            } label: {
                                teamRow(team)
                            }
                            .buttonStyle(.plain)
                            .hbHideDisclosure()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(HBTheme.surface)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("TÝMY (\(teamResults.count))")
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                }

                if !playerResults.isEmpty {
                    Section {
                        ForEach(playerResults) { player in
                            NavigationLink {
                                PlayerDetailView(playerId: player.id)
                            } label: {
                                playerRow(player)
                            }
                            .buttonStyle(.plain)
                            .hbHideDisclosure()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(HBTheme.surface)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("HRÁČI (\(playerResults.count))")
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func competitionRow(_ competition: Competition) -> some View {
        HStack(spacing: 12) {
            CompetitionBadge(competition: competition, size: 28)
            Text(competition.name)
                .font(.hbMontserrat(size: 15, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
        .contentShape(Rectangle())
    }

    private func teamRow(_ team: Team) -> some View {
        HStack(spacing: 12) {
            TeamBadge(team: team, size: 40)
            Text(team.name)
                .font(.hbMontserrat(size: 15, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
        .contentShape(Rectangle())
    }

    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(HBTheme.brand.opacity(0.14))
                Text("\(player.number)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(HBTheme.brand)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.hbMontserrat(size: 15, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                Text(catalog.team(player.teamId)?.shortName ?? "")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
    }
}

typealias PlayerSearchView = CatalogSearchView

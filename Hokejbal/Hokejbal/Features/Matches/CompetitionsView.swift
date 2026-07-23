import SwiftUI

struct CompetitionsView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore

    @State private var query: String = ""

    private var filteredAll: [Competition] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = competitionOrder.sortedCompetitions(catalog.competitions)
        guard !q.isEmpty else { return base }
        return base.filter { comp in
            comp.name.localizedCaseInsensitiveContains(q) || comp.shortName.localizedCaseInsensitiveContains(q)
        }
    }

    private var filteredFavorites: [Competition] {
        competitionOrder.sortedCompetitions(
            filteredAll.filter { favorites.isFavorite(competition: $0) }
        )
    }

    var body: some View {
        List {
            if !filteredFavorites.isEmpty {
                Section {
                    ForEach(filteredFavorites) { comp in
                        competitionRow(comp)
                    }
                } header: {
                    SectionHeaderLabel(title: "Oblíbené")
                }
            }

            Section {
                ForEach(filteredAll) { comp in
                    competitionRow(comp)
                }
            } header: {
                SectionHeaderLabel(title: "Všechny soutěže")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HBTheme.surface)
        .navigationTitle("Soutěže")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Hledat soutěž")
    }

    private func competitionRow(_ comp: Competition) -> some View {
        HStack(spacing: 4) {
            NavigationLink {
                CompetitionDetailView(competitionId: comp.id)
            } label: {
                CompetitionCellView(competition: comp, showsChevron: false)
            }
            .buttonStyle(.plain)

            FavoriteStarButton(
                isFavorite: favorites.isFavorite(competition: comp),
                accessibilityLabel: "Oblíbená soutěž"
            ) {
                favorites.toggleCompetition(comp)
            }
        }
        .listRowInsets(HBTheme.listRowInsets)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

private struct CompetitionCellView: View {
    let competition: Competition
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            CompetitionBadge(competition: competition, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(competition.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)

                Text(competition.season)
                    .font(.caption)
                    .foregroundStyle(HBTheme.textSecondary)
            }

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(HBTheme.textTertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .hbCard()
        .contentShape(Rectangle())
    }
}

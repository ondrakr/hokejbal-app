import SwiftUI

struct StandingsView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var rows: [StandingRow] = []
    @State private var competitionId: String = "extraliga"
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                competitionPicker
                if isLoading && rows.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            headerRow
                            ForEach(rows) { row in
                                NavigationLink(value: row.teamId) {
                                    standingRow(row)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            SectionHeaderLabel(title: "Základní část · \(seasonLabel)")
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(HBTheme.surface)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Tabulka")
            .hbNavigationStyle()
            .navigationDestination(for: String.self) { teamId in
                TeamDetailView(teamId: teamId)
            }
            .task(id: "\(competitionId)-\(apiClient.source.rawValue)") {
                await load()
            }
        }
    }

    private var seasonLabel: String {
        catalog.competitions.first { $0.id == competitionId }?.season ?? "2025/26"
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
        .background(HBTheme.secondarySurface)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: 28, alignment: .leading)
            Text("Tým").frame(maxWidth: .infinity, alignment: .leading)
            stat("Z")
            stat("Skóre")
            stat("B")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .listRowBackground(Color.clear)
    }

    private func standingRow(_ row: StandingRow) -> some View {
        let team = catalog.team(row.teamId)
        let isFav = favorites.isFavorite(team: row.teamId)
        let accent = row.rank <= 3 ? HBTheme.brand : nil

        return HStack(spacing: 0) {
            Text("\(row.rank)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(row.rank <= 8 ? HBTheme.brand : .secondary)
                .frame(width: 28, alignment: .leading)
            HStack(spacing: 8) {
                if let team {
                    TeamBadge(team: team, size: 26)
                    Text(team.shortName)
                        .font(.subheadline.weight(isFav ? .bold : .medium))
                        .foregroundStyle(HBTheme.textPrimary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(row.played)")
                .font(.subheadline.monospacedDigit())
                .frame(width: 28)
            Text(row.scoreText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 56)
            Text("\(row.points)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(row.rank <= 3 ? HBTheme.brand.opacity(0.10) : HBTheme.secondarySurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke((accent ?? .clear), lineWidth: 0.8)
        )
    }

    private func stat(_ title: String) -> some View {
        Text(title)
            .frame(width: title == "Skóre" ? 56 : (title == "B" ? 32 : 28), alignment: title == "B" ? .trailing : .center)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        rows = (try? await apiClient.api.standings(competitionId: competitionId)) ?? []
    }
}

import SwiftUI

/// Položka vysvětlivky pod ligovou tabulkou.
struct StandingLegendItem: Identifiable, Hashable, Sendable {
    let id: String
    let color: Color
    let label: String
    let ranks: ClosedRange<Int>

    init(id: String, color: Color, label: String, ranks: ClosedRange<Int>) {
        self.id = id
        self.color = color
        self.label = label
        self.ranks = ranks
    }

    /// Výchozí zóny podle velikosti tabulky a typu soutěže.
    static func defaults(teamCount: Int, competitionSlug: String? = nil) -> [StandingLegendItem] {
        guard teamCount > 0 else { return [] }

        let playoffEnd = min(8, max(teamCount / 2, 1))
        let relegationCount = teamCount >= 8 ? 2 : (teamCount >= 5 ? 1 : 0)
        let relegationStart = teamCount - relegationCount + 1

        var items: [StandingLegendItem] = [
            .init(
                id: "playoff",
                color: StandingTablePalette.playoff,
                label: playoffLabel(for: competitionSlug),
                ranks: 1...playoffEnd
            )
        ]

        if relegationCount > 0, relegationStart > playoffEnd {
            items.append(
                .init(
                    id: "relegation",
                    color: StandingTablePalette.relegation,
                    label: relegationLabel(for: competitionSlug),
                    ranks: relegationStart...teamCount
                )
            )
        }

        return items
    }

    private static func playoffLabel(for slug: String?) -> String {
        switch slug {
        case "extraliga", "1liga", "2liga":
            return "Postup do čtvrtfinále"
        case "zeny", "prebor-zen":
            return "Postup do play-off"
        default:
            return "Postup do play-off"
        }
    }

    private static func relegationLabel(for slug: String?) -> String {
        switch slug {
        case "extraliga":
            return "Sestup"
        case "1liga", "2liga":
            return "Sestupová příčka"
        default:
            return "Sestup"
        }
    }
}

private enum StandingTablePalette {
    static let playoff = Color(red: 0.22, green: 0.45, blue: 0.85)
    static let relegation = Color(red: 0.82, green: 0.28, blue: 0.28)
    static let neutral = HBTheme.tertiarySurface
}

/// Jednotná ligová tabulka (soutěž, detail zápasu, …).
struct StandingsTableView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var favorites: FavoritesStore

    let rows: [StandingRow]
    var highlightTeamIds: Set<String> = []
    var showsFavoriteStar: Bool = false
    var emptyMessage: String = "Tabulka pro tuto soutěž není k dispozici."
    var topPadding: CGFloat = 8
    /// Volitelný slug soutěže pro text vysvětlivek (`extraliga`, `1liga`…).
    var competitionSlug: String? = nil
    /// Vlastní legenda; když `nil`, sestaví se automaticky.
    var legend: [StandingLegendItem]? = nil

    private var resolvedLegend: [StandingLegendItem] {
        if let legend { return legend }
        return StandingLegendItem.defaults(
            teamCount: rows.count,
            competitionSlug: competitionSlug
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if rows.isEmpty {
                EmptyStateView(icon: "list.number", title: "Bez tabulky", message: emptyMessage)
                    .padding(.top, 32)
            } else {
                header
                ForEach(rows) { row in
                    standingRow(row)
                }
                legendSection
            }
        }
        .padding(.top, topPadding)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 28, alignment: .leading)
            Text("Tým")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Z")
                .frame(width: 28, alignment: .trailing)
            Text("G")
                .frame(width: 52, alignment: .trailing)
            Text("B")
                .frame(width: 28, alignment: .trailing)
            if showsFavoriteStar {
                Color.clear.frame(width: 36)
            }
        }
        .font(.hbMontserrat(size: 11, weight: .semibold))
        .foregroundStyle(HBTheme.textTertiary)
        .padding(.leading, HBTheme.screenPadding)
        .padding(.trailing, showsFavoriteStar ? 8 : HBTheme.screenPadding)
        .padding(.vertical, 10)
    }

    private func standingRow(_ row: StandingRow) -> some View {
        let team = catalog.team(row.teamId)
        let highlighted = highlightTeamIds.contains(row.teamId)
        let zoneColor = zoneColor(for: row.rank)

        return HStack(spacing: 8) {
            NavigationLink {
                TeamDetailView(teamId: row.teamId)
            } label: {
                HStack(spacing: 8) {
                    Text("\(row.rank)")
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .foregroundStyle(rankForeground(for: row.rank))
                        .frame(width: 22, height: 22)
                        .background(zoneColor, in: Circle())

                    if let team {
                        TeamBadge(team: team, size: 22)
                        Text(team.shortName)
                            .font(.hbMontserrat(size: 14, weight: highlighted ? .bold : .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text(row.teamId)
                            .font(.hbMontserrat(size: 14, weight: .medium))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Text("\(row.played)")
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(HBTheme.textSecondary)
                        .frame(width: 28, alignment: .trailing)
                    Text(row.scoreText)
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(HBTheme.textSecondary)
                        .frame(width: 52, alignment: .trailing)
                    Text("\(row.points)")
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundStyle(HBTheme.brand)
                        .frame(width: 28, alignment: .trailing)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsFavoriteStar {
                FavoriteStarButton(
                    isFavorite: favorites.isFavorite(team: row.teamId),
                    accessibilityLabel: "Oblíbený tým"
                ) {
                    favorites.toggleTeam(row.teamId)
                }
            }
        }
        .padding(.leading, HBTheme.screenPadding)
        .padding(.trailing, showsFavoriteStar ? 8 : HBTheme.screenPadding)
        .padding(.vertical, 10)
        .background(highlighted ? HBTheme.brand.opacity(0.06) : Color.clear)
        .overlay(alignment: .leading) {
            if highlighted {
                Rectangle()
                    .fill(HBTheme.brand)
                    .frame(width: 3)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(HBTheme.separator).frame(height: 0.5)
        }
    }

    private var legendSection: some View {
        let items = resolvedLegend
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.label)
                                .font(.hbMontserrat(size: 12, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(items.map(\.label).joined(separator: ", "))
            }
        }
    }

    private func zoneColor(for rank: Int) -> Color {
        if let item = resolvedLegend.first(where: { $0.ranks.contains(rank) }) {
            return item.color
        }
        return StandingTablePalette.neutral
    }

    private func rankForeground(for rank: Int) -> Color {
        resolvedLegend.contains { $0.ranks.contains(rank) } ? .white : HBTheme.textSecondary
    }
}

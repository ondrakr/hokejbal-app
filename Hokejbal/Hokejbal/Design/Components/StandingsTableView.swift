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

/// Jednotná ligová tabulka s Live / Celkem / Doma / Venku / Forma.
struct StandingsTableView: View {
    @EnvironmentObject private var catalog: CatalogStore

    let rows: [StandingRow]
    var matches: [Match] = []
    var competitionId: String? = nil
    var highlightTeamIds: Set<String> = []
    var emptyMessage: String = "Tabulka pro tuto soutěž není k dispozici."
    var topPadding: CGFloat = 8
    var competitionSlug: String? = nil
    var legend: [StandingLegendItem]? = nil

    @State private var scope: StandingsScope = .total
    @State private var formWindow: FormWindow = .five
    @State private var didInitScope = false
    @State private var userPickedScope = false

    private var viewRows: [StandingViewRow] {
        guard let competitionId, !rows.isEmpty else {
            return rows.map { StandingViewRow(from: $0) }
        }
        return StandingsCompute.build(
            base: rows,
            matches: matches,
            competitionId: competitionId,
            scope: scope,
            formWindow: formWindow
        )
    }

    private var hasLive: Bool {
        guard let competitionId else { return false }
        return StandingsCompute.hasLive(matches: matches, competitionId: competitionId)
    }

    private var resolvedLegend: [StandingLegendItem] {
        if let legend { return legend }
        return StandingLegendItem.defaults(
            teamCount: viewRows.count,
            competitionSlug: competitionSlug
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if rows.isEmpty {
                EmptyStateView(icon: "list.number", title: "Bez tabulky", message: emptyMessage)
                    .padding(.top, 32)
            } else {
                if competitionId != nil {
                    HBPillSelector(selection: $scope, compact: true)
                        .onChange(of: scope) { _, _ in
                            if didInitScope { userPickedScope = true }
                        }
                    if scope == .form {
                        HBPillSelector(selection: $formWindow, compact: true)
                    }
                }
                header
                ForEach(viewRows) { row in
                    standingRow(row)
                }
                legendSection
            }
        }
        .padding(.top, topPadding)
        .onAppear {
            guard !didInitScope else { return }
            didInitScope = true
            if hasLive { scope = .live }
        }
        .onChange(of: hasLive) { _, live in
            guard live, !userPickedScope else { return }
            scope = .live
        }
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
        }
        .font(.hbMontserrat(size: 11, weight: .semibold))
        .foregroundStyle(HBTheme.textTertiary)
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 10)
    }

    private func standingRow(_ row: StandingViewRow) -> some View {
        let team = catalog.team(row.teamId)
        let highlighted = highlightTeamIds.contains(row.teamId)
        let zoneColor = zoneColor(for: row.rank)
        let isLiveRow = row.liveScore != nil
        let liveStats = Color(red: 1.0, green: 0.18, blue: 0.33)
        let statsColor: Color = isLiveRow ? liveStats : HBTheme.textSecondary
        let pointsColor: Color = isLiveRow ? liveStats : HBTheme.brand

        return NavigationLink {
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
                    HStack(spacing: 4) {
                        Text(team.shortName)
                            .font(.hbMontserrat(size: 14, weight: highlighted ? .bold : .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if row.rankDelta != 0 {
                            Text(row.rankDelta > 0 ? "▲+\(row.rankDelta)" : "▼\(row.rankDelta)")
                                .font(.system(size: 10, weight: .bold).monospacedDigit())
                                .foregroundStyle(row.rankDelta > 0
                                    ? Color(red: 0.18, green: 0.65, blue: 0.32)
                                    : Color(red: 0.75, green: 0.22, blue: 0.22))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(0)
                } else {
                    HStack(spacing: 4) {
                        Text(row.teamId)
                            .font(.hbMontserrat(size: 14, weight: .medium))
                            .lineLimit(1)
                        if row.rankDelta != 0 {
                            Text(row.rankDelta > 0 ? "▲+\(row.rankDelta)" : "▼\(row.rankDelta)")
                                .font(.system(size: 10, weight: .bold).monospacedDigit())
                                .foregroundStyle(row.rankDelta > 0
                                    ? Color(red: 0.18, green: 0.65, blue: 0.32)
                                    : Color(red: 0.75, green: 0.22, blue: 0.22))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(0)
                }

                if let live = row.liveScore {
                    Text(live.text)
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(liveBadgeColor(live.tone), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(2)
                }

                Text("\(row.played)")
                    .font(.system(size: 13, weight: isLiveRow ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(statsColor)
                    .lineLimit(1)
                    .frame(width: 28, alignment: .trailing)
                    .layoutPriority(1)
                Text(row.scoreText)
                    .font(.system(size: 13, weight: isLiveRow ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(statsColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 52, alignment: .trailing)
                    .layoutPriority(1)
                Text("\(row.points)")
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundStyle(pointsColor)
                    .lineLimit(1)
                    .frame(width: 28, alignment: .trailing)
                    .layoutPriority(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HBTheme.screenPadding)
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

    private func liveBadgeColor(_ tone: LiveScoreTone) -> Color {
        switch tone {
        case .win: return Color(red: 0.18, green: 0.65, blue: 0.32)
        case .draw: return Color(red: 0.90, green: 0.58, blue: 0.10)
        case .loss: return Color(red: 0.85, green: 0.22, blue: 0.22)
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

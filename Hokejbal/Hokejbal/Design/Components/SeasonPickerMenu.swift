import SwiftUI

/// Výběr ročníku — solidní sheet místo systémového glass `Menu`.
struct SeasonPickerMenu: View {
    @EnvironmentObject private var seasons: SeasonStore

    var body: some View {
        HBSolidMenuButton(
            title: "Ročník",
            options: seasons.seasons,
            selectedId: seasons.selectedSeasonId,
            optionLabel: { $0.label },
            optionDetail: { $0.isCurrent ? "aktuální" : nil },
            onSelect: { seasons.selectedSeasonId = $0.id }
        ) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                Text(seasons.selectedLabel)
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(HBTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(HBTheme.secondarySurface)
            )
        }
        .accessibilityLabel("Ročník \(seasons.selectedLabel)")
    }
}

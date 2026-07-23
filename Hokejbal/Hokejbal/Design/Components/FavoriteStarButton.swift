import SwiftUI

/// Hvězdička oblíbených (soutěž / tým / hráč).
struct FavoriteStarButton: View {
    let isFavorite: Bool
    var accessibilityLabel: String = "Oblíbené"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isFavorite ? HBTheme.brand : HBTheme.textTertiary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
    }
}

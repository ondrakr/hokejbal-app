import SwiftUI

/// Hvězdička oblíbených (soutěž / tým / hráč). Vyžaduje přihlášení.
struct FavoriteStarButton: View {
    @EnvironmentObject private var auth: AuthStore
    let isFavorite: Bool
    var accessibilityLabel: String = "Oblíbené"
    let action: () -> Void

    var body: some View {
        Button {
            guard auth.requireAuth() else { return }
            action()
        } label: {
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

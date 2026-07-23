import SwiftUI
import UIKit

enum HBTheme {
    static let brand = Color(red: 201 / 255, green: 42 / 255, blue: 42 / 255) // #C92A2A
    static let brandDark = Color(red: 169 / 255, green: 35 / 255, blue: 35 / 255)
    static let live = Color(red: 0.86, green: 0.15, blue: 0.15)
    static let win = Color(red: 0.18, green: 0.65, blue: 0.32)
    static let draw = Color(red: 0.75, green: 0.55, blue: 0.12)
    static let loss = Color(red: 0.75, green: 0.22, blue: 0.22)

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    static let surface = Color(uiColor: .systemBackground)
    static let secondarySurface = Color(uiColor: .secondarySystemBackground)
    static let tertiarySurface = Color(uiColor: .tertiarySystemBackground)
    static let separator = Color(uiColor: .separator)

    /// Text na brand / LIVE badge (vždy světlý).
    static let onBrand = Color.white

    static let screenPadding: CGFloat = 16
    static let listRowInsets = EdgeInsets(top: 6, leading: screenPadding, bottom: 6, trailing: screenPadding)
    /// Edge-to-edge řádky zápasů (oddělovač přes celou šířku).
    static let matchRowInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    static let categoryColors: [String: Color] = [
        "CTM a HCŽ": Color(red: 0.92, green: 0.45, blue: 0.18),
        "Masters": Color(red: 0.25, green: 0.45, blue: 0.78),
        "Mládež": Color(red: 0.18, green: 0.62, blue: 0.48),
        "2. liga": Color(red: 0.45, green: 0.35, blue: 0.72),
        "Extraliga": brand,
        "1. liga": Color(red: 0.2, green: 0.35, blue: 0.55)
    ]
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Podle systému"
        case .light: return "Světlý"
        case .dark: return "Tmavý"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppearanceStore: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.key) }
    }

    private static let key = "hb.appearance"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? AppAppearance.system.rawValue
        appearance = AppAppearance(rawValue: raw) ?? .system
    }
}

extension Font {
    static func hbMontserrat(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight)
    }

    static let hbScore = hbMontserrat(size: 28, weight: .bold)
    static let hbMatchScore = hbMontserrat(size: 22, weight: .bold)
    static let hbSection = hbMontserrat(size: 13, weight: .semibold)
}

struct HBNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(HBTheme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(HBTheme.surface)
    }
}

extension View {
    func hbNavigationStyle() -> some View {
        modifier(HBNavigationBarModifier())
    }

    /// Skryje šipku NavigationLink u řádku zápasu.
    func hbHideDisclosure() -> some View {
        navigationLinkIndicatorVisibility(.hidden)
    }

    /// Nadpis stránky s ikonou v navigation baru.
    func hbNavTitle(_ title: String, systemImage: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 7) {
                        Image(systemName: systemImage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(HBTheme.brand)
                        Text(title)
                            .font(.hbMontserrat(size: 17, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
    }
}

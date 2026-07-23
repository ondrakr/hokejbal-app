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

    // MARK: - Redesign "HB Arena" tokeny

    /// Podkladová plocha aplikace (jemně tónovaná — karty na ní „plavou“).
    static let canvas = Color(uiColor: .systemGroupedBackground)
    /// Povrch karty (bílá / tmavě šedá) — kontrastní vůči `canvas`.
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    /// Vnořený povrch uvnitř karty (chip / segment).
    static let cardInset = Color(uiColor: .tertiarySystemGroupedBackground)
    /// Vlasová obrysová linka karet.
    static let cardStroke = Color(uiColor: .separator).opacity(0.45)
    /// Tmavý „arénový“ inkoust pro hero plochy.
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.13)
    static let inkSoft = Color(red: 0.16, green: 0.17, blue: 0.21)

    /// Signaturní brandový gradient (diagonální — energie / pohyb).
    static let brandGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 0.18, blue: 0.18), brandDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Tmavý arénový gradient pro hero header.
    static let inkGradient = LinearGradient(
        colors: [Color(red: 0.13, green: 0.14, blue: 0.18), ink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Text na brand / LIVE badge (vždy světlý).
    static let onBrand = Color.white

    static let screenPadding: CGFloat = 16
    static let listRowInsets = EdgeInsets(top: 6, leading: screenPadding, bottom: 6, trailing: screenPadding)
    /// Edge-to-edge řádky zápasů (oddělovač přes celou šířku).
    static let matchRowInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    // Zaoblení
    static let radiusLg: CGFloat = 20
    static let radiusMd: CGFloat = 16
    static let radiusSm: CGFloat = 10

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

    /// Výrazný „display“ řez pro nadpisy a skóre (zaoblený → moderní, sportovní).
    static func hbDisplay(size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Číselný řez pro skóre / statistiky (zaoblený, monospaced číslice).
    static func hbNumber(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let hbScore = hbNumber(size: 30, weight: .heavy)
    static let hbMatchScore = hbNumber(size: 24, weight: .bold)
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

    /// Elevated karta: povrch, zaoblení, vlasový obrys a jemný stín.
    func hbCard(
        cornerRadius: CGFloat = HBTheme.radiusMd,
        fill: Color = HBTheme.card,
        strokeOpacity: Double = 1
    ) -> some View {
        self
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(HBTheme.cardStroke.opacity(strokeOpacity), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
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

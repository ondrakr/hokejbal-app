import SwiftUI
import UIKit

/// Globální vzhled systému — solidní bary, podpora light/dark.
enum HBAppearance {
    static func apply() {
        configureNavigationBar()
        configureTabBar()
        configureToolbar()
    }

    private static var surfaceUIColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
                : .white
        }
    }

    private static var labelUIColor: UIColor { .label }
    private static var mutedUIColor: UIColor { .secondaryLabel }
    private static var shadowUIColor: UIColor { UIColor.separator.withAlphaComponent(0.6) }

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = surfaceUIColor
        appearance.shadowColor = shadowUIColor
        appearance.titleTextAttributes = [
            .foregroundColor: labelUIColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: labelUIColor
        ]

        let nav = UINavigationBar.appearance()
        nav.standardAppearance = appearance
        nav.compactAppearance = appearance
        nav.scrollEdgeAppearance = appearance
        nav.compactScrollEdgeAppearance = appearance
        nav.tintColor = UIColor(red: 201 / 255, green: 42 / 255, blue: 42 / 255, alpha: 1)
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = surfaceUIColor
        appearance.shadowColor = shadowUIColor

        let brand = UIColor(red: 201 / 255, green: 42 / 255, blue: 42 / 255, alpha: 1)

        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = mutedUIColor
        item.normal.titleTextAttributes = [.foregroundColor: mutedUIColor]
        item.selected.iconColor = brand
        item.selected.titleTextAttributes = [.foregroundColor: brand]

        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        let tab = UITabBar.appearance()
        tab.standardAppearance = appearance
        tab.scrollEdgeAppearance = appearance
        tab.tintColor = brand
        tab.unselectedItemTintColor = mutedUIColor
    }

    private static func configureToolbar() {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = surfaceUIColor
        appearance.shadowColor = shadowUIColor

        let toolbar = UIToolbar.appearance()
        toolbar.standardAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        toolbar.compactScrollEdgeAppearance = appearance
    }
}

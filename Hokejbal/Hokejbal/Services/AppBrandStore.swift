import Foundation
import SwiftUI

enum AppBrand: String, CaseIterable, Identifiable, Sendable {
    case hokejbal
    case cmshb

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hokejbal: return "hokejbal.cz"
        case .cmshb: return "CMSHb.CZ"
        }
    }

    var homeURL: URL {
        switch self {
        case .hokejbal: return URL(string: "https://www.hokejbal.cz/")!
        case .cmshb: return URL(string: "https://www.cmshb.cz/")!
        }
    }
}

@MainActor
final class AppBrandStore: ObservableObject {
    @Published var brand: AppBrand {
        didSet { defaults.set(brand.rawValue, forKey: Self.defaultsKey) }
    }

    private let defaults: UserDefaults
    private static let defaultsKey = "hb.appBrand"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.defaultsKey),
           let stored = AppBrand(rawValue: raw) {
            brand = stored
        } else {
            brand = .hokejbal
        }
    }

    func select(_ brand: AppBrand) {
        self.brand = brand
    }
}

import SwiftUI

/// Záložka Více.
struct MoreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(MoreMenuItem.allCases) { item in
                        moreRow(item)
                    }
                }
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(HBTheme.canvas)
            .hbNavTitle("Více", systemImage: "ellipsis.circle.fill")
            .hbNavigationStyle()
        }
    }

    @ViewBuilder
    private func moreRow(_ item: MoreMenuItem) -> some View {
        switch item.destination {
        case .settings:
            NavigationLink {
                SettingsView()
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .search:
            NavigationLink {
                CatalogSearchView(isPresentedAsSheet: false)
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .news:
            NavigationLink {
                NewsView()
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .url(let url):
            Link(destination: url) {
                MoreMenuRowLabel(item: item, showsExternalHint: true)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MoreMenuRowLabel: View {
    let item: MoreMenuItem
    var showsExternalHint: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HBTheme.brand)
                .frame(width: 28, height: 28)

            Text(item.title)
                .font(.hbMontserrat(size: 16, weight: .semibold))
                .foregroundStyle(HBTheme.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Image(systemName: showsExternalHint ? "arrow.up.right" : "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HBTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .hbCard()
        .contentShape(Rectangle())
    }
}

private enum MoreMenuItem: String, CaseIterable, Identifiable {
    case settings
    case search
    case news
    case fantasy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .settings: return "Nastavení"
        case .search: return "Vyhledávání"
        case .news: return "Novinky"
        case .fantasy: return "Fantasy"
        }
    }

    var systemImage: String {
        switch self {
        case .settings: return "gearshape.fill"
        case .search: return "magnifyingglass"
        case .news: return "newspaper.fill"
        case .fantasy: return "gamecontroller.fill"
        }
    }

    enum Destination {
        case settings
        case search
        case news
        case url(URL)
    }

    var destination: Destination {
        switch self {
        case .settings: return .settings
        case .search: return .search
        case .news: return .news
        case .fantasy:
            return .url(URL(string: "https://hokejbal-fantasy.cz")!)
        }
    }
}

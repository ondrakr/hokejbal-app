import SwiftUI

/// Záložka Více.
struct MoreView: View {
    @EnvironmentObject private var tabRouter: AppTabRouter

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

        case .media:
            NavigationLink {
                MediaView()
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .liveStreams:
            Button {
                tabRouter.selectLive(filter: .broadcasts)
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .fantasy:
            NavigationLink {
                FantasyView()
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .amateur:
            NavigationLink {
                AmateurTournamentsView()
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)

        case .tips:
            NavigationLink {
                TipovaniView()
            } label: {
                MoreMenuRowLabel(item: item)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MoreMenuRowLabel: View {
    let item: MoreMenuItem

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

            Image(systemName: "chevron.right")
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
    case fantasy
    case tips
    case amateur
    case settings
    case search
    case news
    case liveStreams
    case media

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fantasy: return "Fantasy"
        case .tips: return "Tipovačka"
        case .amateur: return "Amatérské turnaje"
        case .settings: return "Nastavení"
        case .search: return "Vyhledávání"
        case .news: return "Novinky"
        case .liveStreams: return "Živé přenosy"
        case .media: return "Dělníci hokejbalu"
        }
    }

    var systemImage: String {
        switch self {
        case .fantasy: return "trophy.fill"
        case .tips: return "target"
        case .amateur: return "flag.checkered"
        case .settings: return "gearshape.fill"
        case .search: return "magnifyingglass"
        case .news: return "newspaper.fill"
        case .liveStreams: return "tv.fill"
        case .media: return "headphones"
        }
    }

    enum Destination {
        case fantasy
        case tips
        case amateur
        case settings
        case search
        case news
        case liveStreams
        case media
    }

    var destination: Destination {
        switch self {
        case .fantasy: return .fantasy
        case .tips: return .tips
        case .amateur: return .amateur
        case .settings: return .settings
        case .search: return .search
        case .news: return .news
        case .liveStreams: return .liveStreams
        case .media: return .media
        }
    }
}

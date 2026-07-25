import SwiftUI

/// Záložka Více.
struct MoreView: View {
    @EnvironmentObject private var tabRouter: AppTabRouter
    @EnvironmentObject private var auth: AuthStore

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 10) {
                            ForEach(MoreMenuItem.primary) { item in
                                moreRow(item)
                            }
                        }

                        Spacer(minLength: 28)

                        VStack(spacing: 10) {
                            moreRow(.profile)
                            moreRow(.settings)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height - 36, alignment: .top)
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
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

        case .profile:
            if auth.isAuthenticated {
                NavigationLink {
                    ProfileView()
                } label: {
                    MoreMenuRowLabel(item: item)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    auth.presentLogin()
                } label: {
                    MoreMenuRowLabel(item: item)
                }
                .buttonStyle(.plain)
            }

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
    @EnvironmentObject private var auth: AuthStore
    let item: MoreMenuItem

    var body: some View {
        HStack(spacing: 14) {
            if item == .profile, auth.isAuthenticated {
                UserAvatarView(profile: auth.profile, size: 28)
            } else {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
                    .frame(width: 28, height: 28)
            }

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
    case search
    case news
    case liveStreams
    case media
    case profile
    case settings

    var id: String { rawValue }

    /// Položky hlavního seznamu — Profil a Nastavení jsou odděleně dole.
    static var primary: [MoreMenuItem] {
        allCases.filter { $0 != .settings && $0 != .profile }
    }

    var title: String {
        switch self {
        case .fantasy: return "Fantasy"
        case .tips: return "Tipovačka"
        case .amateur: return "Amatérské turnaje"
        case .settings: return "Nastavení"
        case .profile: return "Profil"
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
        case .profile: return "person.crop.circle.fill"
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
        case profile
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
        case .profile: return .profile
        case .search: return .search
        case .news: return .news
        case .liveStreams: return .liveStreams
        case .media: return .media
        }
    }
}

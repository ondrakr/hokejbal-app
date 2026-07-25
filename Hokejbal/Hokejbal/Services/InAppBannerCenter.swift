import Foundation
import SwiftUI

enum InAppBannerKind: String, Sendable {
    case goal
    case finalScore

    var title: String {
        switch self {
        case .goal: return "Gól"
        case .finalScore: return "Konec"
        }
    }

    var accent: Color {
        switch self {
        case .goal: return HBTheme.live
        case .finalScore: return HBTheme.brand
        }
    }
}

struct InAppBanner: Identifiable, Equatable, Sendable {
    let id: String
    let kind: InAppBannerKind
    let matchId: String
    let homeTeamId: String
    let awayTeamId: String
    let homeName: String
    let awayName: String
    let homeScore: Int
    let awayScore: Int
    let scoringTeamId: String?
    let createdAt: Date

    static let displayDuration: TimeInterval = 3.8

    var scoreText: String { "\(homeScore):\(awayScore)" }

    var accessibilityText: String {
        "\(kind.title). \(homeName) \(scoreText) \(awayName)."
    }

    var homeScored: Bool {
        kind == .goal && scoringTeamId == homeTeamId
    }

    var awayScored: Bool {
        kind == .goal && scoringTeamId == awayTeamId
    }
}

@MainActor
final class InAppBannerCenter: ObservableObject {
    @Published private(set) var current: InAppBanner?
    /// Signal pro UI: odjet nahoru před odstraněním z hierarchie.
    @Published private(set) var isExiting = false
    @Published var openMatchId: String?

    private var viewingMatchIds: Set<String> = []
    private var queue: [InAppBanner] = []
    private var dismissTask: Task<Void, Never>?

    private static let exitAnimationMs: UInt64 = 280

    func beginViewingMatch(_ matchId: String) {
        viewingMatchIds.insert(matchId)
        if current?.matchId == matchId {
            dismissCurrent()
        }
        queue.removeAll { $0.matchId == matchId }
    }

    func endViewingMatch(_ matchId: String) {
        viewingMatchIds.remove(matchId)
    }

    func isViewingMatch(_ matchId: String) -> Bool {
        viewingMatchIds.contains(matchId)
    }

    func present(
        kind: InAppBannerKind,
        match: Match,
        homeName: String,
        awayName: String,
        scoringTeamId: String? = nil
    ) {
        if isViewingMatch(match.id) { return }

        queue.append(
            InAppBanner(
                id: UUID().uuidString,
                kind: kind,
                matchId: match.id,
                homeTeamId: match.homeTeamId,
                awayTeamId: match.awayTeamId,
                homeName: homeName,
                awayName: awayName,
                homeScore: match.homeScore,
                awayScore: match.awayScore,
                scoringTeamId: scoringTeamId,
                createdAt: Date()
            )
        )
        showNextIfNeeded()
    }

    func tapCurrent() {
        guard let current else { return }
        if current.matchId != "banner-preview" {
            openMatchId = current.matchId
        }
        dismissCurrent()
    }

    /// - Parameter alreadyAnimated: swipe už kapsli odjel — jen odstraň z store.
    func dismissCurrent(alreadyAnimated: Bool = false) {
        guard current != nil, !isExiting else { return }
        dismissTask?.cancel()

        if alreadyAnimated {
            finishDismiss()
            return
        }

        isExiting = true
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Self.exitAnimationMs))
            await MainActor.run { self?.finishDismiss() }
        }
    }

    func consumeOpenMatch() -> String? {
        let id = openMatchId
        openMatchId = nil
        return id
    }

    private func finishDismiss() {
        current = nil
        isExiting = false
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            await MainActor.run { self?.showNextIfNeeded() }
        }
    }

    private func showNextIfNeeded() {
        guard current == nil, !isExiting, let next = queue.first else { return }
        queue.removeFirst()
        current = next
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(InAppBanner.displayDuration))
            await MainActor.run { self?.dismissCurrent() }
        }
    }
}

// MARK: - Overlay (mini kapsle)

struct InAppBannerOverlay: View {
    @EnvironmentObject private var banners: InAppBannerCenter
    @EnvironmentObject private var catalog: CatalogStore

    var body: some View {
        VStack(spacing: 0) {
            if let banner = banners.current {
                CapsuleBannerView(banner: banner)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .id(banner.id)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaPadding(.top)
    }
}

private struct CapsuleBannerView: View {
    @EnvironmentObject private var banners: InAppBannerCenter
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.colorScheme) private var colorScheme

    let banner: InAppBanner

    @State private var revealed = false
    @State private var dragOffsetY: CGFloat = 0
    @GestureState private var isDragging = false

    private var accent: Color {
        banner.kind == .goal ? HBTheme.live : HBTheme.brand
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(banner.kind == .goal ? "GÓL" : "KONEC")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(accent)
                .fixedSize()

            matchLine
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(HBTheme.card, in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).strokeBorder(HBTheme.cardStroke, lineWidth: 1))
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.14),
            radius: 14,
            y: 5
        )
        .frame(maxWidth: .infinity)
        // Celá kapsle (včetně log) jako jedna vrstva — jede shora dolů.
        .compositingGroup()
        .offset(y: (revealed ? 0 : -88) + min(0, dragOffsetY))
        .opacity(revealed ? Double(max(0.15, 1 + dragOffsetY / 120)) : 0)
        .contentShape(Capsule(style: .continuous))
        .highPriorityGesture(swipe)
        .onTapGesture {
            guard !isDragging, abs(dragOffsetY) < 10 else { return }
            banners.tapCurrent()
        }
        .onAppear { playEntrance() }
        .onChange(of: banner.id) { _, _ in
            dragOffsetY = 0
            playEntrance()
        }
        .onChange(of: banners.isExiting) { _, exiting in
            guard exiting else { return }
            playExit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(banner.accessibilityText) Klepnutím otevřeš zápas.")
        .accessibilityAddTraits(.isButton)
    }

    private func playEntrance() {
        revealed = false
        // Jeden tick, ať první layout (loga z cache) stihne před animací.
        Task { @MainActor in
            await Task.yield()
            withAnimation(.spring(response: 0.44, dampingFraction: 0.84)) {
                revealed = true
            }
        }
    }

    private func playExit() {
        withAnimation(.easeIn(duration: 0.26)) {
            revealed = false
            dragOffsetY = 0
        }
    }

    private var matchLine: some View {
        let home = catalog.team(banner.homeTeamId)
        let away = catalog.team(banner.awayTeamId)
        let homeLabel = home?.shortName ?? banner.homeName
        let awayLabel = away?.shortName ?? banner.awayName

        return HStack(spacing: 5) {
            if let home {
                TeamBadge(team: home, size: 18)
            }

            Text(homeLabel)
                .font(.hbMontserrat(size: 12, weight: banner.homeScored ? .bold : .semibold))
                .foregroundStyle(banner.homeScored ? HBTheme.live : HBTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 1) {
                Text("\(banner.homeScore)")
                    .font(.hbNumber(size: 14, weight: .heavy))
                    .foregroundStyle(banner.homeScored ? HBTheme.live : HBTheme.textPrimary)
                    .monospacedDigit()

                Text(":")
                    .font(.hbNumber(size: 14, weight: .heavy))
                    .foregroundStyle(HBTheme.textSecondary)

                Text("\(banner.awayScore)")
                    .font(.hbNumber(size: 14, weight: .heavy))
                    .foregroundStyle(banner.awayScored ? HBTheme.live : HBTheme.textPrimary)
                    .monospacedDigit()
            }
            .fixedSize()

            Text(awayLabel)
                .font(.hbMontserrat(size: 12, weight: banner.awayScored ? .bold : .semibold))
                .foregroundStyle(banner.awayScored ? HBTheme.live : HBTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let away {
                TeamBadge(team: away, size: 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                dragOffsetY = min(0, value.translation.height)
            }
            .onEnded { value in
                let up = -value.translation.height
                let fling = -value.predictedEndTranslation.height
                if up > 28 || fling > 120 {
                    withAnimation(.easeIn(duration: 0.22)) {
                        revealed = false
                        dragOffsetY = -20
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        banners.dismissCurrent(alreadyAnimated: true)
                        dragOffsetY = 0
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.18)) { dragOffsetY = 0 }
                }
            }
    }
}

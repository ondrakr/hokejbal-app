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

    var scoreText: String { "\(homeScore):\(awayScore)" }

    var accessibilityText: String {
        "\(kind.title). \(homeName) \(scoreText) \(awayName)."
    }
}

@MainActor
final class InAppBannerCenter: ObservableObject {
    @Published private(set) var current: InAppBanner?
    @Published var openMatchId: String?

    /// Otevřené detaily zápasů — pro ně neposíláme in-app ani lokální upozornění.
    private var viewingMatchIds: Set<String> = []

    private var queue: [InAppBanner] = []
    private var dismissTask: Task<Void, Never>?

    func beginViewingMatch(_ matchId: String) {
        viewingMatchIds.insert(matchId)
        // Schovej banner, pokud právě ukazujeme ten samý zápas.
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
        guard current != nil else { return }
        openMatchId = current?.matchId
        dismissCurrent()
    }

    func dismissCurrent() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.easeOut(duration: 0.2)) {
            current = nil
        }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            await MainActor.run { self?.showNextIfNeeded() }
        }
    }

    func consumeOpenMatch() -> String? {
        let id = openMatchId
        openMatchId = nil
        return id
    }

    private func showNextIfNeeded() {
        guard current == nil, let next = queue.first else { return }
        queue.removeFirst()
        withAnimation(.easeOut(duration: 0.22)) {
            current = next
        }
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.8))
            await MainActor.run { self?.dismissCurrent() }
        }
    }
}

// MARK: - Overlay

struct InAppBannerOverlay: View {
    @EnvironmentObject private var banners: InAppBannerCenter
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var dragOffsetY: CGFloat = 0
    @GestureState private var isDragging = false

    var body: some View {
        Group {
            if let banner = banners.current {
                card(banner)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .offset(y: min(0, dragOffsetY))
                    .opacity(Double(max(0.2, 1 + dragOffsetY / 110)))
                    // Jedna animace celé karty — bez springu, ať nevyjíždí „po částech“.
                    .transition(.offset(y: -28).combined(with: .opacity))
                    .id(banner.id)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .safeAreaPadding(.top)
        .onChange(of: banners.current?.id) { _, _ in dragOffsetY = 0 }
    }

    private func card(_ banner: InAppBanner) -> some View {
        let home = catalog.team(banner.homeTeamId)
        let away = catalog.team(banner.awayTeamId)
        let scoring = banner.scoringTeamId.flatMap(catalog.team)
            ?? (banner.kind == .goal ? home : nil)

        let swipe = DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                dragOffsetY = min(0, value.translation.height)
            }
            .onEnded { value in
                let up = -value.translation.height
                let fling = -value.predictedEndTranslation.height
                if up > 32 || fling > 130 {
                    withAnimation(.easeIn(duration: 0.15)) { dragOffsetY = -150 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        banners.dismissCurrent()
                        dragOffsetY = 0
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffsetY = 0
                    }
                }
            }

        return HStack(alignment: .center, spacing: 14) {
            leadingLogo(banner: banner, scoring: scoring, home: home, away: away)

            VStack(alignment: .leading, spacing: 5) {
                Text(banner.kind.title.uppercased())
                    .font(.hbMontserrat(size: 12, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(banner.kind == .goal ? HBTheme.live : HBTheme.textTertiary)

                matchRow(banner)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(HBTheme.card, in: RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous)
                .strokeBorder(HBTheme.cardStroke, lineWidth: 0.75)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1),
            radius: 16,
            x: 0,
            y: 6
        )
        .contentShape(RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous))
        .compositingGroup()
        .highPriorityGesture(swipe)
        .onTapGesture {
            guard !isDragging, abs(dragOffsetY) < 10 else { return }
            banners.tapCurrent()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(banner.accessibilityText) Klepnutím otevřeš zápas. Potáhni nahoru pro skrytí.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Skrýt") { banners.dismissCurrent() }
    }

    private func matchRow(_ banner: InAppBanner) -> some View {
        HStack(spacing: 7) {
            Text(banner.homeName)
                .font(.hbMontserrat(
                    size: 16,
                    weight: banner.scoringTeamId == banner.homeTeamId ? .bold : .semibold
                ))
                .foregroundStyle(
                    banner.kind == .goal && banner.scoringTeamId != banner.homeTeamId
                        ? HBTheme.textSecondary
                        : HBTheme.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(banner.scoreText)
                .font(.hbNumber(size: 20, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
                .monospacedDigit()
                .fixedSize()

            Text(banner.awayName)
                .font(.hbMontserrat(
                    size: 16,
                    weight: banner.scoringTeamId == banner.awayTeamId ? .bold : .semibold
                ))
                .foregroundStyle(
                    banner.kind == .goal && banner.scoringTeamId != banner.awayTeamId
                        ? HBTheme.textSecondary
                        : HBTheme.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func leadingLogo(
        banner: InAppBanner,
        scoring: Team?,
        home: Team?,
        away: Team?
    ) -> some View {
        if banner.kind == .goal, let scoring {
            TeamBadge(team: scoring, size: 44)
        } else {
            HStack(spacing: 8) {
                if let home { TeamBadge(team: home, size: 34) }
                if let away { TeamBadge(team: away, size: 34) }
            }
        }
    }
}

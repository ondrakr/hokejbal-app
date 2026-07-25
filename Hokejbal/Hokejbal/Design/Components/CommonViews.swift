import SwiftUI

struct TeamBadge: View {
    let team: Team
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let logoURL = team.logoURL, let url = URL(string: logoURL) {
                HBCachedAsyncImage(url: url) { img in
                    img
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    initials
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(team.name)
    }

    private var initials: some View {
        Text(team.logoInitials)
            .font(.hbMontserrat(size: size * 0.34, weight: .bold))
            .foregroundStyle(Color(hex: team.primaryColorHex))
            .frame(width: size, height: size)
    }
}

/// Profilová fotka hráče s fallbackem na iniciály.
struct PlayerAvatar: View {
    let player: Player
    var size: CGFloat = 48
    var cornerRadius: CGFloat? = nil

    private var radius: CGFloat { cornerRadius ?? size * 0.22 }

    var body: some View {
        Group {
            if let url = player.photoURLValue {
                HBCachedAsyncImage(url: url) { img in
                    img
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        }
        .accessibilityLabel(player.fullName)
    }

    private var placeholder: some View {
        ZStack {
            HBTheme.brand.opacity(0.12)
            Text(initials)
                .font(.hbMontserrat(size: size * 0.32, weight: .bold))
                .foregroundStyle(HBTheme.brand)
        }
    }

    private var initials: String {
        let f = player.firstName.prefix(1).uppercased()
        let l = player.lastName.prefix(1).uppercased()
        return "\(f)\(l)"
    }
}

struct CompetitionBadge: View {
    let competition: Competition
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let logoURL = competition.logoURL, let url = URL(string: logoURL) {
                HBCachedAsyncImage(url: url) { img in
                    img
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    fallback
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(competition.name)
    }

    private var fallback: some View {
        Image("BrandLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Pruh soutěže jako v detailu zápasu: logo + název (+ volitelná fáze), s chevronem.
struct CompetitionNavStrip: View {
    let competition: Competition?
    var phase: String? = nil
    var round: Int? = nil
    var fallbackTitle: String = "SOUTĚŽ"
    var showsChevron: Bool = true

    private var titleText: String {
        var parts: [String] = [(competition?.name ?? fallbackTitle).uppercased()]
        if let phase, !phase.isEmpty {
            parts.append(phase.uppercased())
        }
        if let round {
            parts.append("\(round). KOLO")
        }
        return parts.joined(separator: " – ")
    }

    var body: some View {
        HStack(spacing: 8) {
            if let competition {
                CompetitionBadge(competition: competition, size: 18)
            }
            Text(titleText)
                .font(.hbMontserrat(size: 11, weight: .semibold))
                .foregroundStyle(HBTheme.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HBTheme.secondarySurface)
        .contentShape(Rectangle())
    }
}

struct LiveBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .modifier(PulseModifier())
            Text(compact ? "LIVE" : "ŽIVĚ")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(HBTheme.onBrand)
        .padding(.horizontal, compact ? 8 : 9)
        .padding(.vertical, 4)
        .background(HBTheme.live, in: Capsule())
        .fixedSize()
    }
}

private struct PulseModifier: ViewModifier {
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .opacity(pulse ? 0.35 : 1)
            .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}

struct CategoryTag: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.hbMontserrat(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                HBTheme.categoryColors[title] ?? HBTheme.brand,
                in: RoundedRectangle(cornerRadius: 4, style: .continuous)
            )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
    }
}

/// Ikona hokejbalového míčku (oranžový míček s otvory — ne hokejový puk).
struct HokejbalBallIcon: View {
    var size: CGFloat = 12
    var color: Color = .white

    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let ball = Path(ellipseIn: rect.insetBy(dx: 0.5, dy: 0.5))
            context.fill(ball, with: .color(color))

            // Otvorový vzor typický pro hokejbalový míček
            let holeColor = Color.black.opacity(0.28)
            let holes: [(CGFloat, CGFloat, CGFloat)] = [
                (0.30, 0.28, 0.13),
                (0.68, 0.26, 0.12),
                (0.50, 0.50, 0.14),
                (0.28, 0.70, 0.12),
                (0.70, 0.68, 0.13),
                (0.48, 0.78, 0.10)
            ]
            for (x, y, r) in holes {
                let holeRect = CGRect(
                    x: canvasSize.width * x - canvasSize.width * r,
                    y: canvasSize.height * y - canvasSize.height * r,
                    width: canvasSize.width * r * 2,
                    height: canvasSize.height * r * 2
                )
                context.fill(Path(ellipseIn: holeRect), with: .color(holeColor))
            }

            context.stroke(ball, with: .color(Color.black.opacity(0.2)), lineWidth: max(0.6, size * 0.06))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct SectionHeaderLabel: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.hbSection)
                .foregroundStyle(.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Redesign: signaturní diagonální akcent

/// Šikmý „energetický“ pruh — opakující se brandový motiv (odkaz na pohyb / rychlost).
struct HBAccentBar: View {
    var color: Color = HBTheme.brand
    var width: CGFloat = 5
    var height: CGFloat = 20

    var body: some View {
        color
            .frame(width: width, height: height)
            .clipShape(HBSkew(dx: 4))
    }
}

/// Rovnoběžník (posunuté horní hrany) — používá se pro akcenty a odznaky.
struct HBSkew: Shape {
    var dx: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + dx, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - dx, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Sekční hlavička s diagonálním akcentem + volitelný „Vše“ trailing.
struct HBSectionHeader<Trailing: View, TitleAccessory: View>: View {
    let title: String
    var accent: Color = HBTheme.brand
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var titleAccessory: () -> TitleAccessory

    var body: some View {
        HStack(spacing: 10) {
            HBAccentBar(color: accent, height: 18)
            Text(title.uppercased())
                .font(.hbDisplay(size: 17, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textPrimary)
            titleAccessory()
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, HBTheme.screenPadding)
    }
}

extension HBSectionHeader where Trailing == EmptyView, TitleAccessory == EmptyView {
    init(_ title: String, accent: Color = HBTheme.brand) {
        self.init(title: title, accent: accent, trailing: { EmptyView() }, titleAccessory: { EmptyView() })
    }
}

extension HBSectionHeader where TitleAccessory == EmptyView {
    init(title: String, accent: Color = HBTheme.brand, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(title: title, accent: accent, trailing: trailing, titleAccessory: { EmptyView() })
    }
}

/// Kompaktní stavový odznak zápasu (čas / LIVE / KONEC).
struct HBStatusPill: View {
    let match: Match

    var body: some View {
        switch match.status {
        case .scheduled:
            label(match.scheduledAt.hbTime, color: HBTheme.brand, filled: false)
        case .live:
            LiveBadge(compact: true)
        case .finished:
            label("KONEC", color: HBTheme.textTertiary, filled: false)
        case .postponed:
            label("ODLOŽ.", color: .orange, filled: false)
        }
    }

    private func label(_ text: String, color: Color, filled: Bool) -> some View {
        Text(text)
            .font(.hbMontserrat(size: 11, weight: .bold))
            .tracking(0.3)
            .foregroundStyle(filled ? HBTheme.onBrand : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (filled ? color : color.opacity(0.12)),
                in: Capsule()
            )
    }
}

extension String {
    /// První písmeno velké (zbytek beze změny) — pro česká data.
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (201, 42, 42)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

extension Date {
    var hbDayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Dnes" }
        if cal.isDateInYesterday(self) { return "Včera" }
        if cal.isDateInTomorrow(self) { return "Zítra" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "EEE d. M."
        return f.string(from: self)
    }

    var hbTime: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    var hbShortDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "d. M. yyyy"
        return f.string(from: self)
    }

    /// Datum + čas (pro články / novinky).
    var hbShortDateTime: String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        // U článků z webu často máme jen den — nezobrazuj 00:00.
        if (comps.hour ?? 0) == 0 && (comps.minute ?? 0) == 0 {
            return hbShortDate
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateFormat = "d. M. yyyy · HH:mm"
        return f.string(from: self)
    }
}

// MARK: - Reálné fotky článků

extension NewsArticle {
    /// Preferuje fotku z hokejbal.cz; fallback LoremFlickr.
    private var photoSeed: Int {
        var h = 5381
        for b in id.utf8 { h = ((h << 5) &+ h) &+ Int(b) }
        return abs(h) % 100000
    }

    var photoURL: URL? {
        if let imageURL, let url = URL(string: imageURL) { return url }
        return URL(string: "https://loremflickr.com/800/500/hockey,icehockey,sport/all?lock=\(photoSeed)")
    }

    var webURL: URL? {
        if let articleURL, let url = URL(string: articleURL) { return url }
        return URL(string: "https://www.hokejbal.cz")
    }
}

/// Náhledový obrázek článku: reálná fotka přes AsyncImage, s gradient fallbackem.
struct NewsThumbnail: View {
    let article: NewsArticle
    var showsCategory: Bool = false

    private var gradient: LinearGradient {
        LinearGradient(
            colors: HomeContent.gradients[article.imageGradientIndex % HomeContent.gradients.count],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            gradient
            HBCachedAsyncImage(url: article.photoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } placeholder: {
                Color.clear
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .overlay(alignment: .bottomLeading) {
            if showsCategory {
                CategoryTag(title: article.category)
                    .padding(12)
            }
        }
    }
}

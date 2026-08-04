import SwiftUI

/// FIFA-styl kartička — OVR, fotka, volitelně cena / body / soupeř.
struct FantasyPlayerCard: View {
    let player: Player
    var team: Team?
    var size: FantasyCardSize = .regular
    var showsPrice: Bool = true
    var showsPoints: Bool = false
    var opponentLabel: String? = nil
    /// Zvýrazněná karta (vybraný hráč) — silnější obrys a záře.
    var isSelected: Bool = false
    var isEmpty: Bool = false
    var emptyTitle: String = "Vybrat"
    var emptyPosition: String = "?"
    /// Podklad, na kterém karta leží — mění vzhled prázdného slotu.
    var emptyTone: FantasyEmptyTone = .dark

    private var rating: Int { FantasyRules.rating(for: player) }
    private var tier: FantasyCardTier { FantasyRules.tier(for: rating) }
    private var price: Int { FantasyRules.priceCredits(for: player) }
    private var points: Int { FantasyRules.fantasyPoints(for: player) }

    var body: some View {
        Group {
            if isEmpty {
                emptyCard
            } else {
                filledCard
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var filledCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(LinearGradient(colors: tier.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))

            // Lesk: nahoře světlo, dole stín — dává kartě plasticitu.
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), .clear, Color.black.opacity(0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Šikmý odlesk přes kartu
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.16), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .strokeBorder(tier.accent.opacity(isSelected ? 1 : 0.55), lineWidth: isSelected ? 2 : 1.2)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 4) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(rating)")
                            .font(.system(size: size.ratingFont, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        Text(player.position.cardCode)
                            .font(.system(size: size.metaFont, weight: .bold))
                            .foregroundStyle(tier.accent)
                    }
                    Spacer(minLength: 0)
                    if let team {
                        TeamBadge(team: team, size: size.badge)
                    }
                }
                .padding(.horizontal, size.pad)
                .padding(.top, size.pad)

                Spacer(minLength: 2)

                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: size.avatar, height: size.avatar)
                    PlayerAvatar(player: player, size: size.avatar, cornerRadius: size.avatar / 2)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: size.avatar, height: size.avatar)
                }

                Spacer(minLength: 2)

                Text(player.lastName.uppercased())
                    .font(.system(size: size.nameFont, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)

                footer
                    .padding(.bottom, size.pad)
                    .padding(.top, 2)
            }
        }
        .shadow(color: .black.opacity(isSelected ? 0.4 : 0.28), radius: isSelected ? 12 : 8, y: 4)
    }

    @ViewBuilder
    private var footer: some View {
        if let opponentLabel, !opponentLabel.isEmpty {
            Text(opponentLabel)
                .font(.system(size: size.metaFont, weight: .bold))
                .foregroundStyle(tier.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 3)
        } else if showsPrice || showsPoints {
            HStack(spacing: 4) {
                if showsPrice {
                    Text("\(price) kr")
                        .font(.system(size: size.metaFont, weight: .bold).monospacedDigit())
                }
                if showsPrice && showsPoints {
                    Text("·")
                }
                if showsPoints {
                    Text("\(points)b")
                        .font(.system(size: size.metaFont, weight: .semibold).monospacedDigit())
                }
            }
            .foregroundStyle(tier.accent)
        } else {
            Color.clear.frame(height: 2)
        }
    }

    private var emptyCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(emptyTone.fill)
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(emptyTone.stroke)

            VStack(spacing: 6) {
                Text(emptyPosition)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(emptyTone.badgeForeground)
                    .frame(width: 26, height: 26)
                    .background(emptyTone.badgeBackground, in: Circle())
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(emptyTone.foreground)
                Text(emptyTitle)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(emptyTone.foreground)
            }
        }
    }
}

/// Podklad prázdného slotu — na hřišti světlý na tmavém, v přehledu naopak.
enum FantasyEmptyTone {
    case dark
    case light

    var fill: Color {
        switch self {
        case .dark: return Color.white.opacity(0.1)
        case .light: return HBTheme.cardInset
        }
    }

    var stroke: Color {
        switch self {
        case .dark: return Color.white.opacity(0.35)
        case .light: return HBTheme.separator
        }
    }

    var foreground: Color {
        switch self {
        case .dark: return Color.white.opacity(0.7)
        case .light: return HBTheme.textSecondary
        }
    }

    var badgeForeground: Color {
        switch self {
        case .dark: return Color(red: 1.0, green: 0.84, blue: 0.28)
        case .light: return HBTheme.brand
        }
    }

    var badgeBackground: Color {
        switch self {
        case .dark: return Color(red: 1.0, green: 0.84, blue: 0.28).opacity(0.15)
        case .light: return HBTheme.brand.opacity(0.12)
        }
    }
}

/// Štítek tieru (Bronze / Silver / Gold / Elite) v barvách karty.
struct FantasyTierChip: View {
    let tier: FantasyCardTier

    var body: some View {
        Text(tier.label.uppercased())
            .font(.hbMontserrat(size: 10, weight: .heavy))
            .tracking(0.4)
            .foregroundStyle(tier.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                LinearGradient(colors: tier.gradient, startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
    }
}

enum FantasyCardSize {
    case compact
    case regular
    case large

    var width: CGFloat {
        switch self {
        case .compact: return 78
        case .regular: return 96
        case .large: return 120
        }
    }

    var height: CGFloat {
        switch self {
        case .compact: return 118
        case .regular: return 144
        case .large: return 178
        }
    }

    var corner: CGFloat {
        switch self {
        case .compact: return 10
        case .regular: return 12
        case .large: return 14
        }
    }

    var pad: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 8
        case .large: return 10
        }
    }

    var ratingFont: CGFloat {
        switch self {
        case .compact: return 18
        case .regular: return 22
        case .large: return 28
        }
    }

    var metaFont: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 9
        case .large: return 11
        }
    }

    var nameFont: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 9
        case .large: return 11
        }
    }

    var avatar: CGFloat {
        switch self {
        case .compact: return 36
        case .regular: return 46
        case .large: return 58
        }
    }

    var badge: CGFloat {
        switch self {
        case .compact: return 14
        case .regular: return 18
        case .large: return 22
        }
    }
}

extension PlayerPosition {
    var cardCode: String {
        switch self {
        case .goalie: return "B"
        case .defenseman: return "O"
        case .forward: return "Ú"
        }
    }
}

import SwiftUI

/// FIFA-styl kartička — OVR, fotka, volitelně cena / body / soupeř.
struct FantasyPlayerCard: View {
    let player: Player
    var team: Team?
    var size: FantasyCardSize = .regular
    var showsPrice: Bool = true
    var showsPoints: Bool = false
    var opponentLabel: String? = nil
    var isEmpty: Bool = false
    var emptyTitle: String = "Vybrat"
    var emptyPosition: String = "?"

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

            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), .clear, Color.black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .strokeBorder(tier.accent.opacity(0.55), lineWidth: 1.2)

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
                        .fill(Color.black.opacity(0.22))
                        .frame(width: size.avatar, height: size.avatar)
                    PlayerAvatar(player: player, size: size.avatar, cornerRadius: size.avatar / 2)
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
        .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
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
                .fill(Color.white.opacity(0.12))
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(Color.white.opacity(0.35))

            VStack(spacing: 6) {
                Text(emptyPosition)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.28))
                    .frame(width: 28, height: 28)
                    .background(Color(red: 1.0, green: 0.84, blue: 0.28).opacity(0.15), in: Circle())
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(emptyTitle)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
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

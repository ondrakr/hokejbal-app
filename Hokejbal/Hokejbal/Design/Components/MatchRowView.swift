import SwiftUI

/// Redesign „HB Arena“ — zápas jako elevated karta s barevným akcentem podle stavu.
/// Karta má vlastní vnější okraje, takže funguje edge-to-edge i uvnitř Listu.
struct MatchRowView: View {
    let match: Match
    let home: Team?
    let away: Team?
    var showCompetition: Bool = false
    var competitionName: String? = nil
    /// Vypne vnější okraje (pro použití ve vlastním layoutu detailu).
    var embedded: Bool = false

    private var homeLeads: Bool {
        match.status != .scheduled && match.homeScore > match.awayScore
    }

    private var awayLeads: Bool {
        match.status != .scheduled && match.awayScore > match.homeScore
    }

    private var accentColor: Color {
        switch match.status {
        case .live: return HBTheme.live
        case .scheduled: return HBTheme.brand
        case .finished: return HBTheme.textTertiary.opacity(0.5)
        case .postponed: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            accentColor
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 11) {
                header
                teamRow(team: home, score: match.homeScore, leads: homeLeads)
                teamRow(team: away, score: match.awayScore, leads: awayLeads)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
        .hbCard(cornerRadius: HBTheme.radiusMd)
        .padding(.horizontal, embedded ? 0 : HBTheme.screenPadding)
        .padding(.vertical, embedded ? 0 : 5)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(spacing: 6) {
            if showCompetition, let competitionName {
                Text(competitionName.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(HBTheme.textTertiary)
                    .lineLimit(1)
            } else if match.status == .live {
                Text(shortPeriod)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(HBTheme.live)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if match.isBroadcast {
                Image(systemName: "tv")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
                    .accessibilityLabel("Živé vysílání")
            }
            HBStatusPill(match: match)
        }
    }

    private func teamRow(team: Team?, score: Int, leads: Bool) -> some View {
        HStack(spacing: 10) {
            if let team {
                TeamBadge(team: team, size: 24)
                    .frame(width: 26, height: 26)
                Text(team.shortName)
                    .font(.hbMontserrat(size: 15, weight: leads ? .bold : .medium))
                    .foregroundStyle(leads ? HBTheme.textPrimary : HBTheme.textPrimary.opacity(0.82))
                    .lineLimit(1)
            } else {
                Text("—")
                    .font(.hbMontserrat(size: 15, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }

            Spacer(minLength: 8)

            if match.status != .scheduled {
                Text("\(score)")
                    .font(.hbNumber(size: 20, weight: leads ? .heavy : .semibold))
                    .foregroundStyle(scoreColor(leads: leads))
                    .frame(minWidth: 24, alignment: .trailing)
            }
        }
    }

    private func scoreColor(leads: Bool) -> Color {
        if match.status == .live {
            return leads ? HBTheme.live : HBTheme.textSecondary
        }
        return leads ? HBTheme.textPrimary : HBTheme.textSecondary
    }

    /// Kompaktní popisek třetiny.
    private var shortPeriod: String {
        switch match.period {
        case .first: return "1. TŘETINA"
        case .second: return "2. TŘETINA"
        case .third: return "3. TŘETINA"
        case .overtime: return "PRODLOUŽENÍ"
        case .shootout: return "NÁJEZDY"
        case .intermission: return "PŘESTÁVKA"
        case .finished: return "KONEC"
        case .notStarted: return ""
        }
    }
}

struct MatchCardView: View {
    let match: Match
    let home: Team?
    let away: Team?

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                if match.isLive {
                    LiveBadge()
                } else {
                    Text(match.status == .finished ? "Výsledek" : match.scheduledAt.hbDayLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HBTheme.textSecondary)
                }
                Spacer()
                Text(match.venue)
                    .font(.caption)
                    .foregroundStyle(HBTheme.textTertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 16) {
                teamBlock(home)
                scoreBlock
                teamBlock(away)
            }
        }
        .padding(16)
        .background(HBTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func teamBlock(_ team: Team?) -> some View {
        VStack(spacing: 8) {
            if let team {
                TeamBadge(team: team, size: 48)
                Text(team.shortName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var scoreBlock: some View {
        VStack(spacing: 4) {
            if match.status == .scheduled {
                Text(match.scheduledAt.hbTime)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(HBTheme.textPrimary)
            } else {
                Text(match.scoreText)
                    .font(.hbScore)
                    .monospacedDigit()
                    .foregroundStyle(match.isLive ? HBTheme.live : HBTheme.textPrimary)
            }
            if match.isLive {
                Text(match.period.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HBTheme.live)
            }
        }
    }
}

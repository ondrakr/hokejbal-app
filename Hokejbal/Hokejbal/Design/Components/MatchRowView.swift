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
        case .finished: return HBTheme.brand.opacity(0.35)
        case .postponed: return .orange
        }
    }

    var body: some View {
        let inner = HStack(spacing: 0) {
            accentColor
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 11) {
                if hasHeaderContent { header }

                switch match.status {
                case .scheduled:
                    scheduledBody
                case .live, .finished, .postponed:
                    teamRow(team: home, score: match.homeScore, leads: homeLeads)
                    teamRow(team: away, score: match.awayScore, leads: awayLeads)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }

        if embedded {
            // Bez vlastní karty — vykresluje se uvnitř nadřazené karty.
            inner.contentShape(Rectangle())
        } else {
            inner
                .clipShape(RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous))
                .hbCard(cornerRadius: HBTheme.radiusMd)
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
        }
    }

    private var hasHeaderContent: Bool {
        match.status == .scheduled
            || match.status == .live
            || match.status == .finished
            || match.status == .postponed
            || (showCompetition && competitionName != nil)
            || match.isBroadcast
    }

    private var header: some View {
        HStack(spacing: 6) {
            headerLeading
            Spacer(minLength: 8)
            if match.isBroadcast {
                broadcastIcon
            }
            if match.status == .live || match.status == .finished || match.status == .postponed {
                scoreStatusLabel
            }
        }
    }

    @ViewBuilder
    private var headerLeading: some View {
        switch match.status {
        case .finished:
            Text("\(match.scheduledAt.hbShortDate) | \(match.scheduledAt.hbTime)")
                .font(.hbMontserrat(size: 10, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(HBTheme.textTertiary)
                .lineLimit(1)
        case .scheduled:
            Text(match.scheduledAt.hbShortDate)
                .font(.hbMontserrat(size: 10, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(HBTheme.textTertiary)
                .lineLimit(1)
        case .live:
            if showCompetition, let competitionName {
                Text(competitionName.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(HBTheme.textTertiary)
                    .lineLimit(1)
            } else {
                Text(shortPeriod)
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(HBTheme.live)
                    .lineLimit(1)
            }
        default:
            if showCompetition, let competitionName {
                Text(competitionName.uppercased())
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(HBTheme.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private var broadcastIcon: some View {
        Image(systemName: "tv")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(HBTheme.brand)
            .accessibilityLabel("Živé vysílání")
    }

    /// Naplánovaný zápas: týmy vlevo, výrazný čas vpravo.
    private var scheduledBody: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 9) {
                teamNameRow(home, emphasized: false)
                teamNameRow(away, emphasized: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(match.scheduledAt.hbTime)
                .font(.hbNumber(size: 22, weight: .heavy))
                .foregroundStyle(HBTheme.brand)
                .frame(minWidth: 56, alignment: .trailing)
                .fixedSize()
        }
    }

    /// Live / výsledek: řádek týmu se skóre vpravo.
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

            Text("\(score)")
                .font(.hbNumber(size: 20, weight: leads ? .heavy : .semibold))
                .foregroundStyle(scoreColor(leads: leads))
                .frame(minWidth: 28, alignment: .trailing)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var scoreStatusLabel: some View {
        switch match.status {
        case .live:
            LiveBadge(compact: true)
        case .finished:
            Text("KONEC")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(HBTheme.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(HBTheme.textTertiary.opacity(0.12), in: Capsule())
        case .postponed:
            HBStatusPill(match: match)
        case .scheduled:
            EmptyView()
        }
    }

    private func teamNameRow(_ team: Team?, emphasized: Bool) -> some View {
        HStack(spacing: 10) {
            if let team {
                TeamBadge(team: team, size: 24)
                    .frame(width: 26, height: 26)
                Text(team.shortName)
                    .font(.hbMontserrat(size: 15, weight: emphasized ? .bold : .semibold))
                    .foregroundStyle(emphasized ? HBTheme.textPrimary : HBTheme.textPrimary.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } else {
                Text("—")
                    .font(.hbMontserrat(size: 15, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
            Spacer(minLength: 0)
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

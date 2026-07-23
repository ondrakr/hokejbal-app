import SwiftUI

/// Livesport-style řádek zápasu:
/// malé logo + název týmu | vpravo čas NEBO skóre (bez kurzů).
struct MatchRowView: View {
    let match: Match
    let home: Team?
    let away: Team?
    var showCompetition: Bool = false
    var competitionName: String? = nil

    private var homeLeads: Bool {
        match.status != .scheduled && match.homeScore > match.awayScore
    }

    private var awayLeads: Bool {
        match.status != .scheduled && match.awayScore > match.homeScore
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    if showCompetition, let competitionName {
                        Text(competitionName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HBTheme.textTertiary)
                            .lineLimit(1)
                    }
                    teamRow(team: home, emphasize: homeLeads)
                    teamRow(team: away, emphasize: awayLeads)
                }

                Spacer(minLength: 8)

                if match.isBroadcast {
                    Image(systemName: "tv")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                        .accessibilityLabel("Živé vysílání")
                }

                trailingColumn
            }
            .padding(.vertical, 10)
            .padding(.horizontal, HBTheme.screenPadding)

            Rectangle()
                .fill(HBTheme.separator)
                .frame(height: 0.5)
        }
        .background(HBTheme.surface)
        .contentShape(Rectangle())
    }

    private func teamRow(team: Team?, emphasize: Bool) -> some View {
        HStack(spacing: 8) {
            if let team {
                TeamBadge(team: team, size: 18)
                Text(team.shortName)
                    .font(.system(size: 14, weight: emphasize ? .bold : .regular))
                    .foregroundStyle(emphasize ? HBTheme.textPrimary : HBTheme.textPrimary.opacity(0.85))
                    .lineLimit(1)
            } else {
                Text("—")
                    .font(.system(size: 14))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var trailingColumn: some View {
        switch match.status {
        case .scheduled:
            Text(match.scheduledAt.hbTime)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(HBTheme.textPrimary)
                .frame(minWidth: 44, alignment: .trailing)

        case .live:
            HStack(alignment: .center, spacing: 10) {
                VStack(spacing: 2) {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HBTheme.live)
                    Text(shortPeriod)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(HBTheme.live)
                        .lineLimit(1)
                }
                .frame(minWidth: 36, alignment: .trailing)

                VStack(alignment: .trailing, spacing: 7) {
                    scoreText(match.homeScore, emphasize: homeLeads, live: true)
                    scoreText(match.awayScore, emphasize: awayLeads, live: true)
                }
                .frame(minWidth: 22, alignment: .trailing)
            }

        case .finished:
            HStack(alignment: .center, spacing: 10) {
                Text("Konec")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
                    .frame(minWidth: 36, alignment: .trailing)

                VStack(alignment: .trailing, spacing: 7) {
                    scoreText(match.homeScore, emphasize: homeLeads, live: false)
                    scoreText(match.awayScore, emphasize: awayLeads, live: false)
                }
                .frame(minWidth: 22, alignment: .trailing)
            }

        case .postponed:
            Text("Odlož.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    private func scoreText(_ score: Int, emphasize: Bool, live: Bool) -> some View {
        Text("\(score)")
            .font(.system(size: 14, weight: emphasize ? .bold : .semibold).monospacedDigit())
            .foregroundStyle(
                live
                    ? (emphasize ? HBTheme.live : HBTheme.textSecondary)
                    : (emphasize ? HBTheme.textPrimary : HBTheme.textSecondary)
            )
    }

    /// Kompaktní popisek třetiny pro úzký sloupec vpravo.
    private var shortPeriod: String {
        switch match.period {
        case .first: return "1. tř."
        case .second: return "2. tř."
        case .third: return "3. tř."
        case .overtime: return "Prodl."
        case .shootout: return "Náj."
        case .intermission: return "Přest."
        case .finished: return "Konec"
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

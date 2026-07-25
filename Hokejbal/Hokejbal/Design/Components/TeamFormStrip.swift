import SwiftUI

/// Výsledek jednoho zápasu z pohledu konkrétního týmu (pro form strip).
enum TeamFormOutcome: Hashable, Sendable {
    case win
    case draw
    case loss

    var letter: String {
        switch self {
        case .win: return "V"
        case .draw: return "R"
        case .loss: return "P"
        }
    }

    var color: Color {
        switch self {
        case .win: return HBTheme.win
        case .draw: return HBTheme.draw
        case .loss: return HBTheme.loss
        }
    }
}

struct TeamFormItem: Identifiable, Hashable, Sendable {
    let id: String
    let outcome: TeamFormOutcome
}

enum TeamFormCalculator {
    /// Posledních `limit` ukončených zápasů (nejstarší vlevo → nejnovější vpravo).
    static func items(from matches: [Match], teamId: String, excludingMatchId: String? = nil, limit: Int = 5) -> [TeamFormItem] {
        let finished = matches
            .filter { $0.status == .finished }
            .filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
            .filter { excludingMatchId == nil || $0.id != excludingMatchId }
            .sorted { $0.scheduledAt > $1.scheduledAt }
            .prefix(limit)

        return finished.reversed().map { match in
            TeamFormItem(id: match.id, outcome: outcome(for: match, teamId: teamId))
        }
    }

    static func outcome(for match: Match, teamId: String) -> TeamFormOutcome {
        if match.homeScore == match.awayScore { return .draw }
        let isHome = match.homeTeamId == teamId
        let focus = isHome ? match.homeScore : match.awayScore
        let other = isHome ? match.awayScore : match.homeScore
        return focus > other ? .win : .loss
    }
}

/// Řada V/R/P badge (forma týmu).
struct TeamFormBadges: View {
    let items: [TeamFormItem]
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 4) {
            if items.isEmpty {
                Text("—")
                    .font(.hbMontserrat(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            } else {
                ForEach(items) { item in
                    Text(item.outcome.letter)
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: size, height: size)
                        .background(
                            item.outcome.color,
                            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                        )
                        .accessibilityLabel(accessibilityLabel(for: item.outcome))
                }
            }
        }
    }

    private func accessibilityLabel(for outcome: TeamFormOutcome) -> String {
        switch outcome {
        case .win: return "Výhra"
        case .draw: return "Remíza"
        case .loss: return "Prohra"
        }
    }
}

/// Forma jednoho týmu: logo + název + V/R/P.
struct TeamFormRow: View {
    let team: Team?
    let items: [TeamFormItem]
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            if let team {
                TeamBadge(team: team, size: compact ? 22 : 26)
                Text(team.shortName)
                    .font(.hbMontserrat(size: compact ? 13 : 14, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                    .lineLimit(1)
            } else {
                Text("—")
                    .font(.hbMontserrat(size: 14, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }

            Spacer(minLength: 8)

            TeamFormBadges(items: items, size: compact ? 20 : 22)
        }
    }
}

/// Blok „Forma“ pro přehled naplánovaného zápasu (oba týmy).
struct MatchFormPreview: View {
    let home: Team?
    let away: Team?
    let homeForm: [TeamFormItem]
    let awayForm: [TeamFormItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORMA")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(HBTheme.textTertiary)

            VStack(spacing: 10) {
                TeamFormRow(team: home, items: homeForm)
                TeamFormRow(team: away, items: awayForm)
            }
            .padding(12)
            .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))
        }
    }
}

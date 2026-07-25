import Foundation

enum PlayerStatMetric: String, CaseIterable, Hashable, Sendable {
    case points, goals, assists, pim, ppg, shg

    var title: String {
        switch self {
        case .points: return "Kanadské body"
        case .goals: return "Góly"
        case .assists: return "Asistence"
        case .pim: return "Trestné minuty"
        case .ppg: return "Góly v přesilovce"
        case .shg: return "Góly v oslabení"
        }
    }

    var unit: String {
        switch self {
        case .points: return "KB"
        case .goals: return "G"
        case .assists: return "A"
        case .pim: return "TM"
        case .ppg: return "PPG"
        case .shg: return "SHG"
        }
    }
}

enum TeamStatMetric: String, CaseIterable, Hashable, Sendable {
    case gf, ga, ppPct, pkPct, ppg, shg, ppa, sha, ppCount, shCount, wins, losses

    var title: String {
        switch self {
        case .gf: return "Počet vstřelených gólů"
        case .ga: return "Počet inkasovaných gólů"
        case .ppPct: return "Využité přesilovky"
        case .pkPct: return "Ubráněná oslabení"
        case .ppg: return "Počet gólů v přesilovce"
        case .shg: return "Počet gólů v oslabení"
        case .ppa: return "Počet ink. gólů v přesilovce"
        case .sha: return "Počet ink. gólů v oslabení"
        case .ppCount: return "Počet přesilovek"
        case .shCount: return "Počet oslabení"
        case .wins: return "Počet výher"
        case .losses: return "Počet proher"
        }
    }

    var unit: String {
        switch self {
        case .gf, .ga, .ppg, .shg, .ppa, .sha: return "G"
        case .ppPct, .pkPct: return "%"
        case .ppCount, .shCount, .wins, .losses: return ""
        }
    }

    var lowerIsBetter: Bool {
        switch self {
        case .ga, .ppa, .sha: return true
        default: return false
        }
    }
}

struct PlayerStatRow: Identifiable, Hashable {
    var id: String { player.id }
    let player: Player
    let team: Team?
    let value: Double
    let display: String
    let unit: String
}

struct TeamStatRow: Identifiable, Hashable {
    var id: String { team.id }
    let team: Team
    let value: Double
    let display: String
    let unit: String
}

struct PlayerStatLeaderCardModel: Identifiable {
    var id: String { metric.rawValue }
    let metric: PlayerStatMetric
    let title: String
    let leader: PlayerStatRow?
}

struct TeamStatLeaderCardModel: Identifiable {
    var id: String { metric.rawValue }
    let metric: TeamStatMetric
    let title: String
    let leader: TeamStatRow?
}

enum CompetitionStats {

    private struct TeamAgg {
        var ppGoals = 0
        var shGoals = 0
        var ppAgainst = 0
        var shAgainst = 0
        var ppCount = 0
        var shCount = 0
    }

    private static func playerPpg(_ p: Player) -> Int {
        max(0, Int((Double(p.goals) * 0.28).rounded()))
    }

    private static func playerShg(_ p: Player) -> Int {
        max(0, min(p.goals, Int(Double(p.goals) * 0.08) + (p.points > 15 ? 1 : 0)))
    }

    private static func formatValue(_ value: Double, unit: String) -> String {
        if unit == "%" {
            let rounded = (value * 100).rounded() / 100
            if rounded == rounded.rounded(.towardZero) {
                return String(format: "%.0f%%", rounded)
            }
            return String(format: "%.2f%%", rounded)
        }
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded(.towardZero) {
            return String(Int(rounded))
        }
        return String(format: "%.2f", rounded)
    }

    static func playerValue(_ p: Player, metric: PlayerStatMetric) -> Double {
        switch metric {
        case .points: return Double(p.points)
        case .goals: return Double(p.goals)
        case .assists: return Double(p.assists)
        case .pim: return Double(p.penaltyMinutes)
        case .ppg: return Double(playerPpg(p))
        case .shg: return Double(playerShg(p))
        }
    }

    static func rankPlayers(
        _ players: [Player],
        teamById: (String) -> Team?,
        metric: PlayerStatMetric
    ) -> [PlayerStatRow] {
        players
            .map { player in
                let value = playerValue(player, metric: metric)
                return PlayerStatRow(
                    player: player,
                    team: teamById(player.teamId),
                    value: value,
                    display: formatValue(value, unit: metric.unit),
                    unit: metric.unit
                )
            }
            .filter { $0.value > 0 || metric == .pim }
            .sorted {
                if $0.value != $1.value { return $0.value > $1.value }
                return $0.player.fullName.localizedCompare($1.player.fullName) == .orderedAscending
            }
    }

    private static func aggregateTeams(_ matches: [Match]) -> [String: TeamAgg] {
        var map: [String: TeamAgg] = [:]
        func bump(_ teamId: String) -> TeamAgg {
            map[teamId] ?? TeamAgg()
        }

        for m in matches {
            guard m.status == .finished || m.status == .live else { continue }
            let homePP = m.homePowerplayGoals ?? 0
            let awayPP = m.awayPowerplayGoals ?? 0
            let homeSH = m.homeShorthandedGoals ?? 0
            let awaySH = m.awayShorthandedGoals ?? 0

            var home = bump(m.homeTeamId)
            var away = bump(m.awayTeamId)

            home.ppGoals += homePP
            home.shGoals += homeSH
            home.ppAgainst += awayPP
            home.shAgainst += awaySH
            home.ppCount += max(homePP + 2, 3)
            home.shCount += max(awayPP + 2, 3)

            away.ppGoals += awayPP
            away.shGoals += awaySH
            away.ppAgainst += homePP
            away.shAgainst += homeSH
            away.ppCount += max(awayPP + 2, 3)
            away.shCount += max(homePP + 2, 3)

            map[m.homeTeamId] = home
            map[m.awayTeamId] = away
        }
        return map
    }

    private static func teamValue(
        standing: StandingRow?,
        agg: TeamAgg?,
        metric: TeamStatMetric
    ) -> Double {
        switch metric {
        case .gf: return Double(standing?.goalsFor ?? 0)
        case .ga: return Double(standing?.goalsAgainst ?? 0)
        case .wins: return Double(standing?.wins ?? 0)
        case .losses: return Double(standing?.losses ?? 0)
        case .ppg: return Double(agg?.ppGoals ?? 0)
        case .shg: return Double(agg?.shGoals ?? 0)
        case .ppa: return Double(agg?.ppAgainst ?? 0)
        case .sha: return Double(agg?.shAgainst ?? 0)
        case .ppCount: return Double(agg?.ppCount ?? 0)
        case .shCount: return Double(agg?.shCount ?? 0)
        case .ppPct:
            let chances = Double(agg?.ppCount ?? 0)
            let goals = Double(agg?.ppGoals ?? 0)
            guard chances > 0 else { return 0 }
            return (goals / chances) * 100
        case .pkPct:
            let times = Double(agg?.shCount ?? 0)
            let against = Double(agg?.ppAgainst ?? 0)
            guard times > 0 else { return 100 }
            return max(0, ((times - against) / times) * 100)
        }
    }

    static func rankTeams(
        standings: [StandingRow],
        matches: [Match],
        teamById: (String) -> Team?,
        metric: TeamStatMetric
    ) -> [TeamStatRow] {
        let agg = aggregateTeams(matches)
        var rows: [TeamStatRow] = []

        for s in standings {
            guard let team = teamById(s.teamId) else { continue }
            let value = teamValue(standing: s, agg: agg[s.teamId], metric: metric)
            rows.append(
                TeamStatRow(
                    team: team,
                    value: value,
                    display: formatValue(value, unit: metric.unit),
                    unit: metric.unit
                )
            )
        }

        if rows.isEmpty {
            for (teamId, a) in agg {
                guard let team = teamById(teamId) else { continue }
                let value = teamValue(standing: nil, agg: a, metric: metric)
                rows.append(
                    TeamStatRow(
                        team: team,
                        value: value,
                        display: formatValue(value, unit: metric.unit),
                        unit: metric.unit
                    )
                )
            }
        }

        rows.sort {
            if $0.value != $1.value {
                return metric.lowerIsBetter ? $0.value < $1.value : $0.value > $1.value
            }
            return $0.team.name.localizedCompare($1.team.name) == .orderedAscending
        }
        return rows
    }

    static func playerLeaderCards(
        players: [Player],
        teamById: (String) -> Team?
    ) -> [PlayerStatLeaderCardModel] {
        PlayerStatMetric.allCases.map { metric in
            let ranked = rankPlayers(players, teamById: teamById, metric: metric)
            return PlayerStatLeaderCardModel(
                metric: metric,
                title: metric.title,
                leader: ranked.first
            )
        }
    }

    static func teamLeaderCards(
        standings: [StandingRow],
        matches: [Match],
        teamById: (String) -> Team?
    ) -> [TeamStatLeaderCardModel] {
        TeamStatMetric.allCases.map { metric in
            let ranked = rankTeams(
                standings: standings,
                matches: matches,
                teamById: teamById,
                metric: metric
            )
            return TeamStatLeaderCardModel(
                metric: metric,
                title: metric.title,
                leader: ranked.first
            )
        }
    }
}

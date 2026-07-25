import Foundation

enum StandingsScope: String, CaseIterable, Hashable {
    case live = "Live"
    case total = "Celkem"
    case home = "Doma"
    case away = "Venku"
    case form = "Forma"
}

enum FormWindow: String, CaseIterable, Hashable {
    case five = "5 zápasů"
    case ten = "10 zápasů"
    case fifteen = "15 zápasů"

    var count: Int {
        switch self {
        case .five: return 5
        case .ten: return 10
        case .fifteen: return 15
        }
    }
}

enum LiveScoreTone: Hashable {
    case win, draw, loss
}

struct LiveScoreBadge: Hashable {
    let text: String
    let tone: LiveScoreTone
}

struct StandingViewRow: Identifiable, Hashable {
    var id: String
    let teamId: String
    var rank: Int
    var played: Int
    var wins: Int
    var draws: Int
    var losses: Int
    var goalsFor: Int
    var goalsAgainst: Int
    var points: Int
    var liveScore: LiveScoreBadge?
    /// Posun pořadí oproti oficiální tabulce (+ nahoru).
    var rankDelta: Int = 0

    var scoreText: String {
        "\(goalsFor):\(goalsAgainst)"
    }

    init(from row: StandingRow, liveScore: LiveScoreBadge? = nil) {
        self.id = row.id
        self.teamId = row.teamId
        self.rank = row.rank
        self.played = row.played
        self.wins = row.wins
        self.draws = 0
        self.losses = row.losses
        self.goalsFor = row.goalsFor
        self.goalsAgainst = row.goalsAgainst
        self.points = row.points
        self.liveScore = liveScore
        self.rankDelta = 0
    }

    init(
        id: String,
        teamId: String,
        rank: Int,
        played: Int,
        wins: Int,
        draws: Int,
        losses: Int,
        goalsFor: Int,
        goalsAgainst: Int,
        points: Int,
        liveScore: LiveScoreBadge? = nil,
        rankDelta: Int = 0
    ) {
        self.id = id
        self.teamId = teamId
        self.rank = rank
        self.played = played
        self.wins = wins
        self.draws = draws
        self.losses = losses
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.points = points
        self.liveScore = liveScore
        self.rankDelta = rankDelta
    }
}

enum StandingsCompute {
    private struct Agg {
        var teamId: String
        var played = 0
        var wins = 0
        var draws = 0
        var losses = 0
        var goalsFor = 0
        var goalsAgainst = 0
        var points = 0
    }

    static func hasLive(matches: [Match], competitionId: String) -> Bool {
        matches.contains { $0.competitionId == competitionId && $0.status == .live }
    }

    static func build(
        base: [StandingRow],
        matches: [Match],
        competitionId: String,
        scope: StandingsScope,
        formWindow: FormWindow
    ) -> [StandingViewRow] {
        guard !base.isEmpty else { return [] }
        switch scope {
        case .total:
            return base.map { StandingViewRow(from: $0) }
        case .home:
            return aggregateSide(base: base, matches: matches, competitionId: competitionId, home: true)
        case .away:
            return aggregateSide(base: base, matches: matches, competitionId: competitionId, home: false)
        case .form:
            return aggregateForm(base: base, matches: matches, competitionId: competitionId, window: formWindow.count)
        case .live:
            return aggregateLive(base: base, matches: matches, competitionId: competitionId)
        }
    }

    private static func competitionMatches(_ matches: [Match], _ competitionId: String) -> [Match] {
        matches.filter { $0.competitionId == competitionId }
    }

    private static func apply(_ agg: inout Agg, gf: Int, ga: Int) {
        agg.played += 1
        agg.goalsFor += gf
        agg.goalsAgainst += ga
        if gf > ga {
            agg.wins += 1
            agg.points += 3
        } else if gf < ga {
            agg.losses += 1
        } else {
            agg.draws += 1
            agg.points += 1
        }
    }

    private static func sortAndRank(_ aggs: [Agg]) -> [StandingViewRow] {
        let sorted = aggs.sorted {
            if $0.points != $1.points { return $0.points > $1.points }
            let d0 = $0.goalsFor - $0.goalsAgainst
            let d1 = $1.goalsFor - $1.goalsAgainst
            if d0 != d1 { return d0 > d1 }
            if $0.goalsFor != $1.goalsFor { return $0.goalsFor > $1.goalsFor }
            return $0.teamId.localizedCompare($1.teamId) == .orderedAscending
        }
        return sorted.enumerated().map { i, row in
            StandingViewRow(
                id: "view-\(row.teamId)",
                teamId: row.teamId,
                rank: i + 1,
                played: row.played,
                wins: row.wins,
                draws: row.draws,
                losses: row.losses,
                goalsFor: row.goalsFor,
                goalsAgainst: row.goalsAgainst,
                points: row.points
            )
        }
    }

    private static func aggregateSide(
        base: [StandingRow],
        matches: [Match],
        competitionId: String,
        home: Bool
    ) -> [StandingViewRow] {
        var map: [String: Agg] = [:]
        for row in base { map[row.teamId] = Agg(teamId: row.teamId) }

        for m in competitionMatches(matches, competitionId) where m.status == .finished {
            if home {
                var agg = map[m.homeTeamId] ?? Agg(teamId: m.homeTeamId)
                apply(&agg, gf: m.homeScore, ga: m.awayScore)
                map[m.homeTeamId] = agg
            } else {
                var agg = map[m.awayTeamId] ?? Agg(teamId: m.awayTeamId)
                apply(&agg, gf: m.awayScore, ga: m.homeScore)
                map[m.awayTeamId] = agg
            }
        }
        return sortAndRank(Array(map.values))
    }

    private static func aggregateForm(
        base: [StandingRow],
        matches: [Match],
        competitionId: String,
        window: Int
    ) -> [StandingViewRow] {
        var map: [String: Agg] = [:]
        for row in base { map[row.teamId] = Agg(teamId: row.teamId) }

        let finished = competitionMatches(matches, competitionId)
            .filter { $0.status == .finished }
            .sorted { $0.scheduledAt > $1.scheduledAt }

        for teamId in map.keys {
            let recent = finished
                .filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
                .prefix(window)
            var agg = map[teamId]!
            for m in recent {
                let isHome = m.homeTeamId == teamId
                apply(
                    &agg,
                    gf: isHome ? m.homeScore : m.awayScore,
                    ga: isHome ? m.awayScore : m.homeScore
                )
            }
            map[teamId] = agg
        }
        return sortAndRank(Array(map.values))
    }

    private static func aggregateLive(
        base: [StandingRow],
        matches: [Match],
        competitionId: String
    ) -> [StandingViewRow] {
        let live = competitionMatches(matches, competitionId).filter { $0.status == .live }
        var scores: [String: LiveScoreBadge] = [:]
        var delta: [String: Agg] = [:]

        func bump(teamId: String, gf: Int, ga: Int) {
            var agg = delta[teamId] ?? Agg(teamId: teamId)
            apply(&agg, gf: gf, ga: ga)
            delta[teamId] = agg
        }

        for m in live {
            let hs = m.homeScore
            let ascore = m.awayScore
            if hs == ascore {
                bump(teamId: m.homeTeamId, gf: hs, ga: ascore)
                bump(teamId: m.awayTeamId, gf: ascore, ga: hs)
                scores[m.homeTeamId] = LiveScoreBadge(text: "\(hs):\(ascore)", tone: .draw)
                scores[m.awayTeamId] = LiveScoreBadge(text: "\(ascore):\(hs)", tone: .draw)
            } else if hs > ascore {
                bump(teamId: m.homeTeamId, gf: hs, ga: ascore)
                bump(teamId: m.awayTeamId, gf: ascore, ga: hs)
                scores[m.homeTeamId] = LiveScoreBadge(text: "\(hs):\(ascore)", tone: .win)
                scores[m.awayTeamId] = LiveScoreBadge(text: "\(ascore):\(hs)", tone: .loss)
            } else {
                bump(teamId: m.awayTeamId, gf: ascore, ga: hs)
                bump(teamId: m.homeTeamId, gf: hs, ga: ascore)
                scores[m.awayTeamId] = LiveScoreBadge(text: "\(ascore):\(hs)", tone: .win)
                scores[m.homeTeamId] = LiveScoreBadge(text: "\(hs):\(ascore)", tone: .loss)
            }
        }

        let baseRank = Dictionary(uniqueKeysWithValues: base.map { ($0.teamId, $0.rank) })

        var rows = base.map { row -> StandingViewRow in
            let d = delta[row.teamId]
            return StandingViewRow(
                id: "live-\(row.teamId)",
                teamId: row.teamId,
                rank: row.rank,
                played: row.played + (d?.played ?? 0),
                wins: row.wins + (d?.wins ?? 0),
                draws: d?.draws ?? 0,
                losses: row.losses + (d?.losses ?? 0),
                goalsFor: row.goalsFor + (d?.goalsFor ?? 0),
                goalsAgainst: row.goalsAgainst + (d?.goalsAgainst ?? 0),
                points: row.points + (d?.points ?? 0),
                liveScore: scores[row.teamId]
            )
        }

        rows.sort {
            if $0.points != $1.points { return $0.points > $1.points }
            let d0 = $0.goalsFor - $0.goalsAgainst
            let d1 = $1.goalsFor - $1.goalsAgainst
            if d0 != d1 { return d0 > d1 }
            if $0.goalsFor != $1.goalsFor { return $0.goalsFor > $1.goalsFor }
            return $0.teamId.localizedCompare($1.teamId) == .orderedAscending
        }

        for i in rows.indices {
            let rank = i + 1
            rows[i].rank = rank
            let prev = baseRank[rows[i].teamId] ?? rank
            rows[i].rankDelta = prev - rank
        }
        return rows
    }
}

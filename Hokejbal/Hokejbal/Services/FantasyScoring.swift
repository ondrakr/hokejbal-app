import Foundation

/// Bodování tipu skóre — port z `hokejbal-fantasy/packages/shared/src/scoring.ts`.
/// Drží se stejných pravidel jako původní tipovačka MS 2026.
///
/// | Trefa | Body |
/// |---|---|
/// | Přesný výsledek | 5 |
/// | Správný vítěz + gólový rozdíl | 3 |
/// | Správný vítěz / remíza | 2 |
/// | Špatný vítěz, ale sedí góly jednoho týmu | 1 |
/// | Jinak | 0 |
/// + bonus 2 za správně tipnuté prodloužení / nájezdy.
enum FantasyScoring {
    static let exact = 5
    static let goalDiff = 3
    static let winner = 2
    static let partial = 1
    static let miss = 0
    static let overtimeBonus = 2

    /// Tip skóre lze zadat/měnit jen do začátku zápasu (parita s tipem vítěze).
    static let lockMinutesBeforeStart = 0

    enum Outcome { case home, away, draw }

    static func outcome(home: Int, away: Int) -> Outcome {
        if home == away { return .draw }
        return home > away ? .home : .away
    }

    /// Základní body tipu proti výsledku (bez bonusu za prodloužení).
    static func basePoints(predHome: Int, predAway: Int, resHome: Int, resAway: Int) -> Int {
        if predHome == resHome && predAway == resAway {
            return exact
        }
        let predOutcome = outcome(home: predHome, away: predAway)
        let resOutcome = outcome(home: resHome, away: resAway)
        if predOutcome != resOutcome {
            // dílčí bod: aspoň jeden tým přesně
            if predHome == resHome || predAway == resAway { return partial }
            return miss
        }
        let sameDiff = (predHome - predAway) == (resHome - resAway)
        return sameDiff ? goalDiff : winner
    }

    /// Celkové body včetně bonusu za prodloužení/nájezdy.
    static func scorePoints(
        predHome: Int,
        predAway: Int,
        resHome: Int,
        resAway: Int,
        predictedOvertime: Bool,
        decidedInOvertime: Bool
    ) -> Int {
        var points = basePoints(predHome: predHome, predAway: predAway, resHome: resHome, resAway: resAway)
        let sameWinner = outcome(home: predHome, away: predAway) == outcome(home: resHome, away: resAway)
        if predictedOvertime, decidedInOvertime, sameWinner {
            points += overtimeBonus
        }
        return points
    }

    /// „Po prodloužení/nájezdech" jde tipnout jen u 1gólového rozdílu.
    static func canPredictOvertime(predHome: Int, predAway: Int) -> Bool {
        abs(predHome - predAway) == 1
    }

    /// Uzamčeno `lockMinutesBeforeStart` minut před začátkem.
    static func isLocked(startsAt: Date, now: Date = Date()) -> Bool {
        let lockAt = startsAt.addingTimeInterval(-Double(lockMinutesBeforeStart) * 60)
        return now >= lockAt
    }
}

extension Match {
    /// Rozhodl zápas prodloužení nebo nájezdy? (víc než 3 třetiny ve skóre,
    /// nebo perioda overtime/shootout).
    var decidedInOvertime: Bool {
        if period == .overtime || period == .shootout { return true }
        return homePeriodScores.count > 3 || awayPeriodScores.count > 3
    }
}

import Foundation

/// Scoring rules for exact-score match predictions.
///
/// Ported 1:1 from the standalone tipping app
/// (`hokejbal-fantasy/packages/shared/src/scoring.ts`) so points keep the same
/// meaning and stay comparable across seasons.
///
/// ## Points table
///
/// | Hit | Points |
/// |---|---|
/// | Exact score | 5 |
/// | Correct winner + goal difference | 3 |
/// | Correct winner (or draw) | 2 |
/// | Wrong winner, but one team's goals are right | 1 |
/// | Nothing | 0 |
///
/// Plus a **+2 bonus** for correctly calling overtime or a shootout.
///
/// ## Examples
///
/// Actual result 4:2:
/// - `4:2` → 5 pts (exact)
/// - `3:1` → 3 pts (home won, difference of 2 matches)
/// - `5:1` → 2 pts (home won, but difference is off)
/// - `1:2` → 1 pt (wrong winner, but away really scored 2)
/// - `0:3` → 0 pts
///
/// ## Where it is used
///
/// `MatchTipStore.resolveScoreTips(matches:)` once a match is over; the result
/// is stored in `MatchScoreTip.pointsAwarded` and counted into the leaderboard.
///
/// - Note: Evaluated against the **final** score. The original tipping app used
///   the score after regulation time, but our data layer has no such field —
///   overtime is instead handled by the bonus below. In practice a `4:3` tip on
///   a game decided in overtime scores 5 pts (+2 with the bonus), not 3.
enum FantasyScoring {
    /// Points for a fully exact prediction (both numbers match).
    static let exact = 5
    /// Points for the correct winner **and** the correct goal difference.
    static let goalDiff = 3
    /// Points for the correct winner (difference is off).
    static let winner = 2
    /// Consolation point for guessing one team's goals despite the wrong winner.
    static let partial = 1
    /// Complete miss.
    static let miss = 0
    /// Extra points when the player called overtime/shootout and it happened.
    static let overtimeBonus = 2

    /// How many minutes before puck drop predictions lock.
    ///
    /// - Warning: Zero means predictions are open right up to the start time,
    ///   matching the winner tip (`MatchTipStore.canTip(_:)`). The original app
    ///   used 30 minutes.
    static let lockMinutesBeforeStart = 0

    /// How a match (or a prediction) turned out, seen from the home side.
    enum Outcome {
        /// Home team won.
        case home
        /// Away team won.
        case away
        /// Draw.
        case draw
    }

    /// Determines the winner from a score.
    ///
    /// - Parameters:
    ///   - home: Home goals.
    ///   - away: Away goals.
    /// - Returns: The winning side, or `.draw` when the scores are level.
    static func outcome(home: Int, away: Int) -> Outcome {
        if home == away { return .draw }
        return home > away ? .home : .away
    }

    /// Points for a prediction, without the overtime bonus.
    ///
    /// Walks the points table top down: exact hit first, then the correct
    /// winner (with or without the goal difference), and finally the
    /// consolation point for getting one team's goals right.
    ///
    /// - Parameters:
    ///   - predHome: Predicted home goals.
    ///   - predAway: Predicted away goals.
    ///   - resHome: Actual home goals.
    ///   - resAway: Actual away goals.
    /// - Returns: 0, 1, 2, 3 or 5 points.
    static func basePoints(predHome: Int, predAway: Int, resHome: Int, resAway: Int) -> Int {
        if predHome == resHome && predAway == resAway {
            return exact
        }
        let predOutcome = outcome(home: predHome, away: predAway)
        let resOutcome = outcome(home: resHome, away: resAway)
        if predOutcome != resOutcome {
            // partial credit: at least one team's goals are exact
            if predHome == resHome || predAway == resAway { return partial }
            return miss
        }
        let sameDiff = (predHome - predAway) == (resHome - resAway)
        return sameDiff ? goalDiff : winner
    }

    /// Final points for a prediction, including the overtime bonus.
    ///
    /// The bonus only applies when **all three** hold: the player called
    /// overtime, the match really ended there, and the player also got the
    /// winner right. Without the last condition the bonus could be farmed by
    /// ticking the box blindly.
    ///
    /// - Parameters:
    ///   - predHome: Predicted home goals.
    ///   - predAway: Predicted away goals.
    ///   - resHome: Actual home goals.
    ///   - resAway: Actual away goals.
    ///   - predictedOvertime: Player ticked "decided in overtime/shootout".
    ///   - decidedInOvertime: The match really was decided there
    ///     (see `Match.decidedInOvertime`).
    /// - Returns: 0–7 points (max = exact 5 + bonus 2).
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

    /// Should the "decided in overtime/shootout" toggle be offered?
    ///
    /// Only at a one-goal margin — overtime and shootouts always end one goal
    /// apart, so the toggle would make no sense on a `5:2` prediction. The UI
    /// hides it accordingly (`MatchTipCard.scoreSection`).
    ///
    /// - Parameters:
    ///   - predHome: Predicted home goals.
    ///   - predAway: Predicted away goals.
    /// - Returns: `true` when the margin is exactly one goal.
    static func canPredictOvertime(predHome: Int, predAway: Int) -> Bool {
        abs(predHome - predAway) == 1
    }

    /// Is predicting on this match already closed?
    ///
    /// - Parameters:
    ///   - startsAt: Scheduled start of the match.
    ///   - now: Point in time to check against (injectable for tests).
    /// - Returns: `true` when the prediction can no longer be placed or changed.
    static func isLocked(startsAt: Date, now: Date = Date()) -> Bool {
        let lockAt = startsAt.addingTimeInterval(-Double(lockMinutesBeforeStart) * 60)
        return now >= lockAt
    }
}

extension Match {
    /// Was the match decided in overtime or a shootout?
    ///
    /// There is no explicit flag in the data layer, so it is inferred two ways:
    /// from the currently running period, and for finished matches from the
    /// number of recorded periods (regulation has three — anything beyond that
    /// is overtime or a shootout).
    ///
    /// Feeds the bonus in `FantasyScoring.scorePoints(…)`.
    var decidedInOvertime: Bool {
        if period == .overtime || period == .shootout { return true }
        return homePeriodScores.count > 3 || awayPeriodScores.count > 3
    }
}

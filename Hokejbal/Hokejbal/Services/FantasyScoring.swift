import Foundation

/// Bodování tipu na přesné skóre zápasu.
///
/// Pravidla jsou převzatá 1:1 z původní samostatné tipovačky
/// (`hokejbal-fantasy/packages/shared/src/scoring.ts`), aby body znamenaly
/// totéž co dřív a šlo je případně porovnávat napříč sezónami.
///
/// ## Bodová tabulka
///
/// | Trefa | Body |
/// |---|---|
/// | Přesný výsledek | 5 |
/// | Správný vítěz + gólový rozdíl | 3 |
/// | Správný vítěz (nebo remíza) | 2 |
/// | Špatný vítěz, ale sedí góly jednoho týmu | 1 |
/// | Nic z toho | 0 |
///
/// K tomu **bonus +2** za správně tipnuté prodloužení / nájezdy.
///
/// ## Příklady
///
/// Skutečný výsledek 4:2:
/// - tip `4:2` → 5 b (přesně)
/// - tip `3:1` → 3 b (vyhráli domácí, rozdíl 2 sedí)
/// - tip `5:1` → 2 b (vyhráli domácí, ale rozdíl nesedí)
/// - tip `1:2` → 1 b (špatný vítěz, ale hosté dali opravdu 2)
/// - tip `0:3` → 0 b
///
/// ## Kde se to používá
///
/// `MatchTipStore.resolveScoreTips(matches:)` po dohrání zápasu, výsledek se
/// ukládá do `MatchScoreTip.pointsAwarded` a sčítá do žebříčku.
///
/// - Note: Vyhodnocuje se proti **finálnímu** skóre zápasu. Původní tipovačka
///   MS používala skóre po 60 minutách, ale to naše datová vrstva nemá —
///   prodloužení proto řeší až bonus níž. Prakticky to znamená, že tip `4:3`
///   na zápas rozhodnutý v prodloužení dá 5 b (+2 s bonusem), ne 3 b.
enum FantasyScoring {
    /// Body za úplně přesný tip (obě čísla sedí).
    static let exact = 5
    /// Body za správného vítěze **a** správný gólový rozdíl.
    static let goalDiff = 3
    /// Body za správného vítěze (rozdíl nesedí).
    static let winner = 2
    /// Útěcha za trefený počet gólů jednoho týmu, i když vítěz je špatně.
    static let partial = 1
    /// Úplná mimo.
    static let miss = 0
    /// Bonus navrch, když hráč označil prodloužení/nájezdy a opravdu nastaly.
    static let overtimeBonus = 2

    /// Kolik minut před výkopem se tipy zamykají.
    ///
    /// - Warning: Nula = tipovat jde až do začátku zápasu. Držíme tím paritu
    ///   s tipem vítěze (`MatchTipStore.canTip(_:)`); původní appka měla 30 minut.
    static let lockMinutesBeforeStart = 0

    /// Jak zápas (nebo tip) dopadl z pohledu domácích.
    enum Outcome {
        /// Vyhráli domácí.
        case home
        /// Vyhráli hosté.
        case away
        /// Remíza.
        case draw
    }

    /// Určí vítěze ze skóre.
    ///
    /// - Parameters:
    ///   - home: Góly domácích.
    ///   - away: Góly hostů.
    /// - Returns: Kdo vyhrál, nebo `.draw` při shodě.
    static func outcome(home: Int, away: Int) -> Outcome {
        if home == away { return .draw }
        return home > away ? .home : .away
    }

    /// Body za tip bez bonusu za prodloužení.
    ///
    /// Postupuje odshora dolů podle bodové tabulky v popisu typu: nejdřív
    /// přesná trefa, pak správný vítěz (s rozdílem / bez), a nakonec útěcha
    /// za trefený počet gólů jednoho týmu.
    ///
    /// - Parameters:
    ///   - predHome: Tipnuté góly domácích.
    ///   - predAway: Tipnuté góly hostů.
    ///   - resHome: Skutečné góly domácích.
    ///   - resAway: Skutečné góly hostů.
    /// - Returns: 0, 1, 2, 3 nebo 5 bodů.
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

    /// Konečné body za tip včetně bonusu za prodloužení/nájezdy.
    ///
    /// Bonus se přičte jen při splnění **všech tří** podmínek: hráč označil
    /// prodloužení, zápas v něm opravdu skončil, a hráč zároveň trefil vítěze.
    /// Bez poslední podmínky by se dal bonus vyfarmit tipem naslepo.
    ///
    /// - Parameters:
    ///   - predHome: Tipnuté góly domácích.
    ///   - predAway: Tipnuté góly hostů.
    ///   - resHome: Skutečné góly domácích.
    ///   - resAway: Skutečné góly hostů.
    ///   - predictedOvertime: Hráč zaškrtl „po prodloužení / nájezdech".
    ///   - decidedInOvertime: Zápas skutečně skončil v prodloužení nebo nájezdech
    ///     (viz `Match.decidedInOvertime`).
    /// - Returns: 0–7 bodů (max = přesný tip 5 + bonus 2).
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

    /// Smí se u tohoto tipu nabídnout přepínač „po prodloužení / nájezdech"?
    ///
    /// Jen u jednogólového rozdílu — prodloužení i nájezdy vždycky končí
    /// rozdílem jednoho gólu, takže u tipu `5:2` by přepínač neměl smysl.
    /// UI podle toho přepínač skrývá (`MatchTipCard.scoreSection`).
    ///
    /// - Parameters:
    ///   - predHome: Tipnuté góly domácích.
    ///   - predAway: Tipnuté góly hostů.
    /// - Returns: `true`, když je rozdíl přesně jeden gól.
    static func canPredictOvertime(predHome: Int, predAway: Int) -> Bool {
        abs(predHome - predAway) == 1
    }

    /// Je tipování na tento zápas už uzavřené?
    ///
    /// - Parameters:
    ///   - startsAt: Plánovaný začátek zápasu.
    ///   - now: Čas, ke kterému se ptáme (kvůli testovatelnosti).
    /// - Returns: `true`, když už tip nejde zadat ani změnit.
    static func isLocked(startsAt: Date, now: Date = Date()) -> Bool {
        let lockAt = startsAt.addingTimeInterval(-Double(lockMinutesBeforeStart) * 60)
        return now >= lockAt
    }
}

extension Match {
    /// Rozhodlo o zápasu prodloužení nebo nájezdy?
    ///
    /// Datová vrstva nemá explicitní příznak, odvozujeme ho tedy dvěma způsoby:
    /// z právě běžící periody, a u dohraných zápasů z počtu zapsaných třetin
    /// (základní hrací doba má tři — cokoli navíc je prodloužení či nájezdy).
    ///
    /// Používá se jako podklad pro bonus ve `FantasyScoring.scorePoints(…)`.
    var decidedInOvertime: Bool {
        if period == .overtime || period == .shootout { return true }
        return homePeriodScores.count > 3 || awayPeriodScores.count > 3
    }
}

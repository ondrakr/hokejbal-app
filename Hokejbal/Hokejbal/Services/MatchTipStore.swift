import Foundation
import SwiftUI

/// Na koho hráč vsadil v tipu vítěze. Remíza se netipuje.
enum MatchTipPick: String, Codable, Hashable, Sendable {
    case home
    case away

    /// Popisek pro UI.
    var label: String {
        switch self {
        case .home: return "Domácí"
        case .away: return "Hosté"
        }
    }
}

/// Tip na vítěze zápasu — na rozdíl od tipu skóre **veřejný**.
///
/// Z těchto tipů se počítají procenta favorita komunity, která vidí každý.
struct MatchTip: Codable, Hashable, Sendable {
    /// Zápas, ke kterému tip patří.
    var matchId: String
    /// Na koho hráč vsadil.
    var pick: MatchTipPick
    /// Kdy tip vznikl.
    var createdAt: Date
    /// Zápas už skončil a tip je vyhodnocený.
    var resolved: Bool
    /// Trefil hráč vítěze? Platné až po vyhodnocení.
    var isCorrect: Bool?
    /// Získané body (3 za trefu, jinak 0).
    var pointsAwarded: Int
}

/// Tip na přesné skóre zápasu — na rozdíl od tipu vítěze **soukromý**.
///
/// Cizí tipy nikdo nevidí (hlídá to i RLS na tabulce `match_score_tips`);
/// ven jde jen součet bodů do žebříčku. Body počítá `FantasyScoring`.
struct MatchScoreTip: Codable, Hashable, Sendable {
    /// Zápas, ke kterému tip patří.
    var matchId: String
    /// Tipnuté góly domácích.
    var homeScore: Int
    /// Tipnuté góly hostů.
    var awayScore: Int
    /// Hráč označil, že zápas skončí v prodloužení nebo na nájezdy.
    var predictedOvertime: Bool
    /// Zápas už skončil a body jsou spočítané.
    var resolved: Bool
    /// Získané body (platné až když `resolved == true`).
    var pointsAwarded: Int
}

/// Rozložení tipů komunity na jeden zápas — podklad pro pruh „kdo je favorit".
struct MatchTipVotes: Codable, Hashable, Sendable {
    /// Zápas, kterého se hlasování týká.
    var matchId: String
    /// Kolik lidí tipuje domácí.
    var homeCount: Int
    /// Kolik lidí tipuje hosty.
    var awayCount: Int

    /// Celkem hlasů; minimálně 1, aby se nedělilo nulou.
    var total: Int { max(1, homeCount + awayCount) }
    /// Podíl tipů na domácí v procentech.
    var homePercent: Int { Int((Double(homeCount) / Double(total) * 100).rounded()) }
    /// Zbytek do sta procent — ať se pruh vždy sečte přesně.
    var awayPercent: Int { max(0, 100 - homePercent) }
}

/// Řádek žebříčku tipujících.
struct TipLeaderboardEntry: Identifiable, Hashable, Sendable {
    /// ID uživatele (nebo bota v demo režimu).
    let id: String
    /// Jméno zobrazené v žebříčku.
    let name: String
    /// Celkem bodů — tipy vítěze i skóre dohromady.
    let points: Int
    /// Kolik tipů vyšlo.
    let correct: Int
    /// Kolik tipů bylo celkem vyhodnoceno.
    let total: Int
    /// Jde o přihlášeného uživatele? (Řádek se pak v UI zvýrazní.)
    let isCurrentUser: Bool

    /// Úspěšnost v procentech.
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}

@MainActor
/// Stav tipovačky jednoho uživatele.
///
/// Spravuje dva druhy tipů na zápasy Extraligy:
/// - **tip vítěze** — veřejný, sčítá se do procent favorita komunity
/// - **tip skóre** — soukromý, nikdo cizí ho nevidí, jen přináší body
///
/// Tipy se ukládají lokálně a po přihlášení i na server. Po dohrání zápasu
/// se vyhodnotí (`resolve(matches:)`, `resolveScoreTips(matches:)`) a body
/// se sečtou do žebříčku.
final class MatchTipStore: ObservableObject {
    /// Body za správně tipnutého vítěze.
    static let pointsPerCorrectTip = 3
    /// Soutěž, na kterou se tipuje.
    static let competitionSlug = "extraliga"

    /// Přezdívka v žebříčku.
    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    /// Moje tipy vítěze podle ID zápasu.
    @Published private(set) var tips: [String: MatchTip] = [:] {
        didSet { persistTips() }
    }

    /// Rozložení tipů komunity podle ID zápasu.
    @Published private(set) var votes: [String: MatchTipVotes] = [:] {
        didSet { persistVotes() }
    }

    /// Tipy přesného skóre (soukromé) — klíč = matchId.
    @Published private(set) var scoreTips: [String: MatchScoreTip] = [:] {
        didSet { persistScoreTips() }
    }

    /// Vymyšlení soupeři pro demo žebříček, dokud nejsou data ze serveru.
    @Published private(set) var botEntries: [TipLeaderboardEntry] = []

    /// Reálný žebříček ze serveru (tip_leaderboard). Prázdný = fallback na boty.
    @Published private(set) var remoteLeaderboard: [TipLeaderboardEntry] = []

    private let defaults = UserDefaults.standard
    private let userId = "local-user"

    /// Klíče v `UserDefaults`.
    private enum Keys {
        static let displayName = "hb.tips.v1.name"
        static let tips = "hb.tips.v1.tips"
        static let votes = "hb.tips.v1.votes"
        static let bots = "hb.tips.v1.bots"
        static let scoreTips = "hb.tips.v1.scoreTips"
    }

    init() {
        displayName = defaults.string(forKey: Keys.displayName) ?? "Tipér"
        tips = Self.loadTips(from: defaults)
        votes = Self.loadVotes(from: defaults)
        scoreTips = Self.loadScoreTips(from: defaults)
        botEntries = Self.loadBots(from: defaults)
        if botEntries.isEmpty {
            botEntries = Self.makeBots()
            persistBots()
        }
    }

    // MARK: - Rules

    /// Jde o zápas Extraligy? Na ostatní soutěže se netipuje.
    func isExtraliga(_ match: Match, competitions: [Competition]) -> Bool {
        if let comp = competitions.first(where: { $0.id == match.competitionId }) {
            return comp.slug == Self.competitionSlug
        }
        return match.competitionId.contains("extraliga")
    }

    /// Dá se na zápas ještě tipovat? (Jen naplánovaný a před výkopem.)
    func canTip(_ match: Match) -> Bool {
        match.status == .scheduled && Date() < match.scheduledAt
    }

    /// Můj tip vítěze na daný zápas.
    func tip(for matchId: String) -> MatchTip? { tips[matchId] }

    /// Read-only — nikdy nemutuje při čtení z View body.
    func votes(for matchId: String) -> MatchTipVotes {
        votes[matchId] ?? seedVotes(matchId: matchId)
    }

    /// Seed komunitních hlasů — volat z onAppear / placeTip, ne z body.
    func ensureVotes(matchId: String) {
        if votes[matchId] == nil {
            votes[matchId] = seedVotes(matchId: matchId)
        }
        Task { await refreshVotesFromRemote(matchId: matchId) }
    }

    /// Dotáhne počty tipů komunity ze serveru.
    ///
    /// Bere maximum z lokálního odhadu a serveru, aby pruh neposkočil dolů,
    /// než se nasbírají skutečné tipy.
    func refreshVotesFromRemote(matchId: String) async {
        guard let auth = AuthAccess.store else { return }
        do {
            let remote = try await auth.authAPI.fetchTipVotes(matchId: matchId)
            let seed = seedVotes(matchId: matchId)
            votes[matchId] = MatchTipVotes(
                matchId: matchId,
                homeCount: max(seed.homeCount, remote.home),
                awayCount: max(seed.awayCount, remote.away)
            )
        } catch { /* keep local */ }
    }

    /// Stáhne moje tipy vítěze ze serveru; lokální nechává být.
    func syncMyTipsFromRemote() async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let rows = try await auth.authAPI.fetchMyTips(userId: userId, accessToken: token)
            for row in rows {
                guard let pick = MatchTipPick(rawValue: row.pick) else { continue }
                if tips[row.matchId] == nil {
                    tips[row.matchId] = MatchTip(
                        matchId: row.matchId,
                        pick: pick,
                        createdAt: row.createdAt ?? Date(),
                        resolved: false,
                        isCorrect: nil,
                        pointsAwarded: 0
                    )
                }
            }
            if let name = auth.profile?.username, !name.isEmpty {
                displayName = name
            }
        } catch { /* soft */ }
    }

    /// Uloží nebo změní tip na vítěze zápasu.
    ///
    /// Kromě uložení tipu přepočítá i hlasy komunity — při změně tipu se
    /// starý hlas odečte a nový přičte, takže procenta sedí.
    ///
    /// - Parameters:
    ///   - match: Zápas, na který se tipuje.
    ///   - pick: Domácí, nebo hosté.
    ///   - competitions: Katalog soutěží (ověření Extraligy).
    /// - Returns: `nil` při úspěchu, jinak hlášku pro uživatele.
    @discardableResult
    func placeTip(match: Match, pick: MatchTipPick, competitions: [Competition]) -> String? {
        guard FantasyMock.enabled || AuthAccess.store?.isAuthenticated == true else {
            AuthAccess.store?.presentLogin()
            return "Pro tipování se musíš přihlásit."
        }
        guard isExtraliga(match, competitions: competitions) else {
            return "Tipovat lze jen zápasy Extraligy."
        }
        guard canTip(match) else {
            return "Tipování je uzavřené (zápas už začal)."
        }

        ensureVotes(matchId: match.id)
        var tally = votes[match.id]!

        if let existing = tips[match.id] {
            if existing.pick == pick { return nil }
            // přesun hlasu
            if existing.pick == .home { tally.homeCount = max(0, tally.homeCount - 1) }
            else { tally.awayCount = max(0, tally.awayCount - 1) }
        }

        if pick == .home { tally.homeCount += 1 }
        else { tally.awayCount += 1 }
        votes[match.id] = tally

        tips[match.id] = MatchTip(
            matchId: match.id,
            pick: pick,
            createdAt: Date(),
            resolved: false,
            isCorrect: nil,
            pointsAwarded: 0
        )

        Task { await pushTipToRemote(matchId: match.id, pick: pick) }
        return nil
    }

    /// Odešle tip vítěze na server a osvěží počty hlasů.
    private func pushTipToRemote(matchId: String, pick: MatchTipPick) async {
        guard let auth = AuthAccess.store, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertTip(
                userId: userId,
                matchId: matchId,
                pick: pick.rawValue,
                accessToken: token
            )
            await refreshVotesFromRemote(matchId: matchId)
        } catch { /* soft */ }
    }

    // MARK: - Tip skóre (soukromý)

    /// Můj tip skóre na daný zápas.
    ///
    /// - Parameter matchId: ID zápasu.
    /// - Returns: Tip, nebo `nil`, když jsem na zápas skóre netipoval.
    func scoreTip(for matchId: String) -> MatchScoreTip? { scoreTips[matchId] }

    /// Uloží nebo přepíše tip na přesné skóre.
    ///
    /// Kontroluje, že jde o zápas Extraligy, že ještě nezačal a že je uživatel
    /// přihlášený (v demo režimu se přihlášení nevyžaduje). Skóre ořízne na
    /// 0–30 gólů a příznak prodloužení zahodí, pokud tip nemá jednogólový
    /// rozdíl. Po uložení se tip odešle na server.
    ///
    /// - Parameters:
    ///   - match: Zápas, na který se tipuje.
    ///   - home: Tipnuté góly domácích.
    ///   - away: Tipnuté góly hostů.
    ///   - overtime: Hráč označil prodloužení / nájezdy.
    ///   - competitions: Katalog soutěží (kvůli ověření, že jde o Extraligu).
    /// - Returns: `nil` při úspěchu, jinak hlášku pro uživatele, proč tip neprošel.
    @discardableResult
    func placeScoreTip(match: Match, home: Int, away: Int, overtime: Bool, competitions: [Competition]) -> String? {
        guard FantasyMock.enabled || AuthAccess.store?.isAuthenticated == true else {
            AuthAccess.store?.presentLogin()
            return "Pro tipování se musíš přihlásit."
        }
        guard isExtraliga(match, competitions: competitions) else {
            return "Tipovat lze jen zápasy Extraligy."
        }
        guard canTip(match) else {
            return "Tipování je uzavřené (zápas už začal)."
        }
        let h = max(0, min(30, home))
        let a = max(0, min(30, away))
        let ot = overtime && FantasyScoring.canPredictOvertime(predHome: h, predAway: a)
        scoreTips[match.id] = MatchScoreTip(
            matchId: match.id, homeScore: h, awayScore: a,
            predictedOvertime: ot, resolved: false, pointsAwarded: 0
        )
        Task { await pushScoreTip(matchId: match.id) }
        return nil
    }

    /// Spočítá body u tipů skóre na zápasy, které už skončily.
    ///
    /// Každý tip vyhodnotí jen jednou (`resolved`), takže se body nesčítají
    /// opakovaně. Výsledek se zapíše i na server.
    ///
    /// - Parameter matches: Zápasy ke kontrole; nedohrané se ignorují.
    func resolveScoreTips(matches: [Match]) {
        var changed = false
        for match in matches where match.status == .finished {
            guard var tip = scoreTips[match.id], !tip.resolved else { continue }
            tip.pointsAwarded = FantasyScoring.scorePoints(
                predHome: tip.homeScore, predAway: tip.awayScore,
                resHome: match.homeScore, resAway: match.awayScore,
                predictedOvertime: tip.predictedOvertime,
                decidedInOvertime: match.decidedInOvertime
            )
            tip.resolved = true
            scoreTips[match.id] = tip
            changed = true
            Task { await pushScoreTip(matchId: match.id) }
        }
        if changed { objectWillChange.send() }
    }

    /// Odešle tip skóre na server (vytvoří, nebo přepíše ten stávající).
    ///
    /// - Parameter matchId: Zápas, jehož tip se odesílá.
    private func pushScoreTip(matchId: String) async {
        guard let auth = AuthAccess.store, let userId = auth.userId, let tip = scoreTips[matchId] else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertScoreTip(
                userId: userId, matchId: matchId,
                homeScore: tip.homeScore, awayScore: tip.awayScore,
                predictedOvertime: tip.predictedOvertime,
                pointsAwarded: tip.resolved ? tip.pointsAwarded : nil,
                accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Stáhne moje tipy skóre ze serveru (např. po přeinstalaci appky).
    ///
    /// Lokální tipy nechává být — přebírá jen ty, které na zařízení chybí,
    /// aby nepřepsal rozdělanou práci. V demo režimu nedělá nic.
    func syncScoreTipsFromRemote() async {
        guard !FantasyMock.enabled else { return }
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let rows = try await auth.authAPI.fetchMyScoreTips(userId: userId, accessToken: token)
            for row in rows where scoreTips[row.matchId] == nil {
                scoreTips[row.matchId] = MatchScoreTip(
                    matchId: row.matchId, homeScore: row.homeScore, awayScore: row.awayScore,
                    predictedOvertime: row.predictedOvertime,
                    resolved: row.pointsAwarded != nil,
                    pointsAwarded: row.pointsAwarded ?? 0
                )
            }
        } catch { /* soft */ }
    }

    // MARK: - Reálný žebříček

    /// Načte společný žebříček tipujících.
    ///
    /// Pohled `tip_leaderboard` sčítá body z tipů vítěze i skóre dohromady,
    /// ale nevydává jednotlivé tipy — soukromí zůstává zachované. Když se
    /// načtení nepovede (nebo běží demo režim), UI ukáže lokální demo s boty.
    func loadLeaderboard() async {
        guard !FantasyMock.enabled else { return }
        guard let api = AuthAccess.store?.authAPI else { return }
        do {
            let rows = try await api.fetchTipLeaderboard()
            let myId = AuthAccess.store?.userId
            remoteLeaderboard = rows.map { row in
                TipLeaderboardEntry(
                    id: row.userId,
                    name: row.displayName ?? row.username ?? "Tipér",
                    points: row.totalPoints,
                    correct: 0,
                    total: row.tipsCount ?? 0,
                    isCurrentUser: row.userId == myId
                )
            }
        } catch { /* soft */ }
    }

    /// Zapíše body za tip vítěze na server (podklad pro žebříček).
    ///
    /// - Parameter matchId: Zápas, jehož tip byl právě vyhodnocen.
    private func pushWinnerPoints(matchId: String) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId,
              let tip = tips[matchId], tip.resolved else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.setWinnerTipPoints(
                userId: userId, matchId: matchId, points: tip.pointsAwarded, accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Vyhodnotí tipy vítěze u zápasů, které skončily.
    ///
    /// Remíza se počítá jako netrefený tip (vítěz se netipoval). Každý tip
    /// se vyhodnotí jen jednou a výsledek se odešle na server.
    ///
    /// - Parameter matches: Zápasy ke kontrole; nedohrané se ignorují.
    func resolve(matches: [Match]) {
        var changed = false
        for match in matches where match.status == .finished {
            guard var tip = tips[match.id], !tip.resolved else { continue }
            guard match.homeScore != match.awayScore else {
                tip.resolved = true
                tip.isCorrect = false
                tip.pointsAwarded = 0
                tips[match.id] = tip
                changed = true
                Task { await pushWinnerPoints(matchId: match.id) }
                continue
            }
            let winner: MatchTipPick = match.homeScore > match.awayScore ? .home : .away
            let correct = tip.pick == winner
            tip.resolved = true
            tip.isCorrect = correct
            tip.pointsAwarded = correct ? Self.pointsPerCorrectTip : 0
            tips[match.id] = tip
            changed = true
            Task { await pushWinnerPoints(matchId: match.id) }
        }
        if changed { objectWillChange.send() }
    }

    // MARK: - Stats / leaderboard

    /// Všechny moje tipy vítěze.
    var myTips: [MatchTip] { Array(tips.values) }

    /// Počet zadaných tipů vítěze.
    var totalTips: Int { tips.count }
    /// Počet už vyhodnocených tipů.
    var resolvedTips: Int { tips.values.filter(\.resolved).count }
    /// Počet trefených tipů.
    var correctTips: Int { tips.values.filter { $0.isCorrect == true }.count }
    /// Tipy čekající na dohrání zápasu.
    var openTips: Int { tips.values.filter { !$0.resolved }.count }
    /// Body jen z tipů vítěze.
    var seasonPoints: Int { tips.values.reduce(0) { $0 + $1.pointsAwarded } }

    /// Body nasbírané jen z tipů na přesné skóre.
    var scoreTipPoints: Int { scoreTips.values.reduce(0) { $0 + $1.pointsAwarded } }

    /// Celkové body do žebříčku — tipy vítěze i skóre dohromady.
    var combinedPoints: Int { seasonPoints + scoreTipPoints }

    /// Počet tipů skóre, které čekají na dohrání zápasu.
    var openScoreTips: Int { scoreTips.values.filter { !$0.resolved }.count }

    /// Úspěšnost tipů vítěze v procentech.
    var accuracy: Double {
        guard resolvedTips > 0 else { return 0 }
        return Double(correctTips) / Double(resolvedTips) * 100
    }

    /// Můj řádek do žebříčku, složený z lokálních dat.
    var myLeaderboardEntry: TipLeaderboardEntry {
        TipLeaderboardEntry(
            id: AuthAccess.store?.userId ?? userId,
            name: displayName,
            points: combinedPoints,
            correct: correctTips,
            total: resolvedTips,
            isCurrentUser: true
        )
    }

    /// Žebříček k zobrazení — reálný ze serveru, jinak lokální demo s boty.
    var leaderboard: [TipLeaderboardEntry] {
        let sortRule: (TipLeaderboardEntry, TipLeaderboardEntry) -> Bool = {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.correct != $1.correct { return $0.correct > $1.correct }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        // Reálný žebříček ze serveru má přednost; jinak lokální demo s boty.
        if !remoteLeaderboard.isEmpty {
            var rows = remoteLeaderboard
            if AuthAccess.store?.isAuthenticated == true, !rows.contains(where: \.isCurrentUser) {
                rows.append(myLeaderboardEntry)
            }
            return rows.sorted(by: sortRule)
        }
        return (botEntries + [myLeaderboardEntry]).sorted(by: sortRule)
    }

    /// Moje pořadí v žebříčku (1 = první).
    var myRank: Int {
        leaderboard.firstIndex(where: \.isCurrentUser).map { $0 + 1 } ?? leaderboard.count
    }

    // MARK: - Private

    /// Vyrobí věrohodný základ hlasů komunity, než přijdou skutečné tipy.
    ///
    /// Odvozuje se z ID zápasu, takže je pro daný zápas vždy stejný — jinak
    /// by procenta poskakovala při každém otevření.
    private func seedVotes(matchId: String) -> MatchTipVotes {
        // Stabilní „komunitní“ základ podle id zápasu
        var hash: UInt64 = 5381
        for b in matchId.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(b) }
        let total = Int(80 + (hash % 220))
        let homeShare = 0.35 + Double(hash % 30) / 100.0 // 35–64 %
        let home = max(1, Int(Double(total) * homeShare))
        let away = max(1, total - home)
        return MatchTipVotes(matchId: matchId, homeCount: home, awayCount: away)
    }

    /// Uloží tipy vítěze do `UserDefaults`.
    private func persistTips() {
        if let data = try? JSONEncoder().encode(tips) {
            defaults.set(data, forKey: Keys.tips)
        }
    }

    /// Uloží počty hlasů komunity.
    private func persistVotes() {
        if let data = try? JSONEncoder().encode(votes) {
            defaults.set(data, forKey: Keys.votes)
        }
    }

    /// Uloží tipy skóre do `UserDefaults`.
    private func persistScoreTips() {
        if let data = try? JSONEncoder().encode(scoreTips) {
            defaults.set(data, forKey: Keys.scoreTips)
        }
    }

    /// Načte tipy skóre; poškozená data ignoruje.
    private static func loadScoreTips(from defaults: UserDefaults) -> [String: MatchScoreTip] {
        guard let data = defaults.data(forKey: Keys.scoreTips),
              let decoded = try? JSONDecoder().decode([String: MatchScoreTip].self, from: data) else { return [:] }
        return decoded
    }

    /// Uloží demo soupeře.
    private func persistBots() {
        let raw = botEntries.map {
            ["id": $0.id, "name": $0.name, "points": "\($0.points)", "correct": "\($0.correct)", "total": "\($0.total)"]
        }
        defaults.set(raw, forKey: Keys.bots)
    }

    /// Načte tipy vítěze.
    private static func loadTips(from defaults: UserDefaults) -> [String: MatchTip] {
        guard let data = defaults.data(forKey: Keys.tips),
              let decoded = try? JSONDecoder().decode([String: MatchTip].self, from: data) else { return [:] }
        return decoded
    }

    /// Načte počty hlasů komunity.
    private static func loadVotes(from defaults: UserDefaults) -> [String: MatchTipVotes] {
        guard let data = defaults.data(forKey: Keys.votes),
              let decoded = try? JSONDecoder().decode([String: MatchTipVotes].self, from: data) else { return [:] }
        return decoded
    }

    /// Načte demo soupeře.
    private static func loadBots(from defaults: UserDefaults) -> [TipLeaderboardEntry] {
        guard let raw = defaults.array(forKey: Keys.bots) as? [[String: String]] else { return [] }
        return raw.compactMap { row in
            guard let id = row["id"], let name = row["name"],
                  let points = Int(row["points"] ?? ""),
                  let correct = Int(row["correct"] ?? ""),
                  let total = Int(row["total"] ?? "") else { return nil }
            return TipLeaderboardEntry(id: id, name: name, points: points, correct: correct, total: total, isCurrentUser: false)
        }
    }

    /// Vytvoří výchozí sadu demo soupeřů pro prázdný žebříček.
    private static func makeBots() -> [TipLeaderboardEntry] {
        let names = [
            "Extraliga Fan", "Lední šíp", "Tipovač 88", "Hokejbal Pro",
            "Gólman Tip", "Pardubický tip", "Hostivař Ultra", "Plzeňský odhad"
        ]
        return names.enumerated().map { i, name in
            let total = 18 + i * 3
            let correct = 8 + i * 2
            return TipLeaderboardEntry(
                id: "bot-\(i)",
                name: name,
                points: correct * pointsPerCorrectTip,
                correct: correct,
                total: total,
                isCurrentUser: false
            )
        }
    }
}

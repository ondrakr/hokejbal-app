import Foundation
import SwiftUI

// MARK: - Slots (Extraliga: 1 B + 2 O + 3 Ú)

/// Pozice v fantasy sestavě.
///
/// Sestava má pevných šest míst — jeden brankář, dva obránci, tři útočníci —
/// a hráč se dá zařadit jen na slot odpovídající jeho pozici.
enum FantasySlot: String, CaseIterable, Identifiable, Hashable, Sendable {
    case goalie
    case defense1
    case defense2
    case forward1
    case forward2
    case forward3

    var id: String { rawValue }

    /// Pozice hráče, kterou tenhle slot vyžaduje.
    var position: PlayerPosition {
        switch self {
        case .goalie: return .goalie
        case .defense1, .defense2: return .defenseman
        case .forward1, .forward2, .forward3: return .forward
        }
    }

    /// Název slotu pro UI („Obránce 1").
    var title: String {
        switch self {
        case .goalie: return "Brankář"
        case .defense1: return "Obránce 1"
        case .defense2: return "Obránce 2"
        case .forward1: return "Útočník 1"
        case .forward2: return "Útočník 2"
        case .forward3: return "Útočník 3"
        }
    }

    /// Zkratka pozice na kartičce (B / O / Ú).
    var shortTitle: String {
        switch self {
        case .goalie: return "B"
        case .defense1, .defense2: return "O"
        case .forward1, .forward2, .forward3: return "Ú"
        }
    }
}

/// Vizuální úroveň kartičky podle ratingu — čím lepší hráč, tím vzácnější karta.
///
/// Hranice určuje `FantasyRules.tier(for:)`.
enum FantasyCardTier: String, Sendable {
    case bronze
    case silver
    case gold
    case elite

    /// Barvy pozadí kartičky.
    var gradient: [Color] {
        switch self {
        case .bronze:
            return [Color(red: 0.55, green: 0.32, blue: 0.16), Color(red: 0.35, green: 0.18, blue: 0.08)]
        case .silver:
            return [Color(red: 0.72, green: 0.74, blue: 0.78), Color(red: 0.42, green: 0.45, blue: 0.50)]
        case .gold:
            return [Color(red: 0.95, green: 0.78, blue: 0.28), Color(red: 0.72, green: 0.48, blue: 0.08)]
        case .elite:
            return [Color(red: 0.18, green: 0.14, blue: 0.28), Color(red: 0.55, green: 0.35, blue: 0.08)]
        }
    }

    /// Barva textu a orámování na kartičce.
    var accent: Color {
        switch self {
        case .bronze: return Color(red: 0.90, green: 0.70, blue: 0.45)
        case .silver: return Color.white
        case .gold: return Color(red: 1.0, green: 0.92, blue: 0.55)
        case .elite: return Color(red: 1.0, green: 0.84, blue: 0.30)
        }
    }

    /// Název úrovně zobrazený ve scoutu.
    var label: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .elite: return "Elite"
        }
    }
}

// MARK: - Deadline / kola (sobota 10:00 Praha)

/// Kalendář fantasy kol.
///
/// Sezóna je rozsekaná na týdenní kola, každé začíná uzávěrkou **v sobotu
/// v 10:00 pražského času**. Do uzávěrky jde sestava měnit, po ní se zamkne
/// a hraje se s tím, co je uložené.
///
/// Kola se počítají od `seasonAnchor` — první soboty sezóny.
enum FantasyDeadline {
    /// Časová zóna, ve které uzávěrky platí (deadline je pro všechny stejný).
    static let prague = TimeZone(identifier: "Europe/Prague") ?? .current
    /// První sobota sezóny Fantasy (deadline GW1).
    static let seasonAnchor = date(year: 2025, month: 9, day: 6, hour: 10, minute: 0)

    /// Gregoriánský kalendář v pražském čase.
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = prague
        return cal
    }

    /// Sestaví datum v pražském čase ze složek.
    static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return calendar.date(from: comps) ?? Date()
    }

    /// Nejbližší sobota 10:00 (pokud je dnes sobota před 10:00 → dnes, jinak příští sobota).
    static func upcomingDeadline(from now: Date = Date()) -> Date {
        let cal = calendar
        let weekday = cal.component(.weekday, from: now) // 1 = neděle … 7 = sobota
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let startOfToday = cal.startOfDay(for: now)
        guard var saturday = cal.date(byAdding: .day, value: daysUntilSaturday, to: startOfDay(of: now) ?? startOfToday) else {
            return now
        }
        saturday = cal.date(bySettingHour: 10, minute: 0, second: 0, of: saturday) ?? saturday

        if daysUntilSaturday == 0, now >= saturday {
            // Sobota po 10:00 → další sobota
            saturday = cal.date(byAdding: .day, value: 7, to: saturday) ?? saturday
        }
        return saturday
    }

    /// Deadline aktuálně hraného / právě uzamčeného kola (sobota 10:00 tohoto týdne, pokud už prošla).
    static func activeDeadline(from now: Date = Date()) -> Date {
        let next = upcomingDeadline(from: now)
        return calendar.date(byAdding: .day, value: -7, to: next) ?? next
    }

    /// Číslo kola od anchor soboty (min. 1).
    static func gameweek(from now: Date = Date()) -> Int {
        let deadline = upcomingDeadline(from: now)
        let seconds = deadline.timeIntervalSince(seasonAnchor)
        let weeks = Int(floor(seconds / (7 * 24 * 3600)))
        return max(1, weeks + 1)
    }

    /// Sestava pro `gameweek` se dá měnit, dokud `now < deadline` toho kola.
    static func deadline(forGameweek gw: Int) -> Date {
        calendar.date(byAdding: .day, value: (gw - 1) * 7, to: seasonAnchor) ?? seasonAnchor
    }

    /// Jde sestava pro dané kolo ještě měnit?
    ///
    /// - Parameters:
    ///   - gameweek: Číslo kola.
    ///   - now: Čas, ke kterému se ptáme.
    /// - Returns: `true`, dokud neprošla uzávěrka toho kola.
    static func isEditable(gameweek: Int, at now: Date = Date()) -> Bool {
        now < deadline(forGameweek: gameweek)
    }

    /// Zbývající čas do uzávěrky jako krátký text („2d 5h").
    static func countdown(to deadline: Date, from now: Date = Date()) -> String {
        let p = countdownParts(to: deadline, from: now)
        if p.days > 0 { return "\(p.days)d \(p.hours)h" }
        if p.hours > 0 { return "\(p.hours)h \(p.minutes)m" }
        return "\(p.minutes)m \(p.seconds)s"
    }

    /// Zbývající čas rozložený na dny/hodiny/minuty/sekundy — pro odpočet v UI.
    static func countdownParts(to deadline: Date, from now: Date = Date()) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = max(0, Int(deadline.timeIntervalSince(now)))
        let days = interval / 86_400
        let hours = (interval % 86_400) / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        return (days, hours, minutes, seconds)
    }

    /// Půlnoc daného dne v pražském čase.
    private static func startOfDay(of date: Date) -> Date? {
        calendar.startOfDay(for: date)
    }
}

// MARK: - Rules

/// Pravidla hry — rozpočet, ceny, rating hráčů a bodování.
///
/// Všechno bez stavu, aby se dalo volat odkudkoli z UI.
enum FantasyRules {
    /// Soutěž, ze které se dají vybírat hráči.
    static let competitionSlug = "extraliga"

    /// Rozpočet na celou sestavu v kreditech.
    ///
    /// - Warning: Viz upozornění u `priceCredits(for:)` — při stropu ceny 15
    ///   za hráče a šesti slotech je tenhle rozpočet zatím nedosažitelný.
    static let budgetCredits = 100

    /// Kolik hráčů smí být v sestavě z jednoho klubu (proti „naskládám si celou Hostivař").
    static let maxFromSameClub = 2

    /// Počet míst v sestavě (1 brankář + 2 obránci + 3 útočníci).
    static let squadSize = FantasySlot.allCases.count

    /// Kredity, se kterými hráč startuje sezónu.
    static let startingWallet = 0

    /// Patří hráč do Extraligy, a smí se tedy koupit?
    ///
    /// Primárně se řídí soutěží u hráče; když ta chybí, zkusí soutěž jeho týmu.
    static func isExtraligaPlayer(_ player: Player, teamsById: [String: Team], competitionsById: [String: Competition]) -> Bool {
        if let competitionId = player.competitionId,
           let competition = competitionsById[competitionId],
           competition.slug == competitionSlug {
            return true
        }
        guard let team = teamsById[player.teamId] else { return false }
        guard let competition = competitionsById[team.competitionId] else {
            return team.competitionId.contains("extraliga")
        }
        return competition.slug == competitionSlug
    }

    /// Sdílená tabulka parametrů hráčů, ze které počítá `rating(for:)`.
    ///
    /// Plní ji `FantasyAttributesStore` (ze serveru nebo z mocku). Je to
    /// globální stav schválně: rating se počítá na desítkách míst v UI —
    /// při řazení trhu, kreslení kartiček, výpočtu ceny — a protahovat store
    /// do všech těch volání by je zbytečně zaneslo.
    ///
    /// - Warning: Zapisuje se z `@MainActor` storu a čte z UI (taky main
    ///   thread). Kdyby se rating začal počítat na pozadí, je potřeba to
    ///   předělat na izolovaný stav.
    static var attributesByPlayerId: [String: PlayerAttributes] = [:]

    /// OVR hráče — číslo na kartičce.
    ///
    /// Přednost mají parametry od trenérů (`PlayerAttributes`, rozsah až 99).
    /// Když hráč parametry nemá, spočítá se rating ze sezónních statistik
    /// (`statRating(for:)`, rozsah 55–94), aby měl kartičku každý.
    ///
    /// - Parameter player: Hráč.
    /// - Returns: OVR 1–99.
    static func rating(for player: Player) -> Int {
        if let attrs = attributesByPlayerId[player.id],
           let ovr = attrs.computedOverall(position: player.position) {
            return ovr
        }
        return statRating(for: player)
    }

    /// OVR odhadnuté ze sezónních statistik — záloha, když chybí parametry.
    ///
    /// Každá pozice se hodnotí jinak: brankář podle úspěšnosti zákroků a
    /// průměru inkasovaných, hráči do pole podle bodů na zápas, gólů
    /// a odehraných zápasů (odehranost odměňuje stálice v sestavě).
    ///
    /// Výsledek je schválně stlačený do **55–94**, aby statisticky odvozený
    /// rating nikdy nepřebil hráče s ručně vyplněnými parametry.
    ///
    /// - Parameter player: Hráč se sezónními statistikami.
    /// - Returns: OVR 55–94.
    static func statRating(for player: Player) -> Int {
        let value: Double
        switch player.position {
        case .goalie:
            let save = player.savePercentage ?? 88
            let gaa = player.goalsAgainstAverage ?? 3.2
            value = 62 + (save - 86) * 2.2 + Double(player.games) * 0.35 - (gaa - 2.5) * 3
        case .defenseman:
            let ppg = player.games > 0 ? Double(player.points) / Double(player.games) : 0
            value = 58 + ppg * 18 + Double(player.goals) * 0.8 + Double(player.games) * 0.25
        case .forward:
            let ppg = player.games > 0 ? Double(player.points) / Double(player.games) : 0
            value = 58 + ppg * 20 + Double(player.goals) * 1.1 + Double(player.games) * 0.2
        }
        return Int(min(94, max(55, value.rounded())))
    }

    /// Barevná úroveň kartičky podle ratingu (bronz → stříbro → zlato → elite).
    ///
    /// - Parameter rating: OVR hráče.
    /// - Returns: Úroveň, která určuje gradient a orámování kartičky.
    static func tier(for rating: Int) -> FantasyCardTier {
        switch rating {
        case ..<65: return .bronze
        case ..<75: return .silver
        case ..<85: return .gold
        default: return .elite
        }
    }

    /// Cena hráče v kreditech, odvozená lineárně z jeho OVR.
    ///
    /// Rating 55 stojí 4 kredity, rating 94 a výš patnáct — tedy strop.
    ///
    /// - Parameter player: Hráč.
    /// - Returns: Cena 4–15 kreditů.
    ///
    /// - Warning: Strop 15 znamená, že celá sestava (6 hráčů) vyjde nejvýš na
    ///   90 kreditů, zatímco rozpočet je `budgetCredits` = 100. Rozpočet tedy
    ///   zatím nikoho neomezuje — než půjde Fantasy naostro, je potřeba buď
    ///   snížit rozpočet, nebo roztáhnout cenové rozpětí.
    static func priceCredits(for player: Player) -> Int {
        let r = rating(for: player)
        // 55 → 4, 94 → 15
        let raw = 4.0 + Double(r - 55) * (11.0 / 39.0)
        return Int(min(15, max(4, raw.rounded())))
    }

    /// Cena jako `Double` — jen kvůli staršímu UI, jinak použij `priceCredits(for:)`.
    static func price(for player: Player) -> Double {
        Double(priceCredits(for: player))
    }

    /// Orientační bodový přínos hráče za **celou sezónu**.
    ///
    /// Používá se jako vodítko při výběru v trhu a ve scoutu („kolik ten hráč
    /// zhruba nasbírá"), **ne** k počítání skutečných bodů za kolo — od toho
    /// je `weeklyFantasyPoints(for:in:)`.
    ///
    /// - Parameter player: Hráč se sezónními statistikami.
    /// - Returns: Body, nikdy záporné.
    static func fantasyPoints(for player: Player) -> Int {
        switch player.position {
        case .goalie:
            let saveBonus = Int(((player.savePercentage ?? 88) - 85) * 2)
            return max(0, player.games * 2 + saveBonus - player.penaltyMinutes / 4)
        case .defenseman, .forward:
            return max(0, player.goals * 3 + player.assists * 2 + player.games / 2 - player.penaltyMinutes / 5)
        }
    }

    /// Kredity do peněženky za odehrané kolo.
    ///
    /// Základ 10 kreditů dostane každý, kdo měl uloženou sestavu, k tomu
    /// třetina nasbíraných bodů — nejvýš ale 40, aby jedno vydařené kolo
    /// nerozhodlo celou sezónu.
    ///
    /// - Parameter squadPoints: Body sestavy za dané kolo.
    /// - Returns: 10–50 kreditů.
    static func roundRewardCredits(squadPoints: Int) -> Int {
        10 + min(40, squadPoints / 3)
    }

    /// Nejbližší zápas týmu — pro štítek „vs Soupeř" na kartičce a ve scoutu.
    ///
    /// Právě probíhající zápas se počítá taky, a tolerance tří hodin zpět
    /// zajistí, že se štítek nepřepne hned po výkopu.
    ///
    /// - Parameters:
    ///   - teamId: Tým, jehož zápas hledáme.
    ///   - matches: Zápasy, ve kterých se hledá.
    ///   - date: Okamžik, od kterého se hledá (výchozí = teď).
    /// - Returns: Nejbližší zápas, nebo `nil`, když už žádný nezbývá.
    static func nextFixture(for teamId: String, in matches: [Match], after date: Date = Date()) -> Match? {
        matches
            .filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
            .filter { $0.status == .scheduled || $0.status == .live }
            .filter { $0.scheduledAt >= date.addingTimeInterval(-3 * 3600) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    /// Zápasy, které spadají do daného kola.
    ///
    /// Kolo je týdenní okno mezi dvěma deadliny (sobota 10:00 → další sobota
    /// 10:00), takže zápas patří do toho kola, na jehož sestavu se hrál.
    ///
    /// - Parameters:
    ///   - gameweek: Číslo kola.
    ///   - matches: Zápasy, ze kterých se vybírá.
    /// - Returns: Zápasy odehrané v okně daného kola.
    static func matches(inGameweek gameweek: Int, from matches: [Match]) -> [Match] {
        let start = FantasyDeadline.deadline(forGameweek: gameweek)
        let end = FantasyDeadline.deadline(forGameweek: gameweek + 1)
        return matches.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
    }

    /// Body hráče za jedno kolo podle toho, jak mu ten víkend šlo.
    ///
    /// Tohle je jádro Fantasy — právě podle těchhle bodů se posouvá žebříček.
    /// Počítá se jen z **dohraných** zápasů daného kola; když hráčův tým ještě
    /// nehrál, vrací nulu (kolo se pak vyhodnotí později).
    ///
    /// ## Bodování
    ///
    /// **Hráči do pole** — z gólových událostí zápasu:
    /// - vstřelený gól: 3 body
    /// - asistence: 2 body
    ///
    /// **Brankáři** — z výsledku týmu, protože zápisy nemají, kdo chytal:
    /// - výhra: 3 body
    /// - čisté konto: 5 bodů
    /// - jinak podle inkasovaných: `4 − obdržené góly` (nejméně 0)
    ///
    /// - Parameters:
    ///   - player: Hráč ze sestavy.
    ///   - gameweekMatches: Zápasy daného kola (viz `matches(inGameweek:from:)`).
    /// - Returns: Body za kolo, nikdy záporné.
    ///
    /// - Note: U brankářů jde o odhad — dokud data neobsahují rozpis brankářů,
    ///   dostane body brankář v sestavě bez ohledu na to, jestli opravdu chytal.
    static func weeklyFantasyPoints(for player: Player, in gameweekMatches: [Match]) -> Int {
        let played = gameweekMatches.filter {
            $0.isFinished && ($0.homeTeamId == player.teamId || $0.awayTeamId == player.teamId)
        }
        guard !played.isEmpty else { return 0 }

        switch player.position {
        case .forward, .defenseman:
            var pts = 0
            for match in played {
                for event in match.events where event.kind == .goal {
                    if event.playerId == player.id { pts += 3 }
                    if event.assistIds.contains(player.id) { pts += 2 }
                }
            }
            return pts
        case .goalie:
            // Bez rozpisu brankářů heuristika podle výsledku týmu (drž 1 brankáře v sestavě).
            var pts = 0
            for match in played {
                let isHome = match.homeTeamId == player.teamId
                let goalsFor = isHome ? match.homeScore : match.awayScore
                let goalsAgainst = isHome ? match.awayScore : match.homeScore
                if goalsFor > goalsAgainst { pts += 3 }
                pts += goalsAgainst == 0 ? 5 : max(0, 4 - goalsAgainst)
            }
            return pts
        }
    }
}

// MARK: - Store

/// Stav fantasy týmu jednoho uživatele.
///
/// Drží sestavy po kolech, body, kredity a nastavení zobrazení. Data žijí
/// lokálně v `UserDefaults` a po přihlášení se zrcadlí do Supabase, takže
/// tým přežije přeinstalaci i přechod na jiné zařízení.
///
/// ## Jak to spolu souvisí
///
/// 1. `syncGameweekIfNeeded(now:)` posune kolo, když prošla uzávěrka
/// 2. uživatel skládá sestavu přes `assign(_:to:playersById:)`
/// 3. `saveLineup()` ji potvrdí a odešle na server
/// 4. `scorePendingGameweeks(playersById:matches:)` po odehrání kola přidělí body
@MainActor
final class FantasySquadStore: ObservableObject {
    /// Název týmu zobrazený v žebříčku.
    @Published var teamName: String {
        didSet { defaults.set(teamName, forKey: Keys.teamName) }
    }

    /// Sestavy po kolech: gameweek → slot → playerId
    @Published private(set) var lineupsByGameweek: [Int: [FantasySlot: String]] {
        didSet { persistLineups() }
    }

    /// Kolo, které se právě hraje (a jehož sestava jde měnit do uzávěrky).
    @Published private(set) var activeGameweek: Int {
        didSet { defaults.set(activeGameweek, forKey: Keys.activeGW) }
    }

    /// Nasbírané kredity za odehraná kola.
    @Published private(set) var wallet: Int {
        didSet { defaults.set(wallet, forKey: Keys.wallet) }
    }

    /// Součet bodů za celou sezónu — podle něj se řadí žebříček.
    @Published private(set) var seasonPoints: Int {
        didSet { defaults.set(seasonPoints, forKey: Keys.seasonPoints) }
    }

    /// Kola, která už mají přidělené body (pojistka proti dvojímu započítání).
    @Published private(set) var scoredGameweeks: Set<Int> {
        didSet {
            defaults.set(Array(scoredGameweeks), forKey: Keys.scored)
        }
    }

    /// Prohlížené kolo (šipky v hubu) — editace jen když == activeGameweek a není lock.
    @Published var viewingGameweek: Int = 1

    /// Zbývající volné přestupy (99 = neomezeně před prvním deadlinem).
    @Published private(set) var freeTransfers: Int {
        didSet { defaults.set(freeTransfers, forKey: Keys.freeTransfers) }
    }

    /// Potvrzené sestavy po kolech — s těmihle se počítají body.
    ///
    /// Liší se od `lineupsByGameweek`, což je rozpracovaný draft; do bodování
    /// se dostane jen to, co uživatel potvrdil tlačítkem ULOŽIT SESTAVU.
    @Published private(set) var savedLineupsByGameweek: [Int: [FantasySlot: String]] {
        didSet { persistSaved() }
    }

    /// Zobrazovat na kartičkách v sestavě cenu hráče.
    @Published var showPriceOnPitch: Bool {
        didSet { defaults.set(showPriceOnPitch, forKey: Keys.showPrice) }
    }
    /// Zobrazovat na kartičkách body za kolo.
    @Published var showPointsOnPitch: Bool {
        didSet { defaults.set(showPointsOnPitch, forKey: Keys.showPoints) }
    }
    /// Zobrazovat na kartičkách nejbližšího soupeře.
    @Published var showOpponentOnPitch: Bool {
        didSet { defaults.set(showOpponentOnPitch, forKey: Keys.showOpponent) }
    }

    /// Poslední hláška o uložení sestavy (pro potvrzení v UI).
    @Published private(set) var lastSaveMessage: String?

    private let defaults = UserDefaults.standard

    /// Klíče v `UserDefaults`. Verze `v3` kvůli migraci ze starších formátů.
    private enum Keys {
        static let teamName = "hb.fantasy.v3.teamName"
        static let lineups = "hb.fantasy.v3.lineups"
        static let saved = "hb.fantasy.v3.saved"
        static let activeGW = "hb.fantasy.v3.activeGW"
        static let wallet = "hb.fantasy.v3.wallet"
        static let seasonPoints = "hb.fantasy.v3.points"
        static let scored = "hb.fantasy.v3.scored"
        static let freeTransfers = "hb.fantasy.v3.ft"
        static let showPrice = "hb.fantasy.v3.ui.price"
        static let showPoints = "hb.fantasy.v3.ui.points"
        static let showOpponent = "hb.fantasy.v3.ui.opp"
        static let legacyV2Slots = "hb.fantasy.v2.slots"
        static let legacyV1Slots = "hb.fantasy.slots"
    }

    init() {
        let defaults = UserDefaults.standard

        teamName = defaults.string(forKey: Keys.teamName)
            ?? defaults.string(forKey: "hb.fantasy.v2.teamName")
            ?? defaults.string(forKey: "hb.fantasy.teamName")
            ?? "Můj Fantasy tým"

        if defaults.object(forKey: Keys.wallet) != nil {
            wallet = defaults.integer(forKey: Keys.wallet)
        } else if defaults.object(forKey: "hb.fantasy.v2.wallet") != nil {
            wallet = defaults.integer(forKey: "hb.fantasy.v2.wallet")
        } else {
            wallet = FantasyRules.startingWallet
        }

        let v3Points = defaults.integer(forKey: Keys.seasonPoints)
        seasonPoints = v3Points != 0 ? v3Points : defaults.integer(forKey: "hb.fantasy.v2.points")

        let scoredRaw = defaults.array(forKey: Keys.scored) as? [Int] ?? []
        scoredGameweeks = Set(scoredRaw)

        let computedGW = FantasyDeadline.gameweek()
        if defaults.object(forKey: Keys.activeGW) != nil {
            activeGameweek = max(1, defaults.integer(forKey: Keys.activeGW))
        } else {
            activeGameweek = computedGW
        }

        let loadedLineups = Self.loadLineups(from: defaults)
        let loadedSaved = Self.loadLineups(from: defaults, key: Keys.saved)
        lineupsByGameweek = loadedLineups
        savedLineupsByGameweek = loadedSaved.isEmpty ? loadedLineups : loadedSaved

        if defaults.object(forKey: Keys.freeTransfers) != nil {
            freeTransfers = defaults.integer(forKey: Keys.freeTransfers)
        } else {
            freeTransfers = 99 // neomezené do prvního deadlinu sezóny
        }

        showPriceOnPitch = defaults.object(forKey: Keys.showPrice) as? Bool ?? false
        showPointsOnPitch = defaults.object(forKey: Keys.showPoints) as? Bool ?? false
        showOpponentOnPitch = defaults.object(forKey: Keys.showOpponent) as? Bool ?? true
        lastSaveMessage = nil
        viewingGameweek = activeGameweek

        migrateLegacyIfNeeded()
        syncGameweekIfNeeded()
        viewingGameweek = activeGameweek
    }

    // MARK: Computed for active / viewing GW

    /// Uzávěrka aktuálního kola.
    var deadline: Date { FantasyDeadline.deadline(forGameweek: activeGameweek) }
    /// Uzávěrka právě prohlíženého kola.
    var viewingDeadline: Date { FantasyDeadline.deadline(forGameweek: viewingGameweek) }
    /// Prošla už uzávěrka aktuálního kola?
    var isLocked: Bool { !FantasyDeadline.isEditable(gameweek: activeGameweek) }
    /// Jde prohlížená sestava měnit? (Jen aktuální kolo před uzávěrkou.)
    var isViewingEditable: Bool {
        viewingGameweek == activeGameweek && !isLocked
    }
    /// Odpočet do uzávěrky jako text.
    var countdownText: String { FantasyDeadline.countdown(to: deadline) }

    /// Odpočet do uzávěrky po složkách — pro číselník v UI.
    var countdownParts: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        FantasyDeadline.countdownParts(to: deadline)
    }

    /// Obsazení slotů v prohlíženém kole (slot → ID hráče).
    var slotPlayerIds: [FantasySlot: String] {
        lineupsByGameweek[viewingGameweek] ?? lineupsByGameweek[activeGameweek] ?? [:]
    }

    /// Kolik slotů je obsazených.
    var filledCount: Int { slotPlayerIds.count }
    /// Je sestava kompletní (všech šest slotů)?
    var isComplete: Bool { filledCount == FantasyRules.squadSize }
    /// ID hráčů už zařazených v sestavě (aby nešel vybrat dvakrát).
    var selectedPlayerIds: Set<String> { Set(slotPlayerIds.values) }

    /// Liší se rozpracovaná sestava od té potvrzené?
    var hasUnsavedChanges: Bool {
        let draft = lineupsByGameweek[activeGameweek] ?? [:]
        let saved = savedLineupsByGameweek[activeGameweek] ?? [:]
        return draft != saved
    }

    /// Počet přestupů pro UI („∞" před prvním deadlinem).
    var transfersLabel: String {
        if freeTransfers >= 99 { return "∞" }
        return "\(freeTransfers)"
    }

    /// Orientační pořadí z bodů (lokální demo).
    var overallRank: Int {
        max(1, 12_000 - seasonPoints * 17)
    }

    /// Orientační pořadí za kolo (lokální demo, než přijde reálný žebříček).
    var roundRank: Int {
        max(1, 8_500 - squadPoints(playersById: [:]) * 11)
    }

    /// Hráč obsazující daný slot.
    func playerId(for slot: FantasySlot) -> String? { slotPlayerIds[slot] }

    /// Na kterém slotu hráč je (pokud vůbec).
    func slotContaining(playerId: String) -> FantasySlot? {
        slotPlayerIds.first { $0.value == playerId }?.key
    }

    /// Kolik kreditů stojí aktuální sestava.
    func spentCredits(playersById: [String: Player]) -> Int {
        slotPlayerIds.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.priceCredits(for: $1) }
    }

    /// Kolik kreditů z rozpočtu ještě zbývá.
    func remainingBudget(playersById: [String: Player]) -> Int {
        FantasyRules.budgetCredits - spentCredits(playersById: playersById)
    }

    /// Kompatibilita
    func spent(playersById: [String: Player]) -> Double {
        Double(spentCredits(playersById: playersById))
    }

    /// Orientační bodový součet sestavy ze sezónních statistik (náhled, ne skutečné body).
    func squadPoints(playersById: [String: Player]) -> Int {
        slotPlayerIds.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.fantasyPoints(for: $1) }
    }

    /// Přepne prohlížené kolo šipkami v hubu.
    func shiftViewingGameweek(by delta: Int) {
        viewingGameweek = max(1, viewingGameweek + delta)
    }

    /// Reálný žebříček fantasy ze serveru (fallback: lokální demo v UI).
    @Published private(set) var remoteLeaderboard: [FantasyLeaderRow] = []

    /// Uloží draft aktivního kola (jako „ULOŽIT SESTAVU“). Po přihlášení pushne na server.
    @discardableResult
    func saveLineup() -> String? {
        guard !isLocked else { return "Deadline prošlo — sestavu už nelze uložit." }
        guard isComplete else { return "Doplň celou sestavu (1B · 2O · 3Ú)." }
        var saved = savedLineupsByGameweek
        saved[activeGameweek] = lineupsByGameweek[activeGameweek] ?? [:]
        savedLineupsByGameweek = saved
        lastSaveMessage = "Sestava GW \(activeGameweek) uložena"
        let gw = activeGameweek
        Task { await pushSquad(gameweek: gw) }
        return nil
    }

    /// Posune aktivní kolo podle kalendáře a připraví sestavu k editaci.
    ///
    /// Volá se při startu a při otevření Fantasy. Když mezitím prošel deadline
    /// (sobota 10:00), přepne se na nové kolo, převezme se do něj poslední
    /// uložená sestava jako výchozí a přičte se volný přestup.
    ///
    /// Body **nepočítá** — na to je `scorePendingGameweeks(playersById:matches:)`,
    /// které potřebuje odehrané zápasy.
    ///
    /// - Parameter now: Čas, ke kterému se kolo určuje (kvůli testovatelnosti).
    func syncGameweekIfNeeded(now: Date = Date()) {
        let gw = FantasyDeadline.gameweek(from: now)

        if gw > activeGameweek {
            let old = activeGameweek
            if lineupsByGameweek[gw] == nil {
                var copy = lineupsByGameweek
                copy[gw] = savedLineupsByGameweek[old] ?? lineupsByGameweek[old] ?? [:]
                lineupsByGameweek = copy
            }
            activeGameweek = gw
            viewingGameweek = gw
            freeTransfers = min(2, freeTransfers + 1)
            if freeTransfers < 1 { freeTransfers = 1 }
        } else if lineupsByGameweek[gw] == nil, let previous = lineupsByGameweek[gw - 1] {
            var copy = lineupsByGameweek
            copy[gw] = previous
            lineupsByGameweek = copy
        } else if lineupsByGameweek[gw] == nil {
            var copy = lineupsByGameweek
            copy[gw] = [:]
            lineupsByGameweek = copy
        }

        if viewingGameweek < 1 { viewingGameweek = activeGameweek }
    }

    /// Dopočítá body za všechna uzavřená kola, která ještě nebyla vyhodnocená.
    ///
    /// Projde kola od začátku sezóny po to aktuální a u každého, které ještě
    /// nemá spočítané body, sečte výkon uložené sestavy. Kolo přeskočí, když:
    /// - sestava nebyla uložená celá (1 brankář, 2 obránci, 3 útočníci), nebo
    /// - z kola ještě není dohraný ani jeden zápas (vyhodnotí se příště).
    ///
    /// Vyhodnocené kolo se zapíše do `scoredGameweeks`, takže se body nikdy
    /// nepřičtou dvakrát, a odešle se na server.
    ///
    /// - Parameters:
    ///   - playersById: Hráči podle ID — musí obsahovat hráče ze sestav.
    ///   - allMatches: Zápasy sezóny, ze kterých se výkon počítá.
    /// - Returns: Kolik bodů se právě přičetlo (0 = nic nového k vyhodnocení).
    @discardableResult
    func scorePendingGameweeks(playersById: [String: Player], matches allMatches: [Match]) -> Int {
        guard !allMatches.isEmpty, activeGameweek > 1 else { return 0 }
        var gained = 0
        for gw in 1..<activeGameweek where !scoredGameweeks.contains(gw) {
            let slots = savedLineupsByGameweek[gw] ?? lineupsByGameweek[gw] ?? [:]
            guard slots.count == FantasyRules.squadSize else { continue }
            let gwMatches = FantasyRules.matches(inGameweek: gw, from: allMatches)
            guard gwMatches.contains(where: { $0.isFinished }) else { continue }
            let points = slots.values
                .compactMap { playersById[$0] }
                .reduce(0) { $0 + FantasyRules.weeklyFantasyPoints(for: $1, in: gwMatches) }
            let credits = FantasyRules.roundRewardCredits(squadPoints: points)
            seasonPoints += points
            wallet += credits
            scoredGameweeks.insert(gw)
            gained += points
            Task { await pushScore(gameweek: gw, points: points, credits: credits) }
        }
        return gained
    }

    // MARK: - Server sync (Supabase)

    /// Natáhne uložené sestavy a body ze serveru — server je zdroj pravdy.
    ///
    /// Přepíše lokální stav, aby uživatel viděl svůj tým i po přeinstalaci
    /// nebo na jiném zařízení. Bez přihlášení a v demo režimu nedělá nic.
    /// Chyby polyká — appka jede dál na lokálních datech.
    func loadRemote() async {
        guard !FantasyMock.enabled else { return }
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let squads = try await auth.authAPI.fetchFantasySquads(userId: userId, accessToken: token)
            let scores = try await auth.authAPI.fetchFantasyScores(userId: userId, accessToken: token)
            applyRemote(squads: squads, scores: scores)
        } catch { /* soft */ }
    }

    /// Načte celkový žebříček Fantasy.
    ///
    /// Čte veřejný pohled `fantasy_leaderboard`, takže funguje i bez
    /// přihlášení. Když se nepodaří (nebo v demo režimu), zůstane prázdný
    /// a UI ukáže lokální demo s boty.
    func loadLeaderboard() async {
        guard !FantasyMock.enabled else { return }
        guard let api = AuthAccess.store?.authAPI else { return }
        do { remoteLeaderboard = try await api.fetchFantasyLeaderboard() }
        catch { /* soft */ }
    }

    /// Přepíše lokální stav daty ze serveru.
    ///
    /// Sestavy se zapisují jako uložené i jako rozpracované (na serveru jsou
    /// jen potvrzené sestavy), body a kredity se sečtou přes všechna kola.
    ///
    /// - Parameters:
    ///   - squads: Uložené sestavy po kolech.
    ///   - scores: Vyhodnocená kola s body a kredity.
    private func applyRemote(squads: [FantasySquadRow], scores: [FantasyScoreRow]) {
        if !squads.isEmpty {
            var lineups = lineupsByGameweek
            var saved = savedLineupsByGameweek
            for row in squads {
                var map: [FantasySlot: String] = [:]
                for slot in FantasySlot.allCases where row.slots[slot.rawValue] != nil {
                    map[slot] = row.slots[slot.rawValue]
                }
                lineups[row.gameweek] = map
                saved[row.gameweek] = map
                if row.gameweek == activeGameweek, !row.teamName.isEmpty {
                    teamName = row.teamName
                }
            }
            lineupsByGameweek = lineups
            savedLineupsByGameweek = saved
        }
        if !scores.isEmpty {
            seasonPoints = scores.reduce(0) { $0 + $1.points }
            wallet = scores.reduce(FantasyRules.startingWallet) { $0 + $1.credits }
            scoredGameweeks = Set(scores.map(\.gameweek))
        }
    }

    /// Odešle uloženou sestavu daného kola na server.
    ///
    /// - Parameter gameweek: Kolo, jehož sestava se má uložit.
    private func pushSquad(gameweek: Int) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        let slots = (savedLineupsByGameweek[gameweek] ?? [:])
            .reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertFantasySquad(
                userId: userId, gameweek: gameweek, teamName: teamName, slots: slots, accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Zapíše výsledek vyhodnoceného kola na server (podklad pro žebříček).
    ///
    /// - Parameters:
    ///   - gameweek: Vyhodnocené kolo.
    ///   - points: Body sestavy za kolo.
    ///   - credits: Přidělené kredity.
    private func pushScore(gameweek: Int, points: Int, credits: Int) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated, let userId = auth.userId else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.upsertFantasyScore(
                userId: userId, gameweek: gameweek, points: points, credits: credits, accessToken: token
            )
        } catch { /* soft */ }
    }

    /// Zařadí hráče na slot v sestavě.
    ///
    /// Postupně ověří všechna pravidla: kolo jde měnit, hráč sedí na pozici,
    /// vejde se do rozpočtu a nepřekročí limit hráčů z jednoho klubu. Když
    /// hráč už v sestavě je na jiném slotu, přesune se (nezdvojí se).
    ///
    /// - Parameters:
    ///   - player: Vybraný hráč.
    ///   - targetSlot: Slot, kam ho zařadit.
    ///   - playersById: Hráči podle ID (kvůli cenám a klubům už zařazených).
    /// - Returns: `nil` při úspěchu, jinak hlášku, které pravidlo se porušilo.
    @discardableResult
    func assign(_ player: Player, to targetSlot: FantasySlot, playersById: [String: Player]) -> String? {
        guard isViewingEditable else {
            return "Toto kolo nejde upravovat (deadline sobota 10:00)."
        }
        guard player.position == targetSlot.position else {
            return "Hráč neodpovídá pozici \(targetSlot.title)."
        }

        let movingFromOther = slotContaining(playerId: player.id)
        var next = slotPlayerIds
        if let movingFromOther, movingFromOther != targetSlot {
            next[movingFromOther] = nil
        }
        next[targetSlot] = nil

        let currentSpent = next.values.compactMap { playersById[$0] }.reduce(0) { $0 + FantasyRules.priceCredits(for: $1) }
        let price = FantasyRules.priceCredits(for: player)
        if currentSpent + price > FantasyRules.budgetCredits {
            return "Překročíš rozpočet \(FantasyRules.budgetCredits) kreditů."
        }

        var clubCounts = Dictionary(grouping: next.values.compactMap { playersById[$0]?.teamId }, by: { $0 })
            .mapValues(\.count)
        clubCounts[player.teamId, default: 0] += 1
        if clubCounts[player.teamId, default: 0] > FantasyRules.maxFromSameClub {
            return "Max. \(FantasyRules.maxFromSameClub) hráči z jednoho klubu."
        }

        next[targetSlot] = player.id
        var all = lineupsByGameweek
        all[activeGameweek] = next
        lineupsByGameweek = all
        return nil
    }

    /// Uvolní jeden slot v sestavě.
    func clear(slot: FantasySlot) {
        guard isViewingEditable else { return }
        var next = slotPlayerIds
        next[slot] = nil
        var all = lineupsByGameweek
        all[activeGameweek] = next
        lineupsByGameweek = all
    }

    /// Vyprázdní celou sestavu aktuálního kola.
    func clearAll() {
        guard isViewingEditable else { return }
        var all = lineupsByGameweek
        all[activeGameweek] = [:]
        lineupsByGameweek = all
    }

    /// Manuální vyhodnocení uzavřených kol (např. po sobotě 10:00). Vrací přírůstek bodů.
    @discardableResult
    func claimRoundReward(playersById: [String: Player], matches: [Match]) -> Int {
        scorePendingGameweeks(playersById: playersById, matches: matches)
    }

    // MARK: Persistence

    /// Uloží rozpracované sestavy do `UserDefaults`.
    private func persistLineups() {
        persist(lineupsByGameweek, key: Keys.lineups)
    }

    /// Uloží potvrzené sestavy do `UserDefaults`.
    private func persistSaved() {
        persist(savedLineupsByGameweek, key: Keys.saved)
    }

    /// Zapíše sestavy po kolech pod daný klíč (slovníky se serializují na řetězce).
    private func persist(_ map: [Int: [FantasySlot: String]], key: String) {
        var encoded: [String: [String: String]] = [:]
        for (gw, slots) in map {
            var dict: [String: String] = [:]
            for (slot, id) in slots {
                dict[slot.rawValue] = id
            }
            encoded["\(gw)"] = dict
        }
        defaults.set(encoded, forKey: key)
    }

    /// Načte sestavy po kolech z `UserDefaults`; poškozená data ignoruje.
    private static func loadLineups(from defaults: UserDefaults, key: String = Keys.lineups) -> [Int: [FantasySlot: String]] {
        guard let raw = defaults.dictionary(forKey: key) as? [String: [String: String]] else {
            return [:]
        }
        var result: [Int: [FantasySlot: String]] = [:]
        for (gwKey, slots) in raw {
            guard let gw = Int(gwKey) else { continue }
            var map: [FantasySlot: String] = [:]
            for slot in FantasySlot.allCases {
                if let id = slots[slot.rawValue] {
                    map[slot] = id
                }
            }
            result[gw] = map
        }
        return result
    }

    /// Přenese sestavu ze starších verzí úložiště (v1/v2), pokud v3 ještě nic nemá.
    private func migrateLegacyIfNeeded() {
        guard lineupsByGameweek.isEmpty else { return }
        let legacy = (defaults.dictionary(forKey: Keys.legacyV2Slots) as? [String: String])
            ?? (defaults.dictionary(forKey: Keys.legacyV1Slots) as? [String: String])
            ?? [:]
        guard !legacy.isEmpty else { return }
        var map: [FantasySlot: String] = [:]
        for slot in FantasySlot.allCases {
            if let id = legacy[slot.rawValue] {
                map[slot] = id
            }
        }
        lineupsByGameweek = [activeGameweek: map]
    }
}

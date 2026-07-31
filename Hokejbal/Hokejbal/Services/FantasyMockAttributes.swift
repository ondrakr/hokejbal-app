import Foundation

/// Přepínač demo režimu Fantasy a Tipovačky.
///
/// Když je zapnutý, appka nepotřebuje ani spuštěnou databázovou migraci, ani
/// přihlášení — parametry hráčů se generují lokálně a nic se neposílá na server.
/// Slouží k proklikání a odladění funkcí, než se pustí ostrý provoz.
///
/// ## Co se zapnutým mockem mění
///
/// - Fantasy i tipování jsou přístupné bez přihlášení
/// - Parametry hráčů se generují (`FantasyMockAttributes`)
/// - Čtení ze serveru (sestavy, skóre, žebříčky) se přeskakuje
/// - Žebříčky ukazují lokální demo s boty
///
/// - Important: Před ostrým provozem přepnout na `false` **a** spustit migraci
///   `supabase/migrations/20260727000000_fantasy_tipping.sql`.
enum FantasyMock {
    /// Zapnutý demo režim.
    static let enabled = true
}

/// Generátor náhradních FIFA parametrů pro demo režim.
///
/// Než trenéři vyplní `player_attributes`, potřebujeme, aby kartičky vypadaly
/// realisticky. Parametry se proto odvodí z ratingu ze sezónních statistik a
/// rozhýbou deterministickým šumem, takže se hráči od sebe liší, ale výsledek
/// je pro stejného hráče **vždy stejný** (jinak by se čísla měnila při každém
/// otevření obrazovky).
///
/// - Note: Používá se jen když `FantasyMock.enabled == true`.
enum FantasyMockAttributes {
    /// Hráči, kterým se rating nastaví napevno, bez ohledu na statistiky.
    ///
    /// Klíč je příjmení malými písmeny (s diakritikou i bez, ať se trefíme
    /// nezávisle na zápisu v datech), hodnota je cílové OVR — kvůli efektu
    /// „Čejka má 99".
    static let starOverall: [String: Int] = [
        "čejka": 99, "cejka": 99,
        "mácha": 93, "macha": 93,
    ]

    /// Vygeneruje parametry pro celou skupinu hráčů.
    ///
    /// - Parameter players: Hráči, kterým se mají parametry vytvořit.
    /// - Returns: Parametry podle `Player.id`.
    static func map(for players: [Player]) -> [String: PlayerAttributes] {
        var result: [String: PlayerAttributes] = [:]
        for player in players { result[player.id] = attributes(for: player) }
        return result
    }

    /// Vygeneruje parametry jednoho hráče.
    ///
    /// Kolem cílové úrovně (rating ze statistik, nebo pevné OVR u hvězdy) se
    /// jednotlivé parametry rozloží podle pozice — útočník má lepší střelu a
    /// rychlost, obránce defenzivu — a přidá se deterministický šum ±6.
    ///
    /// - Parameter player: Hráč, pro kterého se parametry generují.
    /// - Returns: Kompletní sada parametrů pro jeho pozici.
    static func attributes(for player: Player) -> PlayerAttributes {
        let base = FantasyRules.statRating(for: player) // 55–94
        let star = starOverall[player.lastName.lowercased()]
        let center = star ?? base

        func value(_ salt: String, bias: Int) -> Int {
            clamp(center + bias + jitter(seed: player.id + salt))
        }

        switch player.position {
        case .forward:
            return PlayerAttributes(
                playerId: player.id,
                speed: value("sp", bias: 4),
                strength: value("st", bias: -5),
                shooting: value("sh", bias: 5),
                passing: value("pa", bias: 1),
                dribbling: value("dr", bias: 3),
                iq: value("iq", bias: 1),
                defense: value("df", bias: -7),
                reflexes: nil, positioning: nil, glove: nil,
                blocker: nil, rebound: nil, composure: nil,
                overall: star
            )
        case .defenseman:
            return PlayerAttributes(
                playerId: player.id,
                speed: value("sp", bias: -1),
                strength: value("st", bias: 5),
                shooting: value("sh", bias: -3),
                passing: value("pa", bias: 2),
                dribbling: value("dr", bias: -3),
                iq: value("iq", bias: 3),
                defense: value("df", bias: 6),
                reflexes: nil, positioning: nil, glove: nil,
                blocker: nil, rebound: nil, composure: nil,
                overall: star
            )
        case .goalie:
            return PlayerAttributes(
                playerId: player.id,
                speed: nil, strength: nil, shooting: nil, passing: nil,
                dribbling: nil, iq: nil, defense: nil,
                reflexes: value("rf", bias: 4),
                positioning: value("po", bias: 3),
                glove: value("gl", bias: 2),
                blocker: value("bl", bias: 1),
                rebound: value("rb", bias: 0),
                composure: value("co", bias: 2),
                overall: star
            )
        }
    }

    /// Ořízne parametr na rozumné demo rozpětí 40–99.
    private static func clamp(_ value: Int) -> Int { min(99, max(40, value)) }

    /// Deterministický „šum" −6…+6 pro rozhýbání parametrů.
    ///
    /// Staví na FNV-1a hashi, ne na náhodě — pro stejný vstup vrátí vždy
    /// stejné číslo, takže se hráči parametry nemění mezi spuštěními.
    ///
    /// - Parameter seed: Vstup hashe, typicky `player.id` + název parametru.
    /// - Returns: Odchylka v rozsahu −6…+6.
    private static func jitter(seed: String) -> Int {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211 }
        return Int(hash % 13) - 6
    }
}

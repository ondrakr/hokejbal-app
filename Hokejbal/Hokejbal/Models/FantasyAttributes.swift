import Foundation

/// FIFA-styl parametry jednoho hráče, ze kterých se počítá OVR na kartičce.
///
/// Hodnoty jsou v rozsahu **1–99** a vyplňují je trenéři klubů (zatím ručně
/// v tabulce `player_attributes`). Všechny jsou volitelné: hráč, kterému
/// parametry nikdo nevyplnil, dostane OVR dopočítané ze sezónních statistik
/// — viz `FantasyRules.rating(for:)`. Díky tomu appka funguje i před tím,
/// než kluby cokoli vyplní.
///
/// Sada parametrů se liší podle pozice: hráči do pole mají sedm herních
/// vlastností, brankáři vlastních šest.
struct PlayerAttributes: Codable, Hashable, Sendable {
    /// ID hráče, ke kterému parametry patří (`Player.id`).
    let playerId: String

    // MARK: Hráči do pole

    /// Rychlost bruslení a akcelerace.
    var speed: Int?
    /// Fyzická síla, souboje u mantinelu.
    var strength: Int?
    /// Tvrdost a přesnost střely.
    var shooting: Int?
    /// Přesnost a čtení přihrávek.
    var passing: Int?
    /// Práce s míčkem, klička jeden na jednoho.
    var dribbling: Int?
    /// Herní inteligence — čtení hry, postavení, rozhodování.
    var iq: Int?
    /// Defenzivní práce, obranné souboje, blokování střel.
    var defense: Int?

    // MARK: Brankáři

    /// Reflexy na rychlé zákroky.
    var reflexes: Int?
    /// Postavení v brankovišti.
    var positioning: Int?
    /// Chytání lapačkou.
    var glove: Int?
    /// Zákroky vyrážečkou.
    var blocker: Int?
    /// Práce s dorážkami — kam pouští odražené míčky.
    var rebound: Int?
    /// Klid a koncentrace v tlaku.
    var composure: Int?

    /// OVR předpočítané na serveru.
    ///
    /// Když je vyplněné, má přednost před váženým průměrem parametrů. Slouží
    /// k ručnímu přepsání ratingu (např. hvězda, které chceme dát rovnou 99).
    var overall: Int?

    /// Vyplněné parametry pro danou pozici i s českými popisky.
    ///
    /// Prázdné (nevyplněné) parametry vynechává, takže scout karta nikdy
    /// nezobrazí řádek bez hodnoty.
    ///
    /// - Parameter position: Pozice hráče — rozhoduje, jestli se vrátí sada
    ///   pro brankáře, nebo pro hráče do pole.
    /// - Returns: Dvojice popisek + hodnota v pořadí, v jakém se mají vykreslit.
    func displayRows(position: PlayerPosition) -> [(label: String, value: Int)] {
        let pairs: [(String, Int?)]
        switch position {
        case .goalie:
            pairs = [
                ("Reflexy", reflexes),
                ("Postavení", positioning),
                ("Lapačka", glove),
                ("Vyrážečka", blocker),
                ("Vyrážení", rebound),
                ("Klid", composure),
            ]
        case .defenseman, .forward:
            pairs = [
                ("Rychlost", speed),
                ("Síla", strength),
                ("Střela", shooting),
                ("Přihrávka", passing),
                ("Dribling", dribbling),
                ("Chytrost", iq),
                ("Obrana", defense),
            ]
        }
        return pairs.compactMap { label, value in
            value.map { (label, $0) }
        }
    }

    /// Spočítá OVR (číslo na kartičce) z vyplněných parametrů.
    ///
    /// Váhy se liší podle pozice, aby rating odpovídal tomu, co je pro danou
    /// roli důležité — útočníkovi se nejvíc počítá střela a rychlost,
    /// obránci defenziva a síla. Brankáři mají všech šest parametrů stejně.
    ///
    /// Průměr je vážený jen přes **vyplněné** parametry (dělí se součtem
    /// jejich vah), takže částečně vyplněný hráč nedostane uměle nízké číslo.
    /// Když je vyplněné `overall`, vrátí se rovnou ono.
    ///
    /// - Parameter position: Pozice hráče — určuje sadu parametrů a jejich váhy.
    /// - Returns: OVR v rozsahu 1–99, nebo `nil`, když není vyplněný ani jeden
    ///   parametr pro danou pozici (volající pak sáhne po statistikách).
    func computedOverall(position: PlayerPosition) -> Int? {
        if let overall { return clampRating(overall) }

        let weighted: [(value: Int?, weight: Double)]
        switch position {
        case .forward:
            weighted = [
                (shooting, 0.25), (speed, 0.20), (dribbling, 0.15), (iq, 0.15),
                (passing, 0.15), (strength, 0.05), (defense, 0.05),
            ]
        case .defenseman:
            weighted = [
                (defense, 0.28), (iq, 0.18), (strength, 0.18), (passing, 0.16),
                (speed, 0.10), (shooting, 0.05), (dribbling, 0.05),
            ]
        case .goalie:
            weighted = [
                (reflexes, 1), (positioning, 1), (glove, 1),
                (blocker, 1), (rebound, 1), (composure, 1),
            ]
        }

        var sum = 0.0
        var totalWeight = 0.0
        for (value, weight) in weighted {
            guard let value else { continue }
            sum += Double(value) * weight
            totalWeight += weight
        }
        guard totalWeight > 0 else { return nil }
        return clampRating(Int((sum / totalWeight).rounded()))
    }

    /// Ořízne hodnotu do povoleného rozsahu 1–99.
    private func clampRating(_ value: Int) -> Int {
        min(99, max(1, value))
    }
}

/// Jeden řádek tabulky `player_attributes` tak, jak přijde ze Supabase.
///
/// Sloupce jsou v databázi `snake_case`, dekodér je převádí přes
/// `convertFromSnakeCase` (viz `SupabaseAuthAPI`). Do zbytku appky se
/// překlápí přes `asModel`, aby DTO nikde neprosakovalo.
struct PlayerAttributesRow: Decodable {
    let playerId: String
    let speed: Int?
    let strength: Int?
    let shooting: Int?
    let passing: Int?
    let dribbling: Int?
    let iq: Int?
    let defense: Int?
    let reflexes: Int?
    let positioning: Int?
    let glove: Int?
    let blocker: Int?
    let rebound: Int?
    let composure: Int?
    let overall: Int?

    /// Převede databázový řádek na doménový model.
    var asModel: PlayerAttributes {
        PlayerAttributes(
            playerId: playerId,
            speed: speed, strength: strength, shooting: shooting, passing: passing,
            dribbling: dribbling, iq: iq, defense: defense,
            reflexes: reflexes, positioning: positioning, glove: glove,
            blocker: blocker, rebound: rebound, composure: composure,
            overall: overall
        )
    }
}

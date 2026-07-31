import Foundation

/// FIFA-styl parametry hráče (1–99). Vyplňují je později trenéři/admin;
/// když chybí, OVR se dopočítá ze sezónních statistik (viz `FantasyRules.rating`).
struct PlayerAttributes: Codable, Hashable, Sendable {
    let playerId: String
    // hráči do pole
    var speed: Int?
    var strength: Int?
    var shooting: Int?
    var passing: Int?
    var dribbling: Int?
    var iq: Int?
    var defense: Int?
    // brankáři
    var reflexes: Int?
    var positioning: Int?
    var glove: Int?
    var blocker: Int?
    var rebound: Int?
    var composure: Int?
    /// Předpočítané OVR ze serveru (má přednost, pokud je vyplněné).
    var overall: Int?

    /// Popisky parametrů pro danou pozici (jen ty vyplněné) — pro scout kartu.
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

    /// OVR z parametrů (pozičně vážený průměr). Vrací nil, když nic není vyplněné.
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

    private func clampRating(_ value: Int) -> Int {
        min(99, max(1, value))
    }
}

/// Řádek z tabulky `player_attributes` (snake_case → convertFromSnakeCase).
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

import Foundation

/// FIFA-style attributes of a single player, the basis of the card rating.
///
/// Values range from **1 to 99** and are filled in by club coaches (for now by
/// hand in the `player_attributes` table). All of them are optional: a player
/// nobody has rated yet gets an overall derived from season statistics — see
/// `FantasyRules.rating(for:)`. That keeps the app working before clubs fill
/// anything in.
///
/// The set differs by position: skaters have seven attributes, goalies their
/// own six.
struct PlayerAttributes: Codable, Hashable, Sendable {
    /// The player these attributes belong to (`Player.id`).
    let playerId: String

    // MARK: Skaters

    /// Skating speed and acceleration.
    var speed: Int?
    /// Physical strength, battles along the boards.
    var strength: Int?
    /// Shot power and accuracy.
    var shooting: Int?
    /// Passing accuracy and vision.
    var passing: Int?
    /// Puck handling, beating a defender one on one.
    var dribbling: Int?
    /// Hockey IQ — reading the play, positioning, decision making.
    var iq: Int?
    /// Defensive work, defensive battles, shot blocking.
    var defense: Int?

    // MARK: Goalies

    /// Reflexes on quick saves.
    var reflexes: Int?
    /// Positioning in the crease.
    var positioning: Int?
    /// Glove hand.
    var glove: Int?
    /// Blocker saves.
    var blocker: Int?
    /// Rebound control — where loose pucks end up.
    var rebound: Int?
    /// Composure under pressure.
    var composure: Int?

    /// Overall precomputed on the server.
    ///
    /// When present it wins over the weighted average of the attributes. Used
    /// to override a rating by hand (e.g. a star we want to sit at 99).
    var overall: Int?

    /// The filled-in attributes for a position, with display labels.
    ///
    /// Skips empty attributes, so the scout sheet never renders a row without
    /// a value.
    ///
    /// - Parameter position: The player's position — decides whether the goalie
    ///   or the skater set is returned.
    /// - Returns: Label and value pairs in the order they should be rendered.
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

    /// Computes the overall (the number on the card) from the attributes.
    ///
    /// Weights differ by position so the rating reflects what matters for the
    /// role — shooting and speed carry a forward, defense and strength a
    /// defenseman. Goalies weigh all six attributes equally.
    ///
    /// The average only covers **filled-in** attributes (dividing by the sum of
    /// their weights), so a partially rated player is not dragged down. If
    /// `overall` is set, it is returned as is.
    ///
    /// - Parameter position: The player's position — picks the attribute set and
    ///   its weights.
    /// - Returns: Overall between 1 and 99, or `nil` when not a single attribute
    ///   for that position is set (the caller then falls back to statistics).
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

    /// Clamps a value into the allowed 1–99 range.
    private func clampRating(_ value: Int) -> Int {
        min(99, max(1, value))
    }
}

/// A single `player_attributes` row as it arrives from Supabase.
///
/// Columns are `snake_case` in the database and converted by the decoder via
/// `convertFromSnakeCase` (see `SupabaseAuthAPI`). Mapped into the app through
/// `asModel` so the DTO never leaks further.
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

    /// Maps the database row onto the domain model.
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

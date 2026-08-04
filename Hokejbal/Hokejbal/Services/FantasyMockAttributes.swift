import Foundation

/// Demo-mode switch for Fantasy and the tipping game.
///
/// While on, the app needs neither the database migration nor an account —
/// player attributes are generated locally and nothing is sent to the server.
/// Meant for clicking through and polishing the features before going live.
///
/// ## What the mock changes
///
/// - Fantasy and tipping are reachable without signing in
/// - Player attributes are generated (`FantasyMockAttributes`)
/// - Server reads (squads, scores, leaderboards) are skipped
/// - Leaderboards show the local demo with bots
///
/// - Important: Before going live switch this to `false` **and** run
///   `supabase/migrations/20260727000000_fantasy_tipping.sql`.
enum FantasyMock {
    /// Demo mode is on.
    static let enabled = true
}

/// Generates stand-in FIFA attributes for demo mode.
///
/// Until coaches fill in `player_attributes`, cards still need to look
/// believable. Attributes are therefore derived from the stats-based rating and
/// spread out with deterministic noise, so players differ from each other while
/// the result stays **identical for the same player** (otherwise the numbers
/// would change on every screen open).
///
/// - Note: Only used while `FantasyMock.enabled == true`.
enum FantasyMockAttributes {
    /// Players whose rating is pinned regardless of their statistics.
    ///
    /// Keyed by lowercased surname (with and without diacritics, to match
    /// whichever spelling the data uses); the value is the target overall —
    /// this is what makes "Čejka is a 99" work.
    static let starOverall: [String: Int] = [
        "čejka": 99, "cejka": 99,
        "mácha": 93, "macha": 93,
    ]

    /// Generates attributes for a whole group of players.
    ///
    /// - Parameter players: Players to generate attributes for.
    /// - Returns: Attributes keyed by `Player.id`.
    static func map(for players: [Player]) -> [String: PlayerAttributes] {
        var result: [String: PlayerAttributes] = [:]
        for player in players { result[player.id] = attributes(for: player) }
        return result
    }

    /// Generates attributes for a single player.
    ///
    /// Around a target level (the stats rating, or the pinned overall for a
    /// star) the individual attributes are spread by position — a forward gets
    /// a better shot and speed, a defenseman better defense — plus
    /// deterministic noise of ±6.
    ///
    /// - Parameter player: The player to generate for.
    /// - Returns: A full attribute set for their position.
    static func attributes(for player: Player) -> PlayerAttributes {
        let base = FantasyRules.statRating(for: player) // 55–94
        let star = starOverall[player.lastName.lowercased()]
        let center = star ?? base

        /// One attribute: target level + positional bias + deterministic noise.
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

    /// Clamps an attribute into a sensible 40–99 demo range.
    private static func clamp(_ value: Int) -> Int { min(99, max(40, value)) }

    /// Deterministic noise of −6…+6 used to spread the attributes out.
    ///
    /// Built on an FNV-1a hash rather than randomness — the same input always
    /// yields the same number, so a player's attributes stay put between runs.
    ///
    /// - Parameter seed: Hash input, typically `player.id` + the attribute name.
    /// - Returns: An offset between −6 and +6.
    private static func jitter(seed: String) -> Int {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211 }
        return Int(hash % 13) - 6
    }
}

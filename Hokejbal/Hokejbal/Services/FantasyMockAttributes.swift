import Foundation

/// Globální přepínač: appka zatím jede na mock datech (bez Supabase migrace / loginu),
/// aby šlo všechno proklikat. Až půjdeme naostro, přepni na `false`.
enum FantasyMock {
    static let enabled = true
}

/// Deterministicky vygeneruje FIFA parametry hráče ze statistik + pár hvězd napevno.
/// Slouží k proklikání appky, než parametry doplní trenéři do `player_attributes`.
enum FantasyMockAttributes {
    /// Vybrané hvězdy — lowercased příjmení → cílové OVR (pro efekt „Čejka 99“).
    static let starOverall: [String: Int] = [
        "čejka": 99, "cejka": 99,
        "mácha": 93, "macha": 93,
    ]

    static func map(for players: [Player]) -> [String: PlayerAttributes] {
        var result: [String: PlayerAttributes] = [:]
        for player in players { result[player.id] = attributes(for: player) }
        return result
    }

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

    private static func clamp(_ value: Int) -> Int { min(99, max(40, value)) }

    /// Deterministický „šum" −6…+6 z FNV-1a hashe (stabilní pro daného hráče).
    private static func jitter(seed: String) -> Int {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211 }
        return Int(hash % 13) - 6
    }
}

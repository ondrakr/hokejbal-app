import Foundation
import SwiftUI

/// Načítá FIFA parametry hráčů z tabulky `player_attributes` (veřejné SELECT).
/// Cache v paměti; když hráč atributy nemá, `FantasyRules` spadne na statistiky.
@MainActor
final class FantasyAttributesStore: ObservableObject {
    @Published private(set) var byPlayerId: [String: PlayerAttributes] = [:]
    @Published private(set) var isLoaded = false

    /// Vlastní klient (jen public SELECT přes anon key) — nezávisí na přihlášení.
    private let api = SupabaseAuthAPI()
    private var isLoading = false

    func loadIfNeeded() async {
        guard !isLoaded, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let rows = try await api.fetchPlayerAttributes()
            var map: [String: PlayerAttributes] = [:]
            for row in rows { map[row.playerId] = row.asModel }
            byPlayerId = map
            // Zpřístupní parametry pravidlům (OVR z parametrů napříč appkou).
            FantasyRules.attributesByPlayerId = map
            isLoaded = true
        } catch {
            // Soft-fail — appka jede na fallback OVR ze statistik.
        }
    }

    func attributes(for playerId: String) -> PlayerAttributes? {
        byPlayerId[playerId]
    }

    /// Mock parametry pro proklikání (FantasyMock). Reálná serverová data mají přednost.
    func seedMock(for players: [Player]) {
        guard !players.isEmpty else { return }
        var merged = FantasyMockAttributes.map(for: players)
        for (id, attrs) in byPlayerId { merged[id] = attrs }
        byPlayerId = merged
        FantasyRules.attributesByPlayerId = merged
        isLoaded = true
    }
}

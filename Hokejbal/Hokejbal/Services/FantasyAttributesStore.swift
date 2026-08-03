import Foundation
import SwiftUI

/// Holds the FIFA-style attributes every player card rating is built from.
///
/// Loaded once (the `player_attributes` table is publicly readable, so no sign
/// in is needed) and kept in memory — cards are rendered a lot and the rating
/// is recomputed on every market sort.
///
/// ## Two modes
///
/// - **Live:** `loadIfNeeded()` fetches attributes from Supabase.
/// - **Mock (`FantasyMock.enabled`):** `seedMock(for:)` derives them from season
///   stats, so Fantasy is clickable without the migration or an account.
///
/// Either way the result is mirrored into `FantasyRules.attributesByPlayerId`,
/// which is where the rating calculation reads from.
///
/// Injected as an `@EnvironmentObject` in `HokejbalApp`.
@MainActor
final class FantasyAttributesStore: ObservableObject {
    /// Attributes by `Player.id`. Players missing here fall back to season stats.
    @Published private(set) var byPlayerId: [String: PlayerAttributes] = [:]

    /// `true` once attributes are available (from the server or the mock).
    @Published private(set) var isLoaded = false

    /// Own client — reads public data only, no authentication required.
    private let api = SupabaseAuthAPI()

    /// Guards against two concurrent loads when a view appears twice in a row.
    private var isLoading = false

    /// Fetches attributes unless they are already loaded or in flight.
    ///
    /// Safe to call from any `.task` — repeated calls are no-ops.
    func loadIfNeeded() async {
        guard !isLoaded, !isLoading else { return }
        await load()
    }

    /// Fetches attributes from Supabase and shares them with the rules.
    ///
    /// Errors are swallowed on purpose: if the fetch fails (offline, outage),
    /// the app keeps running on stats-based ratings, so a broken network never
    /// takes Fantasy down.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let rows = try await api.fetchPlayerAttributes()
            var map: [String: PlayerAttributes] = [:]
            for row in rows { map[row.playerId] = row.asModel }
            byPlayerId = map
            // Hand the attributes to the rules so ratings use them app-wide.
            FantasyRules.attributesByPlayerId = map
            isLoaded = true
        } catch {
            // Soft-fail — the app falls back to stats-based ratings.
        }
    }

    /// Attributes of a single player.
    ///
    /// - Parameter playerId: The `Player.id` to look up.
    /// - Returns: The attributes, or `nil` when the player has none.
    func attributes(for playerId: String) -> PlayerAttributes? {
        byPlayerId[playerId]
    }

    /// Fills in generated attributes for demo mode (`FantasyMock`).
    ///
    /// Real server data wins — the mock only covers players that have no
    /// attributes yet, so live values are never overwritten.
    ///
    /// - Parameter players: Players to generate attributes for.
    func seedMock(for players: [Player]) {
        guard !players.isEmpty else { return }
        var merged = FantasyMockAttributes.map(for: players)
        for (id, attrs) in byPlayerId { merged[id] = attrs }
        byPlayerId = merged
        FantasyRules.attributesByPlayerId = merged
        isLoaded = true
    }
}

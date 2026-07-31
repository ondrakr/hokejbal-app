import Foundation
import SwiftUI

/// Drží FIFA parametry všech hráčů, ze kterých se počítá OVR na kartičkách.
///
/// Data se načtou jednou (tabulka `player_attributes` je veřejně čitelná,
/// takže není potřeba přihlášení) a drží se v paměti — kartiček se vykresluje
/// hodně a rating se počítá při každém řazení trhu.
///
/// ## Dva režimy
///
/// - **Ostrý provoz:** `loadIfNeeded()` stáhne parametry ze Supabase.
/// - **Mock (`FantasyMock.enabled`):** `seedMock(for:)` je vygeneruje ze
///   statistik, takže je Fantasy proklikatelná bez migrace i bez účtu.
///
/// V obou případech se výsledek propíše i do `FantasyRules.attributesByPlayerId`,
/// odkud si ho bere výpočet ratingu.
///
/// Injektuje se jako `@EnvironmentObject` v `HokejbalApp`.
@MainActor
final class FantasyAttributesStore: ObservableObject {
    /// Parametry podle `Player.id`. Hráči, kteří tu nejsou, jedou na statistiky.
    @Published private(set) var byPlayerId: [String: PlayerAttributes] = [:]

    /// `true`, jakmile jsou parametry k dispozici (ze serveru nebo z mocku).
    @Published private(set) var isLoaded = false

    /// Vlastní klient — čte jen veřejná data, nepotřebuje přihlášení.
    private let api = SupabaseAuthAPI()

    /// Brání dvěma souběžným stažením, když se view objeví dvakrát rychle po sobě.
    private var isLoading = false

    /// Stáhne parametry, pokud ještě nejsou načtené a zrovna se nenačítají.
    ///
    /// Bezpečné volat z každého `.task` — opakované volání nic nedělá.
    func loadIfNeeded() async {
        guard !isLoaded, !isLoading else { return }
        await load()
    }

    /// Stáhne parametry ze Supabase a nasdílí je pravidlům.
    ///
    /// Chybu záměrně polyká: když se stahování nepovede (offline, výpadek),
    /// appka jede dál na ratingu ze statistik. Rozbitá síť tedy neshodí Fantasy.
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

    /// Parametry konkrétního hráče.
    ///
    /// - Parameter playerId: `Player.id`.
    /// - Returns: Parametry, nebo `nil`, když hráč žádné nemá.
    func attributes(for playerId: String) -> PlayerAttributes? {
        byPlayerId[playerId]
    }

    /// Doplní vygenerované parametry pro demo režim (`FantasyMock`).
    ///
    /// Reálná data ze serveru mají přednost — mock se použije jen tam, kde
    /// hráč parametry zatím nemá, takže se ostrá data nikdy nepřepíšou.
    ///
    /// - Parameter players: Hráči, kterým se mají parametry dogenerovat.
    func seedMock(for players: [Player]) {
        guard !players.isEmpty else { return }
        var merged = FantasyMockAttributes.map(for: players)
        for (id, attrs) in byPlayerId { merged[id] = attrs }
        byPlayerId = merged
        FantasyRules.attributesByPlayerId = merged
        isLoaded = true
    }
}

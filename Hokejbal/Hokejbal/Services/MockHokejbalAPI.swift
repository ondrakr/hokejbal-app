import Foundation

/// Lokální mock s reálnými názvy týmů z Extraligy hokejbalu.
/// Live zápasy periodicky „tikají“ skóre pro simulaci live výsledků.
actor MockHokejbalAPI: HokejbalAPI {
    static let shared = MockHokejbalAPI()

    private let calendar = Calendar.current
    private var liveTick: Int = 0

    private let competitionsData: [Competition]
    private let teamsData: [Team]
    private var playersData: [Player]
    private let standingsByCompetition: [String: [StandingRow]]
    private let newsData: [NewsArticle]
    private var matchesStore: [Match]


    private static func makePlayers() -> [Player] {
        [
            .init(id: "hos-drahos", firstName: "Marek", lastName: "Drahoš", number: 31, position: .goalie, teamId: "hostivar", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mokry", firstName: "Vojtěch", lastName: "Mokry", number: 32, position: .goalie, teamId: "hostivar", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "hos-stoural", firstName: "Václav", lastName: "Štoural", number: 33, position: .goalie, teamId: "hostivar", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "hos-capek", firstName: "Dalibor", lastName: "Čápek", number: 6, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-ciz", firstName: "Patrik", lastName: "Číž", number: 7, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-hrabar", firstName: "Jiří", lastName: "Hrabár", number: 8, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-ilusak", firstName: "Dominik", lastName: "Ilušák", number: 9, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-markytan", firstName: "Jaromír", lastName: "Markytán", number: 10, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-pirek", firstName: "Petr", lastName: "Pírek", number: 11, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-prucha", firstName: "Michal", lastName: "Průcha", number: 12, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-sloup", firstName: "Pavel", lastName: "Sloup", number: 13, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-vanis", firstName: "Daniel", lastName: "Vaniš", number: 14, position: .defenseman, teamId: "hostivar", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "cejka", firstName: "Jan", lastName: "Čejka", number: 20, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-divis", firstName: "Jan", lastName: "Diviš", number: 21, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-dostal", firstName: "Ondřej", lastName: "Dostál", number: 22, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-kern", firstName: "Jan", lastName: "Kern", number: 23, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-krticka", firstName: "Jan", lastName: "Krtička", number: 24, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-neokucharcik", firstName: "Samuel", lastName: "Neo Kucharčík", number: 25, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-patek", firstName: "Jaroslav", lastName: "Pátek", number: 26, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-smerha", firstName: "Tomáš", lastName: "Šmerha", number: 27, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-stastny", firstName: "Adam", lastName: "Šťastný", number: 28, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-urbanec", firstName: "Otto", lastName: "Urbanec", number: 29, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hos-vanis2", firstName: "Jiří", lastName: "Vaniš", number: 30, position: .forward, teamId: "hostivar", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-kremenak", firstName: "Antonín", lastName: "Křemenák", number: 31, position: .goalie, teamId: "letohrad", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "let-manucarjan", firstName: "David", lastName: "Manučarjan", number: 32, position: .goalie, teamId: "letohrad", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "let-novak", firstName: "Michal", lastName: "Novák", number: 33, position: .goalie, teamId: "letohrad", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "let-sterencak", firstName: "Lukáš", lastName: "Sterenčák", number: 34, position: .goalie, teamId: "letohrad", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "let-adamec", firstName: "Miroslav", lastName: "Adamec", number: 7, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-anyz", firstName: "Lukáš", lastName: "Anýž", number: 8, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-becka", firstName: "Jan", lastName: "Bečka", number: 9, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-doskocil", firstName: "Peter", lastName: "Doskočil", number: 10, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-dostal", firstName: "Radim", lastName: "Dostál", number: 11, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-horacek", firstName: "David", lastName: "Horáček", number: 12, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-horvath", firstName: "Lukáš", lastName: "Horváth", number: 13, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-hubalek", firstName: "Ondřej", lastName: "Hubálek", number: 14, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-jurasko", firstName: "Viktor", lastName: "Juraško", number: 15, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-levy", firstName: "David", lastName: "Levý", number: 16, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-lux", firstName: "Filip", lastName: "Lux", number: 17, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-nazad", firstName: "Marcel", lastName: "Nazad", number: 18, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-prazak", firstName: "Tomáš", lastName: "Pražák", number: 19, position: .defenseman, teamId: "letohrad", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-bogdany", firstName: "Vojtěch", lastName: "Bogdány", number: 25, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-brozek", firstName: "David", lastName: "Brožek", number: 26, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-bursik", firstName: "David", lastName: "Buršík", number: 27, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-cvejn", firstName: "Jakub", lastName: "Cvejn", number: 28, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-faltejsek", firstName: "Lukáš", lastName: "Faltejsek", number: 29, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-faltus", firstName: "Filip", lastName: "Faltus", number: 30, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-fiser", firstName: "Jakub", lastName: "Fišer", number: 31, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-halbrstat", firstName: "David", lastName: "Halbrštát", number: 7, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-holik", firstName: "Adam", lastName: "Holík", number: 8, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-lajciak", firstName: "Lukáš", lastName: "Lajčiak", number: 9, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-lhota", firstName: "Lukáš", lastName: "Lhota", number: 10, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-lhota2", firstName: "Tomáš", lastName: "Lhota", number: 11, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-machacek", firstName: "Michal", lastName: "Macháček", number: 12, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-maly", firstName: "Matyáš", lastName: "Malý", number: 13, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-protzner", firstName: "Jaromír", lastName: "Protzner", number: 14, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-puzder", firstName: "Tomáš", lastName: "Puzder", number: 15, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-rozlilek", firstName: "Vít", lastName: "Rozlílek", number: 16, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-sima", firstName: "Petr", lastName: "Šíma", number: 17, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-svec", firstName: "Štěpán", lastName: "Švec", number: 18, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-vencl", firstName: "Jan", lastName: "Vencl", number: 19, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "let-vodvarka", firstName: "Petr", lastName: "Vodvárka", number: 20, position: .forward, teamId: "letohrad", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-gerlich", firstName: "Leoš", lastName: "Gerlich", number: 31, position: .goalie, teamId: "kert", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ker-mikl", firstName: "Petr", lastName: "Mikl", number: 32, position: .goalie, teamId: "kert", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ker-milec", firstName: "Matyáš", lastName: "Milec", number: 33, position: .goalie, teamId: "kert", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ker-rehor", firstName: "Adam", lastName: "Řehoř", number: 34, position: .goalie, teamId: "kert", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ker-toth", firstName: "Jakub", lastName: "Toth", number: 30, position: .goalie, teamId: "kert", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ker-blasko", firstName: "Jan", lastName: "Blaško", number: 8, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-hrdlicka", firstName: "Pavel", lastName: "Hrdlička", number: 9, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-kovarnik", firstName: "Jakub", lastName: "Kovárník", number: 10, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-laurinc", firstName: "Jakub", lastName: "Laurinc", number: 11, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-macek", firstName: "Filip", lastName: "Macek", number: 12, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-peschout", firstName: "Richard", lastName: "Peschout", number: 13, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-rozenberg", firstName: "David", lastName: "Rozenberg", number: 14, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-sperl", firstName: "David", lastName: "Šperl", number: 15, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-stastny", firstName: "Adam", lastName: "Šťastný", number: 16, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-vrabec", firstName: "František", lastName: "Vrabec", number: 17, position: .defenseman, teamId: "kert", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-barnosak", firstName: "Dominik", lastName: "Barnošák", number: 23, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-fejfar", firstName: "Tomáš", lastName: "Fejfar", number: 24, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-hlavka", firstName: "Tadeáš", lastName: "Hlávka", number: 25, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-hnyk", firstName: "Matěj", lastName: "Hnyk", number: 26, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-jagr", firstName: "Vojtěch", lastName: "Jágr", number: 27, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-javurek", firstName: "Michal", lastName: "Javůrek", number: 28, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-jelen", firstName: "Milan", lastName: "Jelen", number: 29, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-krucek", firstName: "Martin", lastName: "Kruček", number: 30, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-mejzlik", firstName: "Marek", lastName: "Mejzlík", number: 31, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-pala", firstName: "Martin", lastName: "Pala", number: 7, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-pavlik", firstName: "Jan", lastName: "Pavlík", number: 8, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-vanek", firstName: "Radomír", lastName: "Vaněk", number: 9, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-wrobel", firstName: "Jakub", lastName: "Wróbel", number: 10, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-wrobel2", firstName: "Tomáš", lastName: "Wróbel", number: 11, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ker-zvonek", firstName: "Dalimil", lastName: "Zvonek", number: 12, position: .forward, teamId: "kert", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-halouzka", firstName: "Matěj", lastName: "Halouzka", number: 31, position: .goalie, teamId: "svitkov", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "svi-novotny", firstName: "Lukáš", lastName: "Novotný", number: 32, position: .goalie, teamId: "svitkov", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "svi-stovicek", firstName: "Jiří", lastName: "Šťovíček", number: 33, position: .goalie, teamId: "svitkov", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "svi-adam", firstName: "Petr", lastName: "Adam", number: 6, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-bures", firstName: "Tomáš", lastName: "Bureš", number: 7, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-hudec", firstName: "Tomáš", lastName: "Hudec", number: 8, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-kastanek", firstName: "Vít", lastName: "Kaštánek", number: 9, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-korbel", firstName: "Martin", lastName: "Korbel", number: 10, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-korec", firstName: "Adam", lastName: "Korec", number: 11, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-kubicek", firstName: "Martin", lastName: "Kubíček", number: 12, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-paulovic", firstName: "Matej", lastName: "Paulovič", number: 13, position: .defenseman, teamId: "svitkov", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-blaha", firstName: "Matyáš", lastName: "Bláha", number: 19, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-kabrt", firstName: "Matěj", lastName: "Kábrt", number: 20, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-kohoutek", firstName: "Lukáš", lastName: "Kohoutek", number: 21, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-kozel", firstName: "Lukáš", lastName: "Kozel", number: 22, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-kral", firstName: "Jakub", lastName: "Král", number: 23, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-macenauer", firstName: "Dominik", lastName: "Macenauer", number: 24, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-matys", firstName: "Daniel", lastName: "Matýs", number: 25, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-matys2", firstName: "Ondřej", lastName: "Matýs", number: 26, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-patera", firstName: "Lukáš", lastName: "Patera", number: 27, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-peca", firstName: "Jakub", lastName: "Peca", number: 28, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-pilar", firstName: "Tomáš", lastName: "Pilař", number: 29, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-prochazka", firstName: "Adam", lastName: "Procházka", number: 30, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-rosulek", firstName: "Lumír", lastName: "Rosůlek", number: 31, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-stromko", firstName: "Jan", lastName: "Stromko", number: 7, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "svi-vizvary", firstName: "Richard", lastName: "Vizváry", number: 8, position: .forward, teamId: "svitkov", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-kolar", firstName: "Kristián", lastName: "Kolář", number: 31, position: .goalie, teamId: "plzen", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "plz-kracina", firstName: "Petr", lastName: "Kráčina", number: 32, position: .goalie, teamId: "plzen", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "plz-benedikt", firstName: "Jiří", lastName: "Benedikt", number: 5, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-chramosta", firstName: "Tomáš", lastName: "Chramosta", number: 6, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-hanus", firstName: "Lukáš", lastName: "Hanuš", number: 7, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kral", firstName: "Dan", lastName: "Král", number: 8, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-matousek", firstName: "Michal", lastName: "Matoušek", number: 9, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-silhan", firstName: "Adam", lastName: "Šilhán", number: 10, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-ulc", firstName: "Tomáš", lastName: "Ulč", number: 11, position: .defenseman, teamId: "plzen", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-beranek", firstName: "Jiří", lastName: "Beránek", number: 17, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-deja", firstName: "Matěj", lastName: "Deja", number: 18, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-hajek", firstName: "Adam", lastName: "Hájek", number: 19, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-kohout", firstName: "Martin", lastName: "Kohout", number: 20, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-kolar2", firstName: "Filip", lastName: "Kolář", number: 21, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-lokajicek", firstName: "Vít", lastName: "Lokajíček", number: 22, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-miksan", firstName: "Jan", lastName: "Miksan", number: 23, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-nemcak", firstName: "David", lastName: "Němčák", number: 24, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-polacek", firstName: "Roman", lastName: "Poláček", number: 25, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-prochazka", firstName: "Jaroslav", lastName: "Procházka", number: 26, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-rac", firstName: "Josef", lastName: "Rác", number: 27, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-svarc", firstName: "Marek", lastName: "Švarc", number: 28, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "plz-vobruba", firstName: "Jakub", lastName: "Vobruba", number: 29, position: .forward, teamId: "plzen", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-brtnik", firstName: "Jan", lastName: "Brtník", number: 8, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-duchek", firstName: "Aleš", lastName: "Duchek", number: 9, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-duchek2", firstName: "Tomáš", lastName: "Duchek", number: 10, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-humlicek", firstName: "Tomáš", lastName: "Humlíček", number: 11, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-kolarik", firstName: "Jakub", lastName: "Kolařík", number: 12, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-kovarik", firstName: "Daniel", lastName: "Kovářík", number: 13, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-kovarik2", firstName: "Jan", lastName: "Kovářík", number: 14, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-kuchar", firstName: "Ondřej", lastName: "Kuchař", number: 15, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-kvapil", firstName: "Štěpán", lastName: "Kvapil", number: 16, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-malotin", firstName: "Matěj", lastName: "Malotín", number: 17, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-matousek", firstName: "Jan", lastName: "Matoušek", number: 18, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-neumaier", firstName: "Michal", lastName: "Neumaier", number: 19, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-pavlicek", firstName: "Matěj", lastName: "Pavlíček", number: 20, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-prokop", firstName: "Jan", lastName: "Prokop", number: 21, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-radvansky", firstName: "Daniel", lastName: "Radvanský", number: 22, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-slehofer", firstName: "Václav", lastName: "Šlehofer", number: 23, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-sloup", firstName: "Pavel", lastName: "Sloup", number: 24, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-stepanek", firstName: "Jan", lastName: "Štěpánek", number: 25, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-stepanek2", firstName: "Jiří", lastName: "Štěpánek", number: 26, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "dob-truchly", firstName: "Tomáš", lastName: "Truchlý", number: 27, position: .forward, teamId: "dobrany", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-banda", firstName: "Zdeněk", lastName: "Banda", number: 31, position: .goalie, teamId: "usti", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ust-koudelka", firstName: "Martin", lastName: "Koudelka", number: 32, position: .goalie, teamId: "usti", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ust-rechtorik", firstName: "Tomáš", lastName: "Rechtorik", number: 33, position: .goalie, teamId: "usti", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "ust-grus", firstName: "Jiří", lastName: "Grus", number: 6, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-kastner", firstName: "Zbyšek", lastName: "Kastner", number: 7, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-kohout", firstName: "Pavel", lastName: "Kohout", number: 8, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-michajlicenko", firstName: "Petr", lastName: "Michajličenko", number: 9, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-polacek", firstName: "Ondřej", lastName: "Poláček", number: 10, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-popluhar", firstName: "Aleš", lastName: "Popluhar", number: 11, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-ruzicka", firstName: "Jakub", lastName: "Růžička", number: 12, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-sedlacek", firstName: "Jan", lastName: "Sedláček", number: 13, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-sedlacek2", firstName: "Matěj", lastName: "Sedláček", number: 14, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-vyhlidal", firstName: "Radek", lastName: "Vyhlídal", number: 15, position: .defenseman, teamId: "usti", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-bacovsky", firstName: "Jan", lastName: "Bacovský", number: 21, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-bercik", firstName: "Martin", lastName: "Berčík", number: 22, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-caloun", firstName: "Matyáš", lastName: "Čaloun", number: 23, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-cermak", firstName: "Tomáš", lastName: "Čermák", number: 24, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-cervinka", firstName: "Vojtěch", lastName: "Červinka", number: 25, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-costa", firstName: "Kale", lastName: "Costa", number: 26, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-faigl", firstName: "Tomáš", lastName: "Faigl", number: 27, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-horejs", firstName: "Pavel", lastName: "Horejš", number: 28, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-kapusta", firstName: "Tomáš", lastName: "Kapusta", number: 29, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-kocourek", firstName: "Matěj", lastName: "Kocourek", number: 30, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-krajicek", firstName: "Pavel", lastName: "Krajíček", number: 31, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-krticka", firstName: "Jan", lastName: "Krtička", number: 7, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-kurty", firstName: "Jan", lastName: "Kurty", number: 8, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-macek", firstName: "Aleš", lastName: "Macek", number: 9, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-macek2", firstName: "Marek", lastName: "Macek", number: 10, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-nedoma", firstName: "David", lastName: "Nedoma", number: 11, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-skurla", firstName: "Jan", lastName: "Škurla", number: 12, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-smolik", firstName: "Michal", lastName: "Smolík", number: 13, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-soukup", firstName: "Lukáš", lastName: "Soukup", number: 14, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-stupka", firstName: "Martin", lastName: "Stupka", number: 15, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-tomas", firstName: "Jiří", lastName: "Tomáš", number: 16, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-vacek", firstName: "Jan", lastName: "Vacek", number: 17, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-zdvoracek", firstName: "Martin", lastName: "Zdvořáček", number: 18, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "ust-zicho", firstName: "Patrik", lastName: "Zicho", number: 19, position: .forward, teamId: "usti", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-forst", firstName: "Pavel", lastName: "Foršt", number: 31, position: .goalie, teamId: "pardubice", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "par-trinacty", firstName: "Jakub", lastName: "Třináctý", number: 32, position: .goalie, teamId: "pardubice", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "par-geisler", firstName: "Jakub", lastName: "Geisler", number: 5, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-halek", firstName: "Miroslav", lastName: "Hálek", number: 6, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-kamaryt", firstName: "Filip", lastName: "Kamaryt", number: 7, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-krejci", firstName: "Roman", lastName: "Krejčí", number: 8, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-kvapil", firstName: "Jakub", lastName: "Kvapil", number: 9, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-novotny", firstName: "Ondřej", lastName: "Novotný", number: 10, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-skoloudik", firstName: "Václav", lastName: "Školoudík", number: 11, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-strouhal", firstName: "Jan", lastName: "Strouhal", number: 12, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-zajicek", firstName: "Tomáš", lastName: "Zajíček", number: 13, position: .defenseman, teamId: "pardubice", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-bily", firstName: "Jan", lastName: "Bílý", number: 19, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-cesak", firstName: "Josef", lastName: "Česák", number: 20, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-forstl", firstName: "Filip", lastName: "Förstl", number: 21, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-janecek", firstName: "Martin", lastName: "Janeček", number: 22, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-jilek", firstName: "Jiří", lastName: "Jílek", number: 23, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-lang", firstName: "Dominik", lastName: "Lang", number: 24, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-langr", firstName: "Nicolas", lastName: "Langr", number: 25, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-lenoch", firstName: "Šimon", lastName: "Lenoch", number: 26, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-licek", firstName: "Matyáš", lastName: "Licek", number: 27, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "par-moravec", firstName: "Luboš", lastName: "Moravec", number: 28, position: .forward, teamId: "pardubice", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-cerbak", firstName: "Jakub", lastName: "Čerbák", number: 31, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-hart", firstName: "Jakub", lastName: "Hart", number: 32, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-hnatek", firstName: "Jakub", lastName: "Hnátek", number: 33, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-krinwald", firstName: "Roman", lastName: "Krinwald", number: 34, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-majernicek", firstName: "Adam", lastName: "Majerníček", number: 30, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-supik", firstName: "Michal", lastName: "Šupík", number: 31, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-zemanec", firstName: "Jan", lastName: "Zemanec", number: 32, position: .goalie, teamId: "mlada", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "mla-bydzovsky", firstName: "Martin", lastName: "Bydžovský", number: 10, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-chyba", firstName: "Tomáš", lastName: "Chyba", number: 11, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-horacek", firstName: "David", lastName: "Horáček", number: 12, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-krejci", firstName: "Martin", lastName: "Krejčí", number: 13, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-malek", firstName: "Jan", lastName: "Málek", number: 14, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-martinek", firstName: "Daniel", lastName: "Martínek", number: 15, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-marusinec", firstName: "Jakub", lastName: "Marušinec", number: 16, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-moucha", firstName: "Lukáš", lastName: "Moucha", number: 17, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-nemecek", firstName: "Michal", lastName: "Němeček", number: 18, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-rudolph", firstName: "David", lastName: "Rudolph", number: 19, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-sipek", firstName: "Lukáš", lastName: "Šípek", number: 20, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-svanda", firstName: "Petr", lastName: "Švanda", number: 21, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-tichy", firstName: "Ondřej", lastName: "Tichý", number: 2, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-zorkler", firstName: "Lukáš", lastName: "Zörkler", number: 3, position: .defenseman, teamId: "mlada", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-benda", firstName: "Petr", lastName: "Benda", number: 29, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-bernard", firstName: "Tomáš", lastName: "Bernard", number: 30, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-briska", firstName: "Kamil", lastName: "Bříška", number: 31, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-erben", firstName: "Jiří", lastName: "Erben", number: 7, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-kral", firstName: "Zdeněk", lastName: "Král", number: 8, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-lhota", firstName: "Lukáš", lastName: "Lhota", number: 9, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-lhota2", firstName: "Tomáš", lastName: "Lhota", number: 10, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-malina", firstName: "Marcel", lastName: "Malina", number: 11, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-matejcek", firstName: "Martin", lastName: "Matějček", number: 12, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-moravcik", firstName: "Andrej", lastName: "Moravčík", number: 13, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-mrhalek", firstName: "Michal", lastName: "Mrhálek", number: 14, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-muller", firstName: "David", lastName: "Müller", number: 15, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-peca", firstName: "Jakub", lastName: "Peca", number: 16, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-pohl", firstName: "Miroslav", lastName: "Pohl", number: 17, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-polansky", firstName: "Marek", lastName: "Polanský", number: 18, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-ruda", firstName: "Tomáš", lastName: "Ruda", number: 19, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-sima", firstName: "Petr", lastName: "Šíma", number: 20, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-sindelar", firstName: "David", lastName: "Šindelář", number: 21, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-stastka", firstName: "Marek", lastName: "Šťástka", number: 22, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-toth", firstName: "Tomáš", lastName: "Tóth", number: 23, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "mla-wurdak", firstName: "Jakub", lastName: "Wurdák", number: 24, position: .forward, teamId: "mlada", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-gerlich", firstName: "Leoš", lastName: "Gerlich", number: 31, position: .goalie, teamId: "kladno", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "kla-jakoubek", firstName: "Matěj", lastName: "Jakoubek", number: 32, position: .goalie, teamId: "kladno", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "kla-bartak", firstName: "Filip", lastName: "Barták", number: 5, position: .defenseman, teamId: "kladno", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-belousek", firstName: "Jan", lastName: "Běloušek", number: 6, position: .defenseman, teamId: "kladno", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-drechsler", firstName: "Matouš", lastName: "Drechsler", number: 7, position: .defenseman, teamId: "kladno", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-haisman", firstName: "Jakub", lastName: "Haisman", number: 8, position: .defenseman, teamId: "kladno", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-kucera", firstName: "Ondřej", lastName: "Kučera", number: 9, position: .defenseman, teamId: "kladno", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-soukup", firstName: "Radek", lastName: "Soukup", number: 10, position: .defenseman, teamId: "kladno", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-adam", firstName: "Petr", lastName: "Adam", number: 16, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-barnosak", firstName: "Dominik", lastName: "Barnošák", number: 17, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-bauer", firstName: "Dominik", lastName: "Bauer", number: 18, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-danicek", firstName: "Marek", lastName: "Daníček", number: 19, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-drechsler2", firstName: "Michael", lastName: "Drechsler", number: 20, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-duras", firstName: "Štěpán", lastName: "Důras", number: 21, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-kohout", firstName: "Martin", lastName: "Kohout", number: 22, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-kubik", firstName: "Adam", lastName: "Kubík", number: 23, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-patera", firstName: "Lukáš", lastName: "Patera", number: 24, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-prochazka", firstName: "Jaroslav", lastName: "Procházka", number: 25, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-schnaubelt", firstName: "Milan", lastName: "Schnaubelt", number: 26, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-slaby", firstName: "Adam", lastName: "Slabý", number: 27, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-slavik", firstName: "Petr", lastName: "Slavík", number: 28, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kla-teinitzer", firstName: "Milan", lastName: "Teinitzer", number: 29, position: .forward, teamId: "kladno", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-fleischman", firstName: "Marek", lastName: "Fleischman", number: 31, position: .goalie, teamId: "blatna", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "bla-koubek", firstName: "Lukáš", lastName: "Koubek", number: 32, position: .goalie, teamId: "blatna", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "bla-fiala", firstName: "Martin", lastName: "Fiala", number: 5, position: .defenseman, teamId: "blatna", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-kafka", firstName: "Jan", lastName: "Kafka", number: 6, position: .defenseman, teamId: "blatna", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-michalek", firstName: "Daniel", lastName: "Michálek", number: 7, position: .defenseman, teamId: "blatna", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-silhan", firstName: "Pavel", lastName: "Šilhán", number: 8, position: .defenseman, teamId: "blatna", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-sip", firstName: "Filip", lastName: "Šíp", number: 9, position: .defenseman, teamId: "blatna", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-tkadlec", firstName: "Ondřej", lastName: "Tkadlec", number: 10, position: .defenseman, teamId: "blatna", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-braun", firstName: "David", lastName: "Braun", number: 16, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-malecha", firstName: "Matyáš", lastName: "Malecha", number: 17, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-manaska", firstName: "Petr", lastName: "Maňaska", number: 18, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-masek", firstName: "Jan", lastName: "Mašek", number: 19, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-matejka", firstName: "Jindřich", lastName: "Matějka", number: 20, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-riha", firstName: "Daniel", lastName: "Říha", number: 21, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-rychlik", firstName: "Miroslav", lastName: "Rychlík", number: 22, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-slezak", firstName: "David", lastName: "Slezák", number: 23, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-sybek", firstName: "Ladislav", lastName: "Sýbek", number: 24, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-vanicek", firstName: "Sebastian", lastName: "Vaníček", number: 25, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "bla-zelenka", firstName: "Lukáš", lastName: "Zelenka", number: 26, position: .forward, teamId: "blatna", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-brykner", firstName: "Petr", lastName: "Brykner", number: 31, position: .goalie, teamId: "hradec", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "hra-vesely", firstName: "Michal", lastName: "Veselý", number: 32, position: .goalie, teamId: "hradec", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "hra-vrkoslav", firstName: "Jan", lastName: "Vrkoslav", number: 33, position: .goalie, teamId: "hradec", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "hra-dlouhy", firstName: "Nikolas", lastName: "Dlouhý", number: 6, position: .defenseman, teamId: "hradec", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-fanderlik", firstName: "Vítek", lastName: "Fanderlik", number: 7, position: .defenseman, teamId: "hradec", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-hruby", firstName: "Michal", lastName: "Hrubý", number: 8, position: .defenseman, teamId: "hradec", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-musilek", firstName: "Vít", lastName: "Musílek", number: 9, position: .defenseman, teamId: "hradec", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-najman", firstName: "Jiří", lastName: "Najman", number: 10, position: .defenseman, teamId: "hradec", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-bakus", firstName: "Patrik", lastName: "Bakus", number: 16, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-blazek", firstName: "Miroslav", lastName: "Blažek", number: 17, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-bohaty", firstName: "Štěpán", lastName: "Bohatý", number: 18, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-borovec", firstName: "David", lastName: "Borovec", number: 19, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-cerny", firstName: "Daniel", lastName: "Černý", number: 20, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-cerny2", firstName: "Lukáš", lastName: "Černý", number: 21, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-divisek", firstName: "Tomáš", lastName: "Divíšek", number: 22, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-habermann", firstName: "Šimon", lastName: "Habermann", number: 23, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-hudecek", firstName: "Miloslav", lastName: "Hudeček", number: 24, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-jirik", firstName: "Tomáš", lastName: "Jiřík", number: 25, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-kachlik", firstName: "Václav", lastName: "Kachlík", number: 26, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-novotny", firstName: "Matěj", lastName: "Novotný", number: 27, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-petr", firstName: "Václav", lastName: "Petr", number: 28, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-pilar", firstName: "Jan", lastName: "Pilař", number: 29, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-prochazka", firstName: "Michal", lastName: "Procházka", number: 30, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-simunek", firstName: "Josef", lastName: "Šimůnek", number: 31, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-sir", firstName: "Ondřej", lastName: "Šír", number: 7, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-smutny", firstName: "Zdeněk", lastName: "Smutný", number: 8, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "hra-zamecnik", firstName: "Matěj", lastName: "Zámečník", number: 9, position: .forward, teamId: "hradec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-cerny", firstName: "Denis", lastName: "Černý", number: 31, position: .goalie, teamId: "vlci", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "vlc-kratky", firstName: "Petr", lastName: "Krátký", number: 32, position: .goalie, teamId: "vlci", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "rehor", firstName: "Adam", lastName: "Řehoř", number: 33, position: .goalie, teamId: "vlci", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "vlc-sobotka", firstName: "Josef", lastName: "Sobotka", number: 34, position: .goalie, teamId: "vlci", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "vlc-sticha", firstName: "Marek", lastName: "Šticha", number: 30, position: .goalie, teamId: "vlci", games: 18, goals: 0, assists: 0, points: 0, penaltyMinutes: 4, savePercentage: 91.0, goalsAgainstAverage: 2.5),
            .init(id: "vlc-doucha", firstName: "Tadeáš", lastName: "Doucha", number: 8, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-gottfried", firstName: "Pavel", lastName: "Gottfried", number: 9, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-janak", firstName: "Milan", lastName: "Janák", number: 10, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-klement", firstName: "Marek", lastName: "Klement", number: 11, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-kucera", firstName: "Ivan", lastName: "Kučera", number: 12, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-loukota", firstName: "Jakub", lastName: "Loukota", number: 13, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-michajlicenko", firstName: "Petr", lastName: "Michajličenko", number: 14, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-navarra", firstName: "Radim", lastName: "Navarra", number: 15, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-polata", firstName: "Ondřej", lastName: "Polata", number: 16, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-troncinsky", firstName: "Jan", lastName: "Trončinský", number: 17, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-zakon", firstName: "Radek", lastName: "Zákon", number: 18, position: .defenseman, teamId: "vlci", games: 18, goals: 3, assists: 6, points: 9, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-baxa", firstName: "Roland", lastName: "Baxa", number: 24, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-bercik", firstName: "Martin", lastName: "Berčík", number: 25, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-brhel", firstName: "Antonín", lastName: "Brhel", number: 26, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "faigl", firstName: "Tomáš", lastName: "Faigl", number: 27, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-gottfried2", firstName: "David", lastName: "Gottfried", number: 28, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-grosse", firstName: "Jan", lastName: "Grosse", number: 29, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-grosse2", firstName: "Jindřich", lastName: "Grosse", number: 30, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-hruska", firstName: "Michal", lastName: "Hruška", number: 31, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-koval", firstName: "Jakub", lastName: "Koval", number: 7, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-koval2", firstName: "Matěj", lastName: "Koval", number: 8, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-kuchynka", firstName: "Štěpán", lastName: "Kuchynka", number: 9, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-macek", firstName: "Aleš", lastName: "Macek", number: 10, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-macek2", firstName: "Marek", lastName: "Macek", number: 11, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-mares", firstName: "Erik", lastName: "Mareš", number: 12, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "navarra", firstName: "Roman", lastName: "Navarra", number: 13, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-radimsky", firstName: "Pavel", lastName: "Radimský", number: 14, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-strnad", firstName: "Petr", lastName: "Strnad", number: 15, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-tuma", firstName: "Jan", lastName: "Tůma", number: 16, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-vilikus", firstName: "Vilém", lastName: "Vilikus", number: 17, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-zdvoracek", firstName: "Martin", lastName: "Zdvořáček", number: 18, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-zdvoracek2", firstName: "Petr", lastName: "Zdvořáček", number: 19, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vlc-zdvoracek3", firstName: "Tomáš", lastName: "Zdvořáček", number: 20, position: .forward, teamId: "vlci", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-benek", firstName: "Marek", lastName: "Benek", number: 8, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-bujak", firstName: "Dominik", lastName: "Buják", number: 9, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-bujak2", firstName: "Patrik", lastName: "Buják", number: 10, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-czeczotka", firstName: "Václav", lastName: "Czeczotka", number: 11, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-farsky", firstName: "Ondřej", lastName: "Fárský", number: 12, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-halouzka", firstName: "Matěj", lastName: "Halouzka", number: 13, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-horak", firstName: "Šimon", lastName: "Horák", number: 14, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-konderla", firstName: "Tomáš", lastName: "Konderla", number: 15, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-korbel", firstName: "Martin", lastName: "Korbel", number: 16, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-miech", firstName: "Dalibor", lastName: "Miech", number: 17, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-palkovsky", firstName: "Erik", lastName: "Palkovský", number: 18, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-planka", firstName: "Filip", lastName: "Plánka", number: 19, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-prochazka", firstName: "Adam", lastName: "Procházka", number: 20, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-przybyla", firstName: "Petr", lastName: "Przybyla", number: 21, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-rihosek", firstName: "Martin", lastName: "Říhošek", number: 22, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-samek", firstName: "Martin", lastName: "Samek", number: 23, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-sobol", firstName: "Samuel", lastName: "Sobol", number: 24, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-sotkovsky", firstName: "Ondřej", lastName: "Šotkovský", number: 25, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-stromko", firstName: "Jan", lastName: "Stromko", number: 26, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-tomis", firstName: "René", lastName: "Tomis", number: 27, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "tri-vitasek", firstName: "Samuel", lastName: "Vitásek", number: 28, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "vizvary", firstName: "Richard", lastName: "Vizváry", number: 29, position: .forward, teamId: "trinec", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-ambros", firstName: "Jakub", lastName: "Ambros", number: 8, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-binova", firstName: "Tereza", lastName: "Bínová", number: 9, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-blaha", firstName: "Jakub", lastName: "Bláha", number: 10, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-bruza", firstName: "Jakub", lastName: "Brůža", number: 11, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-chaloupka", firstName: "Václav", lastName: "Chaloupka", number: 12, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-curdova", firstName: "Kateřina", lastName: "Čurdová", number: 13, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-doucha", firstName: "Filip", lastName: "Doucha", number: 14, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-heime", firstName: "Tobias", lastName: "Heime", number: 15, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-horsky", firstName: "Lukáš", lastName: "Horský", number: 16, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-kraml", firstName: "Adam", lastName: "Kraml", number: 17, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-matejka", firstName: "Michal", lastName: "Matějka", number: 18, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-nalezeny", firstName: "Mikuláš", lastName: "Nalezený", number: 19, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-novotny", firstName: "Jakub", lastName: "Novotný", number: 20, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-skoda", firstName: "Vojta", lastName: "Škoda", number: 21, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-sykora", firstName: "Václav", lastName: "Sýkora", number: 22, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-vlach", firstName: "František", lastName: "Vlach", number: 23, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "pal-zabrodsky", firstName: "David", lastName: "Zábrodský", number: 24, position: .forward, teamId: "palmovka", games: 18, goals: 8, assists: 6, points: 14, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "benes", firstName: "Martin", lastName: "Beneš", number: 16, position: .defenseman, teamId: "svitkov", games: 20, goals: 4, assists: 12, points: 16, penaltyMinutes: 22, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "novak", firstName: "Petr", lastName: "Novák", number: 27, position: .forward, teamId: "letohrad", games: 18, goals: 9, assists: 11, points: 20, penaltyMinutes: 8, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "horsky", firstName: "Adam", lastName: "Horský", number: 31, position: .goalie, teamId: "kert", games: 15, goals: 0, assists: 0, points: 0, penaltyMinutes: 0, savePercentage: 91.2, goalsAgainstAverage: 2.4),
            .init(id: "kupka", firstName: "Tomáš", lastName: "Kupka", number: 14, position: .forward, teamId: "pardubice", games: 12, goals: 10, assists: 15, points: 25, penaltyMinutes: 10, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "jelinek", firstName: "Jáchym", lastName: "Jelínek", number: 19, position: .forward, teamId: "kladno", games: 13, goals: 12, assists: 12, points: 24, penaltyMinutes: 12, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "schnaubelt", firstName: "Michal", lastName: "Schnaubelt", number: 8, position: .forward, teamId: "kladno", games: 7, goals: 7, assists: 13, points: 20, penaltyMinutes: 4, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "zikmund", firstName: "Tomáš", lastName: "Zikmund", number: 5, position: .defenseman, teamId: "hradec", games: 7, goals: 10, assists: 6, points: 16, penaltyMinutes: 14, savePercentage: nil, goalsAgainstAverage: nil),
            .init(id: "kantorova", firstName: "Andrea", lastName: "Kantorová", number: 7, position: .forward, teamId: "palmovka", games: 2, goals: 3, assists: 0, points: 3, penaltyMinutes: 0, savePercentage: nil, goalsAgainstAverage: nil),
        ]
    }

    private func ensurePlayersLoaded() {
        guard playersData.isEmpty else { return }
        var players = Self.makePlayers()
        let covered = Set(players.map(\.teamId))
        for team in teamsData where !covered.contains(team.id) {
            players.append(contentsOf: Self.syntheticRoster(for: team.id))
        }
        playersData = players
    }

    init() {
        let logoBase = "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/competition-logos"
        competitionsData = [
            .init(id: "extraliga-2025-26", slug: "extraliga", seasonId: "2025-26", name: "Extraliga hokejbalu", shortName: "Extraliga", season: "2025/26", logoURL: "\(logoBase)/extraliga.png", logoInitials: "EL", iconSystemName: "trophy.fill"),
            .init(id: "1liga-2025-26", slug: "1liga", seasonId: "2025-26", name: "1. liga hokejbalu", shortName: "1. liga", season: "2025/26", logoURL: "\(logoBase)/1liga.png", logoInitials: "1L", iconSystemName: "sportscourt.fill"),
            .init(id: "2liga-2025-26", slug: "2liga", seasonId: "2025-26", name: "2. liga hokejbalu", shortName: "2. liga", season: "2025/26", logoURL: "\(logoBase)/2liga.png", logoInitials: "2L", iconSystemName: "sportscourt"),
            .init(id: "regionalni-2025-26", slug: "regionalni", seasonId: "2025-26", name: "Regionální liga", shortName: "Regionální", season: "2025/26", logoURL: "\(logoBase)/regionalni.png", logoInitials: "RL", iconSystemName: "map"),
            .init(id: "oblastni-2025-26", slug: "oblastni", seasonId: "2025-26", name: "Oblastní liga", shortName: "Oblastní", season: "2025/26", logoURL: "\(logoBase)/oblastni.png", logoInitials: "OL", iconSystemName: "mappin.and.ellipse"),
            .init(id: "juniori-2025-26", slug: "juniori", seasonId: "2025-26", name: "Extraliga juniorů", shortName: "Junioři", season: "2025/26", logoURL: "\(logoBase)/juniori.png", logoInitials: "EJ", iconSystemName: "person.3.fill"),
            .init(id: "dorost-2025-26", slug: "dorost", seasonId: "2025-26", name: "Extraliga dorostu", shortName: "Dorost", season: "2025/26", logoURL: "\(logoBase)/dorost.png", logoInitials: "ED", iconSystemName: "figure.hockey"),
            .init(id: "starsi-zaci-2025-26", slug: "starsi-zaci", seasonId: "2025-26", name: "Liga starších žáků", shortName: "Starší žáci", season: "2025/26", logoURL: "\(logoBase)/starsi-zaci.png", logoInitials: "SŽ", iconSystemName: "figure.and.child.holdinghands"),
            .init(id: "mladsi-zaci-2025-26", slug: "mladsi-zaci", seasonId: "2025-26", name: "Přebor mladších žáků", shortName: "Mladší žáci", season: "2025/26", logoURL: "\(logoBase)/mladsi-zaci.png", logoInitials: "MŽ", iconSystemName: "figure.child"),
            .init(id: "pripravky-2025-26", slug: "pripravky", seasonId: "2025-26", name: "Přebor přípravek", shortName: "Přípravky", season: "2025/26", logoURL: "\(logoBase)/pripravky.png", logoInitials: "PŘ", iconSystemName: "figure.run"),
            .init(id: "minipripravky-2025-26", slug: "minipripravky", seasonId: "2025-26", name: "Přebor minipřípravek", shortName: "Minipřípravky", season: "2025/26", logoURL: "\(logoBase)/minipripravky.png", logoInitials: "MP", iconSystemName: "star.fill"),
            .init(id: "zeny-2025-26", slug: "zeny", seasonId: "2025-26", name: "Liga žen", shortName: "Liga žen", season: "2025/26", logoURL: "\(logoBase)/zeny.png", logoInitials: "LŽ", iconSystemName: "person.fill"),
            .init(id: "prebor-zen-2025-26", slug: "prebor-zen", seasonId: "2025-26", name: "Přebor žen", shortName: "Přebor žen", season: "2025/26", logoURL: "\(logoBase)/prebor-zen.png", logoInitials: "PŽ", iconSystemName: "person.2.fill"),
            .init(id: "extraliga-2024-25", slug: "extraliga", seasonId: "2024-25", name: "Extraliga hokejbalu", shortName: "Extraliga", season: "2024/25", logoURL: "\(logoBase)/extraliga.png", logoInitials: "EL", iconSystemName: "trophy.fill")
        ]

        // Loga z hokejbal.cz (og:image / is.cmshb.cz).
        teamsData = [
            .init(id: "hostivar", name: "HBC Hostivař", shortName: "Hostivař", city: "Praha", primaryColorHex: "C92A2A", logoInitials: "HH", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/hostivar.png", competitionId: "extraliga-2025-26"),
            .init(id: "letohrad", name: "SK Hokejbal Letohrad", shortName: "Letohrad", city: "Letohrad", primaryColorHex: "1B4F9C", logoInitials: "SL", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/letohrad.png", competitionId: "extraliga-2025-26"),
            .init(id: "kert", name: "HC Kert Park Praha", shortName: "Kert Park", city: "Praha", primaryColorHex: "111111", logoInitials: "KP", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/kert.png", competitionId: "extraliga-2025-26"),
            .init(id: "svitkov", name: "HBC Svítkov Stars Pardubice", shortName: "Svítkov", city: "Pardubice", primaryColorHex: "D4A017", logoInitials: "SS", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/svitkov.png", competitionId: "extraliga-2025-26"),
            .init(id: "plzen", name: "HBC Plzeň", shortName: "Plzeň", city: "Plzeň", primaryColorHex: "0B3D91", logoInitials: "PL", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/plzen.png", competitionId: "extraliga-2025-26"),
            .init(id: "dobrany", name: "TJ Snack Dobřany", shortName: "Dobřany", city: "Dobřany", primaryColorHex: "2E7D32", logoInitials: "DO", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/dobrany.png", competitionId: "extraliga-2025-26"),
            .init(id: "usti", name: "Elba DDM Ústí nad Labem", shortName: "Ústí", city: "Ústí n. L.", primaryColorHex: "E65100", logoInitials: "UL", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/usti.png", competitionId: "extraliga-2025-26"),
            .init(id: "pardubice", name: "HBC Pardubice", shortName: "Pardubice", city: "Pardubice", primaryColorHex: "B71C1C", logoInitials: "PA", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/pardubice.png", competitionId: "extraliga-2025-26"),
            .init(id: "mlada", name: "HBC Tygři Mladá Boleslav", shortName: "Mladá B.", city: "Mladá Boleslav", primaryColorHex: "1565C0", logoInitials: "MB", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/mlada.png", competitionId: "extraliga-2025-26"),
            .init(id: "kladno", name: "HBC Kladno", shortName: "Kladno", city: "Kladno", primaryColorHex: "283593", logoInitials: "KL", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/kladno.png", competitionId: "extraliga-2025-26"),
            .init(id: "blatna", name: "TJ Blatná Datels", shortName: "Blatná", city: "Blatná", primaryColorHex: "5D4037", logoInitials: "BD", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/blatna.png", competitionId: "extraliga-2025-26"),
            .init(id: "hradec", name: "HBC Hradec Králové 1988", shortName: "Hradec", city: "Hradec Králové", primaryColorHex: "C62828", logoInitials: "HK", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/hradec.png", competitionId: "extraliga-2025-26"),
            .init(id: "vlci", name: "Vlčí smečka Ústí nad Labem", shortName: "Vlčí smečka", city: "Ústí n. L.", primaryColorHex: "37474F", logoInitials: "VS", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/vlci.png", competitionId: "1liga-2025-26"),
            .init(id: "trinec", name: "HBC Enviform Třinec", shortName: "Třinec", city: "Třinec", primaryColorHex: "B71C1C", logoInitials: "TR", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/trinec.png", competitionId: "1liga-2025-26"),
            .init(id: "most", name: "HBC Most", shortName: "Most", city: "Most", primaryColorHex: "455A64", logoInitials: "MO", logoURL: nil, competitionId: "1liga-2025-26"),
            .init(id: "teplice", name: "SK Teplice", shortName: "Teplice", city: "Teplice", primaryColorHex: "F9A825", logoInitials: "TE", logoURL: nil, competitionId: "1liga-2025-26"),
            .init(id: "chomutov", name: "HBC Chomutov", shortName: "Chomutov", city: "Chomutov", primaryColorHex: "1565C0", logoInitials: "CH", logoURL: nil, competitionId: "2liga-2025-26"),
            .init(id: "decin", name: "HC Děčín", shortName: "Děčín", city: "Děčín", primaryColorHex: "6A1B9A", logoInitials: "DE", logoURL: nil, competitionId: "2liga-2025-26"),
            .init(id: "kolin", name: "HBC Kolín", shortName: "Kolín", city: "Kolín", primaryColorHex: "0277BD", logoInitials: "KO", logoURL: nil, competitionId: "regionalni-2025-26"),
            .init(id: "benesov", name: "TJ Benešov", shortName: "Benešov", city: "Benešov", primaryColorHex: "2E7D32", logoInitials: "BE", logoURL: nil, competitionId: "regionalni-2025-26"),
            .init(id: "rakovnik", name: "HK Rakovník", shortName: "Rakovník", city: "Rakovník", primaryColorHex: "C62828", logoInitials: "RA", logoURL: nil, competitionId: "oblastni-2025-26"),
            .init(id: "slany", name: "HC Slaný", shortName: "Slaný", city: "Slaný", primaryColorHex: "EF6C00", logoInitials: "SL", logoURL: nil, competitionId: "oblastni-2025-26"),
            .init(id: "pardubice-j", name: "HBC Pardubice junioři", shortName: "Pardubice J", city: "Pardubice", primaryColorHex: "B71C1C", logoInitials: "PJ", logoURL: nil, competitionId: "juniori-2025-26"),
            .init(id: "kladno-j", name: "HBC Kladno junioři", shortName: "Kladno J", city: "Kladno", primaryColorHex: "283593", logoInitials: "KJ", logoURL: nil, competitionId: "juniori-2025-26"),
            .init(id: "hostivar-d", name: "HBC Hostivař dorost", shortName: "Hostivař D", city: "Praha", primaryColorHex: "C92A2A", logoInitials: "HD", logoURL: nil, competitionId: "dorost-2025-26"),
            .init(id: "plzen-d", name: "HBC Plzeň dorost", shortName: "Plzeň D", city: "Plzeň", primaryColorHex: "0B3D91", logoInitials: "PD", logoURL: nil, competitionId: "dorost-2025-26"),
            .init(id: "palmovka", name: "HBC KOVO Palmovka", shortName: "Palmovka", city: "Praha", primaryColorHex: "00695C", logoInitials: "KP", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/palmovka.png", competitionId: "zeny-2025-26"),
            .init(id: "plzen-z", name: "HBC Plzeň ženy", shortName: "Plzeň Ž", city: "Plzeň", primaryColorHex: "0B3D91", logoInitials: "PŽ", logoURL: nil, competitionId: "zeny-2025-26"),
            .init(id: "svitkov-z", name: "HBC Svítkov Stars ženy", shortName: "Svítkov Ž", city: "Pardubice", primaryColorHex: "D4A017", logoInitials: "SŽ", logoURL: nil, competitionId: "zeny-2025-26"),
            .init(id: "praha-pz", name: "HC Praha přebor žen", shortName: "Praha PŽ", city: "Praha", primaryColorHex: "AD1457", logoInitials: "PP", logoURL: nil, competitionId: "prebor-zen-2025-26"),
            .init(id: "brno-pz", name: "SK Brno přebor žen", shortName: "Brno PŽ", city: "Brno", primaryColorHex: "6A1B9A", logoInitials: "BP", logoURL: nil, competitionId: "prebor-zen-2025-26"),
            .init(id: "hostivar-sz", name: "HBC Hostivař SŽ", shortName: "Hostivař SŽ", city: "Praha", primaryColorHex: "C92A2A", logoInitials: "HS", logoURL: nil, competitionId: "starsi-zaci-2025-26"),
            .init(id: "kert-sz", name: "Kert Park SŽ", shortName: "Kert SŽ", city: "Praha", primaryColorHex: "111111", logoInitials: "KS", logoURL: nil, competitionId: "starsi-zaci-2025-26"),
            .init(id: "letohrad-mz", name: "Letohrad MŽ", shortName: "Letohrad MŽ", city: "Letohrad", primaryColorHex: "1B4F9C", logoInitials: "LM", logoURL: nil, competitionId: "mladsi-zaci-2025-26"),
            .init(id: "usti-mz", name: "Ústí MŽ", shortName: "Ústí MŽ", city: "Ústí n. L.", primaryColorHex: "E65100", logoInitials: "UM", logoURL: nil, competitionId: "mladsi-zaci-2025-26"),
            .init(id: "kladno-pr", name: "Kladno přípravky", shortName: "Kladno PŘ", city: "Kladno", primaryColorHex: "283593", logoInitials: "KP", logoURL: nil, competitionId: "pripravky-2025-26"),
            .init(id: "pardubice-pr", name: "Pardubice přípravky", shortName: "Pardubice PŘ", city: "Pardubice", primaryColorHex: "B71C1C", logoInitials: "PP", logoURL: nil, competitionId: "pripravky-2025-26"),
            .init(id: "plzen-mp", name: "Plzeň minipřípravky", shortName: "Plzeň MP", city: "Plzeň", primaryColorHex: "0B3D91", logoInitials: "PM", logoURL: nil, competitionId: "minipripravky-2025-26"),
            .init(id: "hostivar-mp", name: "Hostivař minipřípravky", shortName: "Hostivař MP", city: "Praha", primaryColorHex: "C92A2A", logoInitials: "HM", logoURL: nil, competitionId: "minipripravky-2025-26")
        ]

        playersData = []

        let extraligaStandings: [StandingRow] = [
            .init(id: "s1", rank: 1, teamId: "hostivar", played: 22, wins: 16, overtimeWins: 2, overtimeLosses: 0, losses: 4, goalsFor: 137, goalsAgainst: 82, points: 52),
            .init(id: "s2", rank: 2, teamId: "letohrad", played: 22, wins: 14, overtimeWins: 2, overtimeLosses: 1, losses: 5, goalsFor: 106, goalsAgainst: 71, points: 47),
            .init(id: "s3", rank: 3, teamId: "kert", played: 22, wins: 13, overtimeWins: 3, overtimeLosses: 0, losses: 6, goalsFor: 121, goalsAgainst: 71, points: 45),
            .init(id: "s4", rank: 4, teamId: "svitkov", played: 22, wins: 13, overtimeWins: 2, overtimeLosses: 1, losses: 6, goalsFor: 101, goalsAgainst: 72, points: 44),
            .init(id: "s5", rank: 5, teamId: "plzen", played: 22, wins: 12, overtimeWins: 2, overtimeLosses: 1, losses: 7, goalsFor: 94, goalsAgainst: 72, points: 41),
            .init(id: "s6", rank: 6, teamId: "dobrany", played: 22, wins: 11, overtimeWins: 3, overtimeLosses: 0, losses: 8, goalsFor: 87, goalsAgainst: 91, points: 39),
            .init(id: "s7", rank: 7, teamId: "usti", played: 22, wins: 10, overtimeWins: 3, overtimeLosses: 0, losses: 9, goalsFor: 82, goalsAgainst: 70, points: 36),
            .init(id: "s8", rank: 8, teamId: "pardubice", played: 22, wins: 9, overtimeWins: 1, overtimeLosses: 2, losses: 10, goalsFor: 94, goalsAgainst: 84, points: 31),
            .init(id: "s9", rank: 9, teamId: "mlada", played: 22, wins: 6, overtimeWins: 2, overtimeLosses: 1, losses: 13, goalsFor: 69, goalsAgainst: 105, points: 23),
            .init(id: "s10", rank: 10, teamId: "kladno", played: 22, wins: 5, overtimeWins: 2, overtimeLosses: 2, losses: 13, goalsFor: 58, goalsAgainst: 86, points: 21),
            .init(id: "s11", rank: 11, teamId: "blatna", played: 22, wins: 3, overtimeWins: 0, overtimeLosses: 2, losses: 17, goalsFor: 70, goalsAgainst: 141, points: 11),
            .init(id: "s12", rank: 12, teamId: "hradec", played: 22, wins: 1, overtimeWins: 1, overtimeLosses: 1, losses: 19, goalsFor: 49, goalsAgainst: 123, points: 6)
        ]

        var standingsMap: [String: [StandingRow]] = [
            "extraliga-2025-26": extraligaStandings,
            "extraliga-2024-25": extraligaStandings.map { row in
                StandingRow(
                    id: "\(row.id)-24",
                    rank: row.rank,
                    teamId: row.teamId,
                    played: row.played,
                    wins: max(row.wins - 1, 0),
                    overtimeWins: row.overtimeWins,
                    overtimeLosses: row.overtimeLosses,
                    losses: row.losses + 1,
                    goalsFor: max(row.goalsFor - 8, 0),
                    goalsAgainst: row.goalsAgainst + 5,
                    points: max(row.points - 3, 0)
                )
            }
        ]

        // Automatické tabulky pro ostatní soutěže podle týmů.
        let teamsByComp = Dictionary(grouping: teamsData, by: \.competitionId)
        for (compId, teams) in teamsByComp where standingsMap[compId] == nil {
            standingsMap[compId] = teams.enumerated().map { idx, team in
                let played = 10 + (idx % 4)
                let wins = max(played - idx - 1, 1)
                let losses = max(played - wins, 0)
                let gf = 40 - idx * 4
                let ga = 20 + idx * 5
                return StandingRow(
                    id: "\(compId)-\(team.id)",
                    rank: idx + 1,
                    teamId: team.id,
                    played: played,
                    wins: wins,
                    overtimeWins: idx % 2,
                    overtimeLosses: (idx + 1) % 2,
                    losses: losses,
                    goalsFor: max(gf, 8),
                    goalsAgainst: max(ga, 8),
                    points: wins * 3 + (idx % 2)
                )
            }
        }
        standingsByCompetition = standingsMap

        let cal = Calendar.current
        func daysAgo(_ days: Int) -> Date {
            cal.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        newsData = [
            .init(id: "n1", title: "O gólmany je tento ročník postaráno opravdu velmi dobře, těší trenéra Ondřeje Chovančíka", category: "CTM a HCŽ", publishedAt: daysAgo(3), summary: "Na CTM a HCŽ v České Třebové je v brankách výborná situace.", imageGradientIndex: 0),
            .init(id: "n2", title: "Velice rádi bychom ukončili čekání na medaili od roku 2012, netají před MS Legends Libor Smetana", category: "Masters", publishedAt: daysAgo(4), summary: "České legends míří na MS s jasnou ambicí.", imageGradientIndex: 1),
            .init(id: "n3", title: "Komise mládeže představuje projekty pro rok 2026. Kluby mohou získat podporu pro nábor i vybavení", category: "Mládež", publishedAt: daysAgo(2), summary: "Nové dotační programy pro kluby a nábor dětí.", imageGradientIndex: 2),
            .init(id: "n4", title: "V České Třebové už probíhá také HCŽ! Každá z nás dostává velký prostor, říká Hana Blaschkeová", category: "CTM a HCŽ", publishedAt: daysAgo(5), summary: "Ženské HCŽ odstartovalo společně s CTM.", imageGradientIndex: 3),
            .init(id: "n5", title: "Z Chlumce se vždy vracíš jako z křížové výpravy, říká heřmanoměstecký křižák Dominik Macenauer", category: "2. liga", publishedAt: daysAgo(5), summary: "Rozhovor s hráčem Heřmanova Městce.", imageGradientIndex: 4),
            .init(id: "n6", title: "MS v hokejbalu 2026 Ostrava – vstupenky v prodeji", category: "Extraliga", publishedAt: daysAgo(1), summary: "Vrcholná akce roku 2026 se blíží. Kupte si vstupenky.", imageGradientIndex: 0)
        ]

        matchesStore = Self.buildInitialMatches()
    }

    func seasons() async throws -> [Season] {
        [
            Season(id: "2025-26", label: "2025/26", sortOrder: 2, isCurrent: true),
            Season(id: "2024-25", label: "2024/25", sortOrder: 1, isCurrent: false)
        ]
    }

    func competitions(seasonId: String?) async throws -> [Competition] {
        guard let seasonId else { return competitionsData }
        return competitionsData.filter { $0.seasonId == seasonId }
    }

    func teams(competitionId: String?) async throws -> [Team] {
        guard let competitionId else { return teamsData }
        return teamsData.filter { $0.competitionId == competitionId }
    }

    func players(teamId: String?) async throws -> [Player] {
        try await players(teamId: teamId, seasonId: nil, competitionId: nil)
    }

    func players(teamId: String?, seasonId: String?, competitionId: String?) async throws -> [Player] {
        ensurePlayersLoaded()
        var result = playersData
        if let teamId {
            result = result.filter { $0.teamId == teamId }
        }
        _ = seasonId
        if let competitionId {
            let teamIds = Set(teamsData.filter { $0.competitionId == competitionId }.map(\.id))
            result = result.filter { teamIds.contains($0.teamId) || $0.competitionId == competitionId }
        }
        return result.sorted { $0.points > $1.points }
    }

    func matches(query: MatchesQuery) async throws -> [Match] {
        var result = matchesStore
        if let competitionId = query.competitionId {
            result = result.filter { $0.competitionId == competitionId }
        } else if let seasonId = query.seasonId {
            let ids = Set(competitionsData.filter { $0.seasonId == seasonId }.map(\.id))
            result = result.filter { ids.contains($0.competitionId) }
        }
        if let status = query.status {
            result = result.filter { $0.status == status }
        }
        if let teamId = query.teamId {
            result = result.filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
        }
        if let date = query.date {
            result = result.filter { calendar.isDate($0.scheduledAt, inSameDayAs: date) }
        }
        return result.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func liveMatches(since cursor: String?) async throws -> LiveMatchesResponse {
        liveTick += 1
        if liveTick % 2 == 0 {
            advanceLiveMatches()
        }
        let live = matchesStore.filter { $0.status == .live }
        return LiveMatchesResponse(matches: live, updatedAt: Date(), cursor: "mock-\(liveTick)")
    }

    func matchDetail(id: String) async throws -> Match {
        guard let match = matchesStore.first(where: { $0.id == id }) else { throw APIError.notFound }
        return match
    }

    func standings(competitionId: String) async throws -> [StandingRow] {
        standingsByCompetition[competitionId] ?? []
    }

    func news(limit: Int) async throws -> [NewsArticle] {
        if let live = try? await HokejbalCzNewsClient.fetch(limit: limit), !live.isEmpty {
            return live
        }
        return Array(newsData.prefix(limit))
    }

    func player(id: String) async throws -> Player {
        ensurePlayersLoaded()
        guard let player = playersData.first(where: { $0.id == id }) else { throw APIError.notFound }
        return player
    }

    func team(id: String) async throws -> Team {
        guard let team = teamsData.first(where: { $0.id == id }) else { throw APIError.notFound }
        return team
    }

    func playerHistory(playerId: String) async throws -> [PlayerSeasonStat] {
        ensurePlayersLoaded()
        guard let player = playersData.first(where: { $0.id == playerId }) else { return [] }
        let team = teamsData.first { $0.id == player.teamId }
        let competitionId = team?.competitionId ?? "extraliga-2025-26"
        let competitionName = competitionsData.first { $0.id == competitionId }?.name ?? "Soutěž"
        let seasonId = competitionsData.first { $0.id == competitionId }?.seasonId ?? "2025-26"
        let priorCompetitionId = competitionsData.first {
            $0.slug == (competitionsData.first { $0.id == competitionId }?.slug ?? "")
                && $0.seasonId == "2024-25"
        }?.id ?? competitionId

        return [
            PlayerSeasonStat(
                id: "\(playerId)-\(seasonId)",
                playerId: playerId,
                clubId: player.teamId,
                competitionId: competitionId,
                seasonId: seasonId,
                seasonLabel: seasonId.replacingOccurrences(of: "-", with: "/"),
                competitionName: competitionName,
                number: player.number,
                position: player.position,
                games: player.games,
                goals: player.goals,
                assists: player.assists,
                points: player.points,
                penaltyMinutes: player.penaltyMinutes,
                savePercentage: player.savePercentage,
                goalsAgainstAverage: player.goalsAgainstAverage
            ),
            PlayerSeasonStat(
                id: "\(playerId)-2024-25",
                playerId: playerId,
                clubId: player.teamId,
                competitionId: priorCompetitionId,
                seasonId: "2024-25",
                seasonLabel: "2024/25",
                competitionName: competitionName,
                number: player.number,
                position: player.position,
                games: max(player.games - 2, 1),
                goals: max(player.goals - 2, 0),
                assists: max(player.assists - 1, 0),
                points: max(player.points - 3, 0),
                penaltyMinutes: player.penaltyMinutes,
                savePercentage: player.savePercentage.map { $0 - 0.5 },
                goalsAgainstAverage: player.goalsAgainstAverage.map { $0 + 0.2 }
            )
        ]
    }

    func clubSeasonHistory(clubId: String) async throws -> [ClubSeasonRecord] {
        let team = teamsData.first { $0.id == clubId }
        let competitionId = team?.competitionId ?? "extraliga-2025-26"
        let competitionName = competitionsData.first { $0.id == competitionId }?.name ?? "Soutěž"
        let current = standingsByCompetition[competitionId]?.first { $0.teamId == clubId }
        let prior = standingsByCompetition["extraliga-2024-25"]?.first { $0.teamId == clubId }
            ?? current.map {
                StandingRow(
                    id: "\($0.id)-24",
                    rank: min($0.rank + 1, 12),
                    teamId: clubId,
                    played: $0.played,
                    wins: max($0.wins - 1, 0),
                    overtimeWins: $0.overtimeWins,
                    overtimeLosses: $0.overtimeLosses,
                    losses: $0.losses + 1,
                    goalsFor: max($0.goalsFor - 5, 0),
                    goalsAgainst: $0.goalsAgainst + 4,
                    points: max($0.points - 3, 0)
                )
            }

        return [
            ClubSeasonRecord(
                seasonId: "2025-26",
                seasonLabel: "2025/26",
                competitionId: competitionId,
                competitionName: competitionName,
                standing: current
            ),
            ClubSeasonRecord(
                seasonId: "2024-25",
                seasonLabel: "2024/25",
                competitionId: prior.map { _ in "extraliga-2024-25" } ?? competitionId,
                competitionName: competitionName,
                standing: prior
            )
        ]
    }

    /// Lehcí „gólmani“ pro live tick bez načítání celé soupisky (~400 hráčů).
    private static let liveScorerByTeam: [String: (id: String, name: String)] = [
        "hostivar": ("cejka", "Jan Čejka"),
        "letohrad": ("novak", "Petr Novák"),
        "kert": ("ker-fejfar", "Tomáš Fejfar"),
        "svitkov": ("benes", "Martin Beneš"),
        "plzen": ("kral", "Dan Král"),
        "dobrany": ("dob-brtnik", "Jan Brtník"),
        "usti": ("ust-placeholder", "Ústí"),
        "pardubice": ("kupka", "Tomáš Kupka"),
        "mlada": ("mla-placeholder", "Mladá B."),
        "kladno": ("jelinek", "Jáchym Jelínek"),
        "blatna": ("bla-placeholder", "Blatná"),
        "hradec": ("zikmund", "Tomáš Zikmund"),
        "vlci": ("navarra", "Roman Navarra"),
        "trinec": ("tri-placeholder", "Třinec"),
        "palmovka": ("kantorova", "Andrea Kantorová"),
    ]

    private func liveScorer(teamId: String) -> (id: String, name: String) {
        Self.liveScorerByTeam[teamId] ?? (teamId, "Hráč")
    }

    private func advanceLiveMatches() {
        for i in matchesStore.indices where matchesStore[i].status == .live {
            var match = matchesStore[i]
            let scoreHome = Bool.random()
            if Bool.random() {
                if scoreHome {
                    match.homeScore += 1
                    if !match.homePeriodScores.isEmpty {
                        match.homePeriodScores[match.homePeriodScores.count - 1] += 1
                    }
                    let scorer = liveScorer(teamId: match.homeTeamId)
                    match.events.insert(
                        .init(
                            id: "live-\(match.id)-\(liveTick)-h",
                            kind: .goal,
                            minute: Int.random(in: 1...15),
                            second: Int.random(in: 0...59),
                            teamId: match.homeTeamId,
                            playerId: scorer.id,
                            assistIds: [],
                            description: "Gól \(scorer.name)",
                            period: max(match.homePeriodScores.count, 1)
                        ),
                        at: 0
                    )
                } else {
                    match.awayScore += 1
                    if !match.awayPeriodScores.isEmpty {
                        match.awayPeriodScores[match.awayPeriodScores.count - 1] += 1
                    }
                    let scorer = liveScorer(teamId: match.awayTeamId)
                    match.events.insert(
                        .init(
                            id: "live-\(match.id)-\(liveTick)-a",
                            kind: .goal,
                            minute: Int.random(in: 1...15),
                            second: Int.random(in: 0...59),
                            teamId: match.awayTeamId,
                            playerId: scorer.id,
                            assistIds: [],
                            description: "Gól \(scorer.name)",
                            period: max(match.awayPeriodScores.count, 1)
                        ),
                        at: 0
                    )
                }
            }
            let minutes = Int.random(in: 5...14)
            let seconds = Int.random(in: 0...59)
            match.clock = String(format: "%d:%02d", minutes, seconds)
            matchesStore[i] = match
        }
    }

    private static func buildInitialMatches() -> [Match] {
        let cal = Calendar.current
        let today = Date()
        func at(_ dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
            var comps = cal.dateComponents([.year, .month, .day], from: cal.date(byAdding: .day, value: dayOffset, to: today)!)
            comps.hour = hour
            comps.minute = minute
            return cal.date(from: comps) ?? today
        }

        func finished(
            id: String,
            competitionId: String,
            home: String,
            away: String,
            day: Int,
            hour: Int,
            minute: Int = 0,
            homeScore: Int,
            awayScore: Int,
            periods: ([Int], [Int]),
            venue: String,
            round: Int,
            homeScorer: String,
            awayScorer: String,
            phase: CompetitionPhase = .regular
        ) -> Match {
            let events = syntheticEvents(
                matchId: id,
                homeTeamId: home,
                awayTeamId: away,
                homeScore: homeScore,
                awayScore: awayScore,
                homePeriodScores: periods.0,
                awayPeriodScores: periods.1,
                homeScorerId: homeScorer,
                awayScorerId: awayScorer
            )
            return Match(
                id: id,
                competitionId: competitionId,
                homeTeamId: home,
                awayTeamId: away,
                scheduledAt: at(day, hour: hour, minute: minute),
                status: .finished,
                period: .finished,
                clock: nil,
                phase: phase,
                homeScore: homeScore,
                awayScore: awayScore,
                homePeriodScores: periods.0,
                awayPeriodScores: periods.1,
                venue: venue,
                round: round,
                events: events,
                attendance: Int.random(in: 120...520),
                homeShots: homeScore * 7 + Int.random(in: 8...18),
                awayShots: awayScore * 7 + Int.random(in: 8...18),
                homePowerplayGoals: homeScore > 0 ? 1 : 0,
                awayPowerplayGoals: awayScore > 1 ? 1 : 0,
                homeShorthandedGoals: 0,
                awayShorthandedGoals: 0,
                referees: "Vilém Jonák, Martin Černý"
            )
        }

        func scheduled(
            id: String,
            competitionId: String,
            home: String,
            away: String,
            day: Int,
            hour: Int,
            minute: Int = 0,
            venue: String,
            round: Int,
            streamURL: String? = nil,
            streamLabel: String? = nil
        ) -> Match {
            Match(
                id: id,
                competitionId: competitionId,
                homeTeamId: home,
                awayTeamId: away,
                scheduledAt: at(day, hour: hour, minute: minute),
                status: .scheduled,
                period: .notStarted,
                clock: nil,
                phase: .regular,
                homeScore: 0,
                awayScore: 0,
                homePeriodScores: [],
                awayPeriodScores: [],
                venue: venue,
                round: round,
                events: [],
                attendance: nil,
                streamURL: streamURL,
                streamLabel: streamLabel
            )
        }

        var matches: [Match] = [
            Match(id: "m-live-1", competitionId: "extraliga-2025-26", homeTeamId: "hostivar", awayTeamId: "svitkov", scheduledAt: at(0, hour: 18), status: .live, period: .second, clock: "08:42", phase: .regular, homeScore: 3, awayScore: 2, homePeriodScores: [1, 2], awayPeriodScores: [1, 1], venue: "HBC Hostivař Arena", round: 23, events: [
                .init(id: "e1", kind: .goal, minute: 7, second: 12, teamId: "hostivar", playerId: "cejka", assistIds: ["hos-divis", "hos-dostal"], description: "Gól Jan Čejka", period: 1),
                .init(id: "e2", kind: .goal, minute: 14, second: 3, teamId: "svitkov", playerId: "benes", assistIds: ["svi-f1", "svi-f2"], description: "Gól Martin Beneš", period: 1),
                .init(id: "e2b", kind: .penalty, minute: 18, second: 36, teamId: "hostivar", playerId: "cejka", assistIds: [], description: "Vyloučení 2 min – Čejka (Hrubost)", period: 1),
                .init(id: "e3", kind: .goal, minute: 3, second: 41, teamId: "hostivar", playerId: "cejka", assistIds: ["hos-kern", "hos-krticka"], description: "Gól Jan Čejka", period: 2),
                .init(id: "e3b", kind: .goal, minute: 8, second: 5, teamId: "svitkov", playerId: "benes", assistIds: ["svi-f2", "svi-f3"], description: "Gól Martin Beneš", period: 2),
                .init(id: "e4", kind: .goal, minute: 11, second: 22, teamId: "hostivar", playerId: "cejka", assistIds: ["hos-capek", "hos-pirek"], description: "Gól Jan Čejka", period: 2),
                .init(id: "e4b", kind: .penalty, minute: 13, second: 10, teamId: "svitkov", playerId: "benes", assistIds: [], description: "Vyloučení 2 min – Beneš (Hákování)", period: 2)
            ], attendance: 420, streamURL: "https://www.youtube.com/@hokejbal", streamLabel: "YouTube ČMSHb", homeShots: 28, awayShots: 22, homePowerplayGoals: 1, awayPowerplayGoals: 0, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Vilém Jonák, Martin Černý"),
            Match(id: "m-live-2", competitionId: "extraliga-2025-26", homeTeamId: "letohrad", awayTeamId: "kert", scheduledAt: at(0, hour: 17, minute: 30), status: .live, period: .third, clock: "12:05", phase: .regular, homeScore: 4, awayScore: 4, homePeriodScores: [2, 1, 1], awayPeriodScores: [1, 2, 1], venue: "Letohrad", round: 23, events: [
                .init(id: "e5", kind: .goal, minute: 2, second: 0, teamId: "letohrad", playerId: "novak", assistIds: ["let-bogdany", "let-brozek"], description: "Gól Petr Novák", period: 3)
            ], attendance: 380, streamURL: "https://www.ceskatelevize.cz/sport/", streamLabel: "ČT Sport", homeShots: 31, awayShots: 27, homePowerplayGoals: 0, awayPowerplayGoals: 1, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Petr Novotný, Jan Svoboda"),
            Match(id: "m-live-3", competitionId: "1liga-2025-26", homeTeamId: "vlci", awayTeamId: "trinec", scheduledAt: at(0, hour: 16), status: .live, period: .first, clock: "04:18", phase: .regular, homeScore: 1, awayScore: 0, homePeriodScores: [1], awayPeriodScores: [0], venue: "Ústí nad Labem", round: 12, events: [
                .init(id: "e6", kind: .goal, minute: 4, second: 18, teamId: "vlci", playerId: "navarra", assistIds: ["faigl", "vlci-f1"], description: "Gól Roman Navarra", period: 1)
            ], attendance: 210, streamURL: "https://www.hokejbal.cz", streamLabel: "Hokejbal.cz", homeShots: 12, awayShots: 8, homePowerplayGoals: 0, awayPowerplayGoals: 0, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Tomáš Horák"),
            Match(id: "m-live-4", competitionId: "regionalni-2025-26", homeTeamId: "kolin", awayTeamId: "benesov", scheduledAt: at(0, hour: 19), status: .live, period: .second, clock: "06:20", phase: .regular, homeScore: 1, awayScore: 0, homePeriodScores: [0, 1], awayPeriodScores: [0, 0], venue: "Kolín", round: 8, events: [
                .init(id: "e7", kind: .goal, minute: 5, second: 11, teamId: "kolin", playerId: "kolin-f1", assistIds: ["kolin-f2", "kolin-f3"], description: "Gól Kolín", period: 2)
            ], attendance: 95, homeShots: 14, awayShots: 9, referees: "Jan Novák"),
            Match(id: "m-live-5", competitionId: "zeny-2025-26", homeTeamId: "palmovka", awayTeamId: "plzen-z", scheduledAt: at(0, hour: 15), status: .live, period: .third, clock: "09:01", phase: .regular, homeScore: 2, awayScore: 1, homePeriodScores: [1, 0, 1], awayPeriodScores: [0, 1, 0], venue: "Praha – Palmovka", round: 6, events: [
                .init(id: "e8", kind: .goal, minute: 4, second: 0, teamId: "palmovka", playerId: "kantorova", assistIds: ["palmovka-f1", "palmovka-f2"], description: "Gól Andrea Kantorová", period: 1),
                .init(id: "e9", kind: .goal, minute: 10, second: 22, teamId: "plzen-z", playerId: "plzen-z-f1", assistIds: ["plzen-z-f2", "plzen-z-f3"], description: "Gól Plzeň Ž", period: 2),
                .init(id: "e10", kind: .goal, minute: 7, second: 40, teamId: "palmovka", playerId: "kantorova", assistIds: ["palmovka-f2", "palmovka-f3"], description: "Gól Andrea Kantorová", period: 3)
            ], attendance: 140, homeShots: 18, awayShots: 15, referees: "Eva Horáková"),
        ]

        matches += [
            finished(id: "m-fin-1", competitionId: "extraliga-2025-26", home: "plzen", away: "dobrany", day: -1, hour: 18, homeScore: 5, awayScore: 3, periods: ([2, 1, 2], [1, 1, 1]), venue: "Plzeň", round: 22, homeScorer: "kral", awayScorer: "dob-brtnik", phase: .playoffs),
            finished(id: "m-fin-2", competitionId: "extraliga-2025-26", home: "pardubice", away: "usti", day: -1, hour: 17, homeScore: 3, awayScore: 2, periods: ([1, 1, 1], [0, 1, 1]), venue: "Pardubice", round: 22, homeScorer: "kupka", awayScorer: "ust-placeholder", phase: .playoffs),
            finished(id: "m-fin-3", competitionId: "extraliga-2025-26", home: "kladno", away: "mlada", day: -2, hour: 18, homeScore: 1, awayScore: 4, periods: ([0, 1, 0], [2, 1, 1]), venue: "Kladno", round: 21, homeScorer: "jelinek", awayScorer: "mla-placeholder", phase: .playoffs),
            finished(id: "m-fin-4", competitionId: "extraliga-2025-26", home: "hostivar", away: "kert", day: -3, hour: 18, homeScore: 4, awayScore: 1, periods: ([2, 1, 1], [0, 1, 0]), venue: "Hostivař", round: 21, homeScorer: "cejka", awayScorer: "ker-fejfar"),
            finished(id: "m-fin-5", competitionId: "extraliga-2025-26", home: "svitkov", away: "letohrad", day: -4, hour: 17, homeScore: 2, awayScore: 3, periods: ([1, 0, 1], [1, 1, 1]), venue: "Svítkov", round: 20, homeScorer: "benes", awayScorer: "novak"),
            finished(id: "m-fin-6", competitionId: "1liga-2025-26", home: "most", away: "teplice", day: -1, hour: 16, homeScore: 3, awayScore: 3, periods: ([1, 1, 1], [2, 0, 1]), venue: "Most", round: 11, homeScorer: "most-f1", awayScorer: "teplice-f1"),
            finished(id: "m-fin-7", competitionId: "1liga-2025-26", home: "vlci", away: "most", day: -2, hour: 15, homeScore: 5, awayScore: 2, periods: ([2, 2, 1], [1, 0, 1]), venue: "Ústí", round: 10, homeScorer: "navarra", awayScorer: "most-f1"),
            finished(id: "m-fin-8", competitionId: "2liga-2025-26", home: "chomutov", away: "decin", day: -1, hour: 14, homeScore: 4, awayScore: 0, periods: ([2, 1, 1], [0, 0, 0]), venue: "Chomutov", round: 9, homeScorer: "chomutov-f1", awayScorer: "decin-f1"),
            finished(id: "m-fin-9", competitionId: "zeny-2025-26", home: "svitkov-z", away: "palmovka", day: -2, hour: 13, homeScore: 1, awayScore: 2, periods: ([0, 1, 0], [1, 0, 1]), venue: "Pardubice", round: 5, homeScorer: "svitkov-z-f1", awayScorer: "kantorova"),
            finished(id: "m-fin-10", competitionId: "juniori-2025-26", home: "pardubice-j", away: "kladno-j", day: -1, hour: 11, homeScore: 6, awayScore: 4, periods: ([2, 2, 2], [1, 2, 1]), venue: "Pardubice", round: 14, homeScorer: "pardubice-j-f1", awayScorer: "kladno-j-f1"),
            finished(id: "m-fin-11", competitionId: "dorost-2025-26", home: "hostivar-d", away: "plzen-d", day: -3, hour: 12, homeScore: 3, awayScore: 1, periods: ([1, 1, 1], [0, 1, 0]), venue: "Hostivař", round: 12, homeScorer: "hostivar-d-f1", awayScorer: "plzen-d-f1"),
            finished(id: "m-fin-12", competitionId: "regionalni-2025-26", home: "benesov", away: "kolin", day: -2, hour: 18, homeScore: 2, awayScore: 5, periods: ([1, 0, 1], [2, 2, 1]), venue: "Benešov", round: 7, homeScorer: "benesov-f1", awayScorer: "kolin-f1"),
            finished(id: "m-fin-13", competitionId: "oblastni-2025-26", home: "rakovnik", away: "slany", day: -1, hour: 17, homeScore: 1, awayScore: 1, periods: ([0, 1, 0], [1, 0, 0]), venue: "Rakovník", round: 6, homeScorer: "rakovnik-f1", awayScorer: "slany-f1"),
            finished(id: "m-fin-14", competitionId: "starsi-zaci-2025-26", home: "hostivar-sz", away: "kert-sz", day: -1, hour: 10, homeScore: 4, awayScore: 3, periods: ([1, 2, 1], [1, 1, 1]), venue: "Hostivař", round: 5, homeScorer: "hostivar-sz-f1", awayScorer: "kert-sz-f1"),
            finished(id: "m-fin-15", competitionId: "mladsi-zaci-2025-26", home: "letohrad-mz", away: "usti-mz", day: -2, hour: 9, homeScore: 2, awayScore: 2, periods: ([1, 0, 1], [0, 2, 0]), venue: "Letohrad", round: 4, homeScorer: "letohrad-mz-f1", awayScorer: "usti-mz-f1"),
            finished(id: "m-fin-16", competitionId: "pripravky-2025-26", home: "kladno-pr", away: "pardubice-pr", day: -3, hour: 9, homeScore: 5, awayScore: 4, periods: ([2, 1, 2], [1, 2, 1]), venue: "Kladno", round: 3, homeScorer: "kladno-pr-f1", awayScorer: "pardubice-pr-f1"),
            finished(id: "m-fin-17", competitionId: "minipripravky-2025-26", home: "plzen-mp", away: "hostivar-mp", day: -1, hour: 8, homeScore: 3, awayScore: 3, periods: ([1, 1, 1], [1, 1, 1]), venue: "Plzeň", round: 2, homeScorer: "plzen-mp-f1", awayScorer: "hostivar-mp-f1"),
            finished(id: "m-fin-18", competitionId: "prebor-zen-2025-26", home: "praha-pz", away: "brno-pz", day: -2, hour: 14, homeScore: 2, awayScore: 0, periods: ([1, 0, 1], [0, 0, 0]), venue: "Praha", round: 4, homeScorer: "praha-pz-f1", awayScorer: "brno-pz-f1"),
            finished(id: "m-fin-19", competitionId: "extraliga-2024-25", home: "hostivar", away: "plzen", day: -120, hour: 18, homeScore: 3, awayScore: 2, periods: ([1, 1, 1], [1, 0, 1]), venue: "Hostivař", round: 30, homeScorer: "cejka", awayScorer: "kral"),
            finished(id: "m-fin-20", competitionId: "extraliga-2024-25", home: "letohrad", away: "svitkov", day: -121, hour: 17, homeScore: 1, awayScore: 4, periods: ([0, 1, 0], [2, 1, 1]), venue: "Letohrad", round: 30, homeScorer: "novak", awayScorer: "benes"),
        ]

        matches += [
            scheduled(id: "m-sch-1", competitionId: "extraliga-2025-26", home: "blatna", away: "hradec", day: 1, hour: 15, venue: "Blatná", round: 24, streamURL: "https://www.youtube.com/@hokejbal", streamLabel: "YouTube ČMSHb"),
            scheduled(id: "m-sch-2", competitionId: "extraliga-2025-26", home: "svitkov", away: "letohrad", day: 1, hour: 17, minute: 30, venue: "Pardubice – Svítkov", round: 24, streamURL: "https://www.ceskatelevize.cz/sport/", streamLabel: "ČT Sport"),
            scheduled(id: "m-sch-3", competitionId: "extraliga-2025-26", home: "kert", away: "hostivar", day: 2, hour: 18, venue: "Praha – Kert Park", round: 24, streamURL: "https://www.hokejbal.cz", streamLabel: "Hokejbal.cz"),
            scheduled(id: "m-sch-4", competitionId: "extraliga-2025-26", home: "dobrany", away: "plzen", day: 3, hour: 14, venue: "Dobřany", round: 25),
            scheduled(id: "m-sch-5", competitionId: "1liga-2025-26", home: "trinec", away: "teplice", day: 1, hour: 16, venue: "Třinec", round: 13, streamURL: "https://www.youtube.com/@hokejbal", streamLabel: "YouTube ČMSHb"),
            scheduled(id: "m-sch-6", competitionId: "zeny-2025-26", home: "plzen-z", away: "svitkov-z", day: 2, hour: 13, venue: "Plzeň", round: 7),
            scheduled(id: "m-sch-7", competitionId: "juniori-2025-26", home: "kladno-j", away: "pardubice-j", day: 1, hour: 11, venue: "Kladno", round: 15),
            scheduled(id: "m-sch-8", competitionId: "dorost-2025-26", home: "plzen-d", away: "hostivar-d", day: 2, hour: 12, venue: "Plzeň", round: 13),
            scheduled(id: "m-sch-9", competitionId: "regionalni-2025-26", home: "kolin", away: "benesov", day: 1, hour: 19, venue: "Kolín", round: 9),
            scheduled(id: "m-sch-10", competitionId: "2liga-2025-26", home: "decin", away: "chomutov", day: 3, hour: 15, venue: "Děčín", round: 10),
        ]

        return matches
    }

    /// Vygeneruje góly + pár trestů podle skóre / třetin.
    private static func syntheticEvents(
        matchId: String,
        homeTeamId: String,
        awayTeamId: String,
        homeScore: Int,
        awayScore: Int,
        homePeriodScores: [Int],
        awayPeriodScores: [Int],
        homeScorerId: String,
        awayScorerId: String
    ) -> [MatchEvent] {
        var events: [MatchEvent] = []
        var idx = 0
        let periods = max(homePeriodScores.count, awayPeriodScores.count, 1)
        for p in 1...periods {
            let h = p <= homePeriodScores.count ? homePeriodScores[p - 1] : 0
            let a = p <= awayPeriodScores.count ? awayPeriodScores[p - 1] : 0
            for g in 0..<h {
                idx += 1
                events.append(.init(
                    id: "\(matchId)-hg-\(idx)",
                    kind: .goal,
                    minute: min(2 + g * 4, 14),
                    second: (g * 17) % 60,
                    teamId: homeTeamId,
                    playerId: homeScorerId,
                    assistIds: ["\(homeTeamId)-f1", "\(homeTeamId)-f2"],
                    description: "Gól",
                    period: p
                ))
            }
            for g in 0..<a {
                idx += 1
                events.append(.init(
                    id: "\(matchId)-ag-\(idx)",
                    kind: .goal,
                    minute: min(3 + g * 4, 14),
                    second: (g * 23) % 60,
                    teamId: awayTeamId,
                    playerId: awayScorerId,
                    assistIds: ["\(awayTeamId)-f1", "\(awayTeamId)-f2"],
                    description: "Gól",
                    period: p
                ))
            }
            if p == 1 {
                idx += 1
                events.append(.init(
                    id: "\(matchId)-pen-\(idx)",
                    kind: .penalty,
                    minute: 11,
                    second: 20,
                    teamId: awayTeamId,
                    playerId: awayScorerId,
                    assistIds: [],
                    description: "Vyloučení 2 min – (Hrubost)",
                    period: p
                ))
            }
        }
        _ = homeScore
        _ = awayScore
        return events.sorted {
            if $0.period != $1.period { return $0.period < $1.period }
            if $0.minute != $1.minute { return $0.minute < $1.minute }
            return $0.second < $1.second
        }
    }

    /// Základní soupiska pro týmy bez ručně zadaných hráčů.
    private static func syntheticRoster(for teamId: String) -> [Player] {
        let lastNames = ["Novák", "Svoboda", "Dvořák", "Černý", "Procházka", "Kučera", "Veselý", "Horák", "Němec", "Pokorný", "Marek", "Král"]
        var players: [Player] = []
        // 2 gólmani
        for i in 0..<2 {
            players.append(.init(
                id: "\(teamId)-g\(i + 1)",
                firstName: "Jan",
                lastName: lastNames[i],
                number: 30 + i,
                position: .goalie,
                teamId: teamId,
                games: 10,
                goals: 0,
                assists: 1,
                points: 1,
                penaltyMinutes: 0,
                savePercentage: 90.5 - Double(i),
                goalsAgainstAverage: 2.4 + Double(i) * 0.3
            ))
        }
        // 4 obránci
        for i in 0..<4 {
            let g = 1 + i
            let a = 2 + i
            players.append(.init(
                id: "\(teamId)-d\(i + 1)",
                firstName: "Petr",
                lastName: lastNames[i + 2],
                number: 4 + i,
                position: .defenseman,
                teamId: teamId,
                games: 12,
                goals: g,
                assists: a,
                points: g + a,
                penaltyMinutes: 4 + i * 2,
                savePercentage: nil,
                goalsAgainstAverage: nil
            ))
        }
        // 6 útočníků
        for i in 0..<6 {
            let g = 3 + i
            let a = 2 + i / 2
            players.append(.init(
                id: "\(teamId)-f\(i + 1)",
                firstName: "Tomáš",
                lastName: lastNames[i + 6],
                number: 10 + i,
                position: .forward,
                teamId: teamId,
                games: 12,
                goals: g,
                assists: a,
                points: g + a,
                penaltyMinutes: 2 + i,
                savePercentage: nil,
                goalsAgainstAverage: nil
            ))
        }
        return players
    }
}

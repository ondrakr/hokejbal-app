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
    private let standingsData: [StandingRow]
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
        playersData = Self.makePlayers()
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
            .init(id: "palmovka", name: "HBC KOVO Palmovka", shortName: "Palmovka", city: "Praha", primaryColorHex: "00695C", logoInitials: "KP", logoURL: "https://uqnptbznnbeldtuvywtt.supabase.co/storage/v1/object/public/club-logos/palmovka.png", competitionId: "zeny-2025-26")
        ]

        playersData = []

        standingsData = [
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
        _ = competitionId
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
        _ = competitionId
        return standingsData
    }

    func news(limit: Int) async throws -> [NewsArticle] {
        Array(newsData.prefix(limit))
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
        return [
            PlayerSeasonStat(
                id: "\(playerId)-2025-26",
                playerId: playerId,
                clubId: player.teamId,
                competitionId: "extraliga-2025-26",
                seasonId: "2025-26",
                seasonLabel: "2025/26",
                competitionName: "Extraliga hokejbalu",
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
                competitionId: "extraliga-2024-25",
                seasonId: "2024-25",
                seasonLabel: "2024/25",
                competitionName: "Extraliga hokejbalu",
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
        let current = standingsData.first { $0.teamId == clubId }
        return [
            ClubSeasonRecord(
                seasonId: "2025-26",
                seasonLabel: "2025/26",
                competitionId: "extraliga-2025-26",
                competitionName: "Extraliga hokejbalu",
                standing: current
            ),
            ClubSeasonRecord(
                seasonId: "2024-25",
                seasonLabel: "2024/25",
                competitionId: "extraliga-2024-25",
                competitionName: "Extraliga hokejbalu",
                standing: current.map {
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
                        goalsAgainst: $0.goalsAgainst + 3,
                        points: max($0.points - 3, 0)
                    )
                }
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

        return [
            Match(id: "m-live-1", competitionId: "extraliga-2025-26", homeTeamId: "hostivar", awayTeamId: "svitkov", scheduledAt: at(0, hour: 18), status: .live, period: .second, clock: "08:42", phase: .regular, homeScore: 3, awayScore: 2, homePeriodScores: [1, 2], awayPeriodScores: [1, 1], venue: "HBC Hostivař Arena", round: 23, events: [
                .init(id: "e1", kind: .goal, minute: 7, second: 12, teamId: "hostivar", playerId: "cejka", assistIds: [], description: "Gól Jan Čejka", period: 1),
                .init(id: "e2", kind: .goal, minute: 14, second: 3, teamId: "svitkov", playerId: "benes", assistIds: [], description: "Gól Martin Beneš", period: 1),
                .init(id: "e2b", kind: .penalty, minute: 18, second: 36, teamId: "hostivar", playerId: "cejka", assistIds: [], description: "Vyloučení 2 min – Čejka (Hrubost)", period: 1),
                .init(id: "e3", kind: .goal, minute: 3, second: 41, teamId: "hostivar", playerId: "cejka", assistIds: [], description: "Gól Jan Čejka", period: 2),
                .init(id: "e3b", kind: .goal, minute: 8, second: 5, teamId: "svitkov", playerId: "benes", assistIds: [], description: "Gól Martin Beneš", period: 2),
                .init(id: "e4", kind: .goal, minute: 11, second: 22, teamId: "hostivar", playerId: "cejka", assistIds: [], description: "Gól Jan Čejka", period: 2),
                .init(id: "e4b", kind: .penalty, minute: 13, second: 10, teamId: "svitkov", playerId: "benes", assistIds: [], description: "Vyloučení 2 min – Beneš (Hákování)", period: 2)
            ], attendance: 420, streamURL: "https://www.youtube.com/@hokejbal", streamLabel: "YouTube ČMSHb", homeShots: 28, awayShots: 22, homePowerplayGoals: 1, awayPowerplayGoals: 0, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Vilém Jonák, Martin Černý"),
            Match(id: "m-live-2", competitionId: "extraliga-2025-26", homeTeamId: "letohrad", awayTeamId: "kert", scheduledAt: at(0, hour: 17, minute: 30), status: .live, period: .third, clock: "12:05", phase: .regular, homeScore: 4, awayScore: 4, homePeriodScores: [2, 1, 1], awayPeriodScores: [1, 2, 1], venue: "Letohrad", round: 23, events: [
                .init(id: "e5", kind: .goal, minute: 2, second: 0, teamId: "letohrad", playerId: "novak", assistIds: [], description: "Gól Petr Novák", period: 3)
            ], attendance: 380, streamURL: "https://www.ceskatelevize.cz/sport/", streamLabel: "ČT Sport", homeShots: 31, awayShots: 27, homePowerplayGoals: 0, awayPowerplayGoals: 1, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Petr Novotný, Jan Svoboda"),
            Match(id: "m-live-3", competitionId: "1liga-2025-26", homeTeamId: "vlci", awayTeamId: "trinec", scheduledAt: at(0, hour: 16), status: .live, period: .first, clock: "04:18", phase: .regular, homeScore: 1, awayScore: 0, homePeriodScores: [1], awayPeriodScores: [0], venue: "Ústí nad Labem", round: 12, events: [
                .init(id: "e6", kind: .goal, minute: 4, second: 18, teamId: "vlci", playerId: "navarra", assistIds: ["faigl"], description: "Gól Roman Navarra (Faigl)", period: 1)
            ], attendance: 210, streamURL: "https://www.hokejbal.cz", streamLabel: "Hokejbal.cz", homeShots: 12, awayShots: 8, homePowerplayGoals: 0, awayPowerplayGoals: 0, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Tomáš Horák"),
            Match(id: "m-fin-1", competitionId: "extraliga-2025-26", homeTeamId: "plzen", awayTeamId: "dobrany", scheduledAt: at(-1, hour: 18), status: .finished, period: .finished, clock: nil, phase: .playoffs, homeScore: 5, awayScore: 3, homePeriodScores: [2, 1, 2], awayPeriodScores: [1, 1, 1], venue: "Plzeň", round: 22, events: [
                .init(id: "f1", kind: .goal, minute: 2, second: 39, teamId: "plzen", playerId: "kral", assistIds: [], description: "Gól Dan Král", period: 1),
                .init(id: "f2", kind: .goal, minute: 8, second: 11, teamId: "dobrany", playerId: "dob-brtnik", assistIds: [], description: "Gól Jan Brtník", period: 1),
                .init(id: "f3", kind: .goal, minute: 12, second: 4, teamId: "plzen", playerId: "kral", assistIds: [], description: "Gól Dan Král", period: 1),
                .init(id: "f4", kind: .penalty, minute: 14, second: 20, teamId: "dobrany", playerId: "dob-duchek", assistIds: [], description: "Vyloučení 2 min – Duchek (Hrubost)", period: 1),
                .init(id: "f5", kind: .goal, minute: 5, second: 1, teamId: "dobrany", playerId: "dob-humlicek", assistIds: [], description: "Gól Tomáš Humlíček", period: 2),
                .init(id: "f6", kind: .goal, minute: 9, second: 44, teamId: "plzen", playerId: "kral", assistIds: [], description: "Gól Dan Král", period: 2),
                .init(id: "f7", kind: .goal, minute: 3, second: 10, teamId: "plzen", playerId: "kral", assistIds: [], description: "Gól Dan Král", period: 3),
                .init(id: "f8", kind: .goal, minute: 11, second: 55, teamId: "dobrany", playerId: "dob-kolarik", assistIds: [], description: "Gól Jakub Kolařík", period: 3),
                .init(id: "f9", kind: .goal, minute: 14, second: 2, teamId: "plzen", playerId: "kral", assistIds: [], description: "Gól Dan Král", period: 3)
            ], attendance: 510, homeShots: 24, awayShots: 29, homePowerplayGoals: 0, awayPowerplayGoals: 0, homeShorthandedGoals: 0, awayShorthandedGoals: 0, referees: "Vilém Jonák, Martin Černý"),
            Match(id: "m-fin-2", competitionId: "extraliga-2025-26", homeTeamId: "pardubice", awayTeamId: "usti", scheduledAt: at(-1, hour: 17), status: .finished, period: .finished, clock: nil, phase: .playoffs, homeScore: 2, awayScore: 2, homePeriodScores: [1, 0, 1], awayPeriodScores: [0, 1, 1], venue: "Pardubice", round: 22, events: [], attendance: 290),
            Match(id: "m-fin-3", competitionId: "extraliga-2025-26", homeTeamId: "kladno", awayTeamId: "mlada", scheduledAt: at(-2, hour: 18), status: .finished, period: .finished, clock: nil, phase: .playoffs, homeScore: 1, awayScore: 4, homePeriodScores: [0, 1, 0], awayPeriodScores: [2, 1, 1], venue: "Kladno", round: 21, events: [], attendance: 180),
            Match(id: "m-sch-1", competitionId: "extraliga-2025-26", homeTeamId: "blatna", awayTeamId: "hradec", scheduledAt: at(1, hour: 15), status: .scheduled, period: .notStarted, clock: nil, phase: .regular, homeScore: 0, awayScore: 0, homePeriodScores: [], awayPeriodScores: [], venue: "Blatná", round: 24, events: [], attendance: nil),
            Match(id: "m-sch-2", competitionId: "extraliga-2025-26", homeTeamId: "svitkov", awayTeamId: "letohrad", scheduledAt: at(1, hour: 17, minute: 30), status: .scheduled, period: .notStarted, clock: nil, phase: .regular, homeScore: 0, awayScore: 0, homePeriodScores: [], awayPeriodScores: [], venue: "Pardubice – Svítkov", round: 24, events: [], attendance: nil),
            Match(id: "m-sch-3", competitionId: "extraliga-2025-26", homeTeamId: "kert", awayTeamId: "hostivar", scheduledAt: at(2, hour: 18), status: .scheduled, period: .notStarted, clock: nil, phase: .regular, homeScore: 0, awayScore: 0, homePeriodScores: [], awayPeriodScores: [], venue: "Praha – Kert Park", round: 24, events: [], attendance: nil),
            Match(id: "m-sch-4", competitionId: "extraliga-2025-26", homeTeamId: "dobrany", awayTeamId: "plzen", scheduledAt: at(3, hour: 14), status: .scheduled, period: .notStarted, clock: nil, phase: .regular, homeScore: 0, awayScore: 0, homePeriodScores: [], awayPeriodScores: [], venue: "Dobřany", round: 25, events: [], attendance: nil)
        ]
    }
}

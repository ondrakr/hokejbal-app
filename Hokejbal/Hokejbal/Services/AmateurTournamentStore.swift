import Foundation
import SwiftUI

// MARK: - Models

enum AmateurTournamentStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case finished

    var label: String {
        switch self {
        case .draft: return "Příprava"
        case .active: return "Probíhá"
        case .finished: return "Ukončen"
        }
    }
}

enum AmateurTournamentFormat: String, Codable, CaseIterable, Sendable, Hashable {
    case roundRobin
    case roundRobinAndPlayoff
    case singleElimination
    case bestOfSeries

    var label: String {
        switch self {
        case .roundRobin: return "Jen základní část"
        case .roundRobinAndPlayoff: return "Základní část + play-off"
        case .singleElimination: return "Jen play-off (vyřazovací)"
        case .bestOfSeries: return "Play-off na více vítězných"
        }
    }

    var detail: String {
        switch self {
        case .roundRobin:
            return "Každý s každým. Tabulka podle bodů."
        case .roundRobinAndPlayoff:
            return "Nejdřív základní část, pak vyřazovací play-off."
        case .singleElimination:
            return "Jednozápasové vyřazování od 1. kola po finále."
        case .bestOfSeries:
            return "Vyřazovací série (best-of 3 / 5 / 7)."
        }
    }

    var hasGroupStage: Bool {
        self == .roundRobin || self == .roundRobinAndPlayoff
    }

    var hasPlayoff: Bool {
        self != .roundRobin
    }

    var usesSeries: Bool {
        self == .bestOfSeries
    }
}

struct AmateurMatchFormat: Codable, Hashable, Sendable {
    var periodCount: Int
    var periodLengthMinutes: Int
    var overtimeEnabled: Bool

    static let standard = AmateurMatchFormat(periodCount: 3, periodLengthMinutes: 15, overtimeEnabled: true)

    var label: String {
        let ot = overtimeEnabled ? " · prodl." : ""
        return "\(periodCount)× \(periodLengthMinutes) min\(ot)"
    }

    var maxPeriodIncludingOT: Int {
        overtimeEnabled ? periodCount + 1 : periodCount
    }
}

enum AmateurMatchPhase: String, Codable, Sendable, Hashable {
    case group
    case playoff

    var label: String {
        switch self {
        case .group: return "Základní část"
        case .playoff: return "Play-off"
        }
    }
}

struct AmateurTournament: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var location: String
    var startDate: Date
    var endDate: Date
    var status: AmateurTournamentStatus
    var notes: String
    var createdAt: Date
    var format: AmateurTournamentFormat
    var matchFormat: AmateurMatchFormat
    /// Dvakrát každý s každým (doma / venku) v základní části.
    var homeAndAway: Bool
    /// Počet týmů do play-off (2 / 4 / 8 / 16).
    var playoffTeamCount: Int
    /// Délka série: 1, 3, 5, 7 (best-of).
    var seriesLength: Int
    var scheduleGenerated: Bool
    /// ID vlastníka (auth.users) — nil u starších lokálních turnajů.
    var ownerId: String?

    var dateRangeLabel: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "cs_CZ")
        df.dateFormat = "d. M."
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return df.string(from: startDate)
        }
        return "\(df.string(from: startDate)) – \(df.string(from: endDate))"
    }

    var seriesWinsNeeded: Int { max(1, seriesLength / 2 + 1) }

    init(
        id: String,
        name: String,
        location: String,
        startDate: Date,
        endDate: Date,
        status: AmateurTournamentStatus,
        notes: String,
        createdAt: Date,
        format: AmateurTournamentFormat = .roundRobinAndPlayoff,
        matchFormat: AmateurMatchFormat = .standard,
        homeAndAway: Bool = false,
        playoffTeamCount: Int = 4,
        seriesLength: Int = 1,
        scheduleGenerated: Bool = false,
        ownerId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.format = format
        self.matchFormat = matchFormat
        self.homeAndAway = homeAndAway
        self.playoffTeamCount = playoffTeamCount
        self.seriesLength = seriesLength
        self.scheduleGenerated = scheduleGenerated
        self.ownerId = ownerId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        location = try c.decode(String.self, forKey: .location)
        startDate = try c.decode(Date.self, forKey: .startDate)
        endDate = try c.decode(Date.self, forKey: .endDate)
        status = try c.decode(AmateurTournamentStatus.self, forKey: .status)
        notes = try c.decode(String.self, forKey: .notes)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        format = try c.decodeIfPresent(AmateurTournamentFormat.self, forKey: .format) ?? .roundRobinAndPlayoff
        matchFormat = try c.decodeIfPresent(AmateurMatchFormat.self, forKey: .matchFormat) ?? .standard
        homeAndAway = try c.decodeIfPresent(Bool.self, forKey: .homeAndAway) ?? false
        playoffTeamCount = try c.decodeIfPresent(Int.self, forKey: .playoffTeamCount) ?? 4
        seriesLength = try c.decodeIfPresent(Int.self, forKey: .seriesLength) ?? 1
        scheduleGenerated = try c.decodeIfPresent(Bool.self, forKey: .scheduleGenerated) ?? false
        ownerId = try c.decodeIfPresent(String.self, forKey: .ownerId)
    }
}

struct AmateurTeam: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var tournamentId: String
    var name: String
    var shortName: String
    var city: String
    var primaryColorHex: String
    var logoInitials: String
}

struct AmateurPlayer: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var teamId: String
    var firstName: String
    var lastName: String
    var number: Int
    var position: PlayerPosition

    var fullName: String { "\(firstName) \(lastName)" }
    var shortName: String { "\(firstName.prefix(1)). \(lastName)" }
}

enum AmateurMatchStatus: String, Codable, Sendable {
    case scheduled
    case live
    case finished

    var label: String {
        switch self {
        case .scheduled: return "Naplánován"
        case .live: return "LIVE"
        case .finished: return "Konec"
        }
    }
}

enum AmateurEventKind: String, Codable, Sendable {
    case goal
    case penalty
}

struct AmateurMatchEvent: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var kind: AmateurEventKind
    var teamId: String
    var playerId: String?
    var assistIds: [String]
    var period: Int
    var minute: Int
    var second: Int
    var penaltyMinutes: Int
    var penaltyReason: String

    var clockLabel: String {
        String(format: "%d. · %02d:%02d", period, minute, second)
    }
}

struct AmateurMatch: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var tournamentId: String
    var homeTeamId: String
    var awayTeamId: String
    var scheduledAt: Date
    var status: AmateurMatchStatus
    var homeScore: Int
    var awayScore: Int
    var homeShots: Int
    var awayShots: Int
    var round: Int
    var venue: String
    var events: [AmateurMatchEvent]
    var phase: AmateurMatchPhase
    var roundName: String
    var seriesId: String?
    var seriesGameIndex: Int?

    var scoreText: String { "\(homeScore):\(awayScore)" }

    var phaseLabel: String {
        if let seriesGameIndex, seriesGameIndex > 0 {
            return "\(roundName) · zápas \(seriesGameIndex)"
        }
        return roundName.isEmpty ? phase.label : roundName
    }

    init(
        id: String,
        tournamentId: String,
        homeTeamId: String,
        awayTeamId: String,
        scheduledAt: Date,
        status: AmateurMatchStatus,
        homeScore: Int,
        awayScore: Int,
        homeShots: Int,
        awayShots: Int,
        round: Int,
        venue: String,
        events: [AmateurMatchEvent],
        phase: AmateurMatchPhase = .group,
        roundName: String = "",
        seriesId: String? = nil,
        seriesGameIndex: Int? = nil
    ) {
        self.id = id
        self.tournamentId = tournamentId
        self.homeTeamId = homeTeamId
        self.awayTeamId = awayTeamId
        self.scheduledAt = scheduledAt
        self.status = status
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.homeShots = homeShots
        self.awayShots = awayShots
        self.round = round
        self.venue = venue
        self.events = events
        self.phase = phase
        self.roundName = roundName.isEmpty ? (phase == .group ? "Kolo \(round)" : phase.label) : roundName
        self.seriesId = seriesId
        self.seriesGameIndex = seriesGameIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tournamentId = try c.decode(String.self, forKey: .tournamentId)
        homeTeamId = try c.decode(String.self, forKey: .homeTeamId)
        awayTeamId = try c.decode(String.self, forKey: .awayTeamId)
        scheduledAt = try c.decode(Date.self, forKey: .scheduledAt)
        status = try c.decode(AmateurMatchStatus.self, forKey: .status)
        homeScore = try c.decode(Int.self, forKey: .homeScore)
        awayScore = try c.decode(Int.self, forKey: .awayScore)
        homeShots = try c.decode(Int.self, forKey: .homeShots)
        awayShots = try c.decode(Int.self, forKey: .awayShots)
        round = try c.decode(Int.self, forKey: .round)
        venue = try c.decode(String.self, forKey: .venue)
        events = try c.decode([AmateurMatchEvent].self, forKey: .events)
        phase = try c.decodeIfPresent(AmateurMatchPhase.self, forKey: .phase) ?? .group
        roundName = try c.decodeIfPresent(String.self, forKey: .roundName) ?? ""
        if roundName.isEmpty {
            roundName = phase == .group ? "Kolo \(round)" : phase.label
        }
        seriesId = try c.decodeIfPresent(String.self, forKey: .seriesId)
        seriesGameIndex = try c.decodeIfPresent(Int.self, forKey: .seriesGameIndex)
    }
}

struct AmateurStandingRow: Identifiable, Hashable, Sendable {
    var id: String { teamId }
    let teamId: String
    let played: Int
    let wins: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let points: Int

    var goalDiff: Int { goalsFor - goalsAgainst }
}

// MARK: - Store

@MainActor
final class AmateurTournamentStore: ObservableObject {
    @Published private(set) var tournaments: [AmateurTournament] = []
    @Published private(set) var teams: [AmateurTeam] = []
    @Published private(set) var players: [AmateurPlayer] = []
    @Published private(set) var matches: [AmateurMatch] = []

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let root = "hb.amateur.v1"
    }

    init() {
        load()
        if tournaments.isEmpty {
            seedDemoIfNeeded()
        }
    }

    // MARK: Lookups

    func tournament(_ id: String) -> AmateurTournament? { tournaments.first { $0.id == id } }
    func team(_ id: String) -> AmateurTeam? { teams.first { $0.id == id } }
    func player(_ id: String) -> AmateurPlayer? { players.first { $0.id == id } }
    func match(_ id: String) -> AmateurMatch? { matches.first { $0.id == id } }

    func teams(in tournamentId: String) -> [AmateurTeam] {
        teams.filter { $0.tournamentId == tournamentId }.sorted { $0.name < $1.name }
    }

    func players(inTeam teamId: String) -> [AmateurPlayer] {
        players.filter { $0.teamId == teamId }.sorted {
            if $0.position != $1.position {
                return positionRank($0.position) < positionRank($1.position)
            }
            return $0.number < $1.number
        }
    }

    func matches(in tournamentId: String) -> [AmateurMatch] {
        matches.filter { $0.tournamentId == tournamentId }.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func standings(for tournamentId: String) -> [AmateurStandingRow] {
        let teams = teams(in: tournamentId)
        let tournament = tournament(tournamentId)
        var map: [String: AmateurStandingRow] = [:]
        for t in teams {
            map[t.id] = AmateurStandingRow(teamId: t.id, played: 0, wins: 0, losses: 0, goalsFor: 0, goalsAgainst: 0, points: 0)
        }
        for match in matches(in: tournamentId) where match.status == .finished {
            // Play-off nepočítat do tabulky základní části.
            if tournament?.format.hasGroupStage == true, match.phase == .playoff { continue }
            guard var home = map[match.homeTeamId], var away = map[match.awayTeamId] else { continue }
            home = apply(result: home, gf: match.homeScore, ga: match.awayScore)
            away = apply(result: away, gf: match.awayScore, ga: match.homeScore)
            map[match.homeTeamId] = home
            map[match.awayTeamId] = away
        }
        return map.values.sorted {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.goalDiff != $1.goalDiff { return $0.goalDiff > $1.goalDiff }
            return $0.goalsFor > $1.goalsFor
        }
    }

    // MARK: Tournament CRUD

    @discardableResult
    func createTournament(
        name: String,
        location: String,
        start: Date,
        end: Date,
        notes: String,
        format: AmateurTournamentFormat = .roundRobinAndPlayoff,
        matchFormat: AmateurMatchFormat = .standard,
        homeAndAway: Bool = false,
        playoffTeamCount: Int = 4,
        seriesLength: Int = 1,
        ownerId: String? = nil
    ) -> AmateurTournament {
        let t = AmateurTournament(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: start,
            endDate: end,
            status: .draft,
            notes: notes,
            createdAt: Date(),
            format: format,
            matchFormat: matchFormat,
            homeAndAway: homeAndAway,
            playoffTeamCount: Self.normalizedPlayoffCount(playoffTeamCount),
            seriesLength: Self.normalizedSeriesLength(seriesLength),
            scheduleGenerated: false,
            ownerId: ownerId
        )
        tournaments.insert(t, at: 0)
        persist()
        Task { await pushTournament(t.id) }
        return t
    }

    func updateTournament(_ tournament: AmateurTournament) {
        guard let i = tournaments.firstIndex(where: { $0.id == tournament.id }) else { return }
        tournaments[i] = tournament
        persist()
        Task { await pushTournament(tournament.id) }
    }

    func deleteTournament(_ id: String) {
        let teamIds = Set(teams.filter { $0.tournamentId == id }.map(\.id))
        tournaments.removeAll { $0.id == id }
        teams.removeAll { $0.tournamentId == id }
        players.removeAll { teamIds.contains($0.teamId) }
        matches.removeAll { $0.tournamentId == id }
        persist()
        Task { await deleteRemoteTournament(id) }
    }

    func pullRemote(using auth: AuthStore) async {
        do {
            let token = try? await auth.validAccessToken()
            let rows = try await auth.authAPI.fetchAmateurTournaments(accessToken: token)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .deferredToDate
            for row in rows {
                guard let data = row.payload.data,
                      let snap = try? decoder.decode(RemoteSnapshot.self, from: data) else { continue }
                mergeRemoteSnapshot(snap, ownerId: row.ownerId)
            }
            persist()
        } catch { /* soft */ }
    }

    func pushTournament(_ id: String) async {
        guard let auth = AuthAccess.store,
              auth.isAuthenticated,
              let userId = auth.userId,
              var tournament = tournament(id) else { return }
        if tournament.ownerId == nil {
            tournament.ownerId = userId
            if let i = tournaments.firstIndex(where: { $0.id == id }) {
                tournaments[i].ownerId = userId
            }
        }
        guard tournament.ownerId == userId else { return }
        do {
            let token = try await auth.validAccessToken()
            let snap = RemoteSnapshot(
                tournament: tournament,
                teams: teams(in: id),
                players: players.filter { teamIds(in: id).contains($0.teamId) },
                matches: matches(in: id)
            )
            let encoder = JSONEncoder()
            let data = try encoder.encode(snap)
            try await auth.authAPI.upsertAmateurTournament(
                id: id,
                ownerId: userId,
                name: tournament.name,
                status: tournament.status.rawValue,
                payload: data,
                accessToken: token
            )
            persist()
        } catch { /* soft */ }
    }

    private func deleteRemoteTournament(_ id: String) async {
        guard let auth = AuthAccess.store, auth.isAuthenticated else { return }
        do {
            let token = try await auth.validAccessToken()
            try await auth.authAPI.deleteAmateurTournament(id: id, accessToken: token)
        } catch { /* soft */ }
    }

    private func teamIds(in tournamentId: String) -> Set<String> {
        Set(teams(in: tournamentId).map(\.id))
    }

    private func mergeRemoteSnapshot(_ snap: RemoteSnapshot, ownerId: String) {
        var t = snap.tournament
        t.ownerId = ownerId
        let tid = t.id
        if let i = tournaments.firstIndex(where: { $0.id == tid }) {
            tournaments[i] = t
        } else {
            tournaments.append(t)
        }
        let oldTeamIds = Set(teams.filter { $0.tournamentId == tid }.map(\.id))
        teams.removeAll { $0.tournamentId == tid }
        players.removeAll { oldTeamIds.contains($0.teamId) }
        matches.removeAll { $0.tournamentId == tid }
        teams.append(contentsOf: snap.teams)
        players.append(contentsOf: snap.players)
        matches.append(contentsOf: snap.matches)
        tournaments.sort { $0.createdAt > $1.createdAt }
    }

    private struct RemoteSnapshot: Codable {
        var tournament: AmateurTournament
        var teams: [AmateurTeam]
        var players: [AmateurPlayer]
        var matches: [AmateurMatch]
    }

    // MARK: Teams / players

    @discardableResult
    func addTeam(tournamentId: String, name: String, shortName: String, city: String, colorHex: String) -> AmateurTeam {
        let initials = String((shortName.isEmpty ? name : shortName).prefix(2)).uppercased()
        let team = AmateurTeam(
            id: UUID().uuidString,
            tournamentId: tournamentId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            shortName: shortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? String(name.prefix(8))
                : shortName.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city,
            primaryColorHex: colorHex.isEmpty ? "C92A2A" : colorHex,
            logoInitials: initials
        )
        teams.append(team)
        persist()
        return team
    }

    func updateTeam(_ team: AmateurTeam) {
        guard let i = teams.firstIndex(where: { $0.id == team.id }) else { return }
        teams[i] = team
        persist()
    }

    func deleteTeam(_ id: String) {
        teams.removeAll { $0.id == id }
        players.removeAll { $0.teamId == id }
        matches.removeAll { $0.homeTeamId == id || $0.awayTeamId == id }
        persist()
    }

    @discardableResult
    func addPlayer(teamId: String, firstName: String, lastName: String, number: Int, position: PlayerPosition) -> AmateurPlayer {
        let p = AmateurPlayer(
            id: UUID().uuidString,
            teamId: teamId,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            number: number,
            position: position
        )
        players.append(p)
        persist()
        return p
    }

    func updatePlayer(_ player: AmateurPlayer) {
        guard let i = players.firstIndex(where: { $0.id == player.id }) else { return }
        players[i] = player
        persist()
    }

    func deletePlayer(_ id: String) {
        players.removeAll { $0.id == id }
        persist()
    }

    // MARK: Matches

    @discardableResult
    func addMatch(
        tournamentId: String,
        homeTeamId: String,
        awayTeamId: String,
        scheduledAt: Date,
        round: Int,
        venue: String,
        phase: AmateurMatchPhase = .group,
        roundName: String = "",
        seriesId: String? = nil,
        seriesGameIndex: Int? = nil
    ) -> AmateurMatch {
        let m = AmateurMatch(
            id: UUID().uuidString,
            tournamentId: tournamentId,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            scheduledAt: scheduledAt,
            status: .scheduled,
            homeScore: 0,
            awayScore: 0,
            homeShots: 0,
            awayShots: 0,
            round: round,
            venue: venue,
            events: [],
            phase: phase,
            roundName: roundName,
            seriesId: seriesId,
            seriesGameIndex: seriesGameIndex
        )
        matches.append(m)
        persist()
        return m
    }

    /// Vygeneruje rozpis podle formátu turnaje. Při `replaceExisting` smaže dosavadní zápasy.
    @discardableResult
    func generateSchedule(tournamentId: String, replaceExisting: Bool = true) -> Bool {
        guard var tournament = tournament(tournamentId) else { return false }
        let teamList = teams(in: tournamentId)
        guard teamList.count >= 2 else { return false }

        if replaceExisting {
            matches.removeAll { $0.tournamentId == tournamentId }
        } else if matches.contains(where: { $0.tournamentId == tournamentId }) {
            return false
        }

        let venue = tournament.location
        var slot = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tournament.startDate) ?? tournament.startDate
        let gap: TimeInterval = 90 * 60
        let ids = teamList.map(\.id)

        switch tournament.format {
        case .roundRobin:
            appendRoundRobin(
                tournamentId: tournamentId,
                teamIds: ids,
                homeAndAway: tournament.homeAndAway,
                venue: venue,
                slot: &slot,
                gap: gap
            )
        case .roundRobinAndPlayoff:
            // Play-off se generuje až z tabulky (`generatePlayoffFromStandings`).
            appendRoundRobin(
                tournamentId: tournamentId,
                teamIds: ids,
                homeAndAway: tournament.homeAndAway,
                venue: venue,
                slot: &slot,
                gap: gap
            )
        case .singleElimination:
            appendPlayoffBracket(
                tournamentId: tournamentId,
                seeds: ids,
                seriesLength: 1,
                venue: venue,
                slot: &slot,
                gap: gap
            )
        case .bestOfSeries:
            appendPlayoffBracket(
                tournamentId: tournamentId,
                seeds: ids,
                seriesLength: Self.normalizedSeriesLength(tournament.seriesLength),
                venue: venue,
                slot: &slot,
                gap: gap
            )
        }

        tournament.scheduleGenerated = true
        tournament.status = .active
        updateTournament(tournament)
        return true
    }

    /// Play-off ze základní části podle aktuální tabulky.
    @discardableResult
    func generatePlayoffFromStandings(tournamentId: String) -> Bool {
        guard var tournament = tournament(tournamentId),
              tournament.format == .roundRobinAndPlayoff else { return false }
        let table = standings(for: tournamentId)
        let count = Self.normalizedPlayoffCount(min(tournament.playoffTeamCount, table.count))
        guard count >= 2 else { return false }
        let seeds = Array(table.prefix(count).map(\.teamId))

        matches.removeAll { $0.tournamentId == tournamentId && $0.phase == .playoff }
        var slot = (matches(in: tournamentId).map(\.scheduledAt).max() ?? tournament.startDate)
            .addingTimeInterval(90 * 60)
        appendPlayoffBracket(
            tournamentId: tournamentId,
            seeds: seeds,
            seriesLength: 1,
            venue: tournament.location,
            slot: &slot,
            gap: 90 * 60
        )
        tournament.scheduleGenerated = true
        updateTournament(tournament)
        return true
    }

    func canGenerateSchedule(tournamentId: String) -> Bool {
        teams(in: tournamentId).count >= 2
    }

    // MARK: Schedule helpers

    private func appendRoundRobin(
        tournamentId: String,
        teamIds: [String],
        homeAndAway: Bool,
        venue: String,
        slot: inout Date,
        gap: TimeInterval
    ) {
        let rounds = Self.roundRobinRounds(teamIds: teamIds)
        for (index, pairs) in rounds.enumerated() {
            let roundNumber = index + 1
            for pair in pairs {
                _ = addMatch(
                    tournamentId: tournamentId,
                    homeTeamId: pair.0,
                    awayTeamId: pair.1,
                    scheduledAt: slot,
                    round: roundNumber,
                    venue: venue,
                    phase: .group,
                    roundName: "Kolo \(roundNumber)"
                )
                slot = slot.addingTimeInterval(gap)
            }
        }
        if homeAndAway {
            let returnRounds = Self.roundRobinRounds(teamIds: teamIds)
            let offset = rounds.count
            for (index, pairs) in returnRounds.enumerated() {
                let roundNumber = offset + index + 1
                for pair in pairs {
                    _ = addMatch(
                        tournamentId: tournamentId,
                        homeTeamId: pair.1,
                        awayTeamId: pair.0,
                        scheduledAt: slot,
                        round: roundNumber,
                        venue: venue,
                        phase: .group,
                        roundName: "Kolo \(roundNumber)"
                    )
                    slot = slot.addingTimeInterval(gap)
                }
            }
        }
    }

    private func appendPlayoffBracket(
        tournamentId: String,
        seeds: [String],
        seriesLength: Int,
        venue: String,
        slot: inout Date,
        gap: TimeInterval
    ) {
        guard seeds.count >= 2 else { return }
        let roundTeams = Self.padToPowerOfTwo(seeds)
        let name = Self.playoffRoundName(teamCount: roundTeams.count)
        let gamesPerSeries = max(1, seriesLength)
        var i = 0
        while i + 1 < roundTeams.count {
            let home = roundTeams[i]
            let away = roundTeams[i + 1]
            defer { i += 2 }
            if home == Self.byePlaceholder || away == Self.byePlaceholder {
                continue // volný postup — zápas se negeneruje
            }
            let seriesId = UUID().uuidString
            for game in 1...gamesPerSeries {
                let homeId = game % 2 == 1 ? home : away
                let awayId = game % 2 == 1 ? away : home
                _ = addMatch(
                    tournamentId: tournamentId,
                    homeTeamId: homeId,
                    awayTeamId: awayId,
                    scheduledAt: slot,
                    round: 1,
                    venue: venue,
                    phase: .playoff,
                    roundName: name,
                    seriesId: gamesPerSeries > 1 ? seriesId : nil,
                    seriesGameIndex: gamesPerSeries > 1 ? game : nil
                )
                slot = slot.addingTimeInterval(gap)
            }
        }
    }

    /// Po dohrání aktuálního play-off kola vygeneruje další (semifinále → finále…).
    @discardableResult
    func generateNextPlayoffRound(tournamentId: String) -> Bool {
        guard let tournament = tournament(tournamentId), tournament.format.hasPlayoff else { return false }
        let playoff = matches(in: tournamentId).filter { $0.phase == .playoff }
        guard !playoff.isEmpty else { return false }
        let currentRound = playoff.map(\.round).max() ?? 1
        let roundMatches = playoff.filter { $0.round == currentRound }
        // Seskupit podle série (nebo jednotlivé zápasy)
        let groups = Dictionary(grouping: roundMatches) { $0.seriesId ?? $0.id }
        var winners: [String] = []
        for (_, games) in groups.sorted(by: { ($0.value.first?.scheduledAt ?? .distantPast) < ($1.value.first?.scheduledAt ?? .distantPast) }) {
            guard let winner = seriesWinner(games: games, winsNeeded: tournament.seriesWinsNeeded) else {
                return false // ještě není dohrané kolo
            }
            winners.append(winner)
        }
        guard winners.count >= 2 else { return false }

        var slot = (roundMatches.map(\.scheduledAt).max() ?? Date()).addingTimeInterval(90 * 60)
        let name = Self.playoffRoundName(teamCount: winners.count * 2) // počet týmů na začátku kola
        // winners už jsou vítězové — další kolo má winners.count týmů
        let nextName = Self.playoffRoundName(teamCount: winners.count)
        let gamesPerSeries = tournament.format.usesSeries ? Self.normalizedSeriesLength(tournament.seriesLength) : 1
        let venue = tournament.location
        var i = 0
        while i + 1 < winners.count {
            let home = winners[i]
            let away = winners[i + 1]
            let seriesId = UUID().uuidString
            for game in 1...gamesPerSeries {
                let homeId = game % 2 == 1 ? home : away
                let awayId = game % 2 == 1 ? away : home
                _ = addMatch(
                    tournamentId: tournamentId,
                    homeTeamId: homeId,
                    awayTeamId: awayId,
                    scheduledAt: slot,
                    round: currentRound + 1,
                    venue: venue,
                    phase: .playoff,
                    roundName: nextName.isEmpty ? name : nextName,
                    seriesId: gamesPerSeries > 1 ? seriesId : nil,
                    seriesGameIndex: gamesPerSeries > 1 ? game : nil
                )
                slot = slot.addingTimeInterval(90 * 60)
            }
            i += 2
        }
        return true
    }

    private func seriesWinner(games: [AmateurMatch], winsNeeded: Int) -> String? {
        var homeWins = 0
        var awayWins = 0
        // Pro sérii je „home“ první zápas domácí
        guard let first = games.sorted(by: { ($0.seriesGameIndex ?? 0) < ($1.seriesGameIndex ?? 0) }).first else { return nil }
        let a = first.homeTeamId
        let b = first.awayTeamId
        for g in games where g.status == .finished {
            if g.homeScore == g.awayScore { continue }
            let winner = g.homeScore > g.awayScore ? g.homeTeamId : g.awayTeamId
            if winner == a { homeWins += 1 } else if winner == b { awayWins += 1 }
        }
        if homeWins >= winsNeeded { return a }
        if awayWins >= winsNeeded { return b }
        // Jednozápas: stačí finished
        if winsNeeded == 1, let g = games.first, g.status == .finished, g.homeScore != g.awayScore {
            return g.homeScore > g.awayScore ? g.homeTeamId : g.awayTeamId
        }
        return nil
    }

    private static let byePlaceholder = "__BYE__"

    private static func padToPowerOfTwo(_ seeds: [String]) -> [String] {
        var result = seeds
        var size = 1
        while size < max(2, result.count) { size *= 2 }
        while result.count < size {
            result.append(byePlaceholder)
        }
        // Klasický seeding: 1 vs N, 2 vs N-1…
        let n = result.count
        var ordered: [String] = []
        for i in 0..<(n / 2) {
            ordered.append(result[i])
            ordered.append(result[n - 1 - i])
        }
        return ordered
    }

    private static func playoffRoundName(teamCount: Int) -> String {
        switch teamCount {
        case 2: return "Finále"
        case 4: return "Semifinále"
        case 8: return "Čtvrtfinále"
        case 16: return "Osmifinále"
        default: return "Play-off (\(teamCount))"
        }
    }

    private static func normalizedPlayoffCount(_ value: Int) -> Int {
        let allowed = [2, 4, 8, 16]
        return allowed.min(by: { abs($0 - value) < abs($1 - value) }) ?? 4
    }

    private static func normalizedSeriesLength(_ value: Int) -> Int {
        let allowed = [1, 3, 5, 7]
        return allowed.min(by: { abs($0 - value) < abs($1 - value) }) ?? 1
    }

    /// Circle method — každé kolo je seznam (home, away).
    private static func roundRobinRounds(teamIds: [String]) -> [[(String, String)]] {
        var teams = teamIds
        if teams.count % 2 == 1 {
            teams.append(byePlaceholder)
        }
        let n = teams.count
        let roundCount = n - 1
        var arr = teams
        var rounds: [[(String, String)]] = []
        for r in 0..<roundCount {
            var pairs: [(String, String)] = []
            for i in 0..<(n / 2) {
                let a = arr[i]
                let b = arr[n - 1 - i]
                guard a != byePlaceholder, b != byePlaceholder else { continue }
                if r % 2 == 0 {
                    pairs.append((a, b))
                } else {
                    pairs.append((b, a))
                }
            }
            rounds.append(pairs)
            let fixed = arr[0]
            let rotated = Array(arr[1...])
            arr = [fixed, rotated.last!] + Array(rotated.dropLast())
        }
        return rounds
    }

    func updateMatch(_ match: AmateurMatch) {
        guard let i = matches.firstIndex(where: { $0.id == match.id }) else { return }
        matches[i] = match
        persist()
    }

    func deleteMatch(_ id: String) {
        matches.removeAll { $0.id == id }
        persist()
    }

    func setMatchStatus(_ id: String, status: AmateurMatchStatus) {
        guard var match = match(id) else { return }
        match.status = status
        updateMatch(match)
    }

    func setShots(matchId: String, home: Int, away: Int) {
        guard var match = match(matchId) else { return }
        match.homeShots = max(0, home)
        match.awayShots = max(0, away)
        updateMatch(match)
    }

    func addGoal(
        matchId: String,
        teamId: String,
        scorerId: String?,
        assistIds: [String],
        period: Int,
        minute: Int,
        second: Int
    ) {
        guard var match = match(matchId) else { return }
        let event = AmateurMatchEvent(
            id: UUID().uuidString,
            kind: .goal,
            teamId: teamId,
            playerId: scorerId,
            assistIds: assistIds,
            period: period,
            minute: minute,
            second: second,
            penaltyMinutes: 0,
            penaltyReason: ""
        )
        match.events.append(event)
        match.events.sort { lhs, rhs in
            if lhs.period != rhs.period { return lhs.period < rhs.period }
            if lhs.minute != rhs.minute { return lhs.minute < rhs.minute }
            return lhs.second < rhs.second
        }
        if teamId == match.homeTeamId { match.homeScore += 1 }
        else if teamId == match.awayTeamId { match.awayScore += 1 }
        if match.status == .scheduled { match.status = .live }
        updateMatch(match)
    }

    func addPenalty(
        matchId: String,
        teamId: String,
        playerId: String?,
        minutes: Int,
        reason: String,
        period: Int,
        minute: Int,
        second: Int
    ) {
        guard var match = match(matchId) else { return }
        let event = AmateurMatchEvent(
            id: UUID().uuidString,
            kind: .penalty,
            teamId: teamId,
            playerId: playerId,
            assistIds: [],
            period: period,
            minute: minute,
            second: second,
            penaltyMinutes: minutes,
            penaltyReason: reason
        )
        match.events.append(event)
        match.events.sort { lhs, rhs in
            if lhs.period != rhs.period { return lhs.period < rhs.period }
            if lhs.minute != rhs.minute { return lhs.minute < rhs.minute }
            return lhs.second < rhs.second
        }
        if match.status == .scheduled { match.status = .live }
        updateMatch(match)
    }

    func removeEvent(matchId: String, eventId: String) {
        guard var match = match(matchId) else { return }
        guard let event = match.events.first(where: { $0.id == eventId }) else { return }
        match.events.removeAll { $0.id == eventId }
        if event.kind == .goal {
            if event.teamId == match.homeTeamId { match.homeScore = max(0, match.homeScore - 1) }
            else if event.teamId == match.awayTeamId { match.awayScore = max(0, match.awayScore - 1) }
        }
        updateMatch(match)
    }

    // MARK: Private

    private func apply(result row: AmateurStandingRow, gf: Int, ga: Int) -> AmateurStandingRow {
        let win = gf > ga
        return AmateurStandingRow(
            teamId: row.teamId,
            played: row.played + 1,
            wins: row.wins + (win ? 1 : 0),
            losses: row.losses + (win ? 0 : 1),
            goalsFor: row.goalsFor + gf,
            goalsAgainst: row.goalsAgainst + ga,
            points: row.points + (win ? 2 : 0)
        )
    }

    private func positionRank(_ p: PlayerPosition) -> Int {
        switch p {
        case .goalie: return 0
        case .defenseman: return 1
        case .forward: return 2
        }
    }

    private func persist() {
        let payload = PersistPayload(tournaments: tournaments, teams: teams, players: players, matches: matches)
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: Keys.root)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: Keys.root),
              let payload = try? JSONDecoder().decode(PersistPayload.self, from: data) else { return }
        tournaments = payload.tournaments.sorted { $0.createdAt > $1.createdAt }
        teams = payload.teams
        players = payload.players
        matches = payload.matches
    }

    private func seedDemoIfNeeded() {
        // Prázdný start — uživatel tvoří turnaje sám v adminu.
    }

    private struct PersistPayload: Codable {
        var tournaments: [AmateurTournament]
        var teams: [AmateurTeam]
        var players: [AmateurPlayer]
        var matches: [AmateurMatch]
    }
}

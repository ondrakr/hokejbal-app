import Foundation

/// PostgREST klient proti Supabase projektu Hokejbal.
actor SupabaseHokejbalAPI: HokejbalAPI {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let d = ISO8601DateFormatter.full.date(from: raw) { return d }
            if let d = ISO8601DateFormatter.fractional.date(from: raw) { return d }
            if let d = ISO8601DateFormatter.dateOnly.date(from: raw) { return d }
            // PostgREST / Postgres někdy vrací „2026-07-18 12:43:29.041108+00“
            let normalized = raw
                .replacingOccurrences(of: " ", with: "T")
                .replacingOccurrences(of: "+00", with: "+00:00")
                .replacingOccurrences(of: "Z", with: "+00:00")
            if let d = ISO8601DateFormatter.full.date(from: normalized) { return d }
            if let d = ISO8601DateFormatter.fractional.date(from: normalized) { return d }
            // Bez offsetu / s milisekundami
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            for format in [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                "yyyy-MM-dd HH:mm:ss.SSSSSSZ",
                "yyyy-MM-dd HH:mm:ssZ"
            ] {
                df.dateFormat = format
                if let d = df.date(from: raw) ?? df.date(from: normalized) { return d }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date \(raw)")
        }
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        self.encoder = JSONEncoder()
    }

    // MARK: - Seasons

    func seasons() async throws -> [Season] {
        let rows: [SeasonRow] = try await get("seasons", query: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "sort_order.desc")
        ])
        return rows.map {
            Season(id: $0.id, label: $0.label, sortOrder: $0.sortOrder, isCurrent: $0.isCurrent)
        }
    }

    func competitions(seasonId: String?) async throws -> [Competition] {
        var items = [
            URLQueryItem(name: "select", value: "*,seasons(label)"),
            URLQueryItem(name: "order", value: "name.asc")
        ]
        if let seasonId {
            items.append(URLQueryItem(name: "season_id", value: "eq.\(seasonId)"))
        }
        let rows: [CompetitionRow] = try await get("competitions", query: items)
        return rows.map { $0.asModel }
    }

    func teams(competitionId: String?) async throws -> [Team] {
        var items = [
            URLQueryItem(
                name: "select",
                value: "id,competition_id,clubs(id,name,short_name,city,primary_color_hex,logo_initials,logo_url)"
            )
        ]
        if let competitionId {
            items.append(URLQueryItem(name: "competition_id", value: "eq.\(competitionId)"))
        }
        let rows: [TeamEntryRow] = try await get("team_entries", query: items)
        return rows.compactMap { $0.asTeam }
    }

    func players(teamId: String?) async throws -> [Player] {
        try await players(teamId: teamId, seasonId: nil, competitionId: nil)
    }

    func players(teamId: String?, seasonId: String?, competitionId: String?) async throws -> [Player] {
        var items = [
            URLQueryItem(
                name: "select",
                value: "*,players(id,first_name,last_name),competitions(id,season_id,name,seasons(label))"
            ),
            URLQueryItem(name: "order", value: "points.desc")
        ]
        if let teamId {
            items.append(URLQueryItem(name: "club_id", value: "eq.\(teamId)"))
        }
        if let competitionId {
            items.append(URLQueryItem(name: "competition_id", value: "eq.\(competitionId)"))
        } else if let seasonId {
            // Filtr přes vnořenou soutěž — nejdřív načti competition ids sezóny.
            let comps = try await competitions(seasonId: seasonId)
            let ids = comps.map(\.id)
            guard !ids.isEmpty else { return [] }
            items.append(URLQueryItem(name: "competition_id", value: "in.(\(ids.joined(separator: ",")))"))
        }
        let rows: [PlayerSeasonRow] = try await get("player_seasons", query: items)
        return rows.compactMap { $0.asPlayer }
    }

    func matches(query: MatchesQuery) async throws -> [Match] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "*,match_events(*)"),
            URLQueryItem(name: "order", value: "scheduled_at.asc")
        ]
        if let competitionId = query.competitionId {
            items.append(URLQueryItem(name: "competition_id", value: "eq.\(competitionId)"))
        } else if let seasonId = query.seasonId {
            let comps = try await competitions(seasonId: seasonId)
            let ids = comps.map(\.id)
            guard !ids.isEmpty else { return [] }
            items.append(URLQueryItem(name: "competition_id", value: "in.(\(ids.joined(separator: ",")))"))
        }
        if let status = query.status {
            items.append(URLQueryItem(name: "status", value: "eq.\(status.rawValue)"))
        }
        if let teamId = query.teamId {
            items.append(URLQueryItem(name: "or", value: "(home_club_id.eq.\(teamId),away_club_id.eq.\(teamId))"))
        }
        if let date = query.date {
            let cal = Calendar.current
            let start = cal.startOfDay(for: date)
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
            let f = ISO8601DateFormatter.full
            items.append(URLQueryItem(name: "scheduled_at", value: "gte.\(f.string(from: start))"))
            items.append(URLQueryItem(name: "scheduled_at", value: "lt.\(f.string(from: end))"))
        }

        let rows: [MatchRow] = try await get("matches", query: items)
        return rows.map { $0.asMatch }
    }

    func liveMatches(since cursor: String?) async throws -> LiveMatchesResponse {
        _ = cursor
        let matches = try await matches(query: MatchesQuery(status: .live))
        return LiveMatchesResponse(matches: matches, updatedAt: Date(), cursor: "supabase-\(Int(Date().timeIntervalSince1970))")
    }

    func matchDetail(id: String) async throws -> Match {
        let rows: [MatchRow] = try await get("matches", query: [
            URLQueryItem(name: "select", value: "*,match_events(*)"),
            URLQueryItem(name: "id", value: "eq.\(id)"),
            URLQueryItem(name: "limit", value: "1")
        ])
        guard let match = rows.first?.asMatch else { throw APIError.notFound }
        return match
    }

    func standings(competitionId: String) async throws -> [StandingRow] {
        let rows: [StandingRowDTO] = try await get("standings", query: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "competition_id", value: "eq.\(competitionId)"),
            URLQueryItem(name: "order", value: "rank.asc")
        ])
        return rows.map { $0.asModel }
    }

    func news(limit: Int) async throws -> [NewsArticle] {
        if let live = try? await HokejbalCzNewsClient.fetch(limit: limit), !live.isEmpty {
            return live
        }
        let rows: [NewsRow] = try await get("news", query: [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "published_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ])
        return rows.map { $0.asModel }
    }

    func player(id: String) async throws -> Player {
        // Aktuální sezóna preferována
        let seasons = try await seasons()
        let current = seasons.first(where: \.isCurrent) ?? seasons.first
        if let current {
            let list = try await players(teamId: nil, seasonId: current.id, competitionId: nil)
            if let found = list.first(where: { $0.id == id }) { return found }
        }
        let any = try await players(teamId: nil, seasonId: nil, competitionId: nil)
        guard let found = any.first(where: { $0.id == id }) else { throw APIError.notFound }
        return found
    }

    func team(id: String) async throws -> Team {
        let seasons = try await seasons()
        let current = seasons.first(where: \.isCurrent) ?? seasons.first
        let all = try await teams(competitionId: nil)
        if let current {
            let comps = try await competitions(seasonId: current.id)
            let ids = Set(comps.map(\.id))
            if let t = all.first(where: { $0.id == id && ids.contains($0.competitionId) }) {
                return t
            }
        }
        guard let t = all.first(where: { $0.id == id }) else { throw APIError.notFound }
        return t
    }

    func playerHistory(playerId: String) async throws -> [PlayerSeasonStat] {
        let rows: [PlayerSeasonRow] = try await get("player_seasons", query: [
            URLQueryItem(
                name: "select",
                value: "*,players(id,first_name,last_name),competitions(id,season_id,name,seasons(label))"
            ),
            URLQueryItem(name: "player_id", value: "eq.\(playerId)"),
            URLQueryItem(name: "order", value: "competition_id.desc")
        ])
        return rows.compactMap { $0.asHistory }
    }

    func clubSeasonHistory(clubId: String) async throws -> [ClubSeasonRecord] {
        let rows: [StandingHistoryRow] = try await get("standings", query: [
            URLQueryItem(
                name: "select",
                value: "*,competitions(id,season_id,name,seasons(label))"
            ),
            URLQueryItem(name: "club_id", value: "eq.\(clubId)"),
            URLQueryItem(name: "order", value: "competition_id.desc")
        ])
        return rows.compactMap { $0.asRecord }
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ table: String, query: [URLQueryItem]) async throws -> T {
        var components = URLComponents(url: SupabaseConfig.restURL.appendingPathComponent(table), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        guard let url = components.url else { throw APIError.notConfigured }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.notConfigured }
            guard (200..<300).contains(http.statusCode) else {
                #if DEBUG
                let body = String(data: data, encoding: .utf8) ?? ""
                print("Supabase error \(http.statusCode): \(body)")
                #endif
                throw APIError.network(URLError(.badServerResponse))
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }
}

// MARK: - Row DTOs

private struct SeasonRow: Decodable {
    let id: String
    let label: String
    let sortOrder: Int
    let isCurrent: Bool
}

private struct CompetitionRow: Decodable {
    let id: String
    let seasonId: String
    let slug: String
    let name: String
    let shortName: String
    /// `logo_url` → `logoUrl` (convertFromSnakeCase); ne `logoURL`.
    let logoUrl: String?
    let logoInitials: String
    let iconSystemName: String
    let seasons: SeasonLabelEmbed?

    struct SeasonLabelEmbed: Decodable {
        let label: String
    }

    var asModel: Competition {
        Competition(
            id: id,
            slug: slug,
            seasonId: seasonId,
            name: name,
            shortName: shortName,
            season: seasons?.label ?? seasonId,
            logoURL: logoUrl,
            logoInitials: logoInitials,
            iconSystemName: iconSystemName
        )
    }
}

private struct ClubEmbed: Decodable {
    let id: String
    let name: String
    let shortName: String
    let city: String
    let primaryColorHex: String
    let logoInitials: String
    /// `logo_url` → `logoUrl` (convertFromSnakeCase); ne `logoURL`.
    let logoUrl: String?
}

private struct TeamEntryRow: Decodable {
    let id: String
    let competitionId: String
    let clubs: ClubEmbed?

    var asTeam: Team? {
        guard let c = clubs else { return nil }
        return Team(
            id: c.id,
            name: c.name,
            shortName: c.shortName,
            city: c.city,
            primaryColorHex: c.primaryColorHex,
            logoInitials: c.logoInitials,
            logoURL: c.logoUrl,
            competitionId: competitionId
        )
    }
}

private struct PlayerEmbed: Decodable {
    let id: String
    let firstName: String
    let lastName: String
}

private struct CompetitionEmbed: Decodable {
    let id: String
    let seasonId: String
    let name: String
    let seasons: SeasonLabelEmbed?

    struct SeasonLabelEmbed: Decodable {
        let label: String
    }
}

private struct PlayerSeasonRow: Decodable {
    let id: String
    let playerId: String
    let clubId: String
    let competitionId: String
    let number: Int
    let position: PlayerPosition
    let games: Int
    let goals: Int
    let assists: Int
    let points: Int
    let penaltyMinutes: Int
    let savePercentage: Double?
    let goalsAgainstAverage: Double?
    let players: PlayerEmbed?
    let competitions: CompetitionEmbed?

    var asPlayer: Player? {
        guard let p = players else { return nil }
        return Player(
            id: p.id,
            firstName: p.firstName,
            lastName: p.lastName,
            number: number,
            position: position,
            teamId: clubId,
            games: games,
            goals: goals,
            assists: assists,
            points: points,
            penaltyMinutes: penaltyMinutes,
            savePercentage: savePercentage,
            goalsAgainstAverage: goalsAgainstAverage,
            seasonId: competitions?.seasonId,
            seasonLabel: competitions?.seasons?.label,
            competitionId: competitionId
        )
    }

    var asHistory: PlayerSeasonStat? {
        guard let comp = competitions else { return nil }
        return PlayerSeasonStat(
            id: id,
            playerId: playerId,
            clubId: clubId,
            competitionId: competitionId,
            seasonId: comp.seasonId,
            seasonLabel: comp.seasons?.label ?? comp.seasonId,
            competitionName: comp.name,
            number: number,
            position: position,
            games: games,
            goals: goals,
            assists: assists,
            points: points,
            penaltyMinutes: penaltyMinutes,
            savePercentage: savePercentage,
            goalsAgainstAverage: goalsAgainstAverage
        )
    }
}

private struct MatchEventRow: Decodable {
    let id: String
    let kind: MatchEvent.Kind
    let minute: Int
    let second: Int
    let clubId: String
    let playerId: String?
    let assistIds: [String]?
    let description: String
    let period: Int
    let sortOrder: Int?
}

private struct MatchRow: Decodable {
    let id: String
    let competitionId: String
    let homeClubId: String
    let awayClubId: String
    let scheduledAt: Date
    let status: MatchStatus
    let period: MatchPeriod
    let clock: String?
    let phase: CompetitionPhase?
    let homeScore: Int
    let awayScore: Int
    let homePeriodScores: [Int]?
    let awayPeriodScores: [Int]?
    let venue: String
    let round: Int
    let attendance: Int?
    let streamUrl: String?
    let streamLabel: String?
    let homeShots: Int?
    let awayShots: Int?
    let homePpGoals: Int?
    let awayPpGoals: Int?
    let homeShGoals: Int?
    let awayShGoals: Int?
    let referees: String?
    let matchEvents: [MatchEventRow]?

    var asMatch: Match {
        let events = (matchEvents ?? [])
            .sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
            .map {
                MatchEvent(
                    id: $0.id,
                    kind: $0.kind,
                    minute: $0.minute,
                    second: $0.second,
                    teamId: $0.clubId,
                    playerId: $0.playerId,
                    assistIds: $0.assistIds ?? [],
                    description: $0.description,
                    period: $0.period
                )
            }
        return Match(
            id: id,
            competitionId: competitionId,
            homeTeamId: homeClubId,
            awayTeamId: awayClubId,
            scheduledAt: scheduledAt,
            status: status,
            period: period,
            clock: clock,
            phase: phase,
            homeScore: homeScore,
            awayScore: awayScore,
            homePeriodScores: homePeriodScores ?? [],
            awayPeriodScores: awayPeriodScores ?? [],
            venue: venue,
            round: round,
            events: events,
            attendance: attendance,
            streamURL: streamUrl,
            streamLabel: streamLabel,
            homeShots: homeShots,
            awayShots: awayShots,
            homePowerplayGoals: homePpGoals,
            awayPowerplayGoals: awayPpGoals,
            homeShorthandedGoals: homeShGoals,
            awayShorthandedGoals: awayShGoals,
            referees: referees
        )
    }
}

private struct StandingRowDTO: Decodable {
    let id: String
    let rank: Int
    let clubId: String
    let played: Int
    let wins: Int
    let overtimeWins: Int
    let overtimeLosses: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let points: Int

    var asModel: StandingRow {
        StandingRow(
            id: id,
            rank: rank,
            teamId: clubId,
            played: played,
            wins: wins,
            overtimeWins: overtimeWins,
            overtimeLosses: overtimeLosses,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst,
            points: points
        )
    }
}

private struct StandingHistoryRow: Decodable {
    let id: String
    let rank: Int
    let clubId: String
    let played: Int
    let wins: Int
    let overtimeWins: Int
    let overtimeLosses: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let points: Int
    let competitions: CompetitionEmbed?

    var asRecord: ClubSeasonRecord? {
        guard let comp = competitions else { return nil }
        let standing = StandingRow(
            id: id,
            rank: rank,
            teamId: clubId,
            played: played,
            wins: wins,
            overtimeWins: overtimeWins,
            overtimeLosses: overtimeLosses,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst,
            points: points
        )
        return ClubSeasonRecord(
            seasonId: comp.seasonId,
            seasonLabel: comp.seasons?.label ?? comp.seasonId,
            competitionId: comp.id,
            competitionName: comp.name,
            standing: standing
        )
    }
}

private struct NewsRow: Decodable {
    let id: String
    let title: String
    let category: String
    let publishedAt: Date
    let summary: String
    let imageGradientIndex: Int

    var asModel: NewsArticle {
        NewsArticle(
            id: id,
            title: title,
            category: category,
            publishedAt: publishedAt,
            summary: summary,
            imageGradientIndex: imageGradientIndex
        )
    }
}

private extension ISO8601DateFormatter {
    static let full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}

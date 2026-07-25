import Foundation

/// GoTrue + PostgREST volání s uživatelským JWT.
actor SupabaseAuthAPI {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            if let n = try? c.decode(Double.self) {
                return Date(timeIntervalSince1970: n)
            }
            let raw = try c.decode(String.self)
            if let d = ISO8601DateFormatter.full.date(from: raw) { return d }
            if let d = ISO8601DateFormatter.fractional.date(from: raw) { return d }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Bad date \(raw)")
        }
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    // MARK: - Auth

    func signUp(_ payload: AuthSignUpPayload) async throws -> AuthSession {
        struct Body: Encodable {
            let email: String
            let password: String
            let data: [String: String]
        }
        let username = SupabaseAuthAPI.sanitizedUsername(payload.username)
        let body = Body(
            email: payload.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: payload.password,
            data: [
                "first_name": payload.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                "last_name": payload.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                "username": username,
                "favorite_club_id": payload.favoriteClubId,
            ]
        )
        let data = try await postAuth(path: "signup", body: body, token: nil)
        if let session = try? decodeSession(from: data) {
            return session
        }
        // Bez session (např. confirm e-mail) — zkusíme rovnou přihlášení.
        do {
            return try await signIn(email: payload.email, password: payload.password)
        } catch {
            throw AuthError.message(
                "Účet se vytvořil, ale přihlášení se nepovedlo. Zkus se přihlásit znovu. (\(error.localizedDescription))"
            )
        }
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        struct Body: Encodable {
            let email: String
            let password: String
        }
        let data = try await postAuth(
            path: "token",
            query: [URLQueryItem(name: "grant_type", value: "password")],
            body: Body(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password
            ),
            token: nil
        )
        return try decodeSession(from: data)
    }

    func refresh(refreshToken: String) async throws -> AuthSession {
        struct Body: Encodable {
            let refreshToken: String
            enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
        }
        let data = try await postAuth(
            path: "token",
            query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: Body(refreshToken: refreshToken),
            token: nil
        )
        return try decodeSession(from: data)
    }

    func requestPasswordReset(email: String) async throws {
        struct Body: Encodable {
            let email: String
        }
        _ = try await postAuth(
            path: "recover",
            body: Body(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()),
            token: nil
        )
    }

    func signOut(accessToken: String) async throws {
        var request = URLRequest(url: SupabaseConfig.authURL.appendingPathComponent("logout"))
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try await session.data(for: request)
    }

    private func decodeSession(from data: Data) throws -> AuthSession {
        if let session = try? decoder.decode(TokenResponse.self, from: data).asSession() {
            return session
        }
        // Některé odpovědi mají tokeny na top-level i při částečném user objektu.
        if let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let access = raw["access_token"] as? String,
           let refresh = raw["refresh_token"] as? String,
           let user = raw["user"] as? [String: Any],
           let id = user["id"] as? String {
            let email = (user["email"] as? String) ?? ""
            let expiresIn = (raw["expires_in"] as? Double) ?? Double(raw["expires_in"] as? Int ?? 3600)
            return AuthSession(
                accessToken: access,
                refreshToken: refresh,
                expiresAt: Date().addingTimeInterval(expiresIn),
                userId: id,
                email: email
            )
        }
        throw AuthError.invalidResponse
    }

    // MARK: - Profile / favorites / tips / amateur

    func fetchProfile(userId: String, accessToken: String) async throws -> UserProfile {
        let rows: [ProfileRow] = try await get(
            "profiles",
            query: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "id", value: "eq.\(userId)"),
                URLQueryItem(name: "limit", value: "1"),
            ],
            accessToken: accessToken
        )
        guard let row = rows.first else { throw AuthError.message("Profil se nepodařilo načíst.") }
        return row.asModel
    }

    func updateProfile(
        userId: String,
        firstName: String,
        lastName: String,
        username: String,
        favoriteClubId: String?,
        accessToken: String
    ) async throws -> UserProfile {
        struct Body: Encodable {
            let firstName: String
            let lastName: String
            let username: String
            let favoriteClubId: String?
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
                case username
                case favoriteClubId = "favorite_club_id"
                case updatedAt = "updated_at"
            }
        }
        let cleanUsername = Self.sanitizedUsername(username)
        let body = Body(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            username: cleanUsername,
            favoriteClubId: favoriteClubId,
            updatedAt: ISO8601DateFormatter.full.string(from: Date())
        )
        let rows: [ProfileRow] = try await patch(
            "profiles",
            query: [URLQueryItem(name: "id", value: "eq.\(userId)")],
            body: body,
            accessToken: accessToken
        )
        guard let row = rows.first else { throw AuthError.invalidResponse }
        return row.asModel
    }

    /// Vytvoří nebo aktualizuje profil (fallback, když trigger nestihne / selže).
    func upsertProfile(
        userId: String,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        favoriteClubId: String?,
        accessToken: String
    ) async throws -> UserProfile {
        struct Body: Encodable {
            let id: String
            let email: String
            let firstName: String
            let lastName: String
            let username: String
            let favoriteClubId: String?
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case id, email, username
                case firstName = "first_name"
                case lastName = "last_name"
                case favoriteClubId = "favorite_club_id"
                case updatedAt = "updated_at"
            }
        }
        let body = Body(
            id: userId,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            username: Self.sanitizedUsername(username),
            favoriteClubId: favoriteClubId,
            updatedAt: ISO8601DateFormatter.full.string(from: Date())
        )
        let data = try await postREST(
            "profiles",
            body: body,
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=representation"
        )
        if let rows = try? decoder.decode([ProfileRow].self, from: data), let row = rows.first {
            return row.asModel
        }
        return try await fetchProfile(userId: userId, accessToken: accessToken)
    }

    static func sanitizedUsername(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        let cleaned = String(trimmed.unicodeScalars.filter { allowed.contains($0) })
        if cleaned.count >= 3 { return String(cleaned.prefix(32)) }
        return "user\(Int(Date().timeIntervalSince1970) % 1000000)"
    }

    /// Nahraje JPEG do bucketu `avatars/{userId}/avatar.jpg` a uloží public URL do profilu.
    func uploadAvatar(
        userId: String,
        jpegData: Data,
        accessToken: String
    ) async throws -> UserProfile {
        let objectPath = "\(userId)/avatar.jpg"
        guard let uploadURL = URL(
            string: "\(SupabaseConfig.projectURL.absoluteString)/storage/v1/object/avatars/\(objectPath)"
        ) else {
            throw AuthError.invalidResponse
        }
        var upload = URLRequest(url: uploadURL)
        upload.httpMethod = "POST"
        upload.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        upload.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        upload.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        upload.setValue("true", forHTTPHeaderField: "x-upsert")
        upload.httpBody = jpegData
        let (uploadData, uploadResponse) = try await session.data(for: upload)
        try throwIfNeeded(data: uploadData, response: uploadResponse)

        let publicURL =
            "\(SupabaseConfig.projectURL.absoluteString)/storage/v1/object/public/avatars/\(objectPath)?v=\(Int(Date().timeIntervalSince1970))"

        struct Body: Encodable {
            let avatarUrl: String
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case avatarUrl = "avatar_url"
                case updatedAt = "updated_at"
            }
        }
        let rows: [ProfileRow] = try await patch(
            "profiles",
            query: [URLQueryItem(name: "id", value: "eq.\(userId)")],
            body: Body(
                avatarUrl: publicURL,
                updatedAt: ISO8601DateFormatter.full.string(from: Date())
            ),
            accessToken: accessToken
        )
        guard let row = rows.first else { throw AuthError.invalidResponse }
        return row.asModel
    }

    func clearAvatar(userId: String, accessToken: String) async throws -> UserProfile {
        let objectPath = "\(userId)/avatar.jpg"
        if let deleteURL = URL(
            string: "\(SupabaseConfig.projectURL.absoluteString)/storage/v1/object/avatars/\(objectPath)"
        ) {
            var request = URLRequest(url: deleteURL)
            request.httpMethod = "DELETE"
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            _ = try? await session.data(for: request)
        }

        struct Body: Encodable {
            let avatarUrl: String?
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case avatarUrl = "avatar_url"
                case updatedAt = "updated_at"
            }
        }
        let rows: [ProfileRow] = try await patch(
            "profiles",
            query: [URLQueryItem(name: "id", value: "eq.\(userId)")],
            body: Body(
                avatarUrl: nil,
                updatedAt: ISO8601DateFormatter.full.string(from: Date())
            ),
            accessToken: accessToken
        )
        guard let row = rows.first else { throw AuthError.invalidResponse }
        return row.asModel
    }

    func fetchFavorites(accessToken: String) async throws -> [FavoriteRow] {
        try await get(
            "user_favorites",
            query: [
                URLQueryItem(name: "select", value: "kind,target_id"),
                URLQueryItem(name: "order", value: "created_at.asc"),
            ],
            accessToken: accessToken
        )
    }

    func upsertFavorite(kind: String, targetId: String, userId: String, accessToken: String) async throws {
        struct Body: Encodable {
            let userId: String
            let kind: String
            let targetId: String
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case kind
                case targetId = "target_id"
            }
        }
        _ = try await postREST(
            "user_favorites",
            body: Body(userId: userId, kind: kind, targetId: targetId),
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    func deleteFavorite(kind: String, targetId: String, accessToken: String) async throws {
        try await delete(
            "user_favorites",
            query: [
                URLQueryItem(name: "kind", value: "eq.\(kind)"),
                URLQueryItem(name: "target_id", value: "eq.\(targetId)"),
            ],
            accessToken: accessToken
        )
    }

    func fetchTipVotes(matchId: String) async throws -> (home: Int, away: Int) {
        struct Row: Decodable { let pick: String }
        let rows: [Row] = try await get(
            "match_tips",
            query: [
                URLQueryItem(name: "select", value: "pick"),
                URLQueryItem(name: "match_id", value: "eq.\(matchId)"),
            ],
            accessToken: nil
        )
        let home = rows.filter { $0.pick == "home" }.count
        let away = rows.filter { $0.pick == "away" }.count
        return (home, away)
    }

    func fetchMyTips(userId: String, accessToken: String) async throws -> [TipRow] {
        try await get(
            "match_tips",
            query: [
                URLQueryItem(name: "select", value: "match_id,pick,created_at"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            ],
            accessToken: accessToken
        )
    }

    func upsertTip(userId: String, matchId: String, pick: String, accessToken: String) async throws {
        struct Body: Encodable {
            let userId: String
            let matchId: String
            let pick: String
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case matchId = "match_id"
                case pick
                case updatedAt = "updated_at"
            }
        }
        _ = try await postREST(
            "match_tips",
            body: Body(
                userId: userId,
                matchId: matchId,
                pick: pick,
                updatedAt: ISO8601DateFormatter.full.string(from: Date())
            ),
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    func fetchAmateurTournaments(accessToken: String?) async throws -> [AmateurRemoteRow] {
        try await get(
            "amateur_tournaments",
            query: [
                URLQueryItem(name: "select", value: "id,owner_id,name,status,payload,updated_at"),
                URLQueryItem(name: "order", value: "updated_at.desc"),
            ],
            accessToken: accessToken
        )
    }

    func upsertAmateurTournament(
        id: String,
        ownerId: String,
        name: String,
        status: String,
        payload: Data,
        accessToken: String
    ) async throws {
        struct Body: Encodable {
            let id: String
            let ownerId: String
            let name: String
            let status: String
            let payload: AnyJSON
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case id
                case ownerId = "owner_id"
                case name, status, payload
                case updatedAt = "updated_at"
            }
        }
        let json = try JSONSerialization.jsonObject(with: payload)
        _ = try await postREST(
            "amateur_tournaments",
            body: Body(
                id: id,
                ownerId: ownerId,
                name: name,
                status: status,
                payload: AnyJSON(json),
                updatedAt: ISO8601DateFormatter.full.string(from: Date())
            ),
            accessToken: accessToken,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    func deleteAmateurTournament(id: String, accessToken: String) async throws {
        try await delete(
            "amateur_tournaments",
            query: [URLQueryItem(name: "id", value: "eq.\(id)")],
            accessToken: accessToken
        )
    }

    // MARK: - HTTP

    private func postAuth<Body: Encodable>(
        path: String,
        query: [URLQueryItem] = [],
        body: Body,
        token: String?
    ) async throws -> Data {
        var components = URLComponents(
            url: SupabaseConfig.authURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token ?? SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try throwIfNeeded(data: data, response: response)
        return data
    }

    private func get<T: Decodable>(
        _ table: String,
        query: [URLQueryItem],
        accessToken: String?
    ) async throws -> T {
        var components = URLComponents(url: SupabaseConfig.restURL.appendingPathComponent(table), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try throwIfNeeded(data: data, response: response)
        return try decoder.decode(T.self, from: data)
    }

    private func postREST<Body: Encodable>(
        _ table: String,
        body: Body,
        accessToken: String,
        prefer: String
    ) async throws -> Data {
        var request = URLRequest(url: SupabaseConfig.restURL.appendingPathComponent(table))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try throwIfNeeded(data: data, response: response)
        return data
    }

    private func patch<T: Decodable, Body: Encodable>(
        _ table: String,
        query: [URLQueryItem],
        body: Body,
        accessToken: String
    ) async throws -> T {
        var components = URLComponents(url: SupabaseConfig.restURL.appendingPathComponent(table), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try throwIfNeeded(data: data, response: response)
        return try decoder.decode(T.self, from: data)
    }

    private func delete(_ table: String, query: [URLQueryItem], accessToken: String) async throws {
        var components = URLComponents(url: SupabaseConfig.restURL.appendingPathComponent(table), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try throwIfNeeded(data: data, response: response)
    }

    private func throwIfNeeded(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            if let err = try? decoder.decode(GoTrueError.self, from: data),
               let message = err.resolved {
                throw AuthError.message(friendlyAuthMessage(message))
            }
            if let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let message = (raw["msg"] as? String)
                    ?? (raw["error_description"] as? String)
                    ?? (raw["message"] as? String)
                    ?? (raw["error"] as? String)
                if let message {
                    throw AuthError.message(friendlyAuthMessage(message))
                }
            }
            let text = String(data: data, encoding: .utf8) ?? "Chyba \(http.statusCode)"
            throw AuthError.message(friendlyAuthMessage(text))
        }
    }

    private func friendlyAuthMessage(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("already registered") || lower.contains("user already") {
            return "Účet s tímto e-mailem už existuje."
        }
        if lower.contains("password") && (lower.contains("weak") || lower.contains("least") || lower.contains("short")) {
            return "Heslo je příliš krátké (min. 6 znaků)."
        }
        if lower.contains("invalid login") || lower.contains("invalid credentials") {
            return "Neplatný e-mail nebo heslo."
        }
        if lower.contains("email") && lower.contains("invalid") {
            return "Zadej platný e-mail."
        }
        if lower.contains("username") || lower.contains("profiles_username") {
            return "Toto uživatelské jméno nelze použít (je obsazené nebo neplatné)."
        }
        if lower.contains("duplicate") || lower.contains("unique") {
            return "Účet nebo uživatelské jméno už existuje."
        }
        return raw
    }
}

// MARK: - DTOs

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: FlexibleNumber?
    let expiresAt: FlexibleNumber?
    let user: AuthUser?

    func asSession() throws -> AuthSession {
        guard let user else { throw AuthError.invalidResponse }
        let exp: Date
        if let expiresAt = expiresAt?.doubleValue {
            exp = Date(timeIntervalSince1970: expiresAt)
        } else if let expiresIn = expiresIn?.doubleValue {
            exp = Date().addingTimeInterval(expiresIn)
        } else {
            exp = Date().addingTimeInterval(3600)
        }
        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: exp,
            userId: user.id,
            email: user.email ?? ""
        )
    }
}

private struct FlexibleNumber: Decodable {
    let doubleValue: Double

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) {
            doubleValue = d
        } else if let i = try? c.decode(Int.self) {
            doubleValue = Double(i)
        } else if let s = try? c.decode(String.self), let d = Double(s) {
            doubleValue = d
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Not a number")
        }
    }
}

private struct AuthUser: Decodable {
    let id: String
    let email: String?
}

private struct GoTrueError: Decodable {
    let message: String?
    let errorDescription: String?
    let msg: String?
    var resolved: String? { message ?? errorDescription ?? msg }
}

struct ProfileRow: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let favoriteClubId: String?
    let avatarUrl: String?

    var asModel: UserProfile {
        UserProfile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: email,
            favoriteClubId: favoriteClubId,
            avatarURL: avatarUrl
        )
    }
}

struct FavoriteRow: Decodable {
    let kind: String
    let targetId: String
}

struct TipRow: Decodable {
    let matchId: String
    let pick: String
    let createdAt: Date?
}

struct AmateurRemoteRow: Decodable {
    let id: String
    let ownerId: String
    let name: String
    let status: String
    let payload: AnyJSON
    let updatedAt: Date?
}

struct AnyJSON: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = NSNull(); return }
        if let b = try? c.decode(Bool.self) { value = b; return }
        if let i = try? c.decode(Int.self) { value = i; return }
        if let d = try? c.decode(Double.self) { value = d; return }
        if let s = try? c.decode(String.self) { value = s; return }
        if let arr = try? c.decode([AnyJSON].self) { value = arr.map(\.value); return }
        if let dict = try? c.decode([String: AnyJSON].self) {
            value = dict.mapValues(\.value)
            return
        }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case is NSNull: try c.encodeNil()
        case let b as Bool: try c.encode(b)
        case let i as Int: try c.encode(i)
        case let d as Double: try c.encode(d)
        case let s as String: try c.encode(s)
        case let arr as [Any]: try c.encode(arr.map(AnyJSON.init))
        case let dict as [String: Any]: try c.encode(dict.mapValues(AnyJSON.init))
        default:
            throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported"))
        }
    }

    var data: Data? {
        try? JSONSerialization.data(withJSONObject: value)
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
}

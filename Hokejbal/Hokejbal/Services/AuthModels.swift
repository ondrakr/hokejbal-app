import Foundation

extension SupabaseConfig {
    static var authURL: URL { projectURL.appendingPathComponent("auth/v1") }
}

struct AuthSession: Codable, Hashable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userId: String
    var email: String

    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60)
    }
}

struct UserProfile: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var favoriteClubId: String?
    var avatarURL: String?

    var displayName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? username : full
    }

    var initials: String {
        let f = firstName.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? ""
        let l = lastName.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? ""
        let pair = (f + l).uppercased()
        if !pair.isEmpty { return pair }
        let fromUser = username.trimmingCharacters(in: .whitespaces)
        if fromUser.count >= 2 { return String(fromUser.prefix(2)).uppercased() }
        return "?"
    }
}

enum AuthError: LocalizedError {
    case message(String)
    case notAuthenticated
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        case .notAuthenticated: return "Nejsi přihlášený."
        case .invalidResponse: return "Neočekávaná odpověď ze serveru."
        }
    }
}

struct AuthSignUpPayload: Sendable {
    var firstName: String
    var lastName: String
    var email: String
    var username: String
    var password: String
    var favoriteClubId: String
}

enum AuthRoute: Hashable {
    case login
    case register
    case forgotPassword
}

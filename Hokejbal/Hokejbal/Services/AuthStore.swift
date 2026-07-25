import Foundation
import SwiftUI

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: AuthSession?
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isBootstrapping = true
    @Published var showAuthSheet = false
    @Published var authRoute: AuthRoute = .login
    @Published var lastError: String?

    private let api = SupabaseAuthAPI()
    private let defaults = UserDefaults.standard
    private let sessionKey = "hb.auth.session.v1"

    var isAuthenticated: Bool { session != nil }
    var userId: String? { session?.userId }
    var accessToken: String? { session?.accessToken }

    init() {
        if let data = defaults.data(forKey: sessionKey),
           let stored = try? JSONDecoder().decode(AuthSession.self, from: data) {
            session = stored
        }
    }

    func bootstrap() async {
        defer { isBootstrapping = false }
        guard var current = session else { return }
        do {
            if current.isExpired {
                current = try await api.refresh(refreshToken: current.refreshToken)
                apply(session: current)
            }
            profile = try await api.fetchProfile(userId: current.userId, accessToken: current.accessToken)
        } catch {
            clearSession()
        }
    }

    func presentLogin() {
        authRoute = .login
        showAuthSheet = true
    }

    func presentRegister() {
        authRoute = .register
        showAuthSheet = true
    }

    func presentForgotPassword() {
        authRoute = .forgotPassword
        showAuthSheet = true
    }

    func dismissAuth() {
        showAuthSheet = false
    }

    func requireAuth() -> Bool {
        if isAuthenticated { return true }
        presentLogin()
        return false
    }

    func signIn(email: String, password: String) async throws {
        lastError = nil
        let session = try await api.signIn(email: email, password: password)
        apply(session: session)
        profile = try await api.fetchProfile(userId: session.userId, accessToken: session.accessToken)
        showAuthSheet = false
    }

    func signUp(_ payload: AuthSignUpPayload) async throws {
        lastError = nil
        let clean = AuthSignUpPayload(
            firstName: payload.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: payload.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: payload.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            username: SupabaseAuthAPI.sanitizedUsername(payload.username),
            password: payload.password,
            favoriteClubId: payload.favoriteClubId
        )
        let session = try await api.signUp(clean)
        apply(session: session)

        var loaded: UserProfile?
        for _ in 0..<6 {
            if let p = try? await api.fetchProfile(userId: session.userId, accessToken: session.accessToken) {
                loaded = p
                break
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        if loaded == nil {
            loaded = try await api.upsertProfile(
                userId: session.userId,
                email: session.email.isEmpty ? clean.email : session.email,
                firstName: clean.firstName,
                lastName: clean.lastName,
                username: clean.username,
                favoriteClubId: clean.favoriteClubId,
                accessToken: session.accessToken
            )
        }
        profile = loaded
        showAuthSheet = false
    }

    func requestPasswordReset(email: String) async throws {
        lastError = nil
        try await api.requestPasswordReset(email: email)
    }

    func signOut() async {
        if let token = session?.accessToken {
            try? await api.signOut(accessToken: token)
        }
        clearSession()
    }

    func updateProfile(firstName: String, lastName: String, username: String, favoriteClubId: String?) async throws {
        guard let session else { throw AuthError.notAuthenticated }
        profile = try await api.updateProfile(
            userId: session.userId,
            firstName: firstName,
            lastName: lastName,
            username: username,
            favoriteClubId: favoriteClubId,
            accessToken: session.accessToken
        )
    }

    func uploadAvatar(jpegData: Data) async throws {
        guard let session else { throw AuthError.notAuthenticated }
        let token = try await validAccessToken()
        profile = try await api.uploadAvatar(
            userId: session.userId,
            jpegData: jpegData,
            accessToken: token
        )
    }

    func clearAvatar() async throws {
        guard let session else { throw AuthError.notAuthenticated }
        let token = try await validAccessToken()
        profile = try await api.clearAvatar(userId: session.userId, accessToken: token)
    }

    func validAccessToken() async throws -> String {
        guard var current = session else { throw AuthError.notAuthenticated }
        if current.isExpired {
            current = try await api.refresh(refreshToken: current.refreshToken)
            apply(session: current)
        }
        return current.accessToken
    }

    var authAPI: SupabaseAuthAPI { api }

    private func apply(session: AuthSession) {
        self.session = session
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: sessionKey)
        }
    }

    private func clearSession() {
        session = nil
        profile = nil
        defaults.removeObject(forKey: sessionKey)
    }
}

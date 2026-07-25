import SwiftUI

// MARK: - Shared auth field chrome

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var autocap: TextInputAutocapitalization = .never
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.hbMontserrat(size: 12, weight: .semibold))
                .foregroundStyle(HBTheme.textSecondary)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                        .textContentType(contentType ?? .password)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocap)
                        .autocorrectionDisabled()
                        .textContentType(contentType)
                }
            }
            .font(.hbMontserrat(size: 16, weight: .medium))
            .foregroundStyle(HBTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(HBTheme.cardStroke, lineWidth: 1)
            )
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    var busy = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if busy {
                    ProgressView()
                        .tint(HBTheme.onBrand)
                }
                Text(title)
                    .font(.hbMontserrat(size: 15, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(HBTheme.onBrand)
            .background(HBTheme.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!enabled || busy)
        .opacity(!enabled || busy ? 0.55 : 1)
    }
}

struct AuthBrandHeader: View {
    var title: String

    var body: some View {
        VStack(spacing: 14) {
            BrandLogoImage(size: 72)
            Text(title)
                .font(.hbMontserrat(size: 24, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Flow host (full-screen)

struct AuthFlowView: View {
    @ObservedObject var auth: AuthStore
    @EnvironmentObject private var catalog: CatalogStore

    var body: some View {
        NavigationStack {
            Group {
                switch auth.authRoute {
                case .login:
                    LoginView()
                case .register:
                    RegisterView()
                case .forgotPassword:
                    ForgotPasswordView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        auth.dismissAuth()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                    .accessibilityLabel("Zavřít")
                }
            }
        }
        .environmentObject(auth)
        .environmentObject(catalog)
    }
}

/// Zámek funkce pro nepřihlášené.
struct AuthLockView: View {
    @EnvironmentObject private var auth: AuthStore
    var title: String
    var message: String
    var systemImage: String = "person.crop.circle.badge.lock"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(HBTheme.brand)
            Text(title)
                .font(.hbMontserrat(size: 20, weight: .bold))
                .foregroundStyle(HBTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.hbMontserrat(size: 14, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            HStack(spacing: 10) {
                Button("Přihlásit se") { auth.presentLogin() }
                    .buttonStyle(HBPrimaryButtonStyle())
                Button("Registrace") { auth.presentRegister() }
                    .buttonStyle(HBSecondaryButtonStyle())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(HBTheme.canvas)
    }
}

struct HBPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hbMontserrat(size: 14, weight: .bold))
            .foregroundStyle(HBTheme.onBrand)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(HBTheme.brand, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct HBSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hbMontserrat(size: 14, weight: .bold))
            .foregroundStyle(HBTheme.brand)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(HBTheme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(HBTheme.cardStroke, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Avatar přihlášeného uživatele — fotka nebo iniciály.
struct UserAvatarView: View {
    let profile: UserProfile?
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let urlString = profile?.avatarURL, let url = URL(string: urlString) {
                HBCachedAsyncImage(url: url) { img in
                    img
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        }
        .accessibilityLabel(profile?.displayName ?? "Profil")
    }

    private var initialsView: some View {
        ZStack {
            HBTheme.brand.opacity(0.14)
            Text(profile?.initials ?? "?")
                .font(.hbMontserrat(size: size * 0.36, weight: .bold))
                .foregroundStyle(HBTheme.brand)
        }
    }
}

/// Navigace na profil / auth podle stavu.
struct ProfileEntryLink: View {
    @EnvironmentObject private var auth: AuthStore

    var body: some View {
        Group {
            if auth.isAuthenticated {
                NavigationLink {
                    ProfileView()
                } label: {
                    UserAvatarView(profile: auth.profile, size: 28)
                }
                .accessibilityLabel("Profil")
            } else {
                Button {
                    auth.presentLogin()
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(HBTheme.textPrimary)
                }
                .accessibilityLabel("Přihlásit se")
            }
        }
    }
}

struct AuthSheetHost: ViewModifier {
    @ObservedObject var auth: AuthStore
    @ObservedObject var catalog: CatalogStore

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $auth.showAuthSheet) {
                AuthFlowView(auth: auth)
                    .environmentObject(catalog)
            }
    }
}

extension View {
    /// Full-screen auth — katalog předáváme explicitně (sheet/cover environment).
    func hbAuthSheet(_ auth: AuthStore, catalog: CatalogStore) -> some View {
        modifier(AuthSheetHost(auth: auth, catalog: catalog))
    }
}

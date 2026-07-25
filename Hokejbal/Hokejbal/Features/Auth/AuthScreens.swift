import SwiftUI
import PhotosUI
import UIKit

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error: String?
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AuthBrandHeader(title: "Přihlášení")

                AuthTextField(
                    title: "E-mail",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .username
                )
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit { focused = .password }

                AuthTextField(
                    title: "Heslo",
                    text: $password,
                    contentType: .password,
                    isSecure: true
                )
                .focused($focused, equals: .password)
                .submitLabel(.go)
                .onSubmit { Task { await submit() } }

                HStack {
                    Spacer()
                    Button("Zapomenuté heslo?") {
                        auth.authRoute = .forgotPassword
                    }
                    .font(.hbMontserrat(size: 13, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
                }
                .padding(.top, -6)

                if let error {
                    Text(error)
                        .font(.hbMontserrat(size: 13, weight: .semibold))
                        .foregroundStyle(HBTheme.loss)
                }

                AuthPrimaryButton(
                    title: "Přihlásit se",
                    busy: busy,
                    enabled: canSubmit
                ) {
                    Task { await submit() }
                }

                Button {
                    auth.authRoute = .register
                } label: {
                    Text("Nemáš účet? Registrace")
                        .font(.hbMontserrat(size: 14, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HBTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .onAppear { focused = .email }
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    private func submit() async {
        guard canSubmit, !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Forgot password

struct ForgotPasswordView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var email = ""
    @State private var busy = false
    @State private var error: String?
    @State private var sent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AuthBrandHeader(title: "Obnovení hesla")

                if sent {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Zkontroluj e-mail")
                            .font(.hbMontserrat(size: 17, weight: .bold))
                        Text("Pokud účet existuje, poslali jsme odkaz pro nastavení nového hesla.")
                            .font(.hbMontserrat(size: 14, weight: .medium))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(HBTheme.cardStroke, lineWidth: 1)
                    )
                } else {
                    AuthTextField(
                        title: "E-mail",
                        text: $email,
                        keyboard: .emailAddress,
                        contentType: .emailAddress
                    )

                    if let error {
                        Text(error)
                            .font(.hbMontserrat(size: 13, weight: .semibold))
                            .foregroundStyle(HBTheme.loss)
                    }

                    AuthPrimaryButton(
                        title: "Odeslat odkaz",
                        busy: busy,
                        enabled: email.contains("@")
                    ) {
                        Task { await submit() }
                    }
                }

                Button {
                    auth.authRoute = .login
                } label: {
                    Text("Zpět na přihlášení")
                        .font(.hbMontserrat(size: 14, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HBTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
    }

    private func submit() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await auth.requestPasswordReset(email: email)
            sent = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Register

struct RegisterView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var catalog: CatalogStore

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var favoriteClubId = ""
    @State private var showClubPicker = false
    @State private var busy = false
    @State private var error: String?

    private var selectedClub: Team? {
        guard !favoriteClubId.isEmpty else { return nil }
        return catalog.teamsById[favoriteClubId]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AuthBrandHeader(title: "Registrace")

                HStack(spacing: 12) {
                    AuthTextField(title: "Jméno", text: $firstName, autocap: .words)
                    AuthTextField(title: "Příjmení", text: $lastName, autocap: .words)
                }

                AuthTextField(
                    title: "E-mail",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .emailAddress
                )

                AuthTextField(
                    title: "Uživatelské jméno",
                    text: $username,
                    contentType: .username
                )

                AuthTextField(
                    title: "Heslo",
                    text: $password,
                    contentType: .newPassword,
                    isSecure: true
                )

                clubPickerButton

                if let error {
                    Text(error)
                        .font(.hbMontserrat(size: 13, weight: .semibold))
                        .foregroundStyle(HBTheme.loss)
                }

                AuthPrimaryButton(
                    title: "Vytvořit účet",
                    busy: busy,
                    enabled: canSubmit
                ) {
                    Task { await submit() }
                }

                Button {
                    auth.authRoute = .login
                } label: {
                    Text("Už máš účet? Přihlásit se")
                        .font(.hbMontserrat(size: 14, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(HBTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .sheet(isPresented: $showClubPicker) {
            ClubPickerView(selectedClubId: $favoriteClubId)
                .environmentObject(catalog)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var clubPickerButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Oblíbený klub")
                .font(.hbMontserrat(size: 12, weight: .semibold))
                .foregroundStyle(HBTheme.textSecondary)

            Button {
                showClubPicker = true
            } label: {
                HStack(spacing: 12) {
                    if let club = selectedClub {
                        TeamBadge(team: club, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(club.name)
                                .font(.hbMontserrat(size: 15, weight: .semibold))
                                .foregroundStyle(HBTheme.textPrimary)
                                .lineLimit(1)
                            if !club.city.isEmpty {
                                Text(club.city)
                                    .font(.hbMontserrat(size: 12, weight: .medium))
                                    .foregroundStyle(HBTheme.textSecondary)
                            }
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(HBTheme.cardInset)
                                .frame(width: 36, height: 36)
                            Image(systemName: "shield")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(HBTheme.textTertiary)
                        }
                        Text("Vybrat klub")
                            .font(.hbMontserrat(size: 15, weight: .semibold))
                            .foregroundStyle(HBTheme.textSecondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HBTheme.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            favoriteClubId.isEmpty ? HBTheme.cardStroke : HBTheme.brand.opacity(0.45),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
            && username.trimmingCharacters(in: .whitespaces).count >= 3
            && password.count >= 6
            && !favoriteClubId.isEmpty
    }

    private func submit() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await auth.signUp(
                AuthSignUpPayload(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    username: username,
                    password: password,
                    favoriteClubId: favoriteClubId
                )
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Club picker

struct ClubPickerView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedClubId: String
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var clubs: [Team] {
        catalog.teamsById.values
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var filtered: [Team] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return clubs }
        return clubs.filter {
            $0.name.localizedCaseInsensitiveContains(q)
                || $0.shortName.localizedCaseInsensitiveContains(q)
                || $0.city.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, HBTheme.screenPadding)
                    .padding(.vertical, 10)
                    .background(HBTheme.surface)

                Rectangle()
                    .fill(HBTheme.separator)
                    .frame(height: 0.5)

                if clubs.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Načítám kluby…")
                            .font(.hbMontserrat(size: 14, weight: .medium))
                            .foregroundStyle(HBTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(HBTheme.canvas)
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .background(HBTheme.canvas)
                } else {
                    List {
                        ForEach(filtered) { club in
                            Button {
                                selectedClubId = club.id
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    TeamBadge(team: club, size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(club.name)
                                            .font(.hbMontserrat(size: 15, weight: .semibold))
                                            .foregroundStyle(HBTheme.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        if !club.city.isEmpty {
                                            Text(club.city)
                                                .font(.hbMontserrat(size: 12, weight: .medium))
                                                .foregroundStyle(HBTheme.textSecondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    if selectedClubId == club.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(HBTheme.brand)
                                            .font(.system(size: 20, weight: .semibold))
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(HBTheme.card)
                            .listRowSeparatorTint(HBTheme.separator.opacity(0.5))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(HBTheme.canvas)
                }
            }
            .background(HBTheme.canvas)
            .navigationTitle("Vybrat klub")
            .navigationBarTitleDisplayMode(.inline)
            .hbNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
            .onAppear { searchFocused = true }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(HBTheme.textTertiary)

            TextField("Hledat klub…", text: $query)
                .font(.hbMontserrat(size: 15, weight: .medium))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HBTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Profile

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var tabRouter: AppTabRouter

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var favoriteClubId = ""
    @State private var showClubPicker = false
    @State private var message: String?
    @State private var busy = false
    @State private var avatarBusy = false
    @State private var photoItem: PhotosPickerItem?

    private var selectedClub: Team? {
        guard !favoriteClubId.isEmpty else { return nil }
        return catalog.teamsById[favoriteClubId]
    }

    var body: some View {
        List {
            Section {
                avatarSection
            }

            Section {
                LabeledContent("E-mail") {
                    Text(auth.profile?.email ?? auth.session?.email ?? "—")
                        .foregroundStyle(HBTheme.textSecondary)
                }
                TextField("Jméno", text: $firstName)
                TextField("Příjmení", text: $lastName)
                TextField("Uživatelské jméno", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    showClubPicker = true
                } label: {
                    HStack {
                        Text("Oblíbený klub")
                            .foregroundStyle(HBTheme.textPrimary)
                        Spacer()
                        if let club = selectedClub {
                            TeamBadge(team: club, size: 22)
                            Text(club.shortName)
                                .foregroundStyle(HBTheme.textSecondary)
                        } else {
                            Text("Vybrat")
                                .foregroundStyle(HBTheme.textTertiary)
                        }
                    }
                }
            } header: {
                Text("Účet")
            }

            Section {
                Button {
                    tabRouter.select(.favorites)
                } label: {
                    Label("Spravovat oblíbené", systemImage: "star.fill")
                }
                LabeledContent("Týmy", value: "\(favorites.teamIDs.count)")
                LabeledContent("Hráči", value: "\(favorites.playerIDs.count)")
                LabeledContent("Soutěže", value: "\(favorites.competitionSlugs.count)")
            } header: {
                Text("Oblíbené")
            }

            if let message {
                Section {
                    Text(message)
                        .font(.hbMontserrat(size: 13, weight: .medium))
                        .foregroundStyle(HBTheme.brand)
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if busy {
                        ProgressView()
                    } else {
                        Text("Uložit změny")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(busy || avatarBusy)

                Button("Odhlásit se", role: .destructive) {
                    Task { await auth.signOut() }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(HBTheme.canvas)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .hbNavigationStyle()
        .onAppear { load() }
        .onChange(of: auth.profile) { _, _ in load() }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await handlePhoto(item) }
        }
        .sheet(isPresented: $showClubPicker) {
            ClubPickerView(selectedClubId: $favoriteClubId)
                .environmentObject(catalog)
        }
    }

    private var avatarSection: some View {
        HStack(spacing: 16) {
            ZStack {
                UserAvatarView(profile: auth.profile, size: 72)
                if avatarBusy {
                    Circle()
                        .fill(.black.opacity(0.35))
                        .frame(width: 72, height: 72)
                    ProgressView()
                        .tint(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                let hasAvatar = auth.profile?.avatarURL != nil
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Text(hasAvatar ? "Změnit fotku" : "Nahrát fotku")
                        .font(.hbMontserrat(size: 14, weight: .semibold))
                        .foregroundStyle(HBTheme.brand)
                }
                .disabled(avatarBusy)

                if hasAvatar {
                    Button("Odstranit fotku", role: .destructive) {
                        Task { await removeAvatar() }
                    }
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .disabled(avatarBusy)
                }

                Text("Bez fotky se zobrazí iniciály.")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func load() {
        firstName = auth.profile?.firstName ?? ""
        lastName = auth.profile?.lastName ?? ""
        username = auth.profile?.username ?? ""
        favoriteClubId = auth.profile?.favoriteClubId ?? ""
    }

    private func save() async {
        busy = true
        message = nil
        defer { busy = false }
        do {
            let club = favoriteClubId.isEmpty ? nil : favoriteClubId
            try await auth.updateProfile(
                firstName: firstName,
                lastName: lastName,
                username: username,
                favoriteClubId: club
            )
            if let club {
                favorites.addTeam(club)
            }
            message = "Uloženo."
        } catch {
            message = error.localizedDescription
        }
    }

    private func handlePhoto(_ item: PhotosPickerItem) async {
        avatarBusy = true
        message = nil
        defer {
            avatarBusy = false
            photoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = image.hbAvatarJPEGData()
            else {
                message = "Fotku se nepodařilo načíst."
                return
            }
            try await auth.uploadAvatar(jpegData: jpeg)
            message = "Profilovka uložena."
        } catch {
            message = error.localizedDescription
        }
    }

    private func removeAvatar() async {
        avatarBusy = true
        message = nil
        defer { avatarBusy = false }
        do {
            try await auth.clearAvatar()
            message = "Profilovka odstraněna."
        } catch {
            message = error.localizedDescription
        }
    }
}

private extension UIImage {
    /// Zmenší a zkomprimuje avatar pro upload (max ~768 px, JPEG).
    func hbAvatarJPEGData(maxDimension: CGFloat = 768, quality: CGFloat = 0.84) -> Data? {
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}

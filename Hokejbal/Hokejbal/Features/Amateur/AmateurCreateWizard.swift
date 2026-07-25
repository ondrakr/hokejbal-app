import SwiftUI
import UIKit

/// Průvodce vytvořením amatérského turnaje — 3 kroky, HB design.
/// TextFieldy drží lokální stav, aby psaní nepřekreslovalo celý sheet.
struct AmateurCreateTournamentSheet: View {
    @EnvironmentObject private var store: AmateurTournamentStore
    @Environment(\.dismiss) private var dismiss

    private enum Step: Int, CaseIterable {
        case info, teams, setup

        var title: String {
            switch self {
            case .info: return "Základ"
            case .teams: return "Týmy"
            case .setup: return "Formát"
            }
        }

        var subtitle: String {
            switch self {
            case .info: return "Jak se turnaj jmenuje a kde se hraje"
            case .teams: return "Přidej aspoň 2 týmy"
            case .setup: return "Herní systém a délka zápasu"
            }
        }
    }

    struct DraftTeam: Identifiable, Hashable {
        let id: String
        var name: String
        var shortName: String
        var colorHex: String

        init(name: String, shortName: String, colorHex: String) {
            self.id = UUID().uuidString
            self.name = name
            self.shortName = shortName
            self.colorHex = colorHex
        }
    }

    @State private var step: Step = .info
    @State private var name = ""
    @State private var location = ""
    @State private var start = Date()
    @State private var draftTeams: [DraftTeam] = []
    @State private var format: AmateurTournamentFormat = .roundRobinAndPlayoff
    @State private var homeAndAway = false
    @State private var playoffTeamCount = 4
    @State private var seriesLength = 3
    @State private var periodCount = 3
    @State private var periodLength = 15
    @State private var overtimeEnabled = true

    /// Jen bool — ne string — aby se parent nepřekresloval při každém znaku.
    @State private var infoValid = false
    @State private var infoDraft = AmateurWizardInfoDraft()
    @State private var teamsValid = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progress
                stepHost
            }
            .background(HBTheme.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AmateurWizardBottomBar(
                    showBack: step != .info,
                    primaryTitle: step == .setup ? "Vytvořit turnaj" : "Pokračovat",
                    canAdvance: canAdvance,
                    onBack: {
                        resignKeyboard()
                        if let prev = Step(rawValue: step.rawValue - 1) { step = prev }
                    },
                    onAdvance: {
                        resignKeyboard()
                        advance()
                    }
                )
                .equatable()
            }
        }
    }

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? HBTheme.brand : HBTheme.separator)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var stepHost: some View {
        switch step {
        case .info:
            AmateurWizardStepScaffold(title: Step.info.title, subtitle: Step.info.subtitle) {
                AmateurWizardInfoCard(draft: infoDraft, isValid: $infoValid)
            }
            .id(Step.info)
        case .teams:
            AmateurWizardStepScaffold(title: Step.teams.title, subtitle: Step.teams.subtitle) {
                AmateurWizardTeamsCard(
                    draftTeams: $draftTeams,
                    isValid: $teamsValid
                )
            }
            .id(Step.teams)
        case .setup:
            AmateurWizardStepScaffold(title: Step.setup.title, subtitle: Step.setup.subtitle) {
                AmateurWizardSetupCard(
                    format: $format,
                    homeAndAway: $homeAndAway,
                    playoffTeamCount: $playoffTeamCount,
                    seriesLength: $seriesLength,
                    periodCount: $periodCount,
                    periodLength: $periodLength,
                    overtimeEnabled: $overtimeEnabled
                )
            }
            .id(Step.setup)
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .info: return infoValid
        case .teams: return teamsValid
        case .setup: return teamsValid || draftTeams.count >= 2
        }
    }

    private func advance() {
        guard canAdvance else { return }
        switch step {
        case .info:
            name = infoDraft.name
            location = infoDraft.location
            start = infoDraft.start
            step = .teams
        case .teams:
            step = .setup
        case .setup:
            finish()
        }
    }

    private func finish() {
        let matchFormat = AmateurMatchFormat(
            periodCount: periodCount,
            periodLengthMinutes: periodLength,
            overtimeEnabled: overtimeEnabled
        )
        let tournament = store.createTournament(
            name: name.isEmpty ? infoDraft.name : name,
            location: location.isEmpty ? infoDraft.location : location,
            start: start,
            end: start,
            notes: "",
            format: format,
            matchFormat: matchFormat,
            homeAndAway: homeAndAway,
            playoffTeamCount: playoffTeamCount,
            seriesLength: format.usesSeries ? seriesLength : 1
        )
        for team in draftTeams {
            _ = store.addTeam(
                tournamentId: tournament.id,
                name: team.name,
                shortName: team.shortName,
                city: "",
                colorHex: team.colorHex
            )
        }
        _ = store.generateSchedule(tournamentId: tournament.id, replaceExisting: true)
        dismiss()
    }

    private func resignKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Shared chrome

/// Reference type — zápis při psaní nespouští SwiftUI invalidaci rodiče.
private final class AmateurWizardInfoDraft {
    var name = ""
    var location = ""
    var start = Date()
}

private struct AmateurWizardStepScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(.hbDisplay(size: 26, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                Text(subtitle)
                    .font(.hbMontserrat(size: 14, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
                content
            }
            .padding(HBTheme.screenPadding)
            .padding(.bottom, 100)
        }
        // `.never` — interactive dismiss při každém scrollu zabíjí fokus TextFieldu.
        .scrollDismissesKeyboard(.never)
    }
}

private struct AmateurWizardBottomBar: View, Equatable {
    let showBack: Bool
    let primaryTitle: String
    let canAdvance: Bool
    let onBack: () -> Void
    let onAdvance: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.showBack == rhs.showBack
            && lhs.primaryTitle == rhs.primaryTitle
            && lhs.canAdvance == rhs.canAdvance
    }

    var body: some View {
        HStack(spacing: 10) {
            if showBack {
                Button(action: onBack) {
                    Text("Zpět")
                        .font(.hbMontserrat(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HBTheme.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(HBTheme.cardStroke, lineWidth: 0.75))
                }
                .buttonStyle(.plain)
            }

            Button(action: onAdvance) {
                Text(primaryTitle)
                    .font(.hbMontserrat(size: 15, weight: .bold))
                    .foregroundStyle(HBTheme.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        canAdvance ? AnyShapeStyle(HBTheme.brand) : AnyShapeStyle(HBTheme.textTertiary),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
        }
        .padding(.horizontal, HBTheme.screenPadding)
        .padding(.vertical, 12)
        .background(HBTheme.canvas.opacity(0.96))
    }
}

// MARK: - Info (lokální TextField stav)

private struct AmateurWizardInfoCard: View {
    let draft: AmateurWizardInfoDraft
    @Binding var isValid: Bool

    @State private var name = ""
    @State private var location = ""
    @State private var start = Date()
    @FocusState private var focus: Field?

    private enum Field: Hashable { case name, location }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(title: "Název") {
                TextField("např. Memoriál 2026", text: $name)
                    .font(.hbMontserrat(size: 16, weight: .semibold))
                    .focused($focus, equals: .name)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .onSubmit { focus = .location }
            }
            field(title: "Místo") {
                TextField("Hala / město", text: $location)
                    .font(.hbMontserrat(size: 16, weight: .medium))
                    .focused($focus, equals: .location)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
            }
            field(title: "Datum") {
                DatePicker("", selection: $start, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
        }
        .padding(16)
        .hbCard(cornerRadius: HBTheme.radiusLg)
        .onAppear {
            name = draft.name
            location = draft.location
            start = draft.start
            publishValidity(name)
            DispatchQueue.main.async { focus = .name }
        }
        .onChange(of: name) { _, value in
            draft.name = value
            publishValidity(value)
        }
        .onChange(of: location) { _, value in
            draft.location = value
        }
        .onChange(of: start) { _, value in
            draft.start = value
        }
    }

    private func publishValidity(_ value: String) {
        let valid = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isValid != valid { isValid = valid }
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))
        }
    }
}

// MARK: - Teams

private struct AmateurWizardTeamsCard: View {
    @Binding var draftTeams: [AmateurCreateTournamentSheet.DraftTeam]
    @Binding var isValid: Bool

    @State private var draft = ""
    @FocusState private var focused: Bool

    private let colors = ["C92A2A", "1C7ED6", "2F9E44", "F08C00", "9C36B5", "0B7285", "E8590C", "343A40"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField("Název týmu", text: $draft)
                    .font(.hbMontserrat(size: 16, weight: .semibold))
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(add)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: HBTheme.radiusSm, style: .continuous))

                Button(action: add) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(width: 46, height: 46)
                        .background(HBTheme.brand, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if draftTeams.isEmpty {
                Text("Zatím žádný tým — přidej aspoň dva.")
                    .font(.hbMontserrat(size: 13, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(draftTeams) { team in
                    HStack(spacing: 12) {
                        Text(team.shortName)
                            .font(.hbMontserrat(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: team.colorHex), in: Circle())
                        Text(team.name)
                            .font(.hbMontserrat(size: 15, weight: .bold))
                            .foregroundStyle(HBTheme.textPrimary)
                        Spacer(minLength: 0)
                        Button {
                            draftTeams.removeAll { $0.id == team.id }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(HBTheme.textTertiary)
                                .frame(width: 28, height: 28)
                                .background(HBTheme.cardInset, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
                }
            }
        }
        .onAppear {
            focused = true
            syncValid()
        }
        .onChange(of: draftTeams.count) { _, _ in syncValid() }
    }

    private func syncValid() {
        let valid = draftTeams.count >= 2
        if isValid != valid { isValid = valid }
    }

    private func add() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let short = String(trimmed.split(separator: " ").compactMap(\.first).prefix(3)).uppercased()
        draftTeams.append(
            .init(
                name: trimmed,
                shortName: short.isEmpty ? String(trimmed.prefix(3)).uppercased() : short,
                colorHex: colors[draftTeams.count % colors.count]
            )
        )
        draft = ""
        focused = true
    }
}

// MARK: - Setup

private struct AmateurWizardSetupCard: View {
    @Binding var format: AmateurTournamentFormat
    @Binding var homeAndAway: Bool
    @Binding var playoffTeamCount: Int
    @Binding var seriesLength: Int
    @Binding var periodCount: Int
    @Binding var periodLength: Int
    @Binding var overtimeEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HERNÍ SYSTÉM")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)

            ForEach(AmateurTournamentFormat.allCases, id: \.self) { item in
                Button {
                    format = item
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: format == item ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(format == item ? HBTheme.brand : HBTheme.textTertiary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.label)
                                .font(.hbMontserrat(size: 15, weight: .bold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text(item.detail)
                                .font(.hbMontserrat(size: 12, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
                    .overlay(
                        RoundedRectangle(cornerRadius: HBTheme.radiusMd, style: .continuous)
                            .strokeBorder(format == item ? HBTheme.brand.opacity(0.45) : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }

            if format.hasGroupStage {
                Toggle("Doma i venku", isOn: $homeAndAway)
                    .font(.hbMontserrat(size: 15, weight: .semibold))
                    .tint(HBTheme.brand)
                    .padding(14)
                    .hbCard(cornerRadius: HBTheme.radiusMd)
            }

            if format == .roundRobinAndPlayoff {
                pickerCard("Play-off týmů", selection: $playoffTeamCount, options: [
                    (2, "2"), (4, "4"), (8, "8"), (16, "16")
                ])
            }

            if format.usesSeries {
                pickerCard("Série", selection: $seriesLength, options: [
                    (1, "1"), (3, "Bo3"), (5, "Bo5"), (7, "Bo7")
                ])
            }

            Text("DÉLKA ZÁPASU")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(HBTheme.textTertiary)
                .padding(.top, 6)

            VStack(spacing: 12) {
                Stepper("Třetiny: \(periodCount)", value: $periodCount, in: 1...4)
                Stepper("Délka: \(periodLength) min", value: $periodLength, in: 5...20)
                Toggle("Prodloužení", isOn: $overtimeEnabled)
                    .tint(HBTheme.brand)
            }
            .font(.hbMontserrat(size: 15, weight: .semibold))
            .padding(14)
            .hbCard(cornerRadius: HBTheme.radiusMd)
        }
    }

    private func pickerCard(_ title: String, selection: Binding<Int>, options: [(Int, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.hbMontserrat(size: 13, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
            HStack(spacing: 8) {
                ForEach(options, id: \.0) { value, label in
                    Button {
                        selection.wrappedValue = value
                    } label: {
                        Text(label)
                            .font(.hbMontserrat(size: 13, weight: .bold))
                            .foregroundStyle(selection.wrappedValue == value ? HBTheme.onBrand : HBTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selection.wrappedValue == value ? AnyShapeStyle(HBTheme.brand) : AnyShapeStyle(HBTheme.cardInset),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }
}

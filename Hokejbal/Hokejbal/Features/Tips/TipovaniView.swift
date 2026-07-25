import SwiftUI

/// Tipování vítěze Extraligy — karta do detailu zápasu.
struct MatchTipCard: View {
    @EnvironmentObject private var tips: MatchTipStore
    @EnvironmentObject private var catalog: CatalogStore

    let match: Match
    var home: Team?
    var away: Team?

    private var isExtraliga: Bool {
        tips.isExtraliga(match, competitions: catalog.competitions)
    }

    private var votes: MatchTipVotes {
        tips.votes(for: match.id)
    }

    private var myTip: MatchTip? {
        tips.tip(for: match.id)
    }

    private var canTip: Bool {
        tips.canTip(match)
    }

    var body: some View {
        if isExtraliga {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TIPOVAČKA")
                        .font(.hbMontserrat(size: 11, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(HBTheme.brand)
                    Spacer()
                    Text("+\(MatchTipStore.pointsPerCorrectTip) b za správný tip")
                        .font(.hbMontserrat(size: 11, weight: .semibold))
                        .foregroundStyle(HBTheme.textTertiary)
                }

                percentBar

                if canTip {
                    tipButtons
                } else if let myTip {
                    resultBanner(myTip)
                } else {
                    Text(match.status == .scheduled
                         ? "Tipování uzavřeno před začátkem."
                         : "Na tento zápas jsi netipoval.")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                }
            }
            .padding(14)
            .hbCard(cornerRadius: HBTheme.radiusMd)
            .onAppear {
                tips.ensureVotes(matchId: match.id)
                if match.status == .finished {
                    tips.resolve(matches: [match])
                }
            }
        }
    }

    private var percentBar: some View {
        VStack(spacing: 8) {
            HStack {
                teamPct(home?.shortName ?? "DOM", votes.homePercent, alignment: .leading)
                teamPct(away?.shortName ?? "HOS", votes.awayPercent, alignment: .trailing)
            }

            GeometryReader { geo in
                let homeW = geo.size.width * CGFloat(votes.homePercent) / 100
                ZStack(alignment: .leading) {
                    Capsule().fill(HBTheme.cardInset)
                    HStack(spacing: 0) {
                        Capsule()
                            .fill(HBTheme.brand)
                            .frame(width: max(8, homeW))
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(height: 10)

            Text("\(votes.homeCount + votes.awayCount) tipů komunity")
                .font(.hbMontserrat(size: 11, weight: .medium))
                .foregroundStyle(HBTheme.textTertiary)
                .frame(maxWidth: .infinity)
        }
    }

    private func teamPct(_ name: String, _ pct: Int, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text("\(pct) %")
                .font(.hbNumber(size: 20, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
            Text(name)
                .font(.hbMontserrat(size: 12, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private var tipButtons: some View {
        HStack(spacing: 10) {
            tipButton(
                title: home?.shortName ?? "Domácí",
                pick: .home,
                selected: myTip?.pick == .home
            )
            tipButton(
                title: away?.shortName ?? "Hosté",
                pick: .away,
                selected: myTip?.pick == .away
            )
        }
    }

    private func tipButton(title: String, pick: MatchTipPick, selected: Bool) -> some View {
        Button {
            _ = tips.placeTip(match: match, pick: pick, competitions: catalog.competitions)
        } label: {
            VStack(spacing: 4) {
                Text(selected ? "Tvůj tip" : "Tipnout")
                    .font(.hbMontserrat(size: 10, weight: .bold))
                    .foregroundStyle(selected ? HBTheme.onBrand.opacity(0.85) : HBTheme.textTertiary)
                Text(title)
                    .font(.hbMontserrat(size: 14, weight: .bold))
                    .foregroundStyle(selected ? HBTheme.onBrand : HBTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selected ? AnyShapeStyle(HBTheme.brandGradient) : AnyShapeStyle(HBTheme.cardInset),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? Color.clear : HBTheme.cardStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func resultBanner(_ tip: MatchTip) -> some View {
        HStack(spacing: 10) {
            Image(systemName: tip.isCorrect == true ? "checkmark.circle.fill" : (tip.resolved ? "xmark.circle.fill" : "clock.fill"))
                .foregroundStyle(tip.isCorrect == true ? HBTheme.win : (tip.resolved ? HBTheme.loss : HBTheme.brand))
            VStack(alignment: .leading, spacing: 2) {
                Text(tipLabel(tip))
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                Text(subtitle(tip))
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func tipLabel(_ tip: MatchTip) -> String {
        let team = tip.pick == .home ? (home?.shortName ?? "Domácí") : (away?.shortName ?? "Hosté")
        return "Tip: \(team)"
    }

    private func subtitle(_ tip: MatchTip) -> String {
        if tip.isCorrect == true { return "Správně · +\(tip.pointsAwarded) b" }
        if tip.resolved { return "Špatný tip · 0 b" }
        return "Čeká na výsledek"
    }
}

// MARK: - Více: Tipovačka hub

struct TipovaniView: View {
    @EnvironmentObject private var tips: MatchTipStore
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore

    @State private var recentMatches: [Match] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                statsGrid
                menuBlock
            }
            .padding(HBTheme.screenPadding)
            .padding(.bottom, 28)
        }
        .background(HBTheme.canvas)
        .navigationTitle("Tipovačka")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    TipProfileEditView()
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .hbNavigationStyle()
        .task { await refreshResolutions() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EXTRALIGA")
                .font(.hbMontserrat(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.28))
            Text("Tipuj vítěze zápasu")
                .font(.hbDisplay(size: 24, weight: .heavy))
                .foregroundStyle(.white)
            Text("Tipni domácí nebo hosty před začátkem. Správný tip = \(MatchTipStore.pointsPerCorrectTip) body. Lokální demo na tomto zařízení.")
                .font(.hbMontserrat(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.88))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [HBTheme.ink, HBTheme.brandDark, HBTheme.brand],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: HBTheme.radiusLg, style: .continuous)
        )
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOJE STATISTIKY")
                .font(.hbMontserrat(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(HBTheme.textTertiary)

            tipStat("Pořadí", "#\(tips.myRank)", featured: true)

            HStack(spacing: 8) {
                tipStat("Body", "\(tips.seasonPoints)")
                tipStat("Úspěšnost", String(format: "%.0f %%", tips.accuracy))
            }
        }
    }

    private func tipStat(_ title: String, _ value: String, featured: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.hbMontserrat(size: 10, weight: .bold))
                .foregroundStyle(HBTheme.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(HBTheme.brand)
            Text(value)
                .font(.hbNumber(size: featured ? 28 : 22, weight: .heavy))
                .foregroundStyle(HBTheme.textPrimary)
                .padding(.vertical, featured ? 14 : 10)
        }
        .frame(maxWidth: .infinity)
        .background(HBTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(HBTheme.cardStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var menuBlock: some View {
        VStack(spacing: 0) {
            menuLink("Žebříček", icon: "list.number", destination: TipLeaderboardView())
            menuDivider
            menuLink("Pravidla", icon: "book.fill", destination: TipRulesScreen())
        }
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }

    private func menuLink<Dest: View>(_ title: String, icon: String, destination: Dest) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HBTheme.brand)
                    .frame(width: 28)
                Text(title)
                    .font(.hbMontserrat(size: 16, weight: .semibold))
                    .foregroundStyle(HBTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(HBTheme.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 56)
    }

    private func refreshResolutions() async {
        let comps = catalog.competitions.filter { $0.slug == MatchTipStore.competitionSlug }
        var all: [Match] = []
        for comp in comps {
            let list = await MatchListCache.shared.matches(competitionId: comp.id, using: apiClient.api)
            all.append(contentsOf: list)
        }
        if all.isEmpty {
            all = await MatchListCache.shared.seasonMatches(using: apiClient.api, seasonId: nil)
                .filter { $0.competitionId.contains("extraliga") }
        }
        recentMatches = all
        tips.resolve(matches: all)
    }
}

struct TipLeaderboardView: View {
    @EnvironmentObject private var tips: MatchTipStore

    var body: some View {
        List {
            ForEach(Array(tips.leaderboard.enumerated()), id: \.element.id) { index, row in
                HStack {
                    Text("\(index + 1)")
                        .font(.hbNumber(size: 16, weight: .heavy))
                        .foregroundStyle(row.isCurrentUser ? HBTheme.brand : HBTheme.textSecondary)
                        .frame(width: 28, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.hbMontserrat(size: 15, weight: row.isCurrentUser ? .bold : .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                        Text(String(format: "%.0f %% · %d/%d", row.accuracy, row.correct, row.total))
                            .font(.hbMontserrat(size: 11, weight: .medium))
                            .foregroundStyle(HBTheme.textTertiary)
                    }
                    Spacer()
                    Text("\(row.points) b")
                        .font(.hbNumber(size: 15, weight: .bold))
                        .foregroundStyle(HBTheme.textSecondary)
                }
                .listRowBackground(row.isCurrentUser ? HBTheme.brand.opacity(0.08) : HBTheme.card)
            }
        }
        .navigationTitle("Žebříček")
        .hbNavigationStyle()
    }
}

struct TipRulesScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                rule("Soutěž", "Tipovačka platí pro zápasy Extraligy hokejbalu.")
                rule("Tip", "Před začátkem zápasu tipni vítěze — domácí nebo hosty. Remíza se netipuje.")
                rule("Uzávěrka", "Tipování se uzavírá se začátkem zápasu. Po startu tip už nejde změnit.")
                rule("Body", "Správný tip = \(MatchTipStore.pointsPerCorrectTip) body. Špatný tip = 0.")
                rule("Žebříček", "Pořadí podle bodů za sezónu. Při shodě rozhoduje úspěšnost.")
                rule("Profil", "Přezdívku v žebříčku nastavíš v profilu tipéra (ikona vpravo nahoře).")
            }
            .padding(HBTheme.screenPadding)
        }
        .background(HBTheme.canvas)
        .navigationTitle("Pravidla")
        .hbNavigationStyle()
    }

    private func rule(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.hbMontserrat(size: 15, weight: .bold))
            Text(text)
                .font(.hbMontserrat(size: 13, weight: .medium))
                .foregroundStyle(HBTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hbCard(cornerRadius: HBTheme.radiusMd)
    }
}

struct TipProfileEditView: View {
    @EnvironmentObject private var tips: MatchTipStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        Form {
            Section("Jméno v žebříčku") {
                TextField("Přezdívka", text: $name)
            }
            Section {
                Text("Účty přijdou později — zatím je tipovačka lokální na tomto zařízení.")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
        }
        .navigationTitle("Profil tipéra")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Uložit") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { tips.displayName = trimmed }
                    dismiss()
                }
            }
        }
        .onAppear { name = tips.displayName }
        .hbNavigationStyle()
    }
}

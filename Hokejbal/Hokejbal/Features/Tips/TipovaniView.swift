import SwiftUI

/// Tipování vítěze Extraligy — karta do detailu zápasu.
struct MatchTipCard: View {
    @EnvironmentObject private var tips: MatchTipStore
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var auth: AuthStore

    let match: Match
    var home: Team?
    var away: Team?

    @State private var scoreHome: Int = 0
    @State private var scoreAway: Int = 0
    @State private var scoreOvertime: Bool = false
    @State private var didSeedScore = false

    private var isExtraliga: Bool {
        tips.isExtraliga(match, competitions: catalog.competitions)
    }

    private var votes: MatchTipVotes {
        tips.votes(for: match.id)
    }

    private var myTip: MatchTip? {
        tips.tip(for: match.id)
    }

    private var myScoreTip: MatchScoreTip? {
        tips.scoreTip(for: match.id)
    }

    private var canTip: Bool {
        (FantasyMock.enabled || auth.isAuthenticated) && tips.canTip(match)
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
                } else if let myTip, (FantasyMock.enabled || auth.isAuthenticated) {
                    resultBanner(myTip)
                } else if !FantasyMock.enabled && !auth.isAuthenticated && tips.canTip(match) {
                    Button {
                        auth.presentLogin()
                    } label: {
                        Text("Pro tipování se přihlas")
                            .font(.hbMontserrat(size: 13, weight: .bold))
                            .foregroundStyle(HBTheme.brand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(match.status == .scheduled
                         ? "Tipování uzavřeno před začátkem."
                         : "Na tento zápas jsi netipoval.")
                        .font(.hbMontserrat(size: 12, weight: .medium))
                        .foregroundStyle(HBTheme.textSecondary)
                }

                if canTip || myScoreTip != nil {
                    Rectangle()
                        .fill(HBTheme.separator.opacity(0.5))
                        .frame(height: 0.5)
                        .padding(.vertical, 2)
                    scoreSection
                }
            }
            .padding(14)
            .hbCard(cornerRadius: HBTheme.radiusMd)
            .onAppear {
                tips.ensureVotes(matchId: match.id)
                if !didSeedScore {
                    if let existing = myScoreTip {
                        scoreHome = existing.homeScore
                        scoreAway = existing.awayScore
                        scoreOvertime = existing.predictedOvertime
                    }
                    didSeedScore = true
                }
                if match.status == .finished {
                    tips.resolve(matches: [match])
                    tips.resolveScoreTips(matches: [match])
                }
            }
        }
    }

    // MARK: - Tip skóre (soukromý)

    @ViewBuilder
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TIP SKÓRE")
                    .font(.hbMontserrat(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(HBTheme.brand)
                Spacer()
                Text("soukromé · +5 / 3 / 2 b")
                    .font(.hbMontserrat(size: 11, weight: .semibold))
                    .foregroundStyle(HBTheme.textTertiary)
            }

            if canTip {
                HStack(spacing: 12) {
                    scoreCounter(title: home?.shortName ?? "DOM", value: $scoreHome)
                    Text(":")
                        .font(.hbNumber(size: 22, weight: .heavy))
                        .foregroundStyle(HBTheme.textSecondary)
                    scoreCounter(title: away?.shortName ?? "HOS", value: $scoreAway)
                }

                if FantasyScoring.canPredictOvertime(predHome: scoreHome, predAway: scoreAway) {
                    Toggle(isOn: $scoreOvertime) {
                        Text("Rozhodnuto v prodloužení / nájezdech")
                            .font(.hbMontserrat(size: 12, weight: .semibold))
                            .foregroundStyle(HBTheme.textPrimary)
                    }
                    .tint(HBTheme.brand)
                }

                Button {
                    _ = tips.placeScoreTip(
                        match: match, home: scoreHome, away: scoreAway,
                        overtime: scoreOvertime, competitions: catalog.competitions
                    )
                } label: {
                    Text(myScoreTip == nil ? "Uložit tip skóre" : "Aktualizovat tip skóre")
                        .font(.hbMontserrat(size: 13, weight: .bold))
                        .foregroundStyle(HBTheme.onBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HBTheme.brandGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Text("Tvůj tip skóre nikdo nevidí — počítá se jen do žebříčku.")
                    .font(.hbMontserrat(size: 11, weight: .medium))
                    .foregroundStyle(HBTheme.textTertiary)
            } else if let scoreTip = myScoreTip {
                scoreResultBanner(scoreTip)
            }
        }
    }

    private func scoreCounter(title: String, value: Binding<Int>) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.hbMontserrat(size: 11, weight: .bold))
                .foregroundStyle(HBTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 10) {
                scoreStep("minus") {
                    if value.wrappedValue > 0 { value.wrappedValue -= 1; clampOvertime() }
                }
                Text("\(value.wrappedValue)")
                    .font(.hbNumber(size: 24, weight: .heavy))
                    .foregroundStyle(HBTheme.textPrimary)
                    .frame(minWidth: 28)
                scoreStep("plus") {
                    if value.wrappedValue < 30 { value.wrappedValue += 1; clampOvertime() }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreStep(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(HBTheme.brand)
                .frame(width: 34, height: 34)
                .background(HBTheme.cardInset, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func clampOvertime() {
        if !FantasyScoring.canPredictOvertime(predHome: scoreHome, predAway: scoreAway) {
            scoreOvertime = false
        }
    }

    @ViewBuilder
    private func scoreResultBanner(_ tip: MatchScoreTip) -> some View {
        HStack(spacing: 10) {
            Image(systemName: tip.resolved
                  ? (tip.pointsAwarded > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                  : "lock.fill")
                .foregroundStyle(tip.resolved
                                 ? (tip.pointsAwarded > 0 ? HBTheme.win : HBTheme.loss)
                                 : HBTheme.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tip skóre: \(tip.homeScore):\(tip.awayScore)\(tip.predictedOvertime ? " (P)" : "")")
                    .font(.hbMontserrat(size: 13, weight: .bold))
                    .foregroundStyle(HBTheme.textPrimary)
                Text(tip.resolved ? "+\(tip.pointsAwarded) b" : "Soukromé · čeká na výsledek")
                    .font(.hbMontserrat(size: 12, weight: .medium))
                    .foregroundStyle(HBTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(HBTheme.cardInset, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            Text("Tipuj vítěze i skóre")
                .font(.hbDisplay(size: 24, weight: .heavy))
                .foregroundStyle(.white)
            Text("Tip vítěze = \(MatchTipStore.pointsPerCorrectTip) body a ukáže favorita komunity. K tomu přesné skóre (soukromé) až za 5 bodů do žebříčku.")
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
                tipStat("Body", "\(tips.combinedPoints)")
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
        await tips.syncScoreTipsFromRemote()
        tips.resolve(matches: all)
        tips.resolveScoreTips(matches: all)
        await tips.loadLeaderboard()
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
                        Text("\(row.total) tipů")
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
        .task { await tips.loadLeaderboard() }
    }
}

struct TipRulesScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                rule("Soutěž", "Tipovačka platí pro zápasy Extraligy hokejbalu. Pro tipování se přihlas.")
                rule("Tip vítěze", "Před začátkem tipni vítěze — domácí nebo hosty. Ukáže se favorit komunity v procentech.")
                rule("Tip skóre", "K tomu můžeš tipnout přesné skóre. Tvůj tip skóre je soukromý — nikdo ho nevidí, počítá se jen do žebříčku.")
                rule("Uzávěrka", "Oba tipy se uzavírají se začátkem zápasu. Po startu je už nejde změnit.")
                rule("Body vítěz", "Správný vítěz = \(MatchTipStore.pointsPerCorrectTip) body.")
                rule("Body skóre", "Přesné skóre 5 · správný vítěz + rozdíl 3 · správný vítěz 2 · trefa gólů jednoho týmu 1. Bonus +2 za správně tipnuté prodloužení / nájezdy.")
                rule("Žebříček", "Pořadí podle součtu všech bodů. Porovnáváš se se všemi hráči.")
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
                Text("Přezdívka se ukazuje v žebříčku vedle tvých bodů.")
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

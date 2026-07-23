import SwiftUI

struct LiveView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore

    private var groupedByCompetition: [(Competition?, [Match])] {
        competitionOrder.groupMatchesByCompetition(liveScores.liveMatches, catalog: catalog)
    }

    var body: some View {
        Group {
            if liveScores.liveMatches.isEmpty {
                EmptyStateView(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Žádné živé zápasy",
                    message: "Až začne další kolo, uvidíte zde průběžné výsledky."
                )
            } else {
                List {
                    ForEach(Array(groupedByCompetition.enumerated()), id: \.offset) { _, group in
                        let competition = group.0
                        let matches = group.1
                        Section {
                            if let competition {
                                NavigationLink {
                                    CompetitionDetailView(competitionId: competition.id)
                                } label: {
                                    CompetitionNavStrip(competition: competition)
                                }
                                .buttonStyle(.plain)
                                .navigationLinkIndicatorVisibility(.hidden)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(HBTheme.secondarySurface)
                                .listRowSeparator(.hidden)
                            }

                            ForEach(matches) { match in
                                NavigationLink {
                                    MatchDetailView(matchId: match.id)
                                } label: {
                                    MatchRowView(
                                        match: match,
                                        home: catalog.team(match.homeTeamId),
                                        away: catalog.team(match.awayTeamId),
                                        showCompetition: false,
                                        competitionName: nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .hbHideDisclosure()
                                .listRowInsets(HBTheme.matchRowInsets)
                                .listRowBackground(HBTheme.surface)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(HBTheme.surface)
                .refreshable {
                    await liveScores.pollOnce(using: apiClient.api)
                }
            }
        }
        .background(HBTheme.surface)
        .hbNavTitle("Živě", systemImage: "dot.radiowaves.left.and.right")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LiveBadge(compact: true)
                    .fixedSize()
            }
        }
        .hbNavigationStyle()
    }
}

import SwiftUI

struct LiveView: View {
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var liveScores: LiveScoreService
    @EnvironmentObject private var competitionOrder: CompetitionOrderStore
    @EnvironmentObject private var tabRouter: AppTabRouter

    private var filteredMatches: [Match] {
        switch tabRouter.liveFilter {
        case .all:
            return liveScores.liveMatches
        case .broadcasts:
            return liveScores.liveMatches.filter(\.isBroadcast)
        }
    }

    private var groupedByCompetition: [(Competition?, [Match])] {
        competitionOrder.groupMatchesByCompetition(filteredMatches, catalog: catalog)
    }

    var body: some View {
        VStack(spacing: 0) {
            HBPillSelector(selection: $tabRouter.liveFilter)
                .padding(.horizontal, HBTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(HBTheme.surface)

            content
        }
        .background(HBTheme.canvas)
        .hbNavTitle("Živě", systemImage: "dot.radiowaves.left.and.right")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LiveBadge(compact: true)
                    .fixedSize()
            }
        }
        .hbNavigationStyle()
        .task {
            await liveScores.pollOnce(using: apiClient.api)
        }
    }

    @ViewBuilder
    private var content: some View {
        if filteredMatches.isEmpty {
            EmptyStateView(
                icon: tabRouter.liveFilter == .broadcasts ? "tv" : "dot.radiowaves.left.and.right",
                title: tabRouter.liveFilter == .broadcasts ? "Žádné živé přenosy" : "Žádné živé zápasy",
                message: tabRouter.liveFilter == .broadcasts
                    ? "Teď se žádný zápas nevysílá. Přepněte na Vše, nebo se vraťte později."
                    : "Až začne další kolo, uvidíte zde průběžné výsledky."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(HBTheme.canvas)
            .refreshable {
                await liveScores.pollOnce(using: apiClient.api)
            }
        }
    }
}

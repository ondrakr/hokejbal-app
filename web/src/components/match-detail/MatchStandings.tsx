"use client";

import type { Match, StandingRow } from "@/lib/types";
import { StandingsTable } from "@/components/StandingsTable";
import { useCatalog } from "@/stores/catalog";

/** Thin wrapper — MatchDetail tabulka používá sdílený StandingsTable. */
export function MatchStandings({
  rows,
  highlightTeamIds,
  competitionSlug,
  competitionId,
}: {
  rows: StandingRow[];
  highlightTeamIds: string[];
  teamById?: unknown;
  competitionSlug?: string;
  competitionId?: string;
  onTeam?: (id: string) => void;
}) {
  const { matches } = useCatalog();
  const competitionMatches = competitionId
    ? matches.filter((m: Match) => m.competitionId === competitionId)
    : matches;

  return (
    <StandingsTable
      rows={rows}
      matches={competitionMatches}
      competitionId={competitionId}
      highlightTeamIds={highlightTeamIds}
      competitionSlug={competitionSlug}
      emptyMessage="Tabulka pro tuto soutěž není k dispozici."
    />
  );
}

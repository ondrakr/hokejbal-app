"use client";

import type { StandingRow } from "@/lib/types";
import { StandingsTable } from "@/components/StandingsTable";

/** Thin wrapper — MatchDetail tabulka používá sdílený StandingsTable. */
export function MatchStandings({
  rows,
  highlightTeamIds,
  competitionSlug,
}: {
  rows: StandingRow[];
  highlightTeamIds: string[];
  teamById?: unknown;
  competitionSlug?: string;
  onTeam?: (id: string) => void;
}) {
  return (
    <StandingsTable
      rows={rows}
      highlightTeamIds={highlightTeamIds}
      competitionSlug={competitionSlug}
      emptyMessage="Tabulka pro tuto soutěž není k dispozici."
    />
  );
}

import type { Match } from "@/lib/types";

export type TeamFormOutcome = "win" | "draw" | "loss";

export type TeamFormItem = {
  id: string;
  outcome: TeamFormOutcome;
};

export function teamFormLetter(outcome: TeamFormOutcome) {
  return outcome === "win" ? "V" : outcome === "draw" ? "R" : "P";
}

export function teamFormColor(outcome: TeamFormOutcome) {
  return outcome === "win"
    ? "var(--win)"
    : outcome === "draw"
      ? "var(--draw)"
      : "var(--loss)";
}

export function teamFormOutcome(match: Match, teamId: string): TeamFormOutcome {
  if (match.homeScore === match.awayScore) return "draw";
  const isHome = match.homeTeamId === teamId;
  const focus = isHome ? match.homeScore : match.awayScore;
  const other = isHome ? match.awayScore : match.homeScore;
  return focus > other ? "win" : "loss";
}

/** Posledních `limit` ukončených zápasů (nejstarší vlevo → nejnovější vpravo). */
export function teamFormItems(
  matches: Match[],
  teamId: string,
  excludingMatchId?: string,
  limit = 5
): TeamFormItem[] {
  const finished = matches
    .filter((m) => m.status === "finished")
    .filter((m) => m.homeTeamId === teamId || m.awayTeamId === teamId)
    .filter((m) => !excludingMatchId || m.id !== excludingMatchId)
    .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt))
    .slice(0, limit);

  return [...finished].reverse().map((match) => ({
    id: match.id,
    outcome: teamFormOutcome(match, teamId),
  }));
}

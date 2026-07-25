import type { Match } from "@/lib/types";

/**
 * Sloučí katalogové zápasy s aktuálními live zápasy (skóre / status).
 * Parita s iOS LiveScoreService merge u tabulek.
 */
export function mergeMatchesWithLive(
  matches: Match[],
  liveMatches: Match[],
  competitionId?: string
): Match[] {
  const liveScoped = competitionId
    ? liveMatches.filter((m) => m.competitionId === competitionId)
    : liveMatches;
  const liveById = new Map(liveScoped.map((m) => [m.id, m]));
  const merged = matches.map((m) => liveById.get(m.id) ?? m);
  const extras = liveScoped.filter((live) => !matches.some((m) => m.id === live.id));
  return [...merged, ...extras];
}

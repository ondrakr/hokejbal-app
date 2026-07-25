import type { Match, StandingRow } from "@/lib/types";

export type StandingsScope = "live" | "total" | "home" | "away" | "form";
export type FormWindow = 5 | 10 | 15;

export const STANDINGS_SCOPES: { id: StandingsScope; label: string }[] = [
  { id: "live", label: "Live" },
  { id: "total", label: "Celkem" },
  { id: "home", label: "Doma" },
  { id: "away", label: "Venku" },
  { id: "form", label: "Forma" },
];

export const FORM_WINDOWS: FormWindow[] = [5, 10, 15];

export type LiveScoreTone = "win" | "draw" | "loss";

export type StandingViewRow = StandingRow & {
  /** Live zápas — skóre z pohledu týmu (např. 4:2), badge vedle jména. */
  liveScore?: { text: string; tone: LiveScoreTone };
  /** Posun pořadí oproti oficiální tabulce (+ nahoru, − dolů). */
  rankDelta?: number;
};

type Agg = {
  teamId: string;
  played: number;
  wins: number;
  draws: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
  points: number;
};

function emptyAgg(teamId: string): Agg {
  return {
    teamId,
    played: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    goalsFor: 0,
    goalsAgainst: 0,
    points: 0,
  };
}

function applyResult(agg: Agg, gf: number, ga: number) {
  agg.played += 1;
  agg.goalsFor += gf;
  agg.goalsAgainst += ga;
  if (gf > ga) {
    agg.wins += 1;
    agg.points += 3;
  } else if (gf < ga) {
    agg.losses += 1;
  } else {
    agg.draws += 1;
    agg.points += 1;
  }
}

function sortAndRank(aggs: Agg[]): StandingViewRow[] {
  const sorted = [...aggs].sort((a, b) => {
    if (b.points !== a.points) return b.points - a.points;
    const diffA = a.goalsFor - a.goalsAgainst;
    const diffB = b.goalsFor - b.goalsAgainst;
    if (diffB !== diffA) return diffB - diffA;
    if (b.goalsFor !== a.goalsFor) return b.goalsFor - a.goalsFor;
    return a.teamId.localeCompare(b.teamId, "cs");
  });

  return sorted.map((row, i) => ({
    id: `view-${row.teamId}`,
    teamId: row.teamId,
    rank: i + 1,
    played: row.played,
    wins: row.wins,
    draws: row.draws,
    losses: row.losses,
    goalsFor: row.goalsFor,
    goalsAgainst: row.goalsAgainst,
    points: row.points,
  }));
}

function competitionMatches(matches: Match[], competitionId: string) {
  return matches.filter((m) => m.competitionId === competitionId);
}

function finishedMatches(matches: Match[]) {
  return matches.filter((m) => m.status === "finished");
}

function liveMatches(matches: Match[]) {
  return matches.filter((m) => m.status === "live");
}

/** Domácí / venkovní tabulka z odehraných zápasů. */
function aggregateSide(
  base: StandingRow[],
  matches: Match[],
  competitionId: string,
  side: "home" | "away"
): StandingViewRow[] {
  const map = new Map<string, Agg>();
  for (const row of base) map.set(row.teamId, emptyAgg(row.teamId));

  for (const m of finishedMatches(competitionMatches(matches, competitionId))) {
    if (side === "home") {
      const home = map.get(m.homeTeamId) ?? emptyAgg(m.homeTeamId);
      applyResult(home, m.homeScore, m.awayScore);
      map.set(m.homeTeamId, home);
    } else {
      const away = map.get(m.awayTeamId) ?? emptyAgg(m.awayTeamId);
      applyResult(away, m.awayScore, m.homeScore);
      map.set(m.awayTeamId, away);
    }
  }

  return sortAndRank([...map.values()]);
}

/** Forma — posledních `window` zápasů každého týmu. */
function aggregateForm(
  base: StandingRow[],
  matches: Match[],
  competitionId: string,
  window: FormWindow
): StandingViewRow[] {
  const map = new Map<string, Agg>();
  for (const row of base) map.set(row.teamId, emptyAgg(row.teamId));

  const finished = finishedMatches(competitionMatches(matches, competitionId)).sort((a, b) =>
    b.scheduledAt.localeCompare(a.scheduledAt)
  );

  for (const teamId of map.keys()) {
    const recent = finished
      .filter((m) => m.homeTeamId === teamId || m.awayTeamId === teamId)
      .slice(0, window);
    const agg = map.get(teamId)!;
    for (const m of recent) {
      const isHome = m.homeTeamId === teamId;
      applyResult(
        agg,
        isHome ? m.homeScore : m.awayScore,
        isHome ? m.awayScore : m.homeScore
      );
    }
  }

  return sortAndRank([...map.values()]);
}

/**
 * Live tabulka: oficiální Z/G/B + průběh live zápasů (Z+1, góly, body).
 * Live skóre jde do badge (zelená/červená/oranžová); G = kumulativní skóre.
 */
function aggregateLive(
  base: StandingRow[],
  matches: Match[],
  competitionId: string
): StandingViewRow[] {
  const live = liveMatches(competitionMatches(matches, competitionId));
  const liveScore = new Map<string, { text: string; tone: LiveScoreTone }>();
  const delta = new Map<string, { played: number; gf: number; ga: number; points: number; wins: number; draws: number; losses: number }>();

  function bump(
    teamId: string,
    gf: number,
    ga: number,
    pts: number,
    result: "win" | "draw" | "loss"
  ) {
    const cur = delta.get(teamId) ?? {
      played: 0,
      gf: 0,
      ga: 0,
      points: 0,
      wins: 0,
      draws: 0,
      losses: 0,
    };
    cur.played += 1;
    cur.gf += gf;
    cur.ga += ga;
    cur.points += pts;
    if (result === "win") cur.wins += 1;
    else if (result === "draw") cur.draws += 1;
    else cur.losses += 1;
    delta.set(teamId, cur);
  }

  for (const m of live) {
    const hs = m.homeScore;
    const as = m.awayScore;
    if (hs === as) {
      bump(m.homeTeamId, hs, as, 1, "draw");
      bump(m.awayTeamId, as, hs, 1, "draw");
      liveScore.set(m.homeTeamId, { text: `${hs}:${as}`, tone: "draw" });
      liveScore.set(m.awayTeamId, { text: `${as}:${hs}`, tone: "draw" });
    } else if (hs > as) {
      bump(m.homeTeamId, hs, as, 3, "win");
      bump(m.awayTeamId, as, hs, 0, "loss");
      liveScore.set(m.homeTeamId, { text: `${hs}:${as}`, tone: "win" });
      liveScore.set(m.awayTeamId, { text: `${as}:${hs}`, tone: "loss" });
    } else {
      bump(m.awayTeamId, as, hs, 3, "win");
      bump(m.homeTeamId, hs, as, 0, "loss");
      liveScore.set(m.awayTeamId, { text: `${as}:${hs}`, tone: "win" });
      liveScore.set(m.homeTeamId, { text: `${hs}:${as}`, tone: "loss" });
    }
  }

  const baseRank = new Map(base.map((r) => [r.teamId, r.rank]));

  const rows: StandingViewRow[] = base.map((row) => {
    const d = delta.get(row.teamId);
    return {
      ...row,
      id: `live-${row.teamId}`,
      played: row.played + (d?.played ?? 0),
      wins: row.wins + (d?.wins ?? 0),
      losses: row.losses + (d?.losses ?? 0),
      goalsFor: row.goalsFor + (d?.gf ?? 0),
      goalsAgainst: row.goalsAgainst + (d?.ga ?? 0),
      points: row.points + (d?.points ?? 0),
      liveScore: liveScore.get(row.teamId),
    };
  });

  rows.sort((a, b) => {
    if (b.points !== a.points) return b.points - a.points;
    const diffA = a.goalsFor - a.goalsAgainst;
    const diffB = b.goalsFor - b.goalsAgainst;
    if (diffB !== diffA) return diffB - diffA;
    if (b.goalsFor !== a.goalsFor) return b.goalsFor - a.goalsFor;
    return a.teamId.localeCompare(b.teamId, "cs");
  });

  return rows.map((row, i) => {
    const rank = i + 1;
    const prev = baseRank.get(row.teamId) ?? rank;
    return {
      ...row,
      rank,
      rankDelta: prev - rank,
    };
  });
}

export function buildStandingsView(opts: {
  base: StandingRow[];
  matches: Match[];
  competitionId: string;
  scope: StandingsScope;
  formWindow?: FormWindow;
}): StandingViewRow[] {
  const { base, matches, competitionId, scope, formWindow = 5 } = opts;
  if (!base.length) return [];

  switch (scope) {
    case "total":
      return base.map((r) => ({ ...r }));
    case "home":
      return aggregateSide(base, matches, competitionId, "home");
    case "away":
      return aggregateSide(base, matches, competitionId, "away");
    case "form":
      return aggregateForm(base, matches, competitionId, formWindow);
    case "live":
      return aggregateLive(base, matches, competitionId);
  }
}

export function standingsScopeHasLive(matches: Match[], competitionId: string) {
  return liveMatches(competitionMatches(matches, competitionId)).length > 0;
}

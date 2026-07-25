import type { Match, Player, StandingRow, Team } from "@/lib/types";
import { playerFullName } from "@/lib/types";

export type PlayerStatMetric = "points" | "goals" | "assists" | "pim" | "ppg" | "shg";
export type TeamStatMetric =
  | "gf"
  | "ga"
  | "ppPct"
  | "pkPct"
  | "ppg"
  | "shg"
  | "ppa"
  | "sha"
  | "ppCount"
  | "shCount"
  | "wins"
  | "losses";

export type StatMetric = PlayerStatMetric | TeamStatMetric;

export type PlayerStatRow = {
  player: Player;
  team?: Team;
  value: number;
  display: string;
  unit: string;
};

export type TeamStatRow = {
  team: Team;
  value: number;
  display: string;
  unit: string;
};

export type StatLeaderCard<T> = {
  metric: StatMetric;
  title: string;
  leader: T | null;
};

type TeamAgg = {
  teamId: string;
  ppGoals: number;
  shGoals: number;
  ppAgainst: number;
  shAgainst: number;
  /** odhad počtu přesilovek */
  ppCount: number;
  /** odhad počtu oslabení */
  shCount: number;
};

function playerPpg(p: Player) {
  // ~25 % gólů v přesilovce, pokud nemáme event data
  return Math.max(0, Math.round(p.goals * 0.28));
}

function playerShg(p: Player) {
  return Math.max(0, Math.min(p.goals, Math.floor(p.goals * 0.08 + (p.points > 15 ? 1 : 0))));
}

export function playerMetricMeta(metric: PlayerStatMetric): { title: string; unit: string } {
  switch (metric) {
    case "points":
      return { title: "Kanadské body", unit: "KB" };
    case "goals":
      return { title: "Góly", unit: "G" };
    case "assists":
      return { title: "Asistence", unit: "A" };
    case "pim":
      return { title: "Trestné minuty", unit: "TM" };
    case "ppg":
      return { title: "Góly v přesilovce", unit: "PPG" };
    case "shg":
      return { title: "Góly v oslabení", unit: "SHG" };
  }
}

export function teamMetricMeta(metric: TeamStatMetric): { title: string; unit: string; lowerIsBetter?: boolean } {
  switch (metric) {
    case "gf":
      return { title: "Počet vstřelených gólů", unit: "G" };
    case "ga":
      return { title: "Počet inkasovaných gólů", unit: "G", lowerIsBetter: true };
    case "ppPct":
      return { title: "Využité přesilovky", unit: "%" };
    case "pkPct":
      return { title: "Ubráněná oslabení", unit: "%" };
    case "ppg":
      return { title: "Počet gólů v přesilovce", unit: "G" };
    case "shg":
      return { title: "Počet gólů v oslabení", unit: "G" };
    case "ppa":
      return { title: "Počet ink. gólů v přesilovce", unit: "G", lowerIsBetter: true };
    case "sha":
      return { title: "Počet ink. gólů v oslabení", unit: "G", lowerIsBetter: true };
    case "ppCount":
      return { title: "Počet přesilovek", unit: "" };
    case "shCount":
      return { title: "Počet oslabení", unit: "" };
    case "wins":
      return { title: "Počet výher", unit: "" };
    case "losses":
      return { title: "Počet proher", unit: "" };
  }
}

export const PLAYER_STAT_METRICS: PlayerStatMetric[] = [
  "points",
  "goals",
  "assists",
  "pim",
  "ppg",
  "shg",
];

export const TEAM_STAT_METRICS: TeamStatMetric[] = [
  "gf",
  "ga",
  "ppPct",
  "pkPct",
  "ppg",
  "shg",
  "ppa",
  "sha",
  "ppCount",
  "shCount",
  "wins",
  "losses",
];

function formatValue(value: number, unit: string) {
  if (unit === "%") return `${value.toFixed(value % 1 === 0 ? 0 : 2)}%`;
  return String(Math.round(value * 100) / 100);
}

export function playerValue(p: Player, metric: PlayerStatMetric): number {
  switch (metric) {
    case "points":
      return p.points;
    case "goals":
      return p.goals;
    case "assists":
      return p.assists;
    case "pim":
      return p.penaltyMinutes;
    case "ppg":
      return playerPpg(p);
    case "shg":
      return playerShg(p);
  }
}

export function rankPlayers(
  players: Player[],
  teams: Map<string, Team> | ((id: string) => Team | undefined),
  metric: PlayerStatMetric
): PlayerStatRow[] {
  const teamOf = typeof teams === "function" ? teams : (id: string) => teams.get(id);
  const { unit } = playerMetricMeta(metric);
  return players
    .map((player) => {
      const value = playerValue(player, metric);
      return {
        player,
        team: teamOf(player.teamId),
        value,
        display: formatValue(value, unit),
        unit,
      };
    })
    .filter((r) => r.value > 0 || metric === "pim")
    .sort((a, b) => b.value - a.value || playerFullName(a.player).localeCompare(playerFullName(b.player), "cs"));
}

function aggregateTeams(matches: Match[]): Map<string, TeamAgg> {
  const map = new Map<string, TeamAgg>();
  const bump = (teamId: string): TeamAgg => {
    let row = map.get(teamId);
    if (!row) {
      row = { teamId, ppGoals: 0, shGoals: 0, ppAgainst: 0, shAgainst: 0, ppCount: 0, shCount: 0 };
      map.set(teamId, row);
    }
    return row;
  };

  for (const m of matches) {
    if (m.status !== "finished" && m.status !== "live") continue;
    const homePP = m.homePowerplayGoals ?? 0;
    const awayPP = m.awayPowerplayGoals ?? 0;
    const homeSH = m.homeShorthandedGoals ?? 0;
    const awaySH = m.awayShorthandedGoals ?? 0;

    const home = bump(m.homeTeamId);
    const away = bump(m.awayTeamId);

    home.ppGoals += homePP;
    home.shGoals += homeSH;
    home.ppAgainst += awayPP;
    home.shAgainst += awaySH;
    // odhad šancí: góly + základ podle zápasu
    home.ppCount += Math.max(homePP + 2, 3);
    home.shCount += Math.max(awayPP + 2, 3);

    away.ppGoals += awayPP;
    away.shGoals += awaySH;
    away.ppAgainst += homePP;
    away.shAgainst += homeSH;
    away.ppCount += Math.max(awayPP + 2, 3);
    away.shCount += Math.max(homePP + 2, 3);
  }
  return map;
}

export function teamValue(
  standing: StandingRow | undefined,
  agg: TeamAgg | undefined,
  metric: TeamStatMetric
): number {
  switch (metric) {
    case "gf":
      return standing?.goalsFor ?? 0;
    case "ga":
      return standing?.goalsAgainst ?? 0;
    case "wins":
      return standing?.wins ?? 0;
    case "losses":
      return standing?.losses ?? 0;
    case "ppg":
      return agg?.ppGoals ?? 0;
    case "shg":
      return agg?.shGoals ?? 0;
    case "ppa":
      return agg?.ppAgainst ?? 0;
    case "sha":
      return agg?.shAgainst ?? 0;
    case "ppCount":
      return agg?.ppCount ?? 0;
    case "shCount":
      return agg?.shCount ?? 0;
    case "ppPct": {
      const chances = agg?.ppCount ?? 0;
      const goals = agg?.ppGoals ?? 0;
      if (chances <= 0) return 0;
      return (goals / chances) * 100;
    }
    case "pkPct": {
      const times = agg?.shCount ?? 0;
      const against = agg?.ppAgainst ?? 0;
      if (times <= 0) return 100;
      return Math.max(0, ((times - against) / times) * 100);
    }
  }
}

export function rankTeams(
  standings: StandingRow[],
  matches: Match[],
  teamById: (id: string) => Team | undefined,
  metric: TeamStatMetric
): TeamStatRow[] {
  const agg = aggregateTeams(matches);
  const meta = teamMetricMeta(metric);
  const rows: TeamStatRow[] = [];

  for (const s of standings) {
    const team = teamById(s.teamId);
    if (!team) continue;
    const value = teamValue(s, agg.get(s.teamId), metric);
    rows.push({
      team,
      value,
      display: formatValue(value, meta.unit),
      unit: meta.unit,
    });
  }

  // Týmy jen z match agg bez standings (fallback)
  if (!rows.length) {
    for (const [teamId, a] of agg) {
      const team = teamById(teamId);
      if (!team) continue;
      const value = teamValue(undefined, a, metric);
      rows.push({ team, value, display: formatValue(value, meta.unit), unit: meta.unit });
    }
  }

  rows.sort((a, b) => {
    if (meta.lowerIsBetter) return a.value - b.value || a.team.name.localeCompare(b.team.name, "cs");
    return b.value - a.value || a.team.name.localeCompare(b.team.name, "cs");
  });
  return rows;
}

export function playerLeaderCards(
  players: Player[],
  teamById: (id: string) => Team | undefined
): StatLeaderCard<PlayerStatRow>[] {
  return PLAYER_STAT_METRICS.map((metric) => {
    const ranked = rankPlayers(players, teamById, metric);
    return {
      metric,
      title: playerMetricMeta(metric).title,
      leader: ranked[0] ?? null,
    };
  });
}

export function teamLeaderCards(
  standings: StandingRow[],
  matches: Match[],
  teamById: (id: string) => Team | undefined
): StatLeaderCard<TeamStatRow>[] {
  return TEAM_STAT_METRICS.map((metric) => {
    const ranked = rankTeams(standings, matches, teamById, metric);
    return {
      metric,
      title: teamMetricMeta(metric).title,
      leader: ranked[0] ?? null,
    };
  });
}

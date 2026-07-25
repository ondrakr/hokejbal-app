export type MatchStatus = "scheduled" | "live" | "finished" | "postponed";
export type PlayerPosition = "forward" | "defenseman" | "goalie";
export type CompetitionPhase = "regular" | "playoffs";

export interface Season {
  id: string;
  label: string;
  sortOrder: number;
  isCurrent: boolean;
}

export interface Competition {
  id: string;
  slug: string;
  seasonId: string;
  name: string;
  shortName: string;
  season: string;
  logoURL?: string | null;
  logoInitials: string;
  iconSystemName: string;
}

export interface Team {
  id: string;
  name: string;
  shortName: string;
  city: string;
  primaryColorHex: string;
  logoInitials: string;
  logoURL?: string | null;
  competitionId: string;
}

export interface Player {
  id: string;
  firstName: string;
  lastName: string;
  number: number;
  position: PlayerPosition;
  teamId: string;
  games: number;
  goals: number;
  assists: number;
  points: number;
  penaltyMinutes: number;
  savePercentage?: number | null;
  goalsAgainstAverage?: number | null;
  seasonId?: string | null;
  seasonLabel?: string | null;
  competitionId?: string | null;
  photoURL?: string | null;
}

export interface MatchEvent {
  id: string;
  kind: "goal" | "penalty" | "periodStart" | "periodEnd";
  minute: number;
  second: number;
  teamId: string;
  playerId?: string | null;
  assistIds: string[];
  description: string;
  period: number;
}

export interface Match {
  id: string;
  competitionId: string;
  homeTeamId: string;
  awayTeamId: string;
  scheduledAt: string;
  status: MatchStatus;
  period: string;
  clock?: string | null;
  phase?: CompetitionPhase | null;
  homeScore: number;
  awayScore: number;
  homePeriodScores: number[];
  awayPeriodScores: number[];
  venue: string;
  round: number;
  events: MatchEvent[];
  attendance?: number | null;
  streamURL?: string | null;
  streamLabel?: string | null;
  homeShots?: number | null;
  awayShots?: number | null;
  homePowerplayGoals?: number | null;
  awayPowerplayGoals?: number | null;
  homeShorthandedGoals?: number | null;
  awayShorthandedGoals?: number | null;
  referees?: string | null;
}

export interface StandingRow {
  id: string;
  teamId: string;
  rank: number;
  played: number;
  wins: number;
  draws: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
  points: number;
}

/** Účast klubu v sezóně — historie týmu (iOS ClubSeasonRecord). */
export interface ClubSeasonRecord {
  id: string;
  seasonId: string;
  seasonLabel: string;
  competitionId: string;
  competitionName: string;
  standing: StandingRow | null;
}

export interface NewsArticle {
  id: string;
  title: string;
  summary: string;
  category: string;
  publishedAt: string;
  photoURL?: string | null;
  articleURL?: string | null;
  imageGradientIndex: number;
}

export interface PlayerSeasonStat {
  id: string;
  playerId: string;
  clubId: string;
  competitionId: string;
  seasonId: string;
  seasonLabel: string;
  competitionName: string;
  number: number;
  position: PlayerPosition;
  games: number;
  goals: number;
  assists: number;
  points: number;
  penaltyMinutes: number;
  savePercentage?: number | null;
  goalsAgainstAverage?: number | null;
}

export interface MatchesQuery {
  competitionId?: string;
  seasonId?: string;
  status?: MatchStatus;
  teamId?: string;
}

export function playerFullName(p: Player) {
  return `${p.firstName} ${p.lastName}`;
}

export function playerShortName(p: Player) {
  return `${p.firstName.charAt(0)}. ${p.lastName}`;
}

export function matchScoreText(m: Match) {
  return `${m.homeScore}:${m.awayScore}`;
}

export function positionLabel(pos: PlayerPosition) {
  switch (pos) {
    case "forward":
      return "útočník";
    case "defenseman":
      return "obránce";
    case "goalie":
      return "brankář";
  }
}

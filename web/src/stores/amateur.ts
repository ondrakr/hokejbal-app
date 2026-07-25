"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";
import type { PlayerPosition } from "@/lib/types";

export type AmateurTournamentStatus = "draft" | "active" | "finished";
export type AmateurTournamentFormat =
  | "roundRobin"
  | "roundRobinAndPlayoff"
  | "singleElimination"
  | "bestOfSeries";
export type AmateurMatchPhase = "group" | "playoff";
export type AmateurMatchStatus = "scheduled" | "live" | "finished";
export type AmateurEventKind = "goal" | "penalty";

export type AmateurMatchFormat = {
  periodCount: number;
  periodLengthMinutes: number;
  overtimeEnabled: boolean;
};

export type AmateurTournament = {
  id: string;
  name: string;
  location: string;
  startDate: string;
  endDate: string;
  status: AmateurTournamentStatus;
  notes: string;
  createdAt: string;
  format: AmateurTournamentFormat;
  homeAndAway: boolean;
  playoffTeamCount: number;
  seriesLength: number;
  matchFormat: AmateurMatchFormat;
  scheduleGenerated: boolean;
};

export type AmateurTeam = {
  id: string;
  tournamentId: string;
  name: string;
  shortName: string;
  city: string;
  primaryColorHex: string;
  logoInitials: string;
};

export type AmateurPlayer = {
  id: string;
  teamId: string;
  firstName: string;
  lastName: string;
  number: number;
  position: PlayerPosition;
};

export type AmateurMatchEvent = {
  id: string;
  kind: AmateurEventKind;
  minute: number;
  second: number;
  period: number;
  teamId: string;
  playerId?: string;
  assistIds: string[];
  description: string;
  penaltyMinutes: number;
  penaltyReason: string;
};

export type AmateurMatch = {
  id: string;
  tournamentId: string;
  homeTeamId: string;
  awayTeamId: string;
  scheduledAt: string;
  status: AmateurMatchStatus;
  homeScore: number;
  awayScore: number;
  homeShots: number;
  awayShots: number;
  phase: AmateurMatchPhase;
  round: number;
  roundName: string;
  venue: string;
  events: AmateurMatchEvent[];
  seriesId?: string;
  seriesGameIndex?: number;
};

export type AmateurStandingRow = {
  teamId: string;
  played: number;
  wins: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
  points: number;
};

type PersistPayload = {
  tournaments: AmateurTournament[];
  teams: AmateurTeam[];
  players: AmateurPlayer[];
  matches: AmateurMatch[];
};

const KEY = "hb.amateur.v2";
const BYE = "__BYE__";
const STANDARD_MATCH_FORMAT: AmateurMatchFormat = {
  periodCount: 3,
  periodLengthMinutes: 15,
  overtimeEnabled: true,
};

const listeners = new Set<() => void>();
let state: PersistPayload = {
  tournaments: [],
  teams: [],
  players: [],
  matches: [],
};
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  state = readJSON<PersistPayload>(KEY, {
    tournaments: [],
    teams: [],
    players: [],
    matches: [],
  });
  hydrated = true;
}

function persist() {
  writeJSON(KEY, state);
  emit();
}

function uid() {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `id_${Math.random().toString(36).slice(2, 11)}`;
}

function trim(s: string) {
  return s.trim();
}

export function matchFormatLabel(f: AmateurMatchFormat) {
  const ot = f.overtimeEnabled ? " · prodl." : "";
  return `${f.periodCount}× ${f.periodLengthMinutes} min${ot}`;
}

export function matchFormatMaxPeriod(f: AmateurMatchFormat) {
  return f.overtimeEnabled ? f.periodCount + 1 : f.periodCount;
}

export function formatLabel(f: AmateurTournamentFormat) {
  switch (f) {
    case "roundRobin":
      return "Jen základní část";
    case "roundRobinAndPlayoff":
      return "Základní část + play-off";
    case "singleElimination":
      return "Jen play-off (vyřazovací)";
    case "bestOfSeries":
      return "Play-off na více vítězných";
  }
}

export function formatDetail(f: AmateurTournamentFormat) {
  switch (f) {
    case "roundRobin":
      return "Každý s každým. Tabulka podle bodů.";
    case "roundRobinAndPlayoff":
      return "Nejdřív základní část, pak vyřazovací play-off.";
    case "singleElimination":
      return "Jednozápasové vyřazování od 1. kola po finále.";
    case "bestOfSeries":
      return "Vyřazovací série (best-of 3 / 5 / 7).";
  }
}

export function formatHasGroupStage(f: AmateurTournamentFormat) {
  return f === "roundRobin" || f === "roundRobinAndPlayoff";
}

export function formatHasPlayoff(f: AmateurTournamentFormat) {
  return f !== "roundRobin";
}

export function formatUsesSeries(f: AmateurTournamentFormat) {
  return f === "bestOfSeries";
}

export function statusLabel(s: AmateurTournamentStatus) {
  switch (s) {
    case "draft":
      return "Příprava";
    case "active":
      return "Probíhá";
    case "finished":
      return "Ukončen";
  }
}

export function matchStatusLabel(s: AmateurMatchStatus) {
  switch (s) {
    case "scheduled":
      return "Naplánován";
    case "live":
      return "LIVE";
    case "finished":
      return "Konec";
  }
}

export function phaseLabel(p: AmateurMatchPhase) {
  return p === "group" ? "Základní část" : "Play-off";
}

export function matchPhaseLabel(m: AmateurMatch) {
  if (m.seriesGameIndex != null && m.seriesGameIndex > 0) {
    return `${m.roundName} · zápas ${m.seriesGameIndex}`;
  }
  return m.roundName || phaseLabel(m.phase);
}

export function playerFullName(p: AmateurPlayer) {
  return `${p.firstName} ${p.lastName}`;
}

export function playerShortName(p: AmateurPlayer) {
  return `${p.firstName.slice(0, 1)}. ${p.lastName}`;
}

export function eventClockLabel(e: AmateurMatchEvent) {
  return `${e.period}. · ${String(e.minute).padStart(2, "0")}:${String(e.second).padStart(2, "0")}`;
}

export function dateRangeLabel(t: AmateurTournament) {
  const start = new Date(t.startDate);
  const end = new Date(t.endDate);
  const fmt = new Intl.DateTimeFormat("cs-CZ", { day: "numeric", month: "numeric" });
  const sameDay =
    start.getFullYear() === end.getFullYear() &&
    start.getMonth() === end.getMonth() &&
    start.getDate() === end.getDate();
  if (sameDay) return fmt.format(start);
  return `${fmt.format(start)} – ${fmt.format(end)}`;
}

export function seriesWinsNeeded(seriesLength: number) {
  return Math.max(1, Math.floor(seriesLength / 2) + 1);
}

function normalizedPlayoffCount(value: number) {
  const allowed = [2, 4, 8, 16];
  return allowed.reduce((best, n) =>
    Math.abs(n - value) < Math.abs(best - value) ? n : best
  );
}

function normalizedSeriesLength(value: number) {
  const allowed = [1, 3, 5, 7];
  return allowed.reduce((best, n) =>
    Math.abs(n - value) < Math.abs(best - value) ? n : best
  );
}

function playoffRoundName(teamCount: number) {
  switch (teamCount) {
    case 2:
      return "Finále";
    case 4:
      return "Semifinále";
    case 8:
      return "Čtvrtfinále";
    case 16:
      return "Osmifinále";
    default:
      return `Play-off (${teamCount})`;
  }
}

function padToPowerOfTwo(seeds: string[]) {
  const result = [...seeds];
  let size = 1;
  while (size < Math.max(2, result.length)) size *= 2;
  while (result.length < size) result.push(BYE);
  const n = result.length;
  const ordered: string[] = [];
  for (let i = 0; i < n / 2; i++) {
    ordered.push(result[i]);
    ordered.push(result[n - 1 - i]);
  }
  return ordered;
}

/** Circle method — každé kolo je seznam [home, away]. */
function roundRobinRounds(teamIds: string[]): [string, string][][] {
  const teams = [...teamIds];
  if (teams.length % 2 === 1) teams.push(BYE);
  const n = teams.length;
  const roundCount = n - 1;
  let arr = [...teams];
  const rounds: [string, string][][] = [];
  for (let r = 0; r < roundCount; r++) {
    const pairs: [string, string][] = [];
    for (let i = 0; i < n / 2; i++) {
      const a = arr[i];
      const b = arr[n - 1 - i];
      if (a === BYE || b === BYE) continue;
      if (r % 2 === 0) pairs.push([a, b]);
      else pairs.push([b, a]);
    }
    rounds.push(pairs);
    const fixed = arr[0];
    const rotated = arr.slice(1);
    arr = [fixed, rotated[rotated.length - 1], ...rotated.slice(0, -1)];
  }
  return rounds;
}

function positionRank(p: PlayerPosition) {
  switch (p) {
    case "goalie":
      return 0;
    case "defenseman":
      return 1;
    case "forward":
      return 2;
  }
}

function applyStanding(
  row: AmateurStandingRow,
  gf: number,
  ga: number
): AmateurStandingRow {
  const win = gf > ga;
  return {
    teamId: row.teamId,
    played: row.played + 1,
    wins: row.wins + (win ? 1 : 0),
    losses: row.losses + (win ? 0 : 1),
    goalsFor: row.goalsFor + gf,
    goalsAgainst: row.goalsAgainst + ga,
    points: row.points + (win ? 3 : 0),
  };
}

function sortEvents(events: AmateurMatchEvent[]) {
  return [...events].sort((lhs, rhs) => {
    if (lhs.period !== rhs.period) return lhs.period - rhs.period;
    if (lhs.minute !== rhs.minute) return lhs.minute - rhs.minute;
    return lhs.second - rhs.second;
  });
}

function setAtHour(dateIso: string, hour: number, minute: number) {
  const d = new Date(dateIso);
  d.setHours(hour, minute, 0, 0);
  return d;
}

function addMinutes(iso: string, minutes: number) {
  return new Date(new Date(iso).getTime() + minutes * 60_000).toISOString();
}

// ── Lookups (pure on state) ──────────────────────────────────────────

function getTournament(id: string) {
  return state.tournaments.find((t) => t.id === id);
}
function getTeam(id: string) {
  return state.teams.find((t) => t.id === id);
}
function getPlayer(id: string) {
  return state.players.find((p) => p.id === id);
}
function getMatch(id: string) {
  return state.matches.find((m) => m.id === id);
}

function teamsIn(tournamentId: string) {
  return state.teams
    .filter((t) => t.tournamentId === tournamentId)
    .sort((a, b) => a.name.localeCompare(b.name, "cs"));
}

function playersInTeam(teamId: string) {
  return state.players
    .filter((p) => p.teamId === teamId)
    .sort((a, b) => {
      if (a.position !== b.position) return positionRank(a.position) - positionRank(b.position);
      return a.number - b.number;
    });
}

function matchesIn(tournamentId: string) {
  return state.matches
    .filter((m) => m.tournamentId === tournamentId)
    .sort((a, b) => new Date(a.scheduledAt).getTime() - new Date(b.scheduledAt).getTime());
}

function standingsFor(tournamentId: string): AmateurStandingRow[] {
  const teams = teamsIn(tournamentId);
  const tournament = getTournament(tournamentId);
  const map = new Map<string, AmateurStandingRow>();
  for (const t of teams) {
    map.set(t.id, {
      teamId: t.id,
      played: 0,
      wins: 0,
      losses: 0,
      goalsFor: 0,
      goalsAgainst: 0,
      points: 0,
    });
  }
  for (const match of matchesIn(tournamentId)) {
    if (match.status !== "finished") continue;
    if (tournament && formatHasGroupStage(tournament.format) && match.phase === "playoff") {
      continue;
    }
    const home = map.get(match.homeTeamId);
    const away = map.get(match.awayTeamId);
    if (!home || !away) continue;
    map.set(match.homeTeamId, applyStanding(home, match.homeScore, match.awayScore));
    map.set(match.awayTeamId, applyStanding(away, match.awayScore, match.homeScore));
  }
  return [...map.values()].sort((a, b) => {
    if (a.points !== b.points) return b.points - a.points;
    const ad = a.goalsFor - a.goalsAgainst;
    const bd = b.goalsFor - b.goalsAgainst;
    if (ad !== bd) return bd - ad;
    return b.goalsFor - a.goalsFor;
  });
}

function seriesWinner(games: AmateurMatch[], winsNeeded: number): string | null {
  const sorted = [...games].sort(
    (a, b) => (a.seriesGameIndex ?? 0) - (b.seriesGameIndex ?? 0)
  );
  const first = sorted[0];
  if (!first) return null;
  const a = first.homeTeamId;
  const b = first.awayTeamId;
  let homeWins = 0;
  let awayWins = 0;
  for (const g of games) {
    if (g.status !== "finished") continue;
    if (g.homeScore === g.awayScore) continue;
    const winner = g.homeScore > g.awayScore ? g.homeTeamId : g.awayTeamId;
    if (winner === a) homeWins += 1;
    else if (winner === b) awayWins += 1;
  }
  if (homeWins >= winsNeeded) return a;
  if (awayWins >= winsNeeded) return b;
  if (winsNeeded === 1) {
    const g = games[0];
    if (g && g.status === "finished" && g.homeScore !== g.awayScore) {
      return g.homeScore > g.awayScore ? g.homeTeamId : g.awayTeamId;
    }
  }
  return null;
}

// ── Mutations ────────────────────────────────────────────────────────

function createTournament(input: {
  name: string;
  location: string;
  startDate?: string;
  endDate?: string;
  notes?: string;
  format?: AmateurTournamentFormat;
  matchFormat?: AmateurMatchFormat;
  homeAndAway?: boolean;
  playoffTeamCount?: number;
  seriesLength?: number;
}): AmateurTournament {
  const start = input.startDate ?? new Date().toISOString();
  const t: AmateurTournament = {
    id: uid(),
    name: trim(input.name),
    location: trim(input.location),
    startDate: start,
    endDate: input.endDate ?? start,
    status: "draft",
    notes: input.notes ?? "",
    createdAt: new Date().toISOString(),
    format: input.format ?? "roundRobinAndPlayoff",
    matchFormat: input.matchFormat ?? { ...STANDARD_MATCH_FORMAT },
    homeAndAway: input.homeAndAway ?? false,
    playoffTeamCount: normalizedPlayoffCount(input.playoffTeamCount ?? 4),
    seriesLength: normalizedSeriesLength(input.seriesLength ?? 1),
    scheduleGenerated: false,
  };
  state = { ...state, tournaments: [t, ...state.tournaments] };
  persist();
  return t;
}

function updateTournament(tournament: AmateurTournament) {
  state = {
    ...state,
    tournaments: state.tournaments.map((t) => (t.id === tournament.id ? tournament : t)),
  };
  persist();
}

function deleteTournament(id: string) {
  const teamIds = new Set(state.teams.filter((t) => t.tournamentId === id).map((t) => t.id));
  state = {
    tournaments: state.tournaments.filter((t) => t.id !== id),
    teams: state.teams.filter((t) => t.tournamentId !== id),
    players: state.players.filter((p) => !teamIds.has(p.teamId)),
    matches: state.matches.filter((m) => m.tournamentId !== id),
  };
  persist();
}

function addTeam(
  tournamentId: string,
  name: string,
  shortName: string,
  city: string,
  colorHex: string
): AmateurTeam {
  const trimmedName = trim(name);
  const trimmedShort = trim(shortName);
  const short = trimmedShort || trimmedName.slice(0, 8);
  const initials = (short || trimmedName).slice(0, 2).toUpperCase();
  const team: AmateurTeam = {
    id: uid(),
    tournamentId,
    name: trimmedName,
    shortName: short,
    city,
    primaryColorHex: colorHex || "C92A2A",
    logoInitials: initials,
  };
  state = { ...state, teams: [...state.teams, team] };
  persist();
  return team;
}

function updateTeam(team: AmateurTeam) {
  state = {
    ...state,
    teams: state.teams.map((t) => (t.id === team.id ? team : t)),
  };
  persist();
}

function deleteTeam(id: string) {
  state = {
    ...state,
    teams: state.teams.filter((t) => t.id !== id),
    players: state.players.filter((p) => p.teamId !== id),
    matches: state.matches.filter((m) => m.homeTeamId !== id && m.awayTeamId !== id),
  };
  persist();
}

function addPlayer(
  teamId: string,
  firstName: string,
  lastName: string,
  number: number,
  position: PlayerPosition
): AmateurPlayer {
  const p: AmateurPlayer = {
    id: uid(),
    teamId,
    firstName: trim(firstName),
    lastName: trim(lastName),
    number,
    position,
  };
  state = { ...state, players: [...state.players, p] };
  persist();
  return p;
}

function updatePlayer(player: AmateurPlayer) {
  state = {
    ...state,
    players: state.players.map((p) => (p.id === player.id ? player : p)),
  };
  persist();
}

function deletePlayer(id: string) {
  state = { ...state, players: state.players.filter((p) => p.id !== id) };
  persist();
}

function addMatch(input: {
  tournamentId: string;
  homeTeamId: string;
  awayTeamId: string;
  scheduledAt: string;
  round: number;
  venue: string;
  phase?: AmateurMatchPhase;
  roundName?: string;
  seriesId?: string;
  seriesGameIndex?: number;
}): AmateurMatch {
  const phase = input.phase ?? "group";
  let roundName = input.roundName ?? "";
  if (!roundName) {
    roundName = phase === "group" ? `Kolo ${input.round}` : phaseLabel(phase);
  }
  const m: AmateurMatch = {
    id: uid(),
    tournamentId: input.tournamentId,
    homeTeamId: input.homeTeamId,
    awayTeamId: input.awayTeamId,
    scheduledAt: input.scheduledAt,
    status: "scheduled",
    homeScore: 0,
    awayScore: 0,
    homeShots: 0,
    awayShots: 0,
    round: input.round,
    venue: input.venue,
    events: [],
    phase,
    roundName,
    seriesId: input.seriesId,
    seriesGameIndex: input.seriesGameIndex,
  };
  state = { ...state, matches: [...state.matches, m] };
  persist();
  return m;
}

function updateMatch(match: AmateurMatch) {
  state = {
    ...state,
    matches: state.matches.map((m) => (m.id === match.id ? match : m)),
  };
  persist();
}

function deleteMatch(id: string) {
  state = { ...state, matches: state.matches.filter((m) => m.id !== id) };
  persist();
}

function setMatchStatus(id: string, status: AmateurMatchStatus) {
  const match = getMatch(id);
  if (!match) return;
  updateMatch({ ...match, status });
}

function setShots(matchId: string, home: number, away: number) {
  const match = getMatch(matchId);
  if (!match) return;
  updateMatch({
    ...match,
    homeShots: Math.max(0, home),
    awayShots: Math.max(0, away),
  });
}

function addGoalEvent(input: {
  matchId: string;
  teamId: string;
  playerId?: string;
  assistIds: string[];
  period: number;
  minute: number;
  second: number;
  description?: string;
}) {
  const match = getMatch(input.matchId);
  if (!match) return;
  const event: AmateurMatchEvent = {
    id: uid(),
    kind: "goal",
    teamId: input.teamId,
    playerId: input.playerId,
    assistIds: input.assistIds,
    period: input.period,
    minute: input.minute,
    second: input.second,
    penaltyMinutes: 0,
    penaltyReason: "",
    description: input.description ?? "",
  };
  let next = {
    ...match,
    events: sortEvents([...match.events, event]),
  };
  if (input.teamId === match.homeTeamId) next = { ...next, homeScore: match.homeScore + 1 };
  else if (input.teamId === match.awayTeamId) next = { ...next, awayScore: match.awayScore + 1 };
  if (match.status === "scheduled") next = { ...next, status: "live" };
  updateMatch(next);
}

function addPenaltyEvent(input: {
  matchId: string;
  teamId: string;
  playerId?: string;
  minutes: number;
  reason: string;
  period: number;
  minute: number;
  second: number;
}) {
  const match = getMatch(input.matchId);
  if (!match) return;
  const event: AmateurMatchEvent = {
    id: uid(),
    kind: "penalty",
    teamId: input.teamId,
    playerId: input.playerId,
    assistIds: [],
    period: input.period,
    minute: input.minute,
    second: input.second,
    penaltyMinutes: input.minutes,
    penaltyReason: input.reason,
    description: input.reason,
  };
  let next = {
    ...match,
    events: sortEvents([...match.events, event]),
  };
  if (match.status === "scheduled") next = { ...next, status: "live" };
  updateMatch(next);
}

function removeEvent(matchId: string, eventId: string) {
  const match = getMatch(matchId);
  if (!match) return;
  const event = match.events.find((e) => e.id === eventId);
  if (!event) return;
  let next: AmateurMatch = {
    ...match,
    events: match.events.filter((e) => e.id !== eventId),
  };
  if (event.kind === "goal") {
    if (event.teamId === match.homeTeamId) {
      next = { ...next, homeScore: Math.max(0, match.homeScore - 1) };
    } else if (event.teamId === match.awayTeamId) {
      next = { ...next, awayScore: Math.max(0, match.awayScore - 1) };
    }
  }
  updateMatch(next);
}

function appendRoundRobin(
  tournamentId: string,
  teamIds: string[],
  homeAndAway: boolean,
  venue: string,
  slotRef: { current: string }
) {
  const gapMin = 90;
  const rounds = roundRobinRounds(teamIds);
  rounds.forEach((pairs, index) => {
    const roundNumber = index + 1;
    for (const [home, away] of pairs) {
      addMatch({
        tournamentId,
        homeTeamId: home,
        awayTeamId: away,
        scheduledAt: slotRef.current,
        round: roundNumber,
        venue,
        phase: "group",
        roundName: `Kolo ${roundNumber}`,
      });
      slotRef.current = addMinutes(slotRef.current, gapMin);
    }
  });
  if (homeAndAway) {
    const returnRounds = roundRobinRounds(teamIds);
    const offset = rounds.length;
    returnRounds.forEach((pairs, index) => {
      const roundNumber = offset + index + 1;
      for (const [home, away] of pairs) {
        addMatch({
          tournamentId,
          homeTeamId: away,
          awayTeamId: home,
          scheduledAt: slotRef.current,
          round: roundNumber,
          venue,
          phase: "group",
          roundName: `Kolo ${roundNumber}`,
        });
        slotRef.current = addMinutes(slotRef.current, gapMin);
      }
    });
  }
}

function appendPlayoffBracket(
  tournamentId: string,
  seeds: string[],
  seriesLength: number,
  venue: string,
  slotRef: { current: string },
  round = 1
) {
  if (seeds.length < 2) return;
  const roundTeams = padToPowerOfTwo(seeds);
  const name = playoffRoundName(roundTeams.length);
  const gamesPerSeries = Math.max(1, seriesLength);
  for (let i = 0; i + 1 < roundTeams.length; i += 2) {
    const home = roundTeams[i];
    const away = roundTeams[i + 1];
    if (home === BYE || away === BYE) continue;
    const seriesId = uid();
    for (let game = 1; game <= gamesPerSeries; game++) {
      const homeId = game % 2 === 1 ? home : away;
      const awayId = game % 2 === 1 ? away : home;
      addMatch({
        tournamentId,
        homeTeamId: homeId,
        awayTeamId: awayId,
        scheduledAt: slotRef.current,
        round,
        venue,
        phase: "playoff",
        roundName: name,
        seriesId: gamesPerSeries > 1 ? seriesId : undefined,
        seriesGameIndex: gamesPerSeries > 1 ? game : undefined,
      });
      slotRef.current = addMinutes(slotRef.current, 90);
    }
  }
}

function canGenerateSchedule(tournamentId: string) {
  return teamsIn(tournamentId).length >= 2;
}

function generateSchedule(tournamentId: string, replaceExisting = true): boolean {
  const tournament = getTournament(tournamentId);
  if (!tournament) return false;
  const teamList = teamsIn(tournamentId);
  if (teamList.length < 2) return false;

  if (replaceExisting) {
    state = {
      ...state,
      matches: state.matches.filter((m) => m.tournamentId !== tournamentId),
    };
  } else if (state.matches.some((m) => m.tournamentId === tournamentId)) {
    return false;
  }

  const venue = tournament.location;
  const slotRef = {
    current: setAtHour(tournament.startDate, 9, 0).toISOString(),
  };
  const ids = teamList.map((t) => t.id);

  switch (tournament.format) {
    case "roundRobin":
    case "roundRobinAndPlayoff":
      appendRoundRobin(tournamentId, ids, tournament.homeAndAway, venue, slotRef);
      break;
    case "singleElimination":
      appendPlayoffBracket(tournamentId, ids, 1, venue, slotRef);
      break;
    case "bestOfSeries":
      appendPlayoffBracket(
        tournamentId,
        ids,
        normalizedSeriesLength(tournament.seriesLength),
        venue,
        slotRef
      );
      break;
  }

  updateTournament({
    ...getTournament(tournamentId)!,
    scheduleGenerated: true,
    status: "active",
  });
  return true;
}

function generatePlayoffFromStandings(tournamentId: string): boolean {
  const tournament = getTournament(tournamentId);
  if (!tournament || tournament.format !== "roundRobinAndPlayoff") return false;
  const table = standingsFor(tournamentId);
  const count = normalizedPlayoffCount(Math.min(tournament.playoffTeamCount, table.length));
  if (count < 2) return false;
  const seeds = table.slice(0, count).map((r) => r.teamId);

  state = {
    ...state,
    matches: state.matches.filter(
      (m) => !(m.tournamentId === tournamentId && m.phase === "playoff")
    ),
  };

  const existing = matchesIn(tournamentId);
  const maxAt = existing.reduce(
    (max, m) => Math.max(max, new Date(m.scheduledAt).getTime()),
    new Date(tournament.startDate).getTime()
  );
  const slotRef = { current: new Date(maxAt + 90 * 60_000).toISOString() };
  appendPlayoffBracket(tournamentId, seeds, 1, tournament.location, slotRef);
  updateTournament({
    ...getTournament(tournamentId)!,
    scheduleGenerated: true,
  });
  return true;
}

function generateNextPlayoffRound(tournamentId: string): boolean {
  const tournament = getTournament(tournamentId);
  if (!tournament || !formatHasPlayoff(tournament.format)) return false;
  const playoff = matchesIn(tournamentId).filter((m) => m.phase === "playoff");
  if (!playoff.length) return false;
  const currentRound = Math.max(...playoff.map((m) => m.round));
  const roundMatches = playoff.filter((m) => m.round === currentRound);
  const groups = new Map<string, AmateurMatch[]>();
  for (const m of roundMatches) {
    const key = m.seriesId ?? m.id;
    const list = groups.get(key) ?? [];
    list.push(m);
    groups.set(key, list);
  }
  const winners: string[] = [];
  const sortedGroups = [...groups.values()].sort((a, b) => {
    const at = a[0] ? new Date(a[0].scheduledAt).getTime() : 0;
    const bt = b[0] ? new Date(b[0].scheduledAt).getTime() : 0;
    return at - bt;
  });
  for (const games of sortedGroups) {
    const winner = seriesWinner(games, seriesWinsNeeded(tournament.seriesLength));
    if (!winner) return false;
    winners.push(winner);
  }
  if (winners.length < 2) return false;

  const maxAt = Math.max(...roundMatches.map((m) => new Date(m.scheduledAt).getTime()));
  const slotRef = { current: new Date(maxAt + 90 * 60_000).toISOString() };
  const nextName = playoffRoundName(winners.length);
  const gamesPerSeries = formatUsesSeries(tournament.format)
    ? normalizedSeriesLength(tournament.seriesLength)
    : 1;
  const venue = tournament.location;

  for (let i = 0; i + 1 < winners.length; i += 2) {
    const home = winners[i];
    const away = winners[i + 1];
    const seriesId = uid();
    for (let game = 1; game <= gamesPerSeries; game++) {
      const homeId = game % 2 === 1 ? home : away;
      const awayId = game % 2 === 1 ? away : home;
      addMatch({
        tournamentId,
        homeTeamId: homeId,
        awayTeamId: awayId,
        scheduledAt: slotRef.current,
        round: currentRound + 1,
        venue,
        phase: "playoff",
        roundName: nextName,
        seriesId: gamesPerSeries > 1 ? seriesId : undefined,
        seriesGameIndex: gamesPerSeries > 1 ? game : undefined,
      });
      slotRef.current = addMinutes(slotRef.current, 90);
    }
  }
  return true;
}

export function useAmateur() {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => {
      hydrate();
      return state;
    },
    () => state
  );

  useEffect(() => {
    hydrate();
    emit();
  }, []);

  return {
    tournaments: snap.tournaments,
    teams: snap.teams,
    players: snap.players,
    matches: snap.matches,

    tournament: useCallback((id: string) => getTournament(id), [snap]),
    team: useCallback((id: string) => getTeam(id), [snap]),
    player: useCallback((id: string) => getPlayer(id), [snap]),
    match: useCallback((id: string) => getMatch(id), [snap]),
    teamsIn: useCallback((tournamentId: string) => teamsIn(tournamentId), [snap]),
    playersInTeam: useCallback((teamId: string) => playersInTeam(teamId), [snap]),
    matchesIn: useCallback((tournamentId: string) => matchesIn(tournamentId), [snap]),
    standings: useCallback((tournamentId: string) => standingsFor(tournamentId), [snap]),
    dateRangeLabel,

    createTournament: useCallback(createTournament, []),
    updateTournament: useCallback(updateTournament, []),
    deleteTournament: useCallback(deleteTournament, []),
    addTeam: useCallback(addTeam, []),
    updateTeam: useCallback(updateTeam, []),
    deleteTeam: useCallback(deleteTeam, []),
    addPlayer: useCallback(addPlayer, []),
    updatePlayer: useCallback(updatePlayer, []),
    deletePlayer: useCallback(deletePlayer, []),
    addMatch: useCallback(addMatch, []),
    deleteMatch: useCallback(deleteMatch, []),
    updateMatch: useCallback(updateMatch, []),
    setMatchStatus: useCallback(setMatchStatus, []),
    setShots: useCallback(setShots, []),
    addGoalEvent: useCallback(addGoalEvent, []),
    addPenaltyEvent: useCallback(addPenaltyEvent, []),
    removeEvent: useCallback(removeEvent, []),
    generateSchedule: useCallback(generateSchedule, []),
    generatePlayoffFromStandings: useCallback(generatePlayoffFromStandings, []),
    generateNextPlayoffRound: useCallback(generateNextPlayoffRound, []),
    canGenerateSchedule: useCallback(canGenerateSchedule, [snap]),
  };
}

"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";

export type AmateurStatus = "draft" | "active" | "finished";
export type AmateurFormat =
  | "roundRobin"
  | "roundRobinAndPlayoff"
  | "singleElimination"
  | "bestOfSeries";

export type AmateurTeam = {
  id: string;
  name: string;
  shortName: string;
};

export type AmateurEvent = {
  id: string;
  kind: "goal" | "penalty";
  minute: number;
  teamId: string;
  playerName: string;
  description: string;
};

export type AmateurMatch = {
  id: string;
  tournamentId: string;
  homeTeamId: string;
  awayTeamId: string;
  scheduledAt: string;
  status: "scheduled" | "live" | "finished";
  homeScore: number;
  awayScore: number;
  homeShots: number;
  awayShots: number;
  round: number;
  venue: string;
  phase: "group" | "playoff";
  roundName: string;
  events: AmateurEvent[];
};

export type AmateurTournament = {
  id: string;
  name: string;
  location: string;
  startDate: string;
  endDate: string;
  status: AmateurStatus;
  notes: string;
  createdAt: string;
  format: AmateurFormat;
  homeAndAway: boolean;
  playoffTeamCount: number;
  teams: AmateurTeam[];
  matches: AmateurMatch[];
};

const KEY = "hb.amateur.v1";
const listeners = new Set<() => void>();
let tournaments: AmateurTournament[] = [];
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  tournaments = readJSON(KEY, []);
  hydrated = true;
}

function persist() {
  writeJSON(KEY, tournaments);
  emit();
}

function uid(prefix: string) {
  return `${prefix}_${Math.random().toString(36).slice(2, 10)}`;
}

function generateRoundRobin(teams: AmateurTeam[], tournamentId: string, homeAndAway: boolean) {
  const matches: AmateurMatch[] = [];
  let round = 1;
  for (let i = 0; i < teams.length; i++) {
    for (let j = i + 1; j < teams.length; j++) {
      matches.push({
        id: uid("am"),
        tournamentId,
        homeTeamId: teams[i].id,
        awayTeamId: teams[j].id,
        scheduledAt: new Date(Date.now() + round * 86400000).toISOString(),
        status: "scheduled",
        homeScore: 0,
        awayScore: 0,
        homeShots: 0,
        awayShots: 0,
        round,
        venue: "",
        phase: "group",
        roundName: `Kolo ${round}`,
        events: [],
      });
      if (homeAndAway) {
        matches.push({
          id: uid("am"),
          tournamentId,
          homeTeamId: teams[j].id,
          awayTeamId: teams[i].id,
          scheduledAt: new Date(Date.now() + (round + 50) * 86400000).toISOString(),
          status: "scheduled",
          homeScore: 0,
          awayScore: 0,
          homeShots: 0,
          awayShots: 0,
          round: round + 100,
          venue: "",
          phase: "group",
          roundName: `Odveta`,
          events: [],
        });
      }
      round += 1;
    }
  }
  return matches;
}

export function formatLabel(f: AmateurFormat) {
  switch (f) {
    case "roundRobin":
      return "Jen základní část";
    case "roundRobinAndPlayoff":
      return "Základní část + play-off";
    case "singleElimination":
      return "Jen play-off";
    case "bestOfSeries":
      return "Play-off série";
  }
}

export function statusLabel(s: AmateurStatus) {
  switch (s) {
    case "draft":
      return "Příprava";
    case "active":
      return "Probíhá";
    case "finished":
      return "Ukončen";
  }
}

export function useAmateur() {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => {
      hydrate();
      return tournaments;
    },
    () => tournaments
  );

  useEffect(() => {
    hydrate();
    emit();
  }, []);

  const createTournament = useCallback(
    (input: {
      name: string;
      location: string;
      format: AmateurFormat;
      homeAndAway: boolean;
      teamNames: string[];
    }) => {
      const id = uid("at");
      const teams = input.teamNames
        .map((n) => n.trim())
        .filter(Boolean)
        .map((name) => ({
          id: uid("tm"),
          name,
          shortName: name.slice(0, 3).toUpperCase(),
        }));
      const matches =
        input.format === "singleElimination" || input.format === "bestOfSeries"
          ? []
          : generateRoundRobin(teams, id, input.homeAndAway);
      const t: AmateurTournament = {
        id,
        name: input.name.trim() || "Turnaj",
        location: input.location.trim(),
        startDate: new Date().toISOString(),
        endDate: new Date(Date.now() + 7 * 86400000).toISOString(),
        status: "draft",
        notes: "",
        createdAt: new Date().toISOString(),
        format: input.format,
        homeAndAway: input.homeAndAway,
        playoffTeamCount: 4,
        teams,
        matches,
      };
      tournaments = [t, ...tournaments];
      persist();
      return t.id;
    },
    []
  );

  const updateTournament = useCallback((id: string, patch: Partial<AmateurTournament>) => {
    tournaments = tournaments.map((t) => (t.id === id ? { ...t, ...patch } : t));
    persist();
  }, []);

  const deleteTournament = useCallback((id: string) => {
    tournaments = tournaments.filter((t) => t.id !== id);
    persist();
  }, []);

  const updateMatch = useCallback((tournamentId: string, match: AmateurMatch) => {
    tournaments = tournaments.map((t) =>
      t.id === tournamentId
        ? { ...t, matches: t.matches.map((m) => (m.id === match.id ? match : m)) }
        : t
    );
    persist();
  }, []);

  const get = useCallback((id: string) => snap.find((t) => t.id === id), [snap]);

  return {
    tournaments: snap,
    get,
    createTournament,
    updateTournament,
    deleteTournament,
    updateMatch,
  };
}

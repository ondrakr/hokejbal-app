"use client";

import { useCallback, useEffect, useState, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";

const KEYS = {
  teams: "hb.favorites.teams",
  players: "hb.favorites.players",
  matches: "hb.favorites.matches",
  competitions: "hb.favorites.competitions",
};

type FavState = {
  teams: string[];
  players: string[];
  matches: string[];
  competitions: string[];
};

const listeners = new Set<() => void>();
let state: FavState = {
  teams: [],
  players: [],
  matches: [],
  competitions: [],
};
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  state = {
    teams: readJSON(KEYS.teams, []),
    players: readJSON(KEYS.players, []),
    matches: readJSON(KEYS.matches, []),
    competitions: readJSON(KEYS.competitions, []),
  };
  hydrated = true;
}

function persist() {
  writeJSON(KEYS.teams, state.teams);
  writeJSON(KEYS.players, state.players);
  writeJSON(KEYS.matches, state.matches);
  writeJSON(KEYS.competitions, state.competitions);
  emit();
}

function toggle(list: string[], id: string) {
  return list.includes(id) ? list.filter((x) => x !== id) : [...list, id];
}

export function useFavorites() {
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

  const toggleTeam = useCallback((id: string) => {
    state = { ...state, teams: toggle(state.teams, id) };
    persist();
  }, []);
  const togglePlayer = useCallback((id: string) => {
    state = { ...state, players: toggle(state.players, id) };
    persist();
  }, []);
  const toggleMatch = useCallback((id: string) => {
    state = { ...state, matches: toggle(state.matches, id) };
    persist();
  }, []);
  const toggleCompetition = useCallback((slug: string) => {
    state = { ...state, competitions: toggle(state.competitions, slug) };
    persist();
  }, []);

  return {
    ...snap,
    toggleTeam,
    togglePlayer,
    toggleMatch,
    toggleCompetition,
    isTeam: (id: string) => snap.teams.includes(id),
    isPlayer: (id: string) => snap.players.includes(id),
    isMatch: (id: string) => snap.matches.includes(id),
    isCompetition: (slug: string) => snap.competitions.includes(slug),
  };
}

export function useMounted() {
  const [m, setM] = useState(false);
  useEffect(() => setM(true), []);
  return m;
}

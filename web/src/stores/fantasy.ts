"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, readString, writeJSON, writeString } from "@/lib/storage";

export type FantasySlot = "G" | "D1" | "D2" | "F1" | "F2" | "F3";

export const FANTASY_SLOTS: FantasySlot[] = ["G", "D1", "D2", "F1", "F2", "F3"];
export const FANTASY_BUDGET = 100;
export const FANTASY_MAX_PER_CLUB = 2;

type FantasyState = {
  teamName: string;
  activeGameweek: number;
  viewingGameweek: number;
  wallet: number;
  seasonPoints: number;
  freeTransfers: number;
  lineups: Record<string, Partial<Record<FantasySlot, string>>>;
  scored: number[];
};

const KEYS = {
  teamName: "hb.fantasy.v3.teamName",
  lineups: "hb.fantasy.v3.lineups",
  activeGW: "hb.fantasy.v3.activeGW",
  wallet: "hb.fantasy.v3.wallet",
  points: "hb.fantasy.v3.points",
  scored: "hb.fantasy.v3.scored",
  ft: "hb.fantasy.v3.ft",
};

const listeners = new Set<() => void>();
let state: FantasyState = {
  teamName: "Můj tým",
  activeGameweek: 1,
  viewingGameweek: 1,
  wallet: FANTASY_BUDGET,
  seasonPoints: 0,
  freeTransfers: 1,
  lineups: {},
  scored: [],
};
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  state = {
    teamName: readString(KEYS.teamName, "Můj tým"),
    activeGameweek: Number(readString(KEYS.activeGW, "1")) || 1,
    viewingGameweek: Number(readString(KEYS.activeGW, "1")) || 1,
    wallet: Number(readString(KEYS.wallet, String(FANTASY_BUDGET))) || FANTASY_BUDGET,
    seasonPoints: Number(readString(KEYS.points, "0")) || 0,
    freeTransfers: Number(readString(KEYS.ft, "1")) || 1,
    lineups: readJSON(KEYS.lineups, {}),
    scored: readJSON(KEYS.scored, []),
  };
  hydrated = true;
}

function persist() {
  writeString(KEYS.teamName, state.teamName);
  writeString(KEYS.activeGW, String(state.activeGameweek));
  writeString(KEYS.wallet, String(state.wallet));
  writeString(KEYS.points, String(state.seasonPoints));
  writeString(KEYS.ft, String(state.freeTransfers));
  writeJSON(KEYS.lineups, state.lineups);
  writeJSON(KEYS.scored, state.scored);
  emit();
}

export function playerPrice(points: number, position: string) {
  const base = position === "goalie" ? 6.5 : position === "defenseman" ? 5.5 : 7;
  return Math.round((base + Math.min(points, 40) * 0.15) * 10) / 10;
}

export function useFantasy() {
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

  const setTeamName = useCallback((name: string) => {
    state = { ...state, teamName: name };
    persist();
  }, []);

  const setViewingGameweek = useCallback((gw: number) => {
    state = { ...state, viewingGameweek: gw };
    emit();
  }, []);

  const lineupFor = useCallback(
    (gw = snap.viewingGameweek) => snap.lineups[String(gw)] ?? {},
    [snap.lineups, snap.viewingGameweek]
  );

  const setSlot = useCallback((slot: FantasySlot, playerId: string | null, price: number) => {
    const gw = String(state.viewingGameweek);
    const current = { ...(state.lineups[gw] ?? {}) };
    const prevId = current[slot];
    let wallet = state.wallet;
    if (prevId) wallet += price; // simplified refund uses same price param for selected
    if (playerId) {
      current[slot] = playerId;
      wallet -= price;
    } else {
      delete current[slot];
    }
    state = {
      ...state,
      wallet: Math.round(wallet * 10) / 10,
      lineups: { ...state.lineups, [gw]: current },
    };
    persist();
  }, []);

  const clearLineup = useCallback(() => {
    const gw = String(state.viewingGameweek);
    state = { ...state, wallet: FANTASY_BUDGET, lineups: { ...state.lineups, [gw]: {} } };
    persist();
  }, []);

  const filledCount = Object.keys(lineupFor()).length;

  return {
    ...snap,
    budget: FANTASY_BUDGET,
    filledCount,
    lineupFor,
    setTeamName,
    setViewingGameweek,
    setSlot,
    clearLineup,
  };
}

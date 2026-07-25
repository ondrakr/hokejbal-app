"use client";

import { useCallback, useEffect, useMemo, useSyncExternalStore } from "react";
import type { Match, Player, PlayerPosition } from "@/lib/types";
import { readJSON, readString, writeJSON, writeString } from "@/lib/storage";

export type FantasySlot = "G" | "D1" | "D2" | "F1" | "F2" | "F3";

export const FANTASY_SLOTS: FantasySlot[] = ["G", "D1", "D2", "F1", "F2", "F3"];
export const FANTASY_BUDGET = 100;
export const FANTASY_MAX_PER_CLUB = 2;
export const FANTASY_SQUAD_SIZE = FANTASY_SLOTS.length;

export type FantasyCardTier = "bronze" | "silver" | "gold" | "elite";

type LineupMap = Partial<Record<FantasySlot, string>>;
type LineupsByGW = Record<string, LineupMap>;

type FantasyState = {
  teamName: string;
  activeGameweek: number;
  viewingGameweek: number;
  wallet: number;
  seasonPoints: number;
  freeTransfers: number;
  /** Draft sestavy po kolech (editace před uložením). */
  lineups: LineupsByGW;
  /** Uložené sestavy po kolech. */
  saved: LineupsByGW;
  scored: number[];
  lastSaveMessage: string | null;
};

const KEYS = {
  teamName: "hb.fantasy.v3.teamName",
  lineups: "hb.fantasy.v3.lineups",
  saved: "hb.fantasy.v3.saved",
  activeGW: "hb.fantasy.v3.activeGW",
  wallet: "hb.fantasy.v3.wallet",
  points: "hb.fantasy.v3.points",
  scored: "hb.fantasy.v3.scored",
  ft: "hb.fantasy.v3.ft",
};

const SLOT_POSITION: Record<FantasySlot, PlayerPosition> = {
  G: "goalie",
  D1: "defenseman",
  D2: "defenseman",
  F1: "forward",
  F2: "forward",
  F3: "forward",
};

const SLOT_TITLE: Record<FantasySlot, string> = {
  G: "Brankář",
  D1: "Obránce 1",
  D2: "Obránce 2",
  F1: "Útočník 1",
  F2: "Útočník 2",
  F3: "Útočník 3",
};

const listeners = new Set<() => void>();
let state: FantasyState = {
  teamName: "Můj Fantasy tým",
  activeGameweek: 1,
  viewingGameweek: 1,
  wallet: 0,
  seasonPoints: 0,
  freeTransfers: 99,
  lineups: {},
  saved: {},
  scored: [],
  lastSaveMessage: null,
};
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  const lineups = readJSON<LineupsByGW>(KEYS.lineups, {});
  const savedRaw = readJSON<LineupsByGW>(KEYS.saved, {});
  const saved = Object.keys(savedRaw).length ? savedRaw : { ...lineups };
  const activeGW = Number(readString(KEYS.activeGW, "1")) || 1;
  state = {
    teamName: readString(KEYS.teamName, "Můj Fantasy tým"),
    activeGameweek: activeGW,
    viewingGameweek: activeGW,
    wallet: Number(readString(KEYS.wallet, "0")) || 0,
    seasonPoints: Number(readString(KEYS.points, "0")) || 0,
    freeTransfers: Number(readString(KEYS.ft, "99")) || 99,
    lineups,
    saved,
    scored: readJSON(KEYS.scored, []),
    lastSaveMessage: null,
  };
  hydrated = true;
}

function persistMeta() {
  writeString(KEYS.teamName, state.teamName);
  writeString(KEYS.activeGW, String(state.activeGameweek));
  writeString(KEYS.wallet, String(state.wallet));
  writeString(KEYS.points, String(state.seasonPoints));
  writeString(KEYS.ft, String(state.freeTransfers));
  writeJSON(KEYS.scored, state.scored);
}

function persistDraft() {
  writeJSON(KEYS.lineups, state.lineups);
}

function persistSaved() {
  writeJSON(KEYS.saved, state.saved);
}

function lineupEqual(a: LineupMap, b: LineupMap) {
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    if (a[k as FantasySlot] !== b[k as FantasySlot]) return false;
  }
  return true;
}

/** FIFA-like rating 55…94 — viz FantasyRules.rating. */
export function playerRating(player: Player): number {
  let value: number;
  if (player.position === "goalie") {
    const save = player.savePercentage ?? 88;
    const gaa = player.goalsAgainstAverage ?? 3.2;
    value = 62 + (save - 86) * 2.2 + player.games * 0.35 - (gaa - 2.5) * 3;
  } else if (player.position === "defenseman") {
    const ppg = player.games > 0 ? player.points / player.games : 0;
    value = 58 + ppg * 18 + player.goals * 0.8 + player.games * 0.25;
  } else {
    const ppg = player.games > 0 ? player.points / player.games : 0;
    value = 58 + ppg * 20 + player.goals * 1.1 + player.games * 0.2;
  }
  return Math.min(94, Math.max(55, Math.round(value)));
}

export function tierForRating(rating: number): FantasyCardTier {
  if (rating < 65) return "bronze";
  if (rating < 75) return "silver";
  if (rating < 85) return "gold";
  return "elite";
}

export function tierLabel(ratingOrTier: number | FantasyCardTier): string {
  const tier = typeof ratingOrTier === "number" ? tierForRating(ratingOrTier) : ratingOrTier;
  switch (tier) {
    case "bronze":
      return "Bronze";
    case "silver":
      return "Silver";
    case "gold":
      return "Gold";
    case "elite":
      return "Elite";
  }
}

/** Cena v kreditech 4…15 podle ratingu. */
export function playerPrice(player: Player): number {
  const r = playerRating(player);
  const raw = 4 + (r - 55) * (11 / 39);
  return Math.min(15, Math.max(4, Math.round(raw)));
}

export function fantasyPoints(player: Player): number {
  if (player.position === "goalie") {
    const saveBonus = Math.floor(((player.savePercentage ?? 88) - 85) * 2);
    return Math.max(0, player.games * 2 + saveBonus - Math.floor(player.penaltyMinutes / 4));
  }
  return Math.max(
    0,
    player.goals * 3 + player.assists * 2 + Math.floor(player.games / 2) - Math.floor(player.penaltyMinutes / 5)
  );
}

export function nextFantasyFixture(teamId: string, matches: Match[], after = new Date()): Match | undefined {
  const threshold = after.getTime() - 3 * 3600_000;
  return matches
    .filter((m) => m.homeTeamId === teamId || m.awayTeamId === teamId)
    .filter((m) => m.status === "scheduled" || m.status === "live")
    .filter((m) => new Date(m.scheduledAt).getTime() >= threshold)
    .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt))[0];
}

export function slotPosition(slot: FantasySlot): PlayerPosition {
  return SLOT_POSITION[slot];
}

export function slotTitle(slot: FantasySlot): string {
  return SLOT_TITLE[slot];
}

function spentCreditsFor(lineup: LineupMap, playersById: Map<string, Player> | Record<string, Player>) {
  const get =
    playersById instanceof Map
      ? (id: string) => playersById.get(id)
      : (id: string) => playersById[id];
  return Object.values(lineup)
    .filter(Boolean)
    .reduce((sum, id) => {
      const p = get(id!);
      return sum + (p ? playerPrice(p) : 0);
    }, 0);
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
    persistMeta();
    emit();
  }, []);

  const setViewingGameweek = useCallback((gw: number) => {
    state = { ...state, viewingGameweek: Math.max(1, gw) };
    emit();
  }, []);

  const lineupFor = useCallback(
    (gw = snap.viewingGameweek) => {
      const key = String(gw);
      return snap.lineups[key] ?? snap.lineups[String(snap.activeGameweek)] ?? {};
    },
    [snap.lineups, snap.viewingGameweek, snap.activeGameweek]
  );

  /** Minulé kolo je jen ke čtení; editace jen u aktivního GW. */
  const isViewingEditable = snap.viewingGameweek === snap.activeGameweek;
  const isLocked = !isViewingEditable;

  const draftLineup = lineupFor(snap.viewingGameweek);
  const filledCount = Object.values(draftLineup).filter(Boolean).length;
  const isComplete = filledCount === FANTASY_SQUAD_SIZE;

  const hasUnsavedChanges = useMemo(() => {
    const gw = String(snap.activeGameweek);
    const draft = snap.lineups[gw] ?? {};
    const saved = snap.saved[gw] ?? {};
    return !lineupEqual(draft, saved);
  }, [snap.lineups, snap.saved, snap.activeGameweek]);

  const selectedPlayerIds = useMemo(
    () => new Set(Object.values(draftLineup).filter(Boolean) as string[]),
    [draftLineup]
  );

  const spentCredits = useCallback(
    (playersById: Map<string, Player> | Record<string, Player>) =>
      spentCreditsFor(draftLineup, playersById),
    [draftLineup]
  );

  const remainingBudget = useCallback(
    (playersById: Map<string, Player> | Record<string, Player>) =>
      FANTASY_BUDGET - spentCredits(playersById),
    [spentCredits]
  );

  const squadPoints = useCallback(
    (playersById: Map<string, Player> | Record<string, Player>) => {
      const get =
        playersById instanceof Map
          ? (id: string) => playersById.get(id)
          : (id: string) => playersById[id];
      return Object.values(draftLineup)
        .filter(Boolean)
        .reduce((sum, id) => {
          const p = get(id!);
          return sum + (p ? fantasyPoints(p) : 0);
        }, 0);
    },
    [draftLineup]
  );

  /** Uloží draft aktivního kola. Vrací chybovou hlášku nebo null. */
  const saveLineup = useCallback((): string | null => {
    if (state.viewingGameweek !== state.activeGameweek) {
      return "Toto kolo nejde upravovat (deadline sobota 10:00).";
    }
    const gw = String(state.activeGameweek);
    const draft = state.lineups[gw] ?? {};
    const count = Object.values(draft).filter(Boolean).length;
    if (count !== FANTASY_SQUAD_SIZE) {
      return "Doplň celou sestavu (1B · 2O · 3Ú).";
    }
    state = {
      ...state,
      saved: { ...state.saved, [gw]: { ...draft } },
      lastSaveMessage: `Sestava GW ${state.activeGameweek} uložena`,
    };
    persistSaved();
    emit();
    return null;
  }, []);

  /**
   * Nastaví hráče do slotu v draftu aktivního kola (neukládá saved).
   * Vrací Czech error string | null.
   */
  const setSlot = useCallback(
    (slot: FantasySlot, player: Player, playersById: Map<string, Player> | Record<string, Player>): string | null => {
      if (state.viewingGameweek !== state.activeGameweek) {
        return "Toto kolo nejde upravovat (deadline sobota 10:00).";
      }
      if (player.position !== SLOT_POSITION[slot]) {
        return `Hráč neodpovídá pozici ${SLOT_TITLE[slot]}.`;
      }

      const get =
        playersById instanceof Map
          ? (id: string) => playersById.get(id)
          : (id: string) => playersById[id];

      const gw = String(state.activeGameweek);
      const current: LineupMap = { ...(state.lineups[gw] ?? {}) };

      // Přesun ze slotu, kde už je
      for (const s of FANTASY_SLOTS) {
        if (current[s] === player.id) delete current[s];
      }
      delete current[slot];

      const currentSpent = spentCreditsFor(current, playersById);
      const price = playerPrice(player);
      if (currentSpent + price > FANTASY_BUDGET) {
        return `Překročíš rozpočet ${FANTASY_BUDGET} kreditů.`;
      }

      const clubCounts = new Map<string, number>();
      for (const id of Object.values(current)) {
        if (!id) continue;
        const p = get(id);
        if (!p) continue;
        clubCounts.set(p.teamId, (clubCounts.get(p.teamId) ?? 0) + 1);
      }
      if ((clubCounts.get(player.teamId) ?? 0) + 1 > FANTASY_MAX_PER_CLUB) {
        return `Max. ${FANTASY_MAX_PER_CLUB} hráči z jednoho klubu.`;
      }

      current[slot] = player.id;
      state = {
        ...state,
        lineups: { ...state.lineups, [gw]: current },
        lastSaveMessage: null,
      };
      persistDraft();
      emit();
      return null;
    },
    []
  );

  const removeSlot = useCallback((slot: FantasySlot) => {
    if (state.viewingGameweek !== state.activeGameweek) return;
    const gw = String(state.activeGameweek);
    const current: LineupMap = { ...(state.lineups[gw] ?? {}) };
    delete current[slot];
    state = {
      ...state,
      lineups: { ...state.lineups, [gw]: current },
      lastSaveMessage: null,
    };
    persistDraft();
    emit();
  }, []);

  const clearLineup = useCallback(() => {
    if (state.viewingGameweek !== state.activeGameweek) return;
    const gw = String(state.activeGameweek);
    state = {
      ...state,
      lineups: { ...state.lineups, [gw]: {} },
      lastSaveMessage: null,
    };
    persistDraft();
    emit();
  }, []);

  return {
    ...snap,
    budget: FANTASY_BUDGET,
    filledCount,
    isComplete,
    isViewingEditable,
    isLocked,
    hasUnsavedChanges,
    selectedPlayerIds,
    lineupFor,
    spentCredits,
    remainingBudget,
    squadPoints,
    setTeamName,
    setViewingGameweek,
    setSlot,
    removeSlot,
    clearLineup,
    saveLineup,
  };
}

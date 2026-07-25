"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import type { Match } from "@/lib/types";
import { readJSON, readString, writeJSON, writeString } from "@/lib/storage";

export type TipPick = "home" | "away";

export type MatchTip = {
  matchId: string;
  pick: TipPick;
  createdAt: string;
  resolved: boolean;
  isCorrect?: boolean | null;
  pointsAwarded: number;
};

export type TipVotes = {
  matchId: string;
  homeCount: number;
  awayCount: number;
};

export type TipLeaderboardEntry = {
  id: string;
  name: string;
  points: number;
  correct: number;
  total: number;
  isCurrentUser: boolean;
};

const KEYS = {
  name: "hb.tips.v1.name",
  tips: "hb.tips.v1.tips",
  votes: "hb.tips.v1.votes",
  bots: "hb.tips.v1.bots",
};

const POINTS = 3;

type TipState = {
  displayName: string;
  tips: Record<string, MatchTip>;
  votes: Record<string, TipVotes>;
  bots: TipLeaderboardEntry[];
};

const listeners = new Set<() => void>();
let state: TipState = {
  displayName: "Tipér",
  tips: {},
  votes: {},
  bots: [],
};
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function defaultBots(): TipLeaderboardEntry[] {
  return [
    { id: "bot-1", name: "Arena Ace", points: 42, correct: 14, total: 20, isCurrentUser: false },
    { id: "bot-2", name: "Puk Master", points: 36, correct: 12, total: 18, isCurrentUser: false },
    { id: "bot-3", name: "Brankářská zeď", points: 30, correct: 10, total: 16, isCurrentUser: false },
  ];
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  const bots = readJSON<TipLeaderboardEntry[]>(KEYS.bots, []);
  state = {
    displayName: readString(KEYS.name, "Tipér"),
    tips: readJSON(KEYS.tips, {}),
    votes: readJSON(KEYS.votes, {}),
    bots: bots.length ? bots : defaultBots(),
  };
  if (!bots.length) writeJSON(KEYS.bots, state.bots);
  hydrated = true;
}

function persist() {
  writeString(KEYS.name, state.displayName);
  writeJSON(KEYS.tips, state.tips);
  writeJSON(KEYS.votes, state.votes);
  writeJSON(KEYS.bots, state.bots);
  emit();
}

/** Stabilní „komunitní“ základ podle id zápasu (jako iOS MatchTipStore.seedVotes). */
export function seedVotes(matchId: string): TipVotes {
  let hash = 5381;
  for (let i = 0; i < matchId.length; i++) {
    hash = Math.imul(hash, 33) + matchId.charCodeAt(i);
    hash >>>= 0;
  }
  const total = 80 + (hash % 220);
  const homeShare = 0.35 + (hash % 30) / 100;
  const home = Math.max(1, Math.floor(total * homeShare));
  const away = Math.max(1, total - home);
  return { matchId, homeCount: home, awayCount: away };
}

export function votePercents(votes: TipVotes): { homePercent: number; awayPercent: number } {
  const total = Math.max(1, votes.homeCount + votes.awayCount);
  const homePercent = Math.round((votes.homeCount / total) * 100);
  return { homePercent, awayPercent: Math.max(0, 100 - homePercent) };
}

/** Tipovat lze jen před začátkem naplánovaného zápasu. */
export function canTip(match: Match): boolean {
  return match.status === "scheduled" && Date.now() < new Date(match.scheduledAt).getTime();
}

export function useTips() {
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

  const setDisplayName = useCallback((name: string) => {
    state = { ...state, displayName: name };
    persist();
  }, []);

  const ensureVotes = useCallback((matchId: string) => {
    hydrate();
    if (state.votes[matchId]) return;
    state = {
      ...state,
      votes: { ...state.votes, [matchId]: seedVotes(matchId) },
    };
    persist();
  }, []);

  const placeTip = useCallback((matchId: string, pick: TipPick) => {
    const existing = state.tips[matchId];
    if (existing?.resolved) return;
    const votes = { ...(state.votes[matchId] ?? seedVotes(matchId)) };
    if (existing) {
      if (existing.pick === "home") votes.homeCount = Math.max(0, votes.homeCount - 1);
      else votes.awayCount = Math.max(0, votes.awayCount - 1);
    }
    if (pick === "home") votes.homeCount += 1;
    else votes.awayCount += 1;
    state = {
      ...state,
      tips: {
        ...state.tips,
        [matchId]: {
          matchId,
          pick,
          createdAt: existing?.createdAt ?? new Date().toISOString(),
          resolved: false,
          isCorrect: null,
          pointsAwarded: 0,
        },
      },
      votes: { ...state.votes, [matchId]: votes },
    };
    persist();
  }, []);

  const resolveAgainstMatches = useCallback((matches: Match[]) => {
    let changed = false;
    const tips = { ...state.tips };
    for (const m of matches) {
      const tip = tips[m.id];
      if (!tip || tip.resolved || m.status !== "finished") continue;
      const draw = m.homeScore === m.awayScore;
      const homeWon = m.homeScore > m.awayScore;
      const correct = !draw && ((tip.pick === "home" && homeWon) || (tip.pick === "away" && !homeWon));
      tips[m.id] = {
        ...tip,
        resolved: true,
        isCorrect: correct,
        pointsAwarded: correct ? POINTS : 0,
      };
      changed = true;
    }
    if (changed) {
      state = { ...state, tips };
      persist();
    }
  }, []);

  const userStats = (() => {
    const list = Object.values(snap.tips).filter((t) => t.resolved);
    const correct = list.filter((t) => t.isCorrect).length;
    const points = list.reduce((s, t) => s + t.pointsAwarded, 0);
    return { points, correct, total: list.length };
  })();

  const leaderboard: TipLeaderboardEntry[] = [
    ...snap.bots,
    {
      id: "local-user",
      name: snap.displayName,
      points: userStats.points,
      correct: userStats.correct,
      total: userStats.total,
      isCurrentUser: true,
    },
  ].sort((a, b) => b.points - a.points || b.correct - a.correct);

  const votesFor = (id: string): TipVotes & { homePercent: number; awayPercent: number } => {
    const votes = snap.votes[id] ?? seedVotes(id);
    return { ...votes, ...votePercents(votes) };
  };

  return {
    ...snap,
    pointsPerTip: POINTS,
    userStats,
    leaderboard,
    setDisplayName,
    placeTip,
    ensureVotes,
    resolveAgainstMatches,
    canTip,
    tipFor: (id: string) => snap.tips[id],
    votesFor,
  };
}

"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import type { Match } from "@/lib/types";

export type InAppBannerKind = "goal" | "finalScore";

export type InAppBanner = {
  id: string;
  kind: InAppBannerKind;
  matchId: string;
  homeTeamId: string;
  awayTeamId: string;
  homeName: string;
  awayName: string;
  homeScore: number;
  awayScore: number;
  scoringTeamId?: string | null;
};

type BannerState = {
  current: InAppBanner | null;
  queue: InAppBanner[];
};

const listeners = new Set<() => void>();
let state: BannerState = { current: null, queue: [] };
const viewingMatchIds = new Set<string>();
let dismissTimer: ReturnType<typeof setTimeout> | null = null;
let showNextTimer: ReturnType<typeof setTimeout> | null = null;

function emit() {
  listeners.forEach((l) => l());
}

function snapshot() {
  return state;
}

export function beginViewingMatch(matchId: string) {
  viewingMatchIds.add(matchId);
  if (state.current?.matchId === matchId) {
    dismissCurrent();
  }
  state = {
    ...state,
    queue: state.queue.filter((b) => b.matchId !== matchId),
  };
  emit();
}

export function endViewingMatch(matchId: string) {
  viewingMatchIds.delete(matchId);
}

export function isViewingMatch(matchId: string) {
  return viewingMatchIds.has(matchId);
}

function showNextIfNeeded() {
  if (state.current || !state.queue.length) return;
  const [next, ...rest] = state.queue;
  state = { current: next, queue: rest };
  emit();
  if (dismissTimer) clearTimeout(dismissTimer);
  dismissTimer = setTimeout(() => dismissCurrent(), 3800);
}

export function presentBanner(opts: {
  kind: InAppBannerKind;
  match: Match;
  homeName: string;
  awayName: string;
  scoringTeamId?: string | null;
}) {
  if (isViewingMatch(opts.match.id)) return;
  const banner: InAppBanner = {
    id: `${opts.kind}-${opts.match.id}-${Date.now()}`,
    kind: opts.kind,
    matchId: opts.match.id,
    homeTeamId: opts.match.homeTeamId,
    awayTeamId: opts.match.awayTeamId,
    homeName: opts.homeName,
    awayName: opts.awayName,
    homeScore: opts.match.homeScore,
    awayScore: opts.match.awayScore,
    scoringTeamId: opts.scoringTeamId ?? null,
  };
  state = { ...state, queue: [...state.queue, banner] };
  emit();
  showNextIfNeeded();
}

export function dismissCurrent() {
  if (dismissTimer) {
    clearTimeout(dismissTimer);
    dismissTimer = null;
  }
  state = { ...state, current: null };
  emit();
  if (showNextTimer) clearTimeout(showNextTimer);
  showNextTimer = setTimeout(() => showNextIfNeeded(), 200);
}

export function useBanners() {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    snapshot,
    snapshot
  );

  useEffect(() => {
    emit();
  }, []);

  const dismiss = useCallback(() => dismissCurrent(), []);
  const present = useCallback(
    (opts: {
      kind: InAppBannerKind;
      match: Match;
      homeName: string;
      awayName: string;
      scoringTeamId?: string | null;
    }) => presentBanner(opts),
    []
  );

  return {
    current: snap.current,
    dismiss,
    present,
    beginViewingMatch,
    endViewingMatch,
    isViewingMatch,
  };
}

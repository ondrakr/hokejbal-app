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

export const BANNER_DISPLAY_MS = 3800;

type BannerState = {
  current: InAppBanner | null;
  exiting: boolean;
  queue: InAppBanner[];
};

const listeners = new Set<() => void>();
let state: BannerState = { current: null, exiting: false, queue: [] };
const viewingMatchIds = new Set<string>();
let dismissTimer: ReturnType<typeof setTimeout> | null = null;
let showNextTimer: ReturnType<typeof setTimeout> | null = null;
let exitTimer: ReturnType<typeof setTimeout> | null = null;
const EXIT_MS = 280;

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
  if (state.current || state.exiting || !state.queue.length) return;
  const [next, ...rest] = state.queue;
  state = { current: next, exiting: false, queue: rest };
  emit();
  if (dismissTimer) clearTimeout(dismissTimer);
  dismissTimer = setTimeout(() => dismissCurrent(), BANNER_DISPLAY_MS);
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

export function dismissCurrent(opts?: { alreadyAnimated?: boolean }) {
  if (!state.current || state.exiting) return;
  if (dismissTimer) {
    clearTimeout(dismissTimer);
    dismissTimer = null;
  }
  if (exitTimer) clearTimeout(exitTimer);

  if (opts?.alreadyAnimated) {
    state = { ...state, current: null, exiting: false };
    emit();
    if (showNextTimer) clearTimeout(showNextTimer);
    showNextTimer = setTimeout(() => showNextIfNeeded(), 80);
    return;
  }

  state = { ...state, exiting: true };
  emit();
  exitTimer = setTimeout(() => {
    exitTimer = null;
    state = { ...state, current: null, exiting: false };
    emit();
    if (showNextTimer) clearTimeout(showNextTimer);
    showNextTimer = setTimeout(() => showNextIfNeeded(), 80);
  }, EXIT_MS);
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
    exiting: snap.exiting,
    dismiss,
    present,
    beginViewingMatch,
    endViewingMatch,
    isViewingMatch,
  };
}

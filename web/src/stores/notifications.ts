"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";

const KEY = "hb.notif.settings";

type NotifState = {
  goalsEnabled: boolean;
  matchStartEnabled: boolean;
  finalScoreEnabled: boolean;
  onlyFavorites: boolean;
  newsEnabled: boolean;
};

const defaults: NotifState = {
  goalsEnabled: true,
  matchStartEnabled: true,
  finalScoreEnabled: true,
  onlyFavorites: false,
  newsEnabled: true,
};

const listeners = new Set<() => void>();
let state: NotifState = { ...defaults };
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  state = { ...defaults, ...readJSON(KEY, {}) };
  hydrated = true;
}

function persist() {
  writeJSON(KEY, state);
  emit();
}

export function useNotifications() {
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

  const set = useCallback(<K extends keyof NotifState>(key: K, value: NotifState[K]) => {
    state = { ...state, [key]: value };
    persist();
  }, []);

  const activeLiveTypesSummary = (() => {
    const parts: string[] = [];
    if (snap.goalsEnabled) parts.push("Góly");
    if (snap.finalScoreEnabled) parts.push("Konec");
    if (snap.matchStartEnabled) parts.push("Start");
    return parts.length ? parts.join(" · ") : "Vypnuto";
  })();

  return { ...snap, set, activeLiveTypesSummary };
}

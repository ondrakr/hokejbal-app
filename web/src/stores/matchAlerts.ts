"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";

const KEY = "hb.match.alerts.muted";

const listeners = new Set<() => void>();
let muted: string[] = [];
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  muted = readJSON<string[]>(KEY, []);
  hydrated = true;
}

function persist() {
  writeJSON(KEY, muted);
  emit();
}

export function useMatchAlerts() {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => {
      hydrate();
      return muted;
    },
    () => muted
  );

  useEffect(() => {
    hydrate();
    emit();
  }, []);

  const isEnabled = useCallback(
    (matchId: string) => !snap.includes(matchId),
    [snap]
  );

  const toggle = useCallback((matchId: string) => {
    muted = muted.includes(matchId)
      ? muted.filter((id) => id !== matchId)
      : [...muted, matchId];
    persist();
  }, []);

  return { muted: snap, isEnabled, toggle };
}

"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { fetchLiveMatches } from "@/lib/api";
import type { Match } from "@/lib/types";
import { getDataSource } from "@/stores/dataSource";

const POLL_MS = 8000;

let liveMatches: Match[] = [];
let hydrated = false;
const listeners = new Set<() => void>();
let pollTimer: ReturnType<typeof setInterval> | null = null;
let inflight: Promise<void> | null = null;
let subscribers = 0;

function emit() {
  listeners.forEach((l) => l());
}

async function pollOnce() {
  if (inflight) return inflight;
  inflight = (async () => {
    try {
      if (getDataSource() === "mock") {
        // V mock režimu live zůstává z katalogu — nic nepřepisujeme.
        return;
      }
      const data = await fetchLiveMatches();
      liveMatches = data;
      hydrated = true;
      emit();
    } catch {
      // Tichý fail — tabulka zůstane na katalogových datech.
    } finally {
      inflight = null;
    }
  })();
  return inflight;
}

function startPolling() {
  if (pollTimer) return;
  void pollOnce();
  pollTimer = setInterval(() => {
    void pollOnce();
  }, POLL_MS);
}

function stopPolling() {
  if (subscribers > 0) return;
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

/** Live zápasy pro Live tabulku — poll každých ~8 s, sdílený napříč obrazovkami. */
export function useLiveMatches(): Match[] {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      subscribers += 1;
      startPolling();
      return () => {
        listeners.delete(cb);
        subscribers = Math.max(0, subscribers - 1);
        stopPolling();
      };
    },
    () => liveMatches,
    () => liveMatches
  );

  useEffect(() => {
    if (!hydrated) void pollOnce();
  }, []);

  return snap;
}

export function useRefreshLiveMatches() {
  return useCallback(() => pollOnce(), []);
}

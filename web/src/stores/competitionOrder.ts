"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";
import type { Competition, Match } from "@/lib/types";

const KEY = "hb.competition.order";

const listeners = new Set<() => void>();
let orderedSlugs: string[] = [];
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  orderedSlugs = readJSON(KEY, []);
  hydrated = true;
}

function persist() {
  writeJSON(KEY, orderedSlugs);
  emit();
}

export function useCompetitionOrder() {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => {
      hydrate();
      return orderedSlugs;
    },
    () => orderedSlugs
  );

  useEffect(() => {
    hydrate();
    emit();
  }, []);

  const sync = useCallback((competitions: Competition[]) => {
    hydrate();
    const available = competitions.map((c) => c.slug);
    const next = orderedSlugs.filter((s) => available.includes(s));
    for (const slug of available) {
      if (!next.includes(slug)) next.push(slug);
    }
    if (next.join() === orderedSlugs.join()) return;
    orderedSlugs = next;
    persist();
  }, []);

  const setOrder = useCallback((slugs: string[]) => {
    orderedSlugs = slugs;
    persist();
  }, []);

  const move = useCallback((from: number, to: number) => {
    const next = [...orderedSlugs];
    const [item] = next.splice(from, 1);
    next.splice(to, 0, item);
    orderedSlugs = next;
    persist();
  }, []);

  const sortedCompetitions = useCallback(
    (competitions: Competition[]) =>
      [...competitions].sort((a, b) => {
        const ia = snap.indexOf(a.slug);
        const ib = snap.indexOf(b.slug);
        const aa = ia === -1 ? Number.MAX_SAFE_INTEGER : ia;
        const bb = ib === -1 ? Number.MAX_SAFE_INTEGER : ib;
        if (aa !== bb) return aa - bb;
        return a.name.localeCompare(b.name, "cs");
      }),
    [snap]
  );

  const groupMatchesByCompetition = useCallback(
    (matches: Match[], competitions: Competition[]) => {
      const map = new Map<string, Match[]>();
      for (const m of matches) {
        const list = map.get(m.competitionId) ?? [];
        list.push(m);
        map.set(m.competitionId, list);
      }
      const sortedIds = [...map.keys()].sort((a, b) => {
        const sa = competitions.find((c) => c.id === a)?.slug ?? "";
        const sb = competitions.find((c) => c.id === b)?.slug ?? "";
        const ia = snap.indexOf(sa);
        const ib = snap.indexOf(sb);
        const aa = ia === -1 ? Number.MAX_SAFE_INTEGER : ia;
        const bb = ib === -1 ? Number.MAX_SAFE_INTEGER : ib;
        if (aa !== bb) return aa - bb;
        return a.localeCompare(b);
      });
      return sortedIds.map((id) => ({
        competition: competitions.find((c) => c.id === id),
        matches: (map.get(id) ?? []).sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt)),
      }));
    },
    [snap]
  );

  return { orderedSlugs: snap, sync, setOrder, move, sortedCompetitions, groupMatchesByCompetition };
}

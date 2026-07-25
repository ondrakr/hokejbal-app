"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readJSON, writeJSON } from "@/lib/storage";
import type { Competition, Match } from "@/lib/types";

const KEYS = {
  competitions: "hb.home.feed.competitions",
  teams: "hb.home.feed.teams",
  seeded: "hb.home.feed.seeded",
};

type FeedState = {
  competitionSlugs: string[];
  teamIDs: string[];
};

const listeners = new Set<() => void>();
let state: FeedState = { competitionSlugs: [], teamIDs: [] };
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  state = {
    competitionSlugs: readJSON(KEYS.competitions, []),
    teamIDs: readJSON(KEYS.teams, []),
  };
  hydrated = true;
}

function persist() {
  writeJSON(KEYS.competitions, state.competitionSlugs);
  writeJSON(KEYS.teams, state.teamIDs);
  emit();
}

function toggle(list: string[], id: string) {
  return list.includes(id) ? list.filter((x) => x !== id) : [...list, id];
}

export function useHomeFeed() {
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

  const hasSelection = snap.competitionSlugs.length > 0 || snap.teamIDs.length > 0;

  const selectionSummary = (() => {
    const parts: string[] = [];
    if (snap.competitionSlugs.length) parts.push(`${snap.competitionSlugs.length} soutěží`);
    if (snap.teamIDs.length) parts.push(`${snap.teamIDs.length} týmů`);
    return parts.length ? parts.join(" · ") : "Nic nevybráno";
  })();

  const includesMatch = useCallback(
    (match: Match, competitions: Competition[]) => {
      if (!hasSelection) return false;
      if (snap.teamIDs.includes(match.homeTeamId) || snap.teamIDs.includes(match.awayTeamId)) {
        return true;
      }
      const slug = competitions.find((c) => c.id === match.competitionId)?.slug;
      return Boolean(slug && snap.competitionSlugs.includes(slug));
    },
    [hasSelection, snap.teamIDs, snap.competitionSlugs]
  );

  const seedDefaultsIfNeeded = useCallback((competitions: Competition[]) => {
    hydrate();
    if (typeof window === "undefined") return;
    if (localStorage.getItem(KEYS.seeded) === "1") return;
    localStorage.setItem(KEYS.seeded, "1");
    if (state.competitionSlugs.length || state.teamIDs.length || !competitions.length) return;
    const extraliga = competitions.find((c) => c.slug === "extraliga");
    state = {
      ...state,
      competitionSlugs: [extraliga?.slug ?? competitions[0].slug],
    };
    persist();
  }, []);

  return {
    ...snap,
    hasSelection,
    selectionSummary,
    includesMatch,
    seedDefaultsIfNeeded,
    isCompetitionSelected: (slug: string) => snap.competitionSlugs.includes(slug),
    isTeamSelected: (id: string) => snap.teamIDs.includes(id),
    toggleCompetition: (slug: string) => {
      state = { ...state, competitionSlugs: toggle(state.competitionSlugs, slug) };
      persist();
    },
    toggleTeam: (id: string) => {
      state = { ...state, teamIDs: toggle(state.teamIDs, id) };
      persist();
    },
    selectAllCompetitions: (comps: Competition[]) => {
      state = { ...state, competitionSlugs: comps.map((c) => c.slug) };
      persist();
    },
    clearCompetitions: () => {
      state = { ...state, competitionSlugs: [] };
      persist();
    },
    clearTeams: () => {
      state = { ...state, teamIDs: [] };
      persist();
    },
    clearAll: () => {
      state = { competitionSlugs: [], teamIDs: [] };
      persist();
    },
  };
}

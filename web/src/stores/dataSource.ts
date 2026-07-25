"use client";

import { useCallback, useEffect, useSyncExternalStore } from "react";
import { readString, writeString } from "@/lib/storage";

export type DataSource = "supabase" | "mock";

const KEY = "hb.dataSource";

const listeners = new Set<() => void>();
let source: DataSource = "supabase";
let hydrated = false;

function emit() {
  listeners.forEach((l) => l());
}

function hydrate() {
  if (hydrated || typeof window === "undefined") return;
  const raw = readString(KEY, "supabase");
  source = raw === "mock" ? "mock" : "supabase";
  hydrated = true;
}

export function getDataSource(): DataSource {
  hydrate();
  return source;
}

export function useDataSource() {
  const snap = useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => {
      hydrate();
      return source;
    },
    () => source
  );

  useEffect(() => {
    hydrate();
    emit();
  }, []);

  const setSource = useCallback((next: DataSource) => {
    source = next;
    writeString(KEY, next);
    emit();
  }, []);

  return {
    source: snap,
    setSource,
    title: (s: DataSource) =>
      s === "supabase" ? "Supabase (online)" : "Mock (offline snapshot)",
  };
}

"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchLiveMatches } from "@/lib/api";
import type { Match } from "@/lib/types";
import { MatchRow, Pill } from "@/components/MatchRow";
import { EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

export function LiveScreen() {
  const { competitions } = useCatalog();
  const { liveFilter, selectLive } = useNav();
  const [matches, setMatches] = useState<Match[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    async function poll() {
      try {
        const data = await fetchLiveMatches();
        if (!cancelled) setMatches(data);
      } catch {
        /* keep previous */
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void poll();
    const id = window.setInterval(poll, 8000);
    return () => {
      cancelled = true;
      window.clearInterval(id);
    };
  }, []);

  const filtered = useMemo(() => {
    if (liveFilter === "broadcasts") return matches.filter((m) => Boolean(m.streamURL));
    return matches;
  }, [matches, liveFilter]);

  const grouped = useMemo(() => {
    const map = new Map<string, Match[]>();
    for (const m of filtered) {
      const list = map.get(m.competitionId) ?? [];
      list.push(m);
      map.set(m.competitionId, list);
    }
    return [...map.entries()].map(([id, list]) => ({
      competition: competitions.find((c) => c.id === id),
      matches: list,
    }));
  }, [filtered, competitions]);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="LIVE"
        large
        right={
          <div className="flex items-center gap-1 rounded-full bg-[var(--live)] px-2 py-1 text-[11px] font-bold text-white">
            <span className="hb-live-dot !bg-white" />
            LIVE
          </div>
        }
      />

      <div className="mb-3 flex gap-2 px-[var(--screen-pad)]">
        <Pill active={liveFilter === "all"} onClick={() => selectLive("all")}>
          Vše
        </Pill>
        <Pill active={liveFilter === "broadcasts"} onClick={() => selectLive("broadcasts")}>
          Živé přenosy
        </Pill>
      </div>

      {loading && <LoadingState label="Načítám živé zápasy…" />}

      {!loading &&
        grouped.map(({ competition, matches: list }) => (
          <section key={competition?.id ?? list[0]?.id} className="mb-4">
            <div className="mb-1 px-[var(--screen-pad)] text-[14px] font-bold">
              {competition?.name ?? "Soutěž"}
            </div>
            <div className="mx-[var(--screen-pad)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--card-stroke)]">
              {list.map((m) => (
                <MatchRow key={m.id} match={m} compact />
              ))}
            </div>
          </section>
        ))}

      {!loading && !filtered.length && (
        <EmptyState
          title={liveFilter === "broadcasts" ? "Žádné živé přenosy" : "Teď nic neběží"}
          hint="Živé zápasy se obnovují každých 8 s."
        />
      )}
    </div>
  );
}

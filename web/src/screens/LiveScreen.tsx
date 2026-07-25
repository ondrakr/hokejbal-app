"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchLiveMatches } from "@/lib/api";
import type { Match } from "@/lib/types";
import { LiveBadge, MatchRow, Pill, PillTrack } from "@/components/MatchRow";
import { EmptyState, LoadingState, ScreenHeader, SectionHeader } from "@/components/ui";
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
      <ScreenHeader title="LIVE" right={<LiveBadge />} />

      <PillTrack>
        <Pill active={liveFilter === "all"} onClick={() => selectLive("all")}>
          Vše
        </Pill>
        <Pill active={liveFilter === "broadcasts"} onClick={() => selectLive("broadcasts")}>
          Živé přenosy
        </Pill>
      </PillTrack>

      {loading && <LoadingState label="Načítám živé zápasy…" />}

      {!loading &&
        grouped.map(({ competition, matches: list }) => (
          <section key={competition?.id ?? list[0]?.id} className="mb-3">
            <SectionHeader title={competition?.name ?? "Soutěž"} />
            {list.map((m) => (
              <MatchRow key={m.id} match={m} />
            ))}
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

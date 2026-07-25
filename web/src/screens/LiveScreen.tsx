"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchLiveMatches } from "@/lib/api";
import type { Match } from "@/lib/types";
import { LiveBadge, MatchRow, Pill, PillTrack } from "@/components/MatchRow";
import { EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

/** Port LiveView.swift */
export function LiveScreen() {
  const { competitions } = useCatalog();
  const { liveFilter, selectLive, push } = useNav();
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
      <ScreenHeader title="Živě" systemImage right={<LiveBadge compact />} />

      <div className="bg-[var(--surface)] pb-2.5 pt-2">
        <PillTrack>
          <Pill active={liveFilter === "all"} onClick={() => selectLive("all")}>
            Vše
          </Pill>
          <Pill active={liveFilter === "broadcasts"} onClick={() => selectLive("broadcasts")}>
            Živé přenosy
          </Pill>
        </PillTrack>
      </div>

      {loading && <LoadingState label="Načítám živé zápasy…" />}

      {!loading &&
        grouped.map(({ competition, matches: list }) => (
          <section key={competition?.id ?? list[0]?.id} className="mb-2">
            {competition && (
              <button
                type="button"
                className="mb-1 flex w-full items-center gap-2 bg-[var(--secondary-surface)] px-4 py-2.5 text-left"
                onClick={() => push({ name: "competition", id: competition.id })}
              >
                {competition.logoURL ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={competition.logoURL} alt="" className="h-[18px] w-[18px] object-contain" />
                ) : (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src="/brand/BrandLogo.png" alt="" className="h-[18px] w-[18px] object-contain" />
                )}
                <span className="flex-1 truncate text-[11px] font-semibold uppercase text-[var(--text-secondary)]">
                  {competition.name}
                </span>
                <span className="text-[var(--text-tertiary)]">›</span>
              </button>
            )}
            {list.map((m) => (
              <MatchRow key={m.id} match={m} />
            ))}
          </section>
        ))}

      {!loading && !filtered.length && (
        <EmptyState
          title={liveFilter === "broadcasts" ? "Žádné živé přenosy" : "Žádné živé zápasy"}
          hint={
            liveFilter === "broadcasts"
              ? "Teď se žádný zápas nevysílá. Přepněte na Vše, nebo se vraťte později."
              : "Až začne další kolo, uvidíte zde průběžné výsledky."
          }
        />
      )}
    </div>
  );
}

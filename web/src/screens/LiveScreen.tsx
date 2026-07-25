"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchLiveMatches } from "@/lib/api";
import type { Match } from "@/lib/types";
import { CompetitionBadge } from "@/components/Badges";
import { CompetitionNavStrip } from "@/components/MatchDayStrip";
import { LiveBadge, MatchRow, Pill, PillTrack } from "@/components/MatchRow";
import { IconLive } from "@/components/Icons";
import { EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useCompetitionOrder } from "@/stores/competitionOrder";
import { useNav } from "@/stores/navigation";

/** Port LiveView.swift */
export function LiveScreen() {
  const { competitions } = useCatalog();
  const { liveFilter, selectLive, push } = useNav();
  const order = useCompetitionOrder();
  const [matches, setMatches] = useState<Match[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    order.sync(competitions);
  }, [competitions, order]);

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

  const grouped = useMemo(
    () => order.groupMatchesByCompetition(filtered, competitions),
    [filtered, competitions, order]
  );

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter">
      <ScreenHeader
        title="Živě"
        systemIcon={<IconLive size={14} />}
        right={<LiveBadge compact />}
      />

      <div className="shrink-0 bg-surface">
        <PillTrack>
          <Pill active={liveFilter === "all"} onClick={() => selectLive("all")}>
            Vše
          </Pill>
          <Pill active={liveFilter === "broadcasts"} onClick={() => selectLive("broadcasts")}>
            Živé přenosy
          </Pill>
        </PillTrack>
      </div>

      <div className="hb-scroll min-h-0 flex-1">
        {loading && <LoadingState label="Načítám živé zápasy…" />}

        {!loading &&
          grouped.map(({ competition, matches: list }) => (
            <section key={competition?.id ?? list[0]?.id} className="mb-1">
              {competition && (
                <CompetitionNavStrip
                  title={competition.name}
                  badge={<CompetitionBadge competition={competition} size={18} />}
                  onClick={() => push({ name: "competition", id: competition.id })}
                />
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
    </div>
  );
}

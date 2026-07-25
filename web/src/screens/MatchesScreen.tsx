"use client";

import { useMemo, useState } from "react";
import { addDays, format, parseISO, startOfDay } from "date-fns";
import { cs } from "date-fns/locale";
import { MatchRow } from "@/components/MatchRow";
import { EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { dayKey, formatDayNum, formatShortDay, todayKey } from "@/lib/format";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

export function MatchesScreen() {
  const { matches, competitions, loading } = useCatalog();
  const fav = useFavorites();
  const { push } = useNav();
  const [selectedDay, setSelectedDay] = useState(todayKey());

  const days = useMemo(() => {
    const keys = new Set(matches.map((m) => dayKey(m.scheduledAt)));
    const base = startOfDay(new Date());
    return Array.from({ length: 21 }, (_, i) => {
      const d = addDays(base, i - 7);
      const key = format(d, "yyyy-MM-dd");
      return { key, date: d, has: keys.has(key) };
    });
  }, [matches]);

  const dayMatches = useMemo(
    () => matches.filter((m) => dayKey(m.scheduledAt) === selectedDay),
    [matches, selectedDay]
  );

  const byCompetition = useMemo(() => {
    const map = new Map<string, typeof dayMatches>();
    for (const m of dayMatches) {
      const list = map.get(m.competitionId) ?? [];
      list.push(m);
      map.set(m.competitionId, list);
    }
    return [...map.entries()]
      .map(([id, list]) => ({
        competition: competitions.find((c) => c.id === id),
        matches: list,
      }))
      .filter((x) => x.competition)
      .sort((a, b) => {
        const aFav = fav.isCompetition(a.competition!.slug) ? 0 : 1;
        const bFav = fav.isCompetition(b.competition!.slug) ? 0 : 1;
        return aFav - bFav || a.competition!.name.localeCompare(b.competition!.name, "cs");
      });
  }, [dayMatches, competitions, fav]);

  if (loading) return <LoadingState />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Zápasy"
        large
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--card)] font-bold"
            onClick={() => push({ name: "search" })}
          >
            ⌕
          </button>
        }
      />

      <div className="mb-3 flex gap-2 overflow-x-auto px-[var(--screen-pad)] pb-1">
        {days.map((d) => {
          const active = d.key === selectedDay;
          return (
            <button
              key={d.key}
              type="button"
              onClick={() => setSelectedDay(d.key)}
              className={`relative flex w-12 shrink-0 flex-col items-center rounded-[14px] py-2 ${
                active ? "bg-[var(--brand)] text-white" : "bg-[var(--card)]"
              }`}
            >
              <span className="text-[10px] font-semibold uppercase opacity-80">
                {formatShortDay(d.date.toISOString())}
              </span>
              <span className="text-[16px] font-extrabold">{formatDayNum(d.date.toISOString())}</span>
              {d.has && (
                <span
                  className={`mt-1 h-1 w-1 rounded-full ${active ? "bg-white" : "bg-[var(--brand)]"}`}
                />
              )}
            </button>
          );
        })}
      </div>

      <div className="px-[var(--screen-pad)] pb-2 text-[13px] font-semibold text-[var(--text-secondary)]">
        {format(parseISO(selectedDay), "EEEE d. MMMM", { locale: cs })}
      </div>

      <button
        type="button"
        className="mx-[var(--screen-pad)] mb-3 flex w-[calc(100%-32px)] items-center justify-between rounded-[var(--radius-md)] border border-[var(--card-stroke)] bg-[var(--card)] px-4 py-3 text-left"
        onClick={() => push({ name: "competition", id: "all" })}
      >
        <span className="font-semibold">Všechny zápasy</span>
        <span className="hb-muted">{dayMatches.length}</span>
      </button>

      {byCompetition.map(({ competition, matches: list }) => (
        <section key={competition!.id} className="mb-4">
          <button
            type="button"
            onClick={() => push({ name: "competition", id: competition!.id })}
            className="mb-1 flex w-full items-center justify-between px-[var(--screen-pad)]"
          >
            <div className="text-left">
              <div className="text-[14px] font-bold">{competition!.name}</div>
              <div className="hb-muted">{competition!.season}</div>
            </div>
            <span className="rounded-full bg-[var(--card-inset)] px-2 py-0.5 text-[12px] font-bold">
              {list.length}
            </span>
          </button>
          <div className="mx-[var(--screen-pad)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--card-stroke)]">
            {list.map((m) => (
              <MatchRow key={m.id} match={m} compact />
            ))}
          </div>
        </section>
      ))}

      {!byCompetition.length && (
        <EmptyState title="Žádné zápasy tento den" hint="Vyber jiný den ve stripu nahoře." />
      )}
    </div>
  );
}

"use client";

import { useMemo, useState } from "react";
import { addDays, format, parseISO, startOfDay } from "date-fns";
import { cs } from "date-fns/locale";
import { MatchRow } from "@/components/MatchRow";
import { IconSearch } from "@/components/Icons";
import { EmptyState, LoadingState, ScreenHeader, SectionHeader } from "@/components/ui";
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
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center"
            onClick={() => push({ name: "search" })}
          >
            <IconSearch size={16} />
          </button>
        }
      />

      <div className="mb-2 flex gap-2 overflow-x-auto px-4 py-2">
        {days.map((d) => {
          const active = d.key === selectedDay;
          return (
            <button
              key={d.key}
              type="button"
              onClick={() => setSelectedDay(d.key)}
              className={`relative flex w-12 shrink-0 flex-col items-center rounded-[14px] py-2 ${
                active ? "bg-[var(--brand)] text-white" : "hb-card !shadow-none"
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

      <div className="px-4 pb-2 text-[13px] font-semibold text-[var(--text-secondary)]">
        {format(parseISO(selectedDay), "EEEE d. MMMM", { locale: cs })}
      </div>

      <button
        type="button"
        className="hb-card mx-4 mb-3 flex w-[calc(100%-32px)] items-center justify-between px-4 py-3 text-left"
        onClick={() => push({ name: "competition", id: "all" })}
      >
        <span className="font-semibold">Všechny zápasy</span>
        <span className="hb-muted">{dayMatches.length}</span>
      </button>

      {byCompetition.map(({ competition, matches: list }) => (
        <section key={competition!.id} className="mb-3">
          <button type="button" onClick={() => push({ name: "competition", id: competition!.id })}>
            <SectionHeader title={competition!.shortName || competition!.name} />
          </button>
          <div className="pb-1">
            {list.map((m) => (
              <MatchRow key={m.id} match={m} />
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

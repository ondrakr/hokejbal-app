"use client";

import { useMemo, useState } from "react";
import { addDays, format, startOfDay } from "date-fns";
import { cs } from "date-fns/locale";
import { IconChevronRight, IconSearch } from "@/components/Icons";
import { EmptyState, LoadingState, ScreenHeader, SectionHeader } from "@/components/ui";
import { dayKey, formatDayNum, todayKey } from "@/lib/format";
import type { Competition } from "@/lib/types";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

/** Port MatchesByCompetitionView — denní strip + výběr soutěží (ne seznam zápasů). */
export function MatchesScreen() {
  const { matches, competitions, loading } = useCatalog();
  const fav = useFavorites();
  const { push } = useNav();
  const [selectedDay, setSelectedDay] = useState(todayKey());

  const days = useMemo(() => {
    const keys = new Set(matches.map((m) => dayKey(m.scheduledAt)));
    const base = startOfDay(new Date());
    return Array.from({ length: 64 }, (_, i) => {
      const d = addDays(base, i - 21);
      const key = format(d, "yyyy-MM-dd");
      return { key, date: d, has: keys.has(key), isToday: key === todayKey() };
    });
  }, [matches]);

  const dayMatches = useMemo(
    () => matches.filter((m) => dayKey(m.scheduledAt) === selectedDay),
    [matches, selectedDay]
  );

  const compsToday = useMemo(() => {
    const ids = new Set(dayMatches.map((m) => m.competitionId));
    return competitions
      .filter((c) => ids.has(c.id))
      .sort((a, b) => a.name.localeCompare(b.name, "cs"));
  }, [dayMatches, competitions]);

  const favoriteComps = compsToday.filter((c) => fav.isCompetition(c.slug));
  const otherComps = compsToday.filter((c) => !fav.isCompetition(c.slug));
  const isTodaySelected = selectedDay === todayKey();

  if (loading) return <LoadingState label="Načítám zápasy…" />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Zápasy"
        systemImage
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center"
            onClick={() => push({ name: "search" })}
            aria-label="Hledat"
          >
            <IconSearch size={16} />
          </button>
        }
      />

      {/* MatchDayStrip */}
      <div className="border-b border-[var(--separator)] bg-[var(--surface)] pt-1">
        {!isTodaySelected && (
          <div className="flex justify-end px-4">
            <button
              type="button"
              className="text-[12px] font-bold text-[var(--brand)]"
              onClick={() => setSelectedDay(todayKey())}
            >
              Dnes
            </button>
          </div>
        )}
        <div className="flex gap-1.5 overflow-x-auto px-4 py-2">
          {days.map((d) => {
            const active = d.key === selectedDay;
            const enabled = d.has || active;
            const dayColor = active
              ? "#fff"
              : !enabled
                ? "color-mix(in srgb, var(--text-tertiary) 50%, transparent)"
                : d.isToday
                  ? "var(--brand)"
                  : "var(--text-primary)";
            const dowColor = active
              ? "rgba(255,255,255,0.9)"
              : !enabled
                ? "color-mix(in srgb, var(--text-tertiary) 50%, transparent)"
                : d.isToday
                  ? "var(--brand)"
                  : "var(--text-tertiary)";
            return (
              <button
                key={d.key}
                type="button"
                disabled={!enabled}
                onClick={() => setSelectedDay(d.key)}
                className="flex min-h-12 min-w-[42px] shrink-0 flex-col items-center justify-center gap-[3px] rounded-[12px]"
                style={{ background: active ? "var(--brand)" : "transparent" }}
              >
                <span
                  className="text-[10px] font-semibold tracking-[0.3px] uppercase"
                  style={{ color: dowColor }}
                >
                  {format(d.date, "EE", { locale: cs }).slice(0, 2)}
                </span>
                <span
                  className="hb-number text-[17px]"
                  style={{
                    color: dayColor,
                    fontWeight: active || d.isToday ? 700 : 500,
                  }}
                >
                  {formatDayNum(d.date.toISOString())}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      <div className="pb-6 pt-2">
        <CompetitionCard
          title="Všechny zápasy"
          count={dayMatches.length}
          brandIcon
          onClick={() => push({ name: "competition", id: "all", day: selectedDay })}
        />

        {favoriteComps.length > 0 && (
          <div className="mt-2">
            <SectionHeader title="Oblíbené soutěže" accent="#d9a626" />
            {favoriteComps.map((c) => (
              <CompetitionCard
                key={c.id}
                competition={c}
                count={dayMatches.filter((m) => m.competitionId === c.id).length}
                onClick={() => push({ name: "competition", id: c.id, day: selectedDay })}
              />
            ))}
          </div>
        )}

        {otherComps.length > 0 && (
          <div className="mt-1">
            {otherComps.map((c) => (
              <CompetitionCard
                key={c.id}
                competition={c}
                count={dayMatches.filter((m) => m.competitionId === c.id).length}
                onClick={() => push({ name: "competition", id: c.id, day: selectedDay })}
              />
            ))}
          </div>
        )}

        {!dayMatches.length && (
          <EmptyState title="Žádné zápasy tento den" hint="Vyber jiný den ve stripu nahoře." />
        )}
      </div>
    </div>
  );
}

function CompetitionCard({
  title,
  competition,
  count,
  brandIcon,
  onClick,
}: {
  title?: string;
  competition?: Competition;
  count: number;
  brandIcon?: boolean;
  onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick} className="block w-full px-4 py-[5px] text-left">
      <div className="hb-card flex items-center gap-3 px-3.5 py-3">
        {brandIcon ? (
          <div className="flex h-[34px] w-[34px] items-center justify-center rounded-[9px] bg-[color-mix(in_srgb,var(--brand)_12%,transparent)] text-[var(--brand)]">
            ▤
          </div>
        ) : competition?.logoURL ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={competition.logoURL} alt="" className="h-[30px] w-[30px] object-contain" />
        ) : (
          // eslint-disable-next-line @next/next/no-img-element
          <img src="/brand/BrandLogo.png" alt="" className="h-[30px] w-[30px] object-contain" />
        )}
        <span className={`min-w-0 flex-1 text-[15px] ${brandIcon ? "font-bold" : "font-semibold"}`}>
          {title ?? competition?.name}
        </span>
        {brandIcon && count > 0 ? (
          <span className="rounded-full bg-[var(--brand)] px-2 py-[3px] text-[12px] font-bold text-white">
            {count}
          </span>
        ) : (
          <span className="hb-number min-w-[22px] text-right text-[14px] font-semibold text-[var(--text-secondary)]">
            {count}
          </span>
        )}
        <span className="text-[var(--text-tertiary)]">
          <IconChevronRight size={12} />
        </span>
      </div>
    </button>
  );
}

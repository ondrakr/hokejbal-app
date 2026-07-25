"use client";

import type { ReactNode } from "react";
import { useMemo } from "react";
import { addDays, format, startOfDay } from "date-fns";
import { cs } from "date-fns/locale";
import { formatDayNum, todayKey } from "@/lib/format";

/** Port MatchDayStrip.swift */
export function MatchDayStrip({
  selectedDay,
  onSelect,
  datesWithMatches,
  pastDays = 21,
  futureDays = 42,
}: {
  selectedDay: string;
  onSelect: (key: string) => void;
  datesWithMatches: Set<string> | string[];
  pastDays?: number;
  futureDays?: number;
}) {
  const hasSet = useMemo(
    () => (datesWithMatches instanceof Set ? datesWithMatches : new Set(datesWithMatches)),
    [datesWithMatches]
  );

  const days = useMemo(() => {
    const base = startOfDay(new Date());
    return Array.from({ length: pastDays + futureDays + 1 }, (_, i) => {
      const d = addDays(base, i - pastDays);
      const key = format(d, "yyyy-MM-dd");
      return { key, date: d, has: hasSet.has(key), isToday: key === todayKey() };
    });
  }, [hasSet, pastDays, futureDays]);

  const isTodaySelected = selectedDay === todayKey();

  return (
    <div className="border-b border-separator bg-surface pt-1">
      {!isTodaySelected && (
        <div className="flex justify-end px-4">
          <button type="button" className="text-[12px] font-bold text-brand" onClick={() => onSelect(todayKey())}>
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
              onClick={() => onSelect(d.key)}
              className="flex min-h-12 min-w-[42px] shrink-0 flex-col items-center justify-center gap-[3px] rounded-[12px]"
              style={{ background: active ? "var(--brand)" : "transparent" }}
            >
              <span className="text-[10px] font-semibold tracking-[0.3px] uppercase" style={{ color: dowColor }}>
                {format(d.date, "EE", { locale: cs }).slice(0, 2)}
              </span>
              <span
                className="hb-number text-[17px]"
                style={{ color: dayColor, fontWeight: active || d.isToday ? 700 : 500 }}
              >
                {formatDayNum(d.date.toISOString())}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

export function CompetitionNavStrip({
  title,
  badge,
  onClick,
}: {
  title: string;
  badge?: ReactNode;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="mb-0 flex w-full items-center gap-2 bg-secondary-surface px-4 py-2.5 text-left"
      disabled={!onClick}
    >
      {badge}
      <span className="min-w-0 flex-1 truncate text-[11px] font-semibold tracking-[0.2px] text-hb-muted uppercase">
        {title}
      </span>
      {onClick && <span className="text-[10px] font-semibold text-hb-faint">›</span>}
    </button>
  );
}

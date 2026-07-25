"use client";

import type { ReactNode } from "react";
import { useEffect, useMemo, useRef } from "react";
import {
  formatDayNumFromKey,
  formatDowFromKey,
  shiftDayKey,
  todayKey,
} from "@/lib/format";

/** Port MatchDayStrip.swift — vybraný den vždy uprostřed stripu. */
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
  const scrollRef = useRef<HTMLDivElement>(null);
  const selectedRef = useRef<HTMLButtonElement>(null);
  const didInitialCenter = useRef(false);

  const hasSet = useMemo(
    () => (datesWithMatches instanceof Set ? datesWithMatches : new Set(datesWithMatches)),
    [datesWithMatches]
  );

  const days = useMemo(() => {
    const today = todayKey();
    return Array.from({ length: pastDays + futureDays + 1 }, (_, i) => {
      const key = shiftDayKey(today, i - pastDays);
      return { key, has: hasSet.has(key), isToday: key === today };
    });
  }, [hasSet, pastDays, futureDays]);

  const isTodaySelected = selectedDay === todayKey();

  useEffect(() => {
    const el = selectedRef.current;
    const scroller = scrollRef.current;
    if (!el || !scroller) return;

    const center = (behavior: ScrollBehavior) => {
      const scrollerRect = scroller.getBoundingClientRect();
      const elRect = el.getBoundingClientRect();
      const delta =
        elRect.left +
        elRect.width / 2 -
        (scrollerRect.left + scrollerRect.width / 2);
      scroller.scrollTo({
        left: scroller.scrollLeft + delta,
        behavior,
      });
    };

    // Dvojí rAF: počká na layout dní (včetně pozdního načtení datesWithMatches).
    const id = requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        const smooth = didInitialCenter.current;
        didInitialCenter.current = true;
        center(smooth ? "smooth" : "auto");
      });
    });
    return () => cancelAnimationFrame(id);
  }, [selectedDay, days]);

  return (
    <div className="border-b border-separator bg-surface pt-1">
      {!isTodaySelected && (
        <div className="flex justify-end px-4">
          <button
            type="button"
            className="font-bold"
            style={{ fontSize: 12, color: "var(--brand)" }}
            onClick={() => onSelect(todayKey())}
          >
            Dnes
          </button>
        </div>
      )}
      <div
        ref={scrollRef}
        className="hb-day-strip flex gap-1.5 overflow-x-auto px-4 py-2"
      >
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
              ref={active ? selectedRef : undefined}
              type="button"
              disabled={!enabled}
              onClick={() => onSelect(d.key)}
              className="flex min-h-12 min-w-[42px] shrink-0 flex-col items-center justify-center gap-[3px] rounded-[12px]"
              style={{ background: active ? "var(--brand)" : "transparent" }}
            >
              <span
                className="font-semibold tracking-[0.3px] uppercase"
                style={{ fontSize: 10, color: dowColor }}
              >
                {formatDowFromKey(d.key)}
              </span>
              <span
                className="hb-number"
                style={{
                  fontSize: 17,
                  color: dayColor,
                  fontWeight: active || d.isToday ? 700 : 500,
                }}
              >
                {formatDayNumFromKey(d.key)}
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
      <span
        className="min-w-0 flex-1 truncate font-semibold tracking-[0.2px] uppercase"
        style={{ fontSize: 11, color: "var(--text-secondary)" }}
      >
        {title}
      </span>
      {onClick && (
        <span className="font-semibold" style={{ fontSize: 10, color: "var(--text-tertiary)" }}>
          ›
        </span>
      )}
    </button>
  );
}

"use client";

import type { StandingRow } from "@/lib/types";
import { TeamBadge } from "@/components/Badges";
import { EmptyState } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const PLAYOFF = "rgb(56, 115, 217)";
const RELEGATION = "rgb(209, 71, 71)";
const NEUTRAL = "color-mix(in srgb, var(--ink) 8%, transparent)";

export type StandingLegendItem = {
  id: string;
  color: string;
  label: string;
  start: number;
  end: number;
};

/** Výchozí zóny podle velikosti tabulky a typu soutěže — port StandingLegendItem.defaults */
export function standingLegendDefaults(
  teamCount: number,
  competitionSlug?: string | null
): StandingLegendItem[] {
  if (teamCount <= 0) return [];

  const playoffEnd = Math.min(8, Math.max(Math.floor(teamCount / 2), 1));
  const relegationCount = teamCount >= 8 ? 2 : teamCount >= 5 ? 1 : 0;
  const relegationStart = teamCount - relegationCount + 1;

  const playoffLabel =
    competitionSlug === "extraliga" ||
    competitionSlug === "1liga" ||
    competitionSlug === "2liga"
      ? "Postup do čtvrtfinále"
      : competitionSlug === "zeny" || competitionSlug === "prebor-zen"
        ? "Postup do play-off"
        : "Postup do play-off";

  const relegationLabel =
    competitionSlug === "extraliga"
      ? "Sestup"
      : competitionSlug === "1liga" || competitionSlug === "2liga"
        ? "Sestupová příčka"
        : "Sestup";

  const items: StandingLegendItem[] = [
    { id: "playoff", color: PLAYOFF, label: playoffLabel, start: 1, end: playoffEnd },
  ];

  if (relegationCount > 0 && relegationStart > playoffEnd) {
    items.push({
      id: "relegation",
      color: RELEGATION,
      label: relegationLabel,
      start: relegationStart,
      end: teamCount,
    });
  }

  return items;
}

function zoneColor(rank: number, legend: StandingLegendItem[]): string {
  const item = legend.find((l) => rank >= l.start && rank <= l.end);
  return item?.color ?? NEUTRAL;
}

function rankInZone(rank: number, legend: StandingLegendItem[]): boolean {
  return legend.some((l) => rank >= l.start && rank <= l.end);
}

/**
 * Jednotná ligová tabulka — port StandingsTableView.swift
 * (# | Tým + badge | Z | G GF:GA | B) + legenda + highlight.
 */
export function StandingsTable({
  rows,
  highlightTeamIds,
  competitionSlug,
  emptyMessage = "Tabulka pro tuto soutěž není k dispozici.",
  showsFavoriteStar = false,
  legend,
  topPadding = true,
}: {
  rows: StandingRow[];
  highlightTeamIds?: string[];
  competitionSlug?: string | null;
  emptyMessage?: string;
  showsFavoriteStar?: boolean;
  legend?: StandingLegendItem[];
  topPadding?: boolean;
}) {
  const { teamById } = useCatalog();
  const { push } = useNav();
  const fav = useFavorites();
  const highlight = new Set(highlightTeamIds ?? []);
  const resolvedLegend = legend ?? standingLegendDefaults(rows.length, competitionSlug);

  if (!rows.length) {
    return (
      <div className={topPadding ? "pt-8" : undefined}>
        <EmptyState title="Bez tabulky" hint={emptyMessage} />
      </div>
    );
  }

  return (
    <div className={topPadding ? "pt-2" : undefined}>
      <div
        className={`flex items-center py-2.5 text-[11px] font-semibold text-hb-faint ${
          showsFavoriteStar ? "pl-4 pr-2" : "px-4"
        }`}
      >
        <span className="w-7 text-left">#</span>
        <span className="flex-1 text-left">Tým</span>
        <span className="w-7 text-right">Z</span>
        <span className="w-[52px] text-right">G</span>
        <span className="w-7 text-right">B</span>
        {showsFavoriteStar ? <span className="w-9" /> : null}
      </div>

      {rows.map((row) => {
        const team = teamById(row.teamId);
        const highlighted = highlight.has(row.teamId);
        const zone = zoneColor(row.rank, resolvedLegend);
        const inZone = rankInZone(row.rank, resolvedLegend);

        return (
          <div
            key={row.id}
            className={`relative flex items-center gap-2 border-b border-separator py-2.5 ${
              showsFavoriteStar ? "pl-4 pr-2" : "px-4"
            }`}
            style={{
              background: highlighted
                ? "color-mix(in srgb, var(--brand) 6%, transparent)"
                : undefined,
            }}
          >
            {highlighted && <span className="absolute inset-y-0 left-0 w-[3px] bg-brand" />}
            <button
              type="button"
              onClick={() => push({ name: "team", id: row.teamId })}
              className="flex min-w-0 flex-1 items-center gap-2 text-left"
            >
              <span
                className="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full text-[11px] font-bold tabular-nums"
                style={{
                  background: zone,
                  color: inZone ? "#fff" : "var(--text-secondary)",
                }}
              >
                {row.rank}
              </span>
              <TeamBadge team={team} size={22} />
              <span
                className={`min-w-0 flex-1 truncate text-[14px] text-hb-fg ${
                  highlighted ? "font-bold" : "font-semibold"
                }`}
              >
                {team?.shortName ?? row.teamId}
              </span>
              <span className="w-7 text-right text-[13px] tabular-nums text-hb-muted">
                {row.played}
              </span>
              <span className="w-[52px] text-right text-[13px] tabular-nums text-hb-muted">
                {row.goalsFor}:{row.goalsAgainst}
              </span>
              <span className="w-7 text-right text-[13px] font-bold tabular-nums text-brand">
                {row.points}
              </span>
            </button>
            {showsFavoriteStar ? (
              <button
                type="button"
                className={`flex h-9 w-9 items-center justify-center ${
                  fav.isTeam(row.teamId) ? "text-brand" : "text-hb-faint"
                }`}
                onClick={() => fav.toggleTeam(row.teamId)}
                aria-label="Oblíbený tým"
              >
                ★
              </button>
            ) : null}
          </div>
        );
      })}

      {resolvedLegend.length > 0 && (
        <div className="space-y-2 px-4 pt-3.5 pb-2">
          {resolvedLegend.map((item) => (
            <div key={item.id} className="flex items-center gap-2">
              <span
                className="h-2.5 w-2.5 shrink-0 rounded-full"
                style={{ background: item.color }}
              />
              <span className="text-[12px] font-medium text-hb-muted">{item.label}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

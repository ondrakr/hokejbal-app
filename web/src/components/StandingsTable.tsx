"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import type { Match, StandingRow } from "@/lib/types";
import {
  buildStandingsView,
  FORM_WINDOWS,
  STANDINGS_SCOPES,
  standingsScopeHasLive,
  type FormWindow,
  type StandingViewRow,
  type StandingsScope,
} from "@/lib/standingsViews";
import { TeamBadge } from "@/components/Badges";
import { Pill, PillTrack } from "@/components/MatchRow";
import { EmptyState } from "@/components/ui";
import { mergeMatchesWithLive } from "@/lib/mergeLiveMatches";
import { useCatalog } from "@/stores/catalog";
import { useLiveMatches } from "@/stores/liveMatches";
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

function liveToneColor(tone: "win" | "draw" | "loss") {
  return tone === "win" ? "var(--win)" : tone === "draw" ? "var(--draw)" : "var(--loss)";
}

/** Flashscore-style: živé Z/G/B u týmů v live zápase. */
const LIVE_STATS = "#ff2d55";

function LiveScoreChip({ text, tone }: { text: string; tone: "win" | "draw" | "loss" }) {
  return (
    <span
      className="shrink-0 whitespace-nowrap rounded-[4px] px-1.5 py-0.5 font-bold tabular-nums text-white"
      style={{ fontSize: 11, background: liveToneColor(tone), lineHeight: 1.2 }}
    >
      {text}
    </span>
  );
}

function RankDelta({ delta }: { delta: number }) {
  if (!delta) return null;
  const up = delta > 0;
  return (
    <span
      className="shrink-0 whitespace-nowrap font-bold tabular-nums"
      style={{ fontSize: 10, color: up ? "var(--win)" : "var(--loss)" }}
    >
      {up ? "▲" : "▼"}
      {up ? `+${delta}` : delta}
    </span>
  );
}

/**
 * Ligová tabulka s podmenu Live / Celkem / Doma / Venku / Forma (+ 5/10/15).
 */
export function StandingsTable({
  rows,
  matches = [],
  competitionId,
  highlightTeamIds,
  competitionSlug,
  emptyMessage = "Tabulka pro tuto soutěž není k dispozici.",
  legend,
  topPadding = true,
}: {
  rows: StandingRow[];
  /** Zápasy soutěže — pro Live / Doma / Venku / Forma. */
  matches?: Match[];
  competitionId?: string;
  highlightTeamIds?: string[];
  competitionSlug?: string | null;
  emptyMessage?: string;
  legend?: StandingLegendItem[];
  topPadding?: boolean;
}) {
  const { teamById } = useCatalog();
  const { push } = useNav();
  const liveMatches = useLiveMatches();
  const highlight = new Set(highlightTeamIds ?? []);

  const mergedMatches = useMemo(
    () => mergeMatchesWithLive(matches, liveMatches, competitionId),
    [matches, liveMatches, competitionId]
  );

  const hasLive = Boolean(
    competitionId && standingsScopeHasLive(mergedMatches, competitionId)
  );
  const [scope, setScope] = useState<StandingsScope>("total");
  const [formWindow, setFormWindow] = useState<FormWindow>(5);
  const userPickedScope = useRef(false);

  useEffect(() => {
    if (userPickedScope.current) return;
    if (hasLive) setScope("live");
  }, [hasLive]);

  const viewRows: StandingViewRow[] = useMemo(() => {
    if (!competitionId || !rows.length) return rows.map((r) => ({ ...r }));
    return buildStandingsView({
      base: rows,
      matches: mergedMatches,
      competitionId,
      scope,
      formWindow,
    });
  }, [rows, mergedMatches, competitionId, scope, formWindow]);

  const resolvedLegend =
    legend ?? standingLegendDefaults(viewRows.length, competitionSlug);

  if (!rows.length) {
    return (
      <div className={topPadding ? "pt-8" : undefined}>
        <EmptyState title="Bez tabulky" hint={emptyMessage} />
      </div>
    );
  }

  return (
    <div className={topPadding ? "pt-1" : undefined}>
      {competitionId ? (
        <>
          <PillTrack>
            {STANDINGS_SCOPES.map((s) => (
              <Pill
                key={s.id}
                active={scope === s.id}
                onClick={() => {
                  userPickedScope.current = true;
                  setScope(s.id);
                }}
              >
                {s.label}
              </Pill>
            ))}
          </PillTrack>
          {scope === "form" ? (
            <PillTrack>
              {FORM_WINDOWS.map((w) => (
                <Pill key={w} active={formWindow === w} onClick={() => setFormWindow(w)}>
                  {w} zápasů
                </Pill>
              ))}
            </PillTrack>
          ) : null}
        </>
      ) : null}

      <div
        className="flex items-center px-4 py-2.5 font-semibold"
        style={{ fontSize: 11, color: "var(--text-tertiary)" }}
      >
        <span className="w-7 shrink-0 text-left">#</span>
        <span className="min-w-0 flex-1 text-left">Tým</span>
        <span className="w-7 shrink-0 text-right">Z</span>
        <span className="w-[52px] shrink-0 text-right">G</span>
        <span className="w-7 shrink-0 text-right">B</span>
      </div>

      {viewRows.map((row) => {
        const team = teamById(row.teamId);
        const highlighted = highlight.has(row.teamId);
        const zone = zoneColor(row.rank, resolvedLegend);
        const inZone = rankInZone(row.rank, resolvedLegend);
        const isLiveRow = Boolean(row.liveScore);
        const statsColor = isLiveRow ? LIVE_STATS : "var(--text-secondary)";
        const pointsColor = isLiveRow ? LIVE_STATS : "var(--brand)";

        return (
          <div
            key={row.id}
            className="relative flex items-center gap-2 border-b border-separator px-4 py-2.5"
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
              className="flex min-w-0 flex-1 flex-nowrap items-center gap-2 text-left"
            >
              <span
                className="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full font-bold tabular-nums"
                style={{
                  fontSize: 11,
                  background: zone,
                  color: inZone ? "#fff" : "var(--text-secondary)",
                }}
              >
                {row.rank}
              </span>
              <TeamBadge team={team} size={22} />
              <span className="flex min-w-0 flex-1 items-center gap-1">
                <span
                  className="min-w-0 truncate"
                  style={{
                    fontSize: 14,
                    color: "var(--text-primary)",
                    fontWeight: highlighted ? 700 : 600,
                  }}
                >
                  {team?.shortName ?? row.teamId}
                </span>
                {typeof row.rankDelta === "number" && row.rankDelta !== 0 ? (
                  <RankDelta delta={row.rankDelta} />
                ) : null}
              </span>
              {row.liveScore ? (
                <LiveScoreChip text={row.liveScore.text} tone={row.liveScore.tone} />
              ) : null}
              <span
                className="w-7 shrink-0 whitespace-nowrap text-right tabular-nums"
                style={{ fontSize: 13, color: statsColor, fontWeight: isLiveRow ? 700 : 400 }}
              >
                {row.played}
              </span>
              <span
                className="w-[52px] shrink-0 whitespace-nowrap text-right tabular-nums"
                style={{ fontSize: 13, color: statsColor, fontWeight: isLiveRow ? 700 : 400 }}
              >
                {row.goalsFor}:{row.goalsAgainst}
              </span>
              <span
                className="w-7 shrink-0 whitespace-nowrap text-right font-bold tabular-nums"
                style={{ fontSize: 13, color: pointsColor }}
              >
                {row.points}
              </span>
            </button>
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
              <span
                className="font-medium"
                style={{ fontSize: 12, color: "var(--text-secondary)" }}
              >
                {item.label}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

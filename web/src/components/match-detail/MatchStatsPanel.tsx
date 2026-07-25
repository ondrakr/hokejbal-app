"use client";

import { useState } from "react";
import type { Match } from "@/lib/types";
import { Pill, PillTrack } from "@/components/MatchRow";

type StatsScope = "Zápas" | "1. třetina" | "2. třetina" | "3. třetina";

const SCOPES: StatsScope[] = ["Zápas", "1. třetina", "2. třetina", "3. třetina"];

function penaltyCount(match: Match, teamId: string) {
  return match.events.filter((e) => e.kind === "penalty" && e.teamId === teamId).length;
}

function resolvedShots(home: boolean, match: Match): number {
  if (match.status === "scheduled") return 0;
  if (home && match.homeShots != null) return match.homeShots;
  if (!home && match.awayShots != null) return match.awayShots;
  const score = home ? match.homeScore : match.awayScore;
  return Math.max(score * 7 + 10, 8);
}

function periodScore(scores: number[], index: number) {
  return index < scores.length ? scores[index]! : 0;
}

function ComparisonStat({ title, home, away }: { title: string; home: number; away: number }) {
  const total = Math.max(home + away, 1);
  const homeRatio = home / total;
  const awayRatio = away / total;

  return (
    <div className="space-y-2">
      <div className="flex items-center">
        <span className="w-10 text-left text-[16px] font-bold tabular-nums text-hb-fg">{home}</span>
        <span className="flex-1 text-center text-[13px] font-semibold text-hb-muted">{title}</span>
        <span className="w-10 text-right text-[16px] font-bold tabular-nums text-hb-fg">{away}</span>
      </div>
      <div className="flex gap-1">
        <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-[color-mix(in_srgb,var(--ink)_8%,transparent)]">
          <div
            className="ml-auto h-full rounded-full bg-brand"
            style={{
              width: home > 0 ? `max(6px, ${homeRatio * 100}%)` : "0",
            }}
          />
        </div>
        <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-[color-mix(in_srgb,var(--ink)_8%,transparent)]">
          <div
            className="h-full rounded-full"
            style={{
              width: away > 0 ? `max(6px, ${awayRatio * 100}%)` : "0",
              background: "color-mix(in srgb, var(--ink) 75%, transparent)",
            }}
          />
        </div>
      </div>
    </div>
  );
}

function MetaStat({ title, value }: { title: string; value: string }) {
  return (
    <div className="space-y-1.5 pt-1 text-center">
      <div className="text-[13px] font-semibold text-hb-muted">{title}</div>
      <div className="text-[15px] font-bold text-hb-fg">{value}</div>
    </div>
  );
}

export function MatchStatsPanel({ match }: { match: Match }) {
  const [scope, setScope] = useState<StatsScope>("Zápas");
  const scheduled = match.status === "scheduled";

  const homeShots = scheduled ? 0 : resolvedShots(true, match);
  const awayShots = scheduled ? 0 : resolvedShots(false, match);
  const homePen = scheduled ? 0 : penaltyCount(match, match.homeTeamId);
  const awayPen = scheduled ? 0 : penaltyCount(match, match.awayTeamId);
  const homePP = scheduled ? 0 : awayPen;
  const awayPP = scheduled ? 0 : homePen;
  const homePPG = scheduled ? 0 : (match.homePowerplayGoals ?? 0);
  const awayPPG = scheduled ? 0 : (match.awayPowerplayGoals ?? 0);
  const homeSH = scheduled ? 0 : (match.homeShorthandedGoals ?? 0);
  const awaySH = scheduled ? 0 : (match.awayShorthandedGoals ?? 0);

  const periodIndex = scope === "1. třetina" ? 0 : scope === "2. třetina" ? 1 : 2;

  return (
    <div>
      <PillTrack>
        {SCOPES.map((s) => (
          <Pill key={s} active={scope === s} onClick={() => setScope(s)}>
            {s}
          </Pill>
        ))}
      </PillTrack>

      <div className="space-y-[22px] px-4 pb-5">
        {scope === "Zápas" ? (
          <>
            <ComparisonStat title="Střely" home={homeShots} away={awayShots} />
            <ComparisonStat title="Vyloučení" home={homePen} away={awayPen} />
            <ComparisonStat title="Přesilovky" home={homePP} away={awayPP} />
            <ComparisonStat title="Využití" home={homePPG} away={awayPPG} />
            <ComparisonStat title="Oslabení" home={homeSH} away={awaySH} />
            <MetaStat
              title="Počet diváků"
              value={scheduled ? "0" : match.attendance != null ? String(match.attendance) : "—"}
            />
          </>
        ) : (
          <>
            <ComparisonStat
              title="Góly"
              home={scheduled ? 0 : periodScore(match.homePeriodScores, periodIndex)}
              away={scheduled ? 0 : periodScore(match.awayPeriodScores, periodIndex)}
            />
            {!scheduled && (
              <p className="pt-2 text-center text-[12px] font-medium text-hb-faint">
                Detailní statistiky po třetinách budou doplněny.
              </p>
            )}
          </>
        )}
      </div>
    </div>
  );
}

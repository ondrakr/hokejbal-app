"use client";

import type { Match, Team } from "@/lib/types";
import { APP_TZ, parseDate } from "@/lib/format";
import { teamFormColor, teamFormOutcome } from "@/lib/teamForm";
import { TeamBadge } from "@/components/Badges";
import { IconTv } from "@/components/Icons";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

/** dd.MM. — port TeamResultRow.shortDate (Europe/Prague) */
function resultShortDate(iso: string) {
  return new Intl.DateTimeFormat("cs-CZ", {
    timeZone: APP_TZ,
    day: "2-digit",
    month: "2-digit",
  }).format(parseDate(iso));
}

/**
 * Řádek výsledku na stránce týmu — port TeamResultRow (TeamDetailView.swift).
 * datum | loga+názvy | stav | skóre | V/R/P
 */
export function TeamResultRow({
  match,
  focusTeamId,
}: {
  match: Match;
  focusTeamId: string;
}) {
  const { teamById } = useCatalog();
  const { push } = useNav();
  const home = teamById(match.homeTeamId);
  const away = teamById(match.awayTeamId);
  const isLive = match.status === "live";
  const isDraw = match.homeScore === match.awayScore;
  const outcome = teamFormOutcome(match, focusTeamId);
  const isOvertime =
    match.period.toLowerCase().includes("prodl") ||
    match.period.toLowerCase().includes("ot") ||
    match.period.toLowerCase().includes("overtime");

  return (
    <button
      type="button"
      onClick={() => push({ name: "match", id: match.id })}
      className="flex w-full items-center gap-2.5 border-b border-separator px-4 py-3 text-left"
    >
      <span className="w-10 shrink-0 text-left text-[11px] font-medium text-hb-faint">
        {resultShortDate(match.scheduledAt)}
      </span>

      <div className="flex min-w-0 flex-1 flex-col gap-1.5">
        <TeamLine
          team={home}
          emphasize={match.homeScore > match.awayScore}
        />
        <TeamLine
          team={away}
          emphasize={match.awayScore > match.homeScore}
        />
      </div>

      {match.streamURL ? (
        <span className="shrink-0 text-brand">
          <IconTv size={12} />
        </span>
      ) : null}

      <div className="flex shrink-0 flex-col items-end gap-1.5">
        {isLive ? (
          <span className="text-[10px] font-bold text-live">LIVE</span>
        ) : isOvertime ? (
          <span className="text-[10px] font-medium text-hb-faint">Po prodl.</span>
        ) : null}
        <div className="flex flex-col items-end gap-1.5 text-hb-fg">
          <span
            className={`text-[14px] tabular-nums ${
              match.homeScore > match.awayScore ? "font-bold" : "font-semibold"
            }`}
          >
            {match.homeScore}
          </span>
          <span
            className={`text-[14px] tabular-nums ${
              match.awayScore > match.homeScore ? "font-bold" : "font-semibold"
            }`}
          >
            {match.awayScore}
          </span>
        </div>
      </div>

      <ResultBadge isLive={isLive} isDraw={isDraw} outcome={outcome} />
    </button>
  );
}

function TeamLine({
  team,
  emphasize,
}: {
  team?: Team;
  emphasize: boolean;
}) {
  return (
    <div className="flex min-w-0 items-center gap-2">
      <TeamBadge team={team} size={16} />
      <span
        className={`truncate text-[13px] text-hb-fg ${
          emphasize ? "font-bold" : "font-normal"
        }`}
      >
        {team?.shortName ?? "—"}
      </span>
    </div>
  );
}

function ResultBadge({
  isLive,
  isDraw,
  outcome,
}: {
  isLive: boolean;
  isDraw: boolean;
  outcome: "win" | "draw" | "loss";
}) {
  if (isLive) {
    return (
      <span className="flex h-[22px] w-[22px] items-center justify-center text-[14px] font-bold text-live">
        •
      </span>
    );
  }
  if (isDraw) {
    return (
      <span
        className="flex h-[22px] w-[22px] items-center justify-center rounded-[3px] text-[12px] font-bold text-white"
        style={{ background: teamFormColor("draw") }}
      >
        R
      </span>
    );
  }
  return (
    <span
      className="flex h-[22px] w-[22px] items-center justify-center rounded-[3px] text-[12px] font-bold text-white"
      style={{ background: teamFormColor(outcome) }}
    >
      {outcome === "win" ? "V" : "P"}
    </span>
  );
}

"use client";

import {
  matchPhaseLabel,
  matchStatusLabel,
  useAmateur,
  type AmateurMatch,
} from "@/stores/amateur";
import { AmateurBadge } from "./AmateurBadge";

export function AmateurMatchRow({
  match,
  onClick,
}: {
  match: AmateurMatch;
  onClick?: () => void;
}) {
  const { team } = useAmateur();
  const home = team(match.homeTeamId);
  const away = team(match.awayTeamId);

  const timeLabel = (() => {
    try {
      return new Intl.DateTimeFormat("cs-CZ", {
        weekday: "short",
        day: "numeric",
        month: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      }).format(new Date(match.scheduledAt));
    } catch {
      return "";
    }
  })();

  const score =
    match.status === "scheduled" ? "vs" : `${match.homeScore}:${match.awayScore}`;

  const content = (
    <div className="hb-card flex w-full flex-col gap-2.5 p-3.5 text-left">
      <div className="flex items-center gap-2">
        <span
          className={`text-[10px] font-bold uppercase ${
            match.phase === "playoff" ? "text-brand" : "text-hb-faint"
          }`}
        >
          {matchPhaseLabel(match)}
        </span>
        <span className="ml-auto text-[11px] font-semibold text-hb-faint">{timeLabel}</span>
        <span
          className={`text-[10px] font-bold uppercase ${
            match.status === "live" ? "text-live" : "text-hb-faint"
          }`}
        >
          {matchStatusLabel(match.status)}
        </span>
      </div>
      <div className="flex items-center gap-2">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          {home ? <AmateurBadge team={home} size={28} /> : null}
          <span className="truncate text-[14px] font-bold text-hb-fg">
            {home?.shortName ?? "?"}
          </span>
        </div>
        <span className="hb-number w-16 shrink-0 text-center text-[20px] font-extrabold text-hb-fg">
          {score}
        </span>
        <div className="flex min-w-0 flex-1 items-center justify-end gap-2">
          <span className="truncate text-[14px] font-bold text-hb-fg">
            {away?.shortName ?? "?"}
          </span>
          {away ? <AmateurBadge team={away} size={28} /> : null}
        </div>
      </div>
    </div>
  );

  if (!onClick) return content;
  return (
    <button type="button" onClick={onClick} className="w-full">
      {content}
    </button>
  );
}

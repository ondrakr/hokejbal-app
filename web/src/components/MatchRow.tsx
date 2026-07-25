"use client";

import type { Match, Team } from "@/lib/types";
import {
  formatFinishedStamp,
  formatMatchTime,
  formatShortDate,
  shortPeriodLabel,
} from "@/lib/format";
import { TeamBadge } from "@/components/Badges";
import { IconTv } from "@/components/Icons";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

export function LiveBadge({ compact = false }: { compact?: boolean }) {
  return (
    <span className="hb-live-badge" data-compact={compact}>
      <span className="hb-live-dot" />
      {compact ? "LIVE" : "ŽIVĚ"}
    </span>
  );
}

/**
 * 1:1 port MatchRowView.swift — elevated karta s accent stripem.
 */
export function MatchRow({
  match,
  showCompetition = false,
  competitionName,
  embedded = false,
  width,
}: {
  match: Match;
  showCompetition?: boolean;
  competitionName?: string;
  embedded?: boolean;
  width?: number;
}) {
  const { teamById, competitionById } = useCatalog();
  const { push } = useNav();
  const home = teamById(match.homeTeamId);
  const away = teamById(match.awayTeamId);
  const comp = competitionById(match.competitionId);
  const compLabel = competitionName ?? comp?.name;
  const isBroadcast = Boolean(match.streamURL);
  const homeLeads = match.status !== "scheduled" && match.homeScore > match.awayScore;
  const awayLeads = match.status !== "scheduled" && match.awayScore > match.homeScore;

  const accent =
    match.status === "live"
      ? "var(--live)"
      : match.status === "scheduled"
        ? "var(--brand)"
        : match.status === "postponed"
          ? "#f97316"
          : "color-mix(in srgb, var(--brand) 35%, transparent)";

  const scoreColor = (leads: boolean) => {
    if (match.status === "live") return leads ? "var(--live)" : "var(--text-secondary)";
    return leads ? "var(--text-primary)" : "var(--text-secondary)";
  };

  const headerLeading = (() => {
    if (match.status === "finished") {
      return (
        <span className="truncate text-[10px] font-bold tracking-[0.3px] text-hb-faint">
          {formatFinishedStamp(match.scheduledAt)}
        </span>
      );
    }
    if (match.status === "scheduled") {
      return (
        <span className="truncate text-[10px] font-bold tracking-[0.3px] text-hb-faint">
          {formatShortDate(match.scheduledAt)}
        </span>
      );
    }
    if (match.status === "live") {
      if (showCompetition && compLabel) {
        return (
          <span className="truncate text-[10px] font-bold tracking-[0.4px] text-hb-faint">
            {compLabel.toUpperCase()}
          </span>
        );
      }
      return (
        <span className="truncate text-[10px] font-bold tracking-[0.4px] text-live">
          {shortPeriodLabel(match.period)}
        </span>
      );
    }
    if (showCompetition && compLabel) {
      return (
        <span className="truncate text-[10px] font-bold tracking-[0.4px] text-hb-faint">
          {compLabel.toUpperCase()}
        </span>
      );
    }
    return null;
  })();

  const teamNameRow = (team: Team | undefined, emphasized: boolean) => (
    <div className="flex min-w-0 items-center gap-2.5">
      <div className="flex h-[26px] w-[26px] shrink-0 items-center justify-center">
        <TeamBadge team={team} size={24} />
      </div>
      <span
        className="truncate text-[15px]"
        style={{
          fontWeight: emphasized ? 700 : 600,
          color: emphasized ? "var(--text-primary)" : "color-mix(in srgb, var(--text-primary) 88%, transparent)",
        }}
      >
        {team?.shortName ?? "—"}
      </span>
    </div>
  );

  const teamRow = (team: Team | undefined, score: number, leads: boolean) => (
    <div className="flex min-w-0 items-center gap-2.5">
      <div className="flex h-[26px] w-[26px] shrink-0 items-center justify-center">
        <TeamBadge team={team} size={24} />
      </div>
      <span
        className="min-w-0 flex-1 truncate text-[15px]"
        style={{
          fontWeight: leads ? 700 : 500,
          color: leads
            ? "var(--text-primary)"
            : "color-mix(in srgb, var(--text-primary) 82%, transparent)",
        }}
      >
        {team?.shortName ?? "—"}
      </span>
      <span
        className="hb-number min-w-[28px] text-right text-[20px]"
        style={{
          fontWeight: leads ? 800 : 600,
          color: scoreColor(leads),
        }}
      >
        {score}
      </span>
    </div>
  );

  const inner = (
    <div className="flex">
      <div className="w-[4px] shrink-0 self-stretch" style={{ background: accent }} />
      <div className="flex min-w-0 flex-1 flex-col gap-[11px] px-[14px] py-[13px]">
        <div className="flex items-center gap-1.5">
          <div className="min-w-0 flex-1">{headerLeading}</div>
          {isBroadcast && (
            <span className="text-brand">
              <IconTv size={12} />
            </span>
          )}
          {match.status === "live" && <LiveBadge compact />}
          {match.status === "finished" && (
            <span
              className="rounded-full px-2 py-1 text-[11px] font-bold tracking-[0.3px] text-hb-faint"
              style={{ background: "color-mix(in srgb, var(--text-tertiary) 12%, transparent)" }}
            >
              KONEC
            </span>
          )}
          {match.status === "postponed" && (
            <span className="rounded-full bg-orange-500/15 px-2 py-1 text-[11px] font-bold text-orange-500">
              ODLOŽ.
            </span>
          )}
        </div>

        {match.status === "scheduled" ? (
          <div className="flex items-center gap-3">
            <div className="flex min-w-0 flex-1 flex-col gap-[9px]">
              {teamNameRow(home, false)}
              {teamNameRow(away, false)}
            </div>
            <span className="hb-number min-w-[56px] text-right text-[22px] font-extrabold text-brand">
              {formatMatchTime(match.scheduledAt)}
            </span>
          </div>
        ) : (
          <>
            {teamRow(home, match.homeScore, homeLeads)}
            {teamRow(away, match.awayScore, awayLeads)}
          </>
        )}
      </div>
    </div>
  );

  return (
    <button
      type="button"
      onClick={() => push({ name: "match", id: match.id })}
      className={`block w-full text-left ${embedded ? "" : "px-4 py-[5px]"}`}
      style={width ? { width } : undefined}
    >
      <div
        className={`overflow-hidden ${embedded ? "hb-card h-full" : "hb-card"}`}
        style={embedded ? { width: width ?? 250 } : undefined}
      >
        {inner}
      </div>
    </button>
  );
}

export function Pill({
  active,
  children,
  onClick,
}: {
  active?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex-1 rounded-[10px] py-2 text-[12px] font-bold transition ${
        active
          ? "bg-card text-hb-fg shadow-[0_1px_2px_rgba(0,0,0,0.06)]"
          : "text-hb-muted"
      }`}
    >
      {children}
    </button>
  );
}

/** HBPillSelector track */
export function PillTrack({ children }: { children: React.ReactNode }) {
  return (
    <div className="px-4 py-3">
      <div className="flex gap-[3px] rounded-[12px] bg-card-inset p-1">{children}</div>
    </div>
  );
}

/** HBUnderlineTabs */
export function UnderlineTabs({
  tabs,
  value,
  onChange,
}: {
  tabs: string[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="flex h-[46px] items-stretch gap-1 overflow-x-auto border-b border-separator bg-surface px-0.5">
      {tabs.map((t) => {
        const active = value === t;
        return (
          <button
            key={t}
            type="button"
            onClick={() => onChange(t)}
            className={`relative shrink-0 px-3 pt-3 text-[12px] font-bold tracking-[0.3px] uppercase ${
              active ? "text-brand" : "text-hb-faint"
            }`}
          >
            {t}
            {active && (
              <span className="absolute inset-x-3 bottom-0 h-[3px] rounded-full bg-brand" />
            )}
          </button>
        );
      })}
    </div>
  );
}

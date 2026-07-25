"use client";

import type { Match, Team } from "@/lib/types";
import { formatMatchTime } from "@/lib/format";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

function TeamMark({ team }: { team?: Team }) {
  if (!team) return <div className="h-8 w-8 rounded-full bg-[var(--card-inset)]" />;
  if (team.logoURL) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img src={team.logoURL} alt="" className="h-8 w-8 rounded-full object-cover" />
    );
  }
  return (
    <div
      className="flex h-8 w-8 items-center justify-center rounded-full text-[10px] font-bold text-white"
      style={{ background: team.primaryColorHex || "var(--brand)" }}
    >
      {team.logoInitials}
    </div>
  );
}

export function MatchRow({ match, compact }: { match: Match; compact?: boolean }) {
  const { teamById, competitionById } = useCatalog();
  const { push } = useNav();
  const home = teamById(match.homeTeamId);
  const away = teamById(match.awayTeamId);
  const comp = competitionById(match.competitionId);
  const live = match.status === "live";
  const finished = match.status === "finished";
  const showScore = live || finished;

  return (
    <button
      type="button"
      onClick={() => push({ name: "match", id: match.id })}
      className="flex w-full items-center gap-3 border-b border-[var(--separator)] bg-[var(--card)] px-[var(--screen-pad)] py-3 text-left transition active:bg-[var(--card-inset)]"
    >
      <div className="w-12 shrink-0 text-center">
        {live ? (
          <div className="flex flex-col items-center gap-1">
            <span className="hb-live-dot" />
            <span className="text-[10px] font-bold text-[var(--live)]">LIVE</span>
            {match.clock && <span className="text-[10px] text-[var(--text-secondary)]">{match.clock}</span>}
          </div>
        ) : (
          <div className="text-[12px] font-semibold text-[var(--text-secondary)]">
            {formatMatchTime(match.scheduledAt)}
          </div>
        )}
      </div>
      <div className="min-w-0 flex-1">
        {!compact && comp && (
          <div className="mb-1 truncate text-[11px] font-medium text-[var(--text-tertiary)]">
            {comp.shortName || comp.name}
          </div>
        )}
        <div className="flex items-center gap-2">
          <TeamMark team={home} />
          <span className="truncate text-[14px] font-semibold">{home?.shortName ?? "—"}</span>
          {showScore && (
            <span className="ml-auto font-[family-name:var(--font-display)] text-[16px] font-extrabold tabular-nums">
              {match.homeScore}
            </span>
          )}
        </div>
        <div className="mt-1 flex items-center gap-2">
          <TeamMark team={away} />
          <span className="truncate text-[14px] font-semibold">{away?.shortName ?? "—"}</span>
          {showScore && (
            <span className="ml-auto font-[family-name:var(--font-display)] text-[16px] font-extrabold tabular-nums">
              {match.awayScore}
            </span>
          )}
        </div>
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
      className={`rounded-full px-3 py-1.5 text-[12px] font-semibold whitespace-nowrap ${
        active
          ? "bg-[var(--brand)] text-white"
          : "bg-[var(--card-inset)] text-[var(--text-secondary)]"
      }`}
    >
      {children}
    </button>
  );
}

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
    <div className="flex gap-4 overflow-x-auto border-b border-[var(--separator)] px-[var(--screen-pad)]">
      {tabs.map((t) => (
        <button
          key={t}
          type="button"
          onClick={() => onChange(t)}
          className={`relative shrink-0 pb-2.5 pt-2 text-[13px] font-semibold ${
            value === t ? "text-[var(--text-primary)]" : "text-[var(--text-secondary)]"
          }`}
        >
          {t}
          {value === t && (
            <span className="absolute inset-x-0 bottom-0 h-0.5 rounded-full bg-[var(--brand)]" />
          )}
        </button>
      ))}
    </div>
  );
}

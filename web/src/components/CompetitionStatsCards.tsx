"use client";

import type { PlayerStatRow, TeamStatRow } from "@/lib/competitionStats";
import { PlayerAvatar, TeamBadge } from "@/components/Badges";
import { playerFullName } from "@/lib/types";

/** 1:1 s iOS PlayerStatLeaderCardView */
export function PlayerStatLeaderCard({
  title,
  leader,
  onClick,
}: {
  title: string;
  leader: PlayerStatRow | null;
  onClick?: () => void;
}) {
  if (!leader) {
    return (
      <div className="hb-card flex min-h-[168px] flex-col items-center justify-center px-2.5 py-3 text-center">
        <div className="font-semibold" style={{ fontSize: 12, color: "var(--text-tertiary)" }}>
          {title}
        </div>
        <div className="mt-2 font-medium" style={{ fontSize: 13, color: "var(--text-secondary)" }}>
          —
        </div>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={onClick}
      className="hb-card flex min-h-[168px] w-full flex-col items-center px-2.5 py-3 text-center"
    >
      <div className="relative">
        <PlayerAvatar player={leader.player} size={56} circle />
        {leader.team ? (
          <span className="absolute -right-1 -bottom-1 flex h-6 w-6 items-center justify-center rounded-full bg-card shadow-[0_1px_3px_rgba(0,0,0,0.15)]">
            <TeamBadge team={leader.team} size={18} />
          </span>
        ) : null}
      </div>
      <div
        className="mt-2.5 line-clamp-1 w-full font-bold"
        style={{ fontSize: 13, color: "var(--text-primary)" }}
      >
        {playerFullName(leader.player)}
      </div>
      <div className="line-clamp-1 w-full font-medium" style={{ fontSize: 11, color: "var(--text-secondary)" }}>
        {leader.team?.shortName ?? "—"}
      </div>
      <div className="mt-2 flex items-baseline gap-1">
        <span className="hb-number font-extrabold" style={{ fontSize: 26, color: "var(--text-primary)" }}>
          {leader.display}
        </span>
        {leader.unit ? (
          <span className="font-bold" style={{ fontSize: 12, color: "var(--text-secondary)" }}>
            {leader.unit}
          </span>
        ) : null}
      </div>
      <div
        className="mt-1 line-clamp-2 font-semibold leading-snug"
        style={{ fontSize: 11, color: "var(--text-tertiary)" }}
      >
        {title}
      </div>
    </button>
  );
}

/** 1:1 s iOS TeamStatLeaderCardView */
export function TeamStatLeaderCard({
  title,
  leader,
  onClick,
}: {
  title: string;
  leader: TeamStatRow | null;
  onClick?: () => void;
}) {
  if (!leader) {
    return (
      <div className="hb-card flex min-h-[168px] flex-col items-center justify-center px-2.5 py-3 text-center">
        <div className="font-semibold" style={{ fontSize: 12, color: "var(--text-tertiary)" }}>
          {title}
        </div>
        <div className="mt-2 font-medium" style={{ fontSize: 13, color: "var(--text-secondary)" }}>
          —
        </div>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={onClick}
      className="hb-card flex min-h-[168px] w-full flex-col items-center px-2.5 py-3 text-center"
    >
      <TeamBadge team={leader.team} size={52} />
      <div
        className="mt-2.5 line-clamp-2 w-full font-bold"
        style={{ fontSize: 13, color: "var(--text-primary)" }}
      >
        {leader.team.name}
      </div>
      <div className="mt-2 flex items-baseline gap-1">
        <span className="hb-number font-extrabold" style={{ fontSize: 26, color: "var(--text-primary)" }}>
          {leader.display}
        </span>
        {leader.unit && leader.unit !== "%" ? (
          <span className="font-bold" style={{ fontSize: 12, color: "var(--text-secondary)" }}>
            {leader.unit}
          </span>
        ) : null}
      </div>
      <div
        className="mt-1 line-clamp-2 font-semibold leading-snug"
        style={{ fontSize: 11, color: "var(--text-tertiary)" }}
      >
        {title}
      </div>
    </button>
  );
}

/** 1:1 s iOS PlayerLeaderboardRowView */
export function PlayerLeaderboardRow({
  rank,
  row,
  featured,
  onClick,
}: {
  rank: number;
  row: PlayerStatRow;
  featured?: boolean;
  onClick?: () => void;
}) {
  const avatar = featured ? 56 : 40;
  return (
    <button
      type="button"
      onClick={onClick}
      className="hb-card mb-2 flex w-full items-center gap-3 px-3 text-left"
      style={{ paddingTop: featured ? 14 : 12, paddingBottom: featured ? 14 : 12 }}
    >
      <span
        className="hb-number w-7 shrink-0 text-center font-extrabold"
        style={{ fontSize: featured ? 18 : 15, color: "var(--text-secondary)" }}
      >
        {rank}.
      </span>
      <div className="relative shrink-0">
        <PlayerAvatar player={row.player} size={avatar} circle />
        {row.team ? (
          <span className="absolute -right-0.5 -bottom-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-card shadow-sm">
            <TeamBadge team={row.team} size={14} />
          </span>
        ) : null}
      </div>
      <div className="min-w-0 flex-1">
        <div
          className="truncate font-bold"
          style={{ fontSize: featured ? 16 : 14, color: "var(--text-primary)" }}
        >
          {playerFullName(row.player)}
        </div>
        <div className="truncate font-medium" style={{ fontSize: 12, color: "var(--text-secondary)" }}>
          {row.team?.shortName ?? "—"}
        </div>
      </div>
      <div className="shrink-0 text-right">
        <span
          className="hb-number font-extrabold"
          style={{ fontSize: featured ? 22 : 17, color: "var(--text-primary)" }}
        >
          {row.display}
        </span>{" "}
        <span className="font-bold" style={{ fontSize: 12, color: "var(--text-secondary)" }}>
          {row.unit}
        </span>
      </div>
    </button>
  );
}

/** 1:1 s iOS TeamLeaderboardRowView */
export function TeamLeaderboardRow({
  rank,
  row,
  featured,
  onClick,
}: {
  rank: number;
  row: TeamStatRow;
  featured?: boolean;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="hb-card mb-2 flex w-full items-center gap-3 px-3 py-3 text-left"
    >
      <span
        className="hb-number w-7 shrink-0 text-center font-extrabold"
        style={{ fontSize: 15, color: "var(--text-secondary)" }}
      >
        {rank}.
      </span>
      <TeamBadge team={row.team} size={featured ? 44 : 36} />
      <div
        className="min-w-0 flex-1 truncate font-bold"
        style={{ fontSize: 14, color: "var(--text-primary)" }}
      >
        {row.team.name}
      </div>
      <div className="shrink-0 text-right">
        <span className="hb-number font-extrabold" style={{ fontSize: 17, color: "var(--text-primary)" }}>
          {row.display}
        </span>
        {row.unit && row.unit !== "%" ? (
          <span className="font-bold" style={{ fontSize: 12, color: "var(--text-secondary)" }}>
            {" "}
            {row.unit}
          </span>
        ) : null}
      </div>
    </button>
  );
}

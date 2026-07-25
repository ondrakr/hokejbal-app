"use client";

import { useState } from "react";
import type { Player } from "@/lib/types";
import { playerFullName, positionLabel } from "@/lib/types";
import { PlayerAvatar } from "@/components/Badges";
import { Pill, PillTrack } from "@/components/MatchRow";
import { EmptyState } from "@/components/ui";

type LineupSide = "Domácí" | "Hosté";

export function MatchLineups({
  homePlayers,
  awayPlayers,
  onPlayer,
}: {
  homePlayers: Player[];
  awayPlayers: Player[];
  onPlayer?: (id: string) => void;
}) {
  const [side, setSide] = useState<LineupSide>("Domácí");
  const players = (side === "Domácí" ? homePlayers : awayPlayers)
    .slice()
    .sort((a, b) => a.number - b.number);

  return (
    <div>
      <PillTrack>
        {(["Domácí", "Hosté"] as const).map((s) => (
          <Pill key={s} active={side === s} onClick={() => setSide(s)}>
            {s}
          </Pill>
        ))}
      </PillTrack>

      {players.length === 0 ? (
        <EmptyState title="Bez sestavy" hint="Soupiska týmu zatím není k dispozici." />
      ) : (
        <>
          <div className="flex items-center px-4 py-2 text-[11px] font-semibold text-hb-faint">
            <span className="flex-1 text-left">HRÁČ</span>
            <span className="w-7 text-right">B</span>
            <span className="w-7 text-right">G</span>
            <span className="w-7 text-right">A</span>
            <span className="w-9 text-right">TM</span>
          </div>
          {players.map((player) => (
            <button
              key={player.id}
              type="button"
              onClick={() => onPlayer?.(player.id)}
              className="flex w-full items-center gap-2.5 border-b border-separator px-4 py-2.5 text-left"
            >
              <div className="relative shrink-0">
                <div className="overflow-hidden rounded-full">
                  <PlayerAvatar player={player} size={40} />
                </div>
                <span className="absolute -right-0.5 -bottom-0.5 flex h-[18px] w-[18px] items-center justify-center rounded-full bg-brand text-[9px] font-bold text-white tabular-nums">
                  {player.number}
                </span>
              </div>

              <div className="min-w-0 flex-1">
                <div className="truncate text-[14px] font-semibold text-hb-fg">
                  {playerFullName(player)}
                </div>
                <div className="text-[11px] font-medium capitalize text-hb-faint">
                  {positionLabel(player.position)}
                </div>
              </div>

              <span className="w-7 text-right text-[13px] font-semibold tabular-nums text-hb-fg">
                {player.points}
              </span>
              <span className="w-7 text-right text-[13px] tabular-nums text-hb-muted">
                {player.goals}
              </span>
              <span className="w-7 text-right text-[13px] tabular-nums text-hb-muted">
                {player.assists}
              </span>
              <span className="w-9 text-right text-[13px] tabular-nums text-hb-muted">
                {player.penaltyMinutes}
              </span>
            </button>
          ))}
        </>
      )}
    </div>
  );
}

"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchPlayers } from "@/lib/api";
import type { Player } from "@/lib/types";
import { playerFullName, positionLabel } from "@/lib/types";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  FANTASY_SLOTS,
  playerPrice,
  useFantasy,
  type FantasySlot,
} from "@/stores/fantasy";
import { useNav } from "@/stores/navigation";
import { useCatalog } from "@/stores/catalog";

export function FantasyScreen({
  screen = "hub",
}: {
  screen?: "hub" | "team" | "market" | "leaderboard" | "rules";
}) {
  const { pop, push, replace } = useNav();
  const fantasy = useFantasy();
  const { teamById } = useCatalog();
  const [players, setPlayers] = useState<Player[]>([]);
  const [slotPick, setSlotPick] = useState<FantasySlot | null>(null);

  useEffect(() => {
    void fetchPlayers().then((all) => {
      // prefer high-point skaters for market
      setPlayers([...all].sort((a, b) => b.points - a.points).slice(0, 200));
    });
  }, []);

  const lineup = fantasy.lineupFor();
  const playerById = useMemo(() => new Map(players.map((p) => [p.id, p])), [players]);

  if (screen === "rules") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Pravidla" left={<BackButton onClick={pop} />} />
        <div className="space-y-3 px-[var(--screen-pad)] py-4 text-[14px] leading-relaxed text-[var(--text-secondary)]">
          <p>Sestav tým 6 hráčů Extraligy: 1 brankář, 2 obránci, 3 útočníci.</p>
          <p>Rozpočet {fantasy.budget} mil. Maximálně 2 hráči z jednoho klubu.</p>
          <p>Body za góly, asistence a vychytané nuly — jednoduchý lokální režim jako na iOS.</p>
          <p>Deadline herního kola: sobota 10:00 (Praha).</p>
        </div>
      </div>
    );
  }

  if (screen === "leaderboard") {
    const board = [
      { name: "Ice Wizard", pts: 128 },
      { name: fantasy.teamName, pts: fantasy.seasonPoints, you: true },
      { name: "Puk Dynasty", pts: 111 },
      { name: "Arena FC", pts: 97 },
    ].sort((a, b) => b.pts - a.pts);
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Žebříček" left={<BackButton onClick={pop} />} />
        <div className="space-y-2 px-[var(--screen-pad)] py-3">
          {board.map((row, i) => (
            <div
              key={row.name + i}
              className={`hb-card flex items-center justify-between px-4 py-3 ${row.you ? "border-[var(--brand)]" : ""}`}
            >
              <span className="font-semibold">
                {i + 1}. {row.name}
              </span>
              <span className="font-bold">{row.pts} b</span>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (screen === "market" || slotPick) {
    const slot = slotPick ?? "F1";
    const need =
      slot === "G" ? "goalie" : slot.startsWith("D") ? "defenseman" : "forward";
    const market = players.filter((p) => p.position === need);
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader
          title="Trh"
          subtitle={slot}
          left={
            <BackButton
              onClick={() => {
                setSlotPick(null);
                if (screen === "market") pop();
              }}
            />
          }
        />
        <div className="space-y-2 px-[var(--screen-pad)] py-3">
          {market.map((p) => {
            const price = playerPrice(p.points, p.position);
            const team = teamById(p.teamId);
            return (
              <button
                key={p.id}
                type="button"
                className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
                onClick={() => {
                  fantasy.setSlot(slot, p.id, price);
                  setSlotPick(null);
                  replace({ name: "fantasy", screen: "team" });
                }}
              >
                <div>
                  <div className="font-bold">{playerFullName(p)}</div>
                  <div className="hb-muted">
                    {team?.shortName} · {positionLabel(p.position)} · {p.points} b
                  </div>
                </div>
                <div className="font-bold text-[var(--brand)]">{price}</div>
              </button>
            );
          })}
          {!market.length && <EmptyState title="Trh se načítá…" />}
        </div>
      </div>
    );
  }

  if (screen === "team") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Můj tým" left={<BackButton onClick={pop} />} />
        <div className="px-[var(--screen-pad)] py-3">
          <div className="mb-3 flex items-center justify-between">
            <input
              value={fantasy.teamName}
              onChange={(e) => fantasy.setTeamName(e.target.value)}
              className="rounded-[12px] border border-[var(--card-stroke)] bg-[var(--card)] px-3 py-2 font-bold outline-none"
            />
            <div className="text-[13px] font-semibold">
              Budget: <span className="text-[var(--brand)]">{fantasy.wallet.toFixed(1)}</span>
            </div>
          </div>
          <div className="space-y-2">
            {FANTASY_SLOTS.map((slot) => {
              const pid = lineup[slot];
              const p = pid ? playerById.get(pid) : undefined;
              return (
                <button
                  key={slot}
                  type="button"
                  className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
                  onClick={() => setSlotPick(slot)}
                >
                  <div>
                    <div className="text-[11px] font-bold text-[var(--text-secondary)]">{slot}</div>
                    <div className="font-bold">{p ? playerFullName(p) : "Vybrat hráče"}</div>
                  </div>
                  <span className="text-[var(--brand)]">{p ? "Změnit" : "+"}</span>
                </button>
              );
            })}
          </div>
          <button type="button" className="hb-muted mt-4 underline" onClick={() => fantasy.clearLineup()}>
            Vymazat sestavu
          </button>
        </div>
      </div>
    );
  }

  // hub
  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Fantasy" left={<BackButton onClick={pop} />} />
      <div className="space-y-3 px-[var(--screen-pad)] py-4">
        <div className="hb-card bg-[linear-gradient(135deg,#22252f,#171a21)] p-5 text-white">
          <div className="text-[13px] opacity-70">GW {fantasy.activeGameweek}</div>
          <div className="mt-1 font-[family-name:var(--font-display)] text-[26px] font-extrabold">
            {fantasy.teamName}
          </div>
          <div className="mt-3 flex gap-4 text-[13px]">
            <span>{fantasy.seasonPoints} b sezóna</span>
            <span>{fantasy.filledCount}/6 sestava</span>
            <span>{fantasy.wallet.toFixed(1)} mil.</span>
          </div>
        </div>
        {[
          { title: "Můj tým", screen: "team" as const },
          { title: "Trh hráčů", screen: "market" as const },
          { title: "Žebříček", screen: "leaderboard" as const },
          { title: "Pravidla", screen: "rules" as const },
        ].map((item) => (
          <button
            key={item.title}
            type="button"
            className="hb-card flex w-full items-center justify-between px-4 py-3.5 text-left font-bold"
            onClick={() => push({ name: "fantasy", screen: item.screen })}
          >
            {item.title}
            <span className="text-[var(--text-tertiary)]">›</span>
          </button>
        ))}
      </div>
    </div>
  );
}

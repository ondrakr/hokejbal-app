"use client";

import { useEffect, useMemo } from "react";
import { MatchRow } from "@/components/MatchRow";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";
import { useTips } from "@/stores/tips";

export function TipsScreen({
  screen = "hub",
}: {
  screen?: "hub" | "leaderboard" | "rules";
}) {
  const { pop, push } = useNav();
  const { matches, competitions } = useCatalog();
  const tips = useTips();

  const extraligaIds = useMemo(
    () => new Set(competitions.filter((c) => c.slug === "extraliga").map((c) => c.id)),
    [competitions]
  );

  const tipMatches = useMemo(
    () =>
      matches
        .filter((m) => extraligaIds.has(m.competitionId))
        .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt)),
    [matches, extraligaIds]
  );

  useEffect(() => {
    tips.resolveAgainstMatches(tipMatches);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tipMatches]);

  if (screen === "rules") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Pravidla" left={<BackButton onClick={pop} />} />
        <div className="space-y-3 px-[var(--screen-pad)] py-4 text-[14px] leading-relaxed text-[var(--text-secondary)]">
          <p>Tipuj vítěze zápasů Extraligy — domácí, nebo hosté (bez remízy).</p>
          <p>Za správný tip získáš {tips.pointsPerTip} body. Remíza = 0 bodů.</p>
          <p>Tipovat lze do začátku zápasu. Výsledky se vyhodnotí po finálním skóre.</p>
        </div>
      </div>
    );
  }

  if (screen === "leaderboard") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Žebříček" left={<BackButton onClick={pop} />} />
        <div className="space-y-2 px-[var(--screen-pad)] py-3">
          <div className="hb-card mb-3 p-4">
            <div className="hb-muted text-[12px]">Tvé jméno</div>
            <input
              value={tips.displayName}
              onChange={(e) => tips.setDisplayName(e.target.value)}
              className="mt-1 w-full rounded-[10px] border border-[var(--card-stroke)] bg-[var(--card-inset)] px-3 py-2 font-bold outline-none"
            />
          </div>
          {tips.leaderboard.map((row, i) => (
            <div
              key={row.id}
              className={`hb-card flex items-center justify-between px-4 py-3 ${
                row.isCurrentUser ? "border-[var(--brand)]" : ""
              }`}
            >
              <div>
                <div className="font-semibold">
                  {i + 1}. {row.name}
                </div>
                <div className="hb-muted">
                  {row.correct}/{row.total} správně
                </div>
              </div>
              <div className="font-bold">{row.points} b</div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  const open = tipMatches.filter((m) => m.status === "scheduled").slice(0, 20);
  const recent = tipMatches.filter((m) => m.status === "finished").slice(-10).reverse();

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Tipovačka" left={<BackButton onClick={pop} />} />
      <div className="px-[var(--screen-pad)] py-3">
        <div className="hb-card mb-4 bg-[linear-gradient(135deg,#22252f,#171a21)] p-4 text-white">
          <div className="text-[13px] opacity-70">{tips.displayName}</div>
          <div className="mt-1 font-[family-name:var(--font-display)] text-[28px] font-extrabold">
            {tips.userStats.points} b
          </div>
          <div className="hb-muted mt-1 text-white/70">
            {tips.userStats.correct}/{tips.userStats.total} správných tipů
          </div>
        </div>
        <div className="mb-4 grid grid-cols-2 gap-2">
          <button
            type="button"
            className="hb-card px-4 py-3 text-left font-bold"
            onClick={() => push({ name: "tips", screen: "leaderboard" })}
          >
            Žebříček
          </button>
          <button
            type="button"
            className="hb-card px-4 py-3 text-left font-bold"
            onClick={() => push({ name: "tips", screen: "rules" })}
          >
            Pravidla
          </button>
        </div>
        <h2 className="mb-2 text-[14px] font-bold">K tipování</h2>
        <div className="mb-4 overflow-hidden rounded-[var(--radius-md)] border border-[var(--card-stroke)]">
          {open.map((m) => (
            <MatchRow key={m.id} match={m} />
          ))}
          {!open.length && <EmptyState title="Žádné otevřené zápasy" />}
        </div>
        <h2 className="mb-2 text-[14px] font-bold">Vyhodnocené</h2>
        <div className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--card-stroke)]">
          {recent.map((m) => (
            <MatchRow key={m.id} match={m} />
          ))}
          {!recent.length && <EmptyState title="Zatím nic" />}
        </div>
      </div>
    </div>
  );
}

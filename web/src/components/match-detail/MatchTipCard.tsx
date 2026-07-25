"use client";

import { useEffect } from "react";
import type { Match, Team } from "@/lib/types";
import { canTip as matchCanTip, useTips } from "@/stores/tips";
import { useCatalog } from "@/stores/catalog";

export function MatchTipCard({
  match,
  home,
  away,
}: {
  match: Match;
  home?: Team;
  away?: Team;
}) {
  const tips = useTips();
  const { competitionById } = useCatalog();
  const comp = competitionById(match.competitionId);
  const isExtraliga = comp?.slug === "extraliga" || match.competitionId.includes("extraliga");

  useEffect(() => {
    if (!isExtraliga) return;
    tips.ensureVotes(match.id);
    if (match.status === "finished") {
      tips.resolveAgainstMatches([match]);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [match.id, match.status, isExtraliga]);

  if (!isExtraliga) return null;

  const votes = tips.votesFor(match.id);
  const myTip = tips.tipFor(match.id);
  const canTip = matchCanTip(match);
  const total = votes.homeCount + votes.awayCount;

  return (
    <div className="hb-card space-y-3 p-3.5">
      <div className="flex items-center gap-2">
        <span className="font-bold tracking-[0.7px]" style={{ fontSize: 11, color: "var(--brand)" }}>
          TIPOVAČKA
        </span>
        <span className="ml-auto text-[11px] font-semibold text-hb-faint">
          +{tips.pointsPerTip} b za správný tip
        </span>
      </div>

      <div className="space-y-2">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1 text-left">
            <div className="hb-number text-[20px] font-extrabold text-hb-fg">
              {votes.homePercent} %
            </div>
            <div className="truncate text-[12px] font-bold text-hb-muted">
              {home?.shortName ?? "DOM"}
            </div>
          </div>
          <div className="min-w-0 flex-1 text-right">
            <div className="hb-number text-[20px] font-extrabold text-hb-fg">
              {votes.awayPercent} %
            </div>
            <div className="truncate text-[12px] font-bold text-hb-muted">
              {away?.shortName ?? "HOS"}
            </div>
          </div>
        </div>

        <div className="h-2.5 overflow-hidden rounded-full bg-card-inset">
          <div
            className="h-full rounded-full bg-brand"
            style={{ width: `${Math.max(4, votes.homePercent)}%` }}
          />
        </div>

        <div className="text-center text-[11px] font-medium text-hb-faint">
          {total} tipů komunity
        </div>
      </div>

      {canTip ? (
        <div className="flex gap-2.5">
          {(
            [
              { pick: "home" as const, title: home?.shortName ?? "Domácí" },
              { pick: "away" as const, title: away?.shortName ?? "Hosté" },
            ] as const
          ).map(({ pick, title }) => {
            const selected = myTip?.pick === pick;
            return (
              <button
                key={pick}
                type="button"
                onClick={() => tips.placeTip(match.id, pick)}
                className="hb-tip-pick"
                data-selected={selected ? "true" : "false"}
              >
                <span className="hb-tip-pick-caption">{selected ? "Tvůj tip" : "Tipnout"}</span>
                <span className="hb-tip-pick-title">{title}</span>
              </button>
            );
          })}
        </div>
      ) : myTip ? (
        <ResultBanner tip={myTip} home={home} away={away} />
      ) : (
        <p className="text-[12px] font-medium text-hb-muted">
          {match.status === "scheduled"
            ? "Tipování uzavřeno před začátkem."
            : "Na tento zápas jsi netipoval."}
        </p>
      )}
    </div>
  );
}

function ResultBanner({
  tip,
  home,
  away,
}: {
  tip: NonNullable<ReturnType<ReturnType<typeof useTips>["tipFor"]>>;
  home?: Team;
  away?: Team;
}) {
  const team = tip.pick === "home" ? (home?.shortName ?? "Domácí") : (away?.shortName ?? "Hosté");
  const icon =
    tip.isCorrect === true ? "✓" : tip.resolved ? "✕" : "◷";
  const iconColor =
    tip.isCorrect === true
      ? "var(--win)"
      : tip.resolved
        ? "var(--loss)"
        : "var(--brand)";
  const subtitle =
    tip.isCorrect === true
      ? `Správně · +${tip.pointsAwarded} b`
      : tip.resolved
        ? "Špatný tip · 0 b"
        : "Čeká na výsledek";

  return (
    <div className="flex items-center gap-2.5 rounded-[10px] bg-card-inset p-2.5">
      <span className="text-[18px] font-bold" style={{ color: iconColor }}>
        {icon}
      </span>
      <div className="min-w-0">
        <div className="text-[13px] font-bold text-hb-fg">Tip: {team}</div>
        <div className="text-[12px] font-medium text-hb-muted">{subtitle}</div>
      </div>
    </div>
  );
}

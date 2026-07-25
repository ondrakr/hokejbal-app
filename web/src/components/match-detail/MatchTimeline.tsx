"use client";

import type { Match, MatchEvent, Player, Team } from "@/lib/types";
import { playerShortName, shortenPersonName } from "@/lib/types";
import { EmptyState } from "@/components/ui";

function periodTitle(period: number): string {
  switch (period) {
    case 1:
      return "1. TŘETINA";
    case 2:
      return "2. TŘETINA";
    case 3:
      return "3. TŘETINA";
    case 4:
      return "PRODLOUŽENÍ";
    default:
      return `${period}. ČÁST`;
  }
}

function penaltyMinutes(description: string): string {
  const m = description.match(/(\d+)\s*min/i);
  return m?.[1] ?? "2";
}

function penaltyReasonOnly(description: string): string {
  const open = description.indexOf("(");
  const close = description.indexOf(")");
  if (open >= 0 && close > open) {
    return description.slice(open + 1, close);
  }
  const dash = description.search(/[–-]/);
  if (dash >= 0) {
    const after = description.slice(dash + 1).trim();
    const o = after.indexOf("(");
    const c = after.indexOf(")");
    if (o >= 0 && c > o) return after.slice(o + 1, c);
    return after;
  }
  return "Vyloučení";
}

function displayName(event: MatchEvent, playerMap: Map<string, Player>): string {
  if (event.playerId) {
    const p = playerMap.get(event.playerId);
    if (p) return playerShortName(p);
  }
  const desc = event.description;
  const dash = desc.search(/[–-]/);
  if (dash >= 0) {
    const after = desc.slice(dash + 1).trim();
    const paren = after.indexOf("(");
    return shortenPersonName((paren >= 0 ? after.slice(0, paren) : after).trim());
  }
  if (desc.startsWith("Gól ")) {
    const rest = desc.slice(4);
    const paren = rest.indexOf("(");
    return shortenPersonName((paren >= 0 ? rest.slice(0, paren) : rest).trim());
  }
  return shortenPersonName(desc);
}

function assistEntries(
  event: MatchEvent,
  playerMap: Map<string, Player>
): { id: string; name: string }[] {
  return event.assistIds.slice(0, 2).flatMap((id) => {
    const p = playerMap.get(id);
    if (!p) return [];
    const name = playerShortName(p);
    if (!name) return [];
    return [{ id, name }];
  });
}

function timelineEvents(match: Match): MatchEvent[] {
  return match.events
    .filter((e) => e.kind === "goal" || e.kind === "penalty")
    .sort((a, b) => {
      if (a.period !== b.period) return a.period - b.period;
      if (a.minute !== b.minute) return a.minute - b.minute;
      return a.second - b.second;
    });
}

function periodsFor(match: Match, events: MatchEvent[]): number[] {
  const fromEvents = new Set(events.map((e) => e.period));
  const fromScores = Math.max(match.homePeriodScores.length, match.awayPeriodScores.length);
  if (fromScores > 0) {
    for (let i = 1; i <= fromScores; i++) fromEvents.add(i);
  }
  return [...fromEvents].sort((a, b) => a - b);
}

function runningScore(
  events: MatchEvent[],
  match: Match,
  event: MatchEvent
): [number, number] {
  let home = 0;
  let away = 0;
  for (const e of events) {
    if (e.kind === "goal") {
      if (e.teamId === match.homeTeamId) home += 1;
      else if (e.teamId === match.awayTeamId) away += 1;
    }
    if (e.id === event.id) break;
  }
  return [home, away];
}

function pad2(n: number) {
  return String(n).padStart(2, "0");
}

function PlayerName({
  id,
  name,
  bold,
  onPlayer,
}: {
  id?: string | null;
  name: string;
  bold: boolean;
  onPlayer?: (id: string) => void;
}) {
  const style = bold
    ? { fontSize: 13, fontWeight: 700 as const, color: "var(--text-primary)", whiteSpace: "nowrap" as const }
    : { fontSize: 11, fontWeight: 600 as const, color: "var(--text-secondary)", whiteSpace: "nowrap" as const };
  if (id && onPlayer) {
    return (
      <button type="button" style={style} onClick={() => onPlayer(id)}>
        {name}
      </button>
    );
  }
  return <span style={style}>{name}</span>;
}

function EventBadge({
  event,
  running,
}: {
  event: MatchEvent;
  running: [number, number];
}) {
  if (event.kind === "goal") {
    return (
      <span
        className="inline-flex shrink-0 items-center gap-[5px] rounded-full bg-brand px-[7px] py-1 font-bold tabular-nums hb-on-brand"
        style={{ fontSize: 11 }}
      >
        <span className="h-[7px] w-[7px] rounded-full bg-white" />
        {running[0]}:{running[1]}
      </span>
    );
  }
  return (
    <span
      className="inline-flex shrink-0 items-center rounded-full px-[7px] py-1 font-bold tabular-nums"
      style={{ fontSize: 11, background: "#FFD626", color: "var(--ink)" }}
    >
      {penaltyMinutes(event.description)}&apos;
    </span>
  );
}

/**
 * Gól: „J. Čejka (T. Novák)“ · Trest: „J. Čejka (hákování)“.
 * `mirror` = hosté: asistence/trest vlevo od střelce (čtení zprava: čas, skóre, gól, asistence).
 */
function GoalPlayerBlock({
  event,
  name,
  assists,
  penaltyReason,
  onPlayer,
  mirror,
}: {
  event: MatchEvent;
  name: string;
  assists: { id: string; name: string }[];
  penaltyReason?: string;
  onPlayer?: (id: string) => void;
  mirror?: boolean;
}) {
  const showAssists = event.kind === "goal" && assists.length > 0;
  const showPenalty =
    event.kind === "penalty" && Boolean(penaltyReason && penaltyReason.trim());

  const scorer = <PlayerName id={event.playerId} name={name} bold onPlayer={onPlayer} />;

  const assistsEl = showAssists ? (
    <span style={{ fontSize: 11, fontWeight: 500, color: "var(--text-tertiary)" }}>
      {mirror ? "(" : "\u00A0("}
      {assists.map((a, i) => (
        <span key={a.id}>
          {i > 0 ? ", " : null}
          <PlayerName id={a.id} name={a.name} bold={false} onPlayer={onPlayer} />
        </span>
      ))}
      {mirror ? ")\u00A0" : ")"}
    </span>
  ) : null;

  const penaltyEl = showPenalty ? (
    <span style={{ fontSize: 11, fontWeight: 500, color: "var(--text-tertiary)" }}>
      {mirror ? `(${penaltyReason})\u00A0` : `\u00A0(${penaltyReason})`}
    </span>
  ) : null;

  return (
    <div className="flex shrink-0 flex-nowrap items-baseline" style={{ whiteSpace: "nowrap" }}>
      {mirror ? (
        <>
          {assistsEl}
          {penaltyEl}
          {scorer}
        </>
      ) : (
        <>
          {scorer}
          {assistsEl}
          {penaltyEl}
        </>
      )}
    </div>
  );
}

function EventRow({
  isHome,
  time,
  event,
  name,
  assists,
  reason,
  running,
  onPlayer,
}: {
  isHome: boolean;
  time: string;
  event: MatchEvent;
  name: string;
  assists: { id: string; name: string }[];
  reason: string;
  running: [number, number];
  onPlayer?: (id: string) => void;
}) {
  const timeEl = (
    <span
      className="hb-number shrink-0 font-bold"
      style={{ fontSize: 12, color: "var(--text-tertiary)" }}
    >
      {time}
    </span>
  );
  const badge = <EventBadge event={event} running={running} />;
  const players = (
    <GoalPlayerBlock
      event={event}
      name={name}
      assists={assists}
      penaltyReason={reason}
      onPlayer={onPlayer}
      mirror={!isHome}
    />
  );

  // Domácí L→P: čas, skóre, gól, asistence
  // Hosté P→L: čas, skóre, gól, asistence (stejně jako iOS: players | badge | time u pravého okraje)
  if (isHome) {
    return (
      <div className="flex w-full items-center gap-1.5">
        {timeEl}
        {badge}
        {players}
      </div>
    );
  }

  return (
    <div className="flex w-full items-center justify-end gap-1.5">
      {players}
      {badge}
      {timeEl}
    </div>
  );
}

export function MatchTimeline({
  match,
  playerMap,
  onPlayer,
}: {
  match: Match;
  home?: Team;
  away?: Team;
  playerMap: Map<string, Player>;
  onPlayer?: (id: string) => void;
}) {
  const events = timelineEvents(match);
  const periods = periodsFor(match, events);

  if (events.length === 0 && match.homePeriodScores.length === 0) {
    return (
      <EmptyState
        title="Bez událostí"
        hint="Až padnou góly, uvidíte je tady chronologicky."
      />
    );
  }

  return (
    <div className="space-y-4 px-3">
      {periods.map((period) => {
        const items = events.filter((e) => e.period === period);
        const homeP =
          period <= match.homePeriodScores.length ? match.homePeriodScores[period - 1]! : 0;
        const awayP =
          period <= match.awayPeriodScores.length ? match.awayPeriodScores[period - 1]! : 0;

        return (
          <div key={period} className="space-y-2">
            <div className="flex items-center gap-2.5">
              <span
                className="shrink-0 font-bold tracking-[0.6px]"
                style={{ fontSize: 11, color: "var(--text-secondary)" }}
              >
                {periodTitle(period)}
              </span>
              <div className="h-px flex-1 bg-[var(--card-stroke)]" />
              <span
                className="hb-number shrink-0 rounded-full bg-card-inset px-2.5 py-[5px] font-bold"
                style={{ fontSize: 13, color: "var(--text-primary)" }}
              >
                {homeP} – {awayP}
              </span>
            </div>

            {items.map((event) => {
              const isHome = event.teamId === match.homeTeamId;
              const time = `${pad2(event.minute)}:${pad2(event.second)}`;
              const name = displayName(event, playerMap);
              const assists = assistEntries(event, playerMap);
              const reason = penaltyReasonOnly(event.description);
              const running = runningScore(events, match, event);

              return (
                <div key={event.id} className="flex items-start gap-2 py-2">
                  <div className="min-w-0 flex-1">
                    {isHome ? (
                      <EventRow
                        isHome
                        time={time}
                        event={event}
                        name={name}
                        assists={assists}
                        reason={reason}
                        running={running}
                        onPlayer={onPlayer}
                      />
                    ) : null}
                  </div>
                  <div className="min-w-0 flex-1">
                    {!isHome ? (
                      <EventRow
                        isHome={false}
                        time={time}
                        event={event}
                        name={name}
                        assists={assists}
                        reason={reason}
                        running={running}
                        onPlayer={onPlayer}
                      />
                    ) : null}
                  </div>
                </div>
              );
            })}
          </div>
        );
      })}
    </div>
  );
}

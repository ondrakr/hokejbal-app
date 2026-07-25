"use client";

import { AmateurBadge } from "@/components/amateur/AmateurBadge";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  eventClockLabel,
  matchStatusLabel,
  playerShortName,
  useAmateur,
  type AmateurMatch,
  type AmateurMatchEvent,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

function EventRow({ event, match }: { event: AmateurMatchEvent; match: AmateurMatch }) {
  const { player } = useAmateur();
  const isHome = event.teamId === match.homeTeamId;
  const scorer = event.playerId ? player(event.playerId) : undefined;
  const assists = event.assistIds
    .map((id) => player(id))
    .filter(Boolean)
    .map((p) => playerShortName(p!));

  return (
    <div className={`hb-card flex p-3 ${isHome ? "" : "justify-end"}`}>
      <div className={`max-w-[80%] ${isHome ? "text-left" : "text-right"}`}>
        <div className={`mb-1 flex items-center gap-1.5 ${isHome ? "" : "justify-end"}`}>
          <span className="hb-number text-[11px] font-bold text-hb-faint">
            {eventClockLabel(event)}
          </span>
          <span
            className={`rounded-full px-1.5 py-0.5 text-[10px] font-bold ${
              event.kind === "goal" ? "bg-brand text-white" : "bg-[#ffd626] text-ink"
            }`}
          >
            {event.kind === "goal" ? "GÓL" : `${event.penaltyMinutes}'`}
          </span>
        </div>
        <div className="text-[14px] font-bold text-hb-fg">
          {scorer
            ? playerShortName(scorer)
            : event.description || "Neznámý"}
        </div>
        {event.kind === "goal" && assists.length > 0 ? (
          <div className="text-[12px] font-medium text-hb-muted">({assists.join(", ")})</div>
        ) : null}
        {event.kind === "penalty" && event.penaltyReason ? (
          <div className="text-[12px] font-medium text-hb-muted">{event.penaltyReason}</div>
        ) : null}
      </div>
    </div>
  );
}

export function AmateurMatchDetail({ matchId }: { matchId: string }) {
  const { pop, push } = useNav();
  const { match, team } = useAmateur();
  const m = match(matchId);

  if (!m) {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Zápas" left={<BackButton onClick={pop} />} />
        <EmptyState title="Zápas nenalezen" />
      </div>
    );
  }

  const home = team(m.homeTeamId);
  const away = team(m.awayTeamId);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Zápas"
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-hb-fg"
            aria-label="Zápis zápasu"
            onClick={() =>
              push({
                name: "amateur",
                screen: "scorer",
                id: m.tournamentId,
                matchId: m.id,
              })
            }
          >
            <svg width={18} height={18} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
              <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" />
            </svg>
          </button>
        }
      />

      <div className="space-y-4 px-[var(--screen-pad)] py-4 pb-8">
        <div className="hb-card hb-card-lg p-4">
          <div
            className={`mb-3 text-center text-[11px] font-bold uppercase ${
              m.status === "live" ? "text-live" : "text-hb-faint"
            }`}
          >
            {matchStatusLabel(m.status)}
          </div>
          <div className="flex items-center gap-2">
            <div className="flex flex-1 flex-col items-center gap-2">
              {home ? <AmateurBadge team={home} size={48} /> : null}
              <span className="text-[13px] font-bold text-hb-fg">{home?.shortName ?? "?"}</span>
            </div>
            <span className="hb-number min-w-[90px] text-center text-[36px] font-extrabold text-hb-fg">
              {m.status === "scheduled" ? "–" : `${m.homeScore}:${m.awayScore}`}
            </span>
            <div className="flex flex-1 flex-col items-center gap-2">
              {away ? <AmateurBadge team={away} size={48} /> : null}
              <span className="text-[13px] font-bold text-hb-fg">{away?.shortName ?? "?"}</span>
            </div>
          </div>
        </div>

        <div className="hb-card flex items-center p-3.5">
          <span className="hb-number text-[18px] font-extrabold text-hb-fg">{m.homeShots}</span>
          <span className="flex-1 text-center text-[11px] font-bold text-hb-faint">STŘELY</span>
          <span className="hb-number text-[18px] font-extrabold text-hb-fg">{m.awayShots}</span>
        </div>

        <div>
          <div className="mb-2.5 text-[12px] font-bold text-hb-faint">UDÁLOSTI</div>
          {m.events.length === 0 ? (
            <p className="text-[13px] font-medium text-hb-muted">Zatím bez zápisu.</p>
          ) : (
            <div className="space-y-2">
              {m.events.map((e) => (
                <EventRow key={e.id} event={e} match={m} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

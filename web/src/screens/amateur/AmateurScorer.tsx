"use client";

import { useState } from "react";
import { AmateurBadge } from "@/components/amateur/AmateurBadge";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  eventClockLabel,
  matchFormatMaxPeriod,
  matchPhaseLabel,
  matchStatusLabel,
  playerFullName,
  useAmateur,
  type AmateurMatch,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

const PENALTY_REASONS = [
  "Hákování",
  "Podražení",
  "Nedovolené bránění",
  "Vysoká hůl",
  "Drsnost",
  "Nesportovní chování",
  "Jiné",
];

function fieldClass() {
  return "mt-1 w-full rounded-[12px] border border-card-stroke bg-card px-3 py-2.5 text-[15px] text-hb-fg outline-none";
}

function Sheet({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 sm:items-center sm:p-4">
      <div className="max-h-[92vh] w-full max-w-lg overflow-y-auto rounded-t-2xl bg-canvas sm:rounded-2xl">
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-separator bg-canvas px-4 py-3">
          <button type="button" className="text-[15px] font-semibold text-hb-muted" onClick={onClose}>
            Zrušit
          </button>
          <div className="text-[16px] font-bold text-hb-fg">{title}</div>
          <div className="w-12" />
        </div>
        <div className="p-4 pb-8">{children}</div>
      </div>
    </div>
  );
}

function GoalSheet({
  match,
  teamIsHome,
  onClose,
}: {
  match: AmateurMatch;
  teamIsHome: boolean;
  onClose: () => void;
}) {
  const { team, playersInTeam, tournament, addGoalEvent } = useAmateur();
  const teamId = teamIsHome ? match.homeTeamId : match.awayTeamId;
  const roster = playersInTeam(teamId);
  const tm = team(teamId);
  const mf = tournament(match.tournamentId)?.matchFormat ?? {
    periodCount: 3,
    periodLengthMinutes: 15,
    overtimeEnabled: true,
  };

  const [scorerId, setScorerId] = useState("");
  const [freeName, setFreeName] = useState("");
  const [assist1, setAssist1] = useState("");
  const [assist2, setAssist2] = useState("");
  const [period, setPeriod] = useState(1);
  const [minute, setMinute] = useState(0);
  const [second, setSecond] = useState(0);

  return (
    <Sheet title="Gól" onClose={onClose}>
      <div className="mb-4 flex items-center gap-2.5 rounded-[14px] bg-card p-3.5">
        {tm ? <AmateurBadge team={tm} size={36} /> : null}
        <span className="text-[16px] font-bold text-hb-fg">
          {tm?.name ?? (teamIsHome ? "Domácí" : "Hosté")}
        </span>
      </div>

      <div className="mb-1 text-[11px] font-bold tracking-[0.5px] text-hb-faint">STŘELEC</div>
      <div className="hb-card mb-4 space-y-2 p-3.5">
        <select value={scorerId} onChange={(e) => setScorerId(e.target.value)} className={fieldClass()}>
          <option value="">Bez hráče</option>
          {roster.map((p) => (
            <option key={p.id} value={p.id}>
              #{p.number} {playerFullName(p)}
            </option>
          ))}
        </select>
        {!scorerId && (
          <input
            value={freeName}
            onChange={(e) => setFreeName(e.target.value)}
            placeholder="Volný text jména"
            className={fieldClass()}
          />
        )}
      </div>

      <div className="mb-1 text-[11px] font-bold tracking-[0.5px] text-hb-faint">ASISTENCE</div>
      <div className="hb-card mb-4 space-y-2 p-3.5">
        <select value={assist1} onChange={(e) => setAssist1(e.target.value)} className={fieldClass()}>
          <option value="">1. asistence</option>
          {roster
            .filter((p) => p.id !== scorerId)
            .map((p) => (
              <option key={p.id} value={p.id}>
                #{p.number} {playerFullName(p)}
              </option>
            ))}
        </select>
        <select value={assist2} onChange={(e) => setAssist2(e.target.value)} className={fieldClass()}>
          <option value="">2. asistence</option>
          {roster
            .filter((p) => p.id !== scorerId && p.id !== assist1)
            .map((p) => (
              <option key={p.id} value={p.id}>
                #{p.number} {playerFullName(p)}
              </option>
            ))}
        </select>
      </div>

      <div className="mb-1 text-[11px] font-bold tracking-[0.5px] text-hb-faint">ČAS</div>
      <div className="hb-card mb-4 space-y-3 p-3.5 text-[15px] font-semibold text-hb-fg">
        <label className="flex items-center justify-between gap-3">
          Třetina {period}
          <input
            type="range"
            min={1}
            max={matchFormatMaxPeriod(mf)}
            value={period}
            onChange={(e) => setPeriod(Number(e.target.value))}
          />
        </label>
        <label className="flex items-center justify-between gap-3">
          Minuta {minute}
          <input
            type="range"
            min={0}
            max={mf.periodLengthMinutes}
            value={minute}
            onChange={(e) => setMinute(Number(e.target.value))}
          />
        </label>
        <label className="flex items-center justify-between gap-3">
          Sekunda {second}
          <input
            type="range"
            min={0}
            max={59}
            value={second}
            onChange={(e) => setSecond(Number(e.target.value))}
          />
        </label>
      </div>

      <button
        type="button"
        className="hb-brand-btn w-full"
        onClick={() => {
          const assists = [assist1, assist2].filter(Boolean);
          addGoalEvent({
            matchId: match.id,
            teamId,
            playerId: scorerId || undefined,
            assistIds: assists,
            period,
            minute,
            second,
            description: !scorerId && freeName.trim() ? freeName.trim() : "",
          });
          onClose();
        }}
      >
        Uložit
      </button>
    </Sheet>
  );
}

function PenaltySheet({
  match,
  teamIsHome,
  onClose,
}: {
  match: AmateurMatch;
  teamIsHome: boolean;
  onClose: () => void;
}) {
  const { team, playersInTeam, tournament, addPenaltyEvent } = useAmateur();
  const teamId = teamIsHome ? match.homeTeamId : match.awayTeamId;
  const roster = playersInTeam(teamId);
  const tm = team(teamId);
  const mf = tournament(match.tournamentId)?.matchFormat ?? {
    periodCount: 3,
    periodLengthMinutes: 15,
    overtimeEnabled: true,
  };

  const [playerId, setPlayerId] = useState("");
  const [minutes, setMinutes] = useState(2);
  const [reason, setReason] = useState("Hákování");
  const [period, setPeriod] = useState(1);
  const [minute, setMinute] = useState(0);
  const [second, setSecond] = useState(0);

  return (
    <Sheet title="Trest" onClose={onClose}>
      <div className="mb-4 flex items-center gap-2.5 rounded-[14px] bg-card p-3.5">
        {tm ? <AmateurBadge team={tm} size={36} /> : null}
        <span className="text-[16px] font-bold text-hb-fg">
          {tm?.name ?? (teamIsHome ? "Domácí" : "Hosté")}
        </span>
      </div>

      <div className="mb-1 text-[11px] font-bold tracking-[0.5px] text-hb-faint">HRÁČ</div>
      <div className="hb-card mb-4 p-3.5">
        <select value={playerId} onChange={(e) => setPlayerId(e.target.value)} className={fieldClass()}>
          <option value="">Bez hráče</option>
          {roster.map((p) => (
            <option key={p.id} value={p.id}>
              #{p.number} {playerFullName(p)}
            </option>
          ))}
        </select>
      </div>

      <div className="mb-1 text-[11px] font-bold tracking-[0.5px] text-hb-faint">TREST</div>
      <div className="hb-card mb-4 space-y-3 p-3.5">
        <div className="flex gap-2">
          {[2, 5, 10].map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMinutes(m)}
              className={`flex-1 rounded-full py-2 text-[13px] font-bold ${
                minutes === m ? "bg-brand text-on-brand" : "bg-card-inset text-hb-fg"
              }`}
            >
              {m} min
            </button>
          ))}
        </div>
        <select value={reason} onChange={(e) => setReason(e.target.value)} className={fieldClass()}>
          {PENALTY_REASONS.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>
      </div>

      <div className="mb-1 text-[11px] font-bold tracking-[0.5px] text-hb-faint">ČAS</div>
      <div className="hb-card mb-4 space-y-3 p-3.5 text-[15px] font-semibold text-hb-fg">
        <label className="flex items-center justify-between gap-3">
          Třetina {period}
          <input
            type="range"
            min={1}
            max={matchFormatMaxPeriod(mf)}
            value={period}
            onChange={(e) => setPeriod(Number(e.target.value))}
          />
        </label>
        <label className="flex items-center justify-between gap-3">
          Minuta {minute}
          <input
            type="range"
            min={0}
            max={mf.periodLengthMinutes}
            value={minute}
            onChange={(e) => setMinute(Number(e.target.value))}
          />
        </label>
        <label className="flex items-center justify-between gap-3">
          Sekunda {second}
          <input
            type="range"
            min={0}
            max={59}
            value={second}
            onChange={(e) => setSecond(Number(e.target.value))}
          />
        </label>
      </div>

      <button
        type="button"
        className="hb-brand-btn w-full"
        onClick={() => {
          addPenaltyEvent({
            matchId: match.id,
            teamId,
            playerId: playerId || undefined,
            minutes,
            reason,
            period,
            minute,
            second,
          });
          onClose();
        }}
      >
        Uložit
      </button>
    </Sheet>
  );
}

export function AmateurScorer({ matchId }: { matchId: string }) {
  const { pop } = useNav();
  const {
    match,
    team,
    player,
    setMatchStatus,
    setShots,
    removeEvent,
  } = useAmateur();
  const [showGoal, setShowGoal] = useState(false);
  const [showPenalty, setShowPenalty] = useState(false);
  const [eventTeamIsHome, setEventTeamIsHome] = useState(true);

  const m = match(matchId);
  if (!m) {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Zápis" left={<BackButton onClick={pop} />} />
        <EmptyState title="Zápas nenalezen" />
      </div>
    );
  }

  const home = team(m.homeTeamId);
  const away = team(m.awayTeamId);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Zápis" left={<BackButton onClick={pop} />} />
      <div className="space-y-3.5 px-[var(--screen-pad)] py-4 pb-8">
        <div className="hb-card hb-card-lg p-4">
          <div className="mb-4 flex items-center gap-2">
            <span className="text-[10px] font-bold tracking-[0.5px] text-hb-faint uppercase">
              {matchPhaseLabel(m)}
            </span>
            <span
              className={`ml-auto rounded-full px-2 py-1 text-[10px] font-bold uppercase ${
                m.status === "live"
                  ? "bg-live text-on-brand"
                  : "bg-card-inset text-hb-faint"
              }`}
            >
              {matchStatusLabel(m.status)}
            </span>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex flex-1 flex-col items-start gap-2">
              {home ? <AmateurBadge team={home} size={48} /> : <div className="h-12 w-12 rounded-full bg-card-inset" />}
              <span className="text-[14px] font-bold text-hb-fg">{home?.shortName ?? "—"}</span>
            </div>
            <span className="hb-number min-w-[88px] text-center text-[36px] font-extrabold tabular-nums text-hb-fg">
              {m.homeScore}:{m.awayScore}
            </span>
            <div className="flex flex-1 flex-col items-end gap-2">
              {away ? <AmateurBadge team={away} size={48} /> : <div className="h-12 w-12 rounded-full bg-card-inset" />}
              <span className="text-[14px] font-bold text-hb-fg">{away?.shortName ?? "—"}</span>
            </div>
          </div>
        </div>

        <div className="flex gap-2.5">
          <button
            type="button"
            className={`flex-1 rounded-full py-3 text-[13px] font-bold ${
              m.status === "live" ? "bg-live text-on-brand" : "bg-live/12 text-live"
            }`}
            onClick={() => setMatchStatus(m.id, "live")}
          >
            LIVE
          </button>
          <button
            type="button"
            className={`flex-1 rounded-full border py-3 text-[13px] font-bold ${
              m.status === "finished"
                ? "border-transparent bg-ink text-on-brand"
                : "border-card-stroke bg-card text-hb-fg"
            }`}
            onClick={() => setMatchStatus(m.id, "finished")}
          >
            Konec
          </button>
        </div>

        <div>
          <div className="mb-2.5 text-[11px] font-bold tracking-[0.5px] text-hb-faint">
            RYCHLÝ ZÁPIS
          </div>
          <div className="mb-2.5 grid grid-cols-2 gap-2.5">
            <button
              type="button"
              className="rounded-[14px] bg-brand py-3.5 text-[13px] font-bold text-on-brand"
              onClick={() => {
                setEventTeamIsHome(true);
                setShowGoal(true);
              }}
            >
              Gól {home?.shortName ?? "DOM"}
            </button>
            <button
              type="button"
              className="rounded-[14px] bg-brand py-3.5 text-[13px] font-bold text-on-brand"
              onClick={() => {
                setEventTeamIsHome(false);
                setShowGoal(true);
              }}
            >
              Gól {away?.shortName ?? "HOS"}
            </button>
            <button
              type="button"
              className="rounded-[14px] border border-card-stroke bg-card py-3.5 text-[13px] font-bold text-hb-fg"
              onClick={() => {
                setEventTeamIsHome(true);
                setShowPenalty(true);
              }}
            >
              Trest {home?.shortName ?? "DOM"}
            </button>
            <button
              type="button"
              className="rounded-[14px] border border-card-stroke bg-card py-3.5 text-[13px] font-bold text-hb-fg"
              onClick={() => {
                setEventTeamIsHome(false);
                setShowPenalty(true);
              }}
            >
              Trest {away?.shortName ?? "HOS"}
            </button>
          </div>
        </div>

        <div>
          <div className="mb-2.5 text-[11px] font-bold tracking-[0.5px] text-hb-faint">STŘELY</div>
          <div className="grid grid-cols-2 gap-2.5">
            {[
              {
                title: home?.shortName ?? "DOM",
                value: m.homeShots,
                set: (v: number) => setShots(m.id, v, m.awayShots),
              },
              {
                title: away?.shortName ?? "HOS",
                value: m.awayShots,
                set: (v: number) => setShots(m.id, m.homeShots, v),
              },
            ].map((s) => (
              <div key={s.title} className="hb-card p-3.5 text-center">
                <div className="mb-2 text-[12px] font-bold text-hb-muted">{s.title}</div>
                <div className="flex items-center justify-center gap-3.5">
                  <button
                    type="button"
                    className="flex h-9 w-9 items-center justify-center rounded-full bg-card-inset text-[16px] font-bold text-hb-fg"
                    onClick={() => s.set(Math.max(0, s.value - 1))}
                  >
                    −
                  </button>
                  <span className="hb-number min-w-9 text-[24px] font-extrabold tabular-nums">
                    {s.value}
                  </span>
                  <button
                    type="button"
                    className="flex h-9 w-9 items-center justify-center rounded-full bg-brand text-[16px] font-bold text-on-brand"
                    onClick={() => s.set(Math.min(99, s.value + 1))}
                  >
                    +
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div>
          <div className="mb-2.5 text-[11px] font-bold tracking-[0.5px] text-hb-faint">ZÁPIS</div>
          {m.events.length === 0 ? (
            <div className="hb-card p-4 text-[13px] font-medium text-hb-faint">
              Zatím bez událostí — přidej gól nebo trest.
            </div>
          ) : (
            <div className="hb-card divide-y divide-separator overflow-hidden">
              {[...m.events].reverse().map((event) => {
                const isHome = event.teamId === m.homeTeamId;
                const tm = team(event.teamId);
                const p = event.playerId ? player(event.playerId) : undefined;
                return (
                  <div key={event.id} className="flex items-start gap-3 p-3.5">
                    <span
                      className={`mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full ${
                        event.kind === "goal" ? "bg-white ring-1 ring-brand/35" : "bg-[#ffd626]"
                      }`}
                    />
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-1.5 text-[14px] font-bold text-hb-fg">
                        <span>
                          {event.kind === "goal" ? "Gól" : `Trest ${event.penaltyMinutes}'`}
                        </span>
                        <span className="text-hb-faint">·</span>
                        <span className="hb-number text-[12px] text-hb-faint">
                          {eventClockLabel(event)}
                        </span>
                      </div>
                      <div className="text-[13px] font-medium text-hb-muted">
                        {p
                          ? playerFullName(p)
                          : event.description || "Bez hráče"}
                      </div>
                      {event.kind === "penalty" && event.penaltyReason ? (
                        <div className="text-[12px] font-medium text-hb-faint">
                          {event.penaltyReason}
                        </div>
                      ) : null}
                      <div className="mt-0.5 text-[11px] font-bold text-brand">
                        {isHome ? tm?.shortName ?? "DOM" : tm?.shortName ?? "HOS"}
                      </div>
                    </div>
                    <button
                      type="button"
                      className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-loss/10 text-loss"
                      onClick={() => removeEvent(m.id, event.id)}
                    >
                      🗑
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {showGoal && (
        <GoalSheet
          match={m}
          teamIsHome={eventTeamIsHome}
          onClose={() => setShowGoal(false)}
        />
      )}
      {showPenalty && (
        <PenaltySheet
          match={m}
          teamIsHome={eventTeamIsHome}
          onClose={() => setShowPenalty(false)}
        />
      )}
    </div>
  );
}

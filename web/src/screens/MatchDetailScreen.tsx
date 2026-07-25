"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchMatch, fetchPlayers, fetchStandings } from "@/lib/api";
import { trustedOpenUrl } from "@/lib/supabase";
import type { Match, Player, StandingRow } from "@/lib/types";
import { playerShortName } from "@/lib/types";
import { formatMatchDay, formatMatchTime } from "@/lib/format";
import { UnderlineTabs } from "@/components/MatchRow";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";
import { useTips } from "@/stores/tips";

export function MatchDetailScreen({ id }: { id: string }) {
  const { teamById, competitionById } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const tips = useTips();
  const [match, setMatch] = useState<Match | null>(null);
  const [standings, setStandings] = useState<StandingRow[]>([]);
  const [players, setPlayers] = useState<Player[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const m = await fetchMatch(id);
        if (cancelled) return;
        setMatch(m);
        if (m) {
          const [st, pl] = await Promise.all([
            fetchStandings(m.competitionId),
            fetchPlayers({ competitionId: m.competitionId }),
          ]);
          if (!cancelled) {
            setStandings(st);
            setPlayers(pl);
            tips.resolveAgainstMatches([m]);
          }
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    const timer = window.setInterval(async () => {
      const m = await fetchMatch(id);
      if (!cancelled && m) setMatch(m);
    }, 8000);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const liveOrFinished = match?.status === "live" || match?.status === "finished";
  const tabs = liveOrFinished
    ? ["Zápas", "Statistiky", "Sestavy", "Tabulka", "Přehled"]
    : ["Přehled", "Statistiky", "Sestavy", "Tabulka"];
  const [section, setSection] = useState(tabs[0]);

  useEffect(() => {
    setSection(tabs[0]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [match?.status]);

  const home = match ? teamById(match.homeTeamId) : undefined;
  const away = match ? teamById(match.awayTeamId) : undefined;
  const comp = match ? competitionById(match.competitionId) : undefined;
  const playerMap = useMemo(() => new Map(players.map((p) => [p.id, p])), [players]);

  if (loading) return <LoadingState />;
  if (!match) return <EmptyState title="Zápas nenalezen" />;

  const stream = trustedOpenUrl(match.streamURL);
  const tip = tips.tipFor(match.id);
  const votes = tips.votesFor(match.id);
  const canTip = match.status === "scheduled" && comp?.slug === "extraliga";

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title={comp?.shortName ?? "Zápas"}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className={fav.isMatch(match.id) ? "text-[var(--brand)]" : "text-[var(--text-secondary)]"}
            onClick={() => fav.toggleMatch(match.id)}
          >
            ★
          </button>
        }
      />

      <div className="bg-[linear-gradient(135deg,#22252f,#171a21)] px-[var(--screen-pad)] py-5 text-white">
        <div className="hb-muted mb-3 text-center text-white/70">
          {formatMatchDay(match.scheduledAt)} · {formatMatchTime(match.scheduledAt)}
          {match.status === "live" && (
            <span className="ml-2 inline-flex items-center gap-1 font-bold text-[var(--live)]">
              <span className="hb-live-dot" /> LIVE {match.clock}
            </span>
          )}
        </div>
        <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-3">
          <button type="button" className="text-center" onClick={() => push({ name: "team", id: match.homeTeamId })}>
            <div className="mx-auto mb-2 flex h-14 w-14 items-center justify-center rounded-full bg-white/10 text-sm font-bold">
              {home?.logoInitials}
            </div>
            <div className="text-[14px] font-bold">{home?.shortName}</div>
          </button>
          <div className="font-[family-name:var(--font-display)] text-[36px] font-black tabular-nums">
            {match.status === "scheduled" || match.status === "postponed"
              ? "vs"
              : `${match.homeScore}:${match.awayScore}`}
          </div>
          <button type="button" className="text-center" onClick={() => push({ name: "team", id: match.awayTeamId })}>
            <div className="mx-auto mb-2 flex h-14 w-14 items-center justify-center rounded-full bg-white/10 text-sm font-bold">
              {away?.logoInitials}
            </div>
            <div className="text-[14px] font-bold">{away?.shortName}</div>
          </button>
        </div>
        {stream && (
          <a href={stream} target="_blank" rel="noreferrer" className="hb-brand-btn mt-4 w-full">
            {match.streamLabel || "Sledovat přenos"}
          </a>
        )}
      </div>

      <UnderlineTabs tabs={tabs} value={section} onChange={setSection} />

      <div className="px-[var(--screen-pad)] py-4">
        {(section === "Zápas" || (section === "Přehled" && liveOrFinished === false)) && (
          <div className="space-y-3">
            {canTip && (
              <div className="hb-card p-4">
                <div className="mb-2 text-[14px] font-bold">Tipovačka</div>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    className={`rounded-[12px] py-3 font-bold ${tip?.pick === "home" ? "bg-[var(--brand)] text-white" : "bg-[var(--card-inset)]"}`}
                    onClick={() => tips.placeTip(match.id, "home")}
                  >
                    Domácí
                  </button>
                  <button
                    type="button"
                    className={`rounded-[12px] py-3 font-bold ${tip?.pick === "away" ? "bg-[var(--brand)] text-white" : "bg-[var(--card-inset)]"}`}
                    onClick={() => tips.placeTip(match.id, "away")}
                  >
                    Hosté
                  </button>
                </div>
                {votes && (
                  <div className="hb-muted mt-2">
                    Komunita: {votes.homeCount}:{votes.awayCount}
                  </div>
                )}
              </div>
            )}
            <div className="hb-card p-4">
              <div className="mb-2 text-[14px] font-bold">Info</div>
              <div className="space-y-1 text-[13px]">
                <div>Místo: {match.venue || "—"}</div>
                <div>Kolo: {match.round || "—"}</div>
                {match.referees && <div>Rozhodčí: {match.referees}</div>}
                {match.attendance != null && <div>Diváci: {match.attendance}</div>}
              </div>
            </div>
            {section === "Zápas" && (
              <div className="hb-card divide-y divide-[var(--separator)] overflow-hidden">
                {match.events
                  .filter((e) => e.kind === "goal" || e.kind === "penalty")
                  .map((e) => {
                    const p = e.playerId ? playerMap.get(e.playerId) : undefined;
                    const assists = e.assistIds
                      .map((aid) => playerMap.get(aid))
                      .filter(Boolean)
                      .map((x) => playerShortName(x!));
                    return (
                      <div key={e.id} className="flex items-start gap-3 px-4 py-3">
                        <div className="w-10 shrink-0 text-[12px] font-bold text-[var(--text-secondary)]">
                          {e.minute}&apos;
                        </div>
                        <div>
                          <div className="text-[13px] font-semibold">
                            {e.kind === "goal" ? "Gól" : "Vyloučení"} ·{" "}
                            {e.teamId === match.homeTeamId ? home?.shortName : away?.shortName}
                          </div>
                          <div className="text-[13px]">
                            {p ? playerShortName(p) : e.description}
                            {assists.length > 0 && (
                              <span className="text-[var(--text-secondary)]">
                                {" "}
                                ({assists.join(", ")})
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                {!match.events.filter((e) => e.kind === "goal" || e.kind === "penalty").length && (
                  <EmptyState title="Zatím žádné události" />
                )}
              </div>
            )}
          </div>
        )}

        {section === "Přehled" && liveOrFinished && (
          <div className="hb-card space-y-1 p-4 text-[13px]">
            <div>Místo: {match.venue || "—"}</div>
            <div>Kolo: {match.round || "—"}</div>
            {match.referees && <div>Rozhodčí: {match.referees}</div>}
          </div>
        )}

        {section === "Statistiky" && (
          <div className="hb-card space-y-3 p-4">
            {[
              ["Střely", match.homeShots, match.awayShots],
              ["Góly v přesilovce", match.homePowerplayGoals, match.awayPowerplayGoals],
              ["Góly v oslabení", match.homeShorthandedGoals, match.awayShorthandedGoals],
            ].map(([label, h, a]) => (
              <div key={String(label)} className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 text-[13px]">
                <div className="text-right font-bold tabular-nums">{h ?? "—"}</div>
                <div className="hb-muted min-w-[120px] text-center">{label as string}</div>
                <div className="font-bold tabular-nums">{a ?? "—"}</div>
              </div>
            ))}
            {(match.homePeriodScores.length > 0 || match.awayPeriodScores.length > 0) && (
              <div className="border-t border-[var(--separator)] pt-3">
                <div className="mb-2 text-[13px] font-bold">Třetiny</div>
                <div className="flex justify-center gap-3 font-[family-name:var(--font-display)] text-[18px] font-bold">
                  {match.homePeriodScores.map((s, i) => (
                    <span key={i}>
                      {s}:{match.awayPeriodScores[i] ?? 0}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {section === "Sestavy" && (
          <div className="grid gap-3">
            {[home, away].map((team) => (
              <div key={team?.id} className="hb-card p-4">
                <div className="mb-2 font-bold">{team?.name}</div>
                <div className="space-y-1">
                  {players
                    .filter((p) => p.teamId === team?.id)
                    .slice(0, 20)
                    .map((p) => (
                      <button
                        key={p.id}
                        type="button"
                        className="flex w-full justify-between py-1 text-left text-[13px]"
                        onClick={() => push({ name: "player", id: p.id })}
                      >
                        <span>
                          #{p.number} {playerShortName(p)}
                        </span>
                        <span className="hb-muted">{p.points} b</span>
                      </button>
                    ))}
                  {!players.filter((p) => p.teamId === team?.id).length && (
                    <div className="hb-muted">Sestava není k dispozici</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {section === "Tabulka" && (
          <div className="hb-card overflow-hidden">
            <div className="grid grid-cols-[28px_1fr_28px_28px_28px_36px] gap-1 border-b border-[var(--separator)] px-3 py-2 text-[11px] font-semibold text-[var(--text-secondary)]">
              <span>#</span>
              <span>Tým</span>
              <span>Z</span>
              <span>V</span>
              <span>P</span>
              <span>B</span>
            </div>
            {standings.map((row) => {
              const t = teamById(row.teamId);
              return (
                <button
                  key={row.id}
                  type="button"
                  onClick={() => push({ name: "team", id: row.teamId })}
                  className="grid w-full grid-cols-[28px_1fr_28px_28px_28px_36px] gap-1 border-b border-[var(--separator)] px-3 py-2 text-left text-[13px]"
                >
                  <span className="font-semibold">{row.rank}</span>
                  <span className="truncate font-semibold">{t?.shortName ?? row.teamId}</span>
                  <span>{row.played}</span>
                  <span>{row.wins}</span>
                  <span>{row.losses}</span>
                  <span className="font-bold">{row.points}</span>
                </button>
              );
            })}
            {!standings.length && <EmptyState title="Tabulka není k dispozici" />}
          </div>
        )}
      </div>
    </div>
  );
}

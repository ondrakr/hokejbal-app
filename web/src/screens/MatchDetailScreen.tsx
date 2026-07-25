"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { fetchMatch, fetchMatches, fetchPlayers, fetchStandings } from "@/lib/api";
import { trustedOpenUrl } from "@/lib/supabase";
import type { Match, MatchStatus, Player, StandingRow } from "@/lib/types";
import { teamFormItems, type TeamFormItem } from "@/lib/teamForm";
import { formatMatchTime, formatShortDate } from "@/lib/format";
import { CompetitionBadge, TeamBadge } from "@/components/Badges";
import { IconBell, IconTv } from "@/components/Icons";
import { LiveBadge, UnderlineTabs } from "@/components/MatchRow";
import { MatchTimeline } from "@/components/match-detail/MatchTimeline";
import { MatchOverview } from "@/components/match-detail/MatchOverview";
import { MatchStatsPanel } from "@/components/match-detail/MatchStatsPanel";
import { MatchLineups } from "@/components/match-detail/MatchLineups";
import { MatchStandings } from "@/components/match-detail/MatchStandings";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useMatchAlerts } from "@/stores/matchAlerts";
import { useNav } from "@/stores/navigation";
import { useTips } from "@/stores/tips";

type Section = "Zápas" | "Přehled" | "Statistiky" | "Sestavy" | "Tabulka";

function tabsFor(status: MatchStatus): Section[] {
  if (status === "scheduled" || status === "postponed") {
    return ["Přehled", "Statistiky", "Sestavy", "Tabulka"];
  }
  return ["Zápas", "Statistiky", "Sestavy", "Tabulka", "Přehled"];
}

function defaultSection(status: MatchStatus): Section {
  return status === "scheduled" || status === "postponed" ? "Přehled" : "Zápas";
}

function statusLabel(match: Match): string {
  switch (match.status) {
    case "live":
      return match.period?.trim() ? match.period : "LIVE";
    case "finished": {
      const p = match.period.toLowerCase();
      if (p.includes("prodl") || p.includes("overtime")) return "Po prodloužení";
      if (p.includes("nájez") || p.includes("shoot")) return "Po nájezdech";
      return "Konec";
    }
    case "scheduled":
      return "Začátek";
    case "postponed":
      return "Odloženo";
  }
}

export function MatchDetailScreen({ id }: { id: string }) {
  const { teamById, competitionById } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const alerts = useMatchAlerts();
  const tips = useTips();

  const [match, setMatch] = useState<Match | null>(null);
  const [homePlayers, setHomePlayers] = useState<Player[]>([]);
  const [awayPlayers, setAwayPlayers] = useState<Player[]>([]);
  const [standings, setStandings] = useState<StandingRow[]>([]);
  const [homeForm, setHomeForm] = useState<TeamFormItem[]>([]);
  const [awayForm, setAwayForm] = useState<TeamFormItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [section, setSection] = useState<Section>("Přehled");
  const didApplyInitial = useRef(false);
  const prevStatus = useRef<MatchStatus | null>(null);

  useEffect(() => {
    let cancelled = false;
    didApplyInitial.current = false;
    prevStatus.current = null;

    async function load() {
      setLoading(true);
      try {
        const m = await fetchMatch(id);
        if (cancelled) return;
        if (!m) {
          setMatch(null);
          return;
        }
        setMatch(m);

        const [home, away, table, homeHistory, awayHistory] = await Promise.all([
          fetchPlayers({ teamId: m.homeTeamId }),
          fetchPlayers({ teamId: m.awayTeamId }),
          fetchStandings(m.competitionId),
          fetchMatches({
            competitionId: m.competitionId,
            status: "finished",
            teamId: m.homeTeamId,
          }),
          fetchMatches({
            competitionId: m.competitionId,
            status: "finished",
            teamId: m.awayTeamId,
          }),
        ]);

        if (cancelled) return;
        setHomePlayers(home);
        setAwayPlayers(away);
        setStandings(table);
        setHomeForm(teamFormItems(homeHistory, m.homeTeamId, m.id));
        setAwayForm(teamFormItems(awayHistory, m.awayTeamId, m.id));
        tips.resolveAgainstMatches([m]);

        if (!didApplyInitial.current) {
          setSection(defaultSection(m.status));
          didApplyInitial.current = true;
        }
        prevStatus.current = m.status;
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void load();

    const timer = window.setInterval(async () => {
      const m = await fetchMatch(id);
      if (cancelled || !m) return;
      const was = prevStatus.current;
      if (
        was &&
        (was === "scheduled" || was === "postponed") &&
        (m.status === "live" || m.status === "finished")
      ) {
        setSection("Zápas");
      }
      prevStatus.current = m.status;
      setMatch(m);
    }, 8000);

    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  useEffect(() => {
    if (!match) return;
    const allowed = tabsFor(match.status);
    if (!allowed.includes(section)) {
      setSection(defaultSection(match.status));
    }
  }, [match, section]);

  const home = match ? teamById(match.homeTeamId) : undefined;
  const away = match ? teamById(match.awayTeamId) : undefined;
  const comp = match ? competitionById(match.competitionId) : undefined;

  const playerMap = useMemo(() => {
    const map = new Map<string, Player>();
    for (const p of homePlayers) map.set(p.id, p);
    for (const p of awayPlayers) map.set(p.id, p);
    return map;
  }, [homePlayers, awayPlayers]);

  if (loading) return <LoadingState />;
  if (!match) return <EmptyState title="Zápas nenalezen" />;

  const tabs = tabsFor(match.status);
  const stream = trustedOpenUrl(match.streamURL);
  const isBroadcast = Boolean(match.streamURL);
  const alertOn = alerts.isEnabled(match.id);

  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader
        title={comp?.shortName ?? "Zápas"}
        left={<BackButton onClick={pop} />}
        right={
          <div className="flex items-center gap-0.5">
            <button
              type="button"
              className={`flex h-9 w-9 items-center justify-center ${
                alertOn ? "text-brand" : "text-hb-faint"
              }`}
              onClick={() => alerts.toggle(match.id)}
              aria-label={alertOn ? "Oznámení zápasu zapnuta" : "Oznámení zápasu vypnuta"}
            >
              <IconBell muted={!alertOn} />
            </button>
            <button
              type="button"
              className={`flex h-9 w-9 items-center justify-center text-[20px] ${
                fav.isMatch(match.id) ? "text-brand" : "text-hb-faint"
              }`}
              onClick={() => fav.toggleMatch(match.id)}
              aria-label="Sledovat zápas"
            >
              {fav.isMatch(match.id) ? "★" : "☆"}
            </button>
          </div>
        }
      />

      <div className="px-4 pt-2.5">
        <div className="hb-card hb-card-lg space-y-4 p-4">
          <button
            type="button"
            className="flex w-full items-center gap-2 text-left"
            onClick={() => comp && push({ name: "competition", id: comp.id })}
          >
            <span className="hb-accent-bar !h-4" />
            {comp && <CompetitionBadge competition={comp} size={18} />}
            <span className="min-w-0 flex-1 truncate text-[11px] font-bold tracking-[0.5px] text-hb-muted uppercase">
              {(comp?.name ?? match.competitionId).toUpperCase()}
              {match.round > 0 ? ` · ${match.round}. KOLO` : ""}
            </span>
            {comp && <span className="text-[9px] font-bold text-hb-faint">›</span>}
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              className="flex min-w-0 flex-1 flex-col items-center gap-2"
              onClick={() => push({ name: "team", id: match.homeTeamId })}
            >
              <TeamBadge team={home} size={48} />
              <div className="line-clamp-2 text-center text-[13px] font-bold text-hb-fg">
                {home?.shortName}
              </div>
            </button>

            <div className="flex w-[118px] shrink-0 flex-col items-center gap-2">
              {match.status === "live" ? (
                <LiveBadge />
              ) : (
                <span className="rounded-full bg-card-inset px-2.5 py-1 text-[10px] font-bold tracking-[1px] text-hb-muted uppercase">
                  {statusLabel(match)}
                </span>
              )}
              <div
                className="hb-number text-[34px] font-extrabold leading-none"
                style={{
                  color:
                    match.status === "scheduled"
                      ? "var(--brand)"
                      : match.status === "live"
                        ? "var(--live)"
                        : "var(--text-primary)",
                }}
              >
                {match.status === "scheduled" || match.status === "postponed"
                  ? formatMatchTime(match.scheduledAt)
                  : `${match.homeScore} : ${match.awayScore}`}
              </div>
              <div className="text-center text-[11px] font-medium text-hb-faint">
                {formatShortDate(match.scheduledAt)} · {formatMatchTime(match.scheduledAt)}
              </div>
            </div>

            <button
              type="button"
              className="flex min-w-0 flex-1 flex-col items-center gap-2"
              onClick={() => push({ name: "team", id: match.awayTeamId })}
            >
              <TeamBadge team={away} size={48} />
              <div className="line-clamp-2 text-center text-[13px] font-bold text-hb-fg">
                {away?.shortName}
              </div>
            </button>
          </div>

          {isBroadcast &&
            (stream ? (
              <a href={stream} target="_blank" rel="noreferrer" className="hb-broadcast-btn">
                <IconTv size={14} filled />
                <span className="flex-1">ŽIVÝ PŘENOS: Hokejbal TV</span>
                <span className="text-[11px] font-bold hb-on-brand">↗</span>
              </a>
            ) : (
              <div className="flex items-center gap-2 rounded-[12px] bg-card-inset px-3.5 py-[11px] font-bold text-hb-muted" style={{ fontSize: 13 }}>
                <IconTv size={14} />
                <span className="flex-1">ŽIVÝ PŘENOS: Hokejbal TV</span>
              </div>
            ))}
        </div>
      </div>

      <div className="mx-4 mt-3.5 mb-3 overflow-hidden hb-card hb-card-lg">
        <UnderlineTabs
          tabs={tabs}
          value={section}
          onChange={(v) => setSection(v as Section)}
        />

        <div className="py-3 pb-4">
          {section === "Zápas" && (
            <MatchTimeline
              match={match}
              home={home}
              away={away}
              playerMap={playerMap}
              onPlayer={(pid) => push({ name: "player", id: pid })}
            />
          )}
          {section === "Přehled" && (
            <MatchOverview
              match={match}
              home={home}
              away={away}
              homeForm={homeForm}
              awayForm={awayForm}
            />
          )}
          {section === "Statistiky" && <MatchStatsPanel match={match} />}
          {section === "Sestavy" && (
            <MatchLineups
              homePlayers={homePlayers}
              awayPlayers={awayPlayers}
              onPlayer={(pid) => push({ name: "player", id: pid })}
            />
          )}
          {section === "Tabulka" && (
            <MatchStandings
              rows={standings}
              highlightTeamIds={[match.homeTeamId, match.awayTeamId]}
              teamById={teamById}
              competitionSlug={comp?.slug}
              onTeam={(tid) => push({ name: "team", id: tid })}
            />
          )}
        </div>
      </div>
    </div>
  );
}

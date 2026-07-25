"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchPlayer, fetchPlayerHistory, fetchPlayers } from "@/lib/api";
import { teamFormOutcome } from "@/lib/teamForm";
import type { Match, Player, PlayerSeasonStat, Team } from "@/lib/types";
import { playerFullName } from "@/lib/types";
import { PlayerAvatar, TeamBadge } from "@/components/Badges";
import { IconChevronRight } from "@/components/Icons";
import { MatchRow, Pill, PillTrack, UnderlineTabs } from "@/components/MatchRow";
import { SwipeTabPanels } from "@/components/SwipeTabPanels";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const TABS = ["Zápasy", "Sezóny"];

type PlayerMatchAppearance = {
  id: string;
  match: Match;
  clubId: string;
  seasonId: string;
  goals: number;
  assists: number;
  points: number;
  penaltyMinutes: number;
};

function makeAppearance(
  match: Match,
  clubId: string,
  seasonId: string,
  playerId: string
): PlayerMatchAppearance {
  const goals = match.events.filter(
    (e) => e.kind === "goal" && e.playerId === playerId
  ).length;
  const assists = match.events.filter(
    (e) => e.kind === "goal" && e.assistIds.includes(playerId)
  ).length;
  const pens = match.events.filter(
    (e) => e.kind === "penalty" && e.playerId === playerId
  ).length;
  return {
    id: match.id,
    match,
    clubId,
    seasonId,
    goals,
    assists,
    points: goals + assists,
    penaltyMinutes: pens * 2,
  };
}

function buildAppearances(
  playerId: string,
  playerTeamId: string | undefined,
  history: PlayerSeasonStat[],
  matches: Match[]
): PlayerMatchAppearance[] {
  const collected: PlayerMatchAppearance[] = [];
  const seen = new Set<string>();

  for (const row of history) {
    for (const match of matches) {
      if (seen.has(match.id)) continue;
      if (match.competitionId !== row.competitionId) continue;
      if (match.homeTeamId !== row.clubId && match.awayTeamId !== row.clubId) continue;
      seen.add(match.id);
      collected.push(makeAppearance(match, row.clubId, row.seasonId, playerId));
    }
  }

  for (const match of matches) {
    if (seen.has(match.id)) continue;
    const inEvents = match.events.some(
      (e) =>
        (e.kind === "goal" || e.kind === "penalty") &&
        (e.playerId === playerId || e.assistIds.includes(playerId))
    );
    if (!inEvents) continue;

    const clubId =
      (playerTeamId &&
      (match.homeTeamId === playerTeamId || match.awayTeamId === playerTeamId)
        ? playerTeamId
        : undefined) ??
      match.events.find(
        (e) => e.playerId === playerId || e.assistIds.includes(playerId)
      )?.teamId;
    if (!clubId) continue;
    if (match.homeTeamId !== clubId && match.awayTeamId !== clubId) continue;

    const seasonId =
      history.find(
        (h) => h.clubId === clubId && h.competitionId === match.competitionId
      )?.seasonId ??
      history.find((h) => h.competitionId === match.competitionId)?.seasonId ??
      history[0]?.seasonId ??
      "";

    seen.add(match.id);
    collected.push(makeAppearance(match, clubId, seasonId, playerId));
  }

  return collected.sort((a, b) =>
    b.match.scheduledAt.localeCompare(a.match.scheduledAt)
  );
}

/** Port PlayerDetailView.swift */
export function PlayerDetailScreen({ id }: { id: string }) {
  const { matches, teamById } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const [player, setPlayer] = useState<Player | null>(null);
  const [history, setHistory] = useState<PlayerSeasonStat[]>([]);
  const [tab, setTab] = useState(TABS[0]);
  const [selectedSeasonId, setSelectedSeasonId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const [p, h] = await Promise.all([fetchPlayer(id), fetchPlayerHistory(id)]);
        if (!cancelled) {
          setPlayer(p);
          setHistory(h);
          setSelectedSeasonId(h[0]?.seasonId ?? p?.seasonId ?? null);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [id]);

  const appearances = useMemo(
    () => buildAppearances(id, player?.teamId, history, matches),
    [id, player?.teamId, history, matches]
  );

  const seasonChips = useMemo(() => {
    const ids = [...new Set(history.map((h) => h.seasonId))];
    return ids.sort((a, b) => b.localeCompare(a));
  }, [history]);

  const filteredAppearances = useMemo(() => {
    if (!selectedSeasonId) return appearances;
    return appearances.filter((a) => a.seasonId === selectedSeasonId);
  }, [appearances, selectedSeasonId]);

  const selectedSeasonStat = useMemo(() => {
    if (!selectedSeasonId) return history[0];
    return history.find((h) => h.seasonId === selectedSeasonId) ?? history[0];
  }, [history, selectedSeasonId]);

  const team = player ? teamById(player.teamId) : undefined;

  if (loading) return <LoadingState />;
  if (!player) return <EmptyState title="Hráč nenalezen" />;

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter bg-canvas">
      <ScreenHeader
        title={player.lastName}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-[20px]"
            style={{ color: fav.isPlayer(player.id) ? "var(--brand)" : "var(--text-tertiary)" }}
            onClick={() => fav.togglePlayer(player.id)}
            aria-label="Oblíbený hráč"
          >
            {fav.isPlayer(player.id) ? "★" : "☆"}
          </button>
        }
      />

      <div className="bg-surface px-4 pt-2.5 pb-4">
        <div className="flex items-center gap-3.5">
          <PlayerAvatar player={player} size={68} />
          <div className="min-w-0 flex-1">
            <h1
              className="hb-display leading-tight"
              style={{ fontSize: 24, color: "var(--text-primary)" }}
            >
              {playerFullName(player)}
            </h1>
            {team ? (
              <button
                type="button"
                onClick={() => push({ name: "team", id: team.id })}
                className="mt-1.5 flex items-center gap-1.5"
              >
                <TeamBadge team={team} size={18} />
                <span
                  className="font-semibold"
                  style={{ fontSize: 13, color: "var(--text-primary)" }}
                >
                  {team.shortName}
                </span>
                <span style={{ color: "var(--text-tertiary)" }}>
                  <IconChevronRight size={10} />
                </span>
              </button>
            ) : null}
          </div>
        </div>

        {selectedSeasonStat ? <PlayerStatsStrip stats={selectedSeasonStat} /> : null}
      </div>

      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      <SwipeTabPanels
        tabs={TABS}
        value={tab}
        onChange={setTab}
        panelClassName="bg-canvas pb-7"
      >
        <div>
            {seasonChips.length > 0 && selectedSeasonId && (
              <PillTrack>
                {seasonChips.map((seasonId) => {
                  const label =
                    history.find((h) => h.seasonId === seasonId)?.seasonLabel ?? seasonId;
                  return (
                    <Pill
                      key={seasonId}
                      active={selectedSeasonId === seasonId}
                      onClick={() => setSelectedSeasonId(seasonId)}
                    >
                      {label}
                    </Pill>
                  );
                })}
              </PillTrack>
            )}

            {filteredAppearances.length === 0 ? (
              <EmptyState
                title="Bez zápasů"
                hint="Pro zvolený ročník zatím nemáme zápasy hráče."
              />
            ) : (
              filteredAppearances.map((item) => (
                <PlayerMatchRow key={item.id} item={item} focusTeamId={player.teamId} />
              ))
            )}
          </div>

        <div className="space-y-2.5 px-4 pt-3">
            {history.map((row) => (
              <SeasonCard key={row.id} row={row} team={teamById(row.clubId)} />
            ))}
            {!history.length && (
              <EmptyState title="Bez historie" hint="Zatím nemáme sezónní statistiky." />
            )}
          </div>
      </SwipeTabPanels>
    </div>
  );
}

function PlayerStatsStrip({ stats }: { stats: PlayerSeasonStat }) {
  const cells =
    stats.position === "goalie"
      ? [
          { label: "Z", value: String(stats.games) },
          { label: "%", value: String(Math.round(stats.savePercentage ?? 0)) },
          { label: "GAA", value: (stats.goalsAgainstAverage ?? 0).toFixed(2) },
          { label: "TM", value: String(stats.penaltyMinutes) },
        ]
      : [
          { label: "Z", value: String(stats.games) },
          { label: "G", value: String(stats.goals) },
          { label: "A", value: String(stats.assists) },
          { label: "KB", value: String(stats.points) },
          { label: "TM", value: String(stats.penaltyMinutes) },
        ];

  return (
    <div className="mt-3.5 flex rounded-[var(--radius-md)] bg-card-inset py-3">
      {cells.map((c) => (
        <HeaderStat key={c.label} label={c.label} value={c.value} />
      ))}
    </div>
  );
}

function HeaderStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex min-w-0 flex-1 flex-col items-center gap-1">
      <span
        className="font-bold tracking-[0.3px]"
        style={{ fontSize: 10, color: "var(--text-tertiary)" }}
      >
        {label}
      </span>
      <span
        className="hb-number truncate font-extrabold"
        style={{ fontSize: 16, color: "var(--text-primary)" }}
      >
        {value}
      </span>
    </div>
  );
}

function AppearanceStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex min-w-0 flex-1 flex-col items-center gap-0.5">
      <span
        className="font-bold tracking-[0.3px]"
        style={{ fontSize: 10, color: "var(--text-tertiary)" }}
      >
        {label}
      </span>
      <span
        className="hb-number truncate font-extrabold"
        style={{ fontSize: 14, color: "var(--text-primary)" }}
      >
        {value}
      </span>
    </div>
  );
}

/** Port playerMatchRow — MatchRow embedded + G/A/KB/TM + V/R/P */
function PlayerMatchRow({
  item,
  focusTeamId,
}: {
  item: PlayerMatchAppearance;
  focusTeamId: string;
}) {
  const { push } = useNav();
  const match = item.match;
  const focusIsHome =
    match.homeTeamId === focusTeamId || match.homeTeamId === item.clubId;
  const finished = match.status === "finished";
  const focusWon =
    finished &&
    match.homeScore !== match.awayScore &&
    (focusIsHome ? match.homeScore > match.awayScore : match.awayScore > match.homeScore);
  const outcome = finished ? teamFormOutcome(match, item.clubId) : null;

  return (
    <button
      type="button"
      onClick={() => push({ name: "match", id: match.id })}
      className="block w-full px-4 py-[5px] text-left"
    >
      <div className="hb-card overflow-hidden">
        <MatchRow match={match} embedded />

        <div className="mx-3.5 h-px bg-[var(--card-stroke)]" />

        <div className="mx-2.5 mb-2.5 mt-2 flex items-center rounded-[var(--radius-sm)] bg-card-inset px-1.5 py-2.5">
          <AppearanceStat label="G" value={String(item.goals)} />
          <AppearanceStat label="A" value={String(item.assists)} />
          <AppearanceStat label="KB" value={String(item.points)} />
          <AppearanceStat label="TM" value={String(item.penaltyMinutes)} />
          {finished && outcome ? (
            <span
              className="mr-1 flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded font-bold hb-on-brand"
              style={{
                fontSize: 11,
                background:
                  match.homeScore === match.awayScore
                    ? "var(--draw)"
                    : focusWon
                      ? "var(--win)"
                      : "var(--loss)",
              }}
            >
              {match.homeScore === match.awayScore ? "R" : focusWon ? "V" : "P"}
            </span>
          ) : (
            <span className="w-[26px] shrink-0" />
          )}
        </div>
      </div>
    </button>
  );
}

function SeasonCard({ row, team }: { row: PlayerSeasonStat; team?: Team }) {
  const cells =
    row.position === "goalie"
      ? [
          { label: "Z", value: String(row.games) },
          { label: "%", value: String(Math.round(row.savePercentage ?? 0)) },
          { label: "GAA", value: (row.goalsAgainstAverage ?? 0).toFixed(2) },
          { label: "TM", value: String(row.penaltyMinutes) },
        ]
      : [
          { label: "Z", value: String(row.games) },
          { label: "G", value: String(row.goals) },
          { label: "A", value: String(row.assists) },
          { label: "KB", value: String(row.points) },
          { label: "TM", value: String(row.penaltyMinutes) },
        ];

  return (
    <div className="hb-card space-y-3 p-3.5">
      <div className="flex items-center gap-2.5">
        {team ? <TeamBadge team={team} size={28} /> : null}
        <div className="min-w-0 flex-1">
          <div
            className="truncate font-bold"
            style={{ fontSize: 14, color: "var(--text-primary)" }}
          >
            {row.competitionName}
          </div>
          <div
            className="truncate font-medium"
            style={{ fontSize: 12, color: "var(--text-secondary)" }}
          >
            {team?.shortName ?? "Tým"} · {row.seasonLabel}
          </div>
        </div>
      </div>
      <div className="flex rounded-[var(--radius-sm)] bg-card-inset py-2.5">
        {cells.map((c) => (
          <AppearanceStat key={c.label} label={c.label} value={c.value} />
        ))}
      </div>
    </div>
  );
}

/** Prefetch helper kept for search parity */
export async function loadPlayersForSearch() {
  return fetchPlayers();
}

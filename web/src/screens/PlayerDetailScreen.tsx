"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchPlayer, fetchPlayerHistory, fetchPlayers } from "@/lib/api";
import { format } from "date-fns";
import { parseDate } from "@/lib/format";
import { teamFormColor, teamFormOutcome } from "@/lib/teamForm";
import type { Match, Player, PlayerSeasonStat, Team } from "@/lib/types";
import { playerFullName } from "@/lib/types";
import { PlayerAvatar, TeamBadge } from "@/components/Badges";
import { IconChevronRight } from "@/components/Icons";
import { UnderlineTabs } from "@/components/MatchRow";
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

  // Zápasy kde hráč figuroval v eventech, ale nejsou pokryté historií.
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
    <div className="flex min-h-0 flex-1 flex-col hb-enter bg-surface">
      <ScreenHeader
        title={player.lastName}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className={fav.isPlayer(player.id) ? "text-brand" : "text-hb-faint"}
            onClick={() => fav.togglePlayer(player.id)}
            aria-label="Oblíbený hráč"
          >
            ★
          </button>
        }
      />

      <div className="bg-surface px-4 pt-2.5 pb-4">
        <div className="flex items-center gap-3.5">
          <PlayerAvatar player={player} size={68} />
          <div className="min-w-0 flex-1">
            <h1 className="hb-display text-[24px] leading-tight text-hb-fg">
              {playerFullName(player)}
            </h1>
            {team ? (
              <button
                type="button"
                onClick={() => push({ name: "team", id: team.id })}
                className="mt-1.5 flex items-center gap-1.5"
              >
                <TeamBadge team={team} size={18} />
                <span className="text-[13px] font-semibold text-hb-fg">
                  {team.shortName}
                </span>
                <span className="text-hb-faint">
                  <IconChevronRight size={10} />
                </span>
              </button>
            ) : null}
          </div>
        </div>

        {selectedSeasonStat ? (
          <PlayerStatsStrip stats={selectedSeasonStat} />
        ) : null}
      </div>

      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      <div className="hb-scroll min-h-0 flex-1 bg-canvas pb-7">
        {tab === "Zápasy" && (
          <div>
            {seasonChips.length > 0 && (
              <div className="flex gap-2 overflow-x-auto px-4 pt-3 pb-2">
                {seasonChips.map((seasonId) => {
                  const label =
                    history.find((h) => h.seasonId === seasonId)?.seasonLabel ??
                    seasonId;
                  const selected = selectedSeasonId === seasonId;
                  return (
                    <button
                      key={seasonId}
                      type="button"
                      onClick={() => setSelectedSeasonId(seasonId)}
                      className={`shrink-0 rounded-full px-3 py-2 text-[13px] font-semibold ${
                        selected
                          ? "bg-brand text-on-brand"
                          : "border border-card-stroke bg-card text-hb-muted"
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            )}

            {filteredAppearances.length === 0 ? (
              <EmptyState
                title="Bez zápasů"
                hint="Pro zvolený ročník zatím nemáme zápasy hráče."
              />
            ) : (
              filteredAppearances.map((item) => (
                <PlayerMatchRow
                  key={item.id}
                  item={item}
                  focusTeamId={player.teamId}
                />
              ))
            )}
          </div>
        )}

        {tab === "Sezóny" && (
          <div className="space-y-2.5 px-4 pt-3">
            {history.map((row) => (
              <SeasonCard key={row.id} row={row} team={teamById(row.clubId)} />
            ))}
            {!history.length && (
              <EmptyState
                title="Bez historie"
                hint="Zatím nemáme sezónní statistiky."
              />
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function PlayerStatsStrip({ stats }: { stats: PlayerSeasonStat }) {
  const cells =
    stats.position === "goalie"
      ? [
          { label: "Z", value: String(stats.games) },
          { label: "%", value: String(Math.round(stats.savePercentage ?? 0)) },
          {
            label: "GAA",
            value: (stats.goalsAgainstAverage ?? 0).toFixed(2),
          },
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
      <span className="text-[10px] font-bold tracking-[0.3px] text-hb-faint">
        {label}
      </span>
      <span className="hb-number truncate text-[16px] font-extrabold text-hb-fg">
        {value}
      </span>
    </div>
  );
}

function AppearanceStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex min-w-0 flex-1 flex-col items-center gap-0.5">
      <span className="text-[10px] font-bold tracking-[0.3px] text-hb-faint">
        {label}
      </span>
      <span className="hb-number truncate text-[14px] font-extrabold text-hb-fg">
        {value}
      </span>
    </div>
  );
}

/** date · opponent · V/R/P · G A KB TM — ne generický MatchRow */
function PlayerMatchRow({
  item,
  focusTeamId,
}: {
  item: PlayerMatchAppearance;
  focusTeamId: string;
}) {
  const { teamById } = useCatalog();
  const { push } = useNav();
  const match = item.match;
  const focusIsHome =
    match.homeTeamId === focusTeamId || match.homeTeamId === item.clubId;
  const opponentId = focusIsHome ? match.awayTeamId : match.homeTeamId;
  const opponent = teamById(opponentId);
  const focusScore = focusIsHome ? match.homeScore : match.awayScore;
  const otherScore = focusIsHome ? match.awayScore : match.homeScore;
  const finished = match.status === "finished";
  const outcome = finished ? teamFormOutcome(match, item.clubId) : null;

  return (
    <button
      type="button"
      onClick={() => push({ name: "match", id: match.id })}
      className="block w-full px-4 py-[5px] text-left"
    >
      <div className="hb-card overflow-hidden">
        <div className="flex items-center gap-2.5 px-3.5 pt-3 pb-2">
          <span className="w-10 shrink-0 text-[11px] font-medium text-hb-faint">
            {format(parseDate(match.scheduledAt), "dd.MM.")}
          </span>
          <TeamBadge team={opponent} size={22} />
          <div className="min-w-0 flex-1">
            <div className="truncate text-[14px] font-semibold text-hb-fg">
              {opponent?.shortName ?? "—"}
            </div>
            {finished || match.status === "live" ? (
              <div className="mt-0.5 text-[12px] font-medium tabular-nums text-hb-muted">
                {focusScore}:{otherScore}
              </div>
            ) : null}
          </div>
          {finished && outcome ? (
            <span
              className="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded text-[11px] font-bold text-white"
              style={{ background: teamFormColor(outcome) }}
            >
              {outcome === "win" ? "V" : outcome === "draw" ? "R" : "P"}
            </span>
          ) : null}
        </div>

        <div className="mx-2.5 mb-2.5 mt-1 flex items-center rounded-[var(--radius-sm)] bg-card-inset px-1.5 py-2.5">
          <AppearanceStat label="G" value={String(item.goals)} />
          <AppearanceStat label="A" value={String(item.assists)} />
          <AppearanceStat label="KB" value={String(item.points)} />
          <AppearanceStat label="TM" value={String(item.penaltyMinutes)} />
        </div>
      </div>
    </button>
  );
}

function SeasonCard({
  row,
  team,
}: {
  row: PlayerSeasonStat;
  team?: Team;
}) {
  const cells =
    row.position === "goalie"
      ? [
          { label: "Z", value: String(row.games) },
          { label: "%", value: String(Math.round(row.savePercentage ?? 0)) },
          {
            label: "GAA",
            value: (row.goalsAgainstAverage ?? 0).toFixed(2),
          },
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
          <div className="truncate text-[14px] font-bold text-hb-fg">
            {row.competitionName}
          </div>
          <div className="truncate text-[12px] font-medium text-hb-muted">
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

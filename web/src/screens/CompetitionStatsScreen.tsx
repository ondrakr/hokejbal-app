"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchPlayers, fetchStandings } from "@/lib/api";
import {
  playerLeaderCards,
  playerMetricMeta,
  rankPlayers,
  rankTeams,
  teamLeaderCards,
  teamMetricMeta,
  type PlayerStatMetric,
  type TeamStatMetric,
} from "@/lib/competitionStats";
import type { Match, Player, StandingRow } from "@/lib/types";
import {
  PlayerLeaderboardRow,
  PlayerStatLeaderCard,
  TeamLeaderboardRow,
  TeamStatLeaderCard,
} from "@/components/CompetitionStatsCards";
import { Pill, PillTrack } from "@/components/MatchRow";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

/**
 * Grid leaderů + otevření žebříčku — tab Statistiky v detailu soutěže.
 * 1:1 s iOS CompetitionStatsPanel.
 */
export function CompetitionStatsPanel({
  competitionId,
  matches: matchesProp,
  standings: standingsProp,
}: {
  competitionId: string;
  matches?: Match[];
  standings?: StandingRow[];
}) {
  const { matches: catalogMatches, teamById } = useCatalog();
  const { push } = useNav();
  const [scope, setScope] = useState<"HRÁČI" | "TÝMY">("HRÁČI");
  const [players, setPlayers] = useState<Player[]>([]);
  const [standingsLocal, setStandingsLocal] = useState<StandingRow[]>([]);
  const [loading, setLoading] = useState(true);

  const matches = matchesProp ?? catalogMatches.filter((m) => m.competitionId === competitionId);
  const standings = standingsProp ?? standingsLocal;

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const needStandings = standingsProp === undefined;
        const [pl, st] = await Promise.all([
          fetchPlayers({ competitionId }),
          needStandings ? fetchStandings(competitionId) : Promise.resolve(null),
        ]);
        if (!cancelled) {
          setPlayers(pl);
          if (st) setStandingsLocal(st);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [competitionId, standingsProp]);

  const playerCards = useMemo(
    () => playerLeaderCards(players, teamById),
    [players, teamById]
  );
  const teamCards = useMemo(
    () => teamLeaderCards(standings, matches, teamById),
    [standings, matches, teamById]
  );

  // iOS: Progress jen když je loading a ještě žádná data
  if (loading && players.length === 0 && standings.length === 0) {
    return <LoadingState label="Načítám statistiky…" />;
  }

  return (
    <div className="pb-6">
      <PillTrack>
        {(["HRÁČI", "TÝMY"] as const).map((s) => (
          <Pill key={s} active={scope === s} onClick={() => setScope(s)}>
            {s}
          </Pill>
        ))}
      </PillTrack>

      {scope === "HRÁČI" ? (
        players.length === 0 ? (
          <EmptyState
            title="Bez statistik hráčů"
            hint="Pro tuto soutěž zatím nemáme body hráčů."
          />
        ) : (
          <div className="grid grid-cols-2 gap-2.5 px-4">
            {playerCards.map((card) => (
              <PlayerStatLeaderCard
                key={card.metric}
                title={card.title}
                leader={card.leader}
                onClick={() =>
                  push({
                    name: "competitionStats",
                    competitionId,
                    scope: "players",
                    metric: card.metric,
                  })
                }
              />
            ))}
          </div>
        )
      ) : standings.length === 0 && teamCards.every((c) => !c.leader) ? (
        <EmptyState
          title="Bez statistik týmů"
          hint="Tabulka soutěže zatím není k dispozici."
        />
      ) : (
        <div className="grid grid-cols-2 gap-2.5 px-4">
          {teamCards.map((card) => (
            <TeamStatLeaderCard
              key={card.metric}
              title={card.title}
              leader={card.leader}
              onClick={() =>
                push({
                  name: "competitionStats",
                  competitionId,
                  scope: "teams",
                  metric: card.metric,
                })
              }
            />
          ))}
        </div>
      )}
    </div>
  );
}

/**
 * Statistiky hráčů týmu — stejné metriky jako soutěž (KB/G/A/TM/PPG/SHG), jen soupiska týmu.
 */
export function TeamStatsPanel({
  teamId,
  competitionId,
  players,
}: {
  teamId: string;
  competitionId: string;
  players: Player[];
}) {
  const { teamById } = useCatalog();
  const { push } = useNav();

  const teamPlayers = useMemo(
    () => players.filter((p) => p.teamId === teamId),
    [players, teamId]
  );

  const playerCards = useMemo(
    () => playerLeaderCards(teamPlayers, teamById),
    [teamPlayers, teamById]
  );

  if (teamPlayers.length === 0) {
    return (
      <EmptyState
        title="Bez statistik hráčů"
        hint="Pro tento tým zatím nemáme body hráčů."
      />
    );
  }

  return (
    <div className="grid grid-cols-2 gap-2.5 px-4 pb-6 pt-3">
      {playerCards.map((card) => (
        <PlayerStatLeaderCard
          key={card.metric}
          title={card.title}
          leader={card.leader}
          onClick={() =>
            push({
              name: "competitionStats",
              competitionId,
              scope: "players",
              metric: card.metric,
              teamId,
            })
          }
        />
      ))}
    </div>
  );
}

/** Plný žebříček jedné metriky — 1:1 s iOS CompetitionStatsLeaderboardView */
export function CompetitionStatsLeaderboardScreen({
  competitionId,
  scope,
  metric,
  teamId,
}: {
  competitionId: string;
  scope: "players" | "teams";
  metric: string;
  teamId?: string;
}) {
  const { matches, teamById, competitionById } = useCatalog();
  const { pop, push } = useNav();
  const [players, setPlayers] = useState<Player[]>([]);
  const [standings, setStandings] = useState<StandingRow[]>([]);
  const [loading, setLoading] = useState(true);

  const competition = competitionById(competitionId);
  const team = teamId ? teamById(teamId) : undefined;
  const competitionMatches = useMemo(
    () => matches.filter((m) => m.competitionId === competitionId),
    [matches, competitionId]
  );

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const [pl, st] = await Promise.all([
          fetchPlayers(
            teamId
              ? { teamId, competitionId }
              : { competitionId }
          ),
          fetchStandings(competitionId),
        ]);
        if (!cancelled) {
          setPlayers(pl);
          setStandings(st);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [competitionId, teamId]);

  const title =
    scope === "players"
      ? playerMetricMeta(metric as PlayerStatMetric).title
      : teamMetricMeta(metric as TeamStatMetric).title;

  const scopedPlayers = useMemo(() => {
    if (!teamId) return players;
    return players.filter((p) => p.teamId === teamId);
  }, [players, teamId]);

  const playerRows =
    scope === "players"
      ? rankPlayers(scopedPlayers, teamById, metric as PlayerStatMetric)
      : [];
  const teamRows =
    scope === "teams"
      ? rankTeams(standings, competitionMatches, teamById, metric as TeamStatMetric)
      : [];

  const subtitle = team?.name ?? competition?.name;

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter bg-canvas">
      <ScreenHeader title={title} left={<BackButton onClick={pop} />} />
      {subtitle ? (
        <div
          className="px-4 pb-1 font-semibold"
          style={{ fontSize: 12, color: "var(--text-secondary)" }}
        >
          {subtitle}
        </div>
      ) : null}

      <div className="hb-scroll min-h-0 flex-1 px-4 pb-8 pt-2">
        {loading ? (
          <LoadingState />
        ) : scope === "players" ? (
          playerRows.length === 0 ? (
            <EmptyState
              title="Prázdný žebříček"
              hint="Pro tuto metriku zatím nejsou data."
            />
          ) : (
            playerRows.map((row, i) => (
              <PlayerLeaderboardRow
                key={row.player.id}
                rank={i + 1}
                row={row}
                featured={i === 0}
                onClick={() => push({ name: "player", id: row.player.id })}
              />
            ))
          )
        ) : teamRows.length === 0 ? (
          <EmptyState
            title="Prázdný žebříček"
            hint="Pro tuto metriku zatím nejsou data."
          />
        ) : (
          teamRows.map((row, i) => (
            <TeamLeaderboardRow
              key={row.team.id}
              rank={i + 1}
              row={row}
              featured={i === 0}
              onClick={() => push({ name: "team", id: row.team.id })}
            />
          ))
        )}
      </div>
    </div>
  );
}

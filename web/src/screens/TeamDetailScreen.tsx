"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchClubSeasonHistory, fetchPlayers, fetchStandings, fetchTeam } from "@/lib/api";
import { formatNewsDate } from "@/lib/format";
import { teamFormColor, teamFormItems, teamFormLetter } from "@/lib/teamForm";
import type { ClubSeasonRecord, NewsArticle, Player, StandingRow, Team } from "@/lib/types";
import { playerFullName } from "@/lib/types";
import { CompetitionBadge, PlayerAvatar, TeamBadge } from "@/components/Badges";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { StandingsTable } from "@/components/StandingsTable";
import { TeamResultRow } from "@/components/TeamResultRow";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const TABS = ["Výsledky", "Program", "Tabulka", "Soupiska", "Historie", "Zprávy"];

const ROSTER_GROUPS: { title: string; position: Player["position"] }[] = [
  { title: "Brankáři", position: "goalie" },
  { title: "Obránci", position: "defenseman" },
  { title: "Útočníci", position: "forward" },
];

/** Port TeamDetailView — hlavní taby */
export function TeamDetailScreen({ id }: { id: string }) {
  const { matches, competitionById, news } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const [team, setTeam] = useState<Team | null>(null);
  const [players, setPlayers] = useState<Player[]>([]);
  const [standings, setStandings] = useState<StandingRow[]>([]);
  const [seasonHistory, setSeasonHistory] = useState<ClubSeasonRecord[]>([]);
  const [tab, setTab] = useState(TABS[0]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const t = await fetchTeam(id);
        if (cancelled) return;
        setTeam(t);
        if (t) {
          const [pl, st, history] = await Promise.all([
            fetchPlayers({ teamId: t.id, competitionId: t.competitionId }),
            t.competitionId ? fetchStandings(t.competitionId) : Promise.resolve([]),
            fetchClubSeasonHistory(t.id),
          ]);
          if (!cancelled) {
            setPlayers(pl);
            setStandings(st);
            setSeasonHistory(history);
          }
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

  const teamMatches = useMemo(
    () =>
      matches
        .filter((m) => m.homeTeamId === id || m.awayTeamId === id)
        .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt)),
    [matches, id]
  );

  const finishedMatches = useMemo(
    () =>
      teamMatches
        .filter((m) => m.status === "finished" || m.status === "live")
        .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt)),
    [teamMatches]
  );

  const upcomingMatches = useMemo(
    () =>
      teamMatches
        .filter((m) => m.status === "scheduled")
        .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt)),
    [teamMatches]
  );

  const form = useMemo(() => teamFormItems(teamMatches, id), [teamMatches, id]);

  const rosterGroups = useMemo(() => {
    return ROSTER_GROUPS.map(({ title, position }) => {
      const items = players
        .filter((p) => p.position === position)
        .sort((a, b) => a.lastName.localeCompare(b.lastName, "cs"));
      return items.length ? { title, items } : null;
    }).filter(Boolean) as { title: string; items: Player[] }[];
  }, [players]);

  const teamNews = useMemo(() => {
    if (!team) return [] as NewsArticle[];
    const name = team.name.toLowerCase();
    const short = team.shortName.toLowerCase();
    const filtered = news.filter((n) => {
      const title = n.title.toLowerCase();
      return title.includes(name) || title.includes(short);
    });
    const list = filtered.length ? filtered : news;
    return list.slice(0, 10);
  }, [news, team]);

  if (loading) return <LoadingState />;
  if (!team) return <EmptyState title="Tým nenalezen" />;

  const comp = competitionById(team.competitionId);

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter bg-surface">
      <ScreenHeader
        title={team.shortName}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className={fav.isTeam(team.id) ? "text-brand" : "text-hb-faint"}
            onClick={() => fav.toggleTeam(team.id)}
            aria-label="Oblíbený tým"
          >
            ★
          </button>
        }
      />

      <div className="bg-surface px-4 pt-2 pb-3.5">
        <div className="flex items-center gap-3.5">
          <TeamBadge team={team} size={64} />
          <div className="min-w-0 flex-1">
            <h1 className="text-[26px] font-bold leading-tight text-hb-fg">
              {team.shortName}
            </h1>
            {form.length > 0 && (
              <div className="mt-2 flex items-center gap-2">
                <span className="text-[10px] font-bold tracking-[0.5px] text-hb-faint">
                  FORMA
                </span>
                <div className="flex gap-1">
                  {form.map((f) => (
                    <span
                      key={f.id}
                      className="flex h-5 w-5 items-center justify-center rounded-full text-[10px] font-bold text-white"
                      style={{ background: teamFormColor(f.outcome) }}
                    >
                      {teamFormLetter(f.outcome)}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      <div className="hb-scroll min-h-0 flex-1 bg-canvas pb-6">
        {tab === "Výsledky" && (
          <div>
            <div className="flex items-center gap-2.5 bg-secondary-surface px-4 py-3">
              {comp ? <CompetitionBadge competition={comp} size={28} /> : null}
              <span className="text-[13px] font-semibold text-hb-fg">
                {comp?.name ?? "Soutěž"}
              </span>
            </div>
            {finishedMatches.map((m) => (
              <TeamResultRow key={m.id} match={m} focusTeamId={team.id} />
            ))}
            {!finishedMatches.length && (
              <EmptyState
                title="Bez výsledků"
                hint="Zatím tu nejsou odehrané zápasy."
              />
            )}
          </div>
        )}

        {tab === "Program" && (
          <div className="pt-1">
            {upcomingMatches.map((m) => (
              <MatchRow key={m.id} match={m} />
            ))}
            {!upcomingMatches.length && (
              <EmptyState title="Prázdný program" hint="Žádné naplánované zápasy." />
            )}
          </div>
        )}

        {tab === "Tabulka" && (
          <StandingsTable
            rows={standings}
            highlightTeamIds={[team.id]}
            competitionSlug={comp?.slug}
            emptyMessage="Tabulka pro tuto soutěž není k dispozici."
          />
        )}

        {tab === "Soupiska" && (
          <div className="space-y-[18px] pt-3">
            {rosterGroups.map(({ title, items }) => (
              <div key={title}>
                <h2 className="px-4 text-[16px] font-bold text-hb-fg">{title}</h2>
                <div className="mt-2">
                  {items.map((player) => (
                    <div
                      key={`${player.id}-${player.competitionId ?? ""}`}
                      className="flex items-center gap-1 border-b border-separator px-4"
                    >
                      <button
                        type="button"
                        onClick={() => push({ name: "player", id: player.id })}
                        className="flex min-w-0 flex-1 items-center gap-3 py-2 text-left"
                      >
                        <div className="relative shrink-0">
                          <PlayerAvatar player={player} size={48} />
                          <span className="absolute -right-0.5 -bottom-0.5 rounded bg-brand px-1 py-px text-[10px] font-bold tabular-nums text-white">
                            {player.number}
                          </span>
                        </div>
                        <span className="truncate text-[14px] font-medium text-hb-fg">
                          {playerFullName(player)}
                        </span>
                      </button>
                      <button
                        type="button"
                        className={`flex h-9 w-9 items-center justify-center ${
                          fav.isPlayer(player.id) ? "text-brand" : "text-hb-faint"
                        }`}
                        onClick={() => fav.togglePlayer(player.id)}
                        aria-label="Oblíbený hráč"
                      >
                        ★
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
            {!rosterGroups.length && (
              <EmptyState title="Soupiska není k dispozici" />
            )}
          </div>
        )}

        {tab === "Historie" && (
          <div className="pt-2">
            {seasonHistory.map((record) => (
              <div
                key={record.id}
                className="flex items-start gap-3 border-b border-separator px-4 py-3.5"
              >
                <div className="min-w-0 flex-1">
                  <div className="text-[16px] font-bold text-hb-fg">
                    {record.seasonLabel}
                  </div>
                  <div className="mt-1 text-[12px] font-medium text-hb-muted">
                    {record.competitionName}
                  </div>
                </div>
                {record.standing && (
                  <div className="shrink-0 text-right">
                    <div className="text-[15px] font-bold text-brand">
                      {record.standing.rank}. místo
                    </div>
                    <div className="mt-1 text-[12px] font-medium text-hb-muted">
                      {record.standing.points} b · {record.standing.goalsFor}:
                      {record.standing.goalsAgainst}
                    </div>
                    <div className="mt-1 text-[11px] tabular-nums text-hb-faint">
                      {record.standing.wins}/{record.standing.draws}/
                      {record.standing.losses}
                    </div>
                  </div>
                )}
              </div>
            ))}
            {!seasonHistory.length && (
              <EmptyState
                title="Bez historie"
                hint="Pro tento klub zatím nemáme starší sezóny."
              />
            )}
          </div>
        )}

        {tab === "Zprávy" && (
          <div className="space-y-3 px-4 pt-3">
            {teamNews.map((article) => (
              <button
                key={article.id}
                type="button"
                onClick={() => push({ name: "article", id: article.id })}
                className="hb-card w-full space-y-1.5 p-3.5 text-left"
              >
                <div className="text-[10px] font-bold tracking-[0.3px] text-brand uppercase">
                  {article.category}
                </div>
                <div className="text-[15px] font-semibold leading-snug text-hb-fg">
                  {article.title}
                </div>
                <div className="text-[12px] font-medium text-hb-faint">
                  {formatNewsDate(article.publishedAt)}
                </div>
              </button>
            ))}
            {!teamNews.length && (
              <EmptyState title="Bez zpráv" hint="K tomuto týmu zatím nejsou články." />
            )}
          </div>
        )}
      </div>
    </div>
  );
}

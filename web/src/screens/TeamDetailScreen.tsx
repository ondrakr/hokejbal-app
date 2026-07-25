"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchPlayers, fetchStandings, fetchTeam } from "@/lib/api";
import type { Player, StandingRow, Team } from "@/lib/types";
import { playerFullName, positionLabel } from "@/lib/types";
import { TeamBadge } from "@/components/Badges";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const TABS = ["Zápasy", "Soupiska", "Tabulka"];

export function TeamDetailScreen({ id }: { id: string }) {
  const { matches, competitionById } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const [team, setTeam] = useState<Team | null>(null);
  const [players, setPlayers] = useState<Player[]>([]);
  const [standings, setStandings] = useState<StandingRow[]>([]);
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
          const [pl, st] = await Promise.all([
            fetchPlayers({ teamId: t.id }),
            t.competitionId ? fetchStandings(t.competitionId) : Promise.resolve([]),
          ]);
          if (!cancelled) {
            setPlayers(pl);
            setStandings(st);
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

  if (loading) return <LoadingState />;
  if (!team) return <EmptyState title="Tým nenalezen" />;

  const comp = competitionById(team.competitionId);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title={team.shortName}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className={fav.isTeam(team.id) ? "text-[var(--brand)]" : "text-[var(--text-secondary)]"}
            onClick={() => fav.toggleTeam(team.id)}
          >
            ★
          </button>
        }
      />
      <div className="px-[var(--screen-pad)] py-4">
        <div className="flex items-center gap-3">
          <TeamBadge team={team} size={64} />
          <div>
            <h1 className="font-[family-name:var(--font-display)] text-[22px] font-extrabold">{team.name}</h1>
            <div className="hb-muted">
              {team.city}
              {comp ? ` · ${comp.shortName}` : ""}
            </div>
          </div>
        </div>
      </div>
      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />
      <div className="py-3">
        {tab === "Zápasy" && (
          <div className="pb-1">
            {teamMatches.map((m) => (
              <MatchRow key={m.id} match={m} />
            ))}
            {!teamMatches.length && <EmptyState title="Žádné zápasy" />}
          </div>
        )}
        {tab === "Soupiska" && (
          <div className="space-y-1 px-[var(--screen-pad)]">
            {players.map((p) => (
              <button
                key={`${p.id}-${p.competitionId}`}
                type="button"
                onClick={() => push({ name: "player", id: p.id })}
                className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
              >
                <div>
                  <div className="font-bold">
                    #{p.number} {playerFullName(p)}
                  </div>
                  <div className="hb-muted">{positionLabel(p.position)}</div>
                </div>
                <div className="text-[13px] font-bold">{p.points} b</div>
              </button>
            ))}
            {!players.length && <EmptyState title="Soupiska není k dispozici" />}
          </div>
        )}
        {tab === "Tabulka" && (
          <div className="mx-[var(--screen-pad)] hb-card overflow-hidden">
            {standings.map((row) => (
              <div
                key={row.id}
                className={`flex justify-between border-b border-[var(--separator)] px-4 py-2 text-[13px] ${
                  row.teamId === team.id ? "bg-[var(--brand)]/10 font-bold" : ""
                }`}
              >
                <span>
                  {row.rank}. {row.teamId === team.id ? team.shortName : row.teamId}
                </span>
                <span>{row.points} b</span>
              </div>
            ))}
            {!standings.length && <EmptyState title="Tabulka není k dispozici" />}
          </div>
        )}
      </div>
    </div>
  );
}

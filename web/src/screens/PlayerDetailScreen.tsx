"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchPlayer, fetchPlayerHistory, fetchPlayers } from "@/lib/api";
import type { Player, PlayerSeasonStat } from "@/lib/types";
import { playerFullName, positionLabel } from "@/lib/types";
import { PlayerAvatar } from "@/components/Badges";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const TABS = ["Zápasy", "Sezóny"];

export function PlayerDetailScreen({ id }: { id: string }) {
  const { matches, teamById } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const [player, setPlayer] = useState<Player | null>(null);
  const [history, setHistory] = useState<PlayerSeasonStat[]>([]);
  const [tab, setTab] = useState(TABS[0]);
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

  const team = player ? teamById(player.teamId) : undefined;
  const playerMatches = useMemo(() => {
    if (!player) return [];
    return matches
      .filter((m) => m.homeTeamId === player.teamId || m.awayTeamId === player.teamId)
      .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt))
      .slice(0, 30);
  }, [matches, player]);

  if (loading) return <LoadingState />;
  if (!player) return <EmptyState title="Hráč nenalezen" />;

  const stats = [
    { label: "Z", value: player.games },
    { label: "G", value: player.goals },
    { label: "A", value: player.assists },
    { label: "B", value: player.points },
    { label: "TM", value: player.penaltyMinutes },
  ];

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title={player.lastName}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className={fav.isPlayer(player.id) ? "text-[var(--brand)]" : "text-[var(--text-secondary)]"}
            onClick={() => fav.togglePlayer(player.id)}
          >
            ★
          </button>
        }
      />
      <div className="px-[var(--screen-pad)] py-4">
        <div className="flex items-center gap-3">
          <PlayerAvatar player={player} size={64} />
          <div>
            <h1 className="font-[family-name:var(--font-display)] text-[22px] font-extrabold">
              {playerFullName(player)}
            </h1>
            <button
              type="button"
              className="hb-muted"
              onClick={() => team && push({ name: "team", id: team.id })}
            >
              {positionLabel(player.position)}
              {team ? ` · ${team.name}` : ""}
            </button>
          </div>
        </div>
        <div className="mt-4 grid grid-cols-5 gap-2">
          {stats.map((s) => (
            <div key={s.label} className="hb-card py-2 text-center">
              <div className="font-[family-name:var(--font-display)] text-[18px] font-extrabold">{s.value}</div>
              <div className="text-[10px] font-semibold text-[var(--text-secondary)]">{s.label}</div>
            </div>
          ))}
        </div>
      </div>
      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />
      <div className="py-3">
        {tab === "Zápasy" && (
          <div className="mx-[var(--screen-pad)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--card-stroke)]">
            {playerMatches.map((m) => (
              <MatchRow key={m.id} match={m} />
            ))}
            {!playerMatches.length && <EmptyState title="Žádné zápasy" />}
          </div>
        )}
        {tab === "Sezóny" && (
          <div className="space-y-2 px-[var(--screen-pad)]">
            {history.map((h) => (
              <div key={h.id} className="hb-card px-4 py-3">
                <div className="font-bold">
                  {h.seasonLabel} · {h.competitionName}
                </div>
                <div className="hb-muted mt-1">
                  {h.games} Z · {h.goals}+{h.assists} · {h.points} b · {h.penaltyMinutes} TM
                </div>
              </div>
            ))}
            {!history.length && <EmptyState title="Žádná historie" />}
          </div>
        )}
      </div>
    </div>
  );
}

/** Prefetch helper kept for search parity */
export async function loadPlayersForSearch() {
  return fetchPlayers();
}

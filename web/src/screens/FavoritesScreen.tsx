"use client";

import { useMemo, useState } from "react";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { EmptyState, ScreenHeader } from "@/components/ui";
import { playerFullName } from "@/lib/types";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";
import { fetchPlayers } from "@/lib/api";
import { useEffect } from "react";
import type { Player } from "@/lib/types";

const TABS = ["Zápasy", "Týmy", "Hráči", "Soutěže"];

export function FavoritesScreen() {
  const { matches, teams, competitions } = useCatalog();
  const fav = useFavorites();
  const { push } = useNav();
  const [tab, setTab] = useState(TABS[0]);
  const [players, setPlayers] = useState<Player[]>([]);

  useEffect(() => {
    if (!fav.players.length) {
      setPlayers([]);
      return;
    }
    void fetchPlayers().then((all) => {
      setPlayers(all.filter((p) => fav.players.includes(p.id)));
    });
  }, [fav.players]);

  const favMatches = useMemo(() => {
    return matches.filter(
      (m) =>
        fav.isMatch(m.id) ||
        fav.isTeam(m.homeTeamId) ||
        fav.isTeam(m.awayTeamId) ||
        fav.isCompetition(competitions.find((c) => c.id === m.competitionId)?.slug ?? "")
    );
  }, [matches, fav, competitions]);

  const favTeams = teams.filter((t) => fav.isTeam(t.id));
  const favComps = competitions.filter((c) => fav.isCompetition(c.slug));

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Oblíbené"
        large
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--brand)] text-lg font-bold text-white"
            onClick={() => push({ name: "search" })}
          >
            +
          </button>
        }
      />
      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      {tab === "Zápasy" && (
        <div className="mt-2">
          {favMatches.length ? (
            <div className="pb-2">
              {favMatches.slice(0, 40).map((m) => (
                <MatchRow key={m.id} match={m} />
              ))}
            </div>
          ) : (
            <EmptyState title="Žádné oblíbené zápasy" hint="Přidej tým nebo soutěž přes Hledání." />
          )}
        </div>
      )}

      {tab === "Týmy" && (
        <div className="mt-2 space-y-2 px-[var(--screen-pad)]">
          {favTeams.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => push({ name: "team", id: t.id })}
              className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
            >
              <div>
                <div className="font-bold">{t.name}</div>
                <div className="hb-muted">{t.city}</div>
              </div>
              <button
                type="button"
                className="text-[var(--brand)]"
                onClick={(e) => {
                  e.stopPropagation();
                  fav.toggleTeam(t.id);
                }}
              >
                ★
              </button>
            </button>
          ))}
          {!favTeams.length && <EmptyState title="Žádné oblíbené týmy" />}
        </div>
      )}

      {tab === "Hráči" && (
        <div className="mt-2 space-y-2 px-[var(--screen-pad)]">
          {players.map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() => push({ name: "player", id: p.id })}
              className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
            >
              <div>
                <div className="font-bold">{playerFullName(p)}</div>
                <div className="hb-muted">
                  #{p.number} · {p.points} b
                </div>
              </div>
              <button
                type="button"
                className="text-[var(--brand)]"
                onClick={(e) => {
                  e.stopPropagation();
                  fav.togglePlayer(p.id);
                }}
              >
                ★
              </button>
            </button>
          ))}
          {!players.length && <EmptyState title="Žádní oblíbení hráči" />}
        </div>
      )}

      {tab === "Soutěže" && (
        <div className="mt-2 space-y-2 px-[var(--screen-pad)]">
          {favComps.map((c) => (
            <button
              key={c.id}
              type="button"
              onClick={() => push({ name: "competition", id: c.id })}
              className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
            >
              <div>
                <div className="font-bold">{c.name}</div>
                <div className="hb-muted">{c.season}</div>
              </div>
              <button
                type="button"
                className="text-[var(--brand)]"
                onClick={(e) => {
                  e.stopPropagation();
                  fav.toggleCompetition(c.slug);
                }}
              >
                ★
              </button>
            </button>
          ))}
          {!favComps.length && <EmptyState title="Žádné oblíbené soutěže" />}
        </div>
      )}
    </div>
  );
}

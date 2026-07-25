"use client";

import { useMemo, useState } from "react";
import { CompetitionBadge, TeamBadge } from "@/components/Badges";
import { CompetitionNavStrip, MatchDayStrip } from "@/components/MatchDayStrip";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { SwipeTabPanels } from "@/components/SwipeTabPanels";
import { IconPlusSearch, IconStar } from "@/components/Icons";
import { EmptyState, ScreenHeader } from "@/components/ui";
import { dayKey, todayKey } from "@/lib/format";
import { playerFullName } from "@/lib/types";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const TABS = ["Zápasy", "Týmy", "Hráči", "Soutěže"];

/** Port FavoritesView.swift */
export function FavoritesScreen() {
  const { matches, teams, competitions, players: catalogPlayers, teamById } = useCatalog();
  const fav = useFavorites();
  const { push } = useNav();
  const [tab, setTab] = useState(TABS[0]);
  const [selectedDay, setSelectedDay] = useState(todayKey());

  const players = useMemo(
    () => catalogPlayers.filter((p) => fav.players.includes(p.id)),
    [catalogPlayers, fav.players]
  );

  const favTeams = useMemo(
    () => teams.filter((t) => fav.isTeam(t.id)).sort((a, b) => a.name.localeCompare(b.name, "cs")),
    [teams, fav]
  );

  const favComps = useMemo(
    () => competitions.filter((c) => fav.isCompetition(c.slug)),
    [competitions, fav]
  );

  const hasAnyFavorite =
    fav.teams.length > 0 || fav.players.length > 0 || fav.competitions.length > 0 || fav.matches.length > 0;

  const relevantMatches = useMemo(() => {
    return matches
      .filter(
        (m) =>
          fav.isMatch(m.id) ||
          fav.isTeam(m.homeTeamId) ||
          fav.isTeam(m.awayTeamId) ||
          fav.isCompetition(competitions.find((c) => c.id === m.competitionId)?.slug ?? "")
      )
      .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt));
  }, [matches, fav, competitions]);

  const datesWithMatches = useMemo(
    () => new Set(relevantMatches.map((m) => dayKey(m.scheduledAt))),
    [relevantMatches]
  );

  const dayMatches = useMemo(
    () => relevantMatches.filter((m) => dayKey(m.scheduledAt) === selectedDay),
    [relevantMatches, selectedDay]
  );

  const grouped = useMemo(() => {
    const map = new Map<string, typeof dayMatches>();
    for (const m of dayMatches) {
      const list = map.get(m.competitionId) ?? [];
      list.push(m);
      map.set(m.competitionId, list);
    }
    return [...map.entries()].map(([id, list]) => ({
      competition: competitions.find((c) => c.id === id),
      matches: list,
    }));
  }, [dayMatches, competitions]);

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter bg-surface">
      <ScreenHeader
        title="Oblíbené"
        systemIcon={<IconStar size={14} filled />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-brand"
            onClick={() => push({ name: "search" })}
            aria-label="Přidat přes hledání"
          >
            <IconPlusSearch size={18} />
          </button>
        }
      />
      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      <SwipeTabPanels
        tabs={TABS}
        value={tab}
        onChange={setTab}
        panelClassName="bg-canvas"
      >
        <>
            {!hasAnyFavorite ? (
              <EmptyState
                title="Zatím nic v oblíbených"
                hint="Označte tým, hráče nebo soutěž hvězdičkou. Pak tu uvidíte přehled a zápasy."
                action={
                  <button type="button" className="hb-brand-btn mt-1" onClick={() => push({ name: "search" })}>
                    Hledat a přidat
                  </button>
                }
              />
            ) : relevantMatches.length === 0 ? (
              <EmptyState
                title="Žádné zápasy"
                hint="Pro oblíbené zatím nejsou naplánované zápasy."
              />
            ) : (
              <>
                <MatchDayStrip
                  selectedDay={selectedDay}
                  onSelect={setSelectedDay}
                  datesWithMatches={datesWithMatches}
                />
                {dayMatches.length === 0 ? (
                  <EmptyState title="Bez zápasů" hint="Na tento den nemají oblíbené žádný zápas." />
                ) : (
                  grouped.map(({ competition, matches: list }) => (
                    <section key={competition?.id ?? list[0]?.id} className="mb-1">
                      {competition && (
                        <CompetitionNavStrip
                          title={competition.name}
                          badge={<CompetitionBadge competition={competition} size={18} />}
                          onClick={() =>
                            push({ name: "competition", id: competition.id, day: selectedDay })
                          }
                        />
                      )}
                      {list.map((m) => (
                        <MatchRow key={m.id} match={m} />
                      ))}
                    </section>
                  ))
                )}
              </>
            )}
          </>

        <div className="bg-surface">
            {favTeams.map((t) => (
              <button
                key={t.id}
                type="button"
                onClick={() => push({ name: "team", id: t.id })}
                className="flex w-full items-center gap-3 border-b border-separator/40 px-4 py-3 text-left"
              >
                <TeamBadge team={t} size={40} />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-[15px] font-semibold">{t.name}</div>
                  <div className="text-[12px] font-medium text-hb-muted">{t.city}</div>
                </div>
                <button
                  type="button"
                  className="text-brand"
                  onClick={(e) => {
                    e.stopPropagation();
                    fav.toggleTeam(t.id);
                  }}
                  aria-label="Odebrat"
                >
                  ★
                </button>
              </button>
            ))}
            {!favTeams.length && (
              <EmptyState
                title="Žádné oblíbené týmy"
                hint="Najděte tým ve vyhledávání a klepněte na hvězdičku."
                action={
                  <button type="button" className="hb-brand-btn mt-1" onClick={() => push({ name: "search" })}>
                    Hledat a přidat
                  </button>
                }
              />
            )}
          </div>

        <div className="bg-surface">
            {players.map((p) => (
              <button
                key={p.id}
                type="button"
                onClick={() => push({ name: "player", id: p.id })}
                className="flex w-full items-center gap-3 border-b border-separator/40 px-4 py-3 text-left"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[color-mix(in_srgb,var(--brand)_12%,transparent)] text-[12px] font-bold text-brand">
                  {p.number}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-[15px] font-semibold">{playerFullName(p)}</div>
                  <div className="text-[12px] font-medium text-hb-muted">
                    {teamById(p.teamId)?.shortName ?? ""}
                  </div>
                </div>
                <span className="text-[13px] font-bold tabular-nums text-brand">{p.points} b</span>
                <button
                  type="button"
                  className="text-brand"
                  onClick={(e) => {
                    e.stopPropagation();
                    fav.togglePlayer(p.id);
                  }}
                >
                  ★
                </button>
              </button>
            ))}
            {!players.length && (
              <EmptyState
                title="Žádní oblíbení hráči"
                hint="Najděte hráče ve vyhledávání a klepněte na hvězdičku."
                action={
                  <button type="button" className="hb-brand-btn mt-1" onClick={() => push({ name: "search" })}>
                    Hledat a přidat
                  </button>
                }
              />
            )}
          </div>

        <div className="bg-surface">
            {favComps.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => push({ name: "competition", id: c.id })}
                className="flex w-full items-center gap-3 border-b border-separator/40 px-4 py-3 text-left"
              >
                <CompetitionBadge competition={c} size={36} />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-[15px] font-semibold">{c.name}</div>
                  <div className="text-[12px] font-medium text-hb-muted">{c.season}</div>
                </div>
                <button
                  type="button"
                  className="text-brand"
                  onClick={(e) => {
                    e.stopPropagation();
                    fav.toggleCompetition(c.slug);
                  }}
                >
                  ★
                </button>
              </button>
            ))}
            {!favComps.length && (
              <EmptyState
                title="Žádné oblíbené soutěže"
                hint="Najděte soutěž ve vyhledávání a klepněte na hvězdičku."
                action={
                  <button type="button" className="hb-brand-btn mt-1" onClick={() => push({ name: "search" })}>
                    Hledat a přidat
                  </button>
                }
              />
            )}
          </div>
      </SwipeTabPanels>
    </div>
  );
}

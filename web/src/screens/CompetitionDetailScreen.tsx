"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchStandings } from "@/lib/api";
import type { Match, StandingRow } from "@/lib/types";
import { CompetitionBadge } from "@/components/Badges";
import { CompetitionNavStrip, MatchDayStrip } from "@/components/MatchDayStrip";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { SwipeTabPanels } from "@/components/SwipeTabPanels";
import { StandingsTable } from "@/components/StandingsTable";
import { CompetitionStatsPanel } from "@/screens/CompetitionStatsScreen";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { dayKey, todayKey } from "@/lib/format";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const DETAIL_TABS = ["Program", "Výsledky", "Tabulka", "Statistiky", "Zprávy"];

/** Port CompetitionDetailView + DayMatchesView (id=all) */
export function CompetitionDetailScreen({ id, day }: { id: string; day?: string }) {
  const { competitions, matches, news } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const [tab, setTab] = useState(DETAIL_TABS[0]);
  const [standings, setStandings] = useState<StandingRow[]>([]);
  const [loadingTable, setLoadingTable] = useState(false);
  const [selectedDay, setSelectedDay] = useState(day ?? todayKey());

  const allMode = id === "all";
  const competition = competitions.find((c) => c.id === id);
  const dayMode = allMode || Boolean(day);

  const seasonOptions = useMemo(() => {
    if (!competition) return [];
    return competitions.filter((c) => c.slug === competition.slug);
  }, [competitions, competition]);

  const listAll = useMemo(() => {
    const src = allMode ? matches : matches.filter((m) => m.competitionId === id);
    return [...src].sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt));
  }, [matches, id, allMode]);

  const datesWithMatches = useMemo(
    () => new Set(listAll.map((m) => dayKey(m.scheduledAt))),
    [listAll]
  );

  const dayList = useMemo(() => {
    if (!dayMode) return listAll;
    return listAll.filter((m) => dayKey(m.scheduledAt) === selectedDay);
  }, [listAll, dayMode, selectedDay]);

  const groupedDayList = useMemo(() => {
    if (!allMode) return null;
    const map = new Map<string, Match[]>();
    for (const m of dayList) {
      const list = map.get(m.competitionId) ?? [];
      list.push(m);
      map.set(m.competitionId, list);
    }
    return [...map.entries()].map(([compId, items]) => ({
      competition: competitions.find((c) => c.id === compId),
      matches: items,
    }));
  }, [allMode, dayList, competitions]);

  const upcoming = useMemo(
    () =>
      listAll
        .filter((m) => m.status === "scheduled" || m.status === "live")
        .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt)),
    [listAll]
  );

  const finished = useMemo(
    () =>
      listAll
        .filter((m) => m.status === "finished" || m.status === "postponed")
        .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt)),
    [listAll]
  );

  const competitionNews = useMemo(() => news.slice(0, 12), [news]);

  useEffect(() => {
    if (day) setSelectedDay(day);
  }, [day]);

  useEffect(() => {
    if (allMode || !competition) return;
    setLoadingTable(true);
    void fetchStandings(competition.id)
      .then(setStandings)
      .finally(() => setLoadingTable(false));
  }, [competition, allMode]);

  if (!allMode && !competition) return <EmptyState title="Soutěž nenalezena" />;

  // Day matches mode (from Matches / Favorites calendar)
  if (dayMode) {
    return (
      <div className="flex min-h-0 flex-1 flex-col hb-enter">
        <ScreenHeader
          title={allMode ? "Všechny zápasy" : competition!.name}
          left={<BackButton onClick={pop} />}
          right={
            !allMode ? (
              <button
                type="button"
                className={fav.isCompetition(competition!.slug) ? "text-brand" : "text-hb-faint"}
                onClick={() => fav.toggleCompetition(competition!.slug)}
              >
                ★
              </button>
            ) : undefined
          }
        />
        <MatchDayStrip
          selectedDay={selectedDay}
          onSelect={setSelectedDay}
          datesWithMatches={datesWithMatches}
        />
        {!allMode && competition && (
          <CompetitionNavStrip
            title={competition.name}
            badge={<CompetitionBadge competition={competition} size={18} />}
            onClick={() => push({ name: "competition", id: competition.id })}
          />
        )}
        <div className="hb-scroll min-h-0 flex-1 pb-4">
          {allMode && groupedDayList
            ? groupedDayList.map(({ competition: comp, matches: items }) => (
                <section key={comp?.id ?? items[0]?.id} className="mb-1">
                  {comp && (
                    <CompetitionNavStrip
                      title={comp.name}
                      badge={<CompetitionBadge competition={comp} size={18} />}
                      onClick={() => push({ name: "competition", id: comp.id, day: selectedDay })}
                    />
                  )}
                  {items.map((m) => (
                    <MatchRow key={m.id} match={m} />
                  ))}
                </section>
              ))
            : dayList.map((m) => <MatchRow key={m.id} match={m} />)}
          {!dayList.length && <EmptyState title="Žádné zápasy" hint="Vyber jiný den." />}
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter bg-surface">
      <ScreenHeader
        title={competition!.shortName}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className={fav.isCompetition(competition!.slug) ? "text-brand" : "text-hb-faint"}
            onClick={() => fav.toggleCompetition(competition!.slug)}
          >
            ★
          </button>
        }
      />

      <div className="flex items-center gap-3.5 px-4 pb-3.5 pt-2">
        <CompetitionBadge competition={competition} size={64} />
        <div className="min-w-0 flex-1">
          <h1 className="hb-display text-[22px] leading-tight text-hb-fg">{competition!.name}</h1>
          {seasonOptions.length > 1 ? (
            <select
              className="mt-2 rounded-full bg-secondary-surface px-2.5 py-1.5 text-[14px] font-semibold outline-none"
              value={competition!.id}
              onChange={(e) => push({ name: "competition", id: e.target.value })}
            >
              {seasonOptions.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.season}
                </option>
              ))}
            </select>
          ) : (
            <div className="mt-1 text-[14px] font-semibold text-hb-muted">{competition!.season}</div>
          )}
        </div>
      </div>

      <UnderlineTabs tabs={DETAIL_TABS} value={tab} onChange={setTab} />

      <SwipeTabPanels
        tabs={DETAIL_TABS}
        value={tab}
        onChange={setTab}
        panelClassName="bg-canvas pb-6"
      >
        <div className="pt-1">
          {upcoming.map((m) => (
            <MatchRow key={m.id} match={m} />
          ))}
          {!upcoming.length && <EmptyState title="Žádný program" hint="Nejsou naplánované zápasy." />}
        </div>
        <div className="pt-1">
          {finished.map((m) => (
            <MatchRow key={m.id} match={m} />
          ))}
          {!finished.length && <EmptyState title="Žádné výsledky" />}
        </div>
        <div>
          {loadingTable && <LoadingState />}
          {!loadingTable && (
            <StandingsTable
              rows={standings}
              matches={listAll}
              competitionId={id}
              competitionSlug={competition?.slug}
              emptyMessage="Tabulka pro tuto soutěž není k dispozici."
            />
          )}
        </div>
        <div>
          <CompetitionStatsPanel
            competitionId={id}
            matches={listAll}
            standings={standings}
          />
        </div>
        <div className="space-y-3 px-4 py-3">
          {competitionNews.map((n) => (
            <button
              key={n.id}
              type="button"
              onClick={() => push({ name: "article", id: n.id })}
              className="hb-card w-full overflow-hidden text-left"
            >
              <div
                className="h-28 bg-gradient-to-br from-ink to-brand-dark"
                style={
                  n.photoURL
                    ? {
                        backgroundImage: `url(${n.photoURL})`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                      }
                    : undefined
                }
              />
              <div className="p-3">
                <div className="text-[11px] font-bold text-brand uppercase">{n.category}</div>
                <div className="mt-1 text-[14px] font-bold leading-snug">{n.title}</div>
              </div>
            </button>
          ))}
          {!competitionNews.length && <EmptyState title="Žádné zprávy" />}
        </div>
      </SwipeTabPanels>
    </div>
  );
}

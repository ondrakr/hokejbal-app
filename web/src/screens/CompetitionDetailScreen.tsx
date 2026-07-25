"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchStandings } from "@/lib/api";
import type { StandingRow } from "@/lib/types";
import { MatchRow, UnderlineTabs } from "@/components/MatchRow";
import { BackButton, EmptyState, LoadingState, ScreenHeader } from "@/components/ui";
import { dayKey, todayKey } from "@/lib/format";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

const TABS = ["Zápasy", "Tabulka"];

export function CompetitionDetailScreen({ id }: { id: string }) {
  const { competitions, matches, teamById } = useCatalog();
  const { pop, push } = useNav();
  const fav = useFavorites();
  const [tab, setTab] = useState(TABS[0]);
  const [standings, setStandings] = useState<StandingRow[]>([]);
  const [loadingTable, setLoadingTable] = useState(false);

  const allMode = id === "all";
  const competition = competitions.find((c) => c.id === id);

  const list = useMemo(() => {
    const src = allMode ? matches : matches.filter((m) => m.competitionId === id);
    const today = todayKey();
    return [...src].sort((a, b) => {
      const ad = dayKey(a.scheduledAt) === today ? 0 : 1;
      const bd = dayKey(b.scheduledAt) === today ? 0 : 1;
      return ad - bd || a.scheduledAt.localeCompare(b.scheduledAt);
    });
  }, [matches, id, allMode]);

  useEffect(() => {
    if (allMode || !competition) return;
    setLoadingTable(true);
    void fetchStandings(competition.id)
      .then(setStandings)
      .finally(() => setLoadingTable(false));
  }, [competition, allMode]);

  if (!allMode && !competition) return <EmptyState title="Soutěž nenalezena" />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title={allMode ? "Všechny zápasy" : competition!.name}
        subtitle={allMode ? undefined : competition!.season}
        left={<BackButton onClick={pop} />}
        right={
          !allMode ? (
            <button
              type="button"
              className={
                fav.isCompetition(competition!.slug) ? "text-[var(--brand)]" : "text-[var(--text-secondary)]"
              }
              onClick={() => fav.toggleCompetition(competition!.slug)}
            >
              ★
            </button>
          ) : undefined
        }
      />
      {!allMode && <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />}
      <div className="py-3">
        {(allMode || tab === "Zápasy") && (
          <div className="pb-1">
            {list.slice(0, 80).map((m) => (
              <MatchRow key={m.id} match={m} />
            ))}
            {!list.length && <EmptyState title="Žádné zápasy" />}
          </div>
        )}
        {!allMode && tab === "Tabulka" && (
          <div className="mx-[var(--screen-pad)]">
            {loadingTable && <LoadingState />}
            {!loadingTable && (
              <div className="hb-card overflow-hidden">
                {standings.map((row) => {
                  const t = teamById(row.teamId);
                  return (
                    <button
                      key={row.id}
                      type="button"
                      onClick={() => push({ name: "team", id: row.teamId })}
                      className="flex w-full items-center justify-between border-b border-[var(--separator)] px-4 py-2.5 text-left text-[13px]"
                    >
                      <span>
                        <span className="mr-2 font-semibold text-[var(--text-secondary)]">{row.rank}.</span>
                        {t?.name ?? row.teamId}
                      </span>
                      <span className="font-bold">{row.points}</span>
                    </button>
                  );
                })}
                {!standings.length && <EmptyState title="Tabulka není k dispozici" />}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

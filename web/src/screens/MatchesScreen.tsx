"use client";

import { useEffect, useMemo, useState } from "react";
import { CompetitionBadge } from "@/components/Badges";
import { MatchDayStrip } from "@/components/MatchDayStrip";
import { IconChevronRight, IconCourt, IconSearch, IconStack } from "@/components/Icons";
import { EmptyState, LoadingState, ScreenHeader, SectionHeader } from "@/components/ui";
import { dayKey, todayKey } from "@/lib/format";
import type { Competition } from "@/lib/types";
import { useCatalog } from "@/stores/catalog";
import { useCompetitionOrder } from "@/stores/competitionOrder";
import { useFavorites } from "@/stores/favorites";
import { useNav } from "@/stores/navigation";

/** Port MatchesByCompetitionView */
export function MatchesScreen() {
  const { matches, competitions, loading } = useCatalog();
  const fav = useFavorites();
  const order = useCompetitionOrder();
  const { push } = useNav();
  const [selectedDay, setSelectedDay] = useState(todayKey());

  useEffect(() => {
    order.sync(competitions);
  }, [competitions, order]);

  const datesWithMatches = useMemo(() => new Set(matches.map((m) => dayKey(m.scheduledAt))), [matches]);

  const dayMatches = useMemo(
    () => matches.filter((m) => dayKey(m.scheduledAt) === selectedDay),
    [matches, selectedDay]
  );

  const compsToday = useMemo(() => {
    const ids = new Set(dayMatches.map((m) => m.competitionId));
    return order.sortedCompetitions(competitions.filter((c) => ids.has(c.id)));
  }, [dayMatches, competitions, order]);

  const favoriteComps = compsToday.filter((c) => fav.isCompetition(c.slug));
  const otherComps = compsToday.filter((c) => !fav.isCompetition(c.slug));

  if (loading) return <LoadingState label="Načítám zápasy…" />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Zápasy"
        systemIcon={<IconCourt size={14} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-hb-fg"
            onClick={() => push({ name: "search" })}
            aria-label="Hledat"
          >
            <IconSearch size={16} />
          </button>
        }
      />

      <MatchDayStrip
        selectedDay={selectedDay}
        onSelect={setSelectedDay}
        datesWithMatches={datesWithMatches}
      />

      <div className="pb-6 pt-2">
        <CompetitionCard
          title="Všechny zápasy"
          count={dayMatches.length}
          brandIcon
          onClick={() => push({ name: "competition", id: "all", day: selectedDay })}
        />

        {favoriteComps.length > 0 && (
          <div className="mt-2">
            <SectionHeader title="Oblíbené soutěže" accent="#d9a626" />
            {favoriteComps.map((c) => (
              <CompetitionCard
                key={c.id}
                competition={c}
                count={dayMatches.filter((m) => m.competitionId === c.id).length}
                onClick={() => push({ name: "competition", id: c.id, day: selectedDay })}
              />
            ))}
          </div>
        )}

        {otherComps.length > 0 && (
          <div className="mt-1">
            {otherComps.map((c) => (
              <CompetitionCard
                key={c.id}
                competition={c}
                count={dayMatches.filter((m) => m.competitionId === c.id).length}
                onClick={() => push({ name: "competition", id: c.id, day: selectedDay })}
              />
            ))}
          </div>
        )}

        {!dayMatches.length && (
          <EmptyState title="Žádné zápasy tento den" hint="Vyber jiný den ve stripu nahoře." />
        )}
      </div>
    </div>
  );
}

function CompetitionCard({
  title,
  competition,
  count,
  brandIcon,
  onClick,
}: {
  title?: string;
  competition?: Competition;
  count: number;
  brandIcon?: boolean;
  onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick} className="block w-full px-4 py-[5px] text-left">
      <div className="hb-card flex items-center gap-3 px-3.5 py-[13px]">
        {brandIcon ? (
          <div className="hb-tint-12-brand flex h-[34px] w-[34px] items-center justify-center rounded-[9px]">
            <IconStack size={15} />
          </div>
        ) : (
          <CompetitionBadge competition={competition} size={30} />
        )}
        <span className={`min-w-0 flex-1 text-[15px] ${brandIcon ? "font-bold" : "font-semibold"}`}>
          {title ?? competition?.name}
        </span>
        {brandIcon && count > 0 ? (
          <span className="rounded-full bg-brand px-2 py-[3px] text-[12px] font-bold text-white">{count}</span>
        ) : (
          <span className="hb-number min-w-[22px] text-right text-[14px] font-semibold text-hb-muted">{count}</span>
        )}
        <span className="text-hb-faint">
          <IconChevronRight size={12} />
        </span>
      </div>
    </button>
  );
}

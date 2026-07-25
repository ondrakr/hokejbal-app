"use client";

import { useState } from "react";
import { AmateurBadge } from "@/components/amateur/AmateurBadge";
import { AmateurMatchRow } from "@/components/amateur/AmateurMatchRow";
import { IconChevronRight, IconGear } from "@/components/Icons";
import { UnderlineTabs } from "@/components/MatchRow";
import { SwipeTabPanels } from "@/components/SwipeTabPanels";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  dateRangeLabel,
  statusLabel,
  useAmateur,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

const TABS = ["Program", "Výsledky", "Tabulka", "Týmy"];

export function AmateurDetail({ tournamentId }: { tournamentId: string }) {
  const { pop, push } = useNav();
  const { tournament, matchesIn, teamsIn, playersInTeam, standings, team } = useAmateur();
  const [tab, setTab] = useState("Program");
  const t = tournament(tournamentId);

  if (!t) {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Turnaj" left={<BackButton onClick={pop} />} />
        <EmptyState title="Turnaj nenalezen" hint="Turnaj byl smazán nebo neexistuje." />
      </div>
    );
  }

  const matches = matchesIn(tournamentId);
  const program = matches.filter((m) => m.status !== "finished");
  const results = [...matches.filter((m) => m.status === "finished")].reverse();
  const table = standings(tournamentId);
  const teams = teamsIn(tournamentId);

  return (
    <div className="hb-enter flex min-h-0 flex-1 flex-col">
      <ScreenHeader
        title={t.name}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-hb-fg"
            aria-label="Spravovat turnaj"
            onClick={() => push({ name: "amateur", screen: "admin", id: tournamentId })}
          >
            <IconGear size={16} />
          </button>
        }
      />

      <div className="border-b border-card-stroke bg-surface px-[var(--screen-pad)] py-3">
        <div className="flex items-center justify-between gap-2">
          <span className="text-[11px] font-bold text-brand">{statusLabel(t.status)}</span>
          <span className="text-[12px] font-semibold text-hb-muted">{dateRangeLabel(t)}</span>
        </div>
        {t.location ? (
          <div className="mt-2 text-[14px] font-medium text-hb-muted">{t.location}</div>
        ) : null}
        {t.notes ? (
          <div className="mt-1 text-[13px] font-medium text-hb-faint">{t.notes}</div>
        ) : null}
      </div>

      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      <SwipeTabPanels
        tabs={TABS}
        value={tab}
        onChange={setTab}
        panelClassName="pb-8"
      >
        program.length ? (
            <div className="space-y-2 px-[var(--screen-pad)] pt-3">
              {program.map((m) => (
                <AmateurMatchRow
                  key={m.id}
                  match={m}
                  onClick={() =>
                    push({
                      name: "amateur",
                      screen: "match",
                      id: tournamentId,
                      matchId: m.id,
                    })
                  }
                />
              ))}
            </div>
          ) : (
            <EmptyState
              title="Žádné zápasy"
              hint="V adminu přidej program turnaje."
            />
          )

        results.length ? (
            <div className="space-y-2 px-[var(--screen-pad)] pt-3">
              {results.map((m) => (
                <AmateurMatchRow
                  key={m.id}
                  match={m}
                  onClick={() =>
                    push({
                      name: "amateur",
                      screen: "match",
                      id: tournamentId,
                      matchId: m.id,
                    })
                  }
                />
              ))}
            </div>
          ) : (
            <EmptyState
              title="Žádné zápasy"
              hint="V adminu přidej program turnaje."
            />
          )

        table.length ? (
            <div className="pt-2">
              <div className="flex px-[var(--screen-pad)] py-2 text-[11px] font-bold text-hb-faint">
                <span className="w-7">#</span>
                <span className="flex-1">Tým</span>
                <span className="w-7 text-center">Z</span>
                <span className="w-7 text-center">V</span>
                <span className="w-7 text-center">P</span>
                <span className="w-11 text-center">SK</span>
                <span className="w-7 text-center">B</span>
              </div>
              {table.map((row, index) => {
                const tm = team(row.teamId);
                return (
                  <div
                    key={row.teamId}
                    className={`flex items-center px-[var(--screen-pad)] py-2.5 text-[13px] font-semibold text-hb-fg ${
                      index % 2 === 0 ? "bg-card-inset/35" : ""
                    }`}
                  >
                    <span className="w-7">{index + 1}</span>
                    <span className="flex-1 truncate">{tm?.shortName ?? "?"}</span>
                    <span className="w-7 text-center">{row.played}</span>
                    <span className="w-7 text-center">{row.wins}</span>
                    <span className="w-7 text-center">{row.losses}</span>
                    <span className="w-11 text-center">
                      {row.goalsFor}:{row.goalsAgainst}
                    </span>
                    <span className="w-7 text-center">{row.points}</span>
                  </div>
                );
              })}
            </div>
          ) : (
            <EmptyState
              title="Bez tabulky"
              hint="Tabulka se naplní po odehraných zápasech."
            />
          )

        teams.length ? (
            <div className="space-y-2 px-[var(--screen-pad)] pt-3">
              {teams.map((tm) => (
                <button
                  key={tm.id}
                  type="button"
                  className="hb-card flex w-full items-center gap-3 p-3 text-left"
                  onClick={() =>
                    push({
                      name: "amateur",
                      screen: "team",
                      id: tournamentId,
                      teamId: tm.id,
                    })
                  }
                >
                  <AmateurBadge team={tm} size={40} />
                  <div className="min-w-0 flex-1">
                    <div className="text-[15px] font-bold text-hb-fg">{tm.name}</div>
                    <div className="text-[12px] font-medium text-hb-muted">
                      {playersInTeam(tm.id).length} hráčů
                    </div>
                  </div>
                  <IconChevronRight size={12} />
                </button>
              ))}
            </div>
          ) : (
            <EmptyState title="Bez týmů" hint="V adminu přidej týmy a soupisky." />
          )
      </SwipeTabPanels>
    </div>
  );
}

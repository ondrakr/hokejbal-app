"use client";

import { IconCourt, IconFlagCheckered, IconGear } from "@/components/Icons";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  dateRangeLabel,
  formatLabel,
  statusLabel,
  useAmateur,
  type AmateurTournament,
  type AmateurTournamentStatus,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

function statusChipColor(status: AmateurTournamentStatus) {
  switch (status) {
    case "draft":
      return "bg-hb-faint";
    case "active":
      return "bg-brand";
    case "finished":
      return "bg-ink-soft";
  }
}

function TournamentCard({
  tournament,
  onClick,
}: {
  tournament: AmateurTournament;
  onClick: () => void;
}) {
  const { teamsIn, matchesIn } = useAmateur();
  const teamCount = teamsIn(tournament.id).length;
  const matchCount = matchesIn(tournament.id).length;

  return (
    <button type="button" onClick={onClick} className="hb-card w-full p-3.5 text-left">
      <div className="flex items-start gap-2">
        <div className="min-w-0 flex-1">
          <div className="text-[17px] font-bold leading-snug text-hb-fg">{tournament.name}</div>
          {tournament.location ? (
            <div className="mt-1 flex items-center gap-1 text-[12px] font-medium text-hb-muted">
              <svg width={12} height={12} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                <path d="M12 2a7 7 0 0 0-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z" />
              </svg>
              {tournament.location}
            </div>
          ) : null}
        </div>
        <span
          className={`shrink-0 rounded-full px-2 py-1 text-[10px] font-bold text-on-brand uppercase ${statusChipColor(tournament.status)}`}
        >
          {statusLabel(tournament.status)}
        </span>
      </div>
      <div className="mt-2.5 flex flex-wrap gap-3 text-[11px] font-semibold text-hb-faint">
        <span className="inline-flex items-center gap-1">
          <IconFlagCheckered size={10} />
          {formatLabel(tournament.format)}
        </span>
        <span className="inline-flex items-center gap-1">
          <svg width={10} height={10} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
            <path d="M9 11a4 4 0 1 0-4-4 4 4 0 0 0 4 4zm6 0a4 4 0 1 0-4-4 4 4 0 0 0 4 4zM9 13c-3.3 0-6 1.8-6 4v1h12v-1c0-2.2-2.7-4-6-4zm6 0c-.4 0-.8 0-1.2.1 1.4.9 2.2 2.1 2.2 3.9V18h6v-1c0-2.2-2.7-4-7-4z" />
          </svg>
          {teamCount} týmů
        </span>
        <span className="inline-flex items-center gap-1">
          <IconCourt size={10} />
          {matchCount} zápasů
        </span>
      </div>
      <div className="mt-1 text-[11px] font-medium text-hb-faint">{dateRangeLabel(tournament)}</div>
    </button>
  );
}

export function AmateurHub() {
  const { pop, push } = useNav();
  const { tournaments } = useAmateur();

  return (
    <div className="hb-enter flex min-h-0 flex-1 flex-col">
      <ScreenHeader
        title="Amatérské turnaje"
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-hb-fg"
            aria-label="Správa turnajů"
            onClick={() => push({ name: "amateur", screen: "adminHub" })}
          >
            <IconGear size={16} />
          </button>
        }
      />
      <div className="border-b border-card-stroke bg-surface px-[var(--screen-pad)] py-2 text-[12px] font-medium text-hb-muted">
        Lokální demo — turnaje zůstávají jen na tomto zařízení.
      </div>
      <div className="hb-scroll min-h-0 flex-1">
        {tournaments.length ? (
          <div className="flex flex-col gap-2.5 px-[var(--screen-pad)] pt-3 pb-6">
            {tournaments.map((t) => (
              <TournamentCard
                key={t.id}
                tournament={t}
                onClick={() => push({ name: "amateur", screen: "detail", id: t.id })}
              />
            ))}
          </div>
        ) : (
          <EmptyState
            title="Zatím žádné turnaje"
            hint="V adminu (ikona nastavení) můžeš vytvořit první amatérský turnaj."
          />
        )}
      </div>
    </div>
  );
}

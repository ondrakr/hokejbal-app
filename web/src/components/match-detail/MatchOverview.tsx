"use client";

import type { Match, Team } from "@/lib/types";
import type { TeamFormItem } from "@/lib/teamForm";
import { teamFormColor, teamFormLetter } from "@/lib/teamForm";
import { formatMatchTime, formatShortDate } from "@/lib/format";
import { TeamBadge } from "@/components/Badges";
import { MatchTipCard } from "./MatchTipCard";

function phaseLabel(phase: Match["phase"]): string {
  if (phase === "playoffs") return "Play-off";
  return "Základní část";
}

function PreviewRow({ title, value }: { title: string; value: string }) {
  return (
    <div className="flex items-center gap-2 rounded-[12px] bg-card-inset px-3 py-2.5">
      <span className="shrink-0 text-[13px] font-semibold text-hb-muted">{title}</span>
      <span className="min-w-0 flex-1 text-right text-[14px] font-bold text-hb-fg">{value}</span>
    </div>
  );
}

function FormBadges({ items }: { items: TeamFormItem[] }) {
  if (!items.length) {
    return <span className="text-[12px] font-semibold text-hb-faint">—</span>;
  }
  return (
    <div className="flex gap-1">
      {items.map((item) => (
        <span
          key={item.id}
          className="flex h-[22px] w-[22px] items-center justify-center rounded text-[10px] font-bold text-white"
          style={{ background: teamFormColor(item.outcome) }}
        >
          {teamFormLetter(item.outcome)}
        </span>
      ))}
    </div>
  );
}

function TeamFormRow({ team, items }: { team?: Team; items: TeamFormItem[] }) {
  return (
    <div className="flex items-center gap-2.5">
      {team ? (
        <>
          <TeamBadge team={team} size={26} />
          <span className="min-w-0 flex-1 truncate text-[14px] font-semibold text-hb-fg">
            {team.shortName}
          </span>
        </>
      ) : (
        <span className="flex-1 text-[14px] font-medium text-hb-muted">—</span>
      )}
      <FormBadges items={items} />
    </div>
  );
}

function MatchFormPreview({
  home,
  away,
  homeForm,
  awayForm,
}: {
  home?: Team;
  away?: Team;
  homeForm: TeamFormItem[];
  awayForm: TeamFormItem[];
}) {
  return (
    <div className="space-y-2.5">
      <div className="text-[11px] font-bold tracking-[0.6px] text-hb-faint">FORMA</div>
      <div className="space-y-2.5 rounded-[12px] bg-card-inset p-3">
        <TeamFormRow team={home} items={homeForm} />
        <TeamFormRow team={away} items={awayForm} />
      </div>
    </div>
  );
}

export function MatchOverview({
  match,
  home,
  away,
  homeForm,
  awayForm,
}: {
  match: Match;
  home?: Team;
  away?: Team;
  homeForm: TeamFormItem[];
  awayForm: TeamFormItem[];
}) {
  return (
    <div className="space-y-4">
      <div className="px-3">
        <MatchTipCard match={match} home={home} away={away} />
      </div>

      <div className="space-y-3 px-3.5">
        <PreviewRow
          title="Začátek"
          value={`${formatShortDate(match.scheduledAt)} · ${formatMatchTime(match.scheduledAt)}`}
        />
        {match.venue ? <PreviewRow title="Místo" value={match.venue} /> : null}
        {match.round > 0 ? <PreviewRow title="Kolo" value={`${match.round}. kolo`} /> : null}
        {match.phase ? <PreviewRow title="Fáze" value={phaseLabel(match.phase)} /> : null}

        <div className="pt-1">
          <MatchFormPreview
            home={home}
            away={away}
            homeForm={homeForm}
            awayForm={awayForm}
          />
        </div>

        <PreviewRow
          title="Rozhodčí"
          value={match.referees && match.referees.length > 0 ? match.referees : "—"}
        />
      </div>
    </div>
  );
}

"use client";

import { AmateurBadge } from "@/components/amateur/AmateurBadge";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import { playerFullName, useAmateur } from "@/stores/amateur";
import { positionLabel } from "@/lib/types";
import { useNav } from "@/stores/navigation";

export function AmateurTeamDetail({ teamId }: { teamId: string }) {
  const { pop } = useNav();
  const { team, playersInTeam } = useAmateur();
  const t = team(teamId);

  if (!t) {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Tým" left={<BackButton onClick={pop} />} />
        <EmptyState title="Tým nenalezen" />
      </div>
    );
  }

  const roster = playersInTeam(t.id);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title={t.shortName} left={<BackButton onClick={pop} />} />
      <div className="px-[var(--screen-pad)] py-4 pb-8">
        <div className="hb-card mb-4 flex items-center gap-3 p-4">
          <AmateurBadge team={t} size={56} />
          <div>
            <div className="text-[18px] font-bold text-hb-fg">{t.name}</div>
            {t.city ? (
              <div className="mt-1 text-[13px] font-medium text-hb-muted">{t.city}</div>
            ) : null}
          </div>
        </div>

        <div className="mb-2 text-[12px] font-bold tracking-[0.4px] text-hb-faint">Soupiska</div>
        {roster.length === 0 ? (
          <p className="text-[13px] font-medium text-hb-muted">Soupiska je prázdná.</p>
        ) : (
          <div className="space-y-1">
            {roster.map((p) => (
              <div key={p.id} className="hb-card flex items-center gap-3 px-3 py-2.5">
                <span className="hb-number w-7 text-[14px] font-bold text-brand">{p.number}</span>
                <div>
                  <div className="text-[14px] font-semibold text-hb-fg">{playerFullName(p)}</div>
                  <div className="text-[11px] font-medium capitalize text-hb-faint">
                    {positionLabel(p.position)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

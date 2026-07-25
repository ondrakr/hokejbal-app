"use client";

import { IconChevronRight } from "@/components/Icons";
import { BackButton, ScreenHeader } from "@/components/ui";
import { dateRangeLabel, formatLabel, statusLabel, useAmateur } from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

export function AmateurAdminHub() {
  const { pop, push } = useNav();
  const { tournaments, deleteTournament } = useAmateur();

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Správa turnajů"
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-[22px] font-bold text-hb-fg"
            aria-label="Nový turnaj"
            onClick={() => push({ name: "amateur", screen: "create" })}
          >
            +
          </button>
        }
      />
      <div className="px-[var(--screen-pad)] py-4 pb-8">
        <p className="mb-3.5 text-[13px] font-medium text-hb-muted">
          Lokální správa na tomto zařízení. Účty a práva doplníme později.
        </p>

        <button
          type="button"
          className="hb-brand-btn mb-4 w-full"
          onClick={() => push({ name: "amateur", screen: "create" })}
        >
          Nový turnaj
        </button>

        <div className="mb-2 text-[11px] font-bold tracking-[0.5px] text-hb-faint">TURNAJE</div>

        {tournaments.length === 0 ? (
          <div className="hb-card p-4 text-[14px] font-medium text-hb-faint">
            Zatím žádný turnaj — vytvoř první průvodcem.
          </div>
        ) : (
          <div className="space-y-2.5">
            {tournaments.map((t) => (
              <div key={t.id} className="hb-card flex items-center gap-3 p-3.5">
                <button
                  type="button"
                  className="min-w-0 flex-1 text-left"
                  onClick={() => push({ name: "amateur", screen: "admin", id: t.id })}
                >
                  <div className="text-[16px] font-bold text-hb-fg">{t.name}</div>
                  <div className="mt-1 text-[12px] font-medium text-hb-muted">
                    {statusLabel(t.status)} · {dateRangeLabel(t)}
                  </div>
                  <div className="mt-0.5 text-[11px] font-semibold text-brand">
                    {formatLabel(t.format)}
                  </div>
                </button>
                <button
                  type="button"
                  className="shrink-0 rounded-lg bg-loss/10 px-2.5 py-2 text-[11px] font-bold text-loss"
                  onClick={() => {
                    if (confirm(`Smazat turnaj „${t.name}"?`)) deleteTournament(t.id);
                  }}
                >
                  Smazat
                </button>
                <span className="shrink-0 text-hb-faint">
                  <IconChevronRight size={12} />
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

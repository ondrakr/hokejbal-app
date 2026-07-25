"use client";

import { useState } from "react";
import { AmateurBadge } from "@/components/amateur/AmateurBadge";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import { playerFullName, useAmateur, type AmateurTeam } from "@/stores/amateur";
import { positionLabel, type PlayerPosition } from "@/lib/types";
import { useNav } from "@/stores/navigation";

function fieldClass() {
  return "mt-1 w-full rounded-[12px] border border-card-stroke bg-card px-3 py-2.5 text-[15px] text-hb-fg outline-none";
}

function ModalShell({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 sm:items-center sm:p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl bg-canvas sm:rounded-2xl">
        <div className="sticky top-0 flex items-center justify-between border-b border-separator bg-canvas px-4 py-3">
          <button type="button" className="text-[15px] font-semibold text-hb-muted" onClick={onClose}>
            Zrušit
          </button>
          <div className="text-[16px] font-bold text-hb-fg">{title}</div>
          <div className="w-12" />
        </div>
        <div className="p-4 pb-8">{children}</div>
      </div>
    </div>
  );
}

function EditTeamModal({ team, onClose }: { team: AmateurTeam; onClose: () => void }) {
  const { updateTeam } = useAmateur();
  const [draft, setDraft] = useState(team);

  return (
    <ModalShell title="Upravit tým" onClose={onClose}>
      <div className="space-y-3">
        <label className="block text-[12px] font-semibold text-hb-muted">
          Název
          <input
            value={draft.name}
            onChange={(e) => setDraft({ ...draft, name: e.target.value })}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Zkratka
          <input
            value={draft.shortName}
            onChange={(e) => setDraft({ ...draft, shortName: e.target.value })}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Město
          <input
            value={draft.city}
            onChange={(e) => setDraft({ ...draft, city: e.target.value })}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Iniciály
          <input
            value={draft.logoInitials}
            onChange={(e) => setDraft({ ...draft, logoInitials: e.target.value })}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Barva (HEX)
          <input
            value={draft.primaryColorHex}
            onChange={(e) => setDraft({ ...draft, primaryColorHex: e.target.value })}
            className={fieldClass()}
          />
        </label>
        <button
          type="button"
          className="hb-brand-btn w-full"
          onClick={() => {
            updateTeam(draft);
            onClose();
          }}
        >
          Uložit
        </button>
      </div>
    </ModalShell>
  );
}

function AddPlayerModal({ teamId, onClose }: { teamId: string; onClose: () => void }) {
  const { addPlayer } = useAmateur();
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [number, setNumber] = useState(10);
  const [position, setPosition] = useState<PlayerPosition>("forward");

  return (
    <ModalShell title="Nový hráč" onClose={onClose}>
      <div className="space-y-3">
        <label className="block text-[12px] font-semibold text-hb-muted">
          Jméno
          <input
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Příjmení
          <input
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Číslo {number}
          <input
            type="range"
            min={1}
            max={99}
            value={number}
            onChange={(e) => setNumber(Number(e.target.value))}
            className="mt-2 w-full"
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Pozice
          <select
            value={position}
            onChange={(e) => setPosition(e.target.value as PlayerPosition)}
            className={fieldClass()}
          >
            <option value="forward">Útočník</option>
            <option value="defenseman">Obránce</option>
            <option value="goalie">Brankář</option>
          </select>
        </label>
        <button
          type="button"
          className="hb-brand-btn w-full disabled:opacity-40"
          disabled={!firstName.trim() || !lastName.trim()}
          onClick={() => {
            addPlayer(teamId, firstName, lastName, number, position);
            onClose();
          }}
        >
          Přidat
        </button>
      </div>
    </ModalShell>
  );
}

export function AmateurAdminTeam({ teamId }: { teamId: string }) {
  const { pop } = useNav();
  const { team, playersInTeam, deleteTeam, deletePlayer } = useAmateur();
  const [showAddPlayer, setShowAddPlayer] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
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
        <div className="hb-card mb-3 flex items-center gap-3 p-4">
          <AmateurBadge team={t} size={48} />
          <div>
            <div className="text-[16px] font-bold text-hb-fg">{t.name}</div>
            <div className="text-[13px] text-hb-muted">{t.city || "—"}</div>
          </div>
        </div>

        <button
          type="button"
          className="mb-2 w-full rounded-[12px] bg-card px-4 py-3 text-left text-[14px] font-semibold text-brand"
          onClick={() => setShowEdit(true)}
        >
          Upravit tým
        </button>
        <button
          type="button"
          className="mb-4 w-full rounded-[12px] bg-loss/10 px-4 py-3 text-left text-[14px] font-semibold text-loss"
          onClick={() => {
            if (confirm(`Smazat tým „${t.name}"?`)) {
              deleteTeam(t.id);
              pop();
            }
          }}
        >
          Smazat tým
        </button>

        <div className="mb-2 text-[12px] font-bold tracking-[0.4px] text-hb-faint">Soupiska</div>
        <div className="space-y-1.5">
          {roster.map((p) => (
            <div key={p.id} className="hb-card flex items-center gap-3 px-3 py-2.5">
              <span className="hb-number w-9 text-[13px] font-bold text-brand">#{p.number}</span>
              <div className="min-w-0 flex-1">
                <div className="text-[14px] font-semibold text-hb-fg">{playerFullName(p)}</div>
                <div className="text-[11px] font-medium capitalize text-hb-faint">
                  {positionLabel(p.position)}
                </div>
              </div>
              <button
                type="button"
                className="rounded-lg bg-loss/10 px-2 py-1.5 text-[11px] font-bold text-loss"
                onClick={() => deletePlayer(p.id)}
              >
                Smazat
              </button>
            </div>
          ))}
        </div>

        <button
          type="button"
          className="hb-brand-btn mt-3 w-full"
          onClick={() => setShowAddPlayer(true)}
        >
          Přidat hráče
        </button>
      </div>

      {showAddPlayer && <AddPlayerModal teamId={teamId} onClose={() => setShowAddPlayer(false)} />}
      {showEdit && <EditTeamModal team={t} onClose={() => setShowEdit(false)} />}
    </div>
  );
}

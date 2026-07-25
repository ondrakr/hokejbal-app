"use client";

import { useState } from "react";
import { AmateurBadge } from "@/components/amateur/AmateurBadge";
import { AmateurMatchRow } from "@/components/amateur/AmateurMatchRow";
import { IconChevronRight, IconSliders } from "@/components/Icons";
import { UnderlineTabs } from "@/components/MatchRow";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  dateRangeLabel,
  formatHasPlayoff,
  formatLabel,
  formatUsesSeries,
  matchFormatLabel,
  statusLabel,
  useAmateur,
  type AmateurTournament,
  type AmateurTournamentFormat,
  type AmateurTournamentStatus,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

const TABS = ["Přehled", "Týmy", "Zápasy"];
const COLORS = ["C92A2A", "1B4F9C", "0B3D91", "2E7D32", "111111", "D4A017", "E65100", "6A1B9A"];

function AdminStat({ title, value }: { title: string; value: string }) {
  return (
    <div className="hb-card flex items-center justify-between p-3">
      <span className="text-[13px] font-medium text-hb-muted">{title}</span>
      <span className="text-[14px] font-bold text-hb-fg">{value}</span>
    </div>
  );
}

function AdminAction({ title, onClick, disabled }: { title: string; onClick: () => void; disabled?: boolean }) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="hb-card flex w-full items-center gap-3 p-3.5 text-left disabled:opacity-40"
    >
      <span className="flex-1 text-[14px] font-semibold text-hb-fg">{title}</span>
      <IconChevronRight size={12} />
    </button>
  );
}

function Modal({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-0 sm:items-center sm:p-4">
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

function fieldClass() {
  return "mt-1 w-full rounded-[12px] border border-card-stroke bg-card px-3 py-2.5 text-[15px] text-hb-fg outline-none";
}

function AddTeamModal({ tournamentId, onClose }: { tournamentId: string; onClose: () => void }) {
  const { addTeam } = useAmateur();
  const [name, setName] = useState("");
  const [shortName, setShortName] = useState("");
  const [city, setCity] = useState("");
  const [colorHex, setColorHex] = useState("C92A2A");

  return (
    <Modal title="Nový tým" onClose={onClose}>
      <div className="space-y-3">
        <label className="block text-[12px] font-semibold text-hb-muted">
          Název
          <input value={name} onChange={(e) => setName(e.target.value)} className={fieldClass()} />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Zkratka
          <input value={shortName} onChange={(e) => setShortName(e.target.value)} className={fieldClass()} />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Město
          <input value={city} onChange={(e) => setCity(e.target.value)} className={fieldClass()} />
        </label>
        <div>
          <div className="mb-2 text-[12px] font-semibold text-hb-muted">Barva</div>
          <div className="grid grid-cols-4 gap-2.5">
            {COLORS.map((hex) => (
              <button
                key={hex}
                type="button"
                onClick={() => setColorHex(hex)}
                className={`h-9 rounded-full ${colorHex === hex ? "ring-2 ring-brand ring-offset-2" : ""}`}
                style={{ backgroundColor: `#${hex}` }}
              />
            ))}
          </div>
        </div>
        <button
          type="button"
          className="hb-brand-btn mt-2 w-full disabled:opacity-40"
          disabled={!name.trim()}
          onClick={() => {
            addTeam(tournamentId, name, shortName, city, colorHex);
            onClose();
          }}
        >
          Přidat
        </button>
      </div>
    </Modal>
  );
}

function AddMatchModal({ tournamentId, onClose }: { tournamentId: string; onClose: () => void }) {
  const { addMatch, teamsIn } = useAmateur();
  const teams = teamsIn(tournamentId);
  const [homeId, setHomeId] = useState(teams[0]?.id ?? "");
  const [awayId, setAwayId] = useState(teams[1]?.id ?? "");
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 16));
  const [round, setRound] = useState(1);
  const [venue, setVenue] = useState("");

  return (
    <Modal title="Nový zápas" onClose={onClose}>
      <div className="space-y-3">
        <label className="block text-[12px] font-semibold text-hb-muted">
          Domácí
          <select value={homeId} onChange={(e) => setHomeId(e.target.value)} className={fieldClass()}>
            <option value="">Vyber tým</option>
            {teams.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Hosté
          <select value={awayId} onChange={(e) => setAwayId(e.target.value)} className={fieldClass()}>
            <option value="">Vyber tým</option>
            {teams.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Začátek
          <input
            type="datetime-local"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Kolo {round}
          <input
            type="range"
            min={1}
            max={50}
            value={round}
            onChange={(e) => setRound(Number(e.target.value))}
            className="mt-2 w-full"
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Hřiště / hala
          <input value={venue} onChange={(e) => setVenue(e.target.value)} className={fieldClass()} />
        </label>
        <button
          type="button"
          className="hb-brand-btn mt-2 w-full disabled:opacity-40"
          disabled={!homeId || !awayId || homeId === awayId || teams.length < 2}
          onClick={() => {
            addMatch({
              tournamentId,
              homeTeamId: homeId,
              awayTeamId: awayId,
              scheduledAt: new Date(date).toISOString(),
              round,
              venue,
            });
            onClose();
          }}
        >
          Přidat
        </button>
      </div>
    </Modal>
  );
}

function EditTournamentModal({
  tournament,
  onClose,
}: {
  tournament: AmateurTournament;
  onClose: () => void;
}) {
  const { updateTournament } = useAmateur();
  const [draft, setDraft] = useState(tournament);

  return (
    <Modal title="Upravit turnaj" onClose={onClose}>
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
          Místo
          <input
            value={draft.location}
            onChange={(e) => setDraft({ ...draft, location: e.target.value })}
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Od
          <input
            type="date"
            value={draft.startDate.slice(0, 10)}
            onChange={(e) =>
              setDraft({
                ...draft,
                startDate: new Date(`${e.target.value}T09:00:00`).toISOString(),
              })
            }
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Do
          <input
            type="date"
            value={draft.endDate.slice(0, 10)}
            onChange={(e) =>
              setDraft({
                ...draft,
                endDate: new Date(`${e.target.value}T18:00:00`).toISOString(),
              })
            }
            className={fieldClass()}
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Stav
          <select
            value={draft.status}
            onChange={(e) =>
              setDraft({ ...draft, status: e.target.value as AmateurTournamentStatus })
            }
            className={fieldClass()}
          >
            <option value="draft">Příprava</option>
            <option value="active">Probíhá</option>
            <option value="finished">Ukončen</option>
          </select>
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Formát
          <select
            value={draft.format}
            onChange={(e) =>
              setDraft({ ...draft, format: e.target.value as AmateurTournamentFormat })
            }
            className={fieldClass()}
          >
            <option value="roundRobin">Jen základní část</option>
            <option value="roundRobinAndPlayoff">Základní část + play-off</option>
            <option value="singleElimination">Jen play-off (vyřazovací)</option>
            <option value="bestOfSeries">Play-off na více vítězných</option>
          </select>
        </label>
        <label className="flex items-center justify-between text-[14px] font-semibold text-hb-fg">
          Doma i venku
          <input
            type="checkbox"
            checked={draft.homeAndAway}
            onChange={(e) => setDraft({ ...draft, homeAndAway: e.target.checked })}
          />
        </label>
        {draft.format === "roundRobinAndPlayoff" && (
          <label className="block text-[12px] font-semibold text-hb-muted">
            Play-off týmů
            <select
              value={draft.playoffTeamCount}
              onChange={(e) => setDraft({ ...draft, playoffTeamCount: Number(e.target.value) })}
              className={fieldClass()}
            >
              {[2, 4, 8, 16].map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </label>
        )}
        {formatUsesSeries(draft.format) && (
          <label className="block text-[12px] font-semibold text-hb-muted">
            Série
            <select
              value={draft.seriesLength}
              onChange={(e) => setDraft({ ...draft, seriesLength: Number(e.target.value) })}
              className={fieldClass()}
            >
              <option value={1}>1 zápas</option>
              <option value={3}>Best of 3</option>
              <option value={5}>Best of 5</option>
              <option value={7}>Best of 7</option>
            </select>
          </label>
        )}
        <label className="block text-[12px] font-semibold text-hb-muted">
          Třetiny: {draft.matchFormat.periodCount}
          <input
            type="range"
            min={1}
            max={4}
            value={draft.matchFormat.periodCount}
            onChange={(e) =>
              setDraft({
                ...draft,
                matchFormat: { ...draft.matchFormat, periodCount: Number(e.target.value) },
              })
            }
            className="mt-2 w-full"
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Délka: {draft.matchFormat.periodLengthMinutes} min
          <input
            type="range"
            min={5}
            max={20}
            value={draft.matchFormat.periodLengthMinutes}
            onChange={(e) =>
              setDraft({
                ...draft,
                matchFormat: {
                  ...draft.matchFormat,
                  periodLengthMinutes: Number(e.target.value),
                },
              })
            }
            className="mt-2 w-full"
          />
        </label>
        <label className="flex items-center justify-between text-[14px] font-semibold text-hb-fg">
          Prodloužení
          <input
            type="checkbox"
            checked={draft.matchFormat.overtimeEnabled}
            onChange={(e) =>
              setDraft({
                ...draft,
                matchFormat: { ...draft.matchFormat, overtimeEnabled: e.target.checked },
              })
            }
          />
        </label>
        <label className="block text-[12px] font-semibold text-hb-muted">
          Poznámka
          <textarea
            value={draft.notes}
            onChange={(e) => setDraft({ ...draft, notes: e.target.value })}
            className={`${fieldClass()} min-h-[80px]`}
          />
        </label>
        <button
          type="button"
          className="hb-brand-btn w-full"
          onClick={() => {
            updateTournament(draft);
            onClose();
          }}
        >
          Uložit
        </button>
      </div>
    </Modal>
  );
}

export function AmateurAdminTournament({ tournamentId }: { tournamentId: string }) {
  const { pop, push } = useNav();
  const {
    tournament,
    teamsIn,
    matchesIn,
    playersInTeam,
    standings,
    canGenerateSchedule,
    generateSchedule,
    generatePlayoffFromStandings,
    generateNextPlayoffRound,
    deleteMatch,
  } = useAmateur();

  const [tab, setTab] = useState("Přehled");
  const [showAddTeam, setShowAddTeam] = useState(false);
  const [showAddMatch, setShowAddMatch] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const t = tournament(tournamentId);

  if (!t) {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Turnaj" left={<BackButton onClick={pop} />} />
        <EmptyState title="Turnaj nenalezen" />
      </div>
    );
  }

  const teams = teamsIn(tournamentId);
  const matches = matchesIn(tournamentId);
  const groupDone =
    matches.filter((m) => m.phase === "group").length > 0 &&
    matches.filter((m) => m.phase === "group").every((m) => m.status === "finished");
  const hasPlayoff = matches.some((m) => m.phase === "playoff");

  function runSchedule() {
    if (t!.scheduleGenerated || matches.length > 0) {
      if (
        !confirm(
          "Přegenerovat rozpis?\n\nStávající zápasy se smažou a vytvoří se nový rozpis podle formátu turnaje."
        )
      ) {
        return;
      }
    }
    if (generateSchedule(tournamentId, true)) {
      setMessage(t!.scheduleGenerated ? "Rozpis byl přegenerován." : "Rozpis je připraven.");
      setTab("Zápasy");
    }
  }

  return (
    <div className="hb-enter flex min-h-0 flex-1 flex-col">
      <ScreenHeader
        title={t.name}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-hb-fg"
            aria-label="Upravit turnaj"
            onClick={() => setShowEdit(true)}
          >
            <IconSliders size={16} />
          </button>
        }
      />
      <UnderlineTabs tabs={TABS} value={tab} onChange={setTab} />

      <div className="hb-scroll min-h-0 flex-1 px-[var(--screen-pad)] py-3 pb-8">
        {tab === "Přehled" && (
          <div className="space-y-2.5">
            <AdminStat title="Stav" value={statusLabel(t.status)} />
            <AdminStat title="Formát" value={formatLabel(t.format)} />
            <AdminStat title="Zápas" value={matchFormatLabel(t.matchFormat)} />
            <AdminStat title="Místo" value={t.location || "—"} />
            <AdminStat title="Termín" value={dateRangeLabel(t)} />
            <AdminStat title="Týmy" value={`${teams.length}`} />
            <AdminStat title="Zápasy" value={`${matches.length}`} />
            <AdminStat title="Rozpis" value={t.scheduleGenerated ? "Vygenerován" : "Čeká"} />

            <div className="pt-2 text-[12px] font-bold text-hb-faint">Rychlé akce</div>

            {canGenerateSchedule(tournamentId) && (
              <AdminAction
                title={
                  t.scheduleGenerated
                    ? "Přegenerovat rozpis"
                    : "Připraveno — vygenerovat rozpis"
                }
                onClick={runSchedule}
              />
            )}

            {t.format === "roundRobinAndPlayoff" && (
              <>
                <AdminAction
                  title={
                    hasPlayoff
                      ? "Přegenerovat play-off z tabulky"
                      : "Vygenerovat play-off z tabulky"
                  }
                  disabled={!groupDone && !hasPlayoff && standings(tournamentId).length < 2}
                  onClick={() => {
                    if (generatePlayoffFromStandings(tournamentId)) {
                      setMessage("Play-off je vygenerováno z tabulky.");
                      setTab("Zápasy");
                    } else {
                      setMessage(
                        "Play-off nelze vytvořit — potřeba aspoň 2 týmy v tabulce."
                      );
                    }
                  }}
                />
                {formatHasPlayoff(t.format) && (
                  <AdminAction
                    title="Další kolo play-off"
                    onClick={() => {
                      if (generateNextPlayoffRound(tournamentId)) {
                        setMessage("Další kolo play-off je připravené.");
                        setTab("Zápasy");
                      } else {
                        setMessage(
                          "Další kolo zatím nejde — dohraj aktuální play-off zápasy."
                        );
                      }
                    }}
                  />
                )}
              </>
            )}

            {t.format !== "roundRobinAndPlayoff" && formatHasPlayoff(t.format) && (
              <AdminAction
                title="Další kolo play-off"
                onClick={() => {
                  if (generateNextPlayoffRound(tournamentId)) {
                    setMessage("Další kolo play-off je připravené.");
                    setTab("Zápasy");
                  } else {
                    setMessage("Další kolo zatím nejde — dohraj aktuální play-off zápasy.");
                  }
                }}
              />
            )}

            <AdminAction title="Přidat tým" onClick={() => setShowAddTeam(true)} />
            <AdminAction title="Přidat zápas ručně" onClick={() => setShowAddMatch(true)} />
            <AdminAction
              title="Zobrazit veřejný přehled"
              onClick={() => push({ name: "amateur", screen: "detail", id: tournamentId })}
            />
          </div>
        )}

        {tab === "Týmy" && (
          <div className="space-y-2.5">
            <button
              type="button"
              className="hb-brand-btn w-full"
              onClick={() => setShowAddTeam(true)}
            >
              Přidat tým
            </button>
            {teams.map((tm) => (
              <button
                key={tm.id}
                type="button"
                className="hb-card flex w-full items-center gap-3 p-3 text-left"
                onClick={() =>
                  push({
                    name: "amateur",
                    screen: "adminTeam",
                    id: tournamentId,
                    teamId: tm.id,
                  })
                }
              >
                <AmateurBadge team={tm} size={36} />
                <div className="min-w-0 flex-1">
                  <div className="text-[15px] font-bold text-hb-fg">{tm.name}</div>
                  <div className="text-[12px] font-medium text-hb-muted">
                    {playersInTeam(tm.id).length} hráčů na soupisce
                  </div>
                </div>
                <IconChevronRight size={12} />
              </button>
            ))}
          </div>
        )}

        {tab === "Zápasy" && (
          <div className="space-y-2.5">
            <button
              type="button"
              className="hb-brand-btn w-full"
              onClick={() => setShowAddMatch(true)}
            >
              Přidat zápas
            </button>
            {matches.map((m) => (
              <div key={m.id} className="space-y-2">
                <AmateurMatchRow
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
                <div className="flex gap-2">
                  <button
                    type="button"
                    className="flex-1 rounded-[10px] bg-brand/12 py-2.5 text-[12px] font-bold text-brand"
                    onClick={() =>
                      push({
                        name: "amateur",
                        screen: "scorer",
                        id: tournamentId,
                        matchId: m.id,
                      })
                    }
                  >
                    Zápis
                  </button>
                  <button
                    type="button"
                    className="flex h-10 w-11 items-center justify-center rounded-[10px] bg-loss/12 text-loss"
                    onClick={() => {
                      if (confirm("Smazat zápas?")) deleteMatch(m.id);
                    }}
                  >
                    🗑
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {showAddTeam && (
        <AddTeamModal tournamentId={tournamentId} onClose={() => setShowAddTeam(false)} />
      )}
      {showAddMatch && (
        <AddMatchModal tournamentId={tournamentId} onClose={() => setShowAddMatch(false)} />
      )}
      {showEdit && <EditTournamentModal tournament={t} onClose={() => setShowEdit(false)} />}
      {message && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-6">
          <div className="hb-card w-full max-w-sm p-5 text-center">
            <div className="mb-1 text-[15px] font-bold text-hb-fg">Rozpis</div>
            <p className="mb-4 text-[14px] text-hb-muted">{message}</p>
            <button type="button" className="hb-brand-btn w-full" onClick={() => setMessage(null)}>
              OK
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

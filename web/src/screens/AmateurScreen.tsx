"use client";

import { useMemo, useState } from "react";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import {
  formatLabel,
  statusLabel,
  useAmateur,
  type AmateurFormat,
  type AmateurMatch,
  type AmateurTournament,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

export function AmateurScreen({
  screen = "hub",
  id,
  matchId,
}: {
  screen?: "hub" | "create" | "detail" | "admin" | "scorer";
  id?: string;
  matchId?: string;
}) {
  const { pop, push } = useNav();
  const amateur = useAmateur();
  const tournament = id ? amateur.get(id) : undefined;

  if (screen === "create") return <CreateWizard />;
  if (screen === "scorer" && tournament && matchId)
    return <Scorer tournament={tournament} matchId={matchId} />;
  if ((screen === "detail" || screen === "admin") && tournament)
    return <Detail tournament={tournament} admin={screen === "admin"} />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Amatérské turnaje"
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="rounded-full bg-[var(--brand)] px-3 py-1.5 text-[12px] font-bold text-white"
            onClick={() => push({ name: "amateur", screen: "create" })}
          >
            Nový
          </button>
        }
      />
      <div className="space-y-2 px-[var(--screen-pad)] py-3">
        {amateur.tournaments.map((t) => (
          <button
            key={t.id}
            type="button"
            className="hb-card flex w-full flex-col gap-1 px-4 py-3 text-left"
            onClick={() => push({ name: "amateur", screen: "detail", id: t.id })}
          >
            <div className="flex items-center justify-between">
              <span className="font-bold">{t.name}</span>
              <span className="text-[11px] font-semibold text-[var(--brand)]">
                {statusLabel(t.status)}
              </span>
            </div>
            <div className="hb-muted">
              {t.location || "Bez místa"} · {t.teams.length} týmů · {formatLabel(t.format)}
            </div>
          </button>
        ))}
        {!amateur.tournaments.length && (
          <EmptyState title="Zatím žádný turnaj" hint="Vytvoř turnaj tlačítkem Nový." />
        )}
      </div>
    </div>
  );
}

function CreateWizard() {
  const { pop, replace } = useNav();
  const amateur = useAmateur();
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [location, setLocation] = useState("");
  const [teamText, setTeamText] = useState("Alfa\nBeta\nGama\nDelta");
  const [format, setFormat] = useState<AmateurFormat>("roundRobin");
  const [homeAndAway, setHomeAndAway] = useState(false);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title={["Základ", "Týmy", "Formát"][step]}
        left={<BackButton onClick={() => (step === 0 ? pop() : setStep((s) => s - 1))} />}
      />
      <div className="px-[var(--screen-pad)] py-4">
        {step === 0 && (
          <div className="space-y-3">
            <Field label="Název">
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full rounded-[12px] border border-[var(--card-stroke)] bg-[var(--card)] px-4 py-3 outline-none"
                placeholder="Turnaj na hřišti"
              />
            </Field>
            <Field label="Místo">
              <input
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className="w-full rounded-[12px] border border-[var(--card-stroke)] bg-[var(--card)] px-4 py-3 outline-none"
                placeholder="Praha"
              />
            </Field>
          </div>
        )}
        {step === 1 && (
          <Field label="Týmy (jeden na řádek)">
            <textarea
              value={teamText}
              onChange={(e) => setTeamText(e.target.value)}
              className="min-h-[180px] w-full rounded-[12px] border border-[var(--card-stroke)] bg-[var(--card)] px-4 py-3 outline-none"
            />
          </Field>
        )}
        {step === 2 && (
          <div className="space-y-2">
            {(
              [
                "roundRobin",
                "roundRobinAndPlayoff",
                "singleElimination",
                "bestOfSeries",
              ] as AmateurFormat[]
            ).map((f) => (
              <button
                key={f}
                type="button"
                onClick={() => setFormat(f)}
                className={`hb-card w-full px-4 py-3 text-left ${format === f ? "border-[var(--brand)]" : ""}`}
              >
                <div className="font-bold">{formatLabel(f)}</div>
              </button>
            ))}
            <label className="mt-3 flex items-center gap-2 text-[14px]">
              <input type="checkbox" checked={homeAndAway} onChange={(e) => setHomeAndAway(e.target.checked)} />
              Domácí i venku
            </label>
          </div>
        )}
        <button
          type="button"
          className="hb-brand-btn mt-6 w-full"
          onClick={() => {
            if (step < 2) {
              setStep((s) => s + 1);
              return;
            }
            const newId = amateur.createTournament({
              name,
              location,
              format,
              homeAndAway,
              teamNames: teamText.split("\n"),
            });
            replace({ name: "amateur", screen: "detail", id: newId });
          }}
        >
          {step < 2 ? "Další" : "Vytvořit turnaj"}
        </button>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <div className="mb-1 text-[12px] font-semibold text-[var(--text-secondary)]">{label}</div>
      {children}
    </label>
  );
}

function Detail({ tournament, admin }: { tournament: AmateurTournament; admin: boolean }) {
  const { pop, push } = useNav();
  const amateur = useAmateur();
  const teamName = useMemo(() => {
    const map = new Map(tournament.teams.map((t) => [t.id, t.name]));
    return (id: string) => map.get(id) ?? id;
  }, [tournament.teams]);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title={tournament.name}
        subtitle={statusLabel(tournament.status)}
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="text-[12px] font-bold text-[var(--brand)]"
            onClick={() =>
              push({
                name: "amateur",
                screen: admin ? "detail" : "admin",
                id: tournament.id,
              })
            }
          >
            {admin ? "Veřejný" : "Admin"}
          </button>
        }
      />
      <div className="px-[var(--screen-pad)] py-3">
        <div className="hb-card mb-3 p-4 text-[13px] text-[var(--text-secondary)]">
          {tournament.location || "Bez místa"} · {formatLabel(tournament.format)} ·{" "}
          {tournament.teams.length} týmů
        </div>
        {admin && (
          <div className="mb-3 flex gap-2">
            <button
              type="button"
              className="hb-brand-btn flex-1"
              onClick={() =>
                amateur.updateTournament(tournament.id, {
                  status: tournament.status === "active" ? "finished" : "active",
                })
              }
            >
              {tournament.status === "active" ? "Ukončit" : "Spustit"}
            </button>
            <button
              type="button"
              className="rounded-full bg-[var(--card-inset)] px-4 font-bold"
              onClick={() => {
                amateur.deleteTournament(tournament.id);
                pop();
              }}
            >
              Smazat
            </button>
          </div>
        )}
        <h2 className="mb-2 text-[14px] font-bold">Zápasy</h2>
        <div className="space-y-2">
          {tournament.matches.map((m) => (
            <button
              key={m.id}
              type="button"
              className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
              onClick={() =>
                admin
                  ? push({ name: "amateur", screen: "scorer", id: tournament.id, matchId: m.id })
                  : undefined
              }
            >
              <div>
                <div className="font-semibold">
                  {teamName(m.homeTeamId)} – {teamName(m.awayTeamId)}
                </div>
                <div className="hb-muted">
                  {m.roundName} · {m.status}
                </div>
              </div>
              <div className="font-[family-name:var(--font-display)] text-[18px] font-extrabold">
                {m.status === "scheduled" ? "vs" : `${m.homeScore}:{m.awayScore}`}
              </div>
            </button>
          ))}
          {!tournament.matches.length && <EmptyState title="Zápasy ještě nejsou vygenerované" />}
        </div>
      </div>
    </div>
  );
}

function Scorer({ tournament, matchId }: { tournament: AmateurTournament; matchId: string }) {
  const { pop } = useNav();
  const amateur = useAmateur();
  const match = tournament.matches.find((m) => m.id === matchId);
  if (!match) return <EmptyState title="Zápas nenalezen" />;

  const teamName = (id: string) => tournament.teams.find((t) => t.id === id)?.name ?? id;

  function patch(p: Partial<AmateurMatch>) {
    amateur.updateMatch(tournament.id, { ...match!, ...p });
  }

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Zápis" left={<BackButton onClick={pop} />} />
      <div className="px-[var(--screen-pad)] py-4">
        <div className="hb-card bg-[var(--ink)] p-5 text-center text-white">
          <div className="text-[13px] opacity-70">{match.roundName}</div>
          <div className="mt-2 font-[family-name:var(--font-display)] text-[40px] font-black tabular-nums">
            {match.homeScore}:{match.awayScore}
          </div>
          <div className="mt-2 grid grid-cols-2 gap-2 text-[13px] font-semibold">
            <span>{teamName(match.homeTeamId)}</span>
            <span>{teamName(match.awayTeamId)}</span>
          </div>
        </div>
        <div className="mt-4 grid grid-cols-2 gap-2">
          <button type="button" className="hb-card py-3 font-bold" onClick={() => patch({ homeScore: match.homeScore + 1, status: "live" })}>
            + Gól domácí
          </button>
          <button type="button" className="hb-card py-3 font-bold" onClick={() => patch({ awayScore: match.awayScore + 1, status: "live" })}>
            + Gól hosté
          </button>
          <button type="button" className="hb-card py-3 font-bold" onClick={() => patch({ homeShots: match.homeShots + 1 })}>
            + Střela dom.
          </button>
          <button type="button" className="hb-card py-3 font-bold" onClick={() => patch({ awayShots: match.awayShots + 1 })}>
            + Střela host.
          </button>
        </div>
        <div className="mt-4 flex gap-2">
          <button type="button" className="hb-brand-btn flex-1" onClick={() => patch({ status: "live" })}>
            LIVE
          </button>
          <button type="button" className="flex-1 rounded-full bg-[var(--card-inset)] font-bold" onClick={() => patch({ status: "finished" })}>
            Konec
          </button>
        </div>
      </div>
    </div>
  );
}

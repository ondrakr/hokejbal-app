"use client";

import { useState } from "react";
import { BackButton, ScreenHeader } from "@/components/ui";
import {
  formatDetail,
  formatHasGroupStage,
  formatLabel,
  formatUsesSeries,
  useAmateur,
  type AmateurTournamentFormat,
} from "@/stores/amateur";
import { useNav } from "@/stores/navigation";

const TEAM_COLORS = ["C92A2A", "1C7ED6", "2F9E44", "F08C00", "9C36B5", "0B7285", "E8590C", "343A40"];
const FORMATS: AmateurTournamentFormat[] = [
  "roundRobin",
  "roundRobinAndPlayoff",
  "singleElimination",
  "bestOfSeries",
];

type DraftTeam = { id: string; name: string; shortName: string; colorHex: string };

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <div className="mb-1.5 text-[11px] font-bold tracking-[0.5px] text-hb-faint uppercase">
        {label}
      </div>
      {children}
    </label>
  );
}

function inputClass() {
  return "w-full rounded-[12px] border border-card-stroke bg-card-inset px-3 py-3 text-[15px] font-semibold text-hb-fg outline-none";
}

export function AmateurCreate() {
  const { pop, replace } = useNav();
  const amateur = useAmateur();
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [location, setLocation] = useState("");
  const [startDate, setStartDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [teamText, setTeamText] = useState("");
  const [draftTeams, setDraftTeams] = useState<DraftTeam[]>([]);
  const [format, setFormat] = useState<AmateurTournamentFormat>("roundRobinAndPlayoff");
  const [homeAndAway, setHomeAndAway] = useState(false);
  const [playoffTeamCount, setPlayoffTeamCount] = useState(4);
  const [seriesLength, setSeriesLength] = useState(3);
  const [periodCount, setPeriodCount] = useState(3);
  const [periodLength, setPeriodLength] = useState(15);
  const [overtimeEnabled, setOvertimeEnabled] = useState(true);

  const titles = ["Základ", "Týmy", "Formát"];
  const subtitles = [
    "Jak se turnaj jmenuje a kde se hraje",
    "Přidej aspoň 2 týmy",
    "Herní systém a délka zápasu",
  ];

  const canAdvance =
    step === 0
      ? name.trim().length > 0
      : step === 1
        ? draftTeams.length >= 2 ||
          teamText
            .split("\n")
            .map((l) => l.trim())
            .filter(Boolean).length >= 2
        : true;

  function syncTeamsFromText() {
    if (draftTeams.length >= 2) return draftTeams;
    return teamText
      .split("\n")
      .map((l) => l.trim())
      .filter(Boolean)
      .map((n, i) => {
        const parts = n.split(/\s+/);
        const short =
          parts
            .map((p) => p[0])
            .join("")
            .slice(0, 3)
            .toUpperCase() || n.slice(0, 3).toUpperCase();
        return {
          id: `d_${i}`,
          name: n,
          shortName: short,
          colorHex: TEAM_COLORS[i % TEAM_COLORS.length],
        };
      });
  }

  function addTeamFromDraft() {
    const line = teamText.trim();
    if (!line) return;
    // If multiline paste, add all
    const lines = teamText
      .split("\n")
      .map((l) => l.trim())
      .filter(Boolean);
    if (lines.length > 1 && draftTeams.length === 0) {
      setDraftTeams(
        lines.map((n, i) => {
          const parts = n.split(/\s+/);
          const short =
            parts
              .map((p) => p[0])
              .join("")
              .slice(0, 3)
              .toUpperCase() || n.slice(0, 3).toUpperCase();
          return {
            id: `d_${Date.now()}_${i}`,
            name: n,
            shortName: short,
            colorHex: TEAM_COLORS[i % TEAM_COLORS.length],
          };
        })
      );
      setTeamText("");
      return;
    }
    const n = lines[0] ?? line;
    const parts = n.split(/\s+/);
    const short =
      parts
        .map((p) => p[0])
        .join("")
        .slice(0, 3)
        .toUpperCase() || n.slice(0, 3).toUpperCase();
    setDraftTeams((prev) => [
      ...prev,
      {
        id: `d_${Date.now()}`,
        name: n,
        shortName: short,
        colorHex: TEAM_COLORS[prev.length % TEAM_COLORS.length],
      },
    ]);
    setTeamText("");
  }

  function finish() {
    const teams = syncTeamsFromText();
    if (teams.length < 2 || !name.trim()) return;
    const startIso = new Date(`${startDate}T09:00:00`).toISOString();
    const tournament = amateur.createTournament({
      name,
      location,
      startDate: startIso,
      endDate: startIso,
      notes: "",
      format,
      matchFormat: {
        periodCount,
        periodLengthMinutes: periodLength,
        overtimeEnabled,
      },
      homeAndAway,
      playoffTeamCount,
      seriesLength: formatUsesSeries(format) ? seriesLength : 1,
    });
    for (const team of teams) {
      amateur.addTeam(tournament.id, team.name, team.shortName, "", team.colorHex);
    }
    amateur.generateSchedule(tournament.id, true);
    replace({ name: "amateur", screen: "admin", id: tournament.id });
  }

  return (
    <div className="hb-enter flex min-h-0 flex-1 flex-col">
      <ScreenHeader
        title={titles[step]}
        left={<BackButton onClick={() => (step === 0 ? pop() : setStep((s) => s - 1))} />}
      />
      <div className="flex gap-1.5 px-[var(--screen-pad)] pt-2 pb-1">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className={`h-1 flex-1 rounded-full ${i <= step ? "bg-brand" : "bg-separator"}`}
          />
        ))}
      </div>
      <div className="hb-scroll min-h-0 flex-1 px-[var(--screen-pad)] py-4 pb-28">
        <h2 className="text-[26px] font-extrabold text-hb-fg">{titles[step]}</h2>
        <p className="mt-1 mb-4 text-[14px] font-medium text-hb-muted">{subtitles[step]}</p>

        {step === 0 && (
          <div className="hb-card space-y-3.5 p-4">
            <Field label="Název">
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                className={inputClass()}
                placeholder="např. Memoriál 2026"
              />
            </Field>
            <Field label="Místo">
              <input
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className={inputClass()}
                placeholder="Hala / město"
              />
            </Field>
            <Field label="Datum">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className={inputClass()}
              />
            </Field>
          </div>
        )}

        {step === 1 && (
          <div className="space-y-3">
            <div className="flex gap-2.5">
              <input
                value={teamText}
                onChange={(e) => setTeamText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    addTeamFromDraft();
                  }
                }}
                className={inputClass()}
                placeholder="Název týmu (nebo více řádků)"
              />
              <button
                type="button"
                className="flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full bg-brand text-[22px] font-bold text-on-brand"
                onClick={addTeamFromDraft}
                disabled={!teamText.trim()}
              >
                +
              </button>
            </div>
            <textarea
              value={teamText.includes("\n") || draftTeams.length === 0 ? teamText : ""}
              onChange={(e) => setTeamText(e.target.value)}
              className="min-h-[100px] w-full rounded-[12px] border border-card-stroke bg-card px-3 py-3 text-[14px] text-hb-fg outline-none"
              placeholder="Nebo vlož týmy — jeden na řádek"
            />
            {draftTeams.length === 0 ? (
              <p className="py-2 text-[13px] font-medium text-hb-faint">
                Zatím žádný tým — přidej aspoň dva.
              </p>
            ) : (
              <div className="space-y-2">
                {draftTeams.map((team) => (
                  <div key={team.id} className="hb-card flex items-center gap-3 p-3">
                    <span
                      className="flex h-9 w-9 items-center justify-center rounded-full text-[12px] font-bold text-white"
                      style={{ backgroundColor: `#${team.colorHex}` }}
                    >
                      {team.shortName.slice(0, 2)}
                    </span>
                    <span className="flex-1 text-[15px] font-bold text-hb-fg">{team.name}</span>
                    <button
                      type="button"
                      className="flex h-7 w-7 items-center justify-center rounded-full bg-card-inset text-hb-faint"
                      onClick={() => setDraftTeams((prev) => prev.filter((t) => t.id !== team.id))}
                    >
                      ×
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {step === 2 && (
          <div className="space-y-3.5">
            <div className="text-[11px] font-bold tracking-[0.5px] text-hb-faint">HERNÍ SYSTÉM</div>
            {FORMATS.map((f) => (
              <button
                key={f}
                type="button"
                onClick={() => setFormat(f)}
                className={`hb-card w-full px-3.5 py-3.5 text-left ${
                  format === f ? "ring-2 ring-brand/45" : ""
                }`}
              >
                <div className="flex items-start gap-3">
                  <span className={`mt-0.5 text-[18px] ${format === f ? "text-brand" : "text-hb-faint"}`}>
                    {format === f ? "●" : "○"}
                  </span>
                  <div>
                    <div className="text-[15px] font-bold text-hb-fg">{formatLabel(f)}</div>
                    <div className="mt-1 text-[12px] font-medium text-hb-muted">{formatDetail(f)}</div>
                  </div>
                </div>
              </button>
            ))}

            {formatHasGroupStage(format) && (
              <label className="hb-card flex items-center justify-between p-3.5 text-[15px] font-semibold text-hb-fg">
                Doma i venku
                <input
                  type="checkbox"
                  checked={homeAndAway}
                  onChange={(e) => setHomeAndAway(e.target.checked)}
                />
              </label>
            )}

            {format === "roundRobinAndPlayoff" && (
              <div className="hb-card p-3.5">
                <div className="mb-2 text-[13px] font-bold text-hb-muted">Play-off týmů</div>
                <div className="flex gap-2">
                  {[2, 4, 8, 16].map((n) => (
                    <button
                      key={n}
                      type="button"
                      onClick={() => setPlayoffTeamCount(n)}
                      className="hb-choice-chip flex-1 !rounded-full text-center"
                      data-active={playoffTeamCount === n ? "true" : "false"}
                    >
                      {n}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {formatUsesSeries(format) && (
              <div className="hb-card p-3.5">
                <div className="mb-2 text-[13px] font-bold text-hb-muted">Série</div>
                <div className="flex gap-2">
                  {[
                    [1, "1"],
                    [3, "Bo3"],
                    [5, "Bo5"],
                    [7, "Bo7"],
                  ].map(([v, label]) => (
                    <button
                      key={v}
                      type="button"
                      onClick={() => setSeriesLength(Number(v))}
                      className="hb-choice-chip flex-1 !rounded-full text-center"
                      data-active={seriesLength === v ? "true" : "false"}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>
            )}

            <div className="text-[11px] font-bold tracking-[0.5px] text-hb-faint">DÉLKA ZÁPASU</div>
            <div className="hb-card space-y-3 p-3.5 text-[15px] font-semibold text-hb-fg">
              <label className="flex items-center justify-between gap-3">
                Třetiny: {periodCount}
                <input
                  type="range"
                  min={1}
                  max={4}
                  value={periodCount}
                  onChange={(e) => setPeriodCount(Number(e.target.value))}
                />
              </label>
              <label className="flex items-center justify-between gap-3">
                Délka: {periodLength} min
                <input
                  type="range"
                  min={5}
                  max={20}
                  value={periodLength}
                  onChange={(e) => setPeriodLength(Number(e.target.value))}
                />
              </label>
              <label className="flex items-center justify-between">
                Prodloužení
                <input
                  type="checkbox"
                  checked={overtimeEnabled}
                  onChange={(e) => setOvertimeEnabled(e.target.checked)}
                />
              </label>
            </div>
          </div>
        )}
      </div>

      <div className="sticky bottom-0 border-t border-separator bg-canvas/95 px-[var(--screen-pad)] py-3">
        <div className="flex gap-2.5">
          {step > 0 && (
            <button
              type="button"
              className="flex-1 rounded-full border border-card-stroke bg-card py-3.5 text-[15px] font-bold text-hb-fg"
              onClick={() => setStep((s) => s - 1)}
            >
              Zpět
            </button>
          )}
          <button
            type="button"
            className="hb-brand-btn flex-1 disabled:opacity-40"
            disabled={!canAdvance}
            onClick={() => {
              if (step < 2) {
                if (step === 1 && draftTeams.length < 2) {
                  const fromText = syncTeamsFromText();
                  if (fromText.length >= 2) setDraftTeams(fromText);
                }
                setStep((s) => s + 1);
                return;
              }
              finish();
            }}
          >
            {step === 2 ? "Vytvořit turnaj" : "Pokračovat"}
          </button>
        </div>
      </div>
    </div>
  );
}

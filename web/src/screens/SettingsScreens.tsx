"use client";

import { useEffect, useMemo, useState } from "react";
import { CompetitionBadge, TeamBadge } from "@/components/Badges";
import { IconChevronRight, IconCourt, IconGear, IconNews } from "@/components/Icons";
import { Pill } from "@/components/MatchRow";
import { BackButton, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useCompetitionOrder } from "@/stores/competitionOrder";
import { useDataSource } from "@/stores/dataSource";
import { useHomeFeed } from "@/stores/homeFeed";
import { useNav } from "@/stores/navigation";
import { useNotifications } from "@/stores/notifications";
import type { Competition } from "@/lib/types";

/** Port SettingsView + nested settings */
export function SettingsScreen() {
  const { seasons, selectedSeasonId, setSelectedSeasonId, competitions, refresh } = useCatalog();
  const { pop, push } = useNav();
  const feed = useHomeFeed();
  const notif = useNotifications();
  const order = useCompetitionOrder();
  const dataSource = useDataSource();
  const [theme, setTheme] = useState<"system" | "light" | "dark">(() => {
    if (typeof window === "undefined") return "light";
    return (localStorage.getItem("hb.appearance") as "system" | "light" | "dark") || "light";
  });

  useEffect(() => {
    order.sync(competitions);
  }, [competitions, order]);

  function applyTheme(next: "system" | "light" | "dark") {
    setTheme(next);
    localStorage.setItem("hb.appearance", next);
    const root = document.documentElement;
    if (next === "system") {
      if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
        root.setAttribute("data-theme", "dark");
      } else {
        root.setAttribute("data-theme", "light");
      }
    } else {
      root.setAttribute("data-theme", next);
    }
  }

  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader title="Nastavení" systemIcon={<IconGear size={14} />} left={<BackButton onClick={pop} />} />
      <div className="space-y-5 px-4 py-4 pb-8">
        <SettingsSection title="Zobrazení" footer="Výchozí je světlý režim. Tmavý přizpůsobí barvy; Podle systému sleduje OS.">
          <div className="grid grid-cols-3 gap-2 p-3">
            {(
              [
                ["system", "Systém"],
                ["light", "Světlý"],
                ["dark", "Tmavý"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => applyTheme(id)}
                className={`rounded-[12px] py-2.5 text-[13px] font-semibold ${
                  theme === id ? "bg-brand text-white" : "bg-card-inset text-hb-fg"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </SettingsSection>

        <SettingsSection
          title="Soutěže a Domů"
          footer="Pořadí platí v Zápasech, LIVE i Oblíbených. Zápasy na Domů řídí slider."
        >
          <SettingsLink
            title="Pořadí soutěží"
            onClick={() => push({ name: "settingsOrder" })}
          />
          <SettingsLink
            title="Zápasy na Domů"
            detail={feed.selectionSummary}
            onClick={() => push({ name: "settingsHomeFeed" })}
          />
        </SettingsSection>

        <SettingsSection title="Sezóna">
          <div className="space-y-1.5 p-3">
            {seasons.map((s) => (
              <button
                key={s.id}
                type="button"
                onClick={() => setSelectedSeasonId(s.id)}
                className={`flex w-full items-center justify-between rounded-[12px] px-3 py-2.5 text-left ${
                  selectedSeasonId === s.id ? "bg-brand text-white" : "bg-card-inset"
                }`}
              >
                <span className="font-semibold">{s.label}</span>
                {s.isCurrent && <span className="text-[11px] opacity-80">aktuální</span>}
              </button>
            ))}
          </div>
        </SettingsSection>

        <SettingsSection
          title="Zdroj dat"
          footer="Online = živá data ze Supabase. Mock = offline snapshot z posledního online načtení."
        >
          <div className="space-y-1.5 p-3">
            {(["supabase", "mock"] as const).map((id) => (
              <button
                key={id}
                type="button"
                onClick={() => {
                  dataSource.setSource(id);
                  void refresh();
                }}
                className={`flex w-full items-center justify-between rounded-[12px] px-3 py-2.5 text-left ${
                  dataSource.source === id ? "bg-brand text-white" : "bg-card-inset"
                }`}
              >
                <span className="font-semibold">{dataSource.title(id)}</span>
              </button>
            ))}
          </div>
        </SettingsSection>

        <SettingsSection
          title="Upozornění"
          footer="V prohlížeči jde o lokální preference (bez systémových push)."
        >
          <SettingsLink
            title="Notifikace"
            detail={notif.activeLiveTypesSummary}
            onClick={() => push({ name: "settingsNotifications" })}
          />
        </SettingsSection>

        <SettingsSection title="O aplikaci">
          <div className="space-y-2 px-4 py-3 text-[14px]">
            <Row label="Verze" value="web · Next.js" />
            <Row label="Design" value="hokejbal.cz · iOS" />
            <a href="https://www.hokejbal.cz" target="_blank" rel="noreferrer" className="block font-semibold text-brand">
              hokejbal.cz
            </a>
            <p className="pt-1 text-[12px] leading-relaxed text-hb-muted">
              Web sdílí Supabase data s iOS. Fantasy, tipovačka a amatérské turnaje běží lokálně.
            </p>
          </div>
        </SettingsSection>
      </div>
    </div>
  );
}

export function HomeFeedSettingsScreen() {
  const { pop } = useNav();
  const { competitions, teams, teamById } = useCatalog();
  const feed = useHomeFeed();
  const order = useCompetitionOrder();
  const [pickMode, setPickMode] = useState<"Soutěž" | "Tým">("Soutěž");
  const [teamQuery, setTeamQuery] = useState("");

  useEffect(() => {
    feed.seedDefaultsIfNeeded(competitions);
  }, [competitions, feed]);

  useEffect(() => {
    order.sync(competitions);
  }, [competitions, order]);

  useEffect(() => {
    if (!feed.competitionSlugs.length && feed.teamIDs.length) {
      setPickMode("Tým");
    }
  }, [feed.competitionSlugs.length, feed.teamIDs.length]);

  const sortedCompetitions = useMemo(
    () => order.sortedCompetitions(competitions),
    [order, competitions]
  );

  const filteredTeams = useMemo(() => {
    const q = teamQuery.trim().toLowerCase();
    const list = [...teams].sort((a, b) => a.name.localeCompare(b.name, "cs"));
    if (!q) return list;
    return list.filter(
      (t) =>
        t.name.toLowerCase().includes(q) ||
        t.shortName.toLowerCase().includes(q) ||
        t.city.toLowerCase().includes(q)
    );
  }, [teams, teamQuery]);

  const selectedCompetitions = useMemo(
    () => sortedCompetitions.filter((c) => feed.competitionSlugs.includes(c.slug)),
    [sortedCompetitions, feed.competitionSlugs]
  );

  const selectedTeams = useMemo(
    () =>
      feed.teamIDs
        .map((id) => teamById(id))
        .filter((t): t is NonNullable<typeof t> => Boolean(t))
        .sort((a, b) => a.shortName.localeCompare(b.shortName, "cs")),
    [feed.teamIDs, teamById]
  );

  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader
        title="Zápasy na Domů"
        systemIcon={<IconCourt size={14} />}
        left={<BackButton onClick={pop} />}
      />
      <div className="space-y-5 px-4 py-4 pb-10">
        <p className="text-[13px] leading-relaxed text-hb-muted">
          Nejdřív zvolte, jestli přidáváte soutěž nebo tým. Slider pak ukáže jejich zápasy.{" "}
          {feed.selectionSummary}.
        </p>

        {(selectedCompetitions.length > 0 || selectedTeams.length > 0) && (
          <SettingsSection
            title="Aktuální výběr"
            trailing={
              <button
                type="button"
                className="text-[12px] font-bold text-loss"
                onClick={() => feed.clearAll()}
              >
                Vymazat
              </button>
            }
          >
            <div className="flex flex-wrap gap-2 p-3">
              {selectedCompetitions.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => feed.toggleCompetition(c.slug)}
                  className="inline-flex items-center gap-1.5 rounded-full bg-brand/12 px-2.5 py-1.5 text-[11px] font-bold text-brand"
                >
                  <CompetitionBadge competition={c} size={16} />
                  {c.shortName}
                  <span className="opacity-70">×</span>
                </button>
              ))}
              {selectedTeams.map((t) => (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => feed.toggleTeam(t.id)}
                  className="inline-flex items-center gap-1.5 rounded-full bg-brand/12 px-2.5 py-1.5 text-[11px] font-bold text-brand"
                >
                  <TeamBadge team={t} size={16} />
                  {t.shortName}
                  <span className="opacity-70">×</span>
                </button>
              ))}
            </div>
          </SettingsSection>
        )}

        <div>
          <div className="mb-1 px-1 text-[12px] font-bold tracking-[0.3px] text-hb-faint uppercase">
            Přidat
          </div>
          <div className="flex gap-[3px] rounded-[12px] bg-card-inset p-1">
            {(["Soutěž", "Tým"] as const).map((mode) => (
              <Pill key={mode} active={pickMode === mode} onClick={() => setPickMode(mode)}>
                {mode}
              </Pill>
            ))}
          </div>
          <p className="mt-2 px-1 text-[12px] text-hb-muted">
            {pickMode === "Soutěž"
              ? "Celá soutěž — všechny její zápasy ve slideru."
              : "Konkrétní klub — jeho zápasy i napříč soutěžemi."}
          </p>
        </div>

        {pickMode === "Soutěž" ? (
          <SettingsSection
            title="Soutěže"
            trailing={
              <div className="flex gap-3 text-[12px] font-bold text-brand">
                <button type="button" onClick={() => feed.selectAllCompetitions(sortedCompetitions)}>
                  Vše
                </button>
                <button type="button" onClick={() => feed.clearCompetitions()}>
                  Nic
                </button>
              </div>
            }
          >
            {sortedCompetitions.map((c: Competition) => (
              <ToggleRow
                key={c.id}
                title={c.name}
                subtitle={c.season}
                leading={<CompetitionBadge competition={c} size={28} />}
                on={feed.isCompetitionSelected(c.slug)}
                onToggle={() => feed.toggleCompetition(c.slug)}
              />
            ))}
            {!sortedCompetitions.length && (
              <div className="px-4 py-3 text-[13px] text-hb-muted">Soutěže se ještě načítají…</div>
            )}
          </SettingsSection>
        ) : (
          <SettingsSection
            title="Týmy"
            trailing={
              <button
                type="button"
                className="text-[12px] font-bold text-brand"
                onClick={() => feed.clearTeams()}
              >
                Vymazat týmy
              </button>
            }
          >
            <div className="p-3">
              <input
                value={teamQuery}
                onChange={(e) => setTeamQuery(e.target.value)}
                placeholder="Hledat tým nebo město…"
                className="w-full rounded-[12px] border border-card-stroke bg-card px-3 py-2.5 text-[14px] outline-none focus:border-brand"
              />
            </div>
            {filteredTeams.map((t) => (
              <ToggleRow
                key={t.id}
                title={t.name}
                subtitle={t.city}
                leading={<TeamBadge team={t} size={28} />}
                on={feed.isTeamSelected(t.id)}
                onToggle={() => feed.toggleTeam(t.id)}
              />
            ))}
            {!filteredTeams.length && (
              <div className="px-4 py-3 text-[13px] text-hb-muted">
                {teams.length ? "Žádný tým neodpovídá hledání." : "Týmy se ještě načítají…"}
              </div>
            )}
          </SettingsSection>
        )}
      </div>
    </div>
  );
}

export function CompetitionOrderSettingsScreen() {
  const { pop } = useNav();
  const { competitions } = useCatalog();
  const order = useCompetitionOrder();

  useEffect(() => {
    order.sync(competitions);
  }, [competitions, order]);

  const sorted = order.sortedCompetitions(competitions);

  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader title="Pořadí soutěží" left={<BackButton onClick={pop} />} />
      <p className="px-4 pt-3 text-[13px] text-hb-muted">Přesuň šipkami — pořadí platí v Zápasech, LIVE a Oblíbených.</p>
      <div className="space-y-2 px-4 py-3 pb-10">
        {sorted.map((c, index) => (
          <div key={c.id} className="hb-card flex items-center gap-3 px-3 py-3">
            <CompetitionBadge competition={c} size={28} />
            <div className="min-w-0 flex-1">
              <div className="truncate text-[15px] font-semibold">{c.name}</div>
              <div className="text-[12px] text-hb-muted">{c.season}</div>
            </div>
            <div className="flex flex-col gap-1">
              <button
                type="button"
                disabled={index === 0}
                className="rounded bg-card-inset px-2 py-1 text-[11px] font-bold disabled:opacity-30"
                onClick={() => order.move(index, index - 1)}
              >
                ▲
              </button>
              <button
                type="button"
                disabled={index === sorted.length - 1}
                className="rounded bg-card-inset px-2 py-1 text-[11px] font-bold disabled:opacity-30"
                onClick={() => order.move(index, index + 1)}
              >
                ▼
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export function NotificationSettingsScreen() {
  const { pop } = useNav();
  const n = useNotifications();
  const [perm, setPerm] = useState<NotificationPermission | "unsupported">("default");

  useEffect(() => {
    if (typeof window === "undefined" || !("Notification" in window)) {
      setPerm("unsupported");
      return;
    }
    setPerm(Notification.permission);
  }, []);

  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader title="Notifikace" left={<BackButton onClick={pop} />} />
      <div className="space-y-5 px-4 py-4 pb-10">
        <div className="hb-card space-y-3 p-4">
          <div className="text-[15px] font-bold">Prohlížeč</div>
          <p className="text-[12px] leading-relaxed text-hb-muted">
            Preference + systémová upozornění (gól, konec, začátek) jako lokální notifikace v iOS.
          </p>
          {perm !== "unsupported" && perm !== "granted" && (
            <button
              type="button"
              className="hb-brand-btn w-full"
              onClick={async () => {
                const { ensureNotificationPermission } = await import("@/lib/browserNotify");
                const next = await ensureNotificationPermission();
                setPerm(next);
              }}
            >
              Povolit systémová upozornění
            </button>
          )}
          {perm === "granted" && (
            <div className="text-[12px] font-semibold text-brand">Systémová upozornění povolena</div>
          )}
          {perm === "denied" && (
            <div className="text-[12px] font-medium text-hb-muted">
              Blokováno v nastavení prohlížeče — povolte notifikace pro tento web.
            </div>
          )}
        </div>

        <SettingsSection title="Živé zápasy">
          <ToggleRow title="Góly" subtitle="Upozornění při gólu" on={n.goalsEnabled} onToggle={() => n.set("goalsEnabled", !n.goalsEnabled)} />
          <ToggleRow title="Konečný výsledek" subtitle="Po skončení sledovaného zápasu" on={n.finalScoreEnabled} onToggle={() => n.set("finalScoreEnabled", !n.finalScoreEnabled)} />
          <ToggleRow title="Začátek zápasu" subtitle="Připomenutí před výkopem" on={n.matchStartEnabled} onToggle={() => n.set("matchStartEnabled", !n.matchStartEnabled)} />
        </SettingsSection>

        <SettingsSection title="Rozsah">
          <ToggleRow
            title="Jen oblíbené"
            subtitle={n.onlyFavorites ? "Jen oblíbené týmy a zápasy" : "Všechny zápasy"}
            on={n.onlyFavorites}
            onToggle={() => n.set("onlyFavorites", !n.onlyFavorites)}
          />
        </SettingsSection>

        <SettingsSection title="Obsah">
          <ToggleRow title="Novinky" subtitle="Články a oznámení" on={n.newsEnabled} onToggle={() => n.set("newsEnabled", !n.newsEnabled)} leading={<IconNews size={18} />} />
        </SettingsSection>
      </div>
    </div>
  );
}

function SettingsSection({
  title,
  footer,
  trailing,
  children,
}: {
  title: string;
  footer?: string;
  trailing?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section>
      <div className="mb-2 flex items-center justify-between px-1">
        <h2 className="text-[13px] font-bold tracking-[0.3px] text-hb-muted uppercase">{title}</h2>
        {trailing}
      </div>
      <div className="hb-card overflow-hidden divide-y divide-[color-mix(in_srgb,var(--separator)_70%,transparent)]">
        {children}
      </div>
      {footer && <p className="mt-2 px-1 text-[12px] leading-snug text-hb-faint">{footer}</p>}
    </section>
  );
}

function SettingsLink({
  title,
  detail,
  onClick,
}: {
  title: string;
  detail?: string;
  onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick} className="flex w-full items-center gap-3 px-4 py-3.5 text-left">
      <span className="min-w-0 flex-1 text-[16px] font-semibold text-hb-fg">{title}</span>
      {detail && <span className="max-w-[40%] truncate text-[13px] font-medium text-hb-faint">{detail}</span>}
      <span className="text-hb-faint">
        <IconChevronRight size={12} />
      </span>
    </button>
  );
}

function ToggleRow({
  title,
  subtitle,
  leading,
  on,
  onToggle,
}: {
  title: string;
  subtitle?: string;
  leading?: React.ReactNode;
  on: boolean;
  onToggle: () => void;
}) {
  return (
    <button type="button" onClick={onToggle} className="flex w-full items-center gap-3 px-4 py-3 text-left">
      {leading}
      <div className="min-w-0 flex-1">
        <div className="text-[15px] font-semibold text-hb-fg">{title}</div>
        {subtitle && <div className="text-[12px] font-medium text-hb-muted">{subtitle}</div>}
      </div>
      <span
        className={`relative h-[28px] w-[48px] shrink-0 rounded-full transition ${on ? "bg-brand" : "bg-card-inset"}`}
      >
        <span
          className={`absolute top-[3px] h-[22px] w-[22px] rounded-full bg-white shadow transition ${
            on ? "left-[23px]" : "left-[3px]"
          }`}
        />
      </span>
    </button>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-3">
      <span className="text-hb-muted">{label}</span>
      <span className="font-semibold text-hb-fg">{value}</span>
    </div>
  );
}

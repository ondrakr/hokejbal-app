"use client";

import { useEffect, useMemo, useState, type CSSProperties, type ReactNode } from "react";
import {
  IconChevronLeft,
  IconChevronRight,
  IconSearch,
  IconStack,
  IconTrophy,
  IconUser,
} from "@/components/Icons";
import { TeamBadge } from "@/components/Badges";
import { FantasyCard, FantasyEmptyCard, RinkSurface, TierChip } from "@/components/FantasyCard";
import { Pill, PillTrack } from "@/components/MatchRow";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import type { Match, Player } from "@/lib/types";
import { playerFullName, positionLabel } from "@/lib/types";
import {
  FANTASY_SLOTS,
  fantasyPoints,
  nextFantasyFixture,
  playerAttributeRows,
  playerPrice,
  playerRating,
  slotPosition,
  slotShortTitle,
  slotTitle,
  tierLabel,
  useFantasy,
  type FantasySlot,
} from "@/stores/fantasy";
import { countdownParts } from "@/lib/fantasyDeadline";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";
import { teamFormColor, teamFormItems, teamFormLetter } from "@/lib/teamForm";

type MarketSort = "rating" | "price" | "points" | "name";

const SORT_OPTIONS: { id: MarketSort; label: string }[] = [
  { id: "rating", label: "OVR" },
  { id: "price", label: "Cena" },
  { id: "points", label: "Body" },
  { id: "name", label: "Jméno" },
];

/** Řady sestavy na hřišti — brankář nahoře, útok dole. */
const LINES: { label: string; slots: FantasySlot[] }[] = [
  { label: "BRANKÁŘ", slots: ["G"] },
  { label: "OBRANA", slots: ["D1", "D2"] },
  { label: "ÚTOK", slots: ["F1", "F2", "F3"] },
];

const DARK_CANVAS: CSSProperties = {
  background: "linear-gradient(180deg,#16202c 0%,#101720 60%,#0b1016 100%)",
};

function formatFixtureDate(iso: string) {
  try {
    return new Intl.DateTimeFormat("cs-CZ", {
      weekday: "long",
      day: "numeric",
      month: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "Europe/Prague",
    }).format(new Date(iso));
  } catch {
    return iso.slice(0, 16);
  }
}

function formatFixtureShort(iso: string) {
  try {
    return new Intl.DateTimeFormat("cs-CZ", {
      weekday: "short",
      day: "numeric",
      month: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "Europe/Prague",
    }).format(new Date(iso));
  } catch {
    return iso.slice(0, 16);
  }
}

function pad2(n: number) {
  return String(n).padStart(2, "0");
}

/**
 * Odpočet do uzávěrky sestavy.
 *
 * Vlastní tik po sekundě, aby se překreslovaly jen číslice a ne celá obrazovka.
 */
function Countdown({ deadline }: { deadline: Date }) {
  const [now, setNow] = useState<Date | null>(null);
  useEffect(() => {
    setNow(new Date());
    const id = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(id);
  }, []);

  const parts = now
    ? countdownParts(deadline, now)
    : { days: 0, hours: 0, minutes: 0, seconds: 0 };
  const units: [number, string][] = [
    [parts.days, "DNY"],
    [parts.hours, "HOD"],
    [parts.minutes, "MIN"],
    [parts.seconds, "SEK"],
  ];

  return (
    <div className="flex items-end gap-1.5">
      {units.map(([value, label], i) => (
        <div key={label} className="flex items-end gap-1.5">
          {i > 0 && <span className="hb-number pb-3 text-[15px] font-extrabold text-white/35">:</span>}
          <div className="min-w-[38px] rounded-[9px] bg-white/10 px-1.5 py-1.5 text-center">
            <div className="hb-number text-[19px] font-extrabold tabular-nums text-white">
              {pad2(value)}
            </div>
            <div className="text-[8px] font-bold tracking-[0.5px] text-white/45">{label}</div>
          </div>
        </div>
      ))}
    </div>
  );
}

// MARK: - Drobné stavební prvky

function SectionLabel({ children, tone = "light" }: { children: ReactNode; tone?: "light" | "dark" }) {
  return (
    <div
      className={`text-[11px] font-bold tracking-[0.8px] ${
        tone === "dark" ? "text-white/45" : "text-hb-faint"
      }`}
    >
      {children}
    </div>
  );
}

/** Kompaktní dlaždice se statistikou (na tmavém i světlém podkladu). */
function StatCell({
  label,
  value,
  hint,
  tone = "light",
  highlight,
}: {
  label: string;
  value: string;
  hint?: string;
  tone?: "light" | "dark";
  highlight?: boolean;
}) {
  const dark = tone === "dark";
  return (
    <div
      className={`flex-1 rounded-[12px] px-2 py-2.5 text-center ${
        dark ? "bg-white/10" : "hb-card"
      }`}
    >
      <div className={`text-[9px] font-bold tracking-[0.5px] ${dark ? "text-white/50" : "text-hb-faint"}`}>
        {label}
      </div>
      <div
        className={`hb-number mt-1 text-[17px] font-extrabold ${
          highlight ? "text-brand" : dark ? "text-white" : "text-hb-fg"
        }`}
      >
        {value}
      </div>
      {hint && (
        <div className={`mt-0.5 text-[9px] font-semibold ${dark ? "text-white/40" : "text-hb-faint"}`}>
          {hint}
        </div>
      )}
    </div>
  );
}

/** Pruh využitého rozpočtu — zčervená, když dojdou kredity. */
function BudgetBar({ spent, budget, tone = "dark" }: { spent: number; budget: number; tone?: "light" | "dark" }) {
  const ratio = Math.min(1, Math.max(0, spent / budget));
  const dark = tone === "dark";
  const color = ratio > 0.95 ? "var(--loss)" : ratio > 0.8 ? "var(--draw)" : "var(--win)";
  return (
    <div className={`h-1.5 w-full overflow-hidden rounded-full ${dark ? "bg-white/15" : "bg-card-inset"}`}>
      <div
        className="h-full rounded-full transition-[width] duration-300"
        style={{ width: `${ratio * 100}%`, background: color }}
      />
    </div>
  );
}

/** Řádek jednoho zápasu kola. */
function FixtureRow({ match, last }: { match: Match; last?: boolean }) {
  const { teamById } = useCatalog();
  const home = teamById(match.homeTeamId);
  const away = teamById(match.awayTeamId);
  const time = useMemo(() => formatFixtureShort(match.scheduledAt), [match.scheduledAt]);

  return (
    <>
      <div className="flex items-center gap-2.5 px-3.5 py-2.5">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          <TeamBadge team={home} size={22} />
          <span className="truncate text-[13px] font-semibold text-hb-fg">
            {home?.shortName ?? "—"}
          </span>
        </div>
        <span className="hb-number shrink-0 rounded-full bg-card-inset px-2 py-1 text-[10px] font-bold text-hb-muted">
          {time}
        </span>
        <div className="flex min-w-0 flex-1 items-center justify-end gap-2">
          <span className="truncate text-right text-[13px] font-semibold text-hb-fg">
            {away?.shortName ?? "—"}
          </span>
          <TeamBadge team={away} size={22} />
        </div>
      </div>
      {!last && <div className="mx-3.5 h-px bg-[color-mix(in_srgb,var(--separator)_45%,transparent)]" />}
    </>
  );
}

/** Dlaždice v rozcestníku fantasy. */
function MenuTile({
  icon,
  title,
  subtitle,
  onClick,
}: {
  icon: ReactNode;
  title: string;
  subtitle: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="hb-card flex flex-col items-start gap-2 p-3.5 text-left transition active:scale-[0.98]"
    >
      <span className="flex h-9 w-9 items-center justify-center rounded-[10px] bg-[color-mix(in_srgb,var(--brand)_12%,transparent)] text-brand [&_svg]:h-[18px] [&_svg]:w-[18px]">
        {icon}
      </span>
      <span className="text-[15px] font-bold text-hb-fg">{title}</span>
      <span className="text-[11px] font-medium leading-snug text-hb-muted">{subtitle}</span>
    </button>
  );
}

/** V/R/P odznaky formy klubu. */
function FormBadges({ items, size = 20 }: { items: { id: string; outcome: "win" | "draw" | "loss" }[]; size?: number }) {
  if (!items.length) return <span className="text-[12px] text-hb-muted">—</span>;
  return (
    <span className="flex gap-1">
      {items.map((f) => (
        <span
          key={f.id}
          className="flex items-center justify-center rounded-[5px] font-bold text-white"
          style={{ width: size, height: size, fontSize: size * 0.45, background: teamFormColor(f.outcome) }}
        >
          {teamFormLetter(f.outcome)}
        </span>
      ))}
    </span>
  );
}

/** Krátký popis příštího zápasu hráče („vs LIT“ / „@ PLZ“). */
function useNextOpponent(teamId: string, matches: Match[]) {
  const { teamById } = useCatalog();
  const fixture = nextFantasyFixture(teamId, matches);
  if (!fixture) return null;
  const isHome = fixture.homeTeamId === teamId;
  const opponent = teamById(isHome ? fixture.awayTeamId : fixture.homeTeamId);
  if (!opponent) return null;
  return { fixture, isHome, opponent, label: `${isHome ? "vs" : "@"} ${opponent.shortName}` };
}

// MARK: - Scout

function ScoutStat({ title, value }: { title: string; value: string }) {
  return (
    <div className="flex-1 rounded-[10px] bg-card-inset px-1 py-2.5 text-center">
      <div className="text-[10px] font-bold text-hb-faint">{title}</div>
      <div className="hb-number mt-0.5 text-[15px] font-extrabold text-hb-fg">{value}</div>
    </div>
  );
}

/** Parametry hráče jako proužky 0–99. */
function AttributeBars({ player }: { player: Player }) {
  const rows = useMemo(() => playerAttributeRows(player), [player]);
  if (!rows.length) return null;
  return (
    <div className="hb-card space-y-2.5 p-3.5">
      <SectionLabel>PARAMETRY</SectionLabel>
      <div className="space-y-2">
        {rows.map((row) => (
          <div key={row.label} className="flex items-center gap-2.5">
            <span className="w-[78px] shrink-0 text-[12px] font-semibold text-hb-fg">{row.label}</span>
            <span className="h-[6px] flex-1 overflow-hidden rounded-full bg-card-inset">
              <span
                className="block h-full rounded-full"
                style={{
                  width: `${(row.value / 99) * 100}%`,
                  background: row.value >= 90 ? "var(--win)" : "var(--brand)",
                }}
              />
            </span>
            <span className="hb-number w-6 shrink-0 text-right text-[12px] font-bold text-hb-muted">
              {row.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

/** Detail hráče — karta, parametry, forma klubu a příští zápas. */
function FantasyPlayerScout({
  player,
  canReplace,
  onClose,
  onReplace,
}: {
  player: Player;
  canReplace: boolean;
  onClose: () => void;
  onReplace: () => void;
}) {
  const { teamById, matches } = useCatalog();
  const team = teamById(player.teamId);
  const rating = playerRating(player);
  const price = playerPrice(player);
  const points = fantasyPoints(player);
  const form = teamFormItems(matches, player.teamId);
  const next = useNextOpponent(player.teamId, matches);

  return (
    <div className="hb-enter absolute inset-0 z-40 flex flex-col bg-canvas">
      <ScreenHeader
        title={`${player.firstName.charAt(0)}. ${player.lastName}`}
        left={
          <button type="button" className="hb-fs-link px-2" onClick={onClose}>
            Zavřít
          </button>
        }
      />
      <div className="hb-scroll flex-1">
        <div
          className="flex flex-col items-center gap-3 px-4 pb-5 pt-5"
          style={{ background: "linear-gradient(180deg,#1b2430,#121820)" }}
        >
          <FantasyCard player={player} team={team} size="large" showPrice showPoints />
          <div className="text-center">
            <div className="text-[18px] font-bold text-white">{playerFullName(player)}</div>
            <div className="mt-1 text-[12px] font-medium text-white/60">
              {team?.shortName ?? "Tým"} · {positionLabel(player.position)} · #{player.number}
            </div>
          </div>
          <TierChip rating={rating} label={tierLabel(rating)} />
        </div>

        <div className="space-y-[18px] px-[var(--screen-pad)] py-4 pb-10">
          <div className="flex gap-2.5">
            <ScoutStat title="OVR" value={`${rating}`} />
            <ScoutStat title="CENA" value={`${price} kr`} />
            <ScoutStat title="ZÁPASY" value={`${player.games}`} />
            <ScoutStat title="FPTS" value={`${points}`} />
          </div>

          <AttributeBars player={player} />

          <div className="hb-card space-y-2.5 p-3.5">
            <SectionLabel>FORMA KLUBU</SectionLabel>
            <div className="flex items-center gap-3">
              {team && <TeamBadge team={team} size={28} />}
              {team && <span className="text-[15px] font-bold text-hb-fg">{team.shortName}</span>}
              <div className="ml-auto">
                <FormBadges items={form} size={22} />
              </div>
            </div>
          </div>

          <div className="hb-card space-y-2.5 p-3.5">
            <SectionLabel>PŘÍŠTÍ ZÁPAS</SectionLabel>
            {next ? (
              <div className="flex items-center gap-3">
                <TeamBadge team={next.opponent} size={36} />
                <div className="min-w-0 flex-1">
                  <div className="text-[16px] font-bold text-hb-fg">
                    {next.isHome
                      ? `Doma vs ${next.opponent.shortName}`
                      : `Venku @ ${next.opponent.shortName}`}
                  </div>
                  <div className="mt-1 text-[13px] font-medium text-hb-muted">
                    {formatFixtureDate(next.fixture.scheduledAt)}
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-[14px] text-hb-muted">Žádný nadcházející zápas.</div>
            )}
          </div>

          {canReplace && (
            <button type="button" onClick={onReplace} className="hb-brand-btn w-full">
              Vyměnit hráče
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// MARK: - Akční sheet nad hráčem v sestavě

function PlayerActionSheet({
  player,
  slot,
  editable,
  onDetail,
  onReplace,
  onRemove,
  onClose,
}: {
  player: Player;
  slot: FantasySlot;
  editable: boolean;
  onDetail: () => void;
  onReplace: () => void;
  onRemove: () => void;
  onClose: () => void;
}) {
  const { teamById } = useCatalog();
  const team = teamById(player.teamId);

  const action = (label: string, onClick: () => void, tone?: "danger") => (
    <button
      type="button"
      onClick={onClick}
      className={`hb-fs-action ${tone === "danger" ? "hb-fs-action--danger" : ""}`}
    >
      {label}
    </button>
  );

  return (
    <div className="absolute inset-0 z-40 flex flex-col justify-end">
      <button type="button" aria-label="Zavřít" className="hb-sheet-backdrop" onClick={onClose} />
      <div className="hb-sheet relative m-2.5 space-y-2">
        <div className="overflow-hidden rounded-[14px] bg-card">
          <div className="flex items-center gap-3 border-b border-[color-mix(in_srgb,var(--separator)_45%,transparent)] px-4 py-3">
            <FantasyCard player={player} team={team} size="compact" showPrice />
            <div className="min-w-0 flex-1">
              <div className="truncate text-[15px] font-bold text-hb-fg">{playerFullName(player)}</div>
              <div className="mt-0.5 text-[12px] font-medium text-hb-muted">
                {slotTitle(slot)} · {team?.shortName ?? "Tým"}
              </div>
            </div>
          </div>
          {action("Detail hráče", onDetail)}
          {editable && (
            <>
              <div className="h-px bg-[color-mix(in_srgb,var(--separator)_45%,transparent)]" />
              {action("Vyměnit hráče", onReplace)}
              <div className="h-px bg-[color-mix(in_srgb,var(--separator)_45%,transparent)]" />
              {action("Odebrat ze sestavy", onRemove, "danger")}
            </>
          )}
        </div>
        <button
          type="button"
          onClick={onClose}
          className="hb-fs-action hb-fs-action--brand hb-sheet-cancel"
        >
          Zrušit
        </button>
      </div>
    </div>
  );
}

// MARK: - Výběr hráče

function PickerRow({
  player,
  budget,
  taken,
  editable,
  marketMode,
  onPick,
  onDetail,
}: {
  player: Player;
  budget: number;
  taken: boolean;
  editable: boolean;
  marketMode: boolean;
  onPick: () => void;
  onDetail: () => void;
}) {
  const { teamById, matches } = useCatalog();
  const team = teamById(player.teamId);
  const price = playerPrice(player);
  const rating = playerRating(player);
  const points = fantasyPoints(player);
  const form = teamFormItems(matches, player.teamId, undefined, 4);
  const next = useNextOpponent(player.teamId, matches);
  const affordable = price <= budget || taken;

  return (
    <div className={`hb-card flex items-stretch gap-3 p-2.5 ${affordable ? "" : "opacity-50"}`}>
      <FantasyCard
        player={player}
        team={team}
        size="compact"
        showPrice={false}
        onClick={onDetail}
        ariaLabel={`Detail ${playerFullName(player)}`}
      />

      <button type="button" onClick={onDetail} className="flex min-w-0 flex-1 flex-col justify-center gap-1 text-left">
        <div className="truncate text-[15px] font-bold text-hb-fg">{playerFullName(player)}</div>
        <div className="truncate text-[12px] font-medium text-hb-muted">
          {team?.shortName ?? "Tým"} · {positionLabel(player.position)}
        </div>
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="rounded-full bg-card-inset px-2 py-0.5 text-[10px] font-bold text-hb-muted">
            OVR {rating}
          </span>
          <span className="rounded-full bg-card-inset px-2 py-0.5 text-[10px] font-bold text-hb-muted">
            {points} b
          </span>
          <TierChip rating={rating} label={tierLabel(rating)} />
        </div>
        <div className="flex items-center gap-2">
          <FormBadges items={form} size={16} />
          {next && (
            <span className="truncate text-[10px] font-semibold text-hb-faint">{next.label}</span>
          )}
        </div>
      </button>

      <div className="flex w-[62px] shrink-0 flex-col items-center justify-center gap-1.5">
        <div
          className={`hb-number text-[15px] font-extrabold ${affordable ? "text-hb-fg" : "text-loss"}`}
        >
          {price}
        </div>
        <div className="-mt-1 text-[9px] font-bold text-hb-faint">KREDITŮ</div>
        <button
          type="button"
          disabled={!editable || (!affordable && !taken)}
          onClick={onPick}
          className="hb-fantasy-add"
          data-taken={taken ? "true" : "false"}
          aria-label={taken ? "Už je v sestavě" : marketMode ? "Přidat do sestavy" : "Vybrat hráče"}
        >
          {taken ? "✓" : "+"}
        </button>
      </div>
    </div>
  );
}

function MarketPicker({
  slot,
  marketMode,
  players,
  onBack,
  onPicked,
  showToast,
}: {
  slot: FantasySlot;
  marketMode: boolean;
  players: Player[];
  onBack: () => void;
  onPicked: () => void;
  showToast: (text: string) => void;
}) {
  const fantasy = useFantasy();
  const { teamById, teams } = useCatalog();
  const [sort, setSort] = useState<MarketSort>("rating");
  const [clubFilter, setClubFilter] = useState<string | null>(null);
  const [affordableOnly, setAffordableOnly] = useState(false);
  const [query, setQuery] = useState("");
  const [scoutPlayer, setScoutPlayer] = useState<Player | null>(null);

  const need = slotPosition(slot);
  const playerById = useMemo(() => new Map(players.map((p) => [p.id, p])), [players]);
  const lineup = fantasy.lineupFor();

  /** Rozpočet pro tento slot = zbytek + cena hráče, kterého slot právě drží. */
  const budget = useMemo(() => {
    const remaining = fantasy.remainingBudget(playerById);
    if (marketMode) return remaining;
    const currentId = lineup[slot];
    const current = currentId ? playerById.get(currentId) : undefined;
    return remaining + (current ? playerPrice(current) : 0);
  }, [fantasy, playerById, lineup, slot, marketMode]);

  const pool = useMemo(
    () => (marketMode ? players : players.filter((p) => p.position === need)),
    [players, marketMode, need]
  );

  const clubs = useMemo(() => {
    const ids = new Set(pool.map((p) => p.teamId));
    return teams
      .filter((t) => ids.has(t.id))
      .sort((a, b) => a.shortName.localeCompare(b.shortName, "cs"));
  }, [pool, teams]);

  const market = useMemo(() => {
    let list = pool;
    const q = query.trim().toLowerCase();
    if (q) {
      list = list.filter((p) => {
        const team = teamById(p.teamId);
        return (
          playerFullName(p).toLowerCase().includes(q) ||
          (team?.shortName.toLowerCase().includes(q) ?? false) ||
          (team?.name.toLowerCase().includes(q) ?? false)
        );
      });
    }
    if (clubFilter) list = list.filter((p) => p.teamId === clubFilter);
    if (affordableOnly) {
      list = list.filter((p) => playerPrice(p) <= budget || fantasy.selectedPlayerIds.has(p.id));
    }
    const sorted = [...list];
    switch (sort) {
      case "rating":
        sorted.sort((a, b) => playerRating(b) - playerRating(a));
        break;
      case "price":
        sorted.sort((a, b) => playerPrice(b) - playerPrice(a));
        break;
      case "points":
        sorted.sort((a, b) => fantasyPoints(b) - fantasyPoints(a));
        break;
      case "name":
        sorted.sort((a, b) => a.lastName.localeCompare(b.lastName, "cs"));
        break;
    }
    return sorted;
  }, [pool, query, clubFilter, affordableOnly, budget, sort, teamById, fantasy.selectedPlayerIds]);

  /** Vloží hráče do slotu; v režimu trhu do prvního volného slotu jeho pozice. */
  const pick = (p: Player) => {
    if (!fantasy.isViewingEditable) {
      showToast("Toto kolo nejde upravovat (deadline sobota 10:00).");
      return;
    }
    let target = slot;
    if (marketMode) {
      const candidates = FANTASY_SLOTS.filter((s) => slotPosition(s) === p.position);
      target = candidates.find((s) => !lineup[s]) ?? candidates[0]!;
    }
    const err = fantasy.setSlot(target, p, playerById);
    if (err) {
      showToast(err);
      return;
    }
    if (marketMode) {
      showToast(`${p.lastName} přidán do sestavy`);
      return;
    }
    onPicked();
  };

  return (
    <div className="hb-enter relative flex min-h-0 flex-1 flex-col">
      <ScreenHeader
        title={marketMode ? "Hráčský trh" : slotTitle(slot)}
        left={<BackButton onClick={onBack} />}
      />

      <div className="shrink-0 space-y-2.5 border-b border-separator/40 bg-surface px-[var(--screen-pad)] pb-3 pt-2.5">
        <div className="flex items-center gap-2 rounded-[12px] bg-card-inset px-3 py-2.5">
          <span className="text-hb-faint">
            <IconSearch size={15} />
          </span>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Hledat hráče nebo klub"
            className="hb-fs-input min-w-0 flex-1 bg-transparent outline-none placeholder:text-hb-faint"
          />
          {query && (
            <button type="button" onClick={() => setQuery("")} className="hb-fs-link hb-fs-link--sm">
              Zrušit
            </button>
          )}
        </div>

        <div className="flex items-center justify-between gap-2">
          <span className="text-[12px] font-bold text-hb-muted">
            {marketMode ? "Extraliga" : `Na tento slot zbývá `}
            {!marketMode && (
              <span className="hb-number text-hb-fg">{budget} kr</span>
            )}
          </span>
          <span className="text-[12px] font-semibold text-hb-faint">
            {market.length}{" "}
            {market.length === 1 ? "hráč" : market.length >= 2 && market.length <= 4 ? "hráči" : "hráčů"}
          </span>
        </div>

        <div className="hb-seg">
          {SORT_OPTIONS.map((option) => (
            <button
              key={option.id}
              type="button"
              className="hb-seg-item"
              data-active={sort === option.id}
              onClick={() => setSort(option.id)}
            >
              {option.label}
            </button>
          ))}
        </div>

        <PillTrack inset={false} className="!p-0">
          {!marketMode && (
            <Pill active={affordableOnly} onClick={() => setAffordableOnly((v) => !v)}>
              V rozpočtu
            </Pill>
          )}
          <Pill active={clubFilter == null} onClick={() => setClubFilter(null)}>
            Všechny kluby
          </Pill>
          {clubs.map((t) => (
            <Pill key={t.id} active={clubFilter === t.id} onClick={() => setClubFilter(t.id)}>
              {t.shortName}
            </Pill>
          ))}
        </PillTrack>
      </div>

      <div className="hb-scroll min-h-0 flex-1 space-y-2.5 px-[var(--screen-pad)] py-3 pb-7">
        {!fantasy.isViewingEditable && (
          <div className="rounded-[10px] bg-card-inset px-3 py-2.5 text-[12px] font-semibold text-hb-muted">
            Prohlížíš jiné kolo — hráče teď nejde přidávat.
          </div>
        )}
        {market.map((p) => (
          <PickerRow
            key={p.id}
            player={p}
            budget={budget}
            taken={fantasy.selectedPlayerIds.has(p.id)}
            editable={fantasy.isViewingEditable}
            marketMode={marketMode}
            onPick={() => pick(p)}
            onDetail={() => setScoutPlayer(p)}
          />
        ))}
        {!market.length && (
          <EmptyState title="Žádní hráči" hint="Zkus jiný filtr, klub nebo hledaný výraz." />
        )}
      </div>

      {scoutPlayer && (
        <FantasyPlayerScout
          player={scoutPlayer}
          canReplace={fantasy.isViewingEditable}
          onClose={() => setScoutPlayer(null)}
          onReplace={() => {
            const p = scoutPlayer;
            setScoutPlayer(null);
            pick(p);
          }}
        />
      )}
    </div>
  );
}

// MARK: - Hřiště se sestavou

function Pitch({
  playerById,
  editable,
  onSlotTap,
  onPlayerTap,
  matches,
}: {
  playerById: Map<string, Player>;
  editable: boolean;
  onSlotTap: (slot: FantasySlot) => void;
  onPlayerTap: (slot: FantasySlot, player: Player) => void;
  matches: Match[];
}) {
  const fantasy = useFantasy();
  const { teamById } = useCatalog();
  const lineup = fantasy.lineupFor();

  return (
    <RinkSurface>
      <div className="space-y-3 px-2 py-4">
        {LINES.map((line, index) => (
          <div key={line.label}>
            {index > 0 && <div className="hb-rink-line mx-4 mb-3" />}
            <div className="mb-2 text-center text-[9px] font-bold tracking-[1.2px] text-white/50">
              {line.label}
            </div>
            <div className="flex justify-center gap-2.5">
              {line.slots.map((slot) => {
                const id = lineup[slot];
                const player = id ? playerById.get(id) : undefined;
                if (!player) {
                  return (
                    <FantasyEmptyCard
                      key={slot}
                      positionCode={slotShortTitle(slot)}
                      title={editable ? "Přidat" : "Prázdné"}
                      onClick={editable ? () => onSlotTap(slot) : undefined}
                    />
                  );
                }
                const fixture = nextFantasyFixture(player.teamId, matches);
                const isHome = fixture ? fixture.homeTeamId === player.teamId : false;
                const opponent = fixture
                  ? teamById(isHome ? fixture.awayTeamId : fixture.homeTeamId)
                  : undefined;
                return (
                  <FantasyCard
                    key={slot}
                    player={player}
                    team={teamById(player.teamId)}
                    opponentLabel={opponent ? `${isHome ? "vs" : "@"} ${opponent.shortName}` : null}
                    showPrice
                    onClick={() => onPlayerTap(slot, player)}
                    ariaLabel={`${playerFullName(player)} — ${slotTitle(slot)}`}
                  />
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </RinkSurface>
  );
}

// MARK: - Obrazovka

export function FantasyScreen({
  screen = "hub",
}: {
  screen?: "hub" | "team" | "market" | "leaderboard" | "rules";
}) {
  const { pop, push, replace } = useNav();
  const fantasy = useFantasy();
  const { teamById, matches, competitions, players: catalogPlayers } = useCatalog();
  const [slotPick, setSlotPick] = useState<FantasySlot | null>(null);
  const [action, setAction] = useState<{ slot: FantasySlot; player: Player } | null>(null);
  const [scout, setScout] = useState<{ slot: FantasySlot; player: Player } | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const extraligaIds = useMemo(
    () => new Set(competitions.filter((c) => c.slug === "extraliga").map((c) => c.id)),
    [competitions]
  );

  const players = useMemo(() => {
    const filtered = catalogPlayers.filter((p) => {
      if (p.competitionId && extraligaIds.has(p.competitionId)) return true;
      if (extraligaIds.size === 0) return true;
      // fallback: bez competitionId bereme hráče (katalog je často scoped sezónou)
      return !p.competitionId;
    });
    return [...filtered].sort((a, b) => playerRating(b) - playerRating(a));
  }, [catalogPlayers, extraligaIds]);

  const lineup = fantasy.lineupFor();
  const playerById = useMemo(() => new Map(players.map((p) => [p.id, p])), [players]);
  const spent = fantasy.spentCredits(playerById);
  const remaining = fantasy.budget - spent;
  const squadPoints = fantasy.squadPoints(playerById);

  const roundFixtures = useMemo(() => {
    const gw = fantasy.viewingGameweek;
    return matches
      .filter((m) => extraligaIds.has(m.competitionId) && m.round === gw)
      .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt))
      .slice(0, 12);
  }, [matches, extraligaIds, fantasy.viewingGameweek]);

  const showToast = (text: string) => {
    setToast(text);
    window.setTimeout(() => setToast(null), 2200);
  };

  const handleSave = () => {
    if (!fantasy.isViewingEditable) {
      showToast("Toto kolo nejde upravovat (deadline sobota 10:00).");
      return;
    }
    const err = fantasy.saveLineup();
    if (err) showToast(err);
    else showToast(`Sestava ${fantasy.activeGameweek}. kola uložena`);
  };

  const toastNode = toast ? (
    <div className="pointer-events-none absolute inset-x-0 bottom-6 z-50 flex justify-center px-6">
      <div className="rounded-full bg-ink/92 px-4 py-3 text-center text-[13px] font-bold text-white shadow-lg">
        {toast}
      </div>
    </div>
  ) : null;

  // MARK: Pravidla

  if (screen === "rules") {
    const rules: { title: string; text: string; badge: string }[] = [
      {
        badge: "1B·2O·3Ú",
        title: "Týdenní sestava",
        text: "Každé kolo máš vlastní sestavu — 1 brankář, 2 obránci a 3 útočníci.",
      },
      {
        badge: "SO 10:00",
        title: "Deadline",
        text: "Uzávěrka je vždy v sobotu v 10:00 (Praha). Poté je sestava zamčená a hraje tak, jak jsi ji uložil.",
      },
      {
        badge: `${fantasy.budget} kr`,
        title: "Rozpočet",
        text: "Cena hráče je 4–15 kreditů podle jeho OVR. Nesmíš rozpočet překročit.",
      },
      {
        badge: "MAX 2",
        title: "Kluby",
        text: "Z jednoho klubu můžeš mít nejvýš dva hráče.",
      },
      {
        badge: "OVR",
        title: "Rating",
        text: "OVR vychází z parametrů hráče (rychlost, síla, střela…). Když parametry chybí, spočítá se ze statistik.",
      },
      {
        badge: "3 · 2",
        title: "Body",
        text: "Gól 3 body, asistence 2 body, brankáři bonusy za výhru a čisté konto. Sčítají se po uzávěrce kola.",
      },
      {
        badge: "ULOŽIT",
        title: "Nezapomeň uložit",
        text: "Bez uložení sestavy se kolo nezapočítá do žebříčku.",
      },
    ];

    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Pravidla" left={<BackButton onClick={pop} />} />
        <div className="flex flex-col gap-2.5 px-[var(--screen-pad)] pb-8 pt-3">
          {rules.map((rule) => (
            <div key={rule.title} className="hb-card flex gap-3 p-3.5">
              <span className="flex h-[38px] w-[52px] shrink-0 items-center justify-center rounded-[9px] bg-[color-mix(in_srgb,var(--brand)_12%,transparent)] text-center text-[10px] font-extrabold leading-tight text-brand">
                {rule.badge}
              </span>
              <div className="min-w-0 flex-1 space-y-1">
                <div className="text-[15px] font-bold text-hb-fg">{rule.title}</div>
                <p className="text-[13px] font-medium leading-snug text-hb-muted">{rule.text}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  // MARK: Žebříček

  if (screen === "leaderboard") {
    const board = [
      { name: "Hostivař Ultra", pts: Math.max(0, fantasy.seasonPoints + 12), you: false },
      { name: "Lední žraloci", pts: Math.max(0, fantasy.seasonPoints + 4), you: false },
      { name: fantasy.teamName, pts: fantasy.seasonPoints, you: true },
      { name: "Pardubický sen", pts: Math.max(0, fantasy.seasonPoints - 3), you: false },
      { name: "Plzeňský expres", pts: Math.max(0, fantasy.seasonPoints - 9), you: false },
    ].sort((a, b) => b.pts - a.pts);

    const podium = [board[1], board[0], board[2]].filter(Boolean);
    const podiumHeights = [58, 76, 46];
    const podiumColors = ["#b8bdc7", "#f2c747", "#c98a4b"];
    const podiumRanks = [2, 1, 3];

    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Žebříček" left={<BackButton onClick={pop} />} />

        <div
          className="flex items-end justify-center gap-2.5 px-4 pb-4 pt-6"
          style={{ background: "linear-gradient(180deg,#1b2430,#121820)" }}
        >
          {podium.map((row, i) => (
            <div key={row.name + i} className="flex w-[92px] flex-col items-center gap-2">
              <div
                className="flex h-8 w-8 items-center justify-center rounded-full text-[13px] font-extrabold text-ink"
                style={{ background: podiumColors[i] }}
              >
                {podiumRanks[i]}
              </div>
              <div className="line-clamp-2 text-center text-[11px] font-bold leading-tight text-white">
                {row.name}
              </div>
              <div
                className="flex w-full items-start justify-center rounded-t-[10px] pt-2"
                style={{
                  height: podiumHeights[i],
                  background: `linear-gradient(180deg, color-mix(in srgb, ${podiumColors[i]} 70%, transparent), color-mix(in srgb, ${podiumColors[i]} 25%, transparent))`,
                }}
              >
                <span className="hb-number text-[15px] font-extrabold text-white">{row.pts}</span>
              </div>
            </div>
          ))}
        </div>

        <div className="px-[var(--screen-pad)] py-3 pb-8">
          <div className="hb-card overflow-hidden">
            {board.map((row, i) => (
              <div
                key={row.name + i}
                className={`flex items-center gap-3 px-3.5 py-3 ${
                  row.you ? "bg-[color-mix(in_srgb,var(--brand)_8%,transparent)]" : ""
                } ${i > 0 ? "border-t border-[color-mix(in_srgb,var(--separator)_45%,transparent)]" : ""}`}
              >
                <span
                  className={`hb-number w-7 text-[16px] font-extrabold ${
                    row.you ? "text-brand" : "text-hb-muted"
                  }`}
                >
                  {i + 1}
                </span>
                <span
                  className={`min-w-0 flex-1 truncate text-[15px] ${
                    row.you ? "font-bold" : "font-semibold"
                  } text-hb-fg`}
                >
                  {row.name}
                  {row.you && (
                    <span className="ml-2 rounded-full bg-brand px-1.5 py-0.5 text-[9px] font-bold text-white align-middle">
                      TY
                    </span>
                  )}
                </span>
                <span className="hb-number text-[15px] font-bold text-hb-muted">{row.pts} b</span>
              </div>
            ))}
          </div>
          <p className="mt-3 px-1 text-[12px] font-medium leading-snug text-hb-muted">
            Zatím lokální demo — po prvním vyhodnocení kola se objeví reálné pořadí všech hráčů.
          </p>
        </div>
      </div>
    );
  }

  // MARK: Trh / výběr hráče

  if (screen === "market" || slotPick) {
    return (
      <>
        <MarketPicker
          slot={slotPick ?? "F1"}
          marketMode={screen === "market" && !slotPick}
          players={players}
          onBack={() => {
            setSlotPick(null);
            if (screen === "market") pop();
          }}
          onPicked={() => {
            setSlotPick(null);
            replace({ name: "fantasy", screen: "team" });
          }}
          showToast={showToast}
        />
        {toastNode}
      </>
    );
  }

  // MARK: Můj tým

  if (screen === "team") {
    const editable = fantasy.isViewingEditable;
    const complete = fantasy.filledCount === 6;

    return (
      <div className="hb-enter relative flex min-h-0 flex-1 flex-col">
        <ScreenHeader
          title="Můj tým"
          left={<BackButton onClick={pop} />}
          right={
            editable && fantasy.filledCount > 0 ? (
              <button
                type="button"
                className="hb-fs-link hb-fs-link--sm px-2"
                onClick={() => fantasy.clearLineup()}
              >
                Vymazat
              </button>
            ) : undefined
          }
        />

        <div className="hb-scroll relative min-h-0 flex-1" style={DARK_CANVAS}>
          <div className="flex flex-col gap-3.5 px-[var(--screen-pad)] pb-6 pt-3">
            {!editable && (
              <div className="rounded-[10px] bg-white/10 px-3 py-2.5 text-[12px] font-semibold text-white/75">
                Prohlížíš jiné kolo — sestava je jen ke čtení.
              </div>
            )}

            <div className="rounded-[14px] p-3.5" style={{ background: "rgba(255,255,255,0.07)" }}>
              <div className="flex items-center gap-2">
                <input
                  value={fantasy.teamName}
                  onChange={(e) => editable && fantasy.setTeamName(e.target.value)}
                  disabled={!editable}
                  className="hb-fs-team-name min-w-0 flex-1 bg-transparent outline-none placeholder:text-white/35 disabled:opacity-70"
                  placeholder="Název týmu"
                />
                {editable && <span className="text-[11px] font-semibold text-white/40">upravit</span>}
              </div>
              <div className="mt-3 flex items-center justify-between text-[11px] font-bold">
                <span className="text-white/55">ROZPOČET</span>
                <span className="hb-number text-white">
                  {spent} / {fantasy.budget} kr
                </span>
              </div>
              <div className="mt-1.5">
                <BudgetBar spent={spent} budget={fantasy.budget} />
              </div>
            </div>

            <div className="flex gap-2">
              <StatCell label="SESTAVA" value={`${fantasy.filledCount}/6`} tone="dark" />
              <StatCell label="ZBÝVÁ" value={`${remaining}`} hint="kreditů" tone="dark" />
              <StatCell label="BODY" value={`${fantasy.seasonPoints}`} hint="sezóna" tone="dark" />
              <StatCell label="SÍLA" value={`${squadPoints}`} hint="sestava" tone="dark" />
            </div>

            <Pitch
              playerById={playerById}
              editable={editable}
              matches={matches}
              onSlotTap={(slot) => setSlotPick(slot)}
              onPlayerTap={(slot, player) => setAction({ slot, player })}
            />

            <p className="px-1 text-[12px] font-medium leading-snug text-white/55">
              {editable
                ? "Klepni na prázdný slot a vyber hráče. Klepnutím na kartu otevřeš detail, výměnu nebo odebrání."
                : "Minulé kolo — změny nejsou povolené."}
            </p>
          </div>
        </div>

        <div
          className="shrink-0 px-4 py-3"
          style={{ background: "linear-gradient(135deg,var(--brand),var(--brand-dark))" }}
        >
          <div className="flex items-center gap-3">
            <div className="min-w-0 flex-1">
              <div className="mb-1.5 text-[10px] font-bold tracking-[0.6px] text-white/65">
                {editable ? "DO UZÁVĚRKY SESTAVY" : "SESTAVA UZAMČENA"}
              </div>
              <Countdown deadline={fantasy.deadline} />
            </div>
            <button
              type="button"
              disabled={!editable || !complete}
              onClick={handleSave}
              className="hb-fs-save"
            >
              {!editable
                ? "UZAMČENO"
                : complete
                  ? "ULOŽIT\nSESTAVU"
                  : `CHYBÍ\n${6 - fantasy.filledCount} HRÁČI`}
            </button>
          </div>
        </div>

        {action && (
          <PlayerActionSheet
            player={action.player}
            slot={action.slot}
            editable={editable}
            onClose={() => setAction(null)}
            onDetail={() => {
              setScout(action);
              setAction(null);
            }}
            onReplace={() => {
              setSlotPick(action.slot);
              setAction(null);
            }}
            onRemove={() => {
              fantasy.removeSlot(action.slot);
              setAction(null);
              showToast(`${action.player.lastName} odebrán ze sestavy`);
            }}
          />
        )}

        {scout && (
          <FantasyPlayerScout
            player={scout.player}
            canReplace={editable}
            onClose={() => setScout(null)}
            onReplace={() => {
              setSlotPick(scout.slot);
              setScout(null);
            }}
          />
        )}

        {toastNode}
      </div>
    );
  }

  // MARK: Hub

  const isArchive = fantasy.viewingGameweek !== fantasy.activeGameweek;

  return (
    <div className="hb-enter flex min-h-0 flex-1 flex-col">
      <ScreenHeader title="Fantasy" subtitle="Extraliga" left={<BackButton onClick={pop} />} />
      <div className="hb-scroll relative min-h-0 flex-1">
        <div className="flex flex-col gap-[18px] px-[var(--screen-pad)] pb-8 pt-3">
          {/* Hero — kolo + odpočet */}
          <div className="hb-fantasy-hero overflow-hidden rounded-[18px] p-3.5">
            <div className="flex items-center gap-2">
              <button
                type="button"
                disabled={fantasy.viewingGameweek <= 1}
                onClick={() => fantasy.setViewingGameweek(fantasy.viewingGameweek - 1)}
                className="hb-fs-round"
                aria-label="Předchozí kolo"
              >
                <IconChevronLeft size={14} />
              </button>
              <div className="flex-1 text-center">
                <div className="hb-display text-[20px] leading-tight text-white">
                  {fantasy.viewingGameweek}. KOLO
                </div>
                {isArchive && (
                  <span className="mt-0.5 inline-block rounded-full bg-white/12 px-2 py-0.5 text-[9px] font-bold tracking-[0.5px] text-white/70">
                    ARCHIV
                  </span>
                )}
              </div>
              <button
                type="button"
                onClick={() => fantasy.setViewingGameweek(fantasy.viewingGameweek + 1)}
                className="hb-fs-round"
                aria-label="Další kolo"
              >
                <IconChevronRight size={14} />
              </button>
            </div>

            <div className="mt-3.5 flex items-end justify-between gap-3">
              <div>
                <div className="mb-1.5 text-[10px] font-bold tracking-[0.6px] text-white/50">
                  DO UZÁVĚRKY
                </div>
                <Countdown deadline={fantasy.deadline} />
              </div>
              <div className="text-right">
                <div className="text-[10px] font-bold tracking-[0.6px] text-white/50">MOJE BODY</div>
                <div className="hb-number text-[26px] font-extrabold leading-tight text-white">
                  {fantasy.seasonPoints}
                </div>
              </div>
            </div>
          </div>

          {/* Moje sestava */}
          <div>
            <div className="mb-2.5 flex items-end justify-between gap-2">
              <SectionLabel>MOJE SESTAVA</SectionLabel>
              <span className="text-[11px] font-bold text-hb-muted">
                {fantasy.filledCount}/6 · {remaining} kr zbývá
              </span>
            </div>
            <div className="hb-card overflow-hidden p-3">
              <div className="hb-day-strip flex gap-2 overflow-x-auto pb-1">
                {FANTASY_SLOTS.map((slot) => {
                  const id = lineup[slot];
                  const player = id ? playerById.get(id) : undefined;
                  if (!player) {
                    return (
                      <FantasyEmptyCard
                        key={slot}
                        size="compact"
                        tone="light"
                        positionCode={slotShortTitle(slot)}
                        title="Přidat"
                        onClick={() => push({ name: "fantasy", screen: "team" })}
                      />
                    );
                  }
                  return (
                    <FantasyCard
                      key={slot}
                      player={player}
                      team={teamById(player.teamId)}
                      size="compact"
                      showPrice
                      onClick={() => push({ name: "fantasy", screen: "team" })}
                      ariaLabel={`${playerFullName(player)} — ${slotTitle(slot)}`}
                    />
                  );
                })}
              </div>
              <div className="mt-3">
                <BudgetBar spent={spent} budget={fantasy.budget} tone="light" />
              </div>
              <button
                type="button"
                onClick={() => push({ name: "fantasy", screen: "team" })}
                className="hb-brand-btn mt-3 w-full"
              >
                {fantasy.filledCount === 6 ? "Upravit sestavu" : "Doplnit sestavu"}
              </button>
              {fantasy.hasUnsavedChanges && (
                <div className="mt-2 text-center text-[11px] font-bold text-draw">
                  Máš neuložené změny sestavy.
                </div>
              )}
            </div>
          </div>

          {/* Rozcestník */}
          <div className="grid grid-cols-2 gap-2.5">
            <MenuTile
              icon={<IconUser size={18} />}
              title="Můj tým"
              subtitle="Sestav hráče na hřišti"
              onClick={() => push({ name: "fantasy", screen: "team" })}
            />
            <MenuTile
              icon={<IconStack size={18} />}
              title="Hráčský trh"
              subtitle="Prohlédni si všechny karty"
              onClick={() => push({ name: "fantasy", screen: "market" })}
            />
            <MenuTile
              icon={<IconTrophy size={18} />}
              title="Žebříček"
              subtitle="Pořadí za sezónu"
              onClick={() => push({ name: "fantasy", screen: "leaderboard" })}
            />
            <MenuTile
              icon={
                <svg width={18} height={18} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                  <path d="M6 4h9a3 3 0 0 1 3 3v13l-1.5-.9L15 20.2l-1.5-1.1L12 20.2l-1.5-1.1L9 20.2l-1.5-1.1L6 20V4zm2 4v2h7V8H8zm0 4v2h5v-2H8z" />
                </svg>
              }
              title="Pravidla"
              subtitle="Body, rozpočet, uzávěrka"
              onClick={() => push({ name: "fantasy", screen: "rules" })}
            />
          </div>

          {/* Zápasy kola */}
          <div>
            <div className="mb-2.5">
              <SectionLabel>ZÁPASY {fantasy.viewingGameweek}. KOLA</SectionLabel>
            </div>
            {roundFixtures.length ? (
              <div className="hb-card overflow-hidden py-1">
                {roundFixtures.map((m, i) => (
                  <FixtureRow key={m.id} match={m} last={i === roundFixtures.length - 1} />
                ))}
              </div>
            ) : (
              <div className="hb-card p-3.5 text-[13px] font-medium text-hb-muted">
                Pro toto kolo zatím nejsou zápasy.
              </div>
            )}
          </div>

          <p className="px-1 text-[12px] font-medium leading-snug text-hb-muted">
            Lokální demo — body a žebříček zatím jen na tomto zařízení.
          </p>
        </div>

        {toastNode}
      </div>
    </div>
  );
}

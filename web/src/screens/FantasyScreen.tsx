"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import {
  IconChevronLeft,
  IconChevronRight,
  IconStack,
  IconTrophy,
  IconUser,
} from "@/components/Icons";
import { TeamBadge } from "@/components/Badges";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import type { Match, Player } from "@/lib/types";
import { playerFullName, positionLabel } from "@/lib/types";
import {
  fantasyPoints,
  nextFantasyFixture,
  playerPrice,
  playerRating,
  slotPosition,
  tierLabel,
  useFantasy,
  type FantasySlot,
} from "@/stores/fantasy";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";
import { teamFormColor, teamFormItems, teamFormLetter } from "@/lib/teamForm";

type MarketSort = "rating" | "price" | "points" | "name";

const SORT_PILLS: { id: MarketSort; label: string }[] = [
  { id: "rating", label: "OVR" },
  { id: "price", label: "Cena" },
  { id: "points", label: "Body" },
  { id: "name", label: "Jméno" },
];

function formatFixtureDate(iso: string) {
  try {
    return new Intl.DateTimeFormat("cs-CZ", {
      weekday: "long",
      day: "numeric",
      month: "numeric",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "Europe/Prague",
    }).format(new Date(iso));
  } catch {
    return iso.slice(0, 16);
  }
}

function ScoutStat({ title, value }: { title: string; value: string }) {
  return (
    <div className="flex-1 rounded-[10px] bg-card-inset px-1 py-2.5 text-center">
      <div className="text-[10px] font-bold text-hb-faint">{title}</div>
      <div className="hb-number mt-0.5 text-[15px] font-extrabold text-hb-fg">{value}</div>
    </div>
  );
}

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
  const tier = tierLabel(rating);
  const price = playerPrice(player);
  const pts = fantasyPoints(player);
  const form = teamFormItems(matches, player.teamId);
  const fixture = nextFantasyFixture(player.teamId, matches);
  const isHome = fixture ? fixture.homeTeamId === player.teamId : false;
  const opp = fixture
    ? teamById(isHome ? fixture.awayTeamId : fixture.homeTeamId)
    : undefined;

  return (
    <div className="absolute inset-0 z-40 flex flex-col bg-canvas hb-enter">
      <ScreenHeader
        title={`${player.firstName.charAt(0)}. ${player.lastName}`}
        left={
          <button type="button" className="px-2 text-[15px] font-bold text-brand" onClick={onClose}>
            Zavřít
          </button>
        }
      />
      <div className="hb-scroll flex-1 px-4 py-4 pb-10">
        <div className="space-y-[18px]">
          <div className="hb-card flex items-center gap-3 p-4">
            {team && <TeamBadge team={team} size={48} />}
            <div className="min-w-0 flex-1">
              <div className="truncate text-[18px] font-bold text-hb-fg">{playerFullName(player)}</div>
              <div className="mt-1 text-[13px] font-medium text-hb-muted">
                {team?.shortName ?? "Tým"} · {positionLabel(player.position)} · #{player.number}
              </div>
            </div>
          </div>

          <div className="flex gap-2.5">
            <ScoutStat title="OVR" value={`${rating}`} />
            <ScoutStat title="Cena" value={`${price} kr`} />
            <ScoutStat title="Tier" value={tier} />
            <ScoutStat title="FPTS" value={`${pts}`} />
          </div>

          <div className="hb-card space-y-2.5 p-3.5">
            <div className="text-[11px] font-bold tracking-[0.6px] text-hb-faint">FORMA KLUBU</div>
            <div className="flex items-center gap-3">
              {team && <TeamBadge team={team} size={28} />}
              {team && <span className="text-[15px] font-bold">{team.shortName}</span>}
              <div className="ml-auto flex gap-1">
                {form.map((f) => (
                  <span
                    key={f.id}
                    className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold text-white"
                    style={{ background: teamFormColor(f.outcome) }}
                  >
                    {teamFormLetter(f.outcome)}
                  </span>
                ))}
                {!form.length && <span className="text-[12px] text-hb-muted">—</span>}
              </div>
            </div>
          </div>

          <div className="hb-card space-y-2.5 p-3.5">
            <div className="text-[11px] font-bold tracking-[0.6px] text-hb-faint">PŘÍŠTÍ ZÁPAS</div>
            {fixture && team ? (
              <div className="flex items-center gap-3">
                {opp && <TeamBadge team={opp} size={36} />}
                <div className="min-w-0 flex-1">
                  <div className="text-[16px] font-bold text-hb-fg">
                    {isHome
                      ? `Doma vs ${opp?.shortName ?? "soupeř"}`
                      : `Venku @ ${opp?.shortName ?? "soupeř"}`}
                  </div>
                  <div className="mt-1 text-[13px] font-medium text-hb-muted">
                    {formatFixtureDate(fixture.scheduledAt)}
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

const SLOT_LABEL: Record<FantasySlot, string> = {
  G: "Brankář",
  D1: "Obránce 1",
  D2: "Obránce 2",
  F1: "Útočník 1",
  F2: "Útočník 2",
  F3: "Útočník 3",
};

/** Sobota 10:00 — viz FantasyDeadline.upcomingDeadline (UI countdown). */
function nextSaturdayDeadline(from = new Date()): Date {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Prague",
    weekday: "short",
    hour: "2-digit",
    hour12: false,
  }).formatToParts(from);
  const weekday = parts.find((p) => p.type === "weekday")?.value ?? "Mon";
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const weekdayIndex: Record<string, number> = {
    Sun: 0,
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
  };
  const wd = weekdayIndex[weekday] ?? 0;
  let daysUntil = (6 - wd + 7) % 7;
  if (daysUntil === 0 && hour >= 10) daysUntil = 7;
  const approx = new Date(from.getTime() + daysUntil * 86_400_000);
  approx.setHours(10, 0, 0, 0);
  return approx;
}

function countdownParts(to: Date, from = new Date()) {
  const interval = Math.max(0, Math.floor((to.getTime() - from.getTime()) / 1000));
  return {
    days: Math.floor(interval / 86_400),
    hours: Math.floor((interval % 86_400) / 3600),
    minutes: Math.floor((interval % 3600) / 60),
    seconds: interval % 60,
  };
}

function pad2(n: number) {
  return String(n).padStart(2, "0");
}

function MenuRow({
  icon,
  title,
  onClick,
  last,
}: {
  icon: ReactNode;
  title: string;
  onClick: () => void;
  last?: boolean;
}) {
  return (
    <>
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-center gap-3.5 px-3.5 py-3.5 text-left"
      >
        <span className="flex h-7 w-7 shrink-0 items-center justify-center text-brand [&_svg]:h-4 [&_svg]:w-4">
          {icon}
        </span>
        <span className="min-w-0 flex-1 text-[16px] font-semibold text-hb-fg">{title}</span>
        <span className="text-hb-faint">
          <IconChevronRight size={12} />
        </span>
      </button>
      {!last && (
        <div className="ml-14 h-px bg-[color-mix(in_srgb,var(--separator)_50%,transparent)]" />
      )}
    </>
  );
}

function FantasyStatTile({
  title,
  value,
  featured,
}: {
  title: string;
  value: string;
  featured?: boolean;
}) {
  return (
    <div className="overflow-hidden rounded-[12px] border border-card-stroke bg-card">
      <div className="bg-brand px-2 py-1.5 text-center text-[10px] font-bold tracking-[0.4px] text-on-brand uppercase">
        {title}
      </div>
      <div
        className={`hb-number text-center text-hb-fg ${featured ? "py-3.5 text-[28px]" : "py-2.5 text-[22px]"} font-extrabold`}
      >
        {value}
      </div>
    </div>
  );
}

function RuleCard({ title, text }: { title: string; text: string }) {
  return (
    <div className="hb-card space-y-1.5 p-3.5">
      <div className="text-[15px] font-bold text-hb-fg">{title}</div>
      <p className="text-[13px] font-medium leading-snug text-hb-muted">{text}</p>
    </div>
  );
}

function DeadlineBar({
  locked,
  onSave,
}: {
  locked: boolean;
  onSave: () => void;
}) {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(id);
  }, []);
  const parts = countdownParts(nextSaturdayDeadline(now), now);

  return (
    <div className="shrink-0 bg-[linear-gradient(135deg,var(--brand),var(--brand-dark))] px-4 py-3.5 shadow-[0_-4px_16px_color-mix(in_srgb,var(--brand)_35%,transparent)]">
      <div className="flex items-center gap-3">
        <div className="min-w-0 flex-1">
          <div className="text-[10px] font-bold tracking-[0.6px] text-white/70">DEADLINE SESTAVY</div>
          <div className="mt-1.5 flex items-center gap-1.5">
            {(
              [
                [parts.days, "DNY"],
                [parts.hours, "HOD."],
                [parts.minutes, "MIN."],
                [parts.seconds, "SEK."],
              ] as const
            ).map(([v, label], i) => (
              <div key={label} className="flex items-center gap-1.5">
                {i > 0 && <span className="hb-number text-[16px] font-extrabold text-white/55">:</span>}
                <div className="text-center">
                  <div className="hb-number text-[18px] font-extrabold text-white tabular-nums">
                    {pad2(v)}
                  </div>
                  <div className="text-[8px] font-bold text-white/55">{label}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
        <button
          type="button"
          disabled={locked}
          onClick={onSave}
          className="w-[108px] rounded-[12px] bg-[#ffd647] py-3.5 text-center text-[12px] font-extrabold text-ink disabled:opacity-45"
        >
          {locked ? "UZAMČENO" : "ULOŽIT SESTAVU"}
        </button>
      </div>
    </div>
  );
}

function FixtureChip({ match }: { match: Match }) {
  const { teamById } = useCatalog();
  const home = teamById(match.homeTeamId);
  const away = teamById(match.awayTeamId);
  const time = useMemo(() => {
    try {
      return new Intl.DateTimeFormat("cs-CZ", {
        weekday: "short",
        day: "numeric",
        month: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        timeZone: "Europe/Prague",
      }).format(new Date(match.scheduledAt));
    } catch {
      return match.scheduledAt.slice(0, 16);
    }
  }, [match.scheduledAt]);

  return (
    <div className="flex items-center gap-1.5 rounded-[10px] border border-card-stroke bg-card px-2 py-2.5">
      {home && <TeamBadge team={home} size={22} />}
      <span className="min-w-0 flex-1 truncate text-center text-[10px] font-bold text-hb-muted">
        {time}
      </span>
      {away && <TeamBadge team={away} size={22} />}
    </div>
  );
}

function SlotOpponentChip({
  teamId,
  matches,
}: {
  teamId: string;
  matches: Match[];
}) {
  const { teamById } = useCatalog();
  const fixture = nextFantasyFixture(teamId, matches);
  if (!fixture) return null;
  const isHome = fixture.homeTeamId === teamId;
  const opp = teamById(isHome ? fixture.awayTeamId : fixture.homeTeamId);
  if (!opp) return null;
  return (
    <span className="mt-1 max-w-full truncate rounded-full bg-white/15 px-1.5 py-0.5 text-[9px] font-bold text-white/80">
      {isHome ? "vs" : "@"} {opp.shortName}
    </span>
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
  const { teamById, matches, teams } = useCatalog();
  const [sort, setSort] = useState<MarketSort>("rating");
  const [clubFilter, setClubFilter] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [scoutPlayer, setScoutPlayer] = useState<Player | null>(null);

  const need = slotPosition(slot);
  const playerById = useMemo(() => new Map(players.map((p) => [p.id, p])), [players]);
  const remaining = fantasy.remainingBudget(playerById);

  const clubs = useMemo(() => {
    const ids = new Set(players.filter((p) => p.position === need).map((p) => p.teamId));
    return teams
      .filter((t) => ids.has(t.id))
      .sort((a, b) => a.shortName.localeCompare(b.shortName, "cs"));
  }, [players, teams, need]);

  const market = useMemo(() => {
    let list = players.filter((p) => p.position === need);
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
    switch (sort) {
      case "rating":
        list = [...list].sort((a, b) => playerRating(b) - playerRating(a));
        break;
      case "price":
        list = [...list].sort((a, b) => playerPrice(b) - playerPrice(a));
        break;
      case "points":
        list = [...list].sort((a, b) => fantasyPoints(b) - fantasyPoints(a));
        break;
      case "name":
        list = [...list].sort((a, b) => a.lastName.localeCompare(b.lastName, "cs"));
        break;
    }
    return list;
  }, [players, need, query, clubFilter, sort, teamById]);

  const pick = (p: Player) => {
    if (!fantasy.isViewingEditable) {
      showToast("Toto kolo nejde upravovat (deadline sobota 10:00).");
      return;
    }
    const err = fantasy.setSlot(slot, p, playerById);
    if (err) {
      showToast(err);
      return;
    }
    onPicked();
  };

  return (
    <div className="hb-enter relative flex min-h-0 flex-1 flex-col">
      <ScreenHeader
        title={marketMode ? "Hráčský trh" : SLOT_LABEL[slot]}
        subtitle={marketMode ? "Extraliga" : `${remaining} kr · ${slot}`}
        left={<BackButton onClick={onBack} />}
      />
      <div className="shrink-0 space-y-2.5 border-b border-separator/40 bg-surface px-[var(--screen-pad)] py-3">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Hráč nebo klub"
          className="w-full rounded-[12px] border border-card-stroke bg-card px-3 py-2.5 text-[14px] outline-none focus:border-brand"
        />
        <div className="text-[12px] font-bold text-hb-muted">
          {marketMode ? "Extraliga" : `Rozpočet slotu: ${remaining} kr`}
        </div>
        <div className="flex gap-2 overflow-x-auto pb-0.5">
          {SORT_PILLS.map((pill) => (
            <button
              key={pill.id}
              type="button"
              onClick={() => setSort(pill.id)}
              className={`shrink-0 rounded-full px-2.5 py-1.5 text-[11px] font-bold ${
                sort === pill.id ? "bg-brand text-on-brand" : "bg-card-inset text-hb-muted"
              }`}
            >
              {pill.label}
            </button>
          ))}
          <span className="mx-1 w-px shrink-0 self-stretch bg-separator/50" />
          <button
            type="button"
            onClick={() => setClubFilter(null)}
            className={`shrink-0 rounded-full px-2.5 py-1.5 text-[11px] font-bold ${
              clubFilter == null ? "bg-brand text-on-brand" : "bg-card-inset text-hb-muted"
            }`}
          >
            Všechny kluby
          </button>
          {clubs.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setClubFilter(t.id)}
              className={`shrink-0 rounded-full px-2.5 py-1.5 text-[11px] font-bold ${
                clubFilter === t.id ? "bg-brand text-on-brand" : "bg-card-inset text-hb-muted"
              }`}
            >
              {t.shortName}
            </button>
          ))}
        </div>
      </div>
      <div className="hb-scroll min-h-0 flex-1 space-y-2.5 px-[var(--screen-pad)] py-3 pb-7">
        {market.map((p) => {
          const price = playerPrice(p);
          const rating = playerRating(p);
          const pts = fantasyPoints(p);
          const team = teamById(p.teamId);
          const taken = fantasy.selectedPlayerIds.has(p.id);
          const affordable = price <= remaining || taken;
          const fixture = nextFantasyFixture(p.teamId, matches);
          const isHome = fixture ? fixture.homeTeamId === p.teamId : false;
          const opp = fixture
            ? teamById(isHome ? fixture.awayTeamId : fixture.homeTeamId)
            : undefined;

          return (
            <div
              key={p.id}
              className={`hb-card flex w-full items-center gap-3 px-3.5 py-3 ${
                affordable || taken || marketMode ? "" : "opacity-45"
              }`}
            >
              {team && <TeamBadge team={team} size={36} />}
              <button
                type="button"
                className="min-w-0 flex-1 text-left"
                onClick={() => setScoutPlayer(p)}
              >
                <div className="truncate text-[15px] font-bold text-hb-fg">{playerFullName(p)}</div>
                <div className="mt-0.5 text-[12px] font-medium text-hb-muted">
                  {team?.shortName ?? "Tým"} · {positionLabel(p.position)}
                </div>
                <div className="mt-1.5 flex flex-wrap gap-1.5">
                  <span className="rounded-full bg-card-inset px-2 py-1 text-[10px] font-bold text-hb-muted">
                    OVR {rating}
                  </span>
                  <span className="rounded-full bg-card-inset px-2 py-1 text-[10px] font-bold text-hb-muted">
                    {price} kr
                  </span>
                  <span className="rounded-full bg-card-inset px-2 py-1 text-[10px] font-bold text-hb-muted">
                    {pts} b
                  </span>
                  <span className="rounded-full bg-card-inset px-2 py-1 text-[10px] font-bold text-hb-muted">
                    {tierLabel(rating)}
                  </span>
                </div>
                {fixture && opp && (
                  <div className="mt-1 text-[10px] font-semibold text-hb-faint">
                    {isHome ? "vs" : "@"} {opp.shortName}
                  </div>
                )}
              </button>
              {!marketMode && (
                <button
                  type="button"
                  disabled={!fantasy.isViewingEditable || (!affordable && !taken)}
                  onClick={() => pick(p)}
                  className="text-[22px] font-bold text-brand disabled:opacity-35"
                  aria-label={taken ? "Vybráno" : "Přidat"}
                >
                  {taken ? "✓" : "+"}
                </button>
              )}
              {marketMode && (
                <button
                  type="button"
                  className="text-[12px] font-bold text-brand"
                  onClick={() => setScoutPlayer(p)}
                >
                  Info
                </button>
              )}
            </div>
          );
        })}
        {!market.length && <EmptyState title="Žádní hráči" hint="Zkus jiný filtr nebo klub." />}
      </div>
      {scoutPlayer && (
        <FantasyPlayerScout
          player={scoutPlayer}
          canReplace={!marketMode && fantasy.isViewingEditable}
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

export function FantasyScreen({
  screen = "hub",
}: {
  screen?: "hub" | "team" | "market" | "leaderboard" | "rules";
}) {
  const { pop, push, replace } = useNav();
  const fantasy = useFantasy();
  const { teamById, matches, competitions, players: catalogPlayers } = useCatalog();
  const [slotPick, setSlotPick] = useState<FantasySlot | null>(null);
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
    return [...filtered].sort((a, b) => fantasyPoints(b) - fantasyPoints(a));
  }, [catalogPlayers, extraligaIds]);

  const lineup = fantasy.lineupFor();
  const playerById = useMemo(() => new Map(players.map((p) => [p.id, p])), [players]);
  const remaining = fantasy.remainingBudget(playerById);

  const roundFixtures = useMemo(() => {
    const gw = fantasy.viewingGameweek;
    const byRound = matches
      .filter((m) => extraligaIds.has(m.competitionId) && m.round === gw)
      .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt));
    return byRound.slice(0, 12);
  }, [matches, extraligaIds, fantasy.viewingGameweek]);

  const showToast = (text: string) => {
    setToast(text);
    window.setTimeout(() => setToast(null), 2200);
  };

  const handleSaveWithMessage = () => {
    if (!fantasy.isViewingEditable) {
      showToast("Toto kolo nejde upravovat (deadline sobota 10:00).");
      return;
    }
    const err = fantasy.saveLineup();
    if (err) showToast(err);
    else showToast(`Sestava GW ${fantasy.activeGameweek} uložena`);
  };

  if (screen === "rules") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Pravidla" left={<BackButton onClick={pop} />} />
        <div className="flex flex-col gap-3.5 px-[var(--screen-pad)] pt-3 pb-7">
          <RuleCard
            title="Týdenní sestava"
            text="Každé kolo vlastní sestava 1 brankář · 2 obránci · 3 útočníci."
          />
          <RuleCard title="Deadline" text="Uzávěrka vždy v sobotu v 10:00 (Praha). Poté je sestava zamčená." />
          <RuleCard
            title="Rozpočet"
            text={`${fantasy.budget} kreditů. Cena hráče 4–15 podle ratingu (OVR).`}
          />
          <RuleCard title="Kluby" text="Max. 2 hráči z jednoho klubu." />
          <RuleCard
            title="Body"
            text="Gól 3 · Asistence 2 · Účast / brankářské bonusy. Body se sčítají po kole."
          />
          <RuleCard title="Uložení" text="Nezapomeň klepnout ULOŽIT SESTAVU před deadlinem." />
        </div>
      </div>
    );
  }

  if (screen === "leaderboard") {
    const board = [
      { name: "Hostivař Ultra", pts: Math.max(0, fantasy.seasonPoints + 12), you: false },
      { name: "Lední žraloci", pts: Math.max(0, fantasy.seasonPoints + 4), you: false },
      { name: fantasy.teamName, pts: fantasy.seasonPoints, you: true },
      { name: "Pardubický sen", pts: Math.max(0, fantasy.seasonPoints - 3), you: false },
      { name: "Plzeňský expres", pts: Math.max(0, fantasy.seasonPoints - 9), you: false },
    ].sort((a, b) => b.pts - a.pts);

    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Žebříček" left={<BackButton onClick={pop} />} />
        <div className="flex flex-col gap-0 px-[var(--screen-pad)] py-3">
          <div className="hb-card overflow-hidden">
            {board.map((row, i) => (
              <div
                key={row.name + i}
                className={`flex items-center gap-3 px-3.5 py-3 ${
                  row.you ? "bg-[color-mix(in_srgb,var(--brand)_8%,transparent)]" : ""
                } ${i > 0 ? "border-t border-[color-mix(in_srgb,var(--separator)_50%,transparent)]" : ""}`}
              >
                <span
                  className={`hb-number w-7 text-[16px] font-extrabold ${row.you ? "text-brand" : "text-hb-muted"}`}
                >
                  {i + 1}
                </span>
                <span
                  className={`min-w-0 flex-1 truncate text-[15px] ${row.you ? "font-bold" : "font-semibold"} text-hb-fg`}
                >
                  {row.name}
                </span>
                <span className="hb-number text-[15px] font-bold text-hb-muted">{row.pts} b</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (screen === "market" || slotPick) {
    const slot = slotPick ?? "F1";
    return (
      <>
        <MarketPicker
          slot={slot}
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
        {toast && (
          <div className="pointer-events-none fixed inset-x-0 bottom-24 z-50 flex justify-center">
            <div className="rounded-full bg-ink/90 px-4 py-3 text-[13px] font-bold text-white">{toast}</div>
          </div>
        )}
      </>
    );
  }

  if (screen === "team") {
    const editable = fantasy.isViewingEditable;
    const transfersLabel = fantasy.freeTransfers >= 99 ? "∞" : `${fantasy.freeTransfers}`;

    return (
      <div className="hb-enter relative flex min-h-0 flex-1 flex-col">
        <ScreenHeader title="Můj tým" left={<BackButton onClick={pop} />} />
        <div className="hb-scroll relative min-h-0 flex-1 bg-[linear-gradient(180deg,#14384d,#0d1f29)]">
          <div className="flex flex-col gap-3.5 px-[var(--screen-pad)] pt-3 pb-32">
            {!editable && (
              <div className="rounded-[10px] bg-white/10 px-3 py-2.5 text-[12px] font-semibold text-white/75">
                Prohlížíš minulé kolo — sestava je jen ke čtení.
              </div>
            )}
            <div className="flex flex-col gap-2">
              <FantasyStatTile title="MOJE BODY" value={`${fantasy.seasonPoints}`} featured />
              <div className="grid grid-cols-2 gap-2">
                <FantasyStatTile title="PŘESTUPY" value={transfersLabel} />
                <FantasyStatTile title="ROZPOČET" value={`${remaining} kr`} />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <FantasyStatTile title="SESTAVA" value={`${fantasy.filledCount}/6`} />
                <FantasyStatTile title="KOLO" value={`${fantasy.viewingGameweek}`} />
              </div>
            </div>

            <input
              value={fantasy.teamName}
              onChange={(e) => editable && fantasy.setTeamName(e.target.value)}
              disabled={!editable}
              className="rounded-[10px] bg-white/10 px-3 py-3 text-[15px] font-semibold text-white outline-none placeholder:text-white/40 disabled:opacity-60"
              placeholder="Název týmu"
            />

            <div className="overflow-hidden rounded-[16px] border-2 border-white/20 bg-[linear-gradient(180deg,#1f6185,#143850,#0f3857)] px-2 py-4">
              {(
                [
                  ["BRANKÁŘ", ["G"] as FantasySlot[]],
                  ["OBRANA", ["D1", "D2"] as FantasySlot[]],
                  ["ÚTOK", ["F1", "F2", "F3"] as FantasySlot[]],
                ] as const
              ).map(([label, slots], idx) => (
                <div key={label}>
                  {idx > 0 && <div className="mx-5 my-3.5 h-0.5 bg-[color-mix(in_srgb,var(--brand)_70%,transparent)]" />}
                  <div className="mb-2 text-center text-[9px] font-bold tracking-[1px] text-white/55">
                    {label}
                  </div>
                  <div className="flex justify-center gap-3">
                    {slots.map((slot) => {
                      const pid = lineup[slot];
                      const p = pid ? playerById.get(pid) : undefined;
                      const team = p ? teamById(p.teamId) : undefined;
                      return (
                        <div key={slot} className="relative flex w-[96px] flex-col items-center">
                          <button
                            type="button"
                            disabled={!editable && !p}
                            onClick={() => {
                              if (!editable) {
                                if (p) setScout({ slot, player: p });
                                return;
                              }
                              setSlotPick(slot);
                            }}
                            onContextMenu={(e) => {
                              e.preventDefault();
                              if (p) setScout({ slot, player: p });
                            }}
                            className="flex w-full flex-col items-center gap-1 rounded-[12px] border border-white/20 bg-black/25 px-2 py-2.5 text-center disabled:opacity-80"
                          >
                            {team ? (
                              <TeamBadge team={team} size={28} />
                            ) : (
                              <div className="flex h-7 w-7 items-center justify-center rounded-full bg-white/15 text-[14px] font-bold text-white/70">
                                {editable ? "+" : "—"}
                              </div>
                            )}
                            <div className="w-full truncate text-[11px] font-bold text-white">
                              {p ? playerFullName(p).split(" ").slice(-1)[0] : editable ? "Přidat" : "—"}
                            </div>
                            <div className="text-[9px] font-bold text-white/50">{slot}</div>
                            {p && <SlotOpponentChip teamId={p.teamId} matches={matches} />}
                          </button>
                          {p && (
                            <button
                              type="button"
                              className="mt-1 text-[10px] font-bold text-white/55 underline"
                              onClick={() => setScout({ slot, player: p })}
                            >
                              Info
                            </button>
                          )}
                          {p && editable && (
                            <button
                              type="button"
                              className="mt-0.5 text-[10px] font-bold text-white/40"
                              onClick={() => fantasy.removeSlot(slot)}
                            >
                              Odebrat
                            </button>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>

            <p className="text-[12px] font-medium text-white/65">
              {editable
                ? "Klepni na slot = výběr hráče. Info / dlouhý stisk = scout. Ulož sestavu před deadlinem."
                : "Minulé kolo — změny nejsou povolené."}
            </p>

            {editable && (
              <button
                type="button"
                className="text-left text-[12px] font-semibold text-white/55 underline"
                onClick={() => fantasy.clearLineup()}
              >
                Vymazat sestavu
              </button>
            )}
          </div>

          {toast && (
            <div className="pointer-events-none absolute inset-x-0 top-3 flex justify-center">
              <div className="rounded-full bg-ink/90 px-3.5 py-2.5 text-[13px] font-bold text-white">
                {toast}
              </div>
            </div>
          )}
        </div>
        <DeadlineBar
          locked={!editable}
          onSave={handleSaveWithMessage}
        />
        {scout && (
          <FantasyPlayerScout
            player={scout.player}
            canReplace={editable}
            onClose={() => setScout(null)}
            onReplace={() => {
              setScout(null);
              setSlotPick(scout.slot);
            }}
          />
        )}
      </div>
    );
  }

  // hub
  return (
    <div className="hb-enter flex min-h-0 flex-1 flex-col">
      <ScreenHeader title="Fantasy" subtitle="Extraliga" left={<BackButton onClick={pop} />} />
      <div className="hb-scroll relative min-h-0 flex-1">
        <div className="flex flex-col gap-[18px] px-[var(--screen-pad)] pt-3 pb-32">
          <div className="hb-card rounded-[var(--radius-sm)] px-3 py-3 text-[12px] font-medium leading-snug text-hb-muted">
            Lokální demo — body a žebříček zatím jen na tomto zařízení.
            {fantasy.hasUnsavedChanges && " · Neuložené změny sestavy."}
          </div>

          <div className="flex items-center">
            <button
              type="button"
              disabled={fantasy.viewingGameweek <= 1}
              onClick={() => fantasy.setViewingGameweek(fantasy.viewingGameweek - 1)}
              className="flex h-9 w-9 items-center justify-center rounded-full bg-card text-brand disabled:opacity-35"
              aria-label="Předchozí kolo"
            >
              <IconChevronLeft size={14} />
            </button>
            <div className="hb-display flex-1 text-center text-[22px] text-hb-fg">
              {fantasy.viewingGameweek}. KOLO
              {fantasy.viewingGameweek === fantasy.activeGameweek ? "" : " · archiv"}
            </div>
            <button
              type="button"
              onClick={() => fantasy.setViewingGameweek(fantasy.viewingGameweek + 1)}
              className="flex h-9 w-9 items-center justify-center rounded-full bg-card text-brand"
              aria-label="Další kolo"
            >
              <IconChevronRight size={14} />
            </button>
          </div>

          <div>
            <div className="mb-2.5 text-[11px] font-bold tracking-[0.8px] text-hb-faint">ZÁPASY KOLA</div>
            {roundFixtures.length ? (
              <div className="grid grid-cols-2 gap-2">
                {roundFixtures.map((m) => (
                  <FixtureChip key={m.id} match={m} />
                ))}
              </div>
            ) : (
              <div className="hb-card p-3.5 text-[13px] font-medium text-hb-muted">
                Pro toto kolo zatím nejsou zápasy.
              </div>
            )}
          </div>

          <div className="hb-card overflow-hidden">
            <MenuRow
              icon={<IconUser size={16} />}
              title="Můj tým"
              onClick={() => push({ name: "fantasy", screen: "team" })}
            />
            <MenuRow
              icon={<IconStack size={16} />}
              title="Hráčský trh"
              onClick={() => push({ name: "fantasy", screen: "market" })}
            />
            <MenuRow
              icon={<IconTrophy size={16} />}
              title="Žebříček"
              onClick={() => push({ name: "fantasy", screen: "leaderboard" })}
            />
            <MenuRow
              icon={
                <svg width={16} height={16} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                  <path d="M6 4h9a3 3 0 0 1 3 3v13l-1.5-.9L15 20.2l-1.5-1.1L12 20.2l-1.5-1.1L9 20.2l-1.5-1.1L6 20V4zm2 4v2h7V8H8zm0 4v2h5v-2H8z" />
                </svg>
              }
              title="Pravidla"
              onClick={() => push({ name: "fantasy", screen: "rules" })}
              last
            />
          </div>
        </div>

        {toast && (
          <div className="pointer-events-none absolute inset-x-0 bottom-28 flex justify-center">
            <div className="rounded-full bg-ink/90 px-4 py-3 text-[13px] font-bold text-white">{toast}</div>
          </div>
        )}
      </div>
      <DeadlineBar
        locked={!fantasy.isViewingEditable}
        onSave={handleSaveWithMessage}
      />
    </div>
  );
}

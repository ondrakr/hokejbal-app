/**
 * Port `FantasyDeadline` z `Hokejbal/Hokejbal/Services/FantasySquadStore.swift`.
 *
 * Deadline sestavy je vždy sobota 10:00 Europe/Prague, číslo kola se počítá
 * od kotvy sezóny. Obě platformy musí pro stejný okamžik hlásit stejné kolo —
 * při změně tady je potřeba upravit i Swift verzi.
 */

const PRAGUE = "Europe/Prague";
const WEEK_SECONDS = 7 * 24 * 3600;

/** První sobota sezóny Fantasy (deadline GW1) — 6. 9. 2025 10:00 Praha. */
export const SEASON_ANCHOR = { year: 2025, month: 9, day: 6, hour: 10, minute: 0 } as const;

export type PragueWallClock = {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
  /** 0 = neděle … 6 = sobota */
  weekday: number;
};

const WEEKDAY_INDEX: Record<string, number> = {
  Sun: 0,
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
};

const partsFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: PRAGUE,
  hourCycle: "h23",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  weekday: "short",
});

/** Složky pražského nástěnného času pro daný okamžik. */
export function pragueWallClock(date: Date): PragueWallClock {
  const parts = partsFormatter.formatToParts(date);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
  return {
    year: Number(get("year")),
    month: Number(get("month")),
    day: Number(get("day")),
    hour: Number(get("hour")),
    minute: Number(get("minute")),
    second: Number(get("second")),
    weekday: WEEKDAY_INDEX[get("weekday")] ?? 0,
  };
}

/** Posun Prahy proti UTC v ms (kladný = Praha je napřed). */
function pragueOffsetMs(date: Date): number {
  const w = pragueWallClock(date);
  const asUTC = Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, w.second);
  return asUTC - Math.floor(date.getTime() / 1000) * 1000;
}

/**
 * Pražský nástěnný čas → skutečný okamžik.
 *
 * `day` smí přetéct (např. 6. 9. + 336 dní) — `Date.UTC` to přepočítá.
 * Druhá iterace opravuje odhad na přechodu mezi letním a zimním časem.
 */
export function fromPragueWallClock(
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number
): Date {
  const naive = Date.UTC(year, month - 1, day, hour, minute, 0);
  let ts = naive - pragueOffsetMs(new Date(naive));
  ts = naive - pragueOffsetMs(new Date(ts));
  return new Date(ts);
}

/** Kotva sezóny jako skutečný okamžik. */
export function seasonAnchorDate(): Date {
  return fromPragueWallClock(
    SEASON_ANCHOR.year,
    SEASON_ANCHOR.month,
    SEASON_ANCHOR.day,
    SEASON_ANCHOR.hour,
    SEASON_ANCHOR.minute
  );
}

/** Nejbližší sobota 10:00 (dnes sobota před 10:00 → dnes, jinak příští sobota). */
export function upcomingDeadline(from: Date = new Date()): Date {
  const w = pragueWallClock(from);
  const daysUntilSaturday = (6 - w.weekday + 7) % 7;
  const saturday = fromPragueWallClock(w.year, w.month, w.day + daysUntilSaturday, 10, 0);
  if (daysUntilSaturday === 0 && from.getTime() >= saturday.getTime()) {
    // Sobota po 10:00 → další sobota.
    const sw = pragueWallClock(saturday);
    return fromPragueWallClock(sw.year, sw.month, sw.day + 7, 10, 0);
  }
  return saturday;
}

/** Deadline právě hraného / uzamčeného kola. */
export function activeDeadline(from: Date = new Date()): Date {
  const w = pragueWallClock(upcomingDeadline(from));
  return fromPragueWallClock(w.year, w.month, w.day - 7, w.hour, w.minute);
}

/** Číslo kola od kotvy sezóny (min. 1). */
export function gameweek(from: Date = new Date()): number {
  const seconds = (upcomingDeadline(from).getTime() - seasonAnchorDate().getTime()) / 1000;
  const weeks = Math.floor(seconds / WEEK_SECONDS);
  return Math.max(1, weeks + 1);
}

/** Deadline daného kola — kotva + (gw − 1) týdnů, nástěnných 10:00. */
export function deadlineForGameweek(gw: number): Date {
  return fromPragueWallClock(
    SEASON_ANCHOR.year,
    SEASON_ANCHOR.month,
    SEASON_ANCHOR.day + (gw - 1) * 7,
    SEASON_ANCHOR.hour,
    SEASON_ANCHOR.minute
  );
}

/** Sestavu kola lze měnit, dokud nenastal jeho deadline. */
export function isEditable(gw: number, now: Date = new Date()): boolean {
  return now.getTime() < deadlineForGameweek(gw).getTime();
}

export type CountdownParts = {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
};

export function countdownParts(to: Date, from: Date = new Date()): CountdownParts {
  const interval = Math.max(0, Math.floor((to.getTime() - from.getTime()) / 1000));
  return {
    days: Math.floor(interval / 86_400),
    hours: Math.floor((interval % 86_400) / 3600),
    minutes: Math.floor((interval % 3600) / 60),
    seconds: interval % 60,
  };
}

export function countdown(to: Date, from: Date = new Date()): string {
  const p = countdownParts(to, from);
  if (p.days > 0) return `${p.days}d ${p.hours}h`;
  if (p.hours > 0) return `${p.hours}h ${p.minutes}m`;
  return `${p.minutes}m ${p.seconds}s`;
}

import { parseISO } from "date-fns";

/** Všechny dny/časy v appce bereme v pražském čase — stejně jako hokejbal.cz. */
export const APP_TZ = "Europe/Prague";

/** Postgres / PostgREST často vrací „2026-07-25 16:00:00+00“ bez T. */
export function parseDate(iso: string) {
  const raw = iso.trim();
  const normalized = raw.includes("T") ? raw : raw.replace(" ", "T");
  return parseISO(normalized);
}

function pragueDateParts(date: Date) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: APP_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const get = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((p) => p.type === type)?.value ?? "00";
  return {
    year: get("year"),
    month: get("month"),
    day: get("day"),
  };
}

/** yyyy-MM-dd v Europe/Prague */
export function dayKeyFromDate(date: Date) {
  const { year, month, day } = pragueDateParts(date);
  return `${year}-${month}-${day}`;
}

export function dayKey(iso: string) {
  return dayKeyFromDate(parseDate(iso));
}

export function todayKey() {
  return dayKeyFromDate(new Date());
}

/** Posune kalendářní den (yyyy-MM-dd v Praze) o N dní. */
export function shiftDayKey(key: string, deltaDays: number) {
  const [y, m, d] = key.split("-").map(Number);
  // Poledne UTC drží civilní den stabilní i při DST.
  return dayKeyFromDate(new Date(Date.UTC(y, m - 1, d + deltaDays, 12)));
}

function formatInPrague(
  iso: string,
  options: Intl.DateTimeFormatOptions,
  locale = "cs-CZ"
) {
  return new Intl.DateTimeFormat(locale, { timeZone: APP_TZ, ...options }).format(parseDate(iso));
}

/** HH:mm — iOS hbTime */
export function formatMatchTime(iso: string) {
  return formatInPrague(iso, { hour: "2-digit", minute: "2-digit", hourCycle: "h23" });
}

/** d. M. — iOS hbShortDate */
export function formatShortDate(iso: string) {
  return formatInPrague(iso, { day: "numeric", month: "numeric" });
}

/** d. M. yyyy | HH:mm — finished header */
export function formatFinishedStamp(iso: string) {
  const date = formatInPrague(iso, { day: "numeric", month: "numeric", year: "numeric" });
  return `${date} | ${formatMatchTime(iso)}`;
}

export function formatMatchDay(iso: string) {
  return formatInPrague(iso, { weekday: "long", day: "numeric", month: "numeric" });
}

export function formatShortDay(iso: string) {
  return formatInPrague(iso, { weekday: "short" });
}

export function formatDayNum(iso: string) {
  return formatInPrague(iso, { day: "numeric" });
}

export function formatDayNumFromKey(key: string) {
  const [y, m, d] = key.split("-").map(Number);
  return new Intl.DateTimeFormat("cs-CZ", {
    timeZone: APP_TZ,
    day: "numeric",
  }).format(new Date(Date.UTC(y, m - 1, d, 12)));
}

export function formatDowFromKey(key: string) {
  const [y, m, d] = key.split("-").map(Number);
  return new Intl.DateTimeFormat("cs-CZ", {
    timeZone: APP_TZ,
    weekday: "short",
  })
    .format(new Date(Date.UTC(y, m - 1, d, 12)))
    .slice(0, 2);
}

export function formatNewsDate(iso: string) {
  return formatInPrague(iso, { day: "numeric", month: "numeric", year: "numeric" });
}

/** Mapuje period string z API na iOS shortPeriod */
export function shortPeriodLabel(period: string) {
  const p = period.toLowerCase();
  if (p.includes("1") || p.includes("first")) return "1. TŘETINA";
  if (p.includes("2") || p.includes("second")) return "2. TŘETINA";
  if (p.includes("3") || p.includes("third")) return "3. TŘETINA";
  if (p.includes("prodl") || p.includes("ot") || p.includes("overtime")) return "PRODLOUŽENÍ";
  if (p.includes("nájez") || p.includes("shoot")) return "NÁJEZDY";
  if (p.includes("přest") || p.includes("inter")) return "PŘESTÁVKA";
  if (p.includes("konec") || p.includes("finish")) return "KONEC";
  return period.toUpperCase();
}

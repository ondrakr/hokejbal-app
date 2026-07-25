import { format, parseISO, startOfDay } from "date-fns";
import { cs } from "date-fns/locale";

export function parseDate(iso: string) {
  return parseISO(iso);
}

/** HH:mm — iOS hbTime */
export function formatMatchTime(iso: string) {
  return format(parseDate(iso), "HH:mm", { locale: cs });
}

/** d. M. — iOS hbShortDate */
export function formatShortDate(iso: string) {
  return format(parseDate(iso), "d. M.", { locale: cs });
}

/** d. M. yyyy | HH:mm — finished header */
export function formatFinishedStamp(iso: string) {
  return `${format(parseDate(iso), "d. M. yyyy", { locale: cs })} | ${formatMatchTime(iso)}`;
}

export function formatMatchDay(iso: string) {
  return format(parseDate(iso), "EEEE d. M.", { locale: cs });
}

export function formatShortDay(iso: string) {
  return format(parseDate(iso), "EEE", { locale: cs });
}

export function formatDayNum(iso: string) {
  return format(parseDate(iso), "d", { locale: cs });
}

export function formatNewsDate(iso: string) {
  return format(parseDate(iso), "d. M. yyyy", { locale: cs });
}

export function dayKey(iso: string) {
  return format(startOfDay(parseDate(iso)), "yyyy-MM-dd");
}

export function todayKey() {
  return format(startOfDay(new Date()), "yyyy-MM-dd");
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

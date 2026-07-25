import { format, isSameDay, parseISO, startOfDay } from "date-fns";
import { cs } from "date-fns/locale";

export function parseDate(iso: string) {
  return parseISO(iso);
}

export function formatMatchTime(iso: string) {
  return format(parseDate(iso), "HH:mm", { locale: cs });
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

export function isSameMatchDay(a: string, b: Date | string) {
  const left = parseDate(a);
  const right = typeof b === "string" ? parseDate(b) : b;
  return isSameDay(left, right);
}

export function todayKey() {
  return format(startOfDay(new Date()), "yyyy-MM-dd");
}

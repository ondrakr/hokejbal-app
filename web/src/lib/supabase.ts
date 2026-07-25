import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url =
  process.env.NEXT_PUBLIC_SUPABASE_URL ??
  "https://uqnptbznnbeldtuvywtt.supabase.co";
const anonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxbnB0YnpubmJlbGR0dXZ5d3R0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzI0OTcsImV4cCI6MjEwMDIwODQ5N30.8JNL3wwYUtzhoXAzdn3QG5b00drbQrcXcS0JYDHIwjw";

let client: SupabaseClient | null = null;

export function getSupabase() {
  if (!client) {
    client = createClient(url, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}

export function sanitizeFilterId(id: string): string | null {
  const trimmed = id.trim();
  if (!trimmed || trimmed.length > 128) return null;
  if (!/^[a-zA-Z0-9_-]+$/.test(trimmed)) return null;
  return trimmed;
}

const OPEN_HOSTS = new Set([
  "hokejbal.cz",
  "www.hokejbal.cz",
  "hokejbal-fantasy.cz",
  "www.hokejbal-fantasy.cz",
  "youtube.com",
  "www.youtube.com",
  "m.youtube.com",
  "youtu.be",
  "ceskatelevize.cz",
  "www.ceskatelevize.cz",
  "isbhf.com",
  "www.isbhf.com",
]);

export function trustedOpenUrl(raw?: string | null): string | null {
  if (!raw?.trim()) return null;
  try {
    let s = raw.trim();
    if (s.startsWith("//")) s = "https:" + s;
    const u = new URL(s);
    if (u.protocol !== "https:") return null;
    const host = u.host.toLowerCase();
    if ([...OPEN_HOSTS].some((h) => host === h || host.endsWith("." + h))) {
      return u.toString();
    }
    return null;
  } catch {
    return null;
  }
}

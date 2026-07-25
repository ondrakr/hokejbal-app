import { getSupabase, sanitizeFilterId } from "./supabase";
import type {
  Competition,
  Match,
  MatchEvent,
  MatchesQuery,
  NewsArticle,
  Player,
  PlayerPosition,
  PlayerSeasonStat,
  Season,
  StandingRow,
  Team,
} from "./types";

function asPosition(raw: string): PlayerPosition {
  if (raw === "goalie" || raw === "defenseman" || raw === "forward") return raw;
  return "forward";
}

export async function fetchSeasons(): Promise<Season[]> {
  const { data, error } = await getSupabase()
    .from("seasons")
    .select("*")
    .order("sort_order", { ascending: false });
  if (error) throw error;
  return (data ?? []).map((r) => ({
    id: r.id,
    label: r.label,
    sortOrder: r.sort_order,
    isCurrent: r.is_current,
  }));
}

export async function fetchCompetitions(seasonId?: string): Promise<Competition[]> {
  let q = getSupabase()
    .from("competitions")
    .select("*, seasons(label)")
    .order("name", { ascending: true });
  if (seasonId) {
    const safe = sanitizeFilterId(seasonId);
    if (!safe) return [];
    q = q.eq("season_id", safe);
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []).map((r) => ({
    id: r.id,
    slug: r.slug,
    seasonId: r.season_id,
    name: r.name,
    shortName: r.short_name,
    season: r.seasons?.label ?? r.season_id,
    logoURL: r.logo_url,
    logoInitials: r.logo_initials,
    iconSystemName: r.icon_system_name,
  }));
}

export async function fetchTeams(competitionId?: string): Promise<Team[]> {
  let q = getSupabase().from("team_entries").select(
    "id,competition_id,clubs(id,name,short_name,city,primary_color_hex,logo_initials,logo_url)"
  );
  if (competitionId) {
    const safe = sanitizeFilterId(competitionId);
    if (!safe) return [];
    q = q.eq("competition_id", safe);
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? [])
    .map((r) => {
      const raw = r.clubs as unknown;
      const c = (Array.isArray(raw) ? raw[0] : raw) as Record<string, unknown> | null;
      if (!c) return null;
      return {
        id: String(c.id),
        name: String(c.name),
        shortName: String(c.short_name),
        city: String(c.city),
        primaryColorHex: String(c.primary_color_hex),
        logoInitials: String(c.logo_initials),
        logoURL: (c.logo_url as string) ?? null,
        competitionId: r.competition_id as string,
      } satisfies Team;
    })
    .filter(Boolean) as Team[];
}

type PlayerSeasonRow = {
  id: string;
  player_id: string;
  club_id: string;
  competition_id: string;
  number: number;
  position: string;
  games: number;
  goals: number;
  assists: number;
  points: number;
  penalty_minutes: number;
  save_percentage?: number | null;
  goals_against_average?: number | null;
  players?: {
    id: string;
    first_name: string;
    last_name: string;
    photo_url?: string | null;
  } | null;
  competitions?: {
    id: string;
    season_id: string;
    name: string;
    seasons?: { label: string } | null;
  } | null;
};

function mapPlayer(r: PlayerSeasonRow): Player | null {
  if (!r.players) return null;
  return {
    id: r.players.id,
    firstName: r.players.first_name,
    lastName: r.players.last_name,
    number: r.number,
    position: asPosition(r.position),
    teamId: r.club_id,
    games: r.games,
    goals: r.goals,
    assists: r.assists,
    points: r.points,
    penaltyMinutes: r.penalty_minutes,
    savePercentage: r.save_percentage,
    goalsAgainstAverage: r.goals_against_average,
    seasonId: r.competitions?.season_id,
    seasonLabel: r.competitions?.seasons?.label,
    competitionId: r.competition_id,
    photoURL: r.players.photo_url,
  };
}

export async function fetchPlayers(opts?: {
  teamId?: string;
  seasonId?: string;
  competitionId?: string;
}): Promise<Player[]> {
  let q = getSupabase()
    .from("player_seasons")
    .select(
      "*,players(id,first_name,last_name,photo_url),competitions(id,season_id,name,seasons(label))"
    )
    .order("points", { ascending: false });

  if (opts?.teamId) {
    const safe = sanitizeFilterId(opts.teamId);
    if (!safe) return [];
    q = q.eq("club_id", safe);
  }
  if (opts?.competitionId) {
    const safe = sanitizeFilterId(opts.competitionId);
    if (!safe) return [];
    q = q.eq("competition_id", safe);
  } else if (opts?.seasonId) {
    const comps = await fetchCompetitions(opts.seasonId);
    const ids = comps.map((c) => c.id);
    if (!ids.length) return [];
    q = q.in("competition_id", ids);
  }

  const { data, error } = await q;
  if (error) throw error;
  return ((data ?? []) as PlayerSeasonRow[]).map(mapPlayer).filter(Boolean) as Player[];
}

type MatchEventRow = {
  id: string;
  kind: string;
  minute: number;
  second: number;
  club_id: string;
  player_id?: string | null;
  assist_ids?: string[] | null;
  description: string;
  period: number;
  sort_order?: number | null;
};

type MatchRow = {
  id: string;
  competition_id: string;
  home_club_id: string;
  away_club_id: string;
  scheduled_at: string;
  status: string;
  period: string;
  clock?: string | null;
  phase?: string | null;
  home_score: number;
  away_score: number;
  home_period_scores?: number[] | null;
  away_period_scores?: number[] | null;
  venue: string;
  round: number;
  attendance?: number | null;
  stream_url?: string | null;
  stream_label?: string | null;
  home_shots?: number | null;
  away_shots?: number | null;
  home_pp_goals?: number | null;
  away_pp_goals?: number | null;
  home_sh_goals?: number | null;
  away_sh_goals?: number | null;
  referees?: string | null;
  match_events?: MatchEventRow[] | null;
};

function mapEvent(e: MatchEventRow): MatchEvent {
  return {
    id: e.id,
    kind: e.kind as MatchEvent["kind"],
    minute: e.minute,
    second: e.second,
    teamId: e.club_id,
    playerId: e.player_id,
    assistIds: e.assist_ids ?? [],
    description: e.description,
    period: e.period,
  };
}

function mapMatch(r: MatchRow): Match {
  const events = [...(r.match_events ?? [])]
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    .map(mapEvent);
  return {
    id: r.id,
    competitionId: r.competition_id,
    homeTeamId: r.home_club_id,
    awayTeamId: r.away_club_id,
    scheduledAt: r.scheduled_at,
    status: r.status as Match["status"],
    period: r.period ?? "",
    clock: r.clock,
    phase: (r.phase as Match["phase"]) ?? "regular",
    homeScore: r.home_score,
    awayScore: r.away_score,
    homePeriodScores: r.home_period_scores ?? [],
    awayPeriodScores: r.away_period_scores ?? [],
    venue: r.venue ?? "",
    round: r.round ?? 0,
    events,
    attendance: r.attendance,
    streamURL: r.stream_url,
    streamLabel: r.stream_label,
    homeShots: r.home_shots,
    awayShots: r.away_shots,
    homePowerplayGoals: r.home_pp_goals,
    awayPowerplayGoals: r.away_pp_goals,
    homeShorthandedGoals: r.home_sh_goals,
    awayShorthandedGoals: r.away_sh_goals,
    referees: r.referees,
  };
}

export async function fetchMatches(query: MatchesQuery = {}): Promise<Match[]> {
  let q = getSupabase()
    .from("matches")
    .select("*,match_events(*)")
    .order("scheduled_at", { ascending: true });

  if (query.competitionId) {
    const safe = sanitizeFilterId(query.competitionId);
    if (!safe) return [];
    q = q.eq("competition_id", safe);
  } else if (query.seasonId) {
    const comps = await fetchCompetitions(query.seasonId);
    const ids = comps.map((c) => c.id);
    if (!ids.length) return [];
    q = q.in("competition_id", ids);
  }
  if (query.status) q = q.eq("status", query.status);
  if (query.teamId) {
    const safe = sanitizeFilterId(query.teamId);
    if (!safe) return [];
    q = q.or(`home_club_id.eq.${safe},away_club_id.eq.${safe}`);
  }

  const { data, error } = await q;
  if (error) throw error;
  return ((data ?? []) as MatchRow[]).map(mapMatch);
}

export async function fetchLiveMatches(): Promise<Match[]> {
  return fetchMatches({ status: "live" });
}

export async function fetchMatch(id: string): Promise<Match | null> {
  const safe = sanitizeFilterId(id);
  if (!safe) return null;
  const { data, error } = await getSupabase()
    .from("matches")
    .select("*,match_events(*)")
    .eq("id", safe)
    .maybeSingle();
  if (error) throw error;
  return data ? mapMatch(data as MatchRow) : null;
}

export async function fetchStandings(competitionId: string): Promise<StandingRow[]> {
  const safe = sanitizeFilterId(competitionId);
  if (!safe) return [];
  const { data, error } = await getSupabase()
    .from("standings")
    .select("*")
    .eq("competition_id", safe)
    .order("rank", { ascending: true });
  if (error) throw error;
  return (data ?? []).map((r) => ({
    id: r.id,
    teamId: r.club_id,
    rank: r.rank,
    played: r.played,
    wins: r.wins,
    draws: r.draws,
    losses: r.losses,
    goalsFor: r.goals_for,
    goalsAgainst: r.goals_against,
    points: r.points,
  }));
}

export async function fetchNews(limit = 20): Promise<NewsArticle[]> {
  // 1) Stejně jako iOS: nejdřív živé články z hokejbal.cz (s fotkami).
  try {
    const url =
      typeof window === "undefined"
        ? `${process.env.NEXT_PUBLIC_SITE_URL ?? "http://127.0.0.1:3000"}/api/news?limit=${limit}`
        : `/api/news?limit=${limit}`;
    const res = await fetch(url, { cache: "no-store" });
    if (res.ok) {
      const json = (await res.json()) as { articles?: NewsArticle[] };
      if (json.articles?.length) return json.articles;
    }
  } catch {
    /* fallback níže */
  }

  // 2) Fallback: Supabase `news`
  const { data, error } = await getSupabase()
    .from("news")
    .select("*")
    .order("published_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return (data ?? []).map((r, i) => ({
    id: r.id,
    title: r.title,
    summary: r.summary ?? "",
    category: r.category ?? "Aktuality",
    publishedAt: r.published_at,
    photoURL: r.photo_url ?? null,
    articleURL: r.article_url ?? null,
    imageGradientIndex: r.image_gradient_index ?? i % 4,
  }));
}

/** Všechny kluby (loga) — doplněk k team_entries. */
export async function fetchClubs(): Promise<Team[]> {
  const { data, error } = await getSupabase()
    .from("clubs")
    .select("id,name,short_name,city,primary_color_hex,logo_initials,logo_url")
    .order("name", { ascending: true });
  if (error) throw error;
  return (data ?? []).map((c) => ({
    id: c.id,
    name: c.name,
    shortName: c.short_name,
    city: c.city,
    primaryColorHex: c.primary_color_hex,
    logoInitials: c.logo_initials,
    logoURL: c.logo_url,
    competitionId: "",
  }));
}

/** Týmy pro sezónu — paralelní načtení po soutěžích (jako CatalogStore na iOS). */
export async function fetchTeamsForSeason(seasonId: string): Promise<Team[]> {
  const comps = await fetchCompetitions(seasonId);
  const batches = await Promise.all(comps.map((c) => fetchTeams(c.id)));
  const unique = new Map<string, Team>();
  for (const batch of batches) {
    for (const t of batch) unique.set(t.id, t);
  }
  // Doplň loga z clubs, pokud team_entries nemá URL.
  const clubs = await fetchClubs();
  for (const club of clubs) {
    const existing = unique.get(club.id);
    if (existing) {
      if (!existing.logoURL && club.logoURL) {
        unique.set(club.id, { ...existing, logoURL: club.logoURL });
      }
    } else {
      unique.set(club.id, club);
    }
  }
  return [...unique.values()];
}

export async function fetchPlayer(id: string): Promise<Player | null> {
  const safe = sanitizeFilterId(id);
  if (!safe) return null;
  const { data, error } = await getSupabase()
    .from("player_seasons")
    .select(
      "*,players(id,first_name,last_name,photo_url),competitions(id,season_id,name,seasons(label))"
    )
    .eq("player_id", safe)
    .order("points", { ascending: false })
    .limit(1);
  if (error) throw error;
  const row = (data ?? [])[0] as PlayerSeasonRow | undefined;
  return row ? mapPlayer(row) : null;
}

export async function fetchPlayerHistory(playerId: string): Promise<PlayerSeasonStat[]> {
  const safe = sanitizeFilterId(playerId);
  if (!safe) return [];
  const { data, error } = await getSupabase()
    .from("player_seasons")
    .select(
      "*,players(id,first_name,last_name,photo_url),competitions(id,season_id,name,seasons(label))"
    )
    .eq("player_id", safe)
    .order("competition_id", { ascending: false });
  if (error) throw error;
  return ((data ?? []) as PlayerSeasonRow[]).map((r) => ({
    id: r.id,
    playerId: r.player_id,
    clubId: r.club_id,
    competitionId: r.competition_id,
    seasonId: r.competitions?.season_id ?? "",
    seasonLabel: r.competitions?.seasons?.label ?? "",
    competitionName: r.competitions?.name ?? "",
    number: r.number,
    position: asPosition(r.position),
    games: r.games,
    goals: r.goals,
    assists: r.assists,
    points: r.points,
    penaltyMinutes: r.penalty_minutes,
    savePercentage: r.save_percentage,
    goalsAgainstAverage: r.goals_against_average,
  }));
}

export async function fetchTeam(id: string): Promise<Team | null> {
  const all = await fetchTeams();
  return all.find((t) => t.id === id) ?? null;
}

-- =============================================================================
-- Hokejbal app — Fantasy (FIFA kartičky) + Tipovačka (tip skóre)
-- Projekt: uqnptbznnbeldtuvywtt
--
-- Spusť celý soubor v Supabase → SQL Editor. Je idempotentní (IF NOT EXISTS),
-- takže opakované spuštění nevadí.
--
-- Model důvěry v1: body si počítá klient a zapisuje je do points_awarded /
-- fantasy_scores. Pro přátelskou hru OK; časem přesunout do Edge Function
-- (obdoba settle-match), aby skóre počítal výhradně server.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) player_attributes — FIFA parametry hráče (1–99). Nepovinné: když chybí,
--    klient spočítá OVR ze sezónních statistik (fallback).
-- -----------------------------------------------------------------------------
create table if not exists public.player_attributes (
  player_id     text primary key,
  -- hráči do pole
  speed         smallint,
  strength      smallint,
  shooting      smallint,
  passing       smallint,
  dribbling     smallint,
  iq            smallint,
  defense       smallint,
  -- brankáři
  reflexes      smallint,
  positioning   smallint,
  glove         smallint,
  blocker       smallint,
  rebound       smallint,
  composure     smallint,
  -- volitelně předpočítané OVR (jinak si ho spočítá klient)
  overall       smallint,
  updated_by    uuid references auth.users(id) on delete set null,
  updated_at    timestamptz not null default now()
);

alter table public.player_attributes enable row level security;

-- Čtení pro všechny (i nepřihlášené) — karty vidí každý.
drop policy if exists player_attributes_select_all on public.player_attributes;
create policy player_attributes_select_all
  on public.player_attributes for select
  using (true);

-- Zápis zatím nikdo přes anon/authenticated (plní se přes service_role / admin
-- editorem v pozdější fázi). RLS bez write policy = write zakázán.

-- -----------------------------------------------------------------------------
-- 2) fantasy_squads — sestava uživatele po kolech (gameweek).
--    slots = jsonb { "goalie": "<playerId>", "defense1": "...", ... }
-- -----------------------------------------------------------------------------
create table if not exists public.fantasy_squads (
  user_id     uuid not null references auth.users(id) on delete cascade,
  gameweek    integer not null,
  team_name   text not null default '',
  slots       jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now(),
  primary key (user_id, gameweek)
);

alter table public.fantasy_squads enable row level security;

drop policy if exists fantasy_squads_rw_own on public.fantasy_squads;
create policy fantasy_squads_rw_own
  on public.fantasy_squads for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 3) fantasy_scores — body/kredity uživatele za kolo (píše klient po uzávěrce).
--    SELECT je veřejný (žebříček), zápis jen vlastník.
-- -----------------------------------------------------------------------------
create table if not exists public.fantasy_scores (
  user_id     uuid not null references auth.users(id) on delete cascade,
  gameweek    integer not null,
  points      integer not null default 0,
  credits     integer not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (user_id, gameweek)
);

alter table public.fantasy_scores enable row level security;

drop policy if exists fantasy_scores_select_all on public.fantasy_scores;
create policy fantasy_scores_select_all
  on public.fantasy_scores for select
  using (true);

drop policy if exists fantasy_scores_write_own on public.fantasy_scores;
create policy fantasy_scores_write_own
  on public.fantasy_scores for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 4) match_score_tips — tip skóre (SOUKROMÝ). Vlastník vidí jen své řádky.
--    Do žebříčku jde jen agregace přes view (definer), ne jednotlivé tipy.
-- -----------------------------------------------------------------------------
create table if not exists public.match_score_tips (
  user_id             uuid not null references auth.users(id) on delete cascade,
  match_id            text not null,
  home_score          smallint not null,
  away_score          smallint not null,
  predicted_overtime  boolean not null default false,
  points_awarded      integer,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  primary key (user_id, match_id)
);

alter table public.match_score_tips enable row level security;

-- Klíčové pro soukromí: SELECT jen vlastní řádky.
drop policy if exists match_score_tips_rw_own on public.match_score_tips;
create policy match_score_tips_rw_own
  on public.match_score_tips for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Winner-tip body: přidáme sloupec do existující match_tips (klient je píše
-- při vyhodnocení). Bezpečné i když tabulka už existuje.
alter table public.match_tips
  add column if not exists points_awarded integer not null default 0;

-- -----------------------------------------------------------------------------
-- 5) Žebříčky (views). Normální (definer) view → agreguje napříč uživateli
--    i přes RLS, ale ven pouští jen součty, ne cizí tipy.
-- -----------------------------------------------------------------------------

-- Fantasy: součet bodů za všechna kola.
create or replace view public.fantasy_leaderboard as
  select
    s.user_id,
    coalesce(nullif(trim(p.first_name || ' ' || p.last_name), ''), p.username) as display_name,
    p.username,
    p.avatar_url,
    sum(s.points)::integer  as total_points,
    sum(s.credits)::integer as total_credits,
    count(*)::integer       as scored_gameweeks
  from public.fantasy_scores s
  join public.profiles p on p.id = s.user_id
  group by s.user_id, p.first_name, p.last_name, p.username, p.avatar_url;

grant select on public.fantasy_leaderboard to anon, authenticated;

-- Tipovačka: součet bodů z tipu vítěze (match_tips) + tipu skóre (match_score_tips).
create or replace view public.tip_leaderboard as
  with pts as (
    select user_id, coalesce(points_awarded, 0) as points from public.match_tips
    union all
    select user_id, coalesce(points_awarded, 0) as points from public.match_score_tips
  )
  select
    pts.user_id,
    coalesce(nullif(trim(p.first_name || ' ' || p.last_name), ''), p.username) as display_name,
    p.username,
    p.avatar_url,
    sum(pts.points)::integer as total_points,
    count(*)::integer        as tips_count
  from pts
  join public.profiles p on p.id = pts.user_id
  group by pts.user_id, p.first_name, p.last_name, p.username, p.avatar_url;

grant select on public.tip_leaderboard to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 6) Ukázková seed data pro atributy (nepovinné) — přepiš na reálná player_id.
--    Bez těchto řádků appka OVR spočítá ze statistik (fallback).
-- -----------------------------------------------------------------------------
-- insert into public.player_attributes
--   (player_id, speed, strength, shooting, passing, dribbling, iq, defense, overall)
-- values
--   ('<cejka_player_id>', 96, 88, 99, 95, 97, 96, 84, 99),
--   ('<macha_player_id>', 90, 85, 92, 90, 91, 93, 82, 93)
-- on conflict (player_id) do update set
--   speed = excluded.speed, strength = excluded.strength, shooting = excluded.shooting,
--   passing = excluded.passing, dribbling = excluded.dribbling, iq = excluded.iq,
--   defense = excluded.defense, overall = excluded.overall, updated_at = now();

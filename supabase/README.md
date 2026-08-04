# Supabase — Hokejbal app

Backend appky běží na projektu `uqnptbznnbeldtuvywtt` (stejný, jaký používá iOS i web).
Klient (iOS) jezdí na **anon key** s RLS: veřejné SELECT + zápisy pod přihlášeným uživatelem.

## Migrace

Tabulky se z appky (anon key) vytvořit nedají — spusť SQL ručně:

1. Otevři [Supabase Dashboard](https://supabase.com/dashboard/project/uqnptbznnbeldtuvywtt) → **SQL Editor**.
2. Vlož obsah souboru z `migrations/` (nejnovější) a spusť. SQL je idempotentní.

| Migrace | Co přidává |
|---|---|
| `20260727000000_fantasy_tipping.sql` | `player_attributes`, `fantasy_squads`, `fantasy_scores`, `match_score_tips`, sloupec `match_tips.points_awarded`, views `fantasy_leaderboard` + `tip_leaderboard` (vč. RLS) |

## Existující tabulky (dřívější)

`profiles`, `user_favorites`, `match_tips`, `amateur_tournaments`, storage bucket `avatars`.

## Fantasy body (v1)

Body si zatím počítá klient a zapisuje je do `fantasy_scores` / `*.points_awarded`.
Pro produkci přesunout výpočet do Edge Function (obdoba `settle-match` z původní fantasy appky),
aby skóre nešlo z klienta podvrhnout.

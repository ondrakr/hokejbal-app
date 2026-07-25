# Hokejbal Web

Webová 1:1 verze iOS aplikace Hokejbal (iPhone shell na desktopu, fullscreen na mobilu).  
Data ze stejného Supabase projektu jako iOS. Nasazení na **Vercel**.

## Stack

- Next.js 15 (App Router) + TypeScript + Tailwind CSS 4
- `@supabase/supabase-js` (anon key, RLS SELECT)
- Lokální stav v `localStorage` (Fantasy, Tipovačka, Amatéři, Oblíbené)

## Lokální vývoj

```bash
cd web
cp .env.example .env.local
# doplň NEXT_PUBLIC_SUPABASE_ANON_KEY (stejný jako v iOS SupabaseConfig)
npm install
npm run dev
```

Otevři [http://localhost:3000](http://localhost:3000).

## Env

| Proměnná | Popis |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://uqnptbznnbeldtuvywtt.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | veřejný anon key (stejný jako iOS) |

Anon key je veřejný; RLS na Supabase zůstává read-only.

## Deploy na Vercel

1. Importuj GitHub repo do [Vercel](https://vercel.com).
2. **Root Directory** nastav na `web`.
3. Do Project Settings → Environment Variables přidej obě `NEXT_PUBLIC_*` hodnoty.
4. Deploy — vznikne free URL `https://<project>.vercel.app`.

### CLI

```bash
cd web
npx vercel
# produkce:
npx vercel --prod
```

Preview deploys vznikají automaticky z PR / větví.

## Struktura

```
web/
  src/app/           # Next.js App Router
  src/components/    # PhoneShell, taby, řádky zápasů
  src/screens/       # Domů, Zápasy, LIVE, detaily, Více, hry
  src/lib/           # Supabase klient + API port
  src/stores/        # catalog, favorites, tips, fantasy, amateur
```

## Parita s iOS

- Taby: Domů · Zápasy · LIVE · Oblíbené · Více
- Detaily: zápas, tým, hráč, soutěž
- Více: Fantasy, Tipovačka, Amatérské turnaje, Novinky, Hledání, Nastavení, Media
- LIVE poll ~8 s

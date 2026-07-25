"use client";

import { useMemo, useState } from "react";
import { formatNewsDate } from "@/lib/format";
import { trustedOpenUrl } from "@/lib/supabase";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

export function NewsScreen() {
  const { news } = useCatalog();
  const { pop, push } = useNav();
  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Novinky" left={<BackButton onClick={pop} />} />
      <div className="space-y-3 px-[var(--screen-pad)] py-3">
        {news.map((n) => (
          <button
            key={n.id}
            type="button"
            onClick={() => push({ name: "article", id: n.id })}
            className="hb-card w-full overflow-hidden text-left"
          >
            <div
              className="h-36 bg-gradient-to-br from-[var(--ink)] to-[var(--brand-dark)]"
              style={
                n.photoURL
                  ? {
                      backgroundImage: `linear-gradient(180deg,transparent,rgba(0,0,0,.5)),url(${n.photoURL})`,
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                    }
                  : undefined
              }
            />
            <div className="space-y-1 p-3">
              <div className="text-[11px] font-semibold text-[var(--brand)]">{n.category}</div>
              <div className="text-[15px] font-bold leading-snug">{n.title}</div>
              <div className="hb-muted">{formatNewsDate(n.publishedAt)}</div>
            </div>
          </button>
        ))}
        {!news.length && <EmptyState title="Žádné novinky" />}
      </div>
    </div>
  );
}

export function ArticleScreen({ id }: { id: string }) {
  const { news } = useCatalog();
  const { pop } = useNav();
  const article = news.find((n) => n.id === id);
  if (!article) return <EmptyState title="Článek nenalezen" />;
  const url = trustedOpenUrl(article.articleURL);
  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title={article.category} left={<BackButton onClick={pop} />} />
      <div className="px-[var(--screen-pad)] py-4">
        <h1 className="font-[family-name:var(--font-display)] text-[24px] font-extrabold leading-tight">
          {article.title}
        </h1>
        <div className="hb-muted mt-2">{formatNewsDate(article.publishedAt)}</div>
        <p className="mt-4 text-[15px] leading-relaxed text-[var(--text-secondary)]">{article.summary}</p>
        {url && (
          <a href={url} target="_blank" rel="noreferrer" className="hb-brand-btn mt-6">
            Otevřít článek
          </a>
        )}
      </div>
    </div>
  );
}

export function SearchScreen() {
  const { teams, competitions, matches } = useCatalog();
  const { pop, push } = useNav();
  const [q, setQ] = useState("");
  const query = q.trim().toLowerCase();

  const results = useMemo(() => {
    if (query.length < 2) return { teams: [], competitions: [], matches: [] };
    return {
      teams: teams.filter(
        (t) => t.name.toLowerCase().includes(query) || t.shortName.toLowerCase().includes(query)
      ),
      competitions: competitions.filter((c) => c.name.toLowerCase().includes(query)),
      matches: matches
        .filter((m) => {
          const home = teams.find((t) => t.id === m.homeTeamId);
          const away = teams.find((t) => t.id === m.awayTeamId);
          return (
            home?.name.toLowerCase().includes(query) ||
            away?.name.toLowerCase().includes(query)
          );
        })
        .slice(0, 20),
    };
  }, [query, teams, competitions, matches]);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Hledání" left={<BackButton onClick={pop} />} />
      <div className="px-[var(--screen-pad)] py-3">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Tým, soutěž, zápas…"
          className="w-full rounded-[14px] border border-[var(--card-stroke)] bg-[var(--card)] px-4 py-3 outline-none focus:border-[var(--brand)]"
          autoFocus
        />
      </div>
      {query.length >= 2 && (
        <div className="space-y-4 px-[var(--screen-pad)] pb-8">
          <ResultGroup title="Týmy">
            {results.teams.map((t) => (
              <button
                key={t.id}
                type="button"
                className="hb-card mb-2 flex w-full px-4 py-3 text-left font-semibold"
                onClick={() => push({ name: "team", id: t.id })}
              >
                {t.name}
              </button>
            ))}
            {!results.teams.length && <div className="hb-muted">Nic</div>}
          </ResultGroup>
          <ResultGroup title="Soutěže">
            {results.competitions.map((c) => (
              <button
                key={c.id}
                type="button"
                className="hb-card mb-2 flex w-full px-4 py-3 text-left font-semibold"
                onClick={() => push({ name: "competition", id: c.id })}
              >
                {c.name}
              </button>
            ))}
            {!results.competitions.length && <div className="hb-muted">Nic</div>}
          </ResultGroup>
          <ResultGroup title="Zápasy">
            {results.matches.map((m) => {
              const home = teams.find((t) => t.id === m.homeTeamId);
              const away = teams.find((t) => t.id === m.awayTeamId);
              return (
                <button
                  key={m.id}
                  type="button"
                  className="hb-card mb-2 flex w-full px-4 py-3 text-left font-semibold"
                  onClick={() => push({ name: "match", id: m.id })}
                >
                  {home?.shortName} – {away?.shortName}
                </button>
              );
            })}
            {!results.matches.length && <div className="hb-muted">Nic</div>}
          </ResultGroup>
        </div>
      )}
    </div>
  );
}

function ResultGroup({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="mb-2 text-[13px] font-bold text-[var(--text-secondary)]">{title}</h2>
      {children}
    </section>
  );
}

export function SettingsScreen() {
  const { seasons, selectedSeasonId, setSelectedSeasonId } = useCatalog();
  const { pop } = useNav();
  const [theme, setTheme] = useState<"system" | "light" | "dark">(() => {
    if (typeof window === "undefined") return "system";
    return (localStorage.getItem("hb.appearance") as "system" | "light" | "dark") || "system";
  });

  function applyTheme(next: "system" | "light" | "dark") {
    setTheme(next);
    localStorage.setItem("hb.appearance", next);
    const root = document.documentElement;
    if (next === "system") {
      root.removeAttribute("data-theme");
      if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
        root.setAttribute("data-theme", "dark");
      }
    } else {
      root.setAttribute("data-theme", next);
    }
  }

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Nastavení" left={<BackButton onClick={pop} />} />
      <div className="space-y-4 px-[var(--screen-pad)] py-4">
        <section className="hb-card p-4">
          <div className="mb-3 text-[14px] font-bold">Sezóna</div>
          <div className="space-y-2">
            {seasons.map((s) => (
              <button
                key={s.id}
                type="button"
                onClick={() => setSelectedSeasonId(s.id)}
                className={`flex w-full items-center justify-between rounded-[12px] px-3 py-2.5 text-left ${
                  selectedSeasonId === s.id ? "bg-[var(--brand)] text-white" : "bg-[var(--card-inset)]"
                }`}
              >
                <span className="font-semibold">{s.label}</span>
                {s.isCurrent && <span className="text-[11px] opacity-80">aktuální</span>}
              </button>
            ))}
          </div>
        </section>
        <section className="hb-card p-4">
          <div className="mb-3 text-[14px] font-bold">Vzhled</div>
          <div className="grid grid-cols-3 gap-2">
            {(
              [
                ["system", "Systém"],
                ["light", "Světlý"],
                ["dark", "Tmavý"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => applyTheme(id)}
                className={`rounded-[12px] py-2.5 text-[13px] font-semibold ${
                  theme === id ? "bg-[var(--brand)] text-white" : "bg-[var(--card-inset)]"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </section>
        <section className="hb-card p-4 text-[13px] text-[var(--text-secondary)]">
          Webová verze Hokejbal sdílí data se stejnou Supabase databází jako iOS aplikace. Fantasy,
          tipovačka a amatérské turnaje běží lokálně v prohlížeči.
        </section>
      </div>
    </div>
  );
}

export function MediaScreen() {
  const { pop } = useNav();
  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Dělníci hokejbalu" left={<BackButton onClick={pop} />} />
      <div className="space-y-3 px-[var(--screen-pad)] py-4">
        <a
          href="https://www.youtube.com/@delnicihokejbalu"
          target="_blank"
          rel="noreferrer"
          className="hb-card block overflow-hidden"
          onClick={(e) => {
            if (!trustedOpenUrl("https://www.youtube.com/@delnicihokejbalu")) e.preventDefault();
          }}
        >
          <div className="flex h-40 items-end bg-gradient-to-br from-[var(--ink)] via-[#3a1010] to-[var(--brand)] p-4 text-white">
            <div>
              <div className="text-[18px] font-extrabold">YouTube kanál</div>
              <div className="text-[13px] opacity-80">Rozhovory, reportáže, zákulisí</div>
            </div>
          </div>
        </a>
        <div className="hb-card p-4">
          <div className="font-bold">O projektu</div>
          <p className="hb-muted mt-2 leading-relaxed">
            Série Dělníci hokejbalu přináší příběhy hráčů, trenérů a lidí kolem českého hokejbalu.
          </p>
        </div>
      </div>
    </div>
  );
}

"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchArticleBody } from "@/lib/api";
import { formatNewsDate } from "@/lib/format";
import { DELNICI_CHANNEL_URL, HOME_GRADIENTS, HOME_VIDEOS } from "@/lib/homeContent";
import { trustedOpenUrl } from "@/lib/supabase";
import { CompetitionBadge, PlayerAvatar, TeamBadge } from "@/components/Badges";
import { IconNews } from "@/components/Icons";
import { BackButton, EmptyState, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

export function NewsScreen() {
  const { news } = useCatalog();
  const { pop, push } = useNav();
  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Novinky" systemIcon={<IconNews size={14} />} left={<BackButton onClick={pop} />} />
      <div className="space-y-3 px-4 py-3">
        {news.map((n) => (
          <button
            key={n.id}
            type="button"
            onClick={() => push({ name: "article", id: n.id })}
            className="hb-card w-full overflow-hidden text-left"
          >
            <div
              className="h-[168px] bg-gradient-to-br from-ink to-brand-dark"
              style={
                n.photoURL
                  ? {
                      backgroundImage: `linear-gradient(180deg,transparent 40%,rgba(0,0,0,.55)),url(${n.photoURL})`,
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                    }
                  : undefined
              }
            />
            <div className="space-y-1 p-3.5">
              <div className="text-[11px] font-bold tracking-[0.3px] text-brand uppercase">{n.category}</div>
              <div className="text-[15px] font-bold leading-snug text-hb-fg">{n.title}</div>
              <div className="text-[12px] font-medium text-hb-muted">{formatNewsDate(n.publishedAt)}</div>
            </div>
          </button>
        ))}
        {!news.length && <EmptyState title="Žádné novinky" />}
      </div>
    </div>
  );
}

function ArticleBodySkeleton() {
  return (
    <div className="space-y-3 animate-pulse" aria-hidden>
      <div className="h-3.5 rounded bg-card-inset" />
      <div className="h-3.5 w-[92%] rounded bg-card-inset" />
      <div className="h-3.5 w-[88%] rounded bg-card-inset" />
      <div className="h-3.5 w-[95%] rounded bg-card-inset" />
      <div className="h-3.5 w-[70%] rounded bg-card-inset" />
      <div className="mt-4 h-3.5 rounded bg-card-inset" />
      <div className="h-3.5 w-[90%] rounded bg-card-inset" />
      <div className="h-3.5 w-[80%] rounded bg-card-inset" />
    </div>
  );
}

export function ArticleScreen({ id }: { id: string }) {
  const { news } = useCatalog();
  const { pop } = useNav();
  const article = news.find((n) => n.id === id);
  const [bodyText, setBodyText] = useState<string | null>(null);
  const [isLoadingBody, setIsLoadingBody] = useState(false);
  const [loadFailed, setLoadFailed] = useState(false);

  useEffect(() => {
    if (!article?.articleURL) {
      setLoadFailed(true);
      return;
    }
    let cancelled = false;
    setIsLoadingBody(true);
    setLoadFailed(false);
    setBodyText(null);
    void fetchArticleBody(article.articleURL)
      .then((text) => {
        if (cancelled) return;
        setBodyText(text || null);
        setLoadFailed(!text);
      })
      .catch(() => {
        if (cancelled) return;
        setBodyText(null);
        setLoadFailed(true);
      })
      .finally(() => {
        if (!cancelled) setIsLoadingBody(false);
      });
    return () => {
      cancelled = true;
    };
  }, [article?.id, article?.articleURL]);

  if (!article) return <EmptyState title="Článek nenalezen" />;
  const url = trustedOpenUrl(article.articleURL);

  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader title="" left={<BackButton onClick={pop} />} />
      <div
        className="h-[240px] w-full bg-ink"
        style={
          article.photoURL
            ? {
                backgroundImage: `url(${article.photoURL})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
              }
            : undefined
        }
      />
      <div className="space-y-3.5 px-4 py-4">
        <div className="flex items-center gap-2">
          <span className="rounded-full bg-brand px-2.5 py-1 text-[11px] font-bold tracking-[0.6px] text-on-brand uppercase">
            {article.category}
          </span>
          <span className="ml-auto text-[12px] font-medium text-hb-faint">
            {formatNewsDate(article.publishedAt)}
          </span>
        </div>

        <h1 className="hb-display text-[24px] leading-tight text-hb-fg">{article.title}</h1>

        <div className="h-px bg-card-stroke" />

        {bodyText ? (
          <p className="whitespace-pre-line text-[15px] font-normal leading-[1.55] text-hb-muted">
            {bodyText}
          </p>
        ) : isLoadingBody ? (
          <ArticleBodySkeleton />
        ) : (
          <>
            <p className="text-[15px] font-normal leading-[1.5] text-hb-muted">{article.summary}</p>
            {loadFailed && (
              <p className="pt-1 text-[13px] font-medium text-hb-faint">
                Text článku se nepodařilo načíst.
              </p>
            )}
          </>
        )}

        {url && (
          <a
            href={url}
            target="_blank"
            rel="noreferrer"
            className="inline-block pt-2 text-[12px] font-semibold text-hb-faint underline"
          >
            hokejbal.cz
          </a>
        )}
      </div>
    </div>
  );
}

export function SearchScreen() {
  const { teams, competitions, matches, players, teamById } = useCatalog();
  const { pop, push } = useNav();
  const [q, setQ] = useState("");
  const query = q.trim().toLowerCase();

  const results = useMemo(() => {
    if (query.length < 2) {
      return { teams: [], competitions: [], matches: [], players: [] };
    }
    const uniquePlayers = new Map(players.map((p) => [p.id, p]));
    return {
      teams: teams.filter(
        (t) =>
          t.name.toLowerCase().includes(query) ||
          t.shortName.toLowerCase().includes(query) ||
          t.city.toLowerCase().includes(query)
      ),
      competitions: competitions.filter((c) => c.name.toLowerCase().includes(query)),
      players: [...uniquePlayers.values()]
        .filter(
          (p) =>
            p.firstName.toLowerCase().includes(query) ||
            p.lastName.toLowerCase().includes(query) ||
            `${p.firstName} ${p.lastName}`.toLowerCase().includes(query)
        )
        .slice(0, 30),
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
  }, [query, teams, competitions, matches, players]);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Hledání" left={<BackButton onClick={pop} />} />
      <div className="px-[var(--screen-pad)] py-3">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Tým, hráč, soutěž, zápas…"
          className="w-full rounded-[14px] border border-card-stroke bg-card px-4 py-3 outline-none focus:border-brand"
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
                className="hb-card mb-2 flex w-full items-center gap-3 px-4 py-3 text-left"
                onClick={() => push({ name: "team", id: t.id })}
              >
                <TeamBadge team={t} size={28} />
                <span className="font-semibold">{t.name}</span>
              </button>
            ))}
            {!results.teams.length && <div className="hb-muted">Nic</div>}
          </ResultGroup>
          <ResultGroup title="Hráči">
            {results.players.map((p) => (
              <button
                key={p.id}
                type="button"
                className="hb-card mb-2 flex w-full items-center gap-3 px-4 py-3 text-left"
                onClick={() => push({ name: "player", id: p.id })}
              >
                <PlayerAvatar player={p} size={36} />
                <div>
                  <div className="font-semibold">
                    {p.firstName} {p.lastName}
                  </div>
                  <div className="hb-muted">
                    {teamById(p.teamId)?.shortName ?? p.teamId} · #{p.number}
                  </div>
                </div>
              </button>
            ))}
            {!results.players.length && <div className="hb-muted">Nic</div>}
          </ResultGroup>
          <ResultGroup title="Soutěže">
            {results.competitions.map((c) => (
              <button
                key={c.id}
                type="button"
                className="hb-card mb-2 flex w-full items-center gap-3 px-4 py-3 text-left"
                onClick={() => push({ name: "competition", id: c.id })}
              >
                <CompetitionBadge competition={c} size={28} />
                <span className="font-semibold">{c.name}</span>
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
                  className="hb-card mb-2 flex w-full items-center gap-3 px-4 py-3 text-left font-semibold"
                  onClick={() => push({ name: "match", id: m.id })}
                >
                  <TeamBadge team={home} size={22} />
                  <span>
                    {home?.shortName} – {away?.shortName}
                  </span>
                  <TeamBadge team={away} size={22} />
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
      <h2 className="mb-2 text-[13px] font-bold text-hb-muted">{title}</h2>
      {children}
    </section>
  );
}

export function MediaScreen() {
  const { pop } = useNav();
  return (
    <div className="hb-scroll hb-enter flex-1 bg-canvas">
      <ScreenHeader title="Dělníci hokejbalu" left={<BackButton onClick={pop} />} />
      <div className="space-y-4 px-4 py-4 pb-10">
        <a
          href={trustedOpenUrl(DELNICI_CHANNEL_URL) ?? "#"}
          target="_blank"
          rel="noreferrer"
          className="hb-card hb-card-lg block overflow-hidden"
        >
          <div
            className="flex min-h-[148px] flex-col justify-end p-[18px] text-white"
            style={{ background: "linear-gradient(135deg, #1f4785, #0f2447)" }}
          >
            <div className="hb-display text-[22px]">YouTube kanál</div>
            <div className="mt-2 text-[13px] font-medium text-white/88">
              Rozhovory, reportáže, zákulisí · @delnicihokejbalu
            </div>
            <span className="mt-3 inline-flex w-fit rounded-full bg-white/18 px-3 py-2 text-[12px] font-bold">
              Otevřít kanál ↗
            </span>
          </div>
        </a>

        <div className="space-y-3">
          {HOME_VIDEOS.map((video) => {
            const colors = HOME_GRADIENTS[video.gradientIndex % HOME_GRADIENTS.length];
            return (
              <a
                key={video.id}
                href={trustedOpenUrl(video.url) ?? "#"}
                target="_blank"
                rel="noreferrer"
                className="hb-card flex gap-3 overflow-hidden p-0"
              >
                <div
                  className="relative flex h-16 w-24 shrink-0 items-center justify-center"
                  style={{ background: `linear-gradient(135deg, ${colors[0]}, ${colors[1]})` }}
                >
                  <span className="text-[18px] text-white/95">▶</span>
                  <span className="absolute bottom-1 left-1 rounded bg-[color-mix(in_srgb,var(--brand)_90%,transparent)] px-1.5 py-0.5 text-[8px] font-bold text-white">
                    {video.sourceLabel}
                  </span>
                </div>
                <div className="min-w-0 flex-1 py-2.5 pr-3">
                  <div className="line-clamp-2 text-[13px] font-semibold leading-snug">{video.title}</div>
                  <div className="mt-1 text-[11px] font-medium text-hb-faint">{video.dateLabel}</div>
                </div>
              </a>
            );
          })}
        </div>
      </div>
    </div>
  );
}

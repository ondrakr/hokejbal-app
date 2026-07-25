"use client";

import { useMemo } from "react";
import { trustedOpenUrl } from "@/lib/supabase";
import { formatNewsDate } from "@/lib/format";
import { MatchRow } from "@/components/MatchRow";
import { EmptyState, LoadingState, ScreenHeader, SectionHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

export function HomeScreen() {
  const { matches, news, loading, error } = useCatalog();
  const { push, selectLive, setTab } = useNav();

  const feed = useMemo(() => {
    const live = matches.filter((m) => m.status === "live");
    const upcoming = matches
      .filter((m) => m.status === "scheduled")
      .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt))
      .slice(0, 8);
    const finished = matches
      .filter((m) => m.status === "finished")
      .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt))
      .slice(0, 4);
    return [...live, ...upcoming, ...finished].slice(0, 12);
  }, [matches]);

  if (loading) return <LoadingState />;
  if (error) return <EmptyState title="Chyba načítání" hint={error} />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Hokejbal"
        large
        right={
          <div className="flex gap-1">
            <button
              type="button"
              className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--card)] text-sm font-bold"
              onClick={() => push({ name: "search" })}
              aria-label="Hledat"
            >
              ⌕
            </button>
            <button
              type="button"
              className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--card)] text-sm font-bold"
              onClick={() => push({ name: "settings" })}
              aria-label="Nastavení"
            >
              ⚙
            </button>
          </div>
        }
      />

      <section className="mb-5">
        <SectionHeader
          title="Novinky"
          action={{ label: "Vše", onClick: () => push({ name: "news" }) }}
        />
        <div className="flex gap-3 overflow-x-auto px-[var(--screen-pad)] pb-1">
          {news.slice(0, 5).map((n) => (
            <button
              key={n.id}
              type="button"
              onClick={() => push({ name: "article", id: n.id })}
              className="hb-card w-[260px] shrink-0 overflow-hidden text-left"
            >
              <div
                className="h-28 bg-gradient-to-br from-[#1a1d27] to-[var(--brand-dark)]"
                style={
                  n.photoURL
                    ? {
                        backgroundImage: `linear-gradient(180deg,transparent,rgba(0,0,0,.55)),url(${n.photoURL})`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                      }
                    : undefined
                }
              />
              <div className="space-y-1 p-3">
                <div className="text-[11px] font-semibold text-[var(--brand)]">{n.category}</div>
                <div className="line-clamp-2 text-[14px] font-bold leading-snug">{n.title}</div>
                <div className="hb-muted">{formatNewsDate(n.publishedAt)}</div>
              </div>
            </button>
          ))}
          {!news.length && <EmptyState title="Zatím žádné novinky" />}
        </div>
      </section>

      <section className="mb-5 px-[var(--screen-pad)]">
        <button
          type="button"
          onClick={() => selectLive("broadcasts")}
          className="hb-card flex w-full items-center justify-between px-4 py-3 text-left"
        >
          <div>
            <div className="text-[14px] font-bold">Živé přenosy</div>
            <div className="hb-muted">Sleduj zápasy online</div>
          </div>
          <span className="hb-live-dot" />
        </button>
      </section>

      <section className="mb-5">
        <SectionHeader
          title="Zápasy"
          action={{ label: "Vše", onClick: () => setTab("matches") }}
        />
        <div className="mx-[var(--screen-pad)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--card-stroke)]">
          {feed.map((m) => (
            <MatchRow key={m.id} match={m} />
          ))}
          {!feed.length && <EmptyState title="Žádné zápasy" hint="Zkuste jinou sezónu v Nastavení." />}
        </div>
      </section>

      <section className="mb-5 px-[var(--screen-pad)]">
        <SectionHeader title="Reprezentace" />
        <a
          href="https://www.isbhf.com"
          target="_blank"
          rel="noreferrer"
          className="hb-card mt-2 block px-4 py-3"
          onClick={(e) => {
            const url = trustedOpenUrl("https://www.isbhf.com");
            if (!url) e.preventDefault();
          }}
        >
          <div className="text-[14px] font-bold">ISBHF</div>
          <div className="hb-muted">Mezinárodní hokejbalová federace</div>
        </a>
      </section>

      <section className="mb-8">
        <SectionHeader
          title="Dělníci hokejbalu"
          action={{ label: "Vše", onClick: () => push({ name: "media" }) }}
        />
        <div className="px-[var(--screen-pad)]">
          <button
            type="button"
            onClick={() => push({ name: "media" })}
            className="hb-card w-full overflow-hidden text-left"
          >
            <div className="flex h-28 items-end bg-gradient-to-br from-[var(--ink)] to-[var(--brand-dark)] p-4 text-white">
              <div>
                <div className="text-[15px] font-bold">Videokanál</div>
                <div className="text-[12px] opacity-80">Rozhovory a reportáže</div>
              </div>
            </div>
          </button>
        </div>
      </section>

    </div>
  );
}

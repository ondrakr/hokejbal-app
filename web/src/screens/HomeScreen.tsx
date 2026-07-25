"use client";

import { useEffect, useMemo, useState } from "react";
import { trustedOpenUrl } from "@/lib/supabase";
import { formatNewsDate } from "@/lib/format";
import { LiveBadge, MatchRow } from "@/components/MatchRow";
import { IconChevronRight, IconSearch, IconTv, IconUser } from "@/components/Icons";
import { EmptyState, LoadingState, SectionHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

export function HomeScreen() {
  const { matches, news, loading, error } = useCatalog();
  const { push, selectLive, setTab } = useNav();
  const [newsPage, setNewsPage] = useState(0);

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
    return [...live, ...upcoming, ...finished].slice(0, 10);
  }, [matches]);

  const slides = news.slice(0, 5);

  useEffect(() => {
    if (slides.length < 2) return;
    const id = window.setInterval(() => {
      setNewsPage((p) => (p + 1) % slides.length);
    }, 5000);
    return () => window.clearInterval(id);
  }, [slides.length]);

  if (loading) return <LoadingState />;
  if (error) return <EmptyState title="Chyba načítání" hint={error} />;

  return (
    <div className="hb-scroll hb-enter flex-1">
      {/* Nav: logo + search/profile — HomeView */}
      <header className="hb-nav-bar flex h-11 items-center justify-between px-4">
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-md bg-[var(--brand)] text-[11px] font-extrabold text-white">
            HB
          </div>
          <span className="text-[17px] font-bold tracking-tight">Hokejbal</span>
        </div>
        <div className="flex items-center gap-1">
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-[var(--text-primary)]"
            onClick={() => push({ name: "search" })}
            aria-label="Hledat"
          >
            <IconSearch size={16} />
          </button>
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-[var(--text-primary)]"
            onClick={() => push({ name: "settings" })}
            aria-label="Profil"
          >
            <IconUser size={17} />
          </button>
        </div>
      </header>

      <div className="flex flex-col gap-[26px] pt-3 pb-7">
        {/* Novinky */}
        <section>
          <SectionHeader
            title="Novinky"
            action={{ label: "Vše", onClick: () => push({ name: "news" }) }}
          />
          {slides.length > 0 ? (
            <div className="px-4">
              <button
                type="button"
                onClick={() => push({ name: "article", id: slides[newsPage].id })}
                className="hb-card relative block h-[210px] w-full overflow-hidden text-left"
              >
                <div
                  className="absolute inset-0 bg-gradient-to-br from-[var(--ink-mid)] to-[var(--brand-dark)]"
                  style={
                    slides[newsPage].photoURL
                      ? {
                          backgroundImage: `url(${slides[newsPage].photoURL})`,
                          backgroundSize: "cover",
                          backgroundPosition: "center",
                        }
                      : undefined
                  }
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/15 to-transparent" />
                <div className="absolute left-3 top-3 rounded bg-[var(--brand)] px-2 py-1 text-[10px] font-bold tracking-[0.5px] text-white uppercase">
                  {slides[newsPage].category}
                </div>
                <div className="absolute inset-x-0 bottom-0 space-y-1 p-3.5 text-white">
                  <div className="hb-display line-clamp-3 text-[19px] leading-snug">
                    {slides[newsPage].title}
                  </div>
                  <div className="text-[12px] font-semibold text-white/85">
                    {formatNewsDate(slides[newsPage].publishedAt)}
                  </div>
                </div>
              </button>
              {slides.length > 1 && (
                <div className="mt-2.5 flex justify-center gap-1.5">
                  {slides.map((_, i) => (
                    <button
                      key={i}
                      type="button"
                      aria-label={`Novinka ${i + 1}`}
                      onClick={() => setNewsPage(i)}
                      className={`h-1.5 rounded-full transition-all ${
                        i === newsPage ? "w-4 bg-[var(--brand)]" : "w-1.5 bg-[var(--text-tertiary)]"
                      }`}
                    />
                  ))}
                </div>
              )}
            </div>
          ) : (
            <EmptyState title="Zatím žádné novinky" />
          )}
        </section>

        {/* Živé přenosy CTA */}
        <section className="px-4">
          <button
            type="button"
            onClick={() => selectLive("broadcasts")}
            className="hb-card flex w-full items-center gap-3.5 p-4 text-left"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-[12px] bg-[color-mix(in_srgb,var(--live)_12%,transparent)] text-[var(--live)]">
              <IconTv size={20} />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <span className="text-[16px] font-bold">Živé přenosy</span>
                <LiveBadge compact />
              </div>
              <div className="mt-0.5 text-[12px] font-medium text-[var(--text-secondary)]">
                Sleduj zápasy online
              </div>
            </div>
            <span className="text-[var(--text-tertiary)]">
              <IconChevronRight size={13} />
            </span>
          </button>
        </section>

        {/* Zápasy slider */}
        <section>
          <SectionHeader
            title="Zápasy"
            action={{ label: "Vše", onClick: () => setTab("matches") }}
          />
          <div className="flex gap-3 overflow-x-auto px-4 py-0.5">
            {feed.map((m) => (
              <MatchRow key={m.id} match={m} embedded width={250} showCompetition />
            ))}
            {!feed.length && (
              <div className="hb-card w-full px-4 py-8 text-center text-[13px] text-[var(--text-secondary)]">
                Žádné zápasy
              </div>
            )}
          </div>
        </section>

        {/* Reprezentace */}
        <section className="px-4">
          <SectionHeader title="Reprezentace" />
          <a
            href="https://www.isbhf.com"
            target="_blank"
            rel="noreferrer"
            className="hb-card hb-card-lg mt-2.5 flex min-h-[148px] items-center justify-between overflow-hidden px-[18px] py-3.5 text-white"
            style={{ background: "#00598F" }}
            onClick={(e) => {
              if (!trustedOpenUrl("https://www.isbhf.com")) e.preventDefault();
            }}
          >
            <div>
              <div className="hb-display text-[20px]">ISBHF</div>
              <div className="mt-1 text-[13px] text-white/80">Mezinárodní federace</div>
              <span className="mt-3 inline-flex rounded-full bg-white/18 px-3 py-1.5 text-[12px] font-bold">
                Otevřít web
              </span>
            </div>
            <div className="text-[64px] font-black opacity-25">IS</div>
          </a>
        </section>

        {/* Dělníci */}
        <section>
          <SectionHeader
            title="Dělníci hokejbalu"
            action={{ label: "Vše", onClick: () => push({ name: "media" }) }}
          />
          <div className="px-4">
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

        {/* Partneři */}
        <section>
          <SectionHeader title="Partneři" accent="var(--text-tertiary)" />
          <div className="flex gap-2 overflow-x-auto px-4">
            {["Český hokejbal", "ISBHF", "Extraliga"].map((name) => (
              <div
                key={name}
                className="hb-card shrink-0 px-4 py-3 text-[13px] font-semibold text-[var(--text-secondary)]"
              >
                {name}
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

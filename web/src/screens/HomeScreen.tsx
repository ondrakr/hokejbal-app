"use client";

import { useEffect, useMemo, useState } from "react";
import { trustedOpenUrl } from "@/lib/supabase";
import { formatNewsDate } from "@/lib/format";
import {
  DELNICI_CHANNEL_URL,
  HOME_BANNERS,
  HOME_GRADIENTS,
  HOME_PARTNERS,
  HOME_VIDEOS,
} from "@/lib/homeContent";
import { LiveBadge, MatchRow } from "@/components/MatchRow";
import {
  IconChevronRight,
  IconSearch,
  IconSliders,
  IconTv,
  IconUser,
} from "@/components/Icons";
import { EmptyState, LoadingState, SectionHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";

const CATEGORY_COLORS: Record<string, string> = {
  "CTM a HCŽ": "#eb732e",
  Masters: "#4073c7",
  Mládež: "#2e9e7a",
  "2. liga": "#7359b8",
  Extraliga: "var(--brand)",
  "1. liga": "#33598c",
};

export function HomeScreen() {
  const { matches, news, competitions, loading, error } = useCatalog();
  const { push, selectLive, setTab } = useNav();
  const [newsPage, setNewsPage] = useState(0);
  const [bannerPage, setBannerPage] = useState(0);

  const feed = useMemo(() => {
    const live = matches.filter((m) => m.status === "live");
    const liveIds = new Set(live.map((m) => m.id));
    const upcoming = matches
      .filter((m) => m.status === "scheduled" && !liveIds.has(m.id))
      .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt))
      .slice(0, 8);
    const finished = matches
      .filter((m) => m.status === "finished" && !liveIds.has(m.id))
      .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt))
      .slice(0, 6);
    return [...live, ...upcoming, ...finished].slice(0, 16);
  }, [matches]);

  const slides = news.slice(0, 5);

  useEffect(() => {
    if (slides.length < 2) return;
    const id = window.setInterval(() => {
      setNewsPage((p) => (p + 1) % slides.length);
    }, 5000);
    return () => window.clearInterval(id);
  }, [slides.length]);

  useEffect(() => {
    if (HOME_BANNERS.length < 2) return;
    const id = window.setInterval(() => {
      setBannerPage((p) => (p + 1) % HOME_BANNERS.length);
    }, 6000);
    return () => window.clearInterval(id);
  }, []);

  if (loading) return <LoadingState />;
  if (error) return <EmptyState title="Chyba načítání" hint={error} />;

  const article = slides[newsPage];
  const banner = HOME_BANNERS[bannerPage];
  const bannerColors = HOME_GRADIENTS[banner.gradientIndex % HOME_GRADIENTS.length];

  return (
    <div className="hb-scroll hb-enter flex-1">
      {/* Toolbar = BrandLogo 28 + search/profile — HomeView */}
      <header className="sticky top-0 z-20 flex h-11 items-center justify-between bg-[var(--surface)] px-4">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/brand/BrandLogo.png" alt="Hokejbal" className="h-7 w-auto object-contain" />
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
        {/* NOVINKY — height 230 / card 210 */}
        <section>
          <SectionHeader
            title="Novinky"
            action={{ label: "Vše", onClick: () => push({ name: "news" }) }}
          />
          {article ? (
            <div className="px-4">
              <div className="relative" style={{ height: 230 }}>
              <button
                  type="button"
                  onClick={() => push({ name: "article", id: article.id })}
                  className="hb-card relative block h-[210px] w-full overflow-hidden text-left"
                >
                  <div
                    className="absolute inset-0 bg-gradient-to-br from-[var(--ink-mid)] to-[var(--brand-dark)]"
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
                  <div className="absolute inset-0 bg-gradient-to-t from-black/82 via-black/15 to-transparent" />
                  <div
                    className="absolute left-3 top-3 rounded px-2 py-1 text-[10px] font-bold tracking-[0.5px] text-white uppercase"
                    style={{
                      background: CATEGORY_COLORS[article.category] ?? "var(--brand)",
                      borderRadius: 4,
                    }}
                  >
                    {article.category}
                  </div>
                  <div className="absolute inset-x-0 bottom-0 space-y-1.5 p-3.5 text-left text-white">
                    <div className="hb-display line-clamp-3 text-[19px] leading-snug">
                      {article.title}
                    </div>
                    <div className="text-[12px] font-semibold text-white/85">
                      {formatNewsDate(article.publishedAt)}
                    </div>
                  </div>
                </button>
                {slides.length > 1 && (
                  <div className="mt-2 flex justify-center gap-[5px]">
                    {slides.map((_, i) => (
                      <button
                        key={i}
                        type="button"
                        aria-label={`Novinka ${i + 1}`}
                        onClick={() => setNewsPage(i)}
                        className={`h-[7px] w-[7px] rounded-full ${
                          i === newsPage
                            ? "bg-[color-mix(in_srgb,var(--text-primary)_45%,transparent)]"
                            : "bg-[color-mix(in_srgb,var(--text-primary)_18%,transparent)]"
                        }`}
                      />
                    ))}
                  </div>
                )}
              </div>
            </div>
          ) : (
            <p className="px-4 text-[13px] font-medium text-[var(--text-secondary)]">
              Momentálně nejsou novinky k zobrazení.
            </p>
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
              <div className="mt-1 text-[12px] font-medium text-[var(--text-secondary)]">
                Aktuální zápasy s TV vysíláním
              </div>
            </div>
            <span className="text-[var(--text-tertiary)]">
              <IconChevronRight size={13} />
            </span>
          </button>
        </section>

        {/* Zápasy slider — cards 250 */}
        <section>
          <SectionHeader
            title="Zápasy"
            action={{ label: "Vše", onClick: () => setTab("matches") }}
            accessory={
              <button
                type="button"
                className="flex h-7 w-7 items-center justify-center text-[var(--brand)]"
                aria-label="Nastavit zápasy na Domů"
              >
                <IconSliders size={14} />
              </button>
            }
          />
          <div className="flex gap-3 overflow-x-auto px-4 py-0.5">
            {feed.map((m) => {
              const short =
                competitions.find((c) => c.id === m.competitionId)?.shortName ??
                competitions.find((c) => c.id === m.competitionId)?.name;
              return (
                <MatchRow
                  key={m.id}
                  match={m}
                  embedded
                  width={250}
                  showCompetition
                  competitionName={short}
                />
              );
            })}
            {!feed.length && (
              <p className="px-1 text-[13px] font-medium text-[var(--text-secondary)]">
                Pro vybrané soutěže a týmy teď nejsou zápasy.
              </p>
            )}
          </div>
        </section>

        {/* Bannery — height 168 */}
        <section className="px-4">
          <a
            href={trustedOpenUrl(banner.url) ?? "#"}
            target="_blank"
            rel="noreferrer"
            className="hb-card hb-card-lg relative flex h-[168px] flex-col justify-center overflow-hidden p-[18px] text-white"
            style={{
              background: `linear-gradient(135deg, ${bannerColors[0]}, ${bannerColors[1]})`,
            }}
            onClick={(e) => {
              if (!trustedOpenUrl(banner.url)) e.preventDefault();
            }}
          >
            <div
              className="pointer-events-none absolute top-0 right-6 h-full w-[46px] bg-white/12"
              style={{ clipPath: "polygon(18px 0, 100% 0, calc(100% - 18px) 100%, 0 100%)" }}
            />
            <div className="relative space-y-2">
              <div className="text-[11px] font-bold tracking-[0.6px]">{banner.eyebrow}</div>
              <div className="text-[18px] font-bold">{banner.title}</div>
              <div className="text-[13px] font-medium opacity-90">{banner.subtitle}</div>
              <span className="mt-1 inline-flex rounded-full bg-white/20 px-3 py-2 text-[12px] font-bold uppercase">
                {banner.ctaTitle}
              </span>
            </div>
          </a>
          {HOME_BANNERS.length > 1 && (
            <div className="mt-2 flex justify-center gap-1.5">
              {HOME_BANNERS.map((_, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => setBannerPage(i)}
                  className={`h-[6px] w-[6px] rounded-full ${
                    i === bannerPage ? "bg-[var(--text-secondary)]" : "bg-[var(--text-tertiary)]"
                  }`}
                />
              ))}
            </div>
          )}
        </section>

        {/* Reprezentace / ISBHF */}
        <section className="px-4">
          <a
            href="https://www.isbhf.com"
            target="_blank"
            rel="noreferrer"
            className="hb-card hb-card-lg relative flex min-h-[148px] items-center overflow-hidden text-white"
            style={{ background: "#00598F" }}
            onClick={(e) => {
              if (!trustedOpenUrl("https://www.isbhf.com")) e.preventDefault();
            }}
          >
            <div
              className="pointer-events-none absolute top-0 right-[72px] h-full w-[46px] bg-white/10"
              style={{ clipPath: "polygon(18px 0, 100% 0, calc(100% - 18px) 100%, 0 100%)" }}
            />
            <div className="relative flex-1 py-3.5 pl-[18px] pr-2">
              <div className="hb-display text-[22px]">Reprezentace</div>
              <div className="mt-2 text-[13px] font-medium text-white/88">
                Výsledky, soupisky a MS v oficiální aplikaci.
              </div>
              <span className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-white/18 px-3 py-2 text-[12px] font-bold">
                Otevřít aplikaci ↗
              </span>
            </div>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/brand/ISBHFLogo.png"
              alt=""
              className="relative mr-1.5 h-[128px] w-[128px] object-contain"
            />
          </a>
        </section>

        {/* Dělníci hokejbalu */}
        <section>
          <SectionHeader
            title="Dělníci hokejbalu"
            action={{ label: "Vše", onClick: () => push({ name: "media" }) }}
          />
          <div className="flex gap-3 overflow-x-auto px-4">
            {HOME_VIDEOS.map((video) => {
              const colors = HOME_GRADIENTS[video.gradientIndex % HOME_GRADIENTS.length];
              return (
                <a
                  key={video.id}
                  href={trustedOpenUrl(video.url) ?? "#"}
                  target="_blank"
                  rel="noreferrer"
                  className="w-[260px] shrink-0"
                >
                  <div
                    className="relative flex h-[146px] items-center justify-center overflow-hidden rounded-[var(--radius-md)]"
                    style={{
                      background: `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`,
                    }}
                  >
                    <span className="absolute left-2.5 bottom-2.5 rounded bg-[color-mix(in_srgb,var(--brand)_90%,transparent)] px-2 py-1 text-[10px] font-bold text-white">
                      {video.sourceLabel}
                    </span>
                    <span className="text-[36px] text-white/95">▶</span>
                  </div>
                  <div className="mt-2 line-clamp-2 text-[13px] font-semibold">{video.title}</div>
                  <div className="mt-0.5 text-[11px] font-medium text-[var(--text-tertiary)]">
                    {video.dateLabel}
                  </div>
                </a>
              );
            })}
            <a
              href={trustedOpenUrl(DELNICI_CHANNEL_URL) ?? "#"}
              target="_blank"
              rel="noreferrer"
              className="w-[260px] shrink-0"
            >
              <div
                className="flex h-[146px] flex-col items-center justify-center gap-2.5 rounded-[var(--radius-md)] px-4 text-center text-white"
                style={{
                  background: "linear-gradient(135deg, #1f4785, #0f2447)",
                }}
              >
                <span className="text-[34px]">▣</span>
                <span className="text-[13px] font-bold">Celý kanál Dělníci hokejbalu</span>
              </div>
              <div className="mt-2 text-[13px] font-semibold">YouTube · @delnicihokejbalu</div>
              <div className="text-[11px] font-medium text-[var(--text-tertiary)]">Otevřít kanál</div>
            </a>
          </div>
        </section>

        {/* Partneři */}
        <section>
          <SectionHeader title="Partneři" accent="var(--text-tertiary)" />
          <div className="flex gap-2.5 overflow-x-auto px-4">
            {HOME_PARTNERS.map((p) => (
              <a
                key={p.id}
                href={trustedOpenUrl(p.url) ?? "#"}
                target="_blank"
                rel="noreferrer"
                className="hb-card shrink-0 px-[18px] py-3.5 text-[13px] font-semibold"
                style={{ borderRadius: "var(--radius-sm)" }}
              >
                {p.name}
              </a>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

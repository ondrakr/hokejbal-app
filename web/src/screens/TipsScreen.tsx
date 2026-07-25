"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import { IconChevronRight, IconTrophy, IconUser } from "@/components/Icons";
import { BackButton, ScreenHeader } from "@/components/ui";
import { useCatalog } from "@/stores/catalog";
import { useNav } from "@/stores/navigation";
import { useTips } from "@/stores/tips";

function TipStat({
  title,
  value,
  featured,
}: {
  title: string;
  value: string;
  featured?: boolean;
}) {
  return (
    <div className="overflow-hidden rounded-[12px] border border-card-stroke bg-card">
      <div className="bg-brand px-2 py-1.5 text-center text-[10px] font-bold text-on-brand uppercase">
        {title}
      </div>
      <div
        className={`hb-number text-center font-extrabold text-hb-fg ${
          featured ? "py-3.5 text-[28px]" : "py-2.5 text-[22px]"
        }`}
      >
        {value}
      </div>
    </div>
  );
}

function RuleCard({ title, text }: { title: string; text: string }) {
  return (
    <div className="hb-card space-y-1.5 p-3.5">
      <div className="text-[15px] font-bold text-hb-fg">{title}</div>
      <p className="text-[13px] font-medium leading-snug text-hb-muted">{text}</p>
    </div>
  );
}

function MenuLink({
  icon,
  title,
  onClick,
  last,
}: {
  icon: ReactNode;
  title: string;
  onClick: () => void;
  last?: boolean;
}) {
  return (
    <>
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-center gap-3.5 px-3.5 py-3.5 text-left"
      >
        <span className="flex h-7 w-7 shrink-0 items-center justify-center text-brand [&_svg]:h-4 [&_svg]:w-4">
          {icon}
        </span>
        <span className="min-w-0 flex-1 text-[16px] font-semibold text-hb-fg">{title}</span>
        <span className="text-hb-faint">
          <IconChevronRight size={12} />
        </span>
      </button>
      {!last && (
        <div className="ml-14 h-px bg-[color-mix(in_srgb,var(--separator)_50%,transparent)]" />
      )}
    </>
  );
}

function ProfileEdit({ onClose }: { onClose: () => void }) {
  const tips = useTips();
  const [name, setName] = useState(tips.displayName);

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Profil tipéra"
        left={<BackButton onClick={onClose} />}
        right={
          <button
            type="button"
            className="px-2 text-[15px] font-bold text-brand"
            onClick={() => {
              const trimmed = name.trim();
              if (trimmed) tips.setDisplayName(trimmed);
              onClose();
            }}
          >
            Uložit
          </button>
        }
      />
      <div className="flex flex-col gap-3 px-[var(--screen-pad)] py-4">
        <div className="hb-card p-4">
          <div className="mb-2 text-[12px] font-semibold text-hb-muted">Jméno v žebříčku</div>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Přezdívka"
            className="w-full rounded-[10px] border border-card-stroke bg-card-inset px-3 py-2.5 text-[15px] font-semibold text-hb-fg outline-none"
          />
        </div>
        <p className="text-[12px] font-medium leading-snug text-hb-muted">
          Účty přijdou později — zatím je tipovačka lokální na tomto zařízení.
        </p>
      </div>
    </div>
  );
}

export function TipsScreen({
  screen = "hub",
}: {
  screen?: "hub" | "leaderboard" | "rules";
}) {
  const { pop, push } = useNav();
  const { matches, competitions } = useCatalog();
  const tips = useTips();
  const [editingProfile, setEditingProfile] = useState(false);

  const extraligaIds = useMemo(
    () => new Set(competitions.filter((c) => c.slug === "extraliga").map((c) => c.id)),
    [competitions]
  );

  const tipMatches = useMemo(
    () =>
      matches
        .filter((m) => extraligaIds.has(m.competitionId))
        .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt)),
    [matches, extraligaIds]
  );

  useEffect(() => {
    tips.resolveAgainstMatches(tipMatches);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tipMatches]);

  const myRank = Math.max(1, tips.leaderboard.findIndex((r) => r.isCurrentUser) + 1);
  const accuracy =
    tips.userStats.total > 0 ? Math.round((tips.userStats.correct / tips.userStats.total) * 100) : 0;

  if (editingProfile) {
    return <ProfileEdit onClose={() => setEditingProfile(false)} />;
  }

  if (screen === "rules") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Pravidla" left={<BackButton onClick={pop} />} />
        <div className="flex flex-col gap-3.5 px-[var(--screen-pad)] pt-3 pb-7">
          <RuleCard title="Soutěž" text="Tipovačka platí pro zápasy Extraligy hokejbalu." />
          <RuleCard
            title="Tip"
            text="Před začátkem zápasu tipni vítěze — domácí nebo hosty. Remíza se netipuje."
          />
          <RuleCard
            title="Uzávěrka"
            text="Tipování se uzavírá se začátkem zápasu. Po startu tip už nejde změnit."
          />
          <RuleCard
            title="Body"
            text={`Správný tip = ${tips.pointsPerTip} body. Špatný tip = 0.`}
          />
          <RuleCard
            title="Žebříček"
            text="Pořadí podle bodů za sezónu. Při shodě rozhoduje úspěšnost."
          />
          <RuleCard
            title="Profil"
            text="Přezdívku v žebříčku nastavíš v profilu tipéra (ikona vpravo nahoře)."
          />
        </div>
      </div>
    );
  }

  if (screen === "leaderboard") {
    return (
      <div className="hb-scroll hb-enter flex-1">
        <ScreenHeader title="Žebříček" left={<BackButton onClick={pop} />} />
        <div className="px-[var(--screen-pad)] py-3">
          <div className="hb-card overflow-hidden">
            {tips.leaderboard.map((row, i) => (
              <div
                key={row.id}
                className={`flex items-center gap-3 px-3.5 py-3 ${
                  row.isCurrentUser ? "bg-[color-mix(in_srgb,var(--brand)_8%,transparent)]" : ""
                } ${i > 0 ? "border-t border-[color-mix(in_srgb,var(--separator)_50%,transparent)]" : ""}`}
              >
                <span
                  className={`hb-number w-7 text-[16px] font-extrabold ${
                    row.isCurrentUser ? "text-brand" : "text-hb-muted"
                  }`}
                >
                  {i + 1}
                </span>
                <div className="min-w-0 flex-1">
                  <div
                    className={`truncate text-[15px] text-hb-fg ${
                      row.isCurrentUser ? "font-bold" : "font-semibold"
                    }`}
                  >
                    {row.name}
                  </div>
                  <div className="text-[11px] font-medium text-hb-faint">
                    {row.total > 0
                      ? `${Math.round((row.correct / row.total) * 100)} % · ${row.correct}/${row.total}`
                      : `0 % · ${row.correct}/${row.total}`}
                  </div>
                </div>
                <span className="hb-number text-[15px] font-bold text-hb-muted">{row.points} b</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader
        title="Tipovačka"
        left={<BackButton onClick={pop} />}
        right={
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center text-brand"
            aria-label="Profil tipéra"
            onClick={() => setEditingProfile(true)}
          >
            <IconUser size={20} />
          </button>
        }
      />
      <div className="flex flex-col gap-[18px] px-[var(--screen-pad)] pt-3 pb-7">
        <div className="rounded-[var(--radius-lg)] bg-[linear-gradient(135deg,var(--ink),var(--brand-dark),var(--brand))] p-4 text-white">
          <div className="text-[11px] font-bold tracking-[1px] text-[#ffd647]">EXTRALIGA</div>
          <div className="hb-display mt-2 text-[24px] text-white">Tipuj vítěze zápasu</div>
          <p className="mt-2 text-[13px] font-medium leading-snug text-white/88">
            Tipni domácí nebo hosty před začátkem. Správný tip = {tips.pointsPerTip} body. Lokální
            demo na tomto zařízení.
          </p>
        </div>

        <div className="flex flex-col gap-2.5">
          <div className="text-[12px] font-bold tracking-[0.6px] text-hb-faint">MOJE STATISTIKY</div>
          <TipStat title="Pořadí" value={`#${myRank}`} featured />
          <div className="grid grid-cols-2 gap-2">
            <TipStat title="Body" value={`${tips.userStats.points}`} />
            <TipStat title="Úspěšnost" value={`${accuracy} %`} />
          </div>
        </div>

        <div className="hb-card overflow-hidden">
          <MenuLink
            icon={<IconTrophy size={16} />}
            title="Žebříček"
            onClick={() => push({ name: "tips", screen: "leaderboard" })}
          />
          <MenuLink
            icon={
              <svg width={16} height={16} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
                <path d="M6 4h9a3 3 0 0 1 3 3v13l-1.5-.9L15 20.2l-1.5-1.1L12 20.2l-1.5-1.1L9 20.2l-1.5-1.1L6 20V4zm2 4v2h7V8H8zm0 4v2h5v-2H8z" />
              </svg>
            }
            title="Pravidla"
            onClick={() => push({ name: "tips", screen: "rules" })}
            last
          />
        </div>
      </div>
    </div>
  );
}

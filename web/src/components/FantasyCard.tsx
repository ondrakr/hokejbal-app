"use client";

import type { CSSProperties, ReactNode } from "react";
import { PlayerAvatar, TeamBadge } from "@/components/Badges";
import type { Player, Team } from "@/lib/types";
import {
  TIER_STYLE,
  fantasyPoints,
  playerPrice,
  playerRating,
  positionCardCode,
  tierForRating,
} from "@/stores/fantasy";

export type FantasyCardSize = "compact" | "regular" | "large";

type Metrics = {
  w: number;
  h: number;
  radius: number;
  pad: number;
  ovr: number;
  meta: number;
  name: number;
  avatar: number;
  badge: number;
};

const SIZES: Record<FantasyCardSize, Metrics> = {
  compact: { w: 74, h: 108, radius: 10, pad: 6, ovr: 17, meta: 8, name: 9, avatar: 34, badge: 14 },
  regular: { w: 98, h: 142, radius: 13, pad: 8, ovr: 23, meta: 9, name: 10, avatar: 46, badge: 18 },
  large: { w: 132, h: 190, radius: 16, pad: 11, ovr: 31, meta: 11, name: 13, avatar: 62, badge: 24 },
};

/** Lesk přes celou kartu — nahoře světlo, dole stín (parita s iOS overlay). */
function CardSheen({ radius }: { radius: number }) {
  return (
    <>
      <span
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          borderRadius: radius,
          background:
            "linear-gradient(180deg,rgba(255,255,255,0.24),rgba(255,255,255,0) 45%,rgba(0,0,0,0.28))",
        }}
      />
      <span
        aria-hidden
        className="pointer-events-none absolute inset-0 overflow-hidden"
        style={{ borderRadius: radius }}
      >
        <span
          className="absolute -top-1/2 left-[-30%] h-[200%] w-[45%] rotate-[18deg]"
          style={{
            background:
              "linear-gradient(90deg,rgba(255,255,255,0) 0%,rgba(255,255,255,0.16) 50%,rgba(255,255,255,0) 100%)",
          }}
        />
      </span>
    </>
  );
}

/**
 * FIFA-styl kartička hráče — 1:1 s `FantasyPlayerCard.swift`.
 *
 * OVR a zkratka pozice vlevo nahoře, logo klubu vpravo, fotka uprostřed,
 * příjmení a v patičce cena / body / soupeř. Barva podle tieru (bronze →
 * elite), takže hodnota hráče je vidět na první pohled.
 */
export function FantasyCard({
  player,
  team,
  size = "regular",
  showPrice = true,
  showPoints = false,
  opponentLabel,
  selected,
  dimmed,
  onClick,
  ariaLabel,
}: {
  player: Player;
  team?: Team;
  size?: FantasyCardSize;
  showPrice?: boolean;
  showPoints?: boolean;
  /** Patička s příštím soupeřem — má přednost před cenou / body. */
  opponentLabel?: string | null;
  selected?: boolean;
  dimmed?: boolean;
  onClick?: () => void;
  ariaLabel?: string;
}) {
  const m = SIZES[size];
  const rating = playerRating(player);
  const tier = TIER_STYLE[tierForRating(rating)];
  const price = playerPrice(player);
  const points = fantasyPoints(player);

  const style: CSSProperties = {
    width: m.w,
    height: m.h,
    borderRadius: m.radius,
    background: tier.gradient,
    border: `1.2px solid ${selected ? tier.accent : `color-mix(in srgb, ${tier.accent} 55%, transparent)`}`,
    boxShadow: selected
      ? `0 0 0 2px ${tier.glow}, 0 8px 18px rgba(0,0,0,0.32)`
      : "0 6px 14px rgba(0,0,0,0.28)",
    opacity: dimmed ? 0.45 : 1,
  };

  const footer = (() => {
    if (opponentLabel) return opponentLabel;
    const parts: string[] = [];
    if (showPrice) parts.push(`${price} kr`);
    if (showPoints) parts.push(`${points} b`);
    return parts.join(" · ");
  })();

  const Wrapper = onClick ? "button" : "div";

  return (
    <Wrapper
      {...(onClick ? { type: "button" as const, onClick, "aria-label": ariaLabel } : {})}
      className="relative flex shrink-0 flex-col overflow-hidden text-left transition active:scale-[0.97]"
      style={style}
    >
      <CardSheen radius={m.radius} />

      <span
        className="relative flex items-start justify-between"
        style={{ padding: `${m.pad}px ${m.pad}px 0` }}
      >
        <span className="flex flex-col leading-none">
          <span
            className="hb-number font-black text-white"
            style={{ fontSize: m.ovr, textShadow: "0 1px 2px rgba(0,0,0,0.4)" }}
          >
            {rating}
          </span>
          <span
            className="mt-[3px] font-bold"
            style={{ fontSize: m.meta, color: tier.accent, letterSpacing: "0.4px" }}
          >
            {positionCardCode(player.position)}
          </span>
        </span>
        {team && <TeamBadge team={team} size={m.badge} />}
      </span>

      <span className="relative flex flex-1 items-center justify-center">
        {/* Iniciály leží pod fotkou, takže rozbitý obrázek nenechá kartu prázdnou. */}
        <span
          className="relative flex items-center justify-center overflow-hidden rounded-full"
          style={{
            width: m.avatar,
            height: m.avatar,
            background: "rgba(0,0,0,0.25)",
            boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.18)",
          }}
        >
          <span
            className="font-extrabold text-white/75"
            style={{ fontSize: m.avatar * 0.36, letterSpacing: "0.5px" }}
          >
            {`${player.firstName.charAt(0)}${player.lastName.charAt(0)}`.toUpperCase()}
          </span>
          {player.photoURL && (
            <span className="absolute inset-0">
              <PlayerAvatar player={player} size={m.avatar} circle />
            </span>
          )}
        </span>
      </span>

      <span className="relative flex flex-col items-center" style={{ paddingBottom: m.pad }}>
        <span
          className="max-w-full truncate px-1 font-extrabold uppercase text-white"
          style={{ fontSize: m.name, letterSpacing: "0.2px" }}
        >
          {player.lastName}
        </span>
        {footer && (
          <span
            className="hb-number mt-[3px] max-w-full truncate px-1 font-bold"
            style={{ fontSize: m.meta, color: tier.accent }}
          >
            {footer}
          </span>
        )}
      </span>
    </Wrapper>
  );
}

/**
 * Prázdný slot sestavy — čárkovaná karta s pozicí a „+“.
 *
 * Vizuálně stejně velká jako obsazená karta, aby formace na hřišti nepoletovala
 * podle toho, kolik hráčů je vybraných.
 */
export function FantasyEmptyCard({
  size = "regular",
  positionCode,
  title = "Přidat",
  tone = "dark",
  onClick,
  disabled,
}: {
  size?: FantasyCardSize;
  positionCode: string;
  title?: string;
  /** `dark` = na hřišti, `light` = na světlé kartě (hub). */
  tone?: "dark" | "light";
  onClick?: () => void;
  disabled?: boolean;
}) {
  const m = SIZES[size];
  const Wrapper = onClick ? "button" : "div";
  const dark = tone === "dark";

  return (
    <Wrapper
      {...(onClick ? { type: "button" as const, onClick, disabled } : {})}
      className="flex shrink-0 flex-col items-center justify-center gap-1.5 transition active:scale-[0.97] disabled:opacity-60"
      style={{
        width: m.w,
        height: m.h,
        borderRadius: m.radius,
        background: dark ? "rgba(255,255,255,0.09)" : "var(--card-inset)",
        border: `1.5px dashed ${dark ? "rgba(255,255,255,0.35)" : "var(--separator)"}`,
        color: dark ? "rgba(255,255,255,0.7)" : "var(--text-secondary)",
      }}
    >
      <span
        className="flex items-center justify-center rounded-full font-extrabold"
        style={{
          width: 26,
          height: 26,
          fontSize: 12,
          color: dark ? "#ffd647" : "var(--brand)",
          background: dark
            ? "rgba(255,214,71,0.15)"
            : "color-mix(in srgb, var(--brand) 12%, transparent)",
        }}
      >
        {positionCode}
      </span>
      <span className="text-[18px] font-bold leading-none">+</span>
      <span className="text-[10px] font-bold">{title}</span>
    </Wrapper>
  );
}

/** Malý štítek tieru (Bronze / Silver / Gold / Elite) v barvě karty. */
export function TierChip({ rating, label }: { rating: number; label: string }) {
  const tier = TIER_STYLE[tierForRating(rating)];
  return (
    <span
      className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-[0.4px]"
      style={{ background: tier.gradient, color: tier.accent }}
    >
      {label}
    </span>
  );
}

/** Hřiště pod sestavou — gradient, kruhy a modré čáry. */
export function RinkSurface({ children }: { children: ReactNode }) {
  return (
    <div className="hb-rink relative overflow-hidden rounded-[18px]">
      <span aria-hidden className="hb-rink-lines pointer-events-none absolute inset-0" />
      <div className="relative">{children}</div>
    </div>
  );
}

"use client";

import type { Competition, Player, Team } from "@/lib/types";
import { playerFullName } from "@/lib/types";

export function TeamBadge({ team, size = 24 }: { team?: Team; size?: number }) {
  if (!team) {
    return <div style={{ width: size, height: size }} className="rounded-sm bg-[var(--card-inset)]" />;
  }
  if (team.logoURL) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={team.logoURL}
        alt={team.name}
        width={size}
        height={size}
        className="object-contain"
        style={{ width: size, height: size }}
        loading="lazy"
        referrerPolicy="no-referrer"
      />
    );
  }
  return (
    <div
      className="flex items-center justify-center font-bold"
      style={{
        width: size,
        height: size,
        fontSize: size * 0.34,
        color: team.primaryColorHex?.startsWith("#")
          ? team.primaryColorHex
          : `#${team.primaryColorHex || "C92A2A"}`,
      }}
    >
      {team.logoInitials}
    </div>
  );
}

export function CompetitionBadge({
  competition,
  size = 30,
}: {
  competition?: Competition;
  size?: number;
}) {
  if (competition?.logoURL) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={competition.logoURL}
        alt={competition.name}
        width={size}
        height={size}
        className="object-contain"
        style={{ width: size, height: size }}
        loading="lazy"
        referrerPolicy="no-referrer"
      />
    );
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src="/brand/BrandLogo.png"
      alt=""
      width={size}
      height={size}
      className="object-contain"
      style={{ width: size, height: size }}
    />
  );
}

export function PlayerAvatar({ player, size = 48 }: { player: Player; size?: number }) {
  const initials = `${player.firstName.charAt(0)}${player.lastName.charAt(0)}`.toUpperCase();
  const radius = size * 0.22;
  if (player.photoURL) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={player.photoURL}
        alt={playerFullName(player)}
        width={size}
        height={size}
        className="object-cover"
        style={{ width: size, height: size, borderRadius: radius }}
        loading="lazy"
        referrerPolicy="no-referrer"
      />
    );
  }
  return (
    <div
      className="flex items-center justify-center font-bold text-[var(--brand)]"
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background: "color-mix(in srgb, var(--brand) 12%, transparent)",
        fontSize: size * 0.32,
      }}
    >
      {initials}
    </div>
  );
}

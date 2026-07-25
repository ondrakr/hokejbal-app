"use client";

import type { AmateurTeam } from "@/stores/amateur";

export function AmateurBadge({
  team,
  size = 36,
}: {
  team: AmateurTeam;
  size?: number;
}) {
  return (
    <span
      className="inline-flex shrink-0 items-center justify-center rounded-full font-bold text-white"
      style={{
        width: size,
        height: size,
        fontSize: size * 0.32,
        backgroundColor: `#${team.primaryColorHex.replace(/^#/, "")}`,
      }}
    >
      {team.logoInitials}
    </span>
  );
}

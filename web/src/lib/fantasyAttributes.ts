import type { Player, PlayerPosition } from "@/lib/types";

/**
 * FIFA-styl parametry hráče — 1:1 port `FantasyAttributes.swift`.
 *
 * Hodnoty 1–99 vyplňují trenéři klubů (tabulka `player_attributes`). Všechny
 * jsou volitelné: hráč bez parametrů dostane OVR ze statistik, takže kartu má
 * každý. Bruslaři mají sedm parametrů, brankáři vlastních šest.
 */
export type PlayerAttributes = {
  playerId: string;
  // Bruslaři
  speed?: number;
  strength?: number;
  shooting?: number;
  passing?: number;
  dribbling?: number;
  iq?: number;
  defense?: number;
  // Brankáři
  reflexes?: number;
  positioning?: number;
  glove?: number;
  blocker?: number;
  rebound?: number;
  composure?: number;
  /** Ruční override OVR (server) — přebíjí vážený průměr. */
  overall?: number;
};

export type AttributeRow = { label: string; value: number };

const SKATER_LABELS: [keyof PlayerAttributes, string][] = [
  ["speed", "Rychlost"],
  ["strength", "Síla"],
  ["shooting", "Střela"],
  ["passing", "Přihrávka"],
  ["dribbling", "Dribling"],
  ["iq", "Chytrost"],
  ["defense", "Obrana"],
];

const GOALIE_LABELS: [keyof PlayerAttributes, string][] = [
  ["reflexes", "Reflexy"],
  ["positioning", "Postavení"],
  ["glove", "Lapačka"],
  ["blocker", "Vyrážečka"],
  ["rebound", "Vyrážení"],
  ["composure", "Klid"],
];

/** Vyplněné parametry pro pozici, v pořadí pro vykreslení. */
export function attributeRows(
  attrs: PlayerAttributes | undefined,
  position: PlayerPosition
): AttributeRow[] {
  if (!attrs) return [];
  const labels = position === "goalie" ? GOALIE_LABELS : SKATER_LABELS;
  return labels
    .map(([key, label]) => ({ label, value: attrs[key] as number | undefined }))
    .filter((row): row is AttributeRow => typeof row.value === "number");
}

const WEIGHTS: Record<PlayerPosition, [keyof PlayerAttributes, number][]> = {
  forward: [
    ["shooting", 0.25],
    ["speed", 0.2],
    ["dribbling", 0.15],
    ["iq", 0.15],
    ["passing", 0.15],
    ["strength", 0.05],
    ["defense", 0.05],
  ],
  defenseman: [
    ["defense", 0.28],
    ["iq", 0.18],
    ["strength", 0.18],
    ["passing", 0.16],
    ["speed", 0.1],
    ["shooting", 0.05],
    ["dribbling", 0.05],
  ],
  goalie: [
    ["reflexes", 1],
    ["positioning", 1],
    ["glove", 1],
    ["blocker", 1],
    ["rebound", 1],
    ["composure", 1],
  ],
};

function clampRating(value: number) {
  return Math.min(99, Math.max(1, value));
}

/**
 * OVR z parametrů — číslo na kartě.
 *
 * Váhy se liší podle pozice (útočníka nese střela a rychlost, obránce obrana
 * a síla; brankáři mají všech šest stejně). Průměruje se jen přes **vyplněné**
 * parametry, takže částečně ohodnocený hráč není tažen dolů.
 *
 * @returns OVR 1–99, nebo `null` když není vyplněný ani jeden parametr.
 */
export function computedOverall(
  attrs: PlayerAttributes | undefined,
  position: PlayerPosition
): number | null {
  if (!attrs) return null;
  if (typeof attrs.overall === "number") return clampRating(attrs.overall);

  let sum = 0;
  let totalWeight = 0;
  for (const [key, weight] of WEIGHTS[position]) {
    const value = attrs[key] as number | undefined;
    if (typeof value !== "number") continue;
    sum += value * weight;
    totalWeight += weight;
  }
  if (totalWeight <= 0) return null;
  return clampRating(Math.round(sum / totalWeight));
}

// MARK: - Mock (demo režim)

/** Demo režim — parametry se generují lokálně, nic se neposílá na server. */
export const FANTASY_MOCK_ENABLED = true;

/** Hráči s napevno nastaveným OVR bez ohledu na statistiky. */
const STAR_OVERALL: Record<string, number> = {
  čejka: 99,
  cejka: 99,
  mácha: 93,
  macha: 93,
};

/**
 * Deterministický šum −6…+6 (FNV-1a) — stejný vstup vždy stejné číslo,
 * takže se parametry hráče nemění mezi otevřeními obrazovky.
 */
function jitter(seed: string) {
  let hash = 2166136261;
  for (let i = 0; i < seed.length; i += 1) {
    hash ^= seed.charCodeAt(i);
    hash = Math.imul(hash, 16777619) >>> 0;
  }
  return (hash % 13) - 6;
}

function clampAttribute(value: number) {
  return Math.min(99, Math.max(40, value));
}

/**
 * Vygeneruje parametry hráče kolem cílové úrovně (rating ze statistik nebo
 * napevno nastavené OVR hvězdy) s posunem podle pozice a šumem ±6.
 */
export function mockAttributes(player: Player, statRating: number): PlayerAttributes {
  const star = STAR_OVERALL[player.lastName.toLowerCase()];
  const center = star ?? statRating;
  const value = (salt: string, bias: number) =>
    clampAttribute(center + bias + jitter(player.id + salt));

  switch (player.position) {
    case "forward":
      return {
        playerId: player.id,
        speed: value("sp", 4),
        strength: value("st", -5),
        shooting: value("sh", 5),
        passing: value("pa", 1),
        dribbling: value("dr", 3),
        iq: value("iq", 1),
        defense: value("df", -7),
        overall: star,
      };
    case "defenseman":
      return {
        playerId: player.id,
        speed: value("sp", -1),
        strength: value("st", 5),
        shooting: value("sh", -3),
        passing: value("pa", 2),
        dribbling: value("dr", -3),
        iq: value("iq", 3),
        defense: value("df", 6),
        overall: star,
      };
    case "goalie":
      return {
        playerId: player.id,
        reflexes: value("rf", 4),
        positioning: value("po", 3),
        glove: value("gl", 2),
        blocker: value("bl", 1),
        rebound: value("rb", 0),
        composure: value("co", 2),
        overall: star,
      };
  }
}

"use client";

import type { ReactNode } from "react";
import type { TabId } from "@/stores/navigation";
import { useNav } from "@/stores/navigation";

const TABS: { id: TabId; label: string; icon: string }[] = [
  { id: "home", label: "Domů", icon: "⌂" },
  { id: "matches", label: "Zápasy", icon: "⬡" },
  { id: "live", label: "LIVE", icon: "◉" },
  { id: "favorites", label: "Oblíbené", icon: "★" },
  { id: "more", label: "Více", icon: "⋯" },
];

export function TabBar() {
  const { tab, setTab, stack } = useNav();
  if (stack.length > 0) return null;
  return (
    <nav className="grid shrink-0 grid-cols-5 border-t border-[var(--separator)] bg-[var(--card)] pb-[env(safe-area-inset-bottom)] md:pb-3">
      {TABS.map((t) => {
        const active = tab === t.id;
        return (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            className={`flex flex-col items-center gap-0.5 py-2 text-[10px] font-semibold ${
              active ? "text-[var(--brand)]" : "text-[var(--text-secondary)]"
            }`}
          >
            <span className={`text-[18px] leading-none ${t.id === "live" && active ? "hb-live-dot !w-3 !h-3 mb-1" : ""}`}>
              {t.id === "live" && active ? "" : t.icon}
            </span>
            {t.label}
          </button>
        );
      })}
    </nav>
  );
}

export function ScreenHeader({
  title,
  subtitle,
  left,
  right,
  large,
}: {
  title: string;
  subtitle?: string;
  left?: ReactNode;
  right?: ReactNode;
  large?: boolean;
}) {
  return (
    <header className="sticky top-0 z-20 border-b border-[var(--separator)] bg-[var(--canvas)]/95 px-[var(--screen-pad)] backdrop-blur">
      <div className="flex items-center gap-2 py-2">
        <div className="w-10 shrink-0">{left}</div>
        <div className="min-w-0 flex-1 text-center">
          {!large && (
            <>
              <div className="truncate text-[15px] font-bold tracking-tight">{title}</div>
              {subtitle && <div className="hb-muted truncate">{subtitle}</div>}
            </>
          )}
        </div>
        <div className="flex w-10 shrink-0 justify-end">{right}</div>
      </div>
      {large && (
        <div className="pb-3">
          <h1 className="font-[family-name:var(--font-display)] text-[28px] font-extrabold tracking-tight">
            {title}
          </h1>
          {subtitle && <p className="hb-muted mt-0.5">{subtitle}</p>}
        </div>
      )}
    </header>
  );
}

export function BackButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--card-inset)] text-lg font-bold"
      aria-label="Zpět"
    >
      ‹
    </button>
  );
}

export function EmptyState({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-8 py-16 text-center">
      <div className="text-[15px] font-semibold">{title}</div>
      {hint && <p className="hb-muted">{hint}</p>}
    </div>
  );
}

export function LoadingState({ label = "Načítám…" }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-20">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--brand)] border-t-transparent" />
      <div className="hb-muted">{label}</div>
    </div>
  );
}

export function SectionHeader({
  title,
  action,
}: {
  title: string;
  action?: { label: string; onClick: () => void };
}) {
  return (
    <div className="mb-2 flex items-end justify-between gap-3 px-[var(--screen-pad)]">
      <h2 className="hb-section-title">{title}</h2>
      {action && (
        <button type="button" onClick={action.onClick} className="text-[13px] font-semibold text-[var(--brand)]">
          {action.label}
        </button>
      )}
    </div>
  );
}

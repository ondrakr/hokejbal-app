"use client";

import type { ReactNode } from "react";
import {
  IconChevronLeft,
  IconChevronRight,
  IconCourt,
  IconHome,
  IconLive,
  IconMore,
  IconStar,
} from "@/components/Icons";
import type { TabId } from "@/stores/navigation";
import { useNav } from "@/stores/navigation";

const TABS: { id: TabId; label: string; icon: (active: boolean) => ReactNode }[] = [
  { id: "home", label: "Domů", icon: (a) => <IconHome filled={a} /> },
  { id: "matches", label: "Zápasy", icon: () => <IconCourt /> },
  { id: "live", label: "LIVE", icon: () => <IconLive /> },
  { id: "favorites", label: "Oblíbené", icon: (a) => <IconStar filled={a} /> },
  { id: "more", label: "Více", icon: (a) => <IconMore filled={a} /> },
];

export function TabBar() {
  const { tab, setTab, stack } = useNav();
  if (stack.length > 0) return null;
  return (
    <nav className="grid h-[49px] shrink-0 grid-cols-5 border-t border-[var(--separator)] bg-[var(--surface)] pb-[env(safe-area-inset-bottom)] md:pb-2">
      {TABS.map((t) => {
        const active = tab === t.id;
        return (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            className={`flex flex-col items-center justify-center gap-0.5 text-[10px] font-medium ${
              active ? "text-[var(--brand)]" : "text-[var(--text-secondary)]"
            }`}
          >
            <span className="flex h-[22px] items-center">{t.icon(active)}</span>
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
  systemImage,
}: {
  title: string;
  subtitle?: string;
  left?: ReactNode;
  right?: ReactNode;
  large?: boolean;
  systemImage?: boolean;
}) {
  if (large) {
    return (
      <header className="hb-nav-bar px-[var(--screen-pad)] pt-2 pb-1">
        <div className="mb-1 flex items-center justify-end gap-2 min-h-[28px]">{right}</div>
        <h1 className="hb-display text-[34px] leading-tight tracking-tight">{title}</h1>
        {subtitle && <p className="hb-muted mt-0.5">{subtitle}</p>}
      </header>
    );
  }

  return (
    <header className="hb-nav-bar sticky top-0 z-20 px-[var(--screen-pad)]">
      <div className="flex h-11 items-center gap-2">
        <div className="flex w-16 shrink-0 justify-start">{left}</div>
        <div className="flex min-w-0 flex-1 items-center justify-center gap-[7px]">
          {systemImage ? (
            <span className="text-[14px] font-bold text-[var(--brand)]">●</span>
          ) : null}
          <div className="truncate text-[17px] font-bold tracking-tight">{title}</div>
        </div>
        <div className="flex w-16 shrink-0 justify-end">{right}</div>
      </div>
      {subtitle && <div className="hb-muted -mt-1 pb-2 text-center text-[12px]">{subtitle}</div>}
    </header>
  );
}

export function BackButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex h-9 w-9 items-center justify-center text-[var(--brand)]"
      aria-label="Zpět"
    >
      <IconChevronLeft size={22} />
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
      <div className="h-7 w-7 animate-spin rounded-full border-2 border-[var(--brand)] border-t-transparent" />
      <div className="hb-muted">{label}</div>
    </div>
  );
}

/** HBSectionHeader */
export function SectionHeader({
  title,
  action,
  accent,
  accessory,
}: {
  title: string;
  action?: { label: string; onClick: () => void };
  accent?: string;
  accessory?: ReactNode;
}) {
  return (
    <div className="mb-2.5 flex items-center gap-2.5 px-[var(--screen-pad)]">
      <span className="hb-accent-bar" style={accent ? { background: accent } : undefined} />
      <h2 className="hb-display text-[17px] tracking-[0.5px] uppercase">{title}</h2>
      {accessory}
      <div className="min-w-2 flex-1" />
      {action && (
        <button
          type="button"
          onClick={action.onClick}
          className="inline-flex items-center gap-[3px] text-[13px] font-bold text-[var(--brand)]"
        >
          {action.label}
          <IconChevronRight size={10} />
        </button>
      )}
    </div>
  );
}

export function MoreMenuRow({
  icon,
  title,
  onClick,
}: {
  icon: ReactNode;
  title: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="hb-card flex w-full items-center gap-3.5 px-3.5 py-3.5 text-left"
    >
      <span className="flex h-7 w-7 items-center justify-center text-[var(--brand)]">{icon}</span>
      <span className="flex-1 text-[16px] font-semibold">{title}</span>
      <span className="text-[var(--text-tertiary)]">
        <IconChevronRight size={12} />
      </span>
    </button>
  );
}

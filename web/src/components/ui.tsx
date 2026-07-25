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
import { BrandLoading } from "@/components/BrandLoading";
import type { TabId } from "@/stores/navigation";
import { useNav } from "@/stores/navigation";

const TABS: { id: TabId; label: string; icon: () => ReactNode }[] = [
  { id: "home", label: "Domů", icon: () => <IconHome /> },
  { id: "matches", label: "Zápasy", icon: () => <IconCourt /> },
  { id: "live", label: "LIVE", icon: () => <IconLive /> },
  { id: "favorites", label: "Oblíbené", icon: () => <IconStar filled /> },
  { id: "more", label: "Více", icon: () => <IconMore filled /> },
];

export function TabBar() {
  const { tab, setTab, stack } = useNav();
  if (stack.length > 0) return null;
  return (
    <nav className="hb-tab-bar">
      {TABS.map((t) => {
        const active = tab === t.id;
        return (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            className="hb-tab-item"
            data-active={active}
          >
            {t.icon()}
            <span>{t.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

/** Port hbNavTitle — ikona brand + title 17 bold centered */
export function ScreenHeader({
  title,
  subtitle,
  left,
  right,
  systemIcon,
}: {
  title: string;
  subtitle?: string;
  left?: ReactNode;
  right?: ReactNode;
  /** SF-like ikona vlevo od titulku (brand) */
  systemIcon?: ReactNode;
}) {
  return (
    <header className="hb-nav-bar sticky top-0 z-20 shrink-0">
      <div className="relative flex h-11 items-center px-2">
        <div className="z-10 flex min-w-[56px] items-center justify-start">{left}</div>
        <div className="pointer-events-none absolute inset-x-14 flex items-center justify-center gap-[7px]">
          {systemIcon ? (
            <span className="flex h-[18px] w-[18px] items-center justify-center text-brand [&_svg]:h-[14px] [&_svg]:w-[14px]">
              {systemIcon}
            </span>
          ) : null}
          <div className="truncate text-[17px] font-bold tracking-tight text-hb-fg">{title}</div>
        </div>
        <div className="z-10 ml-auto flex min-w-[56px] items-center justify-end gap-1">{right}</div>
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
      className="flex h-9 w-9 items-center justify-center text-brand"
      aria-label="Zpět"
    >
      <IconChevronLeft size={22} />
    </button>
  );
}

export function EmptyState({
  title,
  hint,
  action,
}: {
  title: string;
  hint?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 px-8 py-16 text-center">
      <div className="text-[15px] font-semibold text-hb-fg">{title}</div>
      {hint && <p className="hb-muted max-w-[280px] text-[13px] leading-snug">{hint}</p>}
      {action}
    </div>
  );
}

export function LoadingState({ label }: { label?: string }) {
  if (label) {
    return <BrandLoading message={label} logoSize={72} />;
  }
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-20">
      <div className="h-7 w-7 animate-spin rounded-full border-2 border-brand border-t-transparent" />
      <div className="hb-muted">Načítám…</div>
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
      <h2 className="hb-display text-[17px] tracking-[0.5px] text-hb-fg uppercase">{title}</h2>
      {accessory}
      <div className="min-w-2 flex-1" />
      {action && (
        <button type="button" onClick={action.onClick} className="hb-section-action">
          {action.label}
          <IconChevronRight size={10} />
        </button>
      )}
    </div>
  );
}

/** MoreMenuRowLabel — MoreView.swift */
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
    <button type="button" onClick={onClick} className="hb-card flex w-full items-center gap-3.5 px-3.5 py-3.5 text-left">
      <span className="flex h-7 w-7 shrink-0 items-center justify-center text-brand [&_svg]:h-[18px] [&_svg]:w-[18px]">
        {icon}
      </span>
      <span className="min-w-0 flex-1 text-[16px] font-semibold text-hb-fg">{title}</span>
      <span className="text-hb-faint">
        <IconChevronRight size={12} />
      </span>
    </button>
  );
}

"use client";

import type { ReactNode, SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function IconBase({ size = 20, children, ...rest }: IconProps & { children: ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      {...rest}
    >
      {children}
    </svg>
  );
}

export function IconHome({ size = 22, filled }: IconProps & { filled?: boolean }) {
  return (
    <IconBase size={size} fill={filled ? "currentColor" : "none"}>
      <path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1v-9.5z" />
    </IconBase>
  );
}

export function IconCourt({ size = 22 }: IconProps) {
  return (
    <IconBase size={size}>
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="M12 5v14M3 12h18" />
    </IconBase>
  );
}

export function IconLive({ size = 22 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M4.9 16.1A7 7 0 0 1 12 5a7 7 0 0 1 7.1 11.1" />
      <path d="M7.8 13.2A3.5 3.5 0 0 1 12 8.5a3.5 3.5 0 0 1 4.2 4.7" />
      <circle cx="12" cy="14.5" r="1.2" fill="currentColor" stroke="none" />
    </IconBase>
  );
}

export function IconStar({ size = 22, filled }: IconProps & { filled?: boolean }) {
  return (
    <IconBase size={size} fill={filled ? "currentColor" : "none"}>
      <path d="m12 3 2.7 5.5 6 .9-4.4 4.2 1 6L12 16.9 6.7 19.6l1-6L3.4 9.4l6-.9L12 3z" />
    </IconBase>
  );
}

export function IconMore({ size = 22, filled }: IconProps & { filled?: boolean }) {
  return (
    <IconBase size={size} fill={filled ? "currentColor" : "none"}>
      <circle cx="12" cy="12" r="9" />
      <circle cx="8" cy="12" r="1" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1" fill="currentColor" stroke="none" />
      <circle cx="16" cy="12" r="1" fill="currentColor" stroke="none" />
    </IconBase>
  );
}

export function IconSearch({ size = 16 }: IconProps) {
  return (
    <IconBase size={size}>
      <circle cx="11" cy="11" r="7" />
      <path d="m20 20-3.5-3.5" />
    </IconBase>
  );
}

export function IconUser({ size = 17 }: IconProps) {
  return (
    <IconBase size={size}>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c1.5-4 14.5-4 16 0" />
    </IconBase>
  );
}

export function IconChevronRight({ size = 12 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.5}>
      <path d="m9 6 6 6-6 6" />
    </IconBase>
  );
}

export function IconChevronLeft({ size = 18 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.5}>
      <path d="m15 6-6 6 6 6" />
    </IconBase>
  );
}

export function IconTv({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <rect x="3" y="5" width="18" height="13" rx="2" />
      <path d="M8 21h8M12 18v3" />
    </IconBase>
  );
}

export function IconTrophy({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M8 4h8v5a4 4 0 0 1-8 0V4z" />
      <path d="M8 6H5a2 2 0 0 0 2 4M16 6h3a2 2 0 0 1-2 4M10 18h4M12 13v5" />
    </IconBase>
  );
}

export function IconTarget({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <circle cx="12" cy="12" r="8" />
      <circle cx="12" cy="12" r="4" />
      <circle cx="12" cy="12" r="1" fill="currentColor" stroke="none" />
    </IconBase>
  );
}

export function IconFlag({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M5 3v18M5 4h11l-2 3 2 3H5" />
    </IconBase>
  );
}

export function IconGear({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <circle cx="12" cy="12" r="3" />
      <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
    </IconBase>
  );
}

export function IconNews({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M4 5h12v14H4zM16 8h4v11a2 2 0 0 1-2 2H6" />
      <path d="M7 9h6M7 13h6M7 17h4" />
    </IconBase>
  );
}

export function IconHeadphones({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M4 13v3a2 2 0 0 0 2 2h1v-7H6a2 2 0 0 0-2 2zM17 11h1a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-1v-7z" />
      <path d="M4 13a8 8 0 0 1 16 0" />
    </IconBase>
  );
}

"use client";

import type { ReactNode, SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function IconBase({
  size = 20,
  children,
  fill = "none",
  strokeWidth = 1.8,
  ...rest
}: IconProps & { children: ReactNode; fill?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={fill}
      stroke={fill === "none" ? "currentColor" : "none"}
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      {...rest}
    >
      {children}
    </svg>
  );
}

/** SF Symbol house.fill */
export function IconHome({ size = 22, filled }: IconProps & { filled?: boolean }) {
  if (filled) {
    return (
      <IconBase size={size} fill="currentColor" strokeWidth={0}>
        <path d="M3.5 10.8 12 3.5l8.5 7.3V20a1.2 1.2 0 0 1-1.2 1.2h-4.6v-6.2h-5.4V21.2H4.7A1.2 1.2 0 0 1 3.5 20V10.8z" />
      </IconBase>
    );
  }
  return (
    <IconBase size={size}>
      <path d="M3.5 10.8 12 3.5l8.5 7.3V20a1.2 1.2 0 0 1-1.2 1.2h-4.6v-6.2h-5.4V21.2H4.7A1.2 1.2 0 0 1 3.5 20V10.8z" />
    </IconBase>
  );
}

/** sportscourt-ish */
export function IconCourt({ size = 22 }: IconProps) {
  return (
    <IconBase size={size}>
      <rect x="3" y="5" width="18" height="14" rx="2.5" />
      <path d="M12 5v14M3 12h18" />
    </IconBase>
  );
}

/** dot.radiowaves.left.and.right */
export function IconLive({ size = 22 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M5 16a7.5 7.5 0 0 1 0-8" />
      <path d="M8.2 14a4.2 4.2 0 0 1 0-4" />
      <circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none" />
      <path d="M15.8 14a4.2 4.2 0 0 0 0-4" />
      <path d="M19 16a7.5 7.5 0 0 0 0-8" />
    </IconBase>
  );
}

export function IconStar({ size = 22, filled }: IconProps & { filled?: boolean }) {
  return (
    <IconBase size={size} fill={filled ? "currentColor" : "none"}>
      <path d="m12 3.2 2.4 4.9 5.4.8-3.9 3.8.9 5.4L12 15.8 7.2 18.1l.9-5.4-3.9-3.8 5.4-.8L12 3.2z" />
    </IconBase>
  );
}

export function IconMore({ size = 22, filled }: IconProps & { filled?: boolean }) {
  return (
    <IconBase size={size} fill={filled ? "currentColor" : "none"}>
      <circle cx="12" cy="12" r="9" />
      <circle cx="8" cy="12" r="1.15" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.15" fill="currentColor" stroke="none" />
      <circle cx="16" cy="12" r="1.15" fill="currentColor" stroke="none" />
    </IconBase>
  );
}

export function IconSearch({ size = 16 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2}>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m20 20-3.8-3.8" />
    </IconBase>
  );
}

export function IconUser({ size = 17 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.9}>
      <circle cx="12" cy="8" r="3.6" />
      <path d="M4.8 19.2c1.2-3.4 13.2-3.4 14.4 0" />
    </IconBase>
  );
}

export function IconChevronRight({ size = 12 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.4}>
      <path d="m9 5.5 6 6.5-6 6.5" />
    </IconBase>
  );
}

export function IconChevronLeft({ size = 18 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.4}>
      <path d="m15 5.5-6 6.5 6 6.5" />
    </IconBase>
  );
}

export function IconTv({ size = 18 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.9}>
      <rect x="3" y="5" width="18" height="12.5" rx="2" />
      <path d="M8 20.5h8M12 17.5v3" />
    </IconBase>
  );
}

export function IconSliders({ size = 14 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2}>
      <path d="M4 7h10M18 7h2M4 17h2M10 17h10M14 4v6M8 14v6" />
    </IconBase>
  );
}

export function IconTrophy({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M8 4h8v5a4 4 0 0 1-8 0V4z" />
      <path d="M8 6H5.5A2 2 0 0 0 7.5 10M16 6h2.5A2 2 0 0 1 16.5 10M10 18h4M12 13v5" />
    </IconBase>
  );
}

export function IconTarget({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <circle cx="12" cy="12" r="8" />
      <circle cx="12" cy="12" r="4" />
      <circle cx="12" cy="12" r="1.2" fill="currentColor" stroke="none" />
    </IconBase>
  );
}

export function IconFlag({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <path d="M5 3v18M5 4h11l-2.2 3.2L16 10.5H5" />
    </IconBase>
  );
}

export function IconGear({ size = 18 }: IconProps) {
  return (
    <IconBase size={size}>
      <circle cx="12" cy="12" r="3" />
      <path d="M12 2.5v2.2M12 19.3v2.2M4.6 4.6l1.6 1.6M17.8 17.8l1.6 1.6M2.5 12h2.2M19.3 12h2.2M4.6 19.4l1.6-1.6M17.8 6.2l1.6-1.6" />
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
      <path d="M4 13.5v2.5a2 2 0 0 0 2 2h1.2v-7H6a2 2 0 0 0-2 2.5zM16.8 11H18a2 2 0 0 1 2 2.5v2.5a2 2 0 0 1-2 2h-1.2v-7z" />
      <path d="M4 13.5a8 8 0 0 1 16 0" />
    </IconBase>
  );
}

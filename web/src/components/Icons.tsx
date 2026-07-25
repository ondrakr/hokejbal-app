"use client";

import type { ReactNode, SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function IconBase({
  size = 20,
  children,
  fill = "none",
  strokeWidth = 1.8,
  viewBox = "0 0 24 24",
  ...rest
}: IconProps & { children: ReactNode; fill?: string; viewBox?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox={viewBox}
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

/** SF Symbol house.fill / house */
export function IconHome({ size = 25, filled }: IconProps & { filled?: boolean }) {
  if (filled) {
    return (
      <IconBase size={size} fill="currentColor" strokeWidth={0} viewBox="0 0 24 24">
        <path d="M11.47 3.84a.75.75 0 0 1 1.06 0l8.69 8.69a.75.75 0 1 1-1.06 1.06l-.72-.72V19.5A1.5 1.5 0 0 1 17.94 21H6.06A1.5 1.5 0 0 1 4.56 19.5v-6.63l-.72.72a.75.75 0 0 1-1.06-1.06l8.69-8.69ZM6.06 19.5h3.19v-4.13c0-.41.34-.75.75-.75h3.5c.41 0 .75.34.75.75v4.13h3.69V11.4L12 5.66 6.06 11.4v8.1Z" />
      </IconBase>
    );
  }
  return (
    <IconBase size={size} strokeWidth={1.7}>
      <path d="M4.5 10.9 12 4.2l7.5 6.7V19a1.3 1.3 0 0 1-1.3 1.3h-4.2v-5.6h-4V20.3H5.8A1.3 1.3 0 0 1 4.5 19V10.9z" />
    </IconBase>
  );
}

/** SF Symbol sportscourt */
export function IconCourt({ size = 25 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.55}>
      <rect x="3.2" y="5.2" width="17.6" height="13.6" rx="2.2" />
      <path d="M12 5.2v13.6M3.2 12h17.6" />
      <path d="M3.2 9.2h2.4M3.2 14.8h2.4M18.4 9.2h2.4M18.4 14.8h2.4" />
    </IconBase>
  );
}

/** SF Symbol dot.radiowaves.left.and.right */
export function IconLive({ size = 25 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.7}>
      <circle cx="12" cy="12" r="1.55" fill="currentColor" stroke="none" />
      <path d="M8.15 15.1a5.2 5.2 0 0 1 0-6.2" />
      <path d="M5.2 17.2a8.4 8.4 0 0 1 0-10.4" />
      <path d="M15.85 15.1a5.2 5.2 0 0 0 0-6.2" />
      <path d="M18.8 17.2a8.4 8.4 0 0 0 0-10.4" />
    </IconBase>
  );
}

/** SF Symbol star / star.fill */
export function IconStar({ size = 25, filled }: IconProps & { filled?: boolean }) {
  return (
    <IconBase size={size} fill={filled ? "currentColor" : "none"} strokeWidth={1.6}>
      <path d="m12 3.4 2.55 5.17 5.71.83-4.13 4.03.98 5.7L12 16.4l-5.11 2.73.98-5.7-4.13-4.03 5.71-.83L12 3.4z" />
    </IconBase>
  );
}

/** SF Symbol ellipsis.circle / ellipsis.circle.fill */
export function IconMore({ size = 25, filled }: IconProps & { filled?: boolean }) {
  if (filled) {
    return (
      <IconBase size={size} fill="currentColor" strokeWidth={0}>
        <circle cx="12" cy="12" r="9.2" />
        <circle cx="7.8" cy="12" r="1.25" fill="#fff" />
        <circle cx="12" cy="12" r="1.25" fill="#fff" />
        <circle cx="16.2" cy="12" r="1.25" fill="#fff" />
      </IconBase>
    );
  }
  return (
    <IconBase size={size} strokeWidth={1.6}>
      <circle cx="12" cy="12" r="9" />
      <circle cx="7.8" cy="12" r="1.15" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.15" fill="currentColor" stroke="none" />
      <circle cx="16.2" cy="12" r="1.15" fill="currentColor" stroke="none" />
    </IconBase>
  );
}

/** SF Symbol magnifyingglass */
export function IconSearch({ size = 17 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.1}>
      <circle cx="10.8" cy="10.8" r="6.2" />
      <path d="m19.2 19.2-3.5-3.5" />
    </IconBase>
  );
}

/** SF Symbol person.crop.circle */
export function IconUser({ size = 20 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.7}>
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="9.2" r="3.1" />
      <path d="M6.4 18.2c1.1-2.6 10.1-2.6 11.2 0" />
    </IconBase>
  );
}

export function IconChevronRight({ size = 12 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.6}>
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

/** SF Symbol tv / tv.fill */
export function IconTv({ size = 18, filled }: IconProps & { filled?: boolean }) {
  if (filled) {
    return (
      <IconBase size={size} fill="currentColor" strokeWidth={0}>
        <path d="M3.5 5.2h17a1.8 1.8 0 0 1 1.8 1.8v9.2a1.8 1.8 0 0 1-1.8 1.8h-17A1.8 1.8 0 0 1 1.7 16.2V7a1.8 1.8 0 0 1 1.8-1.8ZM8.2 20.2h7.6a.75.75 0 0 1 0 1.5H8.2a.75.75 0 0 1 0-1.5Z" />
      </IconBase>
    );
  }
  return (
    <IconBase size={size} strokeWidth={1.8}>
      <rect x="2.8" y="5" width="18.4" height="12.2" rx="2" />
      <path d="M8.2 20.3h7.6M12 17.2v3.1" />
    </IconBase>
  );
}

/** SF Symbol slider.horizontal.3 */
export function IconSliders({ size = 15 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={2.1}>
      <path d="M4 7h7.5M15.5 7H20" />
      <path d="M4 17h2.5M10.5 17H20" />
      <circle cx="13.5" cy="7" r="2.1" />
      <circle cx="8.2" cy="17" r="2.1" />
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

/** SF Symbol plus.magnifyingglass */
export function IconPlusSearch({ size = 18 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.9}>
      <circle cx="11" cy="11" r="6.2" />
      <path d="m19.2 19.2-3.4-3.4" />
      <path d="M11 8.2v5.6M8.2 11h5.6" />
    </IconBase>
  );
}

/** SF Symbol square.stack.3d.up.fill */
export function IconStack({ size = 15 }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 3.2 3.8 7.2 12 11.2l8.2-4L12 3.2ZM4.2 9.6v2.3L12 15.9l7.8-4V9.6L12 13.6 4.2 9.6Zm0 4.2v2.3L12 20.3l7.8-4.2v-2.3L12 17.8 4.2 13.8Z" />
    </svg>
  );
}

/** SF Symbol flag.checkered */
export function IconFlagCheckered({ size = 18 }: IconProps) {
  return (
    <IconBase size={size} strokeWidth={1.7}>
      <path d="M5 3.5v17" />
      <path d="M5 4.2h12.5l-1.8 2.6 1.8 2.6H5" />
      <path d="M8 4.2v5.2M11.2 4.2v5.2M8 6.8h6.5" />
    </IconBase>
  );
}

/** SF Symbol bell.fill / bell.slash.fill */
export function IconBell({ size = 17, muted }: IconProps & { muted?: boolean }) {
  if (muted) {
    return (
      <IconBase size={size} strokeWidth={1.7}>
        <path d="M6.2 9.2a5.8 5.8 0 0 1 11.6 0c0 3.2 1.2 4.4 1.2 4.4H5s1.2-1.2 1.2-4.4Z" />
        <path d="M10 18.2a2 2 0 0 0 4 0" />
        <path d="M5 5l14 14" />
      </IconBase>
    );
  }
  return (
    <IconBase size={size} fill="currentColor" strokeWidth={0}>
      <path d="M12 2.6a5.9 5.9 0 0 0-5.9 5.9c0 3.4-1.4 4.8-1.4 4.8h14.6s-1.4-1.4-1.4-4.8A5.9 5.9 0 0 0 12 2.6Zm-2.1 15.2a2.1 2.1 0 0 0 4.2 0H9.9Z" />
    </IconBase>
  );
}

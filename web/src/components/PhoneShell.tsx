"use client";

import type { ReactNode } from "react";

export function PhoneShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh w-full bg-[#0b0c10] text-[var(--text-primary)]">
      <div className="mx-auto flex min-h-dvh w-full max-w-[480px] items-stretch justify-center md:max-w-none md:items-center md:px-6 md:py-8">
        <div
          className="relative flex h-dvh w-full flex-col overflow-hidden bg-[var(--canvas)] md:h-[var(--phone-h)] md:w-[var(--phone-w)] md:rounded-[44px] md:border md:border-white/12 md:shadow-[0_30px_80px_rgba(0,0,0,0.55)]"
          data-phone-shell
        >
          <div className="pointer-events-none absolute inset-x-0 top-0 z-30 hidden h-[var(--safe-top)] md:block">
            <div className="mx-auto mt-3 h-[28px] w-[120px] rounded-full bg-black/85" />
            <div className="absolute inset-x-0 top-0 flex h-11 items-end justify-between px-7 pb-1 text-[12px] font-semibold text-[var(--text-primary)]">
              <span>9:41</span>
              <span className="flex gap-1.5 text-[11px] opacity-80">
                <span>●●●</span>
                <span>Wi‑Fi</span>
                <span>100%</span>
              </span>
            </div>
          </div>
          <div className="relative flex min-h-0 flex-1 flex-col bg-[var(--canvas)] pt-[env(safe-area-inset-top)] md:pt-[var(--safe-top)]">
            {children}
          </div>
          <div className="pointer-events-none absolute inset-x-0 bottom-2 z-30 hidden justify-center md:flex">
            <div className="h-1.5 w-28 rounded-full bg-black/35" />
          </div>
        </div>
      </div>
    </div>
  );
}

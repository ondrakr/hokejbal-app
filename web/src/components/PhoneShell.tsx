"use client";

import type { ReactNode, RefObject } from "react";
import { useEffect, useRef } from "react";

function isInteractive(el: Element | null) {
  if (!el) return false;
  const tag = el.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || tag === "OPTION") return true;
  if ((el as HTMLElement).isContentEditable) return true;
  return false;
}

function canScroll(el: HTMLElement, axis: "x" | "y") {
  const style = getComputedStyle(el);
  if (axis === "y") {
    const oy = style.overflowY;
    return (oy === "auto" || oy === "scroll" || oy === "overlay") && el.scrollHeight > el.clientHeight + 1;
  }
  const ox = style.overflowX;
  return (ox === "auto" || ox === "scroll" || ox === "overlay") && el.scrollWidth > el.clientWidth + 1;
}

function findScrollers(start: Element | null, root: HTMLElement) {
  const vertical: HTMLElement[] = [];
  const horizontal: HTMLElement[] = [];
  let el: HTMLElement | null = start instanceof HTMLElement ? start : start?.parentElement ?? null;
  while (el && root.contains(el)) {
    if (canScroll(el, "y")) vertical.push(el);
    if (canScroll(el, "x")) horizontal.push(el);
    if (el === root) break;
    el = el.parentElement;
  }
  return { vertical, horizontal };
}

/** Myš táhne scroll jako prst (grab/drag), bez systémových scrollbarů. */
function useFingerMouseScroll(rootRef: RefObject<HTMLElement | null>) {
  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    let active = false;
    let dragging = false;
    let pointerId = -1;
    let startX = 0;
    let startY = 0;
    let scrollersY: HTMLElement[] = [];
    let scrollersX: HTMLElement[] = [];
    let startScrollTop: number[] = [];
    let startScrollLeft: number[] = [];
    let axis: "x" | "y" | null = null;

    const onPointerDown = (e: PointerEvent) => {
      if (e.pointerType !== "mouse" || e.button !== 0) return;
      if (isInteractive(e.target as Element)) return;

      const { vertical, horizontal } = findScrollers(e.target as Element, root);
      if (!vertical.length && !horizontal.length) return;

      active = true;
      dragging = false;
      axis = null;
      pointerId = e.pointerId;
      startX = e.clientX;
      startY = e.clientY;
      scrollersY = vertical;
      scrollersX = horizontal;
      startScrollTop = vertical.map((el) => el.scrollTop);
      startScrollLeft = horizontal.map((el) => el.scrollLeft);
    };

    const onPointerMove = (e: PointerEvent) => {
      if (!active || e.pointerId !== pointerId) return;

      const dx = e.clientX - startX;
      const dy = e.clientY - startY;

      if (!dragging) {
        if (Math.abs(dx) < 6 && Math.abs(dy) < 6) return;
        if (Math.abs(dy) >= Math.abs(dx) && scrollersY.length) axis = "y";
        else if (scrollersX.length) axis = "x";
        else if (scrollersY.length) axis = "y";
        else return;

        dragging = true;
        root.setAttribute("data-dragging", "true");
        try {
          root.setPointerCapture(pointerId);
        } catch {
          /* ignore */
        }
      }

      e.preventDefault();
      if (axis === "y") {
        scrollersY.forEach((el, i) => {
          el.scrollTop = startScrollTop[i]! - (e.clientY - startY);
        });
      } else if (axis === "x") {
        scrollersX.forEach((el, i) => {
          el.scrollLeft = startScrollLeft[i]! - (e.clientX - startX);
        });
      }
    };

    const endDrag = (e: PointerEvent) => {
      if (!active || e.pointerId !== pointerId) return;
      const wasDragging = dragging;
      active = false;
      dragging = false;
      axis = null;
      root.removeAttribute("data-dragging");
      try {
        if (root.hasPointerCapture(pointerId)) root.releasePointerCapture(pointerId);
      } catch {
        /* ignore */
      }

      // Potlač click po drag (ať se neotevře zápas omylem).
      if (wasDragging) {
        const suppress = (ev: Event) => {
          ev.preventDefault();
          ev.stopPropagation();
          root.removeEventListener("click", suppress, true);
        };
        root.addEventListener("click", suppress, true);
        window.setTimeout(() => root.removeEventListener("click", suppress, true), 0);
      }
    };

    root.addEventListener("pointerdown", onPointerDown, { passive: true });
    root.addEventListener("pointermove", onPointerMove, { passive: false });
    root.addEventListener("pointerup", endDrag);
    root.addEventListener("pointercancel", endDrag);

    return () => {
      root.removeEventListener("pointerdown", onPointerDown);
      root.removeEventListener("pointermove", onPointerMove);
      root.removeEventListener("pointerup", endDrag);
      root.removeEventListener("pointercancel", endDrag);
    };
  }, [rootRef]);
}

export function PhoneShell({ children }: { children: ReactNode }) {
  const shellRef = useRef<HTMLDivElement>(null);
  useFingerMouseScroll(shellRef);

  return (
    <div className="min-h-dvh w-full bg-[#0b0c10] text-hb-fg">
      <div className="mx-auto flex min-h-dvh w-full max-w-[480px] items-stretch justify-center md:max-w-none md:items-center md:px-6 md:py-8">
        <div
          ref={shellRef}
          className="relative flex h-dvh w-full flex-col overflow-hidden bg-canvas md:h-[var(--phone-h)] md:w-[var(--phone-w)] md:rounded-[44px] md:border md:border-white/12 md:shadow-[0_30px_80px_rgba(0,0,0,0.55)]"
          data-phone-shell
        >
          <div className="pointer-events-none absolute inset-x-0 top-0 z-30 hidden h-[var(--safe-top)] md:block">
            <div className="mx-auto mt-3 h-[28px] w-[120px] rounded-full bg-black/85" />
            <div className="absolute inset-x-0 top-0 flex h-11 items-end justify-between px-7 pb-1 text-[12px] font-semibold text-hb-fg">
              <span>9:41</span>
              <span className="flex gap-1.5 text-[11px] opacity-80">
                <span>●●●</span>
                <span>Wi‑Fi</span>
                <span>100%</span>
              </span>
            </div>
          </div>
          <div className="relative flex min-h-0 flex-1 flex-col bg-canvas pt-[env(safe-area-inset-top)] md:pt-[var(--safe-top)]">
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

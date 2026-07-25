"use client";

import {
  Children,
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  type ReactNode,
} from "react";

/**
 * Horizontální swipe mezi taby (scroll-snap) — parity s iOS page TabView v detailu zápasu.
 * `children` musí být ve stejném pořadí jako `tabs`.
 */
export function SwipeTabPanels({
  tabs,
  value,
  onChange,
  children,
  className = "",
  panelClassName = "hb-scroll",
}: {
  tabs: string[];
  value: string;
  onChange: (v: string) => void;
  children: ReactNode;
  className?: string;
  /** Třídy pro jednotlivý panel (typicky hb-scroll + padding). */
  panelClassName?: string;
}) {
  const scrollerRef = useRef<HTMLDivElement>(null);
  const ignoreScroll = useRef(false);
  const panels = Children.toArray(children);
  const index = Math.max(0, tabs.indexOf(value));

  const scrollToIndex = useCallback((i: number, behavior: ScrollBehavior) => {
    const el = scrollerRef.current;
    if (!el) return;
    const width = el.clientWidth;
    if (width <= 0) return;
    ignoreScroll.current = true;
    el.scrollTo({ left: i * width, behavior });
    window.setTimeout(
      () => {
        ignoreScroll.current = false;
      },
      behavior === "smooth" ? 360 : 60
    );
  }, []);

  useLayoutEffect(() => {
    scrollToIndex(index, "auto");
    // eslint-disable-next-line react-hooks/exhaustive-deps -- jen při změně sady tabů
  }, [tabs.join("|")]);

  useEffect(() => {
    scrollToIndex(index, "smooth");
  }, [index, scrollToIndex]);

  useEffect(() => {
    const el = scrollerRef.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(() => scrollToIndex(index, "auto"));
    ro.observe(el);
    return () => ro.disconnect();
  }, [index, scrollToIndex]);

  const onScroll = () => {
    if (ignoreScroll.current) return;
    const el = scrollerRef.current;
    if (!el || el.clientWidth <= 0) return;
    const i = Math.round(el.scrollLeft / el.clientWidth);
    const next = tabs[i];
    if (next && next !== value) onChange(next);
  };

  return (
    <div
      ref={scrollerRef}
      onScroll={onScroll}
      className={`hb-swipe-tabs min-h-0 flex-1 ${className}`}
      data-swipe-tabs=""
    >
      {panels.map((child, i) => (
        <div
          key={tabs[i] ?? `panel-${i}`}
          className={`hb-swipe-panel min-h-0 ${panelClassName}`}
        >
          {child}
        </div>
      ))}
    </div>
  );
}

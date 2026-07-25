"use client";

import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { SiteSwitchSheet } from "@/components/SiteSwitchSheet";
import { brandHomeURL } from "@/stores/appBrand";

/** Port CMSHBBrowserShell — chrome + iframe živého webu CMSHb.CZ. */
export function CMSHBBrowserShell() {
  const [showSiteSwitch, setShowSiteSwitch] = useState(false);
  const [loading, setLoading] = useState(true);
  const [progress, setProgress] = useState(0.08);
  const [canGoBack, setCanGoBack] = useState(false);
  const [canGoForward, setCanGoForward] = useState(false);
  const historyRef = useRef<string[]>([brandHomeURL("cmshb")]);
  const indexRef = useRef(0);
  const [src, setSrc] = useState(brandHomeURL("cmshb"));
  const progressTimer = useRef<ReturnType<typeof setInterval> | null>(null);

  const syncNav = useCallback(() => {
    setCanGoBack(indexRef.current > 0);
    setCanGoForward(indexRef.current < historyRef.current.length - 1);
  }, []);

  const startProgress = useCallback(() => {
    setLoading(true);
    setProgress(0.08);
    if (progressTimer.current) clearInterval(progressTimer.current);
    progressTimer.current = setInterval(() => {
      setProgress((p) => (p >= 0.9 ? p : p + (0.9 - p) * 0.12));
    }, 120);
  }, []);

  const endProgress = useCallback(() => {
    if (progressTimer.current) {
      clearInterval(progressTimer.current);
      progressTimer.current = null;
    }
    setProgress(1);
    window.setTimeout(() => {
      setLoading(false);
      setProgress(0);
    }, 180);
  }, []);

  useEffect(
    () => () => {
      if (progressTimer.current) clearInterval(progressTimer.current);
    },
    []
  );

  const goBack = () => {
    if (indexRef.current <= 0) return;
    indexRef.current -= 1;
    syncNav();
    startProgress();
    setSrc(historyRef.current[indexRef.current]);
  };

  const goForward = () => {
    if (indexRef.current >= historyRef.current.length - 1) return;
    indexRef.current += 1;
    syncNav();
    startProgress();
    setSrc(historyRef.current[indexRef.current]);
  };

  const reload = () => {
    startProgress();
    const current = historyRef.current[indexRef.current];
    setSrc("about:blank");
    window.setTimeout(() => setSrc(current), 16);
  };

  return (
    <div className="relative flex min-h-0 flex-1 flex-col bg-canvas">
      <div className="shrink-0 bg-surface">
        <div className="flex items-center gap-3 px-4 py-2.5">
          <button
            type="button"
            onClick={() => setShowSiteSwitch(true)}
            className="flex min-w-0 items-center gap-2 text-left"
            aria-label="Přepnout web"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/brand/BrandLogo.png"
              alt=""
              className="h-7 w-auto object-contain"
            />
            <span className="min-w-0">
              <span className="block text-[14px] font-bold leading-tight text-hb-fg">
                CMSHb.CZ
              </span>
              <span className="block text-[11px] font-medium leading-tight text-hb-muted">
                Přepnout web
              </span>
            </span>
          </button>

          <div className="ml-auto flex items-center gap-1">
            <ChromeButton
              label="Zpět"
              enabled={canGoBack}
              onClick={goBack}
              icon={
                <path
                  d="M15 5.5 9 12l6 6.5"
                  stroke="currentColor"
                  strokeWidth="2.2"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              }
            />
            <ChromeButton
              label="Vpřed"
              enabled={canGoForward}
              onClick={goForward}
              icon={
                <path
                  d="m9 5.5 6 6.5-6 6.5"
                  stroke="currentColor"
                  strokeWidth="2.2"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              }
            />
            <ChromeButton
              label="Obnovit"
              enabled
              onClick={reload}
              icon={
                <path
                  d="M4.5 12a7.5 7.5 0 0 1 12.8-5.3M19.5 12a7.5 7.5 0 0 1-12.8 5.3M17.2 4.2v3.6h-3.6M6.8 19.8v-3.6h3.6"
                  stroke="currentColor"
                  strokeWidth="1.9"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              }
            />
          </div>
        </div>
        <div className="h-px bg-[var(--separator)]" />
        <div
          className="overflow-hidden transition-[height] duration-200"
          style={{ height: loading ? 2 : 0 }}
        >
          <div
            className="h-full bg-brand transition-[width] duration-150 ease-out"
            style={{ width: `${Math.round(progress * 100)}%` }}
          />
        </div>
      </div>

      <iframe
        title="CMSHb.CZ"
        src={src}
        className="min-h-0 w-full flex-1 border-0 bg-white"
        sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-popups-to-escape-sandbox allow-top-navigation-by-user-activation"
        referrerPolicy="no-referrer-when-downgrade"
        onLoad={endProgress}
      />

      <SiteSwitchSheet open={showSiteSwitch} onClose={() => setShowSiteSwitch(false)} />
    </div>
  );
}

function ChromeButton({
  label,
  enabled,
  onClick,
  icon,
}: {
  label: string;
  enabled: boolean;
  onClick: () => void;
  icon: ReactNode;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      disabled={!enabled}
      onClick={onClick}
      className={`flex h-9 w-9 items-center justify-center ${
        enabled ? "text-hb-fg" : "text-hb-faint"
      }`}
    >
      <svg width="15" height="15" viewBox="0 0 24 24" aria-hidden>
        {icon}
      </svg>
    </button>
  );
}

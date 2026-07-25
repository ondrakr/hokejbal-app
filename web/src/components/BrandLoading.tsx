"use client";

import { useEffect, useState } from "react";

/** Port BrandLoadingView — splash / loading s logem ČMSHb. */
export function BrandLoading({
  message,
  logoSize = 132,
}: {
  message?: string;
  logoSize?: number;
}) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const id = requestAnimationFrame(() => setVisible(true));
    return () => cancelAnimationFrame(id);
  }, []);

  return (
    <div
      className="flex h-full min-h-0 w-full flex-1 flex-col items-center justify-center bg-canvas"
      role="status"
      aria-label={message ? `Hokejbal, ${message}` : "Hokejbal, načítám"}
    >
      <div className="flex flex-col items-center gap-[18px]">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/brand/cmshb-logo.svg"
          alt="Hokejbal"
          width={logoSize}
          height={logoSize}
          className="object-contain transition-all duration-[400ms] ease-out"
          style={{
            opacity: visible ? 1 : 0,
            transform: visible ? "scale(1)" : "scale(0.94)",
          }}
        />
        {message ? (
          <>
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-brand border-t-transparent" />
            <p className="text-[14px] font-medium text-hb-muted">{message}</p>
          </>
        ) : null}
      </div>
    </div>
  );
}

"use client";

import {
  APP_BRANDS,
  brandDisplayName,
  useAppBrand,
  type AppBrand,
} from "@/stores/appBrand";

type Props = {
  open: boolean;
  onClose: () => void;
};

/** Port SiteSwitchSheet — detent ~260, volba hokejbal.cz / CMSHb.CZ. */
export function SiteSwitchSheet({ open, onClose }: Props) {
  const { brand, select, closeSiteSwitch } = useAppBrand();

  if (!open) return null;

  function choose(option: AppBrand) {
    select(option);
    onClose();
    closeSiteSwitch();
  }

  return (
    <div className="absolute inset-0 z-[70] flex flex-col justify-end" role="dialog" aria-modal aria-label="Web">
      <button
        type="button"
        className="absolute inset-0 bg-black/35"
        aria-label="Zavřít"
        onClick={onClose}
      />
      <div
        className="hb-site-sheet relative flex h-[260px] flex-col rounded-t-[16px] bg-canvas"
        style={{ paddingBottom: "max(8px, env(safe-area-inset-bottom, 0px))" }}
      >
        <div className="mx-auto mt-2 h-1 w-9 shrink-0 rounded-full bg-[color-mix(in_srgb,var(--hb-fg)_22%,transparent)]" />
        <div className="flex h-11 shrink-0 items-center justify-between px-4">
          <button
            type="button"
            onClick={onClose}
            className="text-[16px] font-medium text-brand"
          >
            Zavřít
          </button>
          <span className="absolute left-1/2 -translate-x-1/2 text-[16px] font-bold text-hb-fg">
            Web
          </span>
          <span className="w-14" aria-hidden />
        </div>
        <div className="flex flex-1 flex-col gap-3 px-4 pt-2">
          {APP_BRANDS.map((option) => {
            const selected = brand === option;
            return (
              <button
                key={option}
                type="button"
                onClick={() => choose(option)}
                className={`flex items-center gap-3 rounded-[14px] px-4 py-3.5 text-left ${
                  selected
                    ? "bg-brand text-white"
                    : "border border-card-stroke bg-card text-hb-fg"
                }`}
              >
                <span className="min-w-0 flex-1 text-[16px] font-bold">
                  {brandDisplayName(option)}
                </span>
                {selected ? (
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden>
                    <path
                      d="M5 12.5 10 17.5 19 7"
                      stroke="currentColor"
                      strokeWidth="2.6"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                ) : null}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

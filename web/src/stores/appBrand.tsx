"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { readString, writeString } from "@/lib/storage";

export type AppBrand = "hokejbal" | "cmshb";

const STORAGE_KEY = "hb.appBrand";

export const APP_BRANDS: AppBrand[] = ["hokejbal", "cmshb"];

export function brandDisplayName(brand: AppBrand): string {
  return brand === "hokejbal" ? "hokejbal.cz" : "CMSHb.CZ";
}

export function brandHomeURL(brand: AppBrand): string {
  return brand === "hokejbal" ? "https://www.hokejbal.cz/" : "https://www.cmshb.cz/";
}

function readStoredBrand(): AppBrand {
  const raw = readString(STORAGE_KEY, "hokejbal");
  return raw === "cmshb" ? "cmshb" : "hokejbal";
}

type AppBrandContextValue = {
  brand: AppBrand;
  select: (brand: AppBrand) => void;
  siteSwitchOpen: boolean;
  openSiteSwitch: () => void;
  closeSiteSwitch: () => void;
};

const AppBrandContext = createContext<AppBrandContextValue | null>(null);

export function AppBrandProvider({ children }: { children: ReactNode }) {
  const [brand, setBrand] = useState<AppBrand>(() =>
    typeof window === "undefined" ? "hokejbal" : readStoredBrand()
  );
  const [siteSwitchOpen, setSiteSwitchOpen] = useState(false);

  const select = useCallback((next: AppBrand) => {
    setBrand(next);
    writeString(STORAGE_KEY, next);
  }, []);

  const openSiteSwitch = useCallback(() => setSiteSwitchOpen(true), []);
  const closeSiteSwitch = useCallback(() => setSiteSwitchOpen(false), []);

  const value = useMemo(
    () => ({ brand, select, siteSwitchOpen, openSiteSwitch, closeSiteSwitch }),
    [brand, select, siteSwitchOpen, openSiteSwitch, closeSiteSwitch]
  );

  return <AppBrandContext.Provider value={value}>{children}</AppBrandContext.Provider>;
}

export function useAppBrand() {
  const ctx = useContext(AppBrandContext);
  if (!ctx) throw new Error("useAppBrand must be used within AppBrandProvider");
  return ctx;
}

export function isCMSHBHost(url: string): boolean {
  try {
    const host = new URL(url).hostname.toLowerCase();
    return host === "cmshb.cz" || host.endsWith(".cmshb.cz");
  } catch {
    return false;
  }
}

export function isHokejbalHost(url: string): boolean {
  try {
    const host = new URL(url).hostname.toLowerCase();
    return host === "hokejbal.cz" || host.endsWith(".hokejbal.cz");
  } catch {
    return false;
  }
}

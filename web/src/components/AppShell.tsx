"use client";

import { useEffect, useState } from "react";
import { BrandLoading } from "@/components/BrandLoading";
import { CMSHBBrowserShell } from "@/components/CMSHBBrowserShell";
import { InAppBannerOverlay } from "@/components/InAppBannerOverlay";
import { PhoneShell } from "@/components/PhoneShell";
import { TabBar } from "@/components/ui";
import { AmateurScreen } from "@/screens/AmateurScreen";
import { CompetitionDetailScreen } from "@/screens/CompetitionDetailScreen";
import { CompetitionStatsLeaderboardScreen } from "@/screens/CompetitionStatsScreen";
import { FavoritesScreen } from "@/screens/FavoritesScreen";
import { FantasyScreen } from "@/screens/FantasyScreen";
import { HomeScreen } from "@/screens/HomeScreen";
import { LiveScreen } from "@/screens/LiveScreen";
import { MatchDetailScreen } from "@/screens/MatchDetailScreen";
import { MatchesScreen } from "@/screens/MatchesScreen";
import { MoreScreen } from "@/screens/MoreScreen";
import {
  ArticleScreen,
  MediaScreen,
  NewsScreen,
  SearchScreen,
} from "@/screens/MoreScreens";
import {
  CompetitionOrderSettingsScreen,
  HomeFeedSettingsScreen,
  NotificationSettingsScreen,
  SettingsScreen,
} from "@/screens/SettingsScreens";
import { PlayerDetailScreen } from "@/screens/PlayerDetailScreen";
import { TeamDetailScreen } from "@/screens/TeamDetailScreen";
import { TipsScreen } from "@/screens/TipsScreen";
import { SiteSwitchSheet } from "@/components/SiteSwitchSheet";
import { AppBrandProvider, useAppBrand } from "@/stores/appBrand";
import { CatalogProvider, useCatalog } from "@/stores/catalog";
import { NavigationProvider, useNav } from "@/stores/navigation";

function applyInitialTheme() {
  const saved = localStorage.getItem("hb.appearance") as "system" | "light" | "dark" | null;
  const root = document.documentElement;
  const mode = saved ?? "light";
  if (mode === "dark") {
    root.setAttribute("data-theme", "dark");
  } else if (mode === "system") {
    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      root.setAttribute("data-theme", "dark");
    } else {
      root.setAttribute("data-theme", "light");
    }
  } else {
    root.setAttribute("data-theme", "light");
  }
}

function StackRouter() {
  const { tab, stack } = useNav();
  const top = stack[stack.length - 1];

  if (top) {
    switch (top.name) {
      case "match":
        return <MatchDetailScreen id={top.id} />;
      case "team":
        return <TeamDetailScreen id={top.id} />;
      case "player":
        return <PlayerDetailScreen id={top.id} />;
      case "competition":
        return <CompetitionDetailScreen id={top.id} day={top.day} />;
      case "competitionStats":
        return (
          <CompetitionStatsLeaderboardScreen
            competitionId={top.competitionId}
            scope={top.scope}
            metric={top.metric}
            teamId={top.teamId}
          />
        );
      case "news":
        return <NewsScreen />;
      case "article":
        return <ArticleScreen id={top.id} />;
      case "search":
        return <SearchScreen />;
      case "settings":
        return <SettingsScreen />;
      case "settingsHomeFeed":
        return <HomeFeedSettingsScreen />;
      case "settingsOrder":
        return <CompetitionOrderSettingsScreen />;
      case "settingsNotifications":
        return <NotificationSettingsScreen />;
      case "media":
        return <MediaScreen />;
      case "fantasy":
        return <FantasyScreen screen={top.screen} />;
      case "tips":
        return <TipsScreen screen={top.screen} />;
      case "amateur":
        return (
          <AmateurScreen
            screen={top.screen}
            id={top.id}
            teamId={top.teamId}
            matchId={top.matchId}
          />
        );
    }
  }

  switch (tab) {
    case "home":
      return <HomeScreen />;
    case "matches":
      return <MatchesScreen />;
    case "live":
      return <LiveScreen />;
    case "favorites":
      return <FavoritesScreen />;
    case "more":
      return <MoreScreen />;
  }
}

function HokejbalApp() {
  const { siteSwitchOpen, closeSiteSwitch } = useAppBrand();
  return (
    <div className="relative flex min-h-0 flex-1 flex-col">
      <InAppBannerOverlay />
      <StackRouter />
      <TabBar />
      <SiteSwitchSheet open={siteSwitchOpen} onClose={closeSiteSwitch} />
    </div>
  );
}

function AppInner() {
  const { loading } = useCatalog();
  const { brand } = useAppBrand();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    applyInitialTheme();
  }, []);

  useEffect(() => {
    if (ready || loading) return;
    // Krátké minimum, ať splash neblikne (jako iOS AppRootView).
    const id = window.setTimeout(() => setReady(true), 450);
    return () => window.clearTimeout(id);
  }, [loading, ready]);

  if (!ready) {
    return (
      <PhoneShell>
        <BrandLoading />
      </PhoneShell>
    );
  }

  return (
    <PhoneShell>
      <div
        key={brand}
        className="relative flex min-h-0 flex-1 flex-col hb-brand-fade"
      >
        {brand === "cmshb" ? <CMSHBBrowserShell /> : <HokejbalApp />}
      </div>
    </PhoneShell>
  );
}

export function AppShell() {
  return (
    <CatalogProvider>
      <NavigationProvider>
        <AppBrandProvider>
          <AppInner />
        </AppBrandProvider>
      </NavigationProvider>
    </CatalogProvider>
  );
}

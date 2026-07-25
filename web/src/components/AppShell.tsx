"use client";

import { useEffect } from "react";
import { PhoneShell } from "@/components/PhoneShell";
import { TabBar } from "@/components/ui";
import { AmateurScreen } from "@/screens/AmateurScreen";
import { CompetitionDetailScreen } from "@/screens/CompetitionDetailScreen";
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
  SettingsScreen,
} from "@/screens/MoreScreens";
import { PlayerDetailScreen } from "@/screens/PlayerDetailScreen";
import { TeamDetailScreen } from "@/screens/TeamDetailScreen";
import { TipsScreen } from "@/screens/TipsScreen";
import { CatalogProvider } from "@/stores/catalog";
import { NavigationProvider, useNav } from "@/stores/navigation";

function applyInitialTheme() {
  const saved = localStorage.getItem("hb.appearance") as "system" | "light" | "dark" | null;
  const root = document.documentElement;
  const preferDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  if (saved === "dark" || ((!saved || saved === "system") && preferDark)) {
    root.setAttribute("data-theme", "dark");
  } else if (saved === "light") {
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
      case "news":
        return <NewsScreen />;
      case "article":
        return <ArticleScreen id={top.id} />;
      case "search":
        return <SearchScreen />;
      case "settings":
        return <SettingsScreen />;
      case "media":
        return <MediaScreen />;
      case "fantasy":
        return <FantasyScreen screen={top.screen} />;
      case "tips":
        return <TipsScreen screen={top.screen} />;
      case "amateur":
        return <AmateurScreen screen={top.screen} id={top.id} matchId={top.matchId} />;
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

function AppInner() {
  useEffect(() => {
    applyInitialTheme();
  }, []);

  return (
    <PhoneShell>
      <div className="flex min-h-0 flex-1 flex-col">
        <StackRouter />
        <TabBar />
      </div>
    </PhoneShell>
  );
}

export function AppShell() {
  return (
    <CatalogProvider>
      <NavigationProvider>
        <AppInner />
      </NavigationProvider>
    </CatalogProvider>
  );
}

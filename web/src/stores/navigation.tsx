"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

export type TabId = "home" | "matches" | "live" | "favorites" | "more";

export type LiveFilter = "all" | "broadcasts";

export type Route =
  | { name: "match"; id: string }
  | { name: "team"; id: string }
  | { name: "player"; id: string }
  | { name: "competition"; id: string; day?: string }
  | {
      name: "competitionStats";
      competitionId: string;
      scope: "players" | "teams";
      metric: string;
    }
  | { name: "news" }
  | { name: "article"; id: string }
  | { name: "search" }
  | { name: "settings" }
  | { name: "settingsHomeFeed" }
  | { name: "settingsOrder" }
  | { name: "settingsNotifications" }
  | { name: "media" }
  | { name: "fantasy"; screen?: "hub" | "team" | "market" | "leaderboard" | "rules" }
  | { name: "tips"; screen?: "hub" | "leaderboard" | "rules" }
  | {
      name: "amateur";
      screen?:
        | "hub"
        | "adminHub"
        | "create"
        | "detail"
        | "admin"
        | "adminTeam"
        | "team"
        | "match"
        | "scorer";
      id?: string;
      teamId?: string;
      matchId?: string;
    };

type NavState = {
  tab: TabId;
  liveFilter: LiveFilter;
  stack: Route[];
  setTab: (tab: TabId) => void;
  selectLive: (filter?: LiveFilter) => void;
  push: (route: Route) => void;
  pop: () => void;
  resetStack: () => void;
  replace: (route: Route) => void;
};

const NavContext = createContext<NavState | null>(null);

export function NavigationProvider({ children }: { children: ReactNode }) {
  const [tab, setTabState] = useState<TabId>("home");
  const [liveFilter, setLiveFilter] = useState<LiveFilter>("all");
  const [stack, setStack] = useState<Route[]>([]);

  const setTab = useCallback((t: TabId) => {
    setTabState(t);
    setStack([]);
  }, []);

  const selectLive = useCallback((filter: LiveFilter = "all") => {
    setLiveFilter(filter);
    setTabState("live");
    setStack([]);
  }, []);

  const push = useCallback((route: Route) => {
    setStack((s) => [...s, route]);
  }, []);

  const pop = useCallback(() => {
    setStack((s) => s.slice(0, -1));
  }, []);

  const resetStack = useCallback(() => setStack([]), []);

  const replace = useCallback((route: Route) => {
    setStack((s) => [...s.slice(0, -1), route]);
  }, []);

  const value = useMemo(
    () => ({
      tab,
      liveFilter,
      stack,
      setTab,
      selectLive,
      push,
      pop,
      resetStack,
      replace,
    }),
    [tab, liveFilter, stack, setTab, selectLive, push, pop, resetStack, replace]
  );

  return <NavContext.Provider value={value}>{children}</NavContext.Provider>;
}

export function useNav() {
  const ctx = useContext(NavContext);
  if (!ctx) throw new Error("useNav outside provider");
  return ctx;
}

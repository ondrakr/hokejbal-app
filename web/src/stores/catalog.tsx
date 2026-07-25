"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  fetchCompetitions,
  fetchMatches,
  fetchNews,
  fetchSeasons,
  fetchTeams,
} from "@/lib/api";
import type { Competition, Match, NewsArticle, Season, Team } from "@/lib/types";
import { readString, writeString } from "@/lib/storage";

type CatalogState = {
  seasons: Season[];
  competitions: Competition[];
  teams: Team[];
  matches: Match[];
  news: NewsArticle[];
  selectedSeasonId: string | null;
  loading: boolean;
  error: string | null;
  teamById: (id: string) => Team | undefined;
  competitionById: (id: string) => Competition | undefined;
  setSelectedSeasonId: (id: string) => void;
  refresh: () => Promise<void>;
  refreshMatches: () => Promise<void>;
};

const CatalogContext = createContext<CatalogState | null>(null);

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [seasons, setSeasons] = useState<Season[]>([]);
  const [competitions, setCompetitions] = useState<Competition[]>([]);
  const [teams, setTeams] = useState<Team[]>([]);
  const [matches, setMatches] = useState<Match[]>([]);
  const [news, setNews] = useState<NewsArticle[]>([]);
  const [selectedSeasonId, setSelectedSeasonIdState] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async (seasonId?: string | null) => {
    setLoading(true);
    setError(null);
    try {
      const seasonsData = await fetchSeasons();
      const saved = readString("hb.selectedSeason", "");
      const current =
        seasonId ??
        (saved ||
          seasonsData.find((s) => s.isCurrent)?.id ||
          seasonsData[0]?.id ||
          null);
      const [comps, newsData] = await Promise.all([
        fetchCompetitions(current ?? undefined),
        fetchNews(20),
      ]);
      const teamsData = await fetchTeams();
      const matchesData = await fetchMatches({ seasonId: current ?? undefined });
      setSeasons(seasonsData);
      setCompetitions(comps);
      setTeams(teamsData);
      setMatches(matchesData);
      setNews(newsData);
      setSelectedSeasonIdState(current);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Nepodařilo se načíst data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const setSelectedSeasonId = useCallback(
    (id: string) => {
      writeString("hb.selectedSeason", id);
      setSelectedSeasonIdState(id);
      void load(id);
    },
    [load]
  );

  const refreshMatches = useCallback(async () => {
    const data = await fetchMatches({ seasonId: selectedSeasonId ?? undefined });
    setMatches(data);
  }, [selectedSeasonId]);

  const teamMap = useMemo(() => new Map(teams.map((t) => [t.id, t])), [teams]);
  const compMap = useMemo(
    () => new Map(competitions.map((c) => [c.id, c])),
    [competitions]
  );

  const value: CatalogState = {
    seasons,
    competitions,
    teams,
    matches,
    news,
    selectedSeasonId,
    loading,
    error,
    teamById: (id) => teamMap.get(id),
    competitionById: (id) => compMap.get(id),
    setSelectedSeasonId,
    refresh: () => load(selectedSeasonId),
    refreshMatches,
  };

  return <CatalogContext.Provider value={value}>{children}</CatalogContext.Provider>;
}

export function useCatalog() {
  const ctx = useContext(CatalogContext);
  if (!ctx) throw new Error("useCatalog outside provider");
  return ctx;
}

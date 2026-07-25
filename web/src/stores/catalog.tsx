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
  fetchPlayers,
  fetchSeasons,
  fetchTeamsForSeason,
} from "@/lib/api";
import type { Competition, Match, NewsArticle, Player, Season, Team } from "@/lib/types";
import { readJSON, readString, writeJSON, writeString } from "@/lib/storage";
import { getDataSource } from "@/stores/dataSource";

const CATALOG_SNAPSHOT_KEY = "hb.catalog.snapshot";

type CatalogSnapshot = {
  seasons: Season[];
  competitions: Competition[];
  teams: Team[];
  players: Player[];
  matches: Match[];
  news: NewsArticle[];
  selectedSeasonId: string | null;
};

type CatalogState = {
  seasons: Season[];
  competitions: Competition[];
  teams: Team[];
  players: Player[];
  matches: Match[];
  news: NewsArticle[];
  selectedSeasonId: string | null;
  loading: boolean;
  error: string | null;
  teamById: (id: string) => Team | undefined;
  playerById: (id: string) => Player | undefined;
  competitionById: (id: string) => Competition | undefined;
  setSelectedSeasonId: (id: string) => void;
  refresh: () => Promise<void>;
  refreshMatches: () => Promise<void>;
};

const CatalogContext = createContext<CatalogState | null>(null);

function readSnapshot(): CatalogSnapshot | null {
  const snap = readJSON<CatalogSnapshot | null>(CATALOG_SNAPSHOT_KEY, null);
  if (!snap || !Array.isArray(snap.seasons)) return null;
  return snap;
}

function writeSnapshot(data: CatalogSnapshot) {
  writeJSON(CATALOG_SNAPSHOT_KEY, data);
}

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [seasons, setSeasons] = useState<Season[]>([]);
  const [competitions, setCompetitions] = useState<Competition[]>([]);
  const [teams, setTeams] = useState<Team[]>([]);
  const [players, setPlayers] = useState<Player[]>([]);
  const [matches, setMatches] = useState<Match[]>([]);
  const [news, setNews] = useState<NewsArticle[]>([]);
  const [selectedSeasonId, setSelectedSeasonIdState] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const applyData = useCallback((data: CatalogSnapshot) => {
    setSeasons(data.seasons);
    setCompetitions(data.competitions);
    setTeams(data.teams);
    setPlayers(data.players);
    setMatches(data.matches);
    setNews(data.news);
    setSelectedSeasonIdState(data.selectedSeasonId);
  }, []);

  const loadFromSnapshot = useCallback((): boolean => {
    const snap = readSnapshot();
    if (!snap) {
      applyData({
        seasons: [],
        competitions: [],
        teams: [],
        players: [],
        matches: [],
        news: [],
        selectedSeasonId: null,
      });
      setError("Nejdřív načti online data, pak přepni na mock");
      return false;
    }
    applyData(snap);
    setError(null);
    return true;
  }, [applyData]);

  const loadOnline = useCallback(
    async (seasonId?: string | null) => {
      const seasonsData = await fetchSeasons();
      const saved = readString("hb.selectedSeason", "");
      const current =
        seasonId ??
        (saved ||
          seasonsData.find((s) => s.isCurrent)?.id ||
          seasonsData[0]?.id ||
          null);

      // Stejné pořadí jako iOS CatalogStore: soutěže sezóny → týmy → zápasy → hráči → novinky
      const comps = await fetchCompetitions(current ?? undefined);
      const [teamsData, matchesData, playersData, newsData] = await Promise.all([
        current ? fetchTeamsForSeason(current) : Promise.resolve([] as Team[]),
        fetchMatches({ seasonId: current ?? undefined }),
        fetchPlayers({ seasonId: current ?? undefined }),
        fetchNews(20),
      ]);

      const snapshot: CatalogSnapshot = {
        seasons: seasonsData,
        competitions: comps,
        teams: teamsData,
        players: playersData,
        matches: matchesData,
        news: newsData,
        selectedSeasonId: current,
      };
      applyData(snapshot);
      writeSnapshot(snapshot);
      setError(null);
    },
    [applyData]
  );

  const load = useCallback(
    async (seasonId?: string | null) => {
      setLoading(true);
      setError(null);
      try {
        if (getDataSource() === "mock") {
          loadFromSnapshot();
        } else {
          await loadOnline(seasonId);
        }
      } catch (e) {
        setError(e instanceof Error ? e.message : "Nepodařilo se načíst data");
      } finally {
        setLoading(false);
      }
    },
    [loadFromSnapshot, loadOnline]
  );

  useEffect(() => {
    void load();
  }, [load]);

  const setSelectedSeasonId = useCallback(
    (id: string) => {
      writeString("hb.selectedSeason", id);
      setSelectedSeasonIdState(id);
      if (getDataSource() === "mock") {
        // V mock režimu jen přepneme vybranou sezónu ve snapshotu (bez síťového fetch).
        const snap = readSnapshot();
        if (snap) {
          writeSnapshot({ ...snap, selectedSeasonId: id });
        }
        return;
      }
      void load(id);
    },
    [load]
  );

  const refreshMatches = useCallback(async () => {
    if (getDataSource() === "mock") {
      const snap = readSnapshot();
      if (snap) setMatches(snap.matches);
      return;
    }
    const data = await fetchMatches({ seasonId: selectedSeasonId ?? undefined });
    setMatches(data);
    const snap = readSnapshot();
    if (snap) {
      writeSnapshot({ ...snap, matches: data });
    }
  }, [selectedSeasonId]);

  const teamMap = useMemo(() => new Map(teams.map((t) => [t.id, t])), [teams]);
  const playerMap = useMemo(() => {
    const map = new Map<string, Player>();
    for (const p of players) {
      if (!map.has(p.id)) map.set(p.id, p);
    }
    return map;
  }, [players]);
  const compMap = useMemo(
    () => new Map(competitions.map((c) => [c.id, c])),
    [competitions]
  );

  const value: CatalogState = {
    seasons,
    competitions,
    teams,
    players,
    matches,
    news,
    selectedSeasonId,
    loading,
    error,
    teamById: (id) => teamMap.get(id),
    playerById: (id) => playerMap.get(id),
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

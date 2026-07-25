"use client";

import { useEffect, useRef } from "react";
import { TeamBadge } from "@/components/Badges";
import type { Match } from "@/lib/types";
import { useCatalog } from "@/stores/catalog";
import { useFavorites } from "@/stores/favorites";
import { useMatchAlerts } from "@/stores/matchAlerts";
import { useNav } from "@/stores/navigation";
import { useNotifications } from "@/stores/notifications";
import { showBrowserNotification } from "@/lib/browserNotify";
import {
  beginViewingMatch,
  dismissCurrent,
  endViewingMatch,
  isViewingMatch,
  presentBanner,
  useBanners,
} from "@/stores/banners";

function shouldNotifyMatch(
  match: Match,
  opts: {
    onlyFavorites: boolean;
    isEnabled: (id: string) => boolean;
    isFavMatch: (id: string) => boolean;
    isFavTeam: (id: string) => boolean;
  }
) {
  // Ztlumený zápas → nikdy.
  if (!opts.isEnabled(match.id)) return false;
  if (opts.onlyFavorites) {
    return (
      opts.isFavMatch(match.id) ||
      opts.isFavTeam(match.homeTeamId) ||
      opts.isFavTeam(match.awayTeamId)
    );
  }
  return true;
}

/** Sleduje skóre live zápasů a frontu in-app bannerů. */
function useLiveBannerWatcher() {
  const { matches, teamById, refreshMatches } = useCatalog();
  const fav = useFavorites();
  const alerts = useMatchAlerts();
  const notif = useNotifications();
  const prevScores = useRef<Map<string, { home: number; away: number; status: string }>>(
    new Map()
  );
  const finishedAnnounced = useRef(new Set<string>());
  const startAnnounced = useRef(new Set<string>());
  const bootstrapped = useRef(false);
  const { push } = useNav();

  useEffect(() => {
    const id = window.setInterval(() => {
      void refreshMatches();
    }, 8000);
    return () => window.clearInterval(id);
  }, [refreshMatches]);

  useEffect(() => {
    const map = prevScores.current;

    if (!bootstrapped.current) {
      for (const m of matches) {
        map.set(m.id, { home: m.homeScore, away: m.awayScore, status: m.status });
        if (m.status === "finished") finishedAnnounced.current.add(m.id);
      }
      bootstrapped.current = true;
      return;
    }

    for (const match of matches) {
      const prev = map.get(match.id);
      const home = teamById(match.homeTeamId)?.shortName ?? "?";
      const away = teamById(match.awayTeamId)?.shortName ?? "?";
      const notifyOk = shouldNotifyMatch(match, {
        onlyFavorites: notif.onlyFavorites,
        isEnabled: alerts.isEnabled,
        isFavMatch: fav.isMatch,
        isFavTeam: fav.isTeam,
      });

      // Začátek zápasu: scheduled → live
      if (
        prev?.status === "scheduled" &&
        match.status === "live" &&
        !startAnnounced.current.has(match.id) &&
        notif.matchStartEnabled &&
        notifyOk
      ) {
        startAnnounced.current.add(match.id);
        if (!isViewingMatch(match.id)) {
          showBrowserNotification({
            title: "Začátek zápasu",
            body: `${home} – ${away}`,
            tag: `start-${match.id}`,
            onClick: () => push({ name: "match", id: match.id }),
          });
        }
      }

      if (prev && match.status === "live") {
        const homeUp = match.homeScore > prev.home;
        const awayUp = match.awayScore > prev.away;
        if ((homeUp || awayUp) && notif.goalsEnabled && notifyOk) {
          let scoringTeamId: string | null = homeUp ? match.homeTeamId : match.awayTeamId;
          if (homeUp && awayUp) {
            scoringTeamId =
              match.events.filter((e) => e.kind === "goal").at(-1)?.teamId ?? scoringTeamId;
          } else {
            const lastGoal = match.events.filter((e) => e.kind === "goal").at(-1);
            if (lastGoal) scoringTeamId = lastGoal.teamId;
          }
          presentBanner({
            kind: "goal",
            match,
            homeName: home,
            awayName: away,
            scoringTeamId,
          });
          if (!isViewingMatch(match.id)) {
            showBrowserNotification({
              title: "Gól",
              body: `${home} ${match.homeScore}:${match.awayScore} ${away}`,
              tag: `goal-${match.id}-${match.homeScore}-${match.awayScore}`,
              onClick: () => push({ name: "match", id: match.id }),
            });
          }
        }
      }

      if (
        match.status === "finished" &&
        prev?.status === "live" &&
        !finishedAnnounced.current.has(match.id) &&
        notif.finalScoreEnabled &&
        notifyOk
      ) {
        finishedAnnounced.current.add(match.id);
        presentBanner({
          kind: "finalScore",
          match,
          homeName: home,
          awayName: away,
        });
        if (!isViewingMatch(match.id)) {
          showBrowserNotification({
            title: "Konec",
            body: `${home} ${match.homeScore}:${match.awayScore} ${away}`,
            tag: `final-${match.id}`,
            onClick: () => push({ name: "match", id: match.id }),
          });
        }
      }

      map.set(match.id, {
        home: match.homeScore,
        away: match.awayScore,
        status: match.status,
      });
    }
  }, [matches, teamById, notif, alerts, fav, push]);
}

/** Sync viewingMatchIds z navigačního stacku (bez zásahu do MatchDetailScreen). */
function useViewingMatchFromNav() {
  const { stack } = useNav();
  const top = stack[stack.length - 1];
  const matchId = top?.name === "match" ? top.id : null;

  useEffect(() => {
    if (!matchId) return;
    beginViewingMatch(matchId);
    return () => endViewingMatch(matchId);
  }, [matchId]);
}

export function InAppBannerOverlay() {
  const { current } = useBanners();
  const { teamById } = useCatalog();
  const { push } = useNav();
  useLiveBannerWatcher();
  useViewingMatchFromNav();

  if (!current) return null;

  const home = teamById(current.homeTeamId);
  const away = teamById(current.awayTeamId);
  const scoring =
    current.scoringTeamId != null
      ? teamById(current.scoringTeamId)
      : current.kind === "goal"
        ? home
        : undefined;
  const title = current.kind === "goal" ? "Gól" : "Konec";
  const score = `${current.homeScore}:${current.awayScore}`;

  return (
    <div className="pointer-events-none absolute inset-x-0 top-0 z-50 flex justify-center px-3.5 pt-1.5">
      <button
        type="button"
        className="pointer-events-auto flex w-full max-w-[420px] items-center gap-3.5 rounded-[var(--radius-lg)] border border-card-stroke bg-card px-4 py-3.5 text-left shadow-[0_6px_16px_rgba(0,0,0,0.12)] hb-enter"
        onClick={() => {
          const id = current.matchId;
          dismissCurrent();
          push({ name: "match", id });
        }}
        aria-label={`${title}. ${current.homeName} ${score} ${current.awayName}.`}
      >
        {current.kind === "goal" && scoring ? (
          <TeamBadge team={scoring} size={44} />
        ) : (
          <div className="flex items-center gap-2">
            {home && <TeamBadge team={home} size={34} />}
            {away && <TeamBadge team={away} size={34} />}
          </div>
        )}
        <div className="min-w-0 flex-1">
          <div
            className={`text-[12px] font-bold tracking-[0.6px] uppercase ${
              current.kind === "goal" ? "text-live" : "text-hb-faint"
            }`}
          >
            {title}
          </div>
          <div className="mt-1 flex min-w-0 items-center gap-1.5">
            <span
              className={`truncate text-[16px] ${
                current.scoringTeamId === current.homeTeamId ? "font-bold" : "font-semibold"
              } ${
                current.kind === "goal" && current.scoringTeamId !== current.homeTeamId
                  ? "text-hb-muted"
                  : "text-hb-fg"
              }`}
            >
              {current.homeName}
            </span>
            <span className="hb-number shrink-0 text-[20px] font-extrabold tabular-nums text-hb-fg">
              {score}
            </span>
            <span
              className={`truncate text-[16px] ${
                current.scoringTeamId === current.awayTeamId ? "font-bold" : "font-semibold"
              } ${
                current.kind === "goal" && current.scoringTeamId !== current.awayTeamId
                  ? "text-hb-muted"
                  : "text-hb-fg"
              }`}
            >
              {current.awayName}
            </span>
          </div>
        </div>
      </button>
    </div>
  );
}

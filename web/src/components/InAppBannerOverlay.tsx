"use client";

import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";
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
  const { current, exiting } = useBanners();
  const { teamById } = useCatalog();
  const { push } = useNav();
  useLiveBannerWatcher();
  useViewingMatchFromNav();

  const [dragY, setDragY] = useState(0);
  const [swipingOut, setSwipingOut] = useState(false);
  const startY = useRef<number | null>(null);
  const dragging = useRef(false);

  const home = current ? teamById(current.homeTeamId) : undefined;
  const away = current ? teamById(current.awayTeamId) : undefined;
  const isGoal = current?.kind === "goal";
  const homeScored = Boolean(current && isGoal && current.scoringTeamId === current.homeTeamId);
  const awayScored = Boolean(current && isGoal && current.scoringTeamId === current.awayTeamId);
  const accentText = isGoal ? "text-live" : "text-brand";
  const homeLabel = home?.shortName ?? current?.homeName ?? "";
  const awayLabel = away?.shortName ?? current?.awayName ?? "";

  useEffect(() => {
    setDragY(0);
    setSwipingOut(false);
    startY.current = null;
    dragging.current = false;
  }, [current?.id]);

  const open = () => {
    if (!current || exiting || swipingOut || dragging.current) return;
    if (Math.abs(dragY) > 10) return;
    const id = current.matchId;
    dismissCurrent();
    if (id !== "banner-preview") push({ name: "match", id });
  };

  const onPointerDown = (e: ReactPointerEvent<HTMLButtonElement>) => {
    if (exiting || swipingOut) return;
    startY.current = e.clientY;
    dragging.current = false;
    e.currentTarget.setPointerCapture(e.pointerId);
  };

  const onPointerMove = (e: ReactPointerEvent<HTMLButtonElement>) => {
    if (startY.current == null || exiting || swipingOut) return;
    const dy = Math.min(0, e.clientY - startY.current);
    if (Math.abs(dy) > 6) dragging.current = true;
    setDragY(dy);
  };

  const onPointerUp = () => {
    if (startY.current == null) return;
    const up = -dragY;
    startY.current = null;
    if (up > 28) {
      setSwipingOut(true);
      setDragY(-88);
      window.setTimeout(() => {
        dismissCurrent({ alreadyAnimated: true });
        setSwipingOut(false);
        setDragY(0);
        dragging.current = false;
      }, 200);
    } else {
      setDragY(0);
      window.setTimeout(() => {
        dragging.current = false;
      }, 50);
    }
  };

  const offsetY = swipingOut ? dragY : dragY;
  const opacity = swipingOut
    ? 0
    : Math.max(0.15, 1 + dragY / 120);

  return (
    <div className="pointer-events-none absolute inset-0 z-50" aria-hidden={!current}>
      {current && (
        <div className="flex justify-center px-4 pt-[calc(var(--safe-top)+6px)]">
          <button
            type="button"
            onClick={open}
            onPointerDown={onPointerDown}
            onPointerMove={onPointerMove}
            onPointerUp={onPointerUp}
            onPointerCancel={onPointerUp}
            className={`pointer-events-auto flex w-full max-w-[420px] items-center gap-2 rounded-full border border-card-stroke bg-card px-3.5 py-2.5 text-left shadow-[0_4px_14px_rgba(0,0,0,0.14)] touch-none ${
              swipingOut
                ? ""
                : exiting
                  ? "hb-banner-slide-out"
                  : dragY === 0
                    ? "hb-banner-slide"
                    : ""
            }`}
            style={
              swipingOut || dragY !== 0
                ? {
                    transform: `translateY(${offsetY}px)`,
                    opacity,
                    transition: swipingOut
                      ? "transform 0.2s ease-in, opacity 0.2s ease-in"
                      : dragging.current
                        ? "none"
                        : "transform 0.18s ease-out, opacity 0.18s ease-out",
                  }
                : undefined
            }
            aria-label={`${isGoal ? "Gól" : "Konec"}. ${current.homeName} ${current.homeScore}:${current.awayScore} ${current.awayName}.`}
          >
            <span className={`shrink-0 text-[11px] font-bold tracking-[0.8px] ${accentText}`}>
              {isGoal ? "GÓL" : "KONEC"}
            </span>
            {home && <TeamBadge team={home} size={18} />}
            <span
              className={`truncate text-[12px] ${
                homeScored ? "font-bold text-live" : "font-semibold text-hb-fg"
              }`}
            >
              {homeLabel}
            </span>
            <span className="hb-number flex shrink-0 items-baseline gap-px text-[14px] font-extrabold tabular-nums">
              <span className={homeScored ? "text-live" : "text-hb-fg"}>{current.homeScore}</span>
              <span className="text-hb-muted">:</span>
              <span className={awayScored ? "text-live" : "text-hb-fg"}>{current.awayScore}</span>
            </span>
            <span
              className={`truncate text-[12px] ${
                awayScored ? "font-bold text-live" : "font-semibold text-hb-fg"
              }`}
            >
              {awayLabel}
            </span>
            {away && <TeamBadge team={away} size={18} />}
          </button>
        </div>
      )}
    </div>
  );
}

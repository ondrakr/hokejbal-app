"use client";

import { AmateurAdminHub } from "@/screens/amateur/AmateurAdminHub";
import { AmateurAdminTeam } from "@/screens/amateur/AmateurAdminTeam";
import { AmateurAdminTournament } from "@/screens/amateur/AmateurAdminTournament";
import { AmateurCreate } from "@/screens/amateur/AmateurCreate";
import { AmateurDetail } from "@/screens/amateur/AmateurDetail";
import { AmateurHub } from "@/screens/amateur/AmateurHub";
import { AmateurMatchDetail } from "@/screens/amateur/AmateurMatchDetail";
import { AmateurScorer } from "@/screens/amateur/AmateurScorer";
import { AmateurTeamDetail } from "@/screens/amateur/AmateurTeamDetail";
import { EmptyState, ScreenHeader, BackButton } from "@/components/ui";
import { useNav } from "@/stores/navigation";

export type AmateurScreenProps = {
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

export function AmateurScreen({
  screen = "hub",
  id,
  teamId,
  matchId,
}: AmateurScreenProps) {
  const { pop } = useNav();

  switch (screen) {
    case "hub":
      return <AmateurHub />;
    case "adminHub":
      return <AmateurAdminHub />;
    case "create":
      return <AmateurCreate />;
    case "detail":
      if (!id) break;
      return <AmateurDetail tournamentId={id} />;
    case "admin":
      if (!id) break;
      return <AmateurAdminTournament tournamentId={id} />;
    case "adminTeam":
      if (!teamId) break;
      return <AmateurAdminTeam teamId={teamId} />;
    case "team":
      if (!teamId) break;
      return <AmateurTeamDetail teamId={teamId} />;
    case "match":
      if (!matchId) break;
      return <AmateurMatchDetail matchId={matchId} />;
    case "scorer":
      if (!matchId) break;
      return <AmateurScorer matchId={matchId} />;
  }

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Amatérské turnaje" left={<BackButton onClick={pop} />} />
      <EmptyState title="Obrazovka nenalezena" hint="Chybí identifikátor turnaje nebo zápasu." />
    </div>
  );
}

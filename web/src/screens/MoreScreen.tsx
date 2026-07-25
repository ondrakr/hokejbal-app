"use client";

import {
  IconFlagCheckered,
  IconGear,
  IconHeadphones,
  IconMore,
  IconNews,
  IconSearch,
  IconTarget,
  IconTrophy,
  IconTv,
} from "@/components/Icons";
import { MoreMenuRow, ScreenHeader } from "@/components/ui";
import { useNav } from "@/stores/navigation";

const PRIMARY_ITEMS = [
  { title: "Fantasy", icon: <IconTrophy size={18} />, action: "fantasy" as const },
  { title: "Tipovačka", icon: <IconTarget size={18} />, action: "tips" as const },
  { title: "Amatérské turnaje", icon: <IconFlagCheckered size={18} />, action: "amateur" as const },
  { title: "Vyhledávání", icon: <IconSearch size={18} />, action: "search" as const },
  { title: "Novinky", icon: <IconNews size={18} />, action: "news" as const },
  { title: "Živé přenosy", icon: <IconTv size={18} filled />, action: "live" as const },
  { title: "Dělníci hokejbalu", icon: <IconHeadphones size={18} />, action: "media" as const },
];

type MoreAction = (typeof PRIMARY_ITEMS)[number]["action"] | "settings";

/** Port MoreView.swift */
export function MoreScreen() {
  const { push, selectLive } = useNav();

  function handle(action: MoreAction) {
    switch (action) {
      case "fantasy":
        push({ name: "fantasy", screen: "hub" });
        break;
      case "tips":
        push({ name: "tips", screen: "hub" });
        break;
      case "amateur":
        push({ name: "amateur", screen: "hub" });
        break;
      case "settings":
        push({ name: "settings" });
        break;
      case "search":
        push({ name: "search" });
        break;
      case "news":
        push({ name: "news" });
        break;
      case "live":
        selectLive("broadcasts");
        break;
      case "media":
        push({ name: "media" });
        break;
    }
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col hb-enter">
      <ScreenHeader title="Více" systemIcon={<IconMore size={14} filled />} />
      <div className="hb-scroll flex min-h-0 flex-1 flex-col px-4 pt-3 pb-6">
        <div className="flex flex-col gap-2.5">
          {PRIMARY_ITEMS.map((item) => (
            <MoreMenuRow
              key={item.title}
              icon={item.icon}
              title={item.title}
              onClick={() => handle(item.action)}
            />
          ))}
        </div>

        <div className="mt-auto pt-8">
          <MoreMenuRow
            icon={<IconGear size={18} />}
            title="Nastavení"
            onClick={() => handle("settings")}
          />
        </div>
      </div>
    </div>
  );
}

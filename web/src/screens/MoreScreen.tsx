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

const ITEMS = [
  { title: "Fantasy", icon: <IconTrophy size={18} />, action: "fantasy" as const },
  { title: "Tipovačka", icon: <IconTarget size={18} />, action: "tips" as const },
  { title: "Amatérské turnaje", icon: <IconFlagCheckered size={18} />, action: "amateur" as const },
  { title: "Nastavení", icon: <IconGear size={18} />, action: "settings" as const },
  { title: "Vyhledávání", icon: <IconSearch size={18} />, action: "search" as const },
  { title: "Novinky", icon: <IconNews size={18} />, action: "news" as const },
  { title: "Živé přenosy", icon: <IconTv size={18} filled />, action: "live" as const },
  { title: "Dělníci hokejbalu", icon: <IconHeadphones size={18} />, action: "media" as const },
];

/** Port MoreView.swift */
export function MoreScreen() {
  const { push, selectLive } = useNav();

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Více" systemIcon={<IconMore size={14} filled />} />
      <div className="flex flex-col gap-2.5 px-4 pt-3 pb-6">
        {ITEMS.map((item) => (
          <MoreMenuRow
            key={item.title}
            icon={item.icon}
            title={item.title}
            onClick={() => {
              switch (item.action) {
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
            }}
          />
        ))}
      </div>
    </div>
  );
}

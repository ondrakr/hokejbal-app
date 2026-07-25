"use client";

import { ScreenHeader } from "@/components/ui";
import { useNav } from "@/stores/navigation";

const ITEMS: {
  title: string;
  subtitle: string;
  action: "fantasy" | "tips" | "amateur" | "settings" | "search" | "news" | "live" | "media";
}[] = [
  { title: "Fantasy", subtitle: "Sestav tým a sbírej body", action: "fantasy" },
  { title: "Tipovačka", subtitle: "Tipuj výsledky extraligy", action: "tips" },
  { title: "Amatérské turnaje", subtitle: "Vlastní turnaje offline", action: "amateur" },
  { title: "Nastavení", subtitle: "Sezóna a vzhled", action: "settings" },
  { title: "Vyhledávání", subtitle: "Týmy, hráči, soutěže", action: "search" },
  { title: "Novinky", subtitle: "Aktuality ze světa hokejbalu", action: "news" },
  { title: "Živé přenosy", subtitle: "Live zápasy se streamem", action: "live" },
  { title: "Dělníci hokejbalu", subtitle: "Videa a reportáže", action: "media" },
];

export function MoreScreen() {
  const { push, selectLive } = useNav();

  return (
    <div className="hb-scroll hb-enter flex-1">
      <ScreenHeader title="Více" large />
      <div className="space-y-2 px-[var(--screen-pad)] pb-8">
        {ITEMS.map((item) => (
          <button
            key={item.title}
            type="button"
            className="hb-card flex w-full items-center justify-between px-4 py-3.5 text-left"
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
          >
            <div>
              <div className="text-[15px] font-bold">{item.title}</div>
              <div className="hb-muted">{item.subtitle}</div>
            </div>
            <span className="text-[var(--text-tertiary)]">›</span>
          </button>
        ))}
      </div>
    </div>
  );
}

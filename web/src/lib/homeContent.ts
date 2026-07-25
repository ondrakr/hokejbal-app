/** Statický obsah Domů — port HomeContent z HomeView.swift */
export type HomeBanner = {
  id: string;
  eyebrow: string;
  title: string;
  subtitle: string;
  ctaTitle: string;
  url: string | null;
  gradientIndex: number;
};

export type HomeVideo = {
  id: string;
  title: string;
  dateLabel: string;
  url: string;
  gradientIndex: number;
  sourceLabel: string;
};

export type HomePartner = {
  id: string;
  name: string;
  url: string;
};

export const HOME_BANNERS: HomeBanner[] = [
  {
    id: "ms2026",
    eyebrow: "MS V HOKEJBALU 2026",
    title: "20.–28. června · Ostravar Aréna",
    subtitle: "Mistrovství světa mužů a žen v Ostravě.",
    ctaTitle: "Kupuj vstupenky",
    url: "https://www.hokejbal.cz",
    gradientIndex: 0,
  },
  {
    id: "legends2026",
    eyebrow: "MS LEGENDS 2026",
    title: "Praha-Černošice",
    subtitle: "Legendy se vrací na domácí půdu.",
    ctaTitle: "Více informací",
    url: "https://www.hokejbal.cz",
    gradientIndex: 1,
  },
];

export const DELNICI_CHANNEL_URL = "https://www.youtube.com/@delnicihokejbalu";

export const HOME_VIDEOS: HomeVideo[] = [
  {
    id: "dh019",
    title: "Doba stříbrná! Jaká byla Ostrava? MS v Bánské je za námi! | DH #019",
    dateLabel: "Dělníci hokejbalu",
    url: "https://www.youtube.com/watch?v=MJJCSt8dr6E",
    gradientIndex: 0,
    sourceLabel: "DĚLNÍCI",
  },
  {
    id: "dh-sipky",
    title: "Slib splněn! Kdo je teda lepší v šipkách? | DH",
    dateLabel: "Dělníci hokejbalu",
    url: "https://www.youtube.com/watch?v=BTvWi0HxN6Q",
    gradientIndex: 1,
    sourceLabel: "DĚLNÍCI",
  },
  {
    id: "dh-pascuzzo",
    title: "Elio Pascuzzo, prezident ISBHF | DH",
    dateLabel: "Dělníci hokejbalu",
    url: "https://www.youtube.com/watch?v=VYGqOhzF-K0",
    gradientIndex: 2,
    sourceLabel: "DĚLNÍCI",
  },
  {
    id: "dh-kabina",
    title: "Prohlídka kabiny s Lucií Kubinovou a Terezou Radovou | DH",
    dateLabel: "Dělníci hokejbalu",
    url: "https://www.youtube.com/watch?v=BzUQc9Ju_DA",
    gradientIndex: 3,
    sourceLabel: "DĚLNÍCI",
  },
  {
    id: "dh-wrobel",
    title: "Tomáš Wróbel a jeho poslední MS? | DH",
    dateLabel: "Dělníci hokejbalu",
    url: "https://www.youtube.com/watch?v=p76vKGaC4Bs",
    gradientIndex: 0,
    sourceLabel: "DĚLNÍCI",
  },
  {
    id: "dh-bydleni",
    title: "Jak bydlí naši reprezentanti? Pojďte se s námi podívat! | DH",
    dateLabel: "Dělníci hokejbalu",
    url: "https://www.youtube.com/watch?v=mJaKifAmi9w",
    gradientIndex: 1,
    sourceLabel: "DĚLNÍCI",
  },
];

export const HOME_PARTNERS: HomePartner[] = [
  { id: "p1", name: "ČMSHb", url: "https://www.hokejbal.cz" },
  { id: "p2", name: "Fantasy", url: "https://hokejbal-fantasy.cz" },
  { id: "p3", name: "Hokejbal TV", url: "https://www.youtube.com/@hokejbal" },
  { id: "p4", name: "Dělníci hokejbalu", url: DELNICI_CHANNEL_URL },
  { id: "p5", name: "Partneři", url: "https://www.hokejbal.cz/partneri" },
];

export const HOME_GRADIENTS: [string, string][] = [
  ["#c92a2a", "#a92323"],
  ["#1f4785", "#0f2447"],
  ["#1f6b52", "#0d382e"],
  ["#7a381f", "#471a0f"],
];

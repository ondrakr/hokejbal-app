import { NextResponse } from "next/server";

const IMAGE_BASE =
  "https://www.hokejbal.cz/image?exact&topcut&w=800&h=500&file=photo/article/article_";

const KNOWN_CATEGORIES = [
  "CTM a HCŽ",
  "Masters",
  "Mládež",
  "Turnaje",
  "Extraliga",
  "1. liga",
  "2. liga",
  "Reprezentace",
  "Liga žen",
  "Junioři",
  "Dorost",
];

function stripTags(html: string) {
  return html.replace(/<[^>]+>/g, " ");
}

function detectCategory(text: string) {
  return KNOWN_CATEGORIES.find((c) => text.includes(c)) ?? null;
}

function detectDate(text: string): string | null {
  const m = text.match(/(\d{1,2}\.\s*\d{1,2}\.\s*\d{4})/);
  if (!m) return null;
  const raw = m[1].replace(/\s+/g, " ");
  const parts = raw.match(/(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})/);
  if (!parts) return null;
  const [, d, mo, y] = parts;
  const iso = `${y}-${mo.padStart(2, "0")}-${d.padStart(2, "0")}T12:00:00.000Z`;
  return iso;
}

function parseNews(html: string, limit: number) {
  const linkRe =
    /<a[^>]+href="(\/clanek\/(\d+)-([^"']+))"[^>]*>([\s\S]*?)<\/a>/gi;
  const seen = new Set<string>();
  const articles: Array<{
    id: string;
    title: string;
    summary: string;
    category: string;
    publishedAt: string;
    photoURL: string;
    articleURL: string;
    imageGradientIndex: number;
  }> = [];

  let match: RegExpExecArray | null;
  while ((match = linkRe.exec(html)) && articles.length < limit) {
    const [, path, id, , inner] = match;
    if (seen.has(id)) continue;
    const title = stripTags(inner)
      .replace(/\s+/g, " ")
      .trim();
    if (title.length < 20) continue;
    seen.add(id);

    const start = Math.max(0, match.index - 600);
    const end = Math.min(html.length, match.index + match[0].length + 200);
    const chunk = stripTags(html.slice(start, end)).replace(/\s+/g, " ");
    const category = detectCategory(chunk) ?? "Novinky";
    const publishedAt = detectDate(chunk) ?? new Date().toISOString();

    articles.push({
      id,
      title,
      summary: title,
      category,
      publishedAt,
      photoURL: `${IMAGE_BASE}${id}.jpg`,
      articleURL: `https://www.hokejbal.cz${path}`,
      imageGradientIndex: articles.length % 5,
    });
  }
  return articles;
}

/** Stejný zdroj jako iOS HokejbalCzNewsClient — scrape homepage s fotkami. */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = Math.min(Number(searchParams.get("limit") ?? 12) || 12, 30);

  try {
    const res = await fetch("https://www.hokejbal.cz", {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
      },
      next: { revalidate: 300 },
    });
    if (!res.ok) {
      return NextResponse.json({ articles: [], error: "upstream" }, { status: 502 });
    }
    const html = await res.text();
    const articles = parseNews(html, limit);
    return NextResponse.json({ articles });
  } catch {
    return NextResponse.json({ articles: [], error: "fetch_failed" }, { status: 502 });
  }
}

import { NextResponse } from "next/server";

const FETCH_HOSTS = new Set(["hokejbal.cz", "www.hokejbal.cz"]);
const JUNK = ["cookie", "souhlas", "gdpr", "newsletter", "přihlášení"];

function isTrustedHost(host: string) {
  const h = host.toLowerCase();
  return [...FETCH_HOSTS].some((allowed) => h === allowed || h.endsWith("." + allowed));
}

function trustedFetchUrl(raw: string | null): URL | null {
  if (!raw?.trim()) return null;
  try {
    let s = raw.trim();
    if (s.startsWith("//")) s = "https:" + s;
    const u = new URL(s);
    if (u.protocol !== "https:") return null;
    if (!u.host || !isTrustedHost(u.host)) return null;
    return u;
  } catch {
    return null;
  }
}

function stripTags(html: string) {
  return html.replace(/<[^>]+>/g, " ");
}

function decodeHTMLEntities(text: string) {
  return text
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/gi, "'");
}

/** Stejná logika jako iOS HokejbalCzNewsClient.parseBody */
export function parseBody(html: string): string {
  const blockMatch = html.match(
    /<div[^>]*class="[^"]*typography[^"]*"[^>]*>([\s\S]*?)<\/div>/i
  );
  const source = blockMatch?.[1] ?? html;

  const paragraphRe = /<p[^>]*>([\s\S]*?)<\/p>/gi;
  const paragraphs: string[] = [];
  let match: RegExpExecArray | null;
  while ((match = paragraphRe.exec(source))) {
    const text = decodeHTMLEntities(stripTags(match[1]))
      .replace(/\s+/g, " ")
      .trim();
    if (text.length < 40) continue;
    const lower = text.toLowerCase();
    if (JUNK.some((j) => lower.includes(j))) continue;
    paragraphs.push(text);
  }
  return paragraphs.join("\n\n");
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const url = trustedFetchUrl(searchParams.get("url"));
  if (!url) {
    return NextResponse.json({ error: "bad_url", body: "" }, { status: 400 });
  }

  try {
    const res = await fetch(url.toString(), {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
      },
      signal: AbortSignal.timeout(20_000),
      cache: "no-store",
    });
    if (!res.ok) {
      return NextResponse.json({ error: "upstream", body: "" }, { status: 502 });
    }
    const html = await res.text();
    const body = parseBody(html);
    return NextResponse.json({ body });
  } catch {
    return NextResponse.json({ error: "fetch_failed", body: "" }, { status: 502 });
  }
}

const cheerio = require("cheerio");
const { isInScope, inSection } = require("./_urlHelpers");

const MAX_SITEMAP_FETCHES = 25; // cap how many sitemap files (incl. nested ones) we'll follow
const MAX_URLS = 20000; // hard safety cap on total URLs pulled from sitemaps

async function fetchText(url) {
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; DocScannerBot/1.0)" },
    });
    if (!res.ok) return null;
    const ct = res.headers.get("content-type") || "";
    if (!ct.includes("xml") && !ct.includes("text")) return null;
    return await res.text();
  } catch {
    return null;
  }
}

/** Parses one sitemap (or sitemap index) XML body.
 *  Returns { urls: string[], childSitemaps: string[] } */
function parseSitemapXml(xml) {
  const $ = cheerio.load(xml, { xmlMode: true });
  const urls = [];
  $("url > loc").each((_, el) => urls.push($(el).text().trim()));
  const childSitemaps = [];
  $("sitemap > loc").each((_, el) => childSitemaps.push($(el).text().trim()));
  return { urls, childSitemaps };
}

async function findSitemapCandidates(origin) {
  // 1. Check robots.txt for a Sitemap: directive (works regardless of CMS).
  const robots = await fetchText(`${origin}/robots.txt`);
  const fromRobots = [];
  if (robots) {
    const matches = robots.matchAll(/^sitemap:\s*(\S+)/gim);
    for (const m of matches) fromRobots.push(m[1]);
  }
  if (fromRobots.length > 0) return fromRobots;

  // 2. Fall back to the common conventional paths.
  return [`${origin}/sitemap_index.xml`, `${origin}/wp-sitemap.xml`, `${origin}/sitemap.xml`];
}

/** Discovers sitemap-listed URLs that are in-scope for this scan.
 *  Returns a deduped array of URLs (does not include the root URL itself). */
async function discoverSitemapUrls(rootUrl, scope) {
  if (scope === "single") return [];

  const origin = new URL(rootUrl).origin;
  const seedHost = new URL(rootUrl).hostname;
  const seedPath = new URL(rootUrl).pathname;

  const candidates = await findSitemapCandidates(origin);
  const found = new Set();
  const queue = [...candidates];
  let fetches = 0;

  while (queue.length > 0 && fetches < MAX_SITEMAP_FETCHES && found.size < MAX_URLS) {
    const next = queue.shift();
    fetches += 1;
    const xml = await fetchText(next);
    if (!xml) continue;

    const { urls, childSitemaps } = parseSitemapXml(xml);
    for (const u of urls) {
      if (found.size >= MAX_URLS) break;
      try {
        const parsed = new URL(u);
        const hostOk = isInScope(seedHost, parsed.hostname, scope) || parsed.hostname === seedHost;
        const pathOk = scope !== "section" || inSection(seedPath, parsed.pathname);
        if (hostOk && pathOk) {
          found.add(parsed.toString());
        }
      } catch {
        /* skip malformed entries */
      }
    }
    for (const cs of childSitemaps) {
      if (!queue.includes(cs)) queue.push(cs);
    }

    // Once we've found real <url> entries from one working candidate, don't also
    // try the other guessed conventional paths - avoids double-counting.
    if (urls.length > 0 && candidates.includes(next)) {
      queue.length = 0;
      for (const cs of childSitemaps) queue.push(cs);
    }
  }

  return Array.from(found);
}

module.exports = { discoverSitemapUrls };

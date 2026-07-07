const { sbFetch } = require("./_sb");
const { discoverSitemapUrls } = require("./_sitemap");

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const { sbUrl, sbKey, url, scope, fileTypes, maxPages, fetchDetails } = req.body || {};

  if (!sbUrl || !sbKey) {
    res.status(400).json({ error: "Missing Supabase credentials." });
    return;
  }

  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    res.status(400).json({ error: "That doesn't look like a valid URL." });
    return;
  }
  if (!fileTypes || fileTypes.length === 0) {
    res.status(400).json({ error: "Pick at least one file type to scan for." });
    return;
  }

  try {
    const [scan] = await sbFetch(sbUrl, sbKey, "doc_scans", {
      method: "POST",
      body: JSON.stringify({
        root_url: parsed.toString(),
        website_name: parsed.hostname,
        scope,
        file_types: fileTypes,
        max_pages: maxPages || 500,
        fetch_details: fetchDetails ?? true,
        status: "running",
      }),
    });

    await sbFetch(sbUrl, sbKey, "doc_scan_queue", {
      method: "POST",
      prefer: "return=minimal",
      body: JSON.stringify({ scan_id: scan.id, url: parsed.toString(), depth: 0 }),
    });

    await sbFetch(sbUrl, sbKey, "doc_scan_visited", {
      method: "POST",
      prefer: "return=minimal",
      body: JSON.stringify({ scan_id: scan.id, url: parsed.toString() }),
    });

    let sitemapUrlsQueued = 0;
    if (scope !== "single") {
      try {
        const sitemapUrls = await discoverSitemapUrls(parsed.toString(), scope);
        const cap = Math.max(0, (maxPages || 500) - 1);
        const toQueue = sitemapUrls.filter((u) => u !== parsed.toString()).slice(0, cap);
        if (toQueue.length > 0) {
          await sbFetch(sbUrl, sbKey, "doc_scan_visited", {
            method: "POST",
            prefer: "return=minimal,resolution=ignore-duplicates",
            body: JSON.stringify(toQueue.map((u) => ({ scan_id: scan.id, url: u }))),
          });
          await sbFetch(sbUrl, sbKey, "doc_scan_queue", {
            method: "POST",
            prefer: "return=minimal",
            body: JSON.stringify(toQueue.map((u) => ({ scan_id: scan.id, url: u, depth: 1 }))),
          });
          sitemapUrlsQueued = toQueue.length;
        }
      } catch {
        // sitemap discovery is a best-effort bonus - normal link-following crawl still runs regardless
      }
    }

    res.status(200).json({ scan, sitemapUrlsQueued });
  } catch (e) {
    res.status(500).json({ error: e.message || "Could not start scan." });
  }
};

const cheerio = require("cheerio");
const { sbFetch } = require("./_sb");
const {
  isInScope,
  extensionOf,
  matchFileType,
  isCrawlableHtmlLink,
  fileNameFromUrl,
} = require("./_urlHelpers");
const { getFileMeta } = require("./_fileMeta");

const BATCH_SIZE = 4;
const FETCH_TIMEOUT_MS = 10000;

async function fetchWithTimeout(url, ms) {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), ms);
  try {
    return await fetch(url, {
      signal: controller.signal,
      headers: { "User-Agent": "Mozilla/5.0 (compatible; DocScannerBot/1.0)" },
    });
  } finally {
    clearTimeout(t);
  }
}

async function markQueueDone(sbUrl, sbKey, id) {
  await sbFetch(sbUrl, sbKey, `doc_scan_queue?id=eq.${id}`, {
    method: "PATCH",
    prefer: "return=minimal",
    body: JSON.stringify({ status: "done" }),
  });
}

async function finishScan(sbUrl, sbKey, scanId, status) {
  await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`, {
    method: "PATCH",
    prefer: "return=minimal",
    body: JSON.stringify({ status, finished_at: new Date().toISOString() }),
  });
}

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }
  const { sbUrl, sbKey, scanId } = req.body || {};
  if (!sbUrl || !sbKey || !scanId) {
    res.status(400).json({ error: "Missing sbUrl, sbKey, or scanId." });
    return;
  }

  try {
    const [scan] = await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`);
    if (!scan) {
      res.status(404).json({ error: "Scan not found." });
      return;
    }
    if (scan.status !== "running") {
      res.status(200).json({ done: true, scan });
      return;
    }

    const batch = await sbFetch(
      sbUrl,
      sbKey,
      `doc_scan_queue?scan_id=eq.${scanId}&status=eq.pending&order=id.asc&limit=${BATCH_SIZE}`
    );

    if (!batch || batch.length === 0) {
      await finishScan(sbUrl, sbKey, scanId, "done");
      const [updated] = await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`);
      res.status(200).json({ done: true, scan: updated });
      return;
    }

    const seedHost = new URL(scan.root_url).hostname;
    let newPagesCrawled = 0;
    let newFilesFound = 0;

    for (const item of batch) {
      try {
        if (scan.pages_crawled + newPagesCrawled >= scan.max_pages) {
          await markQueueDone(sbUrl, sbKey, item.id);
          continue;
        }

        const pageRes = await fetchWithTimeout(item.url, FETCH_TIMEOUT_MS);
        const contentType = pageRes.headers.get("content-type") || "";
        newPagesCrawled += 1;

        if (!pageRes.ok || !contentType.includes("text/html")) {
          await markQueueDone(sbUrl, sbKey, item.id);
          continue;
        }

        const html = await pageRes.text();
        const $ = cheerio.load(html);
        const links = new Set();
        $("a[href]").each((_, el) => {
          const href = $(el).attr("href");
          if (!href) return;
          try {
            const abs = new URL(href, item.url);
            abs.hash = "";
            if (abs.protocol === "http:" || abs.protocol === "https:") links.add(abs.toString());
          } catch {
            /* ignore malformed urls */
          }
        });

        for (const link of links) {
          const linkUrl = new URL(link);
          const ext = extensionOf(linkUrl.pathname);
          const matchedType = matchFileType(ext, scan.file_types);

          if (matchedType) {
            const meta = await getFileMeta(link, matchedType, scan.fetch_details);
            try {
              await sbFetch(sbUrl, sbKey, "doc_scan_files", {
                method: "POST",
                prefer: "return=minimal,resolution=ignore-duplicates",
                body: JSON.stringify({
                  scan_id: scanId,
                  file_name: fileNameFromUrl(link),
                  file_type: matchedType,
                  source_page_url: item.url,
                  file_url: link,
                  size_bytes: meta.sizeBytes,
                  pages: meta.pages,
                }),
              });
              newFilesFound += 1;
            } catch {
              // duplicate file already recorded for this scan - ignore
            }
            continue;
          }

          if (scan.scope !== "single" && isCrawlableHtmlLink(linkUrl) && isInScope(seedHost, linkUrl.hostname, scan.scope)) {
            try {
              await sbFetch(sbUrl, sbKey, "doc_scan_visited", {
                method: "POST",
                prefer: "return=minimal,resolution=ignore-duplicates",
                body: JSON.stringify({ scan_id: scanId, url: link }),
              });
              await sbFetch(sbUrl, sbKey, "doc_scan_queue", {
                method: "POST",
                prefer: "return=minimal",
                body: JSON.stringify({ scan_id: scanId, url: link, depth: item.depth + 1 }),
              });
            } catch {
              // already visited - skip re-queueing
            }
          }
        }

        await markQueueDone(sbUrl, sbKey, item.id);
      } catch {
        await markQueueDone(sbUrl, sbKey, item.id);
      }
    }

    await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`, {
      method: "PATCH",
      prefer: "return=minimal",
      body: JSON.stringify({
        pages_crawled: scan.pages_crawled + newPagesCrawled,
        files_found: scan.files_found + newFilesFound,
      }),
    });

    if (scan.scope === "single") {
      await finishScan(sbUrl, sbKey, scanId, "done");
      const [updated] = await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`);
      res.status(200).json({ done: true, scan: updated });
      return;
    }

    const remaining = await sbFetch(
      sbUrl,
      sbKey,
      `doc_scan_queue?scan_id=eq.${scanId}&status=eq.pending&select=id&limit=1`
    );

    if (!remaining || remaining.length === 0) {
      await finishScan(sbUrl, sbKey, scanId, "done");
    }

    const [updated] = await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`);
    res.status(200).json({ done: !remaining || remaining.length === 0, scan: updated });
  } catch (e) {
    try {
      await finishScan(sbUrl, sbKey, scanId, "error");
      await sbFetch(sbUrl, sbKey, `doc_scans?id=eq.${scanId}`, {
        method: "PATCH",
        prefer: "return=minimal",
        body: JSON.stringify({ error_message: e.message || "Unknown error" }),
      });
    } catch {
      /* best effort */
    }
    res.status(500).json({ error: e.message || "Unknown error while crawling." });
  }
};

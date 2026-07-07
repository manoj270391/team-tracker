module.exports = async (req, res) => {
  const url = req.query.url;
  if (!url) {
    res.status(400).json({ error: "Missing url param." });
    return;
  }

  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    res.status(400).json({ error: "Invalid url." });
    return;
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    res.status(400).json({ error: "Unsupported protocol." });
    return;
  }

  try {
    const upstream = await fetch(parsed.toString(), {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; DocScannerBot/1.0)" },
    });
    if (!upstream.ok || !upstream.body) {
      res.status(502).json({ error: `Upstream returned ${upstream.status}` });
      return;
    }
    res.setHeader("Content-Type", upstream.headers.get("content-type") || "application/octet-stream");
    const buf = Buffer.from(await upstream.arrayBuffer());
    res.status(200).send(buf);
  } catch {
    res.status(502).json({ error: "Could not fetch the file." });
  }
};

// Talks directly to Supabase's PostgREST API, the same way index.html's sbFetch does.
// Credentials come from the request body (same "stored in this browser's localStorage,
// sent straight to Supabase" model as the rest of the app) — no server-side env vars needed.

async function sbFetch(sbUrl, sbKey, path, opts = {}) {
  const res = await fetch(`${sbUrl}/rest/v1/${path}`, {
    ...opts,
    headers: {
      apikey: sbKey,
      Authorization: `Bearer ${sbKey}`,
      "Content-Type": "application/json",
      Prefer: opts.prefer || "return=representation",
      ...(opts.headers || {}),
    },
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    const err = new Error(text || `Supabase REST error ${res.status}`);
    err.status = res.status;
    throw err;
  }
  if (res.status === 204) return null;
  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

module.exports = { sbFetch };

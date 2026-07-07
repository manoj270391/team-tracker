# Team Tracker

A full-stack team productivity and billing tracker.  
Stack: **Supabase** (database) · **GitHub** (version control) · **Vercel** (hosting)

---

## Deploy in 4 stages (~20 minutes total)

### Stage 1 — Supabase (database)

1. Go to [supabase.com](https://supabase.com) and sign up (free).
2. Click **New project** → choose a name (e.g. `team-tracker`) → set a strong DB password → pick a region → **Create new project**. Wait ~1 min.
3. In your project sidebar go to **SQL Editor** → **New query**.
4. Paste the entire contents of `schema.sql` → click **Run**. You should see "Success. No rows returned."
5. Go to **Project Settings → API**. Copy:
   - **Project URL** → looks like `https://xxxx.supabase.co`
   - **anon / public** key → long JWT string

### Stage 2 — GitHub (version control)

1. Go to [github.com](https://github.com) and sign up / log in.
2. Click **+** → **New repository**.
3. Name it `team-tracker` → keep it **Public** (required for free Vercel) → click **Create repository**.
4. On your computer, open a terminal in this project folder and run:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/team-tracker.git
   git push -u origin main
   ```
   Replace `YOUR_USERNAME` with your GitHub username.

### Stage 3 — Vercel (hosting)

1. Go to [vercel.com](https://vercel.com) → **Sign up with GitHub**.
2. Click **Add New → Project**.
3. Find and click **Import** next to your `team-tracker` repository.
4. Leave all settings as default → click **Deploy**.
5. In ~30 seconds you'll see **Congratulations!** with a live URL like `https://team-tracker-xyz.vercel.app`.

### Stage 4 — Connect the app

1. Open your Vercel URL in a browser.
2. The app shows a setup screen — paste your **Supabase Project URL** and **Anon Key** from Stage 1.
3. Click **Connect & open app**. Done — your data is live and syncs across every device.

---

## Future updates

To update the app after making changes:
```bash
git add .
git commit -m "Your update description"
git push
```
Vercel auto-deploys on every push. No manual steps needed.

## Custom domain

In Vercel → your project → **Settings → Domains** → add your domain. Vercel handles HTTPS automatically.

---

## Document Scanner (added)

A new **Document Scanner** page in the sidebar lets you paste a client link, crawl it for
PDF/Word/PowerPoint/Excel files, and export a review sheet (File Name, Type, Pages, Size,
Source Page, File URL, Date Found, plus blank **Complexity**/**Price** columns) — handy for
sizing up a client's files before quoting work in the existing Complexity/rate system.

**One extra setup step:** run `migration_v8.sql` in the Supabase SQL editor (same place you ran
`schema.sql`) — it adds 4 new tables (`doc_scans`, `doc_scan_queue`, `doc_scan_visited`,
`doc_scan_files`) and doesn't touch anything existing.

No new environment variables or Supabase project needed — it reuses the same Project URL/anon
key already saved in this browser, and the crawler runs as small Vercel serverless functions
under `/api` (added to this same project, so it deploys automatically with everything else on
`git push`).

Files are **not stored anywhere** — only their name/link/size/page-count metadata is saved.
"Download all (.zip)" and "Export review sheet (.xlsx)" both download straight to your
computer.

Notes:
- Word files always show a blank Pages column (page count isn't reliably stored in the file
  format itself).
- Legacy binary Office formats (`.doc`, `.ppt`, `.xls`) list fine but only get a slide/sheet
  count on their modern `.docx/.pptx/.xlsx` equivalents.
- Files over 40MB skip the detailed page/slide/sheet lookup (still listed and downloadable) to
  keep scans fast.
- If a client's site only renders links via client-side JavaScript (common on search/filter
  widgets), the crawler won't see them directly from that page's raw HTML. **To help with
  this, every "whole site"/"whole site + subdomains" scan also checks `robots.txt` and common
  paths (`/sitemap_index.xml`, `/wp-sitemap.xml`, `/sitemap.xml`) for an XML sitemap, and
  queues everything it lists** alongside normal link-following — this is how most WordPress
  (and many other CMS) sites let you route around a JS-rendered search widget: the individual
  item pages a sitemap points to are usually still server-rendered with real download links,
  even when the search/listing widget itself isn't. If a site has no sitemap at all and hides
  everything behind client-side JS, that's the one case this doesn't solve — say the word and
  I'll add headless-browser rendering support (a bigger change, since Vercel serverless
  functions need a specific setup for that, e.g. `@sparticuz/chromium`).

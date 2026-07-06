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

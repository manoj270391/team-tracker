-- ─────────────────────────────────────────────
-- Team Tracker – Migration v8: Document Scanner
-- Run this in Supabase → SQL Editor → New query
-- (adds 4 new tables, does not touch existing ones)
-- ─────────────────────────────────────────────

create table if not exists doc_scans (
  id              uuid primary key default gen_random_uuid(),
  root_url        text not null,
  website_name    text not null,
  scope           text not null check (scope in ('single','site','subdomains')),
  file_types      text[] not null,
  max_pages       int not null default 500,
  fetch_details   boolean not null default true,
  status          text not null default 'running' check (status in ('running','done','error')),
  pages_crawled   int not null default 0,
  files_found     int not null default 0,
  error_message   text,
  created_at      timestamptz not null default now(),
  finished_at     timestamptz
);

create table if not exists doc_scan_queue (
  id       bigint generated always as identity primary key,
  scan_id  uuid not null references doc_scans(id) on delete cascade,
  url      text not null,
  depth    int not null default 0,
  status   text not null default 'pending' check (status in ('pending','done'))
);
create index if not exists doc_scan_queue_pick_idx on doc_scan_queue (scan_id, status);

create table if not exists doc_scan_visited (
  id       bigint generated always as identity primary key,
  scan_id  uuid not null references doc_scans(id) on delete cascade,
  url      text not null,
  unique (scan_id, url)
);

create table if not exists doc_scan_files (
  id               bigint generated always as identity primary key,
  scan_id          uuid not null references doc_scans(id) on delete cascade,
  file_name        text not null,
  file_type        text not null check (file_type in ('pdf','doc','ppt','xlsx')),
  source_page_url  text not null,
  file_url         text not null,
  size_bytes       bigint,
  pages            int,
  found_at         timestamptz not null default now(),
  unique (scan_id, file_url)
);

-- Same "public access, anon key does everything" model as the rest of this app.
alter table doc_scans        enable row level security;
alter table doc_scan_queue   enable row level security;
alter table doc_scan_visited enable row level security;
alter table doc_scan_files   enable row level security;

create policy "public access" on doc_scans        for all using (true) with check (true);
create policy "public access" on doc_scan_queue   for all using (true) with check (true);
create policy "public access" on doc_scan_visited for all using (true) with check (true);
create policy "public access" on doc_scan_files   for all using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on doc_scans, doc_scan_queue, doc_scan_visited, doc_scan_files to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

-- Housekeeping note: doc_scan_queue / doc_scan_visited / doc_scan_files rows are only
-- needed while a scan is running or being reviewed. It's safe to periodically delete old
-- rows from these 3 tables (by scan_id) while keeping the summary row in doc_scans for
-- history — you don't need the underlying files kept long-term.

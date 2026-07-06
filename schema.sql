-- ─────────────────────────────────────────────
-- Team Tracker – Supabase Schema
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

create table if not exists resources (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  role        text,
  type        text not null check (type in ('Employee','Freelancer')),
  cost        numeric not null default 0,
  created_at  timestamptz default now()
);

create table if not exists clients (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  simple      numeric not null default 0,
  medium      numeric not null default 0,
  complex     numeric not null default 0,
  created_at  timestamptz default now()
);

create table if not exists attendance (
  id          uuid primary key default gen_random_uuid(),
  resource_id uuid references resources(id) on delete cascade,
  year        int not null,
  month       int not null,
  day         int not null,
  status      text not null check (status in ('P','A','H','L')),
  unique(resource_id, year, month, day)
);

create table if not exists worklog (
  id             uuid primary key default gen_random_uuid(),
  date           date not null,
  resource_id    uuid references resources(id) on delete cascade,
  client_id      uuid references clients(id) on delete set null,
  complexity     text not null check (complexity in ('Simple','Medium','Complex')),
  task           text,
  pages          int default 0,
  override_rate  numeric,
  created_at     timestamptz default now()
);

-- Enable Row Level Security (keep data private)
alter table resources  enable row level security;
alter table clients    enable row level security;
alter table attendance enable row level security;
alter table worklog    enable row level security;

-- Allow all operations for now (tighten after adding auth)
create policy "public access" on resources  for all using (true) with check (true);
create policy "public access" on clients    for all using (true) with check (true);
create policy "public access" on attendance for all using (true) with check (true);
create policy "public access" on worklog    for all using (true) with check (true);

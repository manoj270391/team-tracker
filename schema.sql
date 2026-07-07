-- ─────────────────────────────────────────────
-- Team Tracker – Supabase Schema
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

create table if not exists resources (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  role            text,
  type            text not null check (type in ('Employee','Freelancer')),
  cost            numeric not null default 0,       -- Employee: daily cost (if salary_type='daily') | Freelancer: cost per page
  salary_type     text not null default 'daily' check (salary_type in ('daily','monthly')),
  monthly_salary  numeric,                            -- Employee only, used when salary_type='monthly'
  special_cost    numeric,                            -- Freelancer only, higher rate for Complex/Form files
  joining_date    date,                                -- Employee only, used for EL eligibility & CL/SL pro-ration
  created_at      timestamptz default now()
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
  status      text not null check (status in ('P','A','HF')),
  leave_type  text,
  unique(resource_id, year, month, day),
  constraint attendance_leave_type_check check (
    (status = 'P'  and leave_type is null) or
    (status = 'HF' and leave_type in ('CL','SL')) or
    (status = 'A'  and leave_type in ('CL','SL','EL','LOP'))
  )
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
  is_special_rate boolean not null default false,     -- true = freelancer's special Complex/Form rate applies
  created_at     timestamptz default now()
);

create table if not exists holidays (
  id      uuid primary key default gen_random_uuid(),
  year    int not null,
  month   int not null,
  day     int not null,
  name    text,
  unique(year, month, day)
);

create table if not exists el_settlements (
  id           uuid primary key default gen_random_uuid(),
  resource_id  uuid references resources(id) on delete cascade,
  year         int not null,        -- the completed calendar year this settlement covers
  days         numeric not null,    -- net EL days paid out (accrued − used that year)
  amount       numeric not null,    -- days × daily rate at time of settlement
  created_at   timestamptz default now(),
  unique(resource_id, year)
);

-- Enable Row Level Security (keep data private)
alter table resources     enable row level security;
alter table clients       enable row level security;
alter table attendance    enable row level security;
alter table worklog       enable row level security;
alter table holidays      enable row level security;
alter table el_settlements enable row level security;

-- Allow all operations for now (tighten after adding auth)
create policy "public access" on resources      for all using (true) with check (true);
create policy "public access" on clients        for all using (true) with check (true);
create policy "public access" on attendance     for all using (true) with check (true);
create policy "public access" on worklog        for all using (true) with check (true);
create policy "public access" on holidays       for all using (true) with check (true);
create policy "public access" on el_settlements for all using (true) with check (true);

-- Grant table-level access to the anon role (required for the app's API key to work)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated;

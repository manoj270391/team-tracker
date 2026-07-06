-- ─────────────────────────────────────────────
-- MIGRATION: Monthly salary + holidays support
-- Run this in Supabase → SQL Editor → New query
-- Safe to run even if you already have data — it only adds new columns/tables.
-- ─────────────────────────────────────────────

-- 1. Add salary fields to resources
alter table resources add column if not exists salary_type text not null default 'daily' check (salary_type in ('daily','monthly'));
alter table resources add column if not exists monthly_salary numeric;

-- 2. New holidays table (public/government holidays you add per month)
create table if not exists holidays (
  id      uuid primary key default gen_random_uuid(),
  year    int not null,
  month   int not null,
  day     int not null,
  name    text,
  unique(year, month, day)
);

alter table holidays enable row level security;

drop policy if exists "public access" on holidays;
create policy "public access" on holidays for all using (true) with check (true);

-- 3. Grant table-level access (same fix as before, extended to holidays)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated;

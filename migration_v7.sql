-- ─────────────────────────────────────────────
-- MIGRATION v7: Earned Leave annual settlement (Feb payout)
-- Run this in Supabase → SQL Editor → New query
--
-- Each year, unused EL accrued in the just-completed calendar year is
-- paid out as a bonus added to February salary, then removed from the
-- employee's running EL balance. This table is the audit trail — a row
-- only exists once you've explicitly confirmed the payout in the app.
-- ─────────────────────────────────────────────

create table if not exists el_settlements (
  id           uuid primary key default gen_random_uuid(),
  resource_id  uuid references resources(id) on delete cascade,
  year         int not null,        -- the completed calendar year this settlement covers
  days         numeric not null,    -- net EL days paid out (accrued − used that year)
  amount       numeric not null,    -- days × daily rate at time of settlement
  created_at   timestamptz default now(),
  unique(resource_id, year)         -- can't double-settle the same year
);

alter table el_settlements enable row level security;
drop policy if exists "public access" on el_settlements;
create policy "public access" on el_settlements for all using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated;

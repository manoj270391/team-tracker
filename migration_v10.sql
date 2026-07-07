-- ─────────────────────────────────────────────
-- Team Tracker – Migration v10: Payroll — Professional Tax + Income Tax
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

-- Tamil Nadu professional tax slabs (Greater Chennai Corporation figures as published).
-- IMPORTANT: verify these against the current official notification before relying on
-- them for real deductions — sources disagree slightly on the latest revised amounts,
-- and tn.gov.in itself couldn't be machine-verified. Edit values here any time from the
-- Leave Policy page in the app; the payroll calculation always reads from this table.
create table if not exists pt_slabs (
  id                  bigint generated always as identity primary key,
  min_half_yearly     numeric not null,        -- inclusive lower bound of average half-yearly income
  max_half_yearly     numeric,                 -- inclusive upper bound; null = no upper limit (top slab)
  half_yearly_amount  numeric not null,         -- PT amount for this slab, per half-year
  sort_order          int not null default 0
);

insert into pt_slabs (min_half_yearly, max_half_yearly, half_yearly_amount, sort_order) values
  (0,      21000,  0,    1),
  (21001,  30000,  100,  2),
  (30001,  45000,  235,  3),
  (45001,  60000,  510,  4),
  (60001,  75000,  760,  5),
  (75001,  null,   1095, 6)
on conflict do nothing;

-- Manual, per-employee, per-month Income Tax (TDS) entry. Only meant to be used for
-- employees whose annualized salary crosses ₹12,00,000 (the app gates the input field
-- accordingly) - this is a plain manual figure the admin fills in, not an auto-computed
-- tax engine.
create table if not exists payroll_month_overrides (
  id           bigint generated always as identity primary key,
  resource_id  uuid not null references resources(id) on delete cascade,
  year         int not null,
  month        int not null,
  income_tax   numeric not null default 0,
  unique(resource_id, year, month)
);

alter table pt_slabs enable row level security;
alter table payroll_month_overrides enable row level security;

drop policy if exists "public access" on pt_slabs;
drop policy if exists "public access" on payroll_month_overrides;
create policy "public access" on pt_slabs for all using (true) with check (true);
create policy "public access" on payroll_month_overrides for all using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on pt_slabs, payroll_month_overrides to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

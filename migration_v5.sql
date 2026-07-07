-- ─────────────────────────────────────────────
-- MIGRATION v5: Salary slips + Leave Policy tracking (CL/SL/EL)
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

-- 1. Date of joining — needed to auto-calculate EL eligibility (12 months
--    continuous service) and to pro-rate CL/SL for employees who join mid-year
alter table resources add column if not exists joining_date date;

-- 2. Leave type for each Absent day — captured at the time of marking attendance
alter table attendance add column if not exists leave_type text
  check (leave_type in ('CL','SL','EL','LOP'));

-- Grant refresh (safe to re-run)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated;

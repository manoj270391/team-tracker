-- ─────────────────────────────────────────────
-- Team Tracker – Migration v11: Employee ID + Bank A/C last 4 digits
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

alter table resources add column if not exists employee_code text;   -- e.g. EMP-001
alter table resources add column if not exists bank_last4 text;      -- last 4 digits of bank A/C only, e.g. 1234

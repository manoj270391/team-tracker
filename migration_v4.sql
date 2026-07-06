-- ─────────────────────────────────────────────
-- MIGRATION v4: Freelancer special rate (Complex/Form files)
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

-- Freelancers can now have a second, higher rate for Complex/Form files
alter table resources add column if not exists special_cost numeric;

-- Each work log entry can flag whether the special rate applies
alter table worklog add column if not exists is_special_rate boolean not null default false;

-- ─────────────────────────────────────────────
-- Team Tracker – Migration v12: Manual Pay Date on salary slips
-- Run this in Supabase → SQL Editor → New query
-- ─────────────────────────────────────────────

alter table payroll_month_overrides add column if not exists pay_date date;

-- ─────────────────────────────────────────────
-- MIGRATION v3: Fix attendance status constraint
-- Run this in Supabase → SQL Editor → New query
-- Needed because attendance now stores P / A / HF only
-- (Holiday days are derived automatically from Sundays + the
--  holidays table, and are never written to the attendance table)
-- ─────────────────────────────────────────────

alter table attendance drop constraint if exists attendance_status_check;

alter table attendance
  add constraint attendance_status_check check (status in ('P','A','HF'));

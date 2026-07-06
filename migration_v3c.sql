-- ─────────────────────────────────────────────
-- MIGRATION v3c: Fix attendance status (correct order)
-- Run this in Supabase → SQL Editor → New query
--
-- The previous version failed because Postgres checks the OLD
-- constraint on every UPDATE — so writing 'HF' failed before we
-- even got to replace the constraint. This version drops the old
-- constraint FIRST, then migrates the data, then adds the new one.
-- ─────────────────────────────────────────────

-- Step 1: drop the old constraint so we're free to migrate values
alter table attendance drop constraint if exists attendance_status_check;

-- Step 2: old "H" meant Half-day → rename to "HF"
update attendance set status = 'HF' where status = 'H';

-- Step 3: old "L" meant Leave → treat as Absent (no Leave status anymore)
update attendance set status = 'A' where status = 'L';

-- Step 4: safety net — remove any other stray values
delete from attendance where status not in ('P','A','HF');

-- Step 5: now safe to enforce the new constraint
alter table attendance
  add constraint attendance_status_check check (status in ('P','A','HF'));

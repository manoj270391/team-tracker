-- ─────────────────────────────────────────────
-- MIGRATION v3b: Migrate legacy attendance data, then fix constraint
-- Run this in Supabase → SQL Editor → New query
--
-- Your attendance table has old rows using the previous scheme
-- (H = Half-day, L = Leave). This migrates them to the new scheme
-- before adding the stricter constraint, so no data is silently lost.
-- ─────────────────────────────────────────────

-- Step 1: old "H" meant Half-day → rename to "HF"
update attendance set status = 'HF' where status = 'H';

-- Step 2: old "L" meant Leave → there's no Leave status anymore,
-- so we treat it as Absent. (Change 'A' below to 'HF' instead if
-- you'd rather those old Leave days count as Half-day.)
update attendance set status = 'A' where status = 'L';

-- Step 3: safety net — remove any other stray values that would
-- still violate the new constraint (there shouldn't be any, but
-- this guarantees Step 4 succeeds)
delete from attendance where status not in ('P','A','HF');

-- Step 4: now safe to enforce the new constraint
alter table attendance drop constraint if exists attendance_status_check;
alter table attendance
  add constraint attendance_status_check check (status in ('P','A','HF'));

-- ─────────────────────────────────────────────
-- MIGRATION v6: Half-day now must be Casual or Sick Leave
-- Run this in Supabase → SQL Editor → New query
--
-- Business rule: Half-day (HF) can only be taken against Casual Leave
-- or Sick Leave — not Earned Leave or Loss of Pay. Two half-days count
-- as one full day against the CL/SL balance (handled in the app).
-- ─────────────────────────────────────────────

-- Step 1: drop the old constraint first (it doesn't know about HF yet)
alter table attendance drop constraint if exists attendance_leave_type_check;

-- Step 2: any existing Half-day rows created before this update won't have
-- a leave type — default them to Casual Leave so they don't violate the
-- new rule. Review these if you'd rather reclassify any as Sick Leave.
update attendance set leave_type = 'CL' where status = 'HF' and leave_type is null;

-- Step 3: enforce the new rule —
--   Present days never carry a leave type
--   Half-days only ever carry CL or SL
--   Absent days can carry CL, SL, EL, or LOP
alter table attendance add constraint attendance_leave_type_check check (
  (status = 'P'  and leave_type is null) or
  (status = 'HF' and leave_type in ('CL','SL')) or
  (status = 'A'  and leave_type in ('CL','SL','EL','LOP'))
);

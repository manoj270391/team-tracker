-- ─────────────────────────────────────────────
-- June–December 2026 Holidays
-- Run this in Supabase → SQL Editor → New query
-- Safe to run more than once (holidays has a unique(year,month,day) constraint,
-- so re-running this just skips any dates already present rather than erroring).
--
-- Covers: National holidays, Tamil Nadu state holidays, and the specific festival
-- dates you picked (Krishna Jayanthi, Vinayakar Chathurthi, Deepavali x2, Ayudha
-- Puja x2). All of these can be renamed or removed any time from the Holidays page
-- in the app - just click the day to edit.
-- ─────────────────────────────────────────────

insert into holidays (year, month, day, name) values
  (2026, 8,  15, 'Independence Day'),
  (2026, 9,  4,  'Krishna Jayanthi (Janmashtami)'),
  (2026, 9,  14, 'Vinayakar Chathurthi (Ganesh Chaturthi)'),
  (2026, 10, 2,  'Gandhi Jayanthi'),
  (2026, 10, 19, 'Ayudha Puja'),
  (2026, 10, 20, 'Vijaya Dashami'),
  (2026, 11, 8,  'Deepavali'),
  (2026, 11, 9,  'Deepavali'),
  (2026, 12, 25, 'Christmas')
on conflict (year, month, day) do nothing;

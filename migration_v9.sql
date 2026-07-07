-- ─────────────────────────────────────────────
-- Team Tracker – Migration v9: Document Scanner "section" scope
-- Run this in Supabase → SQL Editor → New query
-- Adds a 4th scan scope: stay within a specific URL path/section instead of
-- crawling the whole domain. Safe to run even if already applied.
-- ─────────────────────────────────────────────

alter table doc_scans drop constraint if exists doc_scans_scope_check;
alter table doc_scans add constraint doc_scans_scope_check
  check (scope in ('single','site','subdomains','section'));

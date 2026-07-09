-- ─────────────────────────────────────────────
-- Team Tracker – Migration v13: Correct Professional Tax slab amounts
-- Run this in Supabase → SQL Editor → New query
-- Updates the half-yearly PT amounts to the figures you confirmed. Safe to
-- run any time - matches existing rows by their slab boundaries and just
-- corrects the amount, doesn't touch anything else.
-- ─────────────────────────────────────────────

update pt_slabs set half_yearly_amount = 0    where min_half_yearly = 0     and max_half_yearly = 21000;
update pt_slabs set half_yearly_amount = 180  where min_half_yearly = 21001 and max_half_yearly = 30000;
update pt_slabs set half_yearly_amount = 425  where min_half_yearly = 30001 and max_half_yearly = 45000;
update pt_slabs set half_yearly_amount = 930  where min_half_yearly = 45001 and max_half_yearly = 60000;
update pt_slabs set half_yearly_amount = 1025 where min_half_yearly = 60001 and max_half_yearly = 75000;
update pt_slabs set half_yearly_amount = 1250 where min_half_yearly = 75001 and max_half_yearly is null;

-- If migration_v10.sql was never run yet on this project, the rows above won't exist to
-- update - this inserts the correct slabs fresh in that case instead.
insert into pt_slabs (min_half_yearly, max_half_yearly, half_yearly_amount, sort_order)
select * from (values
  (0,      21000,  0,    1),
  (21001,  30000,  180,  2),
  (30001,  45000,  425,  3),
  (45001,  60000,  930,  4),
  (60001,  75000,  1025, 5),
  (75001,  null,   1250, 6)
) as v(min_half_yearly, max_half_yearly, half_yearly_amount, sort_order)
where not exists (select 1 from pt_slabs);

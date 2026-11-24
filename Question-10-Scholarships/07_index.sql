-- =====================================================================
-- Question 10 (f) Index for applications searched by status within a
-- submitted_on date range.
--
-- Justification:
--   status is matched by EQUALITY and submitted_on by a RANGE, so the
--   composite B-tree index (status, submitted_on) puts status first.
--   All applications with one status are stored together in date order,
--   so a search such as "PENDING applications submitted this month"
--   seeks to (status, start date) and reads one contiguous slice. status
--   alone has only three values and would be a poor index on its own;
--   combined with the date it becomes selective. The same index also
--   serves the scheduled job's "WHERE status = 'PENDING'" loop.
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE INDEX idx_applications_status_submitted ON applications (status, submitted_on);
ANALYZE applications;

-- Matching query and plan on the seed data
EXPLAIN
SELECT application_id, student_id, submitted_on
FROM applications
WHERE status = 'PENDING'
  AND submitted_on BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE;

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT application_id, student_id, submitted_on
FROM applications
WHERE status = 'PENDING'
  AND submitted_on BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE;
ROLLBACK;

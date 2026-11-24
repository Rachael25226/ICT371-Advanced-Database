-- =====================================================================
-- Question 2 (f) Composite index for payments filtered by student_id and
-- a paid_on date range.
--
-- Justification:
--   student_id is tested for EQUALITY and paid_on for a RANGE, so the
--   equality column goes first: (student_id, paid_on). Within one
--   student the entries are sorted by date, so PostgreSQL seeks to the
--   first matching date and reads a single contiguous slice of the index.
--   The same index also serves fn_fee_balance and pr_receive_payment
--   (WHERE student_id = ?) and indexes the student_id foreign key.
-- =====================================================================
SET search_path TO q02_university_fees;

CREATE INDEX idx_payments_student_paid_on ON payments (student_id, paid_on);
ANALYZE payments;

-- Matching query and plan on the seed data (few rows: a sequential scan
-- may legitimately be cheaper).
EXPLAIN
SELECT payment_id, amount, paid_on
FROM payments
WHERE student_id = 1
  AND paid_on BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE;

-- Same query with sequential scans disabled for this transaction only,
-- showing the index matches both conditions (Index Cond).
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT payment_id, amount, paid_on
FROM payments
WHERE student_id = 1
  AND paid_on BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE;
ROLLBACK;

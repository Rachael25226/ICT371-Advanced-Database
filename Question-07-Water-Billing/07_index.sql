-- =====================================================================
-- Question 7 (f) Index supporting date-based searches for overdue bills.
--
-- Justification:
--   An overdue search is "due_on before a date AND not fully paid".
--   A PARTIAL B-tree index on bills(due_on) WHERE amount_paid < charge
--   holds only UNPAID bills, ordered by due date. Paid bills - the large
--   majority over time - are left out, so the index stays small and a
--   range scan on due_on returns only candidate overdue bills. The query
--   repeats "amount_paid < charge" so the planner can use the index.
-- =====================================================================
SET search_path TO q07_water_billing;

CREATE INDEX idx_bills_unpaid_due_on ON bills (due_on) WHERE amount_paid < charge;
ANALYZE bills;

-- Matching unpaid-bill query and plan on the seed data
EXPLAIN
SELECT bill_id, reading_id, charge - amount_paid AS outstanding, due_on
FROM bills
WHERE due_on < CURRENT_DATE
  AND amount_paid < charge;

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT bill_id, reading_id, charge - amount_paid AS outstanding, due_on
FROM bills
WHERE due_on < CURRENT_DATE
  AND amount_paid < charge;
ROLLBACK;

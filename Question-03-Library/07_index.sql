-- =====================================================================
-- Question 3 (f) Index supporting a search for a given book's
-- UNRETURNED loans.
--
-- Justification:
--   A PARTIAL index on loans(book_id) WHERE returned_on IS NULL stores
--   only the open loans. Over time most loans are returned, so this index
--   stays small (it shrinks as books come back) and every entry it holds
--   is a match for "unreturned" - PostgreSQL seeks straight to the
--   book_id and reads only open loans, never visiting returned rows.
--   The query must repeat the predicate "returned_on IS NULL" so the
--   planner can prove the partial index applies.
-- =====================================================================
SET search_path TO q03_library;

CREATE INDEX idx_loans_open_by_book ON loans (book_id) WHERE returned_on IS NULL;
ANALYZE loans;

-- Matching query and plan on the seed data
EXPLAIN
SELECT loan_id, borrower_name, borrowed_on, due_on
FROM loans
WHERE book_id = 1
  AND returned_on IS NULL;

-- Same query with sequential scans disabled for this transaction only:
-- the partial index is chosen for this predicate.
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT loan_id, borrower_name, borrowed_on, due_on
FROM loans
WHERE book_id = 1
  AND returned_on IS NULL;
ROLLBACK;

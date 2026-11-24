-- =====================================================================
-- Question 1 (f) Index for finding one medicine's sales within a
-- sold_on date range.
--
-- Justification:
--   The query filters with EQUALITY on medicine_id and a RANGE on
--   sold_on. A composite B-tree index with the equality column first,
--   (medicine_id, sold_on), stores each medicine's sales together and in
--   date order. PostgreSQL can therefore seek straight to
--   (medicine_id = X, sold_on >= start) and read forward only until
--   sold_on > end, instead of scanning every sale. The opposite column
--   order (sold_on, medicine_id) would have to read the rows of every
--   medicine in the date range. The index also supports the medicine_id
--   foreign key, which PostgreSQL does not index automatically.
-- =====================================================================
SET search_path TO q01_pharmacy;

CREATE INDEX idx_sales_medicine_sold_on ON sales (medicine_id, sold_on);
ANALYZE sales;

-- Matching query and its plan on the seed data. With only a few rows
-- the planner may correctly choose a sequential scan, because reading
-- one small page is cheaper than using any index.
EXPLAIN
SELECT sale_id, quantity, unit_price, sold_on
FROM sales
WHERE medicine_id = 1
  AND sold_on BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE;

-- The same query with sequential scans disabled for this transaction
-- only. This shows the index matches the predicate (both columns appear
-- in the Index Cond) - the plan used once the table is realistically
-- large.
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT sale_id, quantity, unit_price, sold_on
FROM sales
WHERE medicine_id = 1
  AND sold_on BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE;
ROLLBACK;

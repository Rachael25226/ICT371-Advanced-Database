-- =====================================================================
-- Question 9 (f) Composite index for a farmer's deliveries between two
-- dates.
--
-- Justification:
--   farmer_id is matched by EQUALITY and delivered_on by a RANGE, so the
--   composite B-tree index (farmer_id, delivered_on) puts the equality
--   column first. One farmer's deliveries are stored together in date
--   order, so PostgreSQL seeks to (farmer, first date) and reads only up
--   to the last date, instead of scanning every farmer's deliveries.
--   It also indexes the farmer_id foreign key used by v_farmer_amount_due.
-- =====================================================================
SET search_path TO q09_maize;

CREATE INDEX idx_deliveries_farmer_delivered_on ON deliveries (farmer_id, delivered_on);
ANALYZE deliveries;

-- Matching query and plan on the seed data
EXPLAIN
SELECT delivery_id, grade, weight_kg, total_value, delivered_on
FROM deliveries
WHERE farmer_id = 1
  AND delivered_on BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE;

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT delivery_id, grade, weight_kg, total_value, delivered_on
FROM deliveries
WHERE farmer_id = 1
  AND delivered_on BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE;
ROLLBACK;

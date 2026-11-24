-- =====================================================================
-- Question 8 (f) Index supporting one vehicle's trips within a trip_on
-- date range.
--
-- Justification:
--   The query has EQUALITY on vehicle_id and a RANGE on trip_on, so the
--   composite B-tree index (vehicle_id, trip_on) puts the equality column
--   first. Each vehicle's trips are stored together in date order;
--   PostgreSQL seeks to (vehicle_id, start date) and reads forward to the
--   end date - a small contiguous slice - instead of scanning the trip
--   history of the whole fleet. It also indexes the vehicle_id foreign key.
-- =====================================================================
SET search_path TO q08_transport;

CREATE INDEX idx_trips_vehicle_trip_on ON trips (vehicle_id, trip_on);
ANALYZE trips;

-- Matching query and plan on the seed data
EXPLAIN
SELECT trip_id, trip_on, start_odometer, end_odometer
FROM trips
WHERE vehicle_id = 2
  AND trip_on BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE;

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT trip_id, trip_on, start_odometer, end_odometer
FROM trips
WHERE vehicle_id = 2
  AND trip_on BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE;
ROLLBACK;

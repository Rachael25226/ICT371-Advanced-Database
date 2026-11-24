-- =====================================================================
-- Question 5 (f) Index supporting ACTIVE allocations filtered by room_id.
--
-- Justification:
--   fn_free_beds, the capacity trigger and v_room_occupancy all ask
--   "how many ACTIVE allocations does room X have?". A PARTIAL index on
--   allocations(room_id) WHERE status = 'ACTIVE' contains only current
--   occupants - at most the total number of beds - while ENDED history
--   rows keep growing every semester and are never stored in it. The
--   index therefore stays small and every entry it returns is relevant.
--   The query repeats "status = 'ACTIVE'" so the planner can use it.
-- =====================================================================
SET search_path TO q05_hostel;

CREATE INDEX idx_allocations_active_room ON allocations (room_id) WHERE status = 'ACTIVE';
ANALYZE allocations;

-- Matching query and plan on the seed data
EXPLAIN
SELECT allocation_id, student_id, allocated_on
FROM allocations
WHERE room_id = 1
  AND status = 'ACTIVE';

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT allocation_id, student_id, allocated_on
FROM allocations
WHERE room_id = 1
  AND status = 'ACTIVE';
ROLLBACK;

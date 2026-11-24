-- =====================================================================
-- Question 4 (f) Non-unique index for appointments searched by
-- appointment_day and doctor_id.
--
-- Justification:
--   Day-sheet queries, fn_daily_load and the clash trigger all look up
--   appointments by a specific date AND doctor. A composite B-tree index
--   on (appointment_day, doctor_id) lets PostgreSQL go directly to that
--   date and doctor instead of scanning every appointment ever made. The
--   date comes first because it is the most common filter on its own
--   (e.g. "all of today's appointments", the daily summary job), so the
--   same index also serves day-only searches.
--   It must be NON-unique: a doctor has up to four appointments per day,
--   and cancelled appointments may share a slot with a new booking.
-- =====================================================================
SET search_path TO q04_clinic;

CREATE INDEX idx_appointments_day_doctor ON appointments (appointment_day, doctor_id);
ANALYZE appointments;

-- Matching query and plan on the seed data
EXPLAIN
SELECT appointment_id, slot_time, status
FROM appointments
WHERE appointment_day = CURRENT_DATE
  AND doctor_id = 1;

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT appointment_id, slot_time, status
FROM appointments
WHERE appointment_day = CURRENT_DATE
  AND doctor_id = 1;
ROLLBACK;

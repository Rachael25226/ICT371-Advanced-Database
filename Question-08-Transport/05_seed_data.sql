-- =====================================================================
-- Question 8 (a) Seed data: three vehicles at different service
-- positions and six trips, added through pr_record_trip AFTER the
-- trigger is installed (so the trigger moves each odometer forward).
--   vehicle 1 ABC 1234: 2,000 km since service -> 2,600 after trips (not due)
--   vehicle 2 BCD 2345: 4,800 km since service -> 5,250 after trips (crosses 5,000)
--   vehicle 3 CDE 3456: 6,000 km since service -> 6,900 after trips (already due)
-- Each trip starts where the previous one ended.
-- =====================================================================
SET search_path TO q08_transport;

INSERT INTO vehicles (registration, current_odometer, last_service_odometer) VALUES
    ('ABC 1234', 12000, 10000),   -- 1
    ('BCD 2345', 54800, 50000),   -- 2
    ('CDE 3456', 86000, 80000);   -- 3

CALL pr_record_trip(1, CURRENT_DATE - 6, 12000, 12350);
CALL pr_record_trip(2, CURRENT_DATE - 5, 54800, 55100);
CALL pr_record_trip(3, CURRENT_DATE - 4, 86000, 86420);
CALL pr_record_trip(1, CURRENT_DATE - 3, 12350, 12600);
CALL pr_record_trip(2, CURRENT_DATE - 2, 55100, 55250);
CALL pr_record_trip(3, CURRENT_DATE - 1, 86420, 86900);

SELECT vehicle_id, registration, current_odometer, last_service_odometer,
       current_odometer - last_service_odometer AS km_since_service,
       fn_service_due(vehicle_id) AS service_due
FROM vehicles ORDER BY vehicle_id;

SELECT * FROM trips ORDER BY trip_id;

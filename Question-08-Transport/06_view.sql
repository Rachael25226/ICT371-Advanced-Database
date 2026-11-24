-- =====================================================================
-- Question 8 (e) View v_service_due
-- Registration and kilometres since service for vehicles that currently
-- meet the 5,000 km service threshold.
-- =====================================================================
SET search_path TO q08_transport;

CREATE OR REPLACE VIEW v_service_due AS
SELECT vehicle_id,
       registration,
       current_odometer - last_service_odometer AS km_since_service
FROM vehicles
WHERE current_odometer - last_service_odometer >= 5000;

SELECT * FROM v_service_due ORDER BY registration;

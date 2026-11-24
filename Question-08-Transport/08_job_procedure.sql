-- =====================================================================
-- Question 8 (g) Procedure pr_refresh_service_alerts()
--   1. INSERT ... ON CONFLICT (vehicle_id) DO UPDATE: one alert per due
--      vehicle - inserted the first time, kilometres updated afterwards
--      (flagged_on keeps the date the vehicle was FIRST flagged);
--   2. DELETE the alert of any vehicle that is no longer due, e.g. after
--      a service resets last_service_odometer.
-- Because vehicle_id is the primary key of service_alerts, reruns can
-- never create duplicate alerts.
-- =====================================================================
SET search_path TO q08_transport;

CREATE OR REPLACE PROCEDURE pr_refresh_service_alerts()
LANGUAGE plpgsql
SET search_path = q08_transport, pg_temp
AS $$
BEGIN
    INSERT INTO service_alerts (vehicle_id, km_since_service, flagged_on)
    SELECT vehicle_id,
           current_odometer - last_service_odometer,
           CURRENT_DATE
    FROM vehicles
    WHERE current_odometer - last_service_odometer >= 5000
    ON CONFLICT (vehicle_id) DO UPDATE
        SET km_since_service = EXCLUDED.km_since_service;

    DELETE FROM service_alerts sa
    USING vehicles v
    WHERE v.vehicle_id = sa.vehicle_id
      AND v.current_odometer - v.last_service_odometer < 5000;
END;
$$;

CALL pr_refresh_service_alerts();
SELECT * FROM service_alerts ORDER BY vehicle_id;

-- rerun: same alerts, no duplicates
CALL pr_refresh_service_alerts();
SELECT * FROM service_alerts ORDER BY vehicle_id;

-- =====================================================================
-- Question 8 (c) Procedure pr_record_trip(p_vehicle_id, p_trip_on, p_start, p_end)
--   * validates the vehicle and the inputs;
--   * requires end_odometer greater than start_odometer;
--   * inserts the trip.
-- It deliberately does NOT update vehicles.current_odometer: the BEFORE
-- INSERT trigger (d) checks the starting odometer and moves the vehicle
-- odometer forward exactly once, for procedure calls and direct SQL alike.
-- =====================================================================
SET search_path TO q08_transport;

CREATE OR REPLACE PROCEDURE pr_record_trip(p_vehicle_id integer,
                                           p_trip_on    date,
                                           p_start      integer,
                                           p_end        integer)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vehicles WHERE vehicle_id = p_vehicle_id) THEN
        RAISE EXCEPTION 'Unknown vehicle_id %', p_vehicle_id;
    END IF;

    IF p_trip_on IS NULL THEN
        RAISE EXCEPTION 'Trip date (p_trip_on) is required';
    END IF;

    IF p_start IS NULL OR p_end IS NULL OR p_start < 0 THEN
        RAISE EXCEPTION 'Start and end odometer values are required and cannot be negative';
    END IF;

    IF p_end <= p_start THEN
        RAISE EXCEPTION 'End odometer % must be greater than start odometer %', p_end, p_start;
    END IF;

    INSERT INTO trips (vehicle_id, trip_on, start_odometer, end_odometer)
    VALUES (p_vehicle_id, p_trip_on, p_start, p_end);
END;
$$;

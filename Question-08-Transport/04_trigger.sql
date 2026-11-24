-- =====================================================================
-- Question 8 (d) BEFORE INSERT row trigger on trips.
--   1. locks the vehicle row (FOR UPDATE) so concurrent trips for the
--      same vehicle are applied one after another;
--   2. verifies start_odometer equals the vehicle's current_odometer;
--   3. rejects invalid mileage (missing, negative, or end <= start);
--   4. updates current_odometer to the trip's end - exactly once per trip.
-- If the trip insert fails afterwards, the odometer update is rolled
-- back with it because both happen in the same statement.
-- =====================================================================
SET search_path TO q08_transport;

CREATE OR REPLACE FUNCTION fn_trg_trips_odometer()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_current vehicles.current_odometer%TYPE;
BEGIN
    SELECT current_odometer INTO v_current
    FROM vehicles
    WHERE vehicle_id = NEW.vehicle_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown vehicle_id %', NEW.vehicle_id;
    END IF;

    IF NEW.start_odometer IS NULL OR NEW.end_odometer IS NULL
       OR NEW.start_odometer < 0 OR NEW.end_odometer <= NEW.start_odometer THEN
        RAISE EXCEPTION 'Invalid mileage: start %, end % (end must be greater than start)',
              NEW.start_odometer, NEW.end_odometer;
    END IF;

    IF NEW.start_odometer <> v_current THEN
        RAISE EXCEPTION 'Trip must start at the vehicle''s current odometer %, not %',
              v_current, NEW.start_odometer;
    END IF;

    UPDATE vehicles
       SET current_odometer = NEW.end_odometer
     WHERE vehicle_id = NEW.vehicle_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_trips_odometer
BEFORE INSERT ON trips
FOR EACH ROW
EXECUTE FUNCTION fn_trg_trips_odometer();

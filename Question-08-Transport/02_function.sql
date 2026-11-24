-- =====================================================================
-- Question 8 (b) Function fn_service_due(p_vehicle_id)
-- Returns TRUE when the vehicle has travelled at least 5,000 km since its
-- last service (current_odometer - last_service_odometer >= 5000),
-- otherwise FALSE. An unknown vehicle is rejected.
-- =====================================================================
SET search_path TO q08_transport;

CREATE OR REPLACE FUNCTION fn_service_due(p_vehicle_id integer)
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_km integer;
BEGIN
    SELECT current_odometer - last_service_odometer INTO v_km
    FROM vehicles
    WHERE vehicle_id = p_vehicle_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown vehicle_id %', p_vehicle_id;
    END IF;

    RETURN v_km >= 5000;
END;
$$;

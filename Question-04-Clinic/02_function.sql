-- =====================================================================
-- Question 4 (b) Function fn_daily_load(p_doctor_id, p_day)
-- Returns the number of the doctor's NON-cancelled appointments on that
-- day. COUNT(*) returns 0 when the day has no bookings. An unknown
-- doctor is rejected.
-- =====================================================================
SET search_path TO q04_clinic;

CREATE OR REPLACE FUNCTION fn_daily_load(p_doctor_id integer, p_day date)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_count integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM doctors WHERE doctor_id = p_doctor_id) THEN
        RAISE EXCEPTION 'Unknown doctor_id %', p_doctor_id;
    END IF;

    IF p_day IS NULL THEN
        RAISE EXCEPTION 'p_day is required';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_day = p_day
      AND status <> 'CANCELLED';

    RETURN v_count;
END;
$$;

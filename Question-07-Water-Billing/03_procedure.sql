-- =====================================================================
-- Question 7 (c) Procedure pr_generate_bill(p_reading_id, p_due_on)
--   * rejects an unknown reading and a reading that already has a bill;
--   * derives consumption = current_reading - previous_reading;
--   * calls fn_water_charge for the charge;
--   * inserts the bill with amount_paid = 0.
-- The reading row is locked (FOR UPDATE) so two sessions cannot bill the
-- same reading at once; the UNIQUE(reading_id) key is a final safeguard.
-- =====================================================================
SET search_path TO q07_water_billing;

CREATE OR REPLACE PROCEDURE pr_generate_bill(p_reading_id integer, p_due_on date)
LANGUAGE plpgsql
AS $$
DECLARE
    v_units   numeric;
    v_charge  numeric;
BEGIN
    IF p_due_on IS NULL THEN
        RAISE EXCEPTION 'Due date (p_due_on) is required';
    END IF;

    SELECT current_reading - previous_reading INTO v_units
    FROM readings
    WHERE reading_id = p_reading_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown reading_id %', p_reading_id;
    END IF;

    IF EXISTS (SELECT 1 FROM bills WHERE reading_id = p_reading_id) THEN
        RAISE EXCEPTION 'Reading % already has a bill', p_reading_id;
    END IF;

    v_charge := fn_water_charge(v_units);

    INSERT INTO bills (reading_id, charge, amount_paid, due_on)
    VALUES (p_reading_id, v_charge, 0, p_due_on);
END;
$$;

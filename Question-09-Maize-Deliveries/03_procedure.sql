-- =====================================================================
-- Question 9 (c) Procedure pr_receive_delivery(p_farmer_id, p_grade, p_weight, p_date)
--   * rejects an unknown farmer;
--   * rejects invalid inputs: missing/unsupported grade (checked with
--     fn_maize_rate), missing or non-positive weight, missing date;
--   * inserts ONLY the basic delivery fields with is_paid = false.
-- unit_rate and total_value are intentionally not supplied here - the
-- BEFORE INSERT trigger (d) calculates them.
-- =====================================================================
SET search_path TO q09_maize;

CREATE OR REPLACE PROCEDURE pr_receive_delivery(p_farmer_id integer,
                                                p_grade     text,
                                                p_weight    numeric,
                                                p_date      date)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM farmers WHERE farmer_id = p_farmer_id) THEN
        RAISE EXCEPTION 'Unknown farmer_id %', p_farmer_id;
    END IF;

    PERFORM fn_maize_rate(p_grade);          -- raises for NULL / unsupported grade

    IF p_weight IS NULL OR p_weight <= 0 THEN
        RAISE EXCEPTION 'Invalid weight %: weight must be greater than zero', p_weight;
    END IF;

    IF p_date IS NULL THEN
        RAISE EXCEPTION 'Delivery date (p_date) is required';
    END IF;

    INSERT INTO deliveries (farmer_id, grade, weight_kg, delivered_on, is_paid)
    VALUES (p_farmer_id, upper(trim(p_grade)), p_weight, p_date, false);
END;
$$;

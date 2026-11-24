-- =====================================================================
-- Question 1 (b) Function fn_sale_value(p_medicine_id, p_quantity)
-- Returns the current unit price multiplied by a positive quantity.
-- Rejects an unknown medicine or an invalid (NULL, zero or negative)
-- quantity.
-- =====================================================================
SET search_path TO q01_pharmacy;

CREATE OR REPLACE FUNCTION fn_sale_value(p_medicine_id integer, p_quantity integer)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_price medicines.unit_price%TYPE;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity %: quantity must be a positive whole number', p_quantity;
    END IF;

    SELECT unit_price INTO v_price
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown medicine_id %', p_medicine_id;
    END IF;

    RETURN v_price * p_quantity;
END;
$$;

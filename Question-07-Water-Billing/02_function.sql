-- =====================================================================
-- Question 7 (b) Function fn_water_charge(p_units)
-- Hypothetical two-band tariff:
--   first 10 units  -> K5 per unit
--   units above 10  -> K8 per unit
--   zero units      -> K0
-- Rejects NULL or negative consumption. Returns an exact two-decimal
-- value (numeric, rounded to 2 places - never floating point).
-- =====================================================================
SET search_path TO q07_water_billing;

CREATE OR REPLACE FUNCTION fn_water_charge(p_units numeric)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_units IS NULL OR p_units < 0 THEN
        RAISE EXCEPTION 'Invalid consumption %: units must be zero or more', p_units;
    END IF;

    RETURN round(LEAST(p_units, 10) * 5.00
               + GREATEST(p_units - 10, 0) * 8.00, 2);
END;
$$;

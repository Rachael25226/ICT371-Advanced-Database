-- =====================================================================
-- Question 9 (g) Procedure pr_refresh_purchases(p_day)
-- Stores that date's purchased weight and value in daily_purchases.
-- Totals are recalculated from deliveries on every run and written with
-- INSERT ... ON CONFLICT DO UPDATE, so repeated execution REPLACES the
-- totals rather than adding them again. A day with no deliveries is
-- stored as zeros.
-- =====================================================================
SET search_path TO q09_maize;

CREATE OR REPLACE PROCEDURE pr_refresh_purchases(p_day date)
LANGUAGE plpgsql
SET search_path = q09_maize, pg_temp
AS $$
BEGIN
    IF p_day IS NULL THEN
        RAISE EXCEPTION 'p_day is required';
    END IF;

    INSERT INTO daily_purchases (purchase_date, total_weight, total_value)
    SELECT p_day,
           COALESCE(SUM(weight_kg), 0),
           COALESCE(SUM(total_value), 0)
    FROM deliveries
    WHERE delivered_on = p_day
    ON CONFLICT (purchase_date) DO UPDATE
        SET total_weight = EXCLUDED.total_weight,
            total_value  = EXCLUDED.total_value;
END;
$$;

CALL pr_refresh_purchases(CURRENT_DATE - 1);
SELECT * FROM daily_purchases ORDER BY purchase_date;

-- rerun replaces, does not add
CALL pr_refresh_purchases(CURRENT_DATE - 1);
SELECT * FROM daily_purchases ORDER BY purchase_date;

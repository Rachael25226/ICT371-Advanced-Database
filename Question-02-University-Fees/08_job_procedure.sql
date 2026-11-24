-- =====================================================================
-- Question 2 (g) Procedure pr_refresh_collections(p_day)
-- Stores the payment count and total amount for that date in
-- daily_collections. Totals are recalculated from payments each time and
-- written with INSERT ... ON CONFLICT DO UPDATE, so a rerun REPLACES the
-- existing summary row. A date with no payments is stored as 0 / 0.00.
-- SET search_path lets pg_cron run it from any session.
-- =====================================================================
SET search_path TO q02_university_fees;

CREATE OR REPLACE PROCEDURE pr_refresh_collections(p_day date)
LANGUAGE plpgsql
SET search_path = q02_university_fees, pg_temp
AS $$
BEGIN
    IF p_day IS NULL THEN
        RAISE EXCEPTION 'p_day is required';
    END IF;

    INSERT INTO daily_collections (collection_date, payment_count, total_amount)
    SELECT p_day, COUNT(*), COALESCE(SUM(amount), 0)
    FROM payments
    WHERE paid_on = p_day
    ON CONFLICT (collection_date) DO UPDATE
        SET payment_count = EXCLUDED.payment_count,
            total_amount  = EXCLUDED.total_amount;
END;
$$;

CALL pr_refresh_collections(CURRENT_DATE - 1);
SELECT * FROM daily_collections ORDER BY collection_date;

-- rerun: the row is replaced, not duplicated or doubled
CALL pr_refresh_collections(CURRENT_DATE - 1);
SELECT * FROM daily_collections ORDER BY collection_date;

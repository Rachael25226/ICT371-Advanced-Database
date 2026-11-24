-- =====================================================================
-- Question 1 (g) Procedure pr_refresh_sales(p_day)
-- Replaces (never adds to) that day's total quantity and revenue in
-- daily_sales. The totals are recalculated from sales on every run and
-- written with INSERT ... ON CONFLICT DO UPDATE, so a rerun overwrites
-- the same row: no duplicate row and no double counting. A day with no
-- sales is stored as zeros.
-- SET search_path lets the procedure run from pg_cron, whose session
-- does not have the q01_pharmacy schema on its search path.
-- =====================================================================
SET search_path TO q01_pharmacy;

CREATE OR REPLACE PROCEDURE pr_refresh_sales(p_day date)
LANGUAGE plpgsql
SET search_path = q01_pharmacy, pg_temp
AS $$
BEGIN
    IF p_day IS NULL THEN
        RAISE EXCEPTION 'p_day is required';
    END IF;

    INSERT INTO daily_sales (sales_date, total_qty, total_amount)
    SELECT p_day,
           COALESCE(SUM(quantity), 0),
           COALESCE(SUM(quantity * unit_price), 0)
    FROM sales
    WHERE sold_on = p_day
    ON CONFLICT (sales_date) DO UPDATE
        SET total_qty    = EXCLUDED.total_qty,
            total_amount = EXCLUDED.total_amount;
END;
$$;

-- Run for yesterday, then rerun: the same row is replaced, not doubled.
CALL pr_refresh_sales(CURRENT_DATE - 1);
SELECT * FROM daily_sales ORDER BY sales_date;

CALL pr_refresh_sales(CURRENT_DATE - 1);
SELECT * FROM daily_sales ORDER BY sales_date;

-- =====================================================================
-- Question 7 (g) Procedure pr_refresh_receivables()
-- Stores today's total unpaid bill balance (sum of charge - amount_paid
-- over every bill not fully paid) in receivable_snapshot for
-- CURRENT_DATE. ON CONFLICT DO UPDATE replaces the same date's total on
-- a rerun.
-- =====================================================================
SET search_path TO q07_water_billing;

CREATE OR REPLACE PROCEDURE pr_refresh_receivables()
LANGUAGE plpgsql
SET search_path = q07_water_billing, pg_temp
AS $$
BEGIN
    INSERT INTO receivable_snapshot (snapshot_date, total_due)
    SELECT CURRENT_DATE, COALESCE(SUM(charge - amount_paid), 0)
    FROM bills
    WHERE amount_paid < charge
    ON CONFLICT (snapshot_date) DO UPDATE
        SET total_due = EXCLUDED.total_due;
END;
$$;

CALL pr_refresh_receivables();
SELECT * FROM receivable_snapshot ORDER BY snapshot_date;

-- rerun replaces today's total
CALL pr_refresh_receivables();
SELECT * FROM receivable_snapshot ORDER BY snapshot_date;

-- =====================================================================
-- Question 3 (g) Procedure pr_refresh_overdue(p_as_of)
-- Counts the loans still unreturned as of p_as_of that are past their due
-- date, and sums their fines as of that date, into overdue_summary.
--   "unreturned as of p_as_of" = borrowed on/before p_as_of and either not
--   returned yet or returned after p_as_of (so historical dates are
--   correct too). Only loans due before p_as_of carry a fine, so these
--   are the loans counted as overdue (overdue_count).
-- INSERT ... ON CONFLICT DO UPDATE replaces the same snapshot_date on a
-- rerun. SET search_path lets pg_cron run it.
-- =====================================================================
SET search_path TO q03_library;

CREATE OR REPLACE PROCEDURE pr_refresh_overdue(p_as_of date)
LANGUAGE plpgsql
SET search_path = q03_library, pg_temp
AS $$
BEGIN
    IF p_as_of IS NULL THEN
        RAISE EXCEPTION 'p_as_of is required';
    END IF;

    INSERT INTO overdue_summary (snapshot_date, overdue_count, total_fine)
    SELECT p_as_of,
           COUNT(*),
           COALESCE(SUM(fn_loan_fine(l.loan_id, p_as_of)), 0)
    FROM loans l
    WHERE l.borrowed_on <= p_as_of
      AND (l.returned_on IS NULL OR l.returned_on > p_as_of)
      AND l.due_on < p_as_of
    ON CONFLICT (snapshot_date) DO UPDATE
        SET overdue_count = EXCLUDED.overdue_count,
            total_fine    = EXCLUDED.total_fine;
END;
$$;

CALL pr_refresh_overdue(CURRENT_DATE);
SELECT * FROM overdue_summary ORDER BY snapshot_date;

-- rerun replaces the same snapshot_date
CALL pr_refresh_overdue(CURRENT_DATE);
SELECT * FROM overdue_summary ORDER BY snapshot_date;

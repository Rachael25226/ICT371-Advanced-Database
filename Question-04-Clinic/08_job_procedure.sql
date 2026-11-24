-- =====================================================================
-- Question 4 (g) Procedure pr_refresh_clinic_summary(p_day)
-- Counts each of the three statuses for that appointment date (using
-- COUNT ... FILTER) and stores them in clinic_summary. ON CONFLICT DO
-- UPDATE makes a rerun replace that date's summary. A date with no
-- appointments is stored as zeros.
-- =====================================================================
SET search_path TO q04_clinic;

CREATE OR REPLACE PROCEDURE pr_refresh_clinic_summary(p_day date)
LANGUAGE plpgsql
SET search_path = q04_clinic, pg_temp
AS $$
BEGIN
    IF p_day IS NULL THEN
        RAISE EXCEPTION 'p_day is required';
    END IF;

    INSERT INTO clinic_summary (summary_date, booked_count, attended_count, cancelled_count)
    SELECT p_day,
           COUNT(*) FILTER (WHERE status = 'BOOKED'),
           COUNT(*) FILTER (WHERE status = 'ATTENDED'),
           COUNT(*) FILTER (WHERE status = 'CANCELLED')
    FROM appointments
    WHERE appointment_day = p_day
    ON CONFLICT (summary_date) DO UPDATE
        SET booked_count    = EXCLUDED.booked_count,
            attended_count  = EXCLUDED.attended_count,
            cancelled_count = EXCLUDED.cancelled_count;
END;
$$;

CALL pr_refresh_clinic_summary(CURRENT_DATE - 1);
SELECT * FROM clinic_summary ORDER BY summary_date;

-- rerun replaces the row
CALL pr_refresh_clinic_summary(CURRENT_DATE - 1);
SELECT * FROM clinic_summary ORDER BY summary_date;

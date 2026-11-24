-- =====================================================================
-- Question 10 (g) Procedure pr_assess_pending()
-- Uses a query FOR loop that selects ONLY PENDING applications and
-- passes each one to pr_assess_application. Completed (APPROVED /
-- REJECTED) applications are never selected, so a rerun does not
-- reassess them and - because their status does not change - the
-- trigger writes no duplicate audit entries.
-- SET search_path lets pg_cron run it.
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE OR REPLACE PROCEDURE pr_assess_pending()
LANGUAGE plpgsql
SET search_path = q10_scholarships, pg_temp
AS $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT application_id
        FROM applications
        WHERE status = 'PENDING'
        ORDER BY submitted_on, application_id
    LOOP
        CALL pr_assess_application(r.application_id);
    END LOOP;
END;
$$;

-- First run assesses the six seeded applications ...
CALL pr_assess_pending();
SELECT application_id, age_at_application, monthly_income, average_mark, status
FROM applications ORDER BY application_id;
SELECT * FROM decision_audit ORDER BY audit_id;

-- ... a rerun finds nothing PENDING: no reassessment, no new audit rows.
CALL pr_assess_pending();
SELECT count(*) AS audit_rows_after_rerun FROM decision_audit;

-- The view now shows the approved applicants
SELECT * FROM v_approved_applicants ORDER BY student_number;

-- =====================================================================
-- Question 10 (c) Procedure pr_assess_application(p_application_id)
--   * requires an existing application in PENDING status - a clear
--     exception is raised for an unknown or already assessed application;
--   * calls fn_scholarship_eligible;
--   * updates the status to APPROVED or REJECTED.
-- The row is locked (FOR UPDATE) so it cannot be assessed twice at once.
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE OR REPLACE PROCEDURE pr_assess_application(p_application_id integer)
LANGUAGE plpgsql
AS $$
DECLARE
    v_app applications%ROWTYPE;
BEGIN
    SELECT * INTO v_app
    FROM applications
    WHERE application_id = p_application_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Application % does not exist', p_application_id;
    END IF;

    IF v_app.status <> 'PENDING' THEN
        RAISE EXCEPTION 'Application % has already been assessed (status %)',
              p_application_id, v_app.status;
    END IF;

    UPDATE applications
       SET status = CASE
                        WHEN fn_scholarship_eligible(v_app.age_at_application,
                                                     v_app.monthly_income,
                                                     v_app.average_mark)
                        THEN 'APPROVED'
                        ELSE 'REJECTED'
                    END
     WHERE application_id = p_application_id;
END;
$$;

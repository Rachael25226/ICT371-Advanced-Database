-- =====================================================================
-- Question 10 (e) View v_approved_applicants
-- Student number, full name, average mark and status for APPROVED
-- applications only. Household income (and age) are deliberately omitted.
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE OR REPLACE VIEW v_approved_applicants AS
SELECT s.student_number,
       s.full_name,
       a.average_mark,
       a.status
FROM applications a
JOIN students s ON s.student_id = a.student_id
WHERE a.status = 'APPROVED';

-- Empty until applications are assessed (all six are still PENDING here);
-- 08_job_procedure.sql assesses them and queries the view again.
SELECT * FROM v_approved_applicants ORDER BY student_number;

-- =====================================================================
-- Question 2 (e) View v_fee_balances
-- Student number, full name and outstanding balance for students who
-- still owe fees. Fully settled students (balance 0) are excluded.
-- Payments are aggregated once per student and LEFT JOINed so a student
-- with no payments shows the full fee as outstanding.
-- =====================================================================
SET search_path TO q02_university_fees;

CREATE OR REPLACE VIEW v_fee_balances AS
SELECT s.student_number,
       s.full_name,
       s.fee_due - COALESCE(p.total_paid, 0) AS outstanding_balance
FROM students s
LEFT JOIN (SELECT student_id, SUM(amount) AS total_paid
           FROM payments
           GROUP BY student_id) p ON p.student_id = s.student_id
WHERE s.fee_due - COALESCE(p.total_paid, 0) > 0;

SELECT * FROM v_fee_balances ORDER BY student_number;

-- =====================================================================
-- Question 3 (e) View v_overdue_loans
-- Loans that are currently unreturned AND due before CURRENT_DATE, with
-- book title, borrower, due date and the fine as of today.
-- =====================================================================
SET search_path TO q03_library;

CREATE OR REPLACE VIEW v_overdue_loans AS
SELECT l.loan_id,
       b.title,
       l.borrower_name,
       l.due_on,
       fn_loan_fine(l.loan_id, CURRENT_DATE) AS fine_as_of_today
FROM loans l
JOIN books b ON b.book_id = l.book_id
WHERE l.returned_on IS NULL
  AND l.due_on < CURRENT_DATE;

SELECT * FROM v_overdue_loans ORDER BY due_on;

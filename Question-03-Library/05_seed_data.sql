-- =====================================================================
-- Question 3 (a) Seed data: three books and six loans.
-- Dates are relative to CURRENT_DATE (CD) so the scenario holds whenever
-- the script is run:
--   loan 1  open, due CD-6            -> open OVERDUE loan (fine K12 today)
--   loan 2  open, due CD+11           -> open loan, not yet due
--   loan 3  returned CD-10, due CD-16 -> returned LATE (final fine K12)
--   loan 4  returned on its due date  -> ON-TIME return (fine K0)
--   loan 5  open, due CD-2            -> open overdue (fine K4 today)
--   loan 6  open, due today           -> not overdue yet
-- Loans 3 and 4 are returned through pr_return_loan, so their fines are
-- calculated by the procedure and the trigger audits the change.
-- =====================================================================
SET search_path TO q03_library;

INSERT INTO books (title) VALUES
    ('Database System Concepts'),          -- id 1
    ('Fundamentals of Database Systems'),  -- id 2
    ('SQL Performance Explained');         -- id 3

INSERT INTO loans (book_id, borrower_name, borrowed_on, due_on) VALUES
    (1, 'Natasha Zulu',    CURRENT_DATE - 20, CURRENT_DATE - 6),    -- 1
    (2, 'Joseph Tembo',    CURRENT_DATE - 3,  CURRENT_DATE + 11),   -- 2
    (3, 'Grace Lungu',     CURRENT_DATE - 30, CURRENT_DATE - 16),   -- 3
    (1, 'Peter Sakala',    CURRENT_DATE - 15, CURRENT_DATE - 1),    -- 4
    (2, 'Mercy Daka',      CURRENT_DATE - 10, CURRENT_DATE - 2),    -- 5
    (3, 'Kelvin Chileshe', CURRENT_DATE - 7,  CURRENT_DATE);        -- 6

CALL pr_return_loan(3, CURRENT_DATE - 10);   -- 6 days late -> K12
CALL pr_return_loan(4, CURRENT_DATE - 1);    -- on the due date -> K0

SELECT l.loan_id, b.title, l.borrower_name, l.borrowed_on, l.due_on,
       l.returned_on, l.fine_amount,
       fn_loan_fine(l.loan_id, CURRENT_DATE) AS fine_as_of_today
FROM loans l JOIN books b ON b.book_id = l.book_id
ORDER BY l.loan_id;

SELECT * FROM loan_audit ORDER BY audit_id;

-- =====================================================================
-- Question 3 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q03_library;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    IF p_ok IS TRUE THEN RETURN 'PASS: ' || p_label; END IF;
    RAISE EXCEPTION 'FAIL: %', p_label;
END $$;

CREATE OR REPLACE FUNCTION pg_temp.expect_error(p_sql text, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'PASS: ' || p_label || '  [rejected: ' || SQLERRM || ']';
    END;
    RAISE EXCEPTION 'FAIL: % (statement was accepted)', p_label;
END $$;

\echo '--- (a) constraints and seed data ---'
SELECT pg_temp.expect_error($q$INSERT INTO loans (book_id, borrower_name, borrowed_on, due_on) VALUES (1, 'X', CURRENT_DATE, CURRENT_DATE - 1)$q$,
                            'due_on before borrowed_on rejected');
SELECT pg_temp.expect_error($q$INSERT INTO loans (book_id, borrower_name, borrowed_on, due_on) VALUES (99, 'X', CURRENT_DATE, CURRENT_DATE)$q$,
                            'loan of an unknown book rejected (foreign key)');
SELECT pg_temp.assert_true((SELECT count(*) FROM books) = 3 AND (SELECT count(*) FROM loans) = 6,
                           'three books and six loans');
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM loans WHERE returned_on IS NULL AND due_on < CURRENT_DATE),
                           'an open overdue loan exists');
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM loans WHERE returned_on = due_on AND fine_amount = 0),
                           'an on-time loan exists (returned on the due date, no fine)');
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM loans WHERE returned_on IS NOT NULL),
                           'a returned loan exists');

\echo '--- (b) fn_loan_fine ---'
SELECT pg_temp.assert_true(fn_loan_fine(1, CURRENT_DATE) = 12,     'open loan 6 days overdue = K12');
SELECT pg_temp.assert_true(fn_loan_fine(1, CURRENT_DATE + 1) = 14, 'an open loan keeps accumulating (K14 tomorrow)');
SELECT pg_temp.assert_true(fn_loan_fine(2, CURRENT_DATE) = 0,      'loan not yet due = K0 (minimum zero)');
SELECT pg_temp.assert_true(fn_loan_fine(6, CURRENT_DATE) = 0,      'loan due today = K0');
SELECT pg_temp.assert_true(fn_loan_fine(3, CURRENT_DATE) = 12,     'returned loan: fine frozen at return date (K12)');
SELECT pg_temp.assert_true(fn_loan_fine(3, CURRENT_DATE + 100) = 12, 'returned loan: no growth after return');
SELECT pg_temp.assert_true(fn_loan_fine(3, CURRENT_DATE - 13) = 6, 'returned loan: earlier p_as_of is used when it is before the return (3 days = K6)');
SELECT pg_temp.assert_true(fn_loan_fine(4, CURRENT_DATE) = 0,      'returned on the due date = K0');
SELECT pg_temp.expect_error('SELECT fn_loan_fine(999, CURRENT_DATE)', 'unknown loan rejected');

\echo '--- (c) pr_return_loan ---'
SELECT pg_temp.expect_error('CALL pr_return_loan(999, CURRENT_DATE)',    'unknown loan rejected');
SELECT pg_temp.expect_error('CALL pr_return_loan(3, CURRENT_DATE)',      'already returned loan rejected');
SELECT pg_temp.expect_error('CALL pr_return_loan(1, CURRENT_DATE - 21)', 'return before borrowed_on rejected');
SELECT pg_temp.expect_error('CALL pr_return_loan(1, NULL)',              'missing return date rejected');
SELECT pg_temp.assert_true((SELECT returned_on IS NULL AND fine_amount = 0 FROM loans WHERE loan_id = 1),
                           'loan 1 unchanged after the rejected calls');
CALL pr_return_loan(5, CURRENT_DATE);   -- 2 days late
SELECT pg_temp.assert_true((SELECT returned_on = CURRENT_DATE AND fine_amount = 4 FROM loans WHERE loan_id = 5),
                           'return date and final fine (K4) stored together');

\echo '--- (d) trigger ---'
SELECT count(*) AS audit_before FROM loan_audit \gset
SELECT pg_temp.assert_true((SELECT count(*) FROM loan_audit WHERE loan_id IN (3, 4, 5)) = 3,
                           'each of the three returns produced one audit row');
SELECT pg_temp.assert_true((SELECT old_returned_on IS NULL AND new_returned_on = CURRENT_DATE
                            FROM loan_audit WHERE loan_id = 5),
                           'audit row holds OLD (NULL) and NEW (today) return dates');
UPDATE loans SET fine_amount = fine_amount, borrower_name = borrower_name WHERE loan_id = 5;
UPDATE loans SET returned_on = returned_on WHERE loan_id = 3;
SELECT pg_temp.assert_true((SELECT count(*) FROM loan_audit) = :audit_before,
                           'updates that do not change returned_on create no audit row');
UPDATE loans SET returned_on = CURRENT_DATE - 9 WHERE loan_id = 3;   -- correction by direct SQL
SELECT pg_temp.assert_true((SELECT count(*) FROM loan_audit) = :audit_before + 1,
                           'a direct correction of returned_on is audited');
SELECT * FROM loan_audit ORDER BY audit_id;

\echo '--- (e) view ---'
SELECT pg_temp.assert_true((SELECT array_agg(loan_id ORDER BY loan_id) FROM v_overdue_loans) = ARRAY[1],
                           'v_overdue_loans lists only loan 1 (returned, not-yet-due and due-today loans excluded)');
SELECT pg_temp.assert_true((SELECT fine_as_of_today FROM v_overdue_loans WHERE loan_id = 1) = 12,
                           'fine as of today shown (K12)');
SELECT * FROM v_overdue_loans;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q03_library'
                                     AND indexname = 'idx_loans_open_by_book'),
                           'idx_loans_open_by_book exists');

\echo '--- (g) pr_refresh_overdue ---'
CALL pr_refresh_overdue(CURRENT_DATE);
CALL pr_refresh_overdue(CURRENT_DATE);
SELECT pg_temp.assert_true((SELECT count(*) FROM overdue_summary WHERE snapshot_date = CURRENT_DATE) = 1,
                           'rerun keeps one row for the snapshot_date');
SELECT pg_temp.assert_true((SELECT overdue_count = 1 AND total_fine = 12
                            FROM overdue_summary WHERE snapshot_date = CURRENT_DATE),
                           'today: 1 overdue loan, K12 (loan 5 now returned, not counted)');
CALL pr_refresh_overdue(CURRENT_DATE - 1);
SELECT pg_temp.assert_true((SELECT overdue_count = 2 AND total_fine = 10 + 2
                            FROM overdue_summary WHERE snapshot_date = CURRENT_DATE - 1),
                           'yesterday: loans 1 (K10) and 5 (K2) were unreturned and overdue -> 2 loans, K12');
SELECT * FROM overdue_summary ORDER BY snapshot_date;

\echo '=== Question 3: all tests passed ==='

-- =====================================================================
-- Question 2 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q02_university_fees;

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
SELECT pg_temp.expect_error($q$INSERT INTO students (student_number, full_name, fee_due) VALUES ('2024-0001', 'Duplicate', 100)$q$,
                            'duplicate student_number rejected (UNIQUE)');
SELECT pg_temp.expect_error($q$INSERT INTO students (student_number, full_name, fee_due) VALUES ('2024-0099', 'Negative', -1)$q$,
                            'negative fee_due rejected');
SELECT pg_temp.expect_error($q$INSERT INTO payments (student_id, amount, paid_on) VALUES (999, 10, CURRENT_DATE)$q$,
                            'payment for unknown student rejected (foreign key)');
SELECT pg_temp.assert_true((SELECT count(*) FROM payments) >= 6, 'at least six payments loaded');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM payments WHERE student_id = 3),
                           'student 3 initially has no payments');
SELECT pg_temp.assert_true((SELECT count(DISTINCT fn_fee_balance(student_id)) FROM students) = 3,
                           'the three students have different balances');

\echo '--- (b) fn_fee_balance ---'
SELECT pg_temp.assert_true(fn_fee_balance(1) = 3000.00, 'student 1: 15000 - 12000 = 3000');
SELECT pg_temp.assert_true(fn_fee_balance(2) = 0,       'student 2: fully settled = 0');
SELECT pg_temp.assert_true(fn_fee_balance(3) = 9000.00, 'student 3: no payments returns the full fee 9000');
SELECT pg_temp.expect_error('SELECT fn_fee_balance(999)', 'unknown student rejected');

\echo '--- (c) pr_receive_payment ---'
SELECT count(*) AS pay_before, (SELECT sum(fee_due) FROM students) AS fee_due_before FROM payments \gset
SELECT pg_temp.expect_error('CALL pr_receive_payment(1, NULL, CURRENT_DATE)',  'NULL amount rejected');
SELECT pg_temp.expect_error('CALL pr_receive_payment(1, 0, CURRENT_DATE)',     'zero amount rejected');
SELECT pg_temp.expect_error('CALL pr_receive_payment(1, -50, CURRENT_DATE)',   'negative amount rejected');
SELECT pg_temp.expect_error('CALL pr_receive_payment(1, 3000.01, CURRENT_DATE)','payment above the 3000 balance rejected');
SELECT pg_temp.expect_error('CALL pr_receive_payment(2, 1, CURRENT_DATE)',     'any payment by a settled student rejected');
SELECT pg_temp.expect_error('CALL pr_receive_payment(999, 10, CURRENT_DATE)',  'unknown student rejected');
SELECT pg_temp.expect_error('CALL pr_receive_payment(1, 10, NULL)',            'missing date rejected');
SELECT pg_temp.assert_true((SELECT count(*) FROM payments) = :pay_before, 'no payment stored by the invalid calls');

CALL pr_receive_payment(3, 2500.00, CURRENT_DATE);
SELECT pg_temp.assert_true((SELECT count(*) FROM payments) = :pay_before + 1, 'valid payment inserted');
SELECT pg_temp.assert_true((SELECT sum(fee_due) FROM students) = :fee_due_before, 'fee_due NOT changed by the payment');
SELECT pg_temp.assert_true(fn_fee_balance(3) = 6500.00, 'student 3 balance now 9000 - 2500 = 6500');
CALL pr_receive_payment(1, 3000.00, CURRENT_DATE);      -- exactly the balance is allowed
SELECT pg_temp.assert_true(fn_fee_balance(1) = 0, 'paying exactly the balance settles the account (no credit)');

\echo '--- (d) trigger ---'
SELECT pg_temp.assert_true((SELECT count(*) FROM payment_audit) = (SELECT count(*) FROM payments),
                           'one audit row for every payment');
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT 1 FROM payments p
         LEFT JOIN payment_audit a ON a.payment_id = p.payment_id
         WHERE a.audit_id IS NULL OR a.student_id <> p.student_id OR a.amount <> p.amount),
         'every audit row matches its payment (ID, student and amount)');
SELECT pg_temp.assert_true(
         (SELECT prosrc NOT ILIKE '%payment_audit%' FROM pg_proc
          WHERE proname = 'pr_receive_payment' AND pronamespace = 'q02_university_fees'::regnamespace),
         'pr_receive_payment itself never writes to payment_audit');
INSERT INTO payments (student_id, amount, paid_on) VALUES (3, 100.00, CURRENT_DATE);  -- direct SQL
SELECT pg_temp.assert_true((SELECT count(*) FROM payment_audit) = (SELECT count(*) FROM payments),
                           'a direct SQL insert is also audited by the trigger');
SELECT * FROM payment_audit ORDER BY audit_id;

\echo '--- (e) view ---'
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_fee_balances WHERE outstanding_balance <= 0),
                           'v_fee_balances excludes fully settled students');
SELECT pg_temp.assert_true((SELECT outstanding_balance FROM v_fee_balances WHERE student_number = '2024-0003') = 6400.00,
                           'student 3 shown with balance 6400');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_fee_balances WHERE student_number IN ('2024-0001', '2024-0002')),
                           'settled students 1 and 2 are not listed');
SELECT * FROM v_fee_balances ORDER BY student_number;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q02_university_fees'
                                     AND indexname = 'idx_payments_student_paid_on'),
                           'idx_payments_student_paid_on exists');

\echo '--- (g) pr_refresh_collections ---'
CALL pr_refresh_collections(CURRENT_DATE);
CALL pr_refresh_collections(CURRENT_DATE);
SELECT pg_temp.assert_true((SELECT count(*) FROM daily_collections WHERE collection_date = CURRENT_DATE) = 1,
                           'rerun keeps one summary row for the date');
SELECT pg_temp.assert_true(
         (SELECT payment_count = (SELECT count(*) FROM payments WHERE paid_on = CURRENT_DATE)
             AND total_amount  = (SELECT sum(amount) FROM payments WHERE paid_on = CURRENT_DATE)
          FROM daily_collections WHERE collection_date = CURRENT_DATE),
         'count and total equal the real payments for the date (not doubled)');
CALL pr_refresh_collections(CURRENT_DATE - 30);
SELECT pg_temp.assert_true(
         (SELECT payment_count = 0 AND total_amount = 0 FROM daily_collections WHERE collection_date = CURRENT_DATE - 30),
         'a date with no payments is stored as zero');
SELECT * FROM daily_collections ORDER BY collection_date;

\echo '=== Question 2: all tests passed ==='

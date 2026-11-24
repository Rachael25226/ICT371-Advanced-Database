-- =====================================================================
-- Question 6 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q06_payroll;

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

-- variant that also checks the error is the EXPECTED one (message contains p_expect)
CREATE OR REPLACE FUNCTION pg_temp.expect_error(p_sql text, p_label text, p_expect text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        IF position(lower(p_expect) IN lower(SQLERRM)) = 0 THEN
            RAISE EXCEPTION 'FAIL: % (rejected for the wrong reason: %)', p_label, SQLERRM;
        END IF;
        RETURN 'PASS: ' || p_label || '  [rejected: ' || SQLERRM || ']';
    END;
    RAISE EXCEPTION 'FAIL: % (statement was accepted)', p_label;
END $$;

\set this_month 'date_trunc(''month'', CURRENT_DATE)::date'

\echo '--- (a) constraints and seed data ---'
SELECT pg_temp.expect_error($q$INSERT INTO employees (full_name, basic_salary) VALUES ('Bad', -1)$q$, 'negative salary rejected');
SELECT pg_temp.expect_error($q$INSERT INTO employees (full_name, basic_salary, allowance) VALUES ('Bad', 1, -1)$q$, 'negative allowance rejected');
SELECT pg_temp.expect_error($q$INSERT INTO employees (full_name, basic_salary, deduction) VALUES ('Bad', 1, -1)$q$, 'negative deduction rejected');
SELECT pg_temp.expect_error($q$INSERT INTO payroll (employee_id, pay_month, gross_pay, net_pay) VALUES (1, DATE '2026-01-15', 1, 1)$q$,
                            'pay_month that is not a month start rejected');
SELECT pg_temp.expect_error($q$INSERT INTO payroll (employee_id, pay_month, gross_pay, net_pay) SELECT employee_id, pay_month, gross_pay, net_pay FROM payroll LIMIT 1$q$,
                            'duplicate employee/month rejected (UNIQUE)');
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM employees WHERE active) AND EXISTS (SELECT 1 FROM employees WHERE NOT active),
                           'active and inactive employees exist');
SELECT pg_temp.assert_true((SELECT count(DISTINCT pay_month) FROM payroll) >= 2, 'payroll data for at least two months');

\echo '--- (b) fn_net_pay ---'
SELECT pg_temp.assert_true(fn_net_pay(1) = 9000 + 1500 - 1200, 'employee 1 net = 9000 + 1500 - 1200 = 9300 (current salary)');
SELECT pg_temp.assert_true(fn_net_pay(2) = 6100, 'employee 2 net = 6200 + 800 - 900 = 6100');
SELECT pg_temp.expect_error('SELECT fn_net_pay(999)', 'unknown employee rejected');
INSERT INTO employees (full_name, basic_salary, allowance, deduction, active)
VALUES ('Paul Hamoonga', 1000.00, 100.00, 2000.00, true)            -- net would be -900
RETURNING employee_id AS bad_emp \gset
SELECT pg_temp.expect_error(format('SELECT fn_net_pay(%s)', :bad_emp), 'negative computed net pay rejected',
                            'Negative net pay');

\echo '--- (c) pr_process_payroll ---'
SELECT pg_temp.expect_error($q$CALL pr_process_payroll(DATE '2026-03-15')$q$, 'non month-start date rejected');
SELECT pg_temp.expect_error('CALL pr_process_payroll(NULL)', 'NULL month rejected');
SELECT pg_temp.expect_error(format('CALL pr_process_payroll(%L)', :this_month),
                            'an invalid employee calculation fails the whole call', 'Negative net pay');
SELECT pg_temp.assert_true((SELECT count(*) FROM payroll WHERE pay_month = :this_month) = 0,
                           'no rows kept for the month - employees 1-3 processed before the invalid one were rolled back too');
UPDATE employees SET deduction = 150.00 WHERE employee_id = :bad_emp;   -- correct the data
CALL pr_process_payroll(:this_month);
SELECT pg_temp.assert_true((SELECT count(*) FROM payroll WHERE pay_month = :this_month) =
                           (SELECT count(*) FROM employees WHERE active),
                           'one row per ACTIVE employee for the month');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM payroll WHERE pay_month = :this_month AND employee_id = 4),
                           'inactive employee 4 not paid');
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT 1 FROM payroll p JOIN employees e USING (employee_id)
         WHERE p.pay_month = :this_month
           AND (p.gross_pay <> e.basic_salary + e.allowance OR p.net_pay <> e.basic_salary + e.allowance - e.deduction)),
         'gross = salary + allowance and net = gross - deduction');
SELECT gross_pay AS gross_before FROM payroll WHERE employee_id = 2 AND pay_month = :this_month \gset
UPDATE employees SET basic_salary = 7000.00 WHERE employee_id = 2;
CALL pr_process_payroll(:this_month);
SELECT pg_temp.assert_true((SELECT count(*) FROM payroll WHERE pay_month = :this_month) = 4,
                           'reprocessing the month adds no duplicate rows');
SELECT pg_temp.assert_true((SELECT gross_pay FROM payroll WHERE employee_id = 2 AND pay_month = :this_month) = :gross_before,
                           'existing row left unchanged even after a salary change');

\echo '--- (d) trigger ---'
SELECT count(*) AS audit_before FROM salary_audit \gset
UPDATE employees SET allowance = allowance + 100 WHERE employee_id = 3;
UPDATE employees SET basic_salary = basic_salary WHERE employee_id = 3;
SELECT pg_temp.assert_true((SELECT count(*) FROM salary_audit) = :audit_before,
                           'allowance change and unchanged salary produce no audit entry');
UPDATE employees SET basic_salary = 10200.00 WHERE employee_id = 3;
SELECT pg_temp.assert_true((SELECT old_salary = 9800 AND new_salary = 10200 FROM salary_audit
                            ORDER BY audit_id DESC LIMIT 1),
                           'actual salary change audited with OLD 9800 and NEW 10200');
SELECT * FROM salary_audit ORDER BY audit_id;

\echo '--- (e) view ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM v_payroll_report WHERE employee_id = 4),
                           'historical payroll of inactive employee 4 still in the report');
SELECT pg_temp.assert_true((SELECT count(*) FROM v_payroll_report) = (SELECT count(*) FROM payroll),
                           'report contains every payroll row');
SELECT * FROM v_payroll_report ORDER BY pay_month, employee_id;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(
         (SELECT indexdef LIKE '%(pay_month)' FROM pg_indexes
          WHERE schemaname = 'q06_payroll' AND indexname = 'idx_payroll_pay_month'),
         'idx_payroll_pay_month exists on pay_month only');
SELECT pg_temp.assert_true(
         (SELECT count(*) FROM pg_indexes WHERE schemaname = 'q06_payroll' AND tablename = 'payroll'
            AND indexdef LIKE '%(employee_id, pay_month)') = 1,
         'no duplicate of the employee/month unique index');

\echo '--- (g) scheduled call expression ---'
SELECT pg_temp.assert_true(
         (date_trunc('month', DATE '2027-03-01') - INTERVAL '1 month')::date = DATE '2027-02-01'
     AND (date_trunc('month', DATE '2027-01-01') - INTERVAL '1 month')::date = DATE '2026-12-01',
         'on the 1st the job passes the first date of the previous month (also across a year end)');

\echo '=== Question 6: all tests passed ==='

-- =====================================================================
-- Question 10 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    IF p_ok IS TRUE THEN RETURN 'PASS: ' || p_label; END IF;
    RAISE EXCEPTION 'FAIL: %', p_label;
END $$;

-- expect_error(sql, label, expected text in the error message)
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

\echo '--- (a) constraints and seed data ---'
SELECT pg_temp.expect_error($q$INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark) VALUES (1, 0, 100, 50)$q$,
                            'non-positive age rejected', 'chk_applications_age_positive');
SELECT pg_temp.expect_error($q$INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark) VALUES (1, 20, -1, 50)$q$,
                            'negative income rejected', 'chk_applications_income_non_negative');
SELECT pg_temp.expect_error($q$INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark) VALUES (1, 20, 100, 100.01)$q$,
                            'mark above 100 rejected', 'chk_applications_mark_range');
SELECT pg_temp.expect_error($q$INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark, status) VALUES (1, 20, 100, 50, 'WAITING')$q$,
                            'status outside PENDING/APPROVED/REJECTED rejected', 'chk_applications_status');
SELECT pg_temp.assert_true((SELECT count(*) FROM applications) = 6
                       AND (SELECT count(DISTINCT student_id) FROM applications) >= 3,
                           'six applications across at least three students');

\echo '--- (b) fn_scholarship_eligible ---'
SELECT pg_temp.assert_true(fn_scholarship_eligible(20, 2500, 75) = true,  'typical qualifying applicant');
SELECT pg_temp.assert_true(fn_scholarship_eligible(18, 3000, 70) = true,  'boundary: age 18, income 3000, mark 70 all qualify');
SELECT pg_temp.assert_true(fn_scholarship_eligible(25, 0, 100) = true,    'boundary: age 25 qualifies');
SELECT pg_temp.assert_true(fn_scholarship_eligible(17, 1000, 90) = false, 'age 17 too young');
SELECT pg_temp.assert_true(fn_scholarship_eligible(26, 1000, 90) = false, 'age 26 too old');
SELECT pg_temp.assert_true(fn_scholarship_eligible(20, 3000.01, 90) = false, 'income 3000.01 over the limit');
SELECT pg_temp.assert_true(fn_scholarship_eligible(20, 1000, 69.99) = false, 'mark 69.99 below 70');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(NULL, 1000, 80)', 'NULL age rejected', 'required');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(20, NULL, 80)',   'NULL income rejected', 'required');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(20, 1000, NULL)', 'NULL mark rejected', 'required');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(20, -1, 80)',     'negative income rejected', 'Invalid income');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(0, 1000, 80)',    'zero age rejected', 'Invalid age');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(-3, 1000, 80)',   'negative age rejected', 'Invalid age');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(20, 1000, 101)',  'mark above 100 rejected', 'Invalid mark');
SELECT pg_temp.expect_error('SELECT fn_scholarship_eligible(20, 1000, -0.5)', 'mark below 0 rejected', 'Invalid mark');

\echo '--- (c) pr_assess_application (the six seeds were assessed by 08_job_procedure.sql) ---'
SELECT pg_temp.assert_true(
         (SELECT array_agg(status::text ORDER BY application_id) FROM applications)
         = ARRAY['APPROVED', 'APPROVED', 'APPROVED', 'REJECTED', 'REJECTED', 'REJECTED'],
         'seeded applications decided correctly, including every boundary case');
SELECT pg_temp.expect_error('CALL pr_assess_application(999)', 'unknown application rejected with a clear message', 'does not exist');
SELECT pg_temp.expect_error('CALL pr_assess_application(1)',   'already APPROVED application rejected', 'already been assessed');
SELECT pg_temp.expect_error('CALL pr_assess_application(4)',   'already REJECTED application rejected', 'already been assessed');
INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark, submitted_on)
VALUES (2, 21, 1800.00, 91.50, CURRENT_DATE)
RETURNING application_id AS new_app \gset
CALL pr_assess_application(:new_app);
SELECT pg_temp.assert_true((SELECT status FROM applications WHERE application_id = :new_app) = 'APPROVED',
                           'new PENDING application assessed and APPROVED');

\echo '--- (d) trigger ---'
SELECT pg_temp.assert_true((SELECT count(*) FROM decision_audit) = 7, 'seven decisions -> seven audit rows');
SELECT pg_temp.assert_true((SELECT old_status = 'PENDING' AND new_status = 'APPROVED' AND changed_at IS NOT NULL
                            FROM decision_audit WHERE application_id = :new_app),
                           'audit row has OLD, NEW status and a timestamp');
UPDATE applications SET status = status, average_mark = average_mark WHERE application_id = 2;
SELECT pg_temp.assert_true((SELECT count(*) FROM decision_audit) = 7, 'unchanged status creates no audit entry');
UPDATE applications SET status = 'REJECTED' WHERE application_id = :new_app;      -- manual override
SELECT pg_temp.assert_true((SELECT count(*) FROM decision_audit) = 8, 'a real status change by direct SQL is audited');
UPDATE applications SET status = 'APPROVED' WHERE application_id = :new_app;      -- restore
SELECT * FROM decision_audit ORDER BY audit_id;

\echo '--- (e) view ---'
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_approved_applicants WHERE status <> 'APPROVED'),
                           'view contains APPROVED applications only');
SELECT pg_temp.assert_true((SELECT count(*) FROM v_approved_applicants) = 4, 'four approved applications listed');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM information_schema.columns
                                       WHERE table_schema = 'q10_scholarships' AND table_name = 'v_approved_applicants'
                                         AND column_name IN ('monthly_income', 'age_at_application')),
                           'household income is not exposed');
SELECT * FROM v_approved_applicants ORDER BY student_number;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q10_scholarships'
                                     AND indexname = 'idx_applications_status_submitted'),
                           'idx_applications_status_submitted exists');

\echo '--- (g) pr_assess_pending ---'
INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark, submitted_on) VALUES
    (1, 23, 3500.00, 95.00, CURRENT_DATE),
    (3, 24, 900.00,  72.00, CURRENT_DATE);
SELECT count(*) AS audit_before FROM decision_audit \gset
CALL pr_assess_pending();
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM applications WHERE status = 'PENDING'), 'all pending applications processed');
SELECT pg_temp.assert_true((SELECT count(*) FROM decision_audit) = :audit_before + 2,
                           'only the two new PENDING applications were assessed (2 audit rows)');
CALL pr_assess_pending();
CALL pr_assess_pending();
SELECT pg_temp.assert_true((SELECT count(*) FROM decision_audit) = :audit_before + 2,
                           'reruns reassess nothing and add no duplicate audit entries');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT application_id FROM decision_audit GROUP BY application_id
                                       HAVING count(*) FILTER (WHERE old_status = 'PENDING') > 1),
                           'no application was ever assessed from PENDING twice');
SELECT application_id, age_at_application, monthly_income, average_mark, status
FROM applications ORDER BY application_id;

\echo '=== Question 10: all tests passed ==='

-- =====================================================================
-- Question 7 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q07_water_billing;

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
SELECT pg_temp.expect_error($q$INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading) VALUES (1, DATE '2026-01-15', 0, 1)$q$,
                            'reading_month not a month start rejected', 'chk_readings_month_start');
SELECT pg_temp.expect_error($q$INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading) VALUES (1, DATE '2020-01-01', -5, 1)$q$,
                            'negative meter value rejected', 'chk_readings_previous_non_negative');
SELECT pg_temp.expect_error($q$INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading) SELECT customer_id, reading_month, 0, 0 FROM readings LIMIT 1$q$,
                            'second reading for the same customer and month rejected', 'uq_readings_customer_month');
SELECT pg_temp.expect_error($q$UPDATE bills SET amount_paid = charge + 1 WHERE bill_id = 2$q$,
                            'amount_paid above the charge rejected', 'chk_bills_amount_paid_range');
SELECT pg_temp.expect_error($q$UPDATE bills SET amount_paid = -1 WHERE bill_id = 2$q$,
                            'negative amount_paid rejected', 'chk_bills_amount_paid_range');
SELECT pg_temp.assert_true((SELECT count(*) FROM customers) = 3 AND (SELECT count(*) FROM readings) = 6,
                           'three customers and six readings');
SELECT pg_temp.assert_true(
         (SELECT bool_or(u = 0) AND bool_or(u = 10) AND bool_or(u > 10)
          FROM (SELECT current_reading - previous_reading AS u FROM readings) x),
         'readings cover zero, exactly 10 and above 10 units');

\echo '--- (b) fn_water_charge ---'
SELECT pg_temp.assert_true(fn_water_charge(0)     = 0.00,   '0 units    = K0.00');
SELECT pg_temp.assert_true(fn_water_charge(7)     = 35.00,  '7 units    = 7 x 5 = K35.00');
SELECT pg_temp.assert_true(fn_water_charge(10)    = 50.00,  'exactly 10 = K50.00 (all in the first band)');
SELECT pg_temp.assert_true(fn_water_charge(10.5)  = 54.00,  '10.5 units = 50 + 0.5 x 8 = K54.00');
SELECT pg_temp.assert_true(fn_water_charge(25)    = 170.00, '25 units   = 50 + 15 x 8 = K170.00');
SELECT pg_temp.assert_true(fn_water_charge(3.333) = 16.67,  '3.333 units = 16.665 rounded to exactly K16.67');
SELECT pg_temp.assert_true(scale(fn_water_charge(12)) = 2,  'result always has exactly two decimal places');
SELECT pg_temp.expect_error('SELECT fn_water_charge(NULL)', 'NULL consumption rejected', 'Invalid consumption');
SELECT pg_temp.expect_error('SELECT fn_water_charge(-1)',   'negative consumption rejected', 'Invalid consumption');

\echo '--- (c) pr_generate_bill ---'
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT 1 FROM bills b JOIN readings r USING (reading_id)
         WHERE b.charge <> fn_water_charge(r.current_reading - r.previous_reading)),
         'every seeded bill charge equals the tariff for its consumption');
SELECT pg_temp.expect_error('CALL pr_generate_bill(999, CURRENT_DATE)', 'unknown reading rejected', 'Unknown reading_id');
SELECT pg_temp.expect_error('CALL pr_generate_bill(1, CURRENT_DATE)',   'reading that already has a bill rejected', 'already has a bill');
SELECT pg_temp.expect_error('CALL pr_generate_bill(1, NULL)',           'missing due date rejected', 'Due date');
INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading)
VALUES (1, date_trunc('month', CURRENT_DATE)::date, 110.00, 122.00)
RETURNING reading_id AS new_reading \gset
CALL pr_generate_bill(:new_reading, CURRENT_DATE + 30);
SELECT pg_temp.assert_true((SELECT charge = 66.00 AND amount_paid = 0 FROM bills WHERE reading_id = :new_reading),
                           'new 12-unit reading billed K66.00 with amount_paid 0');

\echo '--- (d) trigger ---'
SELECT count(*) AS readings_before FROM readings \gset
SELECT pg_temp.expect_error($q$INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading) VALUES (2, date_trunc('month', CURRENT_DATE)::date, 240.00, 239.99)$q$,
                            'direct import with current below previous rejected', 'below previous');
SELECT pg_temp.expect_error($q$UPDATE readings SET current_reading = 90 WHERE reading_id = 2$q$,
                            'UPDATE setting current below previous rejected', 'below previous');
SELECT pg_temp.assert_true((SELECT count(*) FROM readings) = :readings_before
                       AND (SELECT current_reading FROM readings WHERE reading_id = 2) = 110.00,
                           'rejected readings were not stored or changed');
INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading)
VALUES (2, date_trunc('month', CURRENT_DATE)::date, 240.00, 240.00);
SELECT pg_temp.assert_true(true, 'current equal to previous (zero use) accepted');

\echo '--- (e) view ---'
SELECT pg_temp.assert_true((SELECT array_agg(bill_id ORDER BY bill_id) FROM v_overdue_bills) = ARRAY[3],
                           'only bill 3 is overdue and unpaid (bill 1 is K0, bill 5 fully paid, others not yet due)');
SELECT pg_temp.assert_true((SELECT outstanding_amount FROM v_overdue_bills WHERE bill_id = 3) = 50.00,
                           'bill 3 outstanding = 90 - 40 = K50.00');
UPDATE bills SET amount_paid = charge WHERE bill_id = 3;
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_overdue_bills), 'a fully paid bill leaves the view');
UPDATE bills SET amount_paid = 40.00 WHERE bill_id = 3;
SELECT * FROM v_overdue_bills;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q07_water_billing'
                                     AND indexname = 'idx_bills_unpaid_due_on'),
                           'idx_bills_unpaid_due_on exists');

\echo '--- (g) pr_refresh_receivables ---'
CALL pr_refresh_receivables();
CALL pr_refresh_receivables();
SELECT pg_temp.assert_true((SELECT count(*) FROM receivable_snapshot WHERE snapshot_date = CURRENT_DATE) = 1,
                           'one row for today after reruns');
SELECT pg_temp.assert_true((SELECT total_due FROM receivable_snapshot WHERE snapshot_date = CURRENT_DATE)
                           = (SELECT sum(charge - amount_paid) FROM bills),
                           'total equals all unpaid balances (50 + 50 + 170 + 54 + 66 = 390)');
UPDATE bills SET amount_paid = 66.00 WHERE reading_id = :new_reading;
CALL pr_refresh_receivables();
SELECT pg_temp.assert_true((SELECT total_due FROM receivable_snapshot WHERE snapshot_date = CURRENT_DATE) = 324.00,
                           'rerun after a payment replaces the total (390 - 66 = 324)');
SELECT * FROM receivable_snapshot;

\echo '=== Question 7: all tests passed ==='

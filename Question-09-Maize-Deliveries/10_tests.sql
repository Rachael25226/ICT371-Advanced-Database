-- =====================================================================
-- Question 9 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q09_maize;

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

\echo '--- (a) seed data ---'
SELECT pg_temp.assert_true((SELECT count(*) FROM farmers) = 3 AND (SELECT count(*) FROM deliveries) = 6,
                           'three farmers and six deliveries');
SELECT pg_temp.assert_true((SELECT count(DISTINCT grade) FROM deliveries) = 3, 'all three grades covered');
SELECT pg_temp.assert_true((SELECT bool_or(is_paid) AND bool_or(NOT is_paid) FROM deliveries), 'both payment states covered');
SELECT pg_temp.expect_error($q$INSERT INTO farmers (farmer_number, full_name) VALUES ('FC-1001', 'Duplicate')$q$,
                            'duplicate farmer_number rejected', 'farmers_farmer_number_key');

\echo '--- (b) fn_maize_rate ---'
SELECT pg_temp.assert_true(fn_maize_rate('A') = 5 AND fn_maize_rate('B') = 4 AND fn_maize_rate('C') = 3,
                           'A = K5, B = K4, C = K3');
SELECT pg_temp.assert_true(fn_maize_rate(' b ') = 4, 'lower case / spaces normalised');
SELECT pg_temp.expect_error('SELECT fn_maize_rate(NULL)', 'NULL grade rejected', 'Grade is required');
SELECT pg_temp.expect_error($q$SELECT fn_maize_rate('D')$q$, 'unsupported grade D rejected', 'Unsupported grade');
SELECT pg_temp.expect_error($q$SELECT fn_maize_rate('')$q$,  'empty grade rejected', 'Unsupported grade');

\echo '--- (c) pr_receive_delivery ---'
SELECT count(*) AS del_before FROM deliveries \gset
SELECT pg_temp.expect_error($q$CALL pr_receive_delivery(99, 'A', 10, CURRENT_DATE)$q$, 'unknown farmer rejected', 'Unknown farmer_id');
SELECT pg_temp.expect_error($q$CALL pr_receive_delivery(1, 'Z', 10, CURRENT_DATE)$q$,  'unsupported grade rejected', 'Unsupported grade');
SELECT pg_temp.expect_error($q$CALL pr_receive_delivery(1, NULL, 10, CURRENT_DATE)$q$, 'NULL grade rejected', 'Grade is required');
SELECT pg_temp.expect_error($q$CALL pr_receive_delivery(1, 'A', 0, CURRENT_DATE)$q$,   'zero weight rejected', 'Invalid weight');
SELECT pg_temp.expect_error($q$CALL pr_receive_delivery(1, 'A', -5, CURRENT_DATE)$q$,  'negative weight rejected', 'Invalid weight');
SELECT pg_temp.expect_error($q$CALL pr_receive_delivery(1, 'A', 10, NULL)$q$,          'missing date rejected', 'Delivery date');
SELECT pg_temp.assert_true((SELECT count(*) FROM deliveries) = :del_before, 'nothing stored by the rejected calls');
CALL pr_receive_delivery(2, 'b', 120.25, CURRENT_DATE);
SELECT pg_temp.assert_true(
         (SELECT grade = 'B' AND unit_rate = 4 AND total_value = 481.00 AND NOT is_paid
          FROM deliveries ORDER BY delivery_id DESC LIMIT 1),
         'valid delivery stored unpaid; trigger supplied rate K4 and value 120.25 x 4 = K481.00');
SELECT pg_temp.assert_true(
         (SELECT prosrc NOT ILIKE '%unit_rate%' AND prosrc NOT ILIKE '%total_value%' FROM pg_proc
          WHERE proname = 'pr_receive_delivery' AND pronamespace = 'q09_maize'::regnamespace),
         'the procedure itself never sets unit_rate or total_value');

\echo '--- (d) trigger (direct SQL) ---'
INSERT INTO deliveries (farmer_id, grade, weight_kg, unit_rate, total_value, delivered_on, is_paid)
VALUES (3, 'A', 100.00, 99.00, 1.00, CURRENT_DATE, false)
RETURNING delivery_id AS direct_id \gset
SELECT pg_temp.assert_true((SELECT unit_rate = 5 AND total_value = 500.00 FROM deliveries WHERE delivery_id = :direct_id),
                           'direct insert with wrong rate/value corrected by the trigger (K5, K500.00)');
UPDATE deliveries SET grade = 'C' WHERE delivery_id = :direct_id;
SELECT pg_temp.assert_true((SELECT unit_rate = 3 AND total_value = 300.00 FROM deliveries WHERE delivery_id = :direct_id),
                           'changing the grade by UPDATE re-prices the delivery (K3, K300.00)');
UPDATE deliveries SET total_value = 0 WHERE delivery_id = :direct_id;
SELECT pg_temp.assert_true((SELECT total_value = 300.00 FROM deliveries WHERE delivery_id = :direct_id),
                           'a direct attempt to change total_value is overridden');
SELECT pg_temp.expect_error($q$INSERT INTO deliveries (farmer_id, grade, weight_kg, unit_rate, total_value, delivered_on) VALUES (1, 'A', 0, 5, 0, CURRENT_DATE)$q$,
                            'direct insert with zero weight rejected by the trigger', 'Invalid weight');
SELECT pg_temp.expect_error(format('UPDATE deliveries SET weight_kg = -1 WHERE delivery_id = %s', :direct_id),
                            'direct update to a negative weight rejected by the trigger', 'Invalid weight');
SELECT pg_temp.expect_error($q$INSERT INTO deliveries (farmer_id, grade, weight_kg, unit_rate, total_value, delivered_on) VALUES (1, 'X', 10, 5, 50, CURRENT_DATE)$q$,
                            'direct insert with an unsupported grade rejected', 'Unsupported grade');
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT 1 FROM deliveries
         WHERE unit_rate <> fn_maize_rate(grade) OR total_value <> round(weight_kg * unit_rate, 2)),
         'every stored delivery follows the pricing rule');

\echo '--- (e) view ---'
SELECT pg_temp.assert_true((SELECT count(*) FROM v_farmer_amount_due) = (SELECT count(*) FROM farmers),
                           'every farmer listed');
SELECT pg_temp.assert_true((SELECT amount_due FROM v_farmer_amount_due WHERE farmer_number = 'FC-1001') = 3700.00,
                           'farmer FC-1001 owes 2500 + 1200 = K3,700.00');
SELECT pg_temp.assert_true((SELECT amount_due FROM v_farmer_amount_due WHERE farmer_number = 'FC-1002') = 1252.50 + 481.00,
                           'farmer FC-1002 owes 1252.50 + 481.00 = K1,733.50 (paid delivery excluded)');
UPDATE deliveries SET is_paid = true WHERE delivery_id = :direct_id;
SELECT pg_temp.assert_true((SELECT amount_due FROM v_farmer_amount_due WHERE farmer_number = 'FC-1003') = 0,
                           'farmer FC-1003 has no unpaid deliveries and shows K0');
INSERT INTO farmers (farmer_number, full_name) VALUES ('FC-1004', 'Victor Mbewe');
SELECT pg_temp.assert_true((SELECT amount_due FROM v_farmer_amount_due WHERE farmer_number = 'FC-1004') = 0,
                           'a farmer with no deliveries at all shows K0');
SELECT * FROM v_farmer_amount_due ORDER BY farmer_number;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q09_maize'
                                     AND indexname = 'idx_deliveries_farmer_delivered_on'),
                           'idx_deliveries_farmer_delivered_on exists');

\echo '--- (g) pr_refresh_purchases ---'
CALL pr_refresh_purchases(CURRENT_DATE - 2);
CALL pr_refresh_purchases(CURRENT_DATE - 2);
CALL pr_refresh_purchases(CURRENT_DATE - 2);
SELECT pg_temp.assert_true((SELECT count(*) FROM daily_purchases WHERE purchase_date = CURRENT_DATE - 2) = 1,
                           'one row for the date after three runs');
SELECT pg_temp.assert_true((SELECT total_weight = 1100.00 AND total_value = 4500.00
                            FROM daily_purchases WHERE purchase_date = CURRENT_DATE - 2),
                           'CD-2 totals 500 + 400 + 200 = 1,100 kg and K4,500.00 (not tripled)');
SELECT pg_temp.assert_true((SELECT total_weight = 700.50 AND total_value = 2902.50
                            FROM daily_purchases WHERE purchase_date = CURRENT_DATE - 1),
                           'CD-1 totals 700.50 kg and K2,902.50 (from 08_job_procedure.sql)');
CALL pr_refresh_purchases(CURRENT_DATE - 60);
SELECT pg_temp.assert_true((SELECT total_weight = 0 AND total_value = 0 FROM daily_purchases WHERE purchase_date = CURRENT_DATE - 60),
                           'a day with no deliveries is stored as zeros');
SELECT * FROM daily_purchases ORDER BY purchase_date;

\echo '=== Question 9: all tests passed ==='

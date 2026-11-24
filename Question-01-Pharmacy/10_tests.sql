-- =====================================================================
-- Question 1 - Automated tests
-- Every check prints "PASS: ..." or stops the script with "FAIL: ...".
-- Rejection tests run inside a sub-transaction, so a rejected statement
-- is rolled back exactly as it would be at top level.
-- =====================================================================
SET search_path TO q01_pharmacy;

-- ---------- test helpers (temporary, removed when the session ends) ----------
CREATE OR REPLACE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    IF p_ok IS TRUE THEN
        RETURN 'PASS: ' || p_label;
    END IF;
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

\echo '--- (a) constraints ---'
SELECT pg_temp.expect_error($q$INSERT INTO medicines (medicine_name, unit_price, stock_qty) VALUES ('Bad price', 0, 5)$q$,
                            'zero price rejected');
SELECT pg_temp.expect_error($q$INSERT INTO medicines (medicine_name, unit_price, stock_qty) VALUES ('Bad stock', 1, -1)$q$,
                            'negative stock rejected');
SELECT pg_temp.expect_error($q$INSERT INTO sales (medicine_id, quantity, unit_price, sold_on) VALUES (999, 1, 1, CURRENT_DATE)$q$,
                            'sale for a non-existent medicine rejected by foreign key');
SELECT pg_temp.assert_true((SELECT count(*) FROM medicines) >= 3 AND (SELECT count(*) FROM sales) >= 6,
                           'at least 3 medicines and 6 sales loaded');

\echo '--- (b) fn_sale_value ---'
SELECT pg_temp.assert_true(fn_sale_value(1, 3) = 7.50, 'fn_sale_value(1, 3) = 3 x 2.50 = 7.50');
SELECT pg_temp.expect_error('SELECT fn_sale_value(999, 1)',  'unknown medicine rejected');
SELECT pg_temp.expect_error('SELECT fn_sale_value(1, 0)',    'zero quantity rejected');
SELECT pg_temp.expect_error('SELECT fn_sale_value(1, -2)',   'negative quantity rejected');
SELECT pg_temp.expect_error('SELECT fn_sale_value(1, NULL)', 'NULL quantity rejected');

\echo '--- (c) pr_record_sale: valid sale ---'
SELECT stock_qty AS stock_before FROM medicines WHERE medicine_id = 1 \gset
SELECT count(*)  AS audit_before FROM stock_audit \gset
UPDATE medicines SET unit_price = 2.75 WHERE medicine_id = 1;   -- price change, stock unchanged
CALL pr_record_sale(1, 4, CURRENT_DATE);
SELECT pg_temp.assert_true((SELECT stock_qty FROM medicines WHERE medicine_id = 1) = :stock_before - 4,
                           'stock deducted exactly once (by 4)');
SELECT pg_temp.assert_true((SELECT unit_price FROM sales ORDER BY sale_id DESC LIMIT 1) = 2.75,
                           'sale stores the CURRENT price (2.75 after the price change)');
SELECT pg_temp.assert_true((SELECT count(*) FROM stock_audit) = :audit_before + 1,
                           'one audit row for the sale; none for the price-only update');

\echo '--- (c) pr_record_sale: invalid sales leave both tables unchanged ---'
SELECT count(*) AS sales_before, (SELECT sum(stock_qty) FROM medicines) AS total_stock_before FROM sales \gset
SELECT pg_temp.expect_error('CALL pr_record_sale(1, 100000, CURRENT_DATE)', 'overselling rejected');
SELECT pg_temp.expect_error('CALL pr_record_sale(999, 1, CURRENT_DATE)',    'unknown medicine rejected');
SELECT pg_temp.expect_error('CALL pr_record_sale(1, 0, CURRENT_DATE)',      'zero quantity rejected');
SELECT pg_temp.expect_error('CALL pr_record_sale(1, 1, NULL)',              'missing sale date rejected');
SELECT pg_temp.assert_true((SELECT count(*) FROM sales) = :sales_before
                       AND (SELECT sum(stock_qty) FROM medicines) = :total_stock_before,
                           'after the four invalid sales, sales and medicines are unchanged');

\echo '--- (d) trigger ---'
SELECT count(*) AS audit_before FROM stock_audit \gset
UPDATE medicines SET stock_qty = stock_qty WHERE medicine_id = 2;          -- no real change
SELECT pg_temp.assert_true((SELECT count(*) FROM stock_audit) = :audit_before,
                           'stock set to the same value: no audit row');
UPDATE medicines SET stock_qty = stock_qty + 50 WHERE medicine_id = 2;     -- restock
SELECT pg_temp.assert_true(
         (SELECT new_qty - old_qty = 50 FROM stock_audit ORDER BY audit_id DESC LIMIT 1),
         'restock of 50 audited with correct OLD and NEW quantities');
SELECT * FROM stock_audit ORDER BY audit_id;

\echo '--- (e) view ---'
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_low_stock WHERE remaining_stock >= 10),
                           'v_low_stock lists only stock below 10');
SELECT pg_temp.assert_true(
         (SELECT count(*) FROM v_low_stock) = (SELECT count(*) FROM medicines WHERE stock_qty < 10),
         'v_low_stock lists every medicine below 10');
SELECT * FROM v_low_stock ORDER BY medicine_id;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes
                                   WHERE schemaname = 'q01_pharmacy'
                                     AND indexname  = 'idx_sales_medicine_sold_on'),
                           'idx_sales_medicine_sold_on exists');

\echo '--- (g) pr_refresh_sales rerun behaviour ---'
CALL pr_refresh_sales(CURRENT_DATE);
CALL pr_refresh_sales(CURRENT_DATE);
CALL pr_refresh_sales(CURRENT_DATE);
SELECT pg_temp.assert_true((SELECT count(*) FROM daily_sales WHERE sales_date = CURRENT_DATE) = 1,
                           'three runs for the same day keep exactly one row');
SELECT pg_temp.assert_true(
         (SELECT total_qty = (SELECT sum(quantity) FROM sales WHERE sold_on = CURRENT_DATE)
             AND total_amount = (SELECT sum(quantity * unit_price) FROM sales WHERE sold_on = CURRENT_DATE)
          FROM daily_sales WHERE sales_date = CURRENT_DATE),
         'totals equal the real sales for the day (not double-counted)');
CALL pr_record_sale(1, 1, CURRENT_DATE);   -- a late sale
CALL pr_refresh_sales(CURRENT_DATE);
SELECT pg_temp.assert_true(
         (SELECT total_qty = (SELECT sum(quantity) FROM sales WHERE sold_on = CURRENT_DATE)
          FROM daily_sales WHERE sales_date = CURRENT_DATE),
         'rerun after a new sale replaces the totals with the new correct value');
CALL pr_refresh_sales(CURRENT_DATE - 30);
SELECT pg_temp.assert_true(
         (SELECT total_qty = 0 AND total_amount = 0 FROM daily_sales WHERE sales_date = CURRENT_DATE - 30),
         'a day with no sales is stored as zeros');
SELECT pg_temp.expect_error('CALL pr_refresh_sales(NULL)', 'NULL day rejected');
SELECT * FROM daily_sales ORDER BY sales_date;

\echo '=== Question 1: all tests passed ==='

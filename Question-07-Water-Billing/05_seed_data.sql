-- =====================================================================
-- Question 7 (a) Seed data: three customers and six readings covering
-- ZERO, EXACTLY 10 and ABOVE 10 units. M2 = the month two months ago,
-- M1 = last month.
--   reading 1  customer 1  M2  100.00 -> 100.00   0 units    -> K0.00
--   reading 2  customer 1  M1  100.00 -> 110.00  10 units    -> K50.00
--   reading 3  customer 2  M2  200.00 -> 215.00  15 units    -> K90.00
--   reading 4  customer 2  M1  215.00 -> 240.00  25 units    -> K170.00
--   reading 5  customer 3  M2   50.00 ->  57.00   7 units    -> K35.00
--   reading 6  customer 3  M1   57.00 ->  67.50  10.5 units  -> K54.00
-- Every reading is billed through pr_generate_bill. M2 bills are past
-- due; M1 bills fall due in 10 days. Some payments are recorded.
-- =====================================================================
SET search_path TO q07_water_billing;

INSERT INTO customers (full_name) VALUES
    ('Kapembwa Mutale'),   -- 1
    ('Linda Mwenya'),      -- 2
    ('Moses Kangwa');      -- 3

INSERT INTO readings (customer_id, reading_month, previous_reading, current_reading) VALUES
    (1, (date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')::date, 100.00, 100.00),
    (1, (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date,  100.00, 110.00),
    (2, (date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')::date, 200.00, 215.00),
    (2, (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date,  215.00, 240.00),
    (3, (date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')::date,  50.00,  57.00),
    (3, (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date,   57.00,  67.50);

CALL pr_generate_bill(1, CURRENT_DATE - 20);
CALL pr_generate_bill(2, CURRENT_DATE + 10);
CALL pr_generate_bill(3, CURRENT_DATE - 20);
CALL pr_generate_bill(4, CURRENT_DATE + 10);
CALL pr_generate_bill(5, CURRENT_DATE - 20);
CALL pr_generate_bill(6, CURRENT_DATE + 10);

-- payments: bill 3 part-paid (K40 of K90), bill 5 fully paid (K35)
UPDATE bills SET amount_paid = 40.00 WHERE bill_id = 3;
UPDATE bills SET amount_paid = 35.00 WHERE bill_id = 5;

SELECT r.reading_id, c.full_name, r.reading_month, r.previous_reading, r.current_reading,
       r.current_reading - r.previous_reading AS units,
       b.bill_id, b.charge, b.amount_paid, b.due_on
FROM readings r
JOIN customers c ON c.customer_id = r.customer_id
LEFT JOIN bills b ON b.reading_id = r.reading_id
ORDER BY r.reading_id;

-- =====================================================================
-- Question 1 (a) Seed data
-- Four medicines are inserted directly. The six sales are loaded
-- THROUGH the completed procedure pr_record_sale, so each price is taken
-- from medicines, stock is deducted and the trigger audits every change.
-- Dates are relative to CURRENT_DATE so the data stays meaningful
-- whenever the script is run.
-- =====================================================================
SET search_path TO q01_pharmacy;

INSERT INTO medicines (medicine_name, unit_price, stock_qty) VALUES
    ('Paracetamol 500mg (pack of 10)', 2.50, 200),   -- id 1
    ('Amoxicillin 250mg (pack of 15)', 8.75,  60),   -- id 2
    ('Cough Syrup 100ml',             25.00,  15),   -- id 3
    ('Oral Rehydration Salts sachet',  3.00,  12);   -- id 4

CALL pr_record_sale(1, 20, CURRENT_DATE - 2);
CALL pr_record_sale(2,  5, CURRENT_DATE - 2);
CALL pr_record_sale(3,  4, CURRENT_DATE - 1);
CALL pr_record_sale(1, 15, CURRENT_DATE - 1);
CALL pr_record_sale(4,  3, CURRENT_DATE - 1);
CALL pr_record_sale(2, 10, CURRENT_DATE);

SELECT * FROM medicines   ORDER BY medicine_id;
SELECT * FROM sales       ORDER BY sale_id;
SELECT * FROM stock_audit ORDER BY audit_id;

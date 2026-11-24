-- =====================================================================
-- Question 1 (e) View v_low_stock: each medicine whose stock_qty is
-- below 10, with its name, price and remaining stock.
-- =====================================================================
SET search_path TO q01_pharmacy;

CREATE OR REPLACE VIEW v_low_stock AS
SELECT medicine_id,
       medicine_name,
       unit_price,
       stock_qty AS remaining_stock
FROM medicines
WHERE stock_qty < 10;

-- Query the view after a sale.
-- Before: Cough Syrup has 11 in stock, so it is not listed.
SELECT * FROM v_low_stock ORDER BY medicine_id;

-- Sell 2 bottles: stock falls to 9, which is below 10.
CALL pr_record_sale(3, 2, CURRENT_DATE);

-- After: Cough Syrup now appears in the view.
SELECT * FROM v_low_stock ORDER BY medicine_id;

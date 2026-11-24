-- =====================================================================
-- Question 9 (e) View v_farmer_amount_due
-- Each farmer's number, name and total UNPAID delivery value. The LEFT
-- JOIN keeps farmers with no deliveries, and COALESCE plus the FILTER
-- clause show K0.00 for farmers with no unpaid deliveries.
-- =====================================================================
SET search_path TO q09_maize;

CREATE OR REPLACE VIEW v_farmer_amount_due AS
SELECT f.farmer_number,
       f.full_name,
       COALESCE(SUM(d.total_value) FILTER (WHERE NOT d.is_paid), 0.00) AS amount_due
FROM farmers f
LEFT JOIN deliveries d ON d.farmer_id = f.farmer_id
GROUP BY f.farmer_id, f.farmer_number, f.full_name;

SELECT * FROM v_farmer_amount_due ORDER BY farmer_number;

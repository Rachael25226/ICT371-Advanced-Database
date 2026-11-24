-- =====================================================================
-- Question 7 (e) View v_overdue_bills
-- Customer name, due date and outstanding amount for bills whose due_on
-- is before CURRENT_DATE and which are not fully paid.
-- =====================================================================
SET search_path TO q07_water_billing;

CREATE OR REPLACE VIEW v_overdue_bills AS
SELECT b.bill_id,
       c.full_name,
       b.due_on,
       b.charge - b.amount_paid AS outstanding_amount
FROM bills b
JOIN readings  r ON r.reading_id  = b.reading_id
JOIN customers c ON c.customer_id = r.customer_id
WHERE b.due_on < CURRENT_DATE
  AND b.amount_paid < b.charge;

SELECT * FROM v_overdue_bills ORDER BY due_on, bill_id;

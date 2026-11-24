-- =====================================================================
-- Question 9 (a) Seed data: three farmers and six deliveries covering all
-- grades and both payment states, loaded AFTER the trigger is installed.
-- Deliveries come in through pr_receive_delivery (is_paid = false, the
-- trigger prices them); some are then marked as paid.
--   1  farmer 1  A  500.00 kg  CD-2  K2,500.00  unpaid
--   2  farmer 1  B  300.00 kg  CD-1  K1,200.00  unpaid
--   3  farmer 2  C  400.00 kg  CD-2  K1,200.00  PAID
--   4  farmer 2  A  250.50 kg  CD-1  K1,252.50  unpaid
--   5  farmer 3  B  200.00 kg  CD-2    K800.00  PAID
--   6  farmer 3  C  150.00 kg  CD-1    K450.00  PAID
-- Farmer 3 therefore has no unpaid deliveries (amount due K0).
-- =====================================================================
SET search_path TO q09_maize;

INSERT INTO farmers (farmer_number, full_name) VALUES
    ('FC-1001', 'Rhoda Mwanza'),     -- 1
    ('FC-1002', 'Stephen Lungu'),    -- 2
    ('FC-1003', 'Theresa Kabwe');    -- 3

CALL pr_receive_delivery(1, 'A', 500.00, CURRENT_DATE - 2);
CALL pr_receive_delivery(1, 'B', 300.00, CURRENT_DATE - 1);
CALL pr_receive_delivery(2, 'C', 400.00, CURRENT_DATE - 2);
CALL pr_receive_delivery(2, 'A', 250.50, CURRENT_DATE - 1);
CALL pr_receive_delivery(3, 'B', 200.00, CURRENT_DATE - 2);
CALL pr_receive_delivery(3, 'C', 150.00, CURRENT_DATE - 1);

UPDATE deliveries SET is_paid = true WHERE delivery_id IN (3, 5, 6);

SELECT d.delivery_id, f.farmer_number, d.grade, d.weight_kg, d.unit_rate,
       d.total_value, d.delivered_on, d.is_paid
FROM deliveries d JOIN farmers f ON f.farmer_id = d.farmer_id
ORDER BY d.delivery_id;

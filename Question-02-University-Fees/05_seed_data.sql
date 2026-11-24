-- =====================================================================
-- Question 2 (a) Seed data
-- Three students with different fees. Six payments are received through
-- pr_receive_payment (so each is validated and audited by the trigger):
--   student 1  fee 15 000, pays 5 000 + 4 000 + 3 000  -> balance 3 000
--   student 2  fee 12 000, pays 4 000 + 4 000 + 4 000  -> balance 0 (settled)
--   student 3  fee  9 000, no payments                -> balance 9 000
-- =====================================================================
SET search_path TO q02_university_fees;

INSERT INTO students (student_number, full_name, fee_due) VALUES
    ('2024-0001', 'Chanda Mwila',   15000.00),   -- id 1
    ('2024-0002', 'Bwalya Phiri',   12000.00),   -- id 2
    ('2024-0003', 'Mutale Banda',    9000.00);   -- id 3 (no payments)

CALL pr_receive_payment(1, 5000.00, CURRENT_DATE - 3);
CALL pr_receive_payment(2, 4000.00, CURRENT_DATE - 3);
CALL pr_receive_payment(1, 4000.00, CURRENT_DATE - 2);
CALL pr_receive_payment(2, 4000.00, CURRENT_DATE - 1);
CALL pr_receive_payment(1, 3000.00, CURRENT_DATE - 1);
CALL pr_receive_payment(2, 4000.00, CURRENT_DATE - 1);

SELECT s.student_id, s.student_number, s.full_name, s.fee_due,
       fn_fee_balance(s.student_id) AS balance
FROM students s
ORDER BY s.student_id;

SELECT * FROM payments      ORDER BY payment_id;
SELECT * FROM payment_audit ORDER BY audit_id;

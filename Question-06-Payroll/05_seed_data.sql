-- =====================================================================
-- Question 6 (a) Seed data: active and inactive employees and payroll
-- data for two months.
--   1. four employees, all active;
--   2. payroll processed for the month two months ago (4 rows);
--   3. employee 1 gets a salary increase (audited by the trigger);
--   4. employee 4 leaves (active = false);
--   5. payroll processed for last month (3 rows - employee 4 excluded).
-- Employee 4's earlier payroll row remains as history.
-- =====================================================================
SET search_path TO q06_payroll;

INSERT INTO employees (full_name, basic_salary, allowance, deduction, active) VALUES
    ('Lombe Chibwe',    8500.00, 1500.00, 1200.00, true),   -- 1
    ('Mwansa Kaoma',    6200.00,  800.00,  900.00, true),   -- 2
    ('Namakau Inonge',  9800.00, 2000.00, 1650.00, true),   -- 3
    ('Owen Simukonda',  5400.00,  600.00,  700.00, true);   -- 4

CALL pr_process_payroll((date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')::date);

UPDATE employees SET basic_salary = 9000.00 WHERE employee_id = 1;   -- pay rise
UPDATE employees SET active = false        WHERE employee_id = 4;    -- leaves

CALL pr_process_payroll((date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date);

SELECT * FROM employees    ORDER BY employee_id;
SELECT * FROM payroll      ORDER BY pay_month, employee_id;
SELECT * FROM salary_audit ORDER BY audit_id;

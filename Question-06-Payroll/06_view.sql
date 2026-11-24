-- =====================================================================
-- Question 6 (e) View v_payroll_report
-- Joins employee names to pay_month, gross_pay and net_pay. The view
-- does NOT filter on employees.active, so historical payroll rows for
-- employees who later became inactive are still reported.
-- =====================================================================
SET search_path TO q06_payroll;

CREATE OR REPLACE VIEW v_payroll_report AS
SELECT p.payroll_id,
       e.employee_id,
       e.full_name,
       p.pay_month,
       p.gross_pay,
       p.net_pay
FROM payroll p
JOIN employees e ON e.employee_id = p.employee_id;

SELECT * FROM v_payroll_report ORDER BY pay_month, employee_id;

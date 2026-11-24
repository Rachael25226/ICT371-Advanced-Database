-- =====================================================================
-- Question 6 (f) Index for a report filtered by pay_month across all
-- employees.
--
-- Justification:
--   The UNIQUE (employee_id, pay_month) constraint already created a
--   B-tree index whose LEADING column is employee_id. A B-tree can only
--   seek efficiently on its leading column, so that index cannot jump to
--   "all rows for October" - it would have to scan every employee.
--   A separate single-column index on pay_month serves the monthly report
--   directly. It is not a duplicate: it has a different leading column
--   and supports a different query. (An index on (employee_id, pay_month)
--   again WOULD duplicate the unique index and is deliberately avoided.)
-- =====================================================================
SET search_path TO q06_payroll;

CREATE INDEX idx_payroll_pay_month ON payroll (pay_month);
ANALYZE payroll;

-- Existing indexes on payroll: primary key, unique employee/month, new one
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'q06_payroll' AND tablename = 'payroll'
ORDER BY indexname;

-- Matching report query and plan on the seed data
EXPLAIN
SELECT employee_id, gross_pay, net_pay
FROM payroll
WHERE pay_month = (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date;

-- Same query with sequential scans disabled for this transaction only
BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN
SELECT employee_id, gross_pay, net_pay
FROM payroll
WHERE pay_month = (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date;
ROLLBACK;

# Question 6: Monthly Payroll Processing

Schema: `q06_payroll`. Tables: `employees`, `payroll` (with `UNIQUE (employee_id, pay_month)`), `salary_audit`.

Gross pay is basic salary plus allowance. Net pay is gross pay minus deduction.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | Non-negative CHECKs on salary, allowance and deduction; `active boolean`; `CHECK (pay_month = date_trunc('month', pay_month)::date)`. Four employees. Payroll is processed for the month two months ago; then employee 4 becomes inactive and last month is processed. That gives two months of data and a historical row for an inactive employee. |
| (b) | 6 | `02_function.sql` | `fn_net_pay(p_employee_id)` returns `basic_salary + allowance - deduction` from the current values. Rejects an unknown employee and a negative result. |
| (c) | 8 | `03_procedure.sql` | `pr_process_payroll(p_month)` requires a month-start date and loops over active employees with a query `FOR` loop. Each row is inserted with `ON CONFLICT (employee_id, pay_month) DO NOTHING`, so existing rows stay unchanged. `fn_net_pay`'s exception is not caught, so one invalid employee fails and rolls back the whole call. |
| (d) | 8 | `04_trigger.sql` | `trg_employees_salary_audit`: `AFTER UPDATE … WHEN (OLD.basic_salary IS DISTINCT FROM NEW.basic_salary)` logs the old and new salary. |
| (e) | 5 | `06_view.sql` | `v_payroll_report`: employee name with pay month, gross and net pay. There is no filter on `active`, so inactive employees' history is included. |
| (f) | 5 | `07_index.sql` | `idx_payroll_pay_month (pay_month)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | Scheduled `'0 2 1 * *'` (02:00 on the 1st of each month), calling `pr_process_payroll((date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date)`. Includes queries on `cron.job` and `cron.job_run_details` to inspect the job and its run history. |

## Index justification (f)
The unique constraint's index leads with `employee_id`, so it cannot seek on `pay_month` alone. A monthly report for all employees needs `pay_month` as the leading column. A single-column index on `pay_month` serves that query without duplicating the existing `(employee_id, pay_month)` index (checked by a test).

## Tests
27 checks, all passing. The tests cover:
- the CHECK and UNIQUE constraints;
- net pay from current values;
- an unknown employee and a negative net pay rejected;
- a non-month-start date rejected;
- an invalid employee aborting the whole run, with no rows kept for the valid employees processed before it;
- one row per active employee;
- a rerun adding nothing and leaving existing rows unchanged after a salary rise;
- audit rows only for real salary changes;
- inactive employees' history in the report;
- no duplicate index;
- the previous-month expression across a year end.

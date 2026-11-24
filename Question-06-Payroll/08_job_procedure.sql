-- =====================================================================
-- Question 6 (g) The scheduled job calls pr_process_payroll from (c);
-- no separate procedure is needed. The expression the job passes - the
-- first date of the PREVIOUS month - is:
--     (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date
-- Rerun behaviour: existing employee/month rows are left unchanged, so
-- running the job again (or by hand) never duplicates or alters payroll.
-- =====================================================================
SET search_path TO q06_payroll;

SELECT (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date AS month_the_job_will_process;

-- run it twice by hand: the second run inserts nothing
SELECT count(*) AS payroll_rows_before FROM payroll;
CALL pr_process_payroll((date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date);
CALL pr_process_payroll((date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date);
SELECT count(*) AS payroll_rows_after FROM payroll;

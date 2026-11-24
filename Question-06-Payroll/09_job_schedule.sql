-- =====================================================================
-- Question 6 (g) Schedule with pg_cron: 02:00 on the FIRST day of each
-- month, passing the first date of the PREVIOUS month.
-- Cron '0 2 1 * *' = minute 0, hour 2, day-of-month 1, every month.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q06_process_payroll',
    '0 2 1 * *',
    $$CALL q06_payroll.pr_process_payroll((date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date)$$
);

-- How to inspect the job
SELECT jobid, jobname, schedule, command, database, username, active
FROM cron.job
WHERE jobname = 'q06_process_payroll';

-- How to inspect its run history (one row per execution: status is
-- 'starting', 'running', 'succeeded' or 'failed', with any error text)
SELECT d.runid, d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q06_process_payroll'
ORDER BY d.start_time DESC
LIMIT 12;

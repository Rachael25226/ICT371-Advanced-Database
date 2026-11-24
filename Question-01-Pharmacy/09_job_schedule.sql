-- =====================================================================
-- Question 1 (g) Schedule with pg_cron: every day at 00:15, refresh the
-- PREVIOUS day's totals.
-- Cron fields: minute hour day-of-month month day-of-week.
-- Scheduling again under the same job name updates the existing job, so
-- running this file twice does not create a second job.
-- pg_cron uses the server time zone (GMT unless cron.timezone is set).
-- =====================================================================
SELECT cron.schedule(
    'q01_refresh_sales',
    '15 0 * * *',
    $$CALL q01_pharmacy.pr_refresh_sales(CURRENT_DATE - 1)$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q01_refresh_sales';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q01_refresh_sales'
ORDER BY d.start_time DESC
LIMIT 10;

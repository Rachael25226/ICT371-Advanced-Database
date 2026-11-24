-- =====================================================================
-- Question 9 (g) Schedule with pg_cron: daily at 01:30 for the PREVIOUS day.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q09_refresh_purchases',
    '30 1 * * *',
    $$CALL q09_maize.pr_refresh_purchases(CURRENT_DATE - 1)$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q09_refresh_purchases';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q09_refresh_purchases'
ORDER BY d.start_time DESC
LIMIT 10;

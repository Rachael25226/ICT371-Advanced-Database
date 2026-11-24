-- =====================================================================
-- Question 7 (g) Schedule with pg_cron: daily at 00:30.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q07_refresh_receivables',
    '30 0 * * *',
    $$CALL q07_water_billing.pr_refresh_receivables()$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q07_refresh_receivables';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q07_refresh_receivables'
ORDER BY d.start_time DESC
LIMIT 10;

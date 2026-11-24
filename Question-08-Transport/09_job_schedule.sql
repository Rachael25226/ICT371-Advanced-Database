-- =====================================================================
-- Question 8 (g) Schedule with pg_cron: every Monday at 06:00.
-- Cron '0 6 * * 1' = minute 0, hour 6, any day-of-month, any month,
-- day-of-week 1 (Monday; 0 = Sunday).
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q08_refresh_service_alerts',
    '0 6 * * 1',
    $$CALL q08_transport.pr_refresh_service_alerts()$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q08_refresh_service_alerts';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q08_refresh_service_alerts'
ORDER BY d.start_time DESC
LIMIT 10;

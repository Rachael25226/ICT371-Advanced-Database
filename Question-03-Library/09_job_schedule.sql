-- =====================================================================
-- Question 3 (g) Schedule with pg_cron: daily at 00:10 for CURRENT_DATE.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q03_refresh_overdue',
    '10 0 * * *',
    $$CALL q03_library.pr_refresh_overdue(CURRENT_DATE)$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q03_refresh_overdue';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q03_refresh_overdue'
ORDER BY d.start_time DESC
LIMIT 10;

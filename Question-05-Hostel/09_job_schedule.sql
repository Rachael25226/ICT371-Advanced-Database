-- =====================================================================
-- Question 5 (g) Schedule with pg_cron: daily at 23:55.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q05_refresh_occupancy',
    '55 23 * * *',
    $$CALL q05_hostel.pr_refresh_occupancy()$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q05_refresh_occupancy';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q05_refresh_occupancy'
ORDER BY d.start_time DESC
LIMIT 10;

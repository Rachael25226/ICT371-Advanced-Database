-- =====================================================================
-- Question 2 (g) Schedule with pg_cron: daily at 01:00 for the PREVIOUS day.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q02_refresh_collections',
    '0 1 * * *',
    $$CALL q02_university_fees.pr_refresh_collections(CURRENT_DATE - 1)$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q02_refresh_collections';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q02_refresh_collections'
ORDER BY d.start_time DESC
LIMIT 10;

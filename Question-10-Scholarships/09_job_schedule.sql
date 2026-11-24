-- =====================================================================
-- Question 10 (g) Schedule with pg_cron: every Monday at 08:00.
-- Cron '0 8 * * 1' = minute 0, hour 8, day-of-week 1 (Monday).
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q10_assess_pending',
    '0 8 * * 1',
    $$CALL q10_scholarships.pr_assess_pending()$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q10_assess_pending';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q10_assess_pending'
ORDER BY d.start_time DESC
LIMIT 10;

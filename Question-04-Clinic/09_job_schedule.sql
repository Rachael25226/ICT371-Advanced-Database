-- =====================================================================
-- Question 4 (g) Schedule with pg_cron: daily at 01:00 for the PREVIOUS day.
-- Re-scheduling under the same job name updates the existing job.
-- =====================================================================
SELECT cron.schedule(
    'q04_refresh_clinic_summary',
    '0 1 * * *',
    $$CALL q04_clinic.pr_refresh_clinic_summary(CURRENT_DATE - 1)$$
);

-- Inspect the job
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'q04_refresh_clinic_summary';

-- Inspect its run history
SELECT d.jobid, d.status, d.return_message, d.start_time, d.end_time
FROM cron.job_run_details d
JOIN cron.job j ON j.jobid = d.jobid
WHERE j.jobname = 'q04_refresh_clinic_summary'
ORDER BY d.start_time DESC
LIMIT 10;

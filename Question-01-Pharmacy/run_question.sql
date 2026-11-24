-- =====================================================================
-- Question 1 - run every script in the correct order.
--   psql -U postgres -d ict371 -v ON_ERROR_STOP=1 -f run_question.sql
-- (run from inside this folder, or from the repository root through
--  run_all.sql - \ir resolves paths relative to this file)
-- =====================================================================
\echo '================ Question 1 - Pharmacy Stock and Daily Sales ================'
\ir 01_tables.sql
\ir 02_function.sql
\ir 03_procedure.sql
\ir 04_trigger.sql
\ir 05_seed_data.sql
\ir 06_view.sql
\ir 07_index.sql
\ir 08_job_procedure.sql
SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') AS has_pg_cron \gset
\if :has_pg_cron
\ir 09_job_schedule.sql
\else
\echo 'NOTE: pg_cron is not installed in this database - 09_job_schedule.sql was skipped.'
\endif
\ir 10_tests.sql

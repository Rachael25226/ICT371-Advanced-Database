-- =====================================================================
-- ICT371 - OPTIONAL: enable pg_cron for the (g) scheduled jobs.
-- Prerequisites (postgresql.conf, then restart PostgreSQL):
--     shared_preload_libraries = 'pg_cron'
--     cron.database_name       = 'ict371'
-- Then run while connected to ict371:
--     psql -U postgres -d ict371 -f setup/01_enable_pg_cron.sql
-- If pg_cron is not installed, skip this file: every question still
-- builds and tests completely; only the cron.schedule() step is skipped.
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_cron';

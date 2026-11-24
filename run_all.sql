-- =====================================================================
-- ICT371 Advanced Database - build and test all ten questions.
-- First create the database (once):
--     psql -U postgres -d postgres -f setup/00_create_database.sql
-- Then, from the repository root:
--     psql -U postgres -d ict371 -v ON_ERROR_STOP=1 -f run_all.sql
-- Each question rebuilds its own schema from scratch, so this file can
-- be run again at any time.
-- =====================================================================
\ir Question-01-Pharmacy/run_question.sql
\ir Question-02-University-Fees/run_question.sql
\ir Question-03-Library/run_question.sql
\ir Question-04-Clinic/run_question.sql
\ir Question-05-Hostel/run_question.sql
\ir Question-06-Payroll/run_question.sql
\ir Question-07-Water-Billing/run_question.sql
\ir Question-08-Transport/run_question.sql
\ir Question-09-Maize-Deliveries/run_question.sql
\ir Question-10-Scholarships/run_question.sql
\echo '=============== ALL TEN QUESTIONS BUILT AND TESTED SUCCESSFULLY ==============='

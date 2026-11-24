-- =====================================================================
-- ICT371 Advanced Database - environment setup
-- Run while connected to the default "postgres" database:
--     psql -U postgres -d postgres -f setup/00_create_database.sql
-- Creates a clean database called ict371. Each question is then built
-- in its own schema inside this database (q01_pharmacy ... q10_scholarships)
-- because several questions reuse table names such as "students".
-- =====================================================================
DROP DATABASE IF EXISTS ict371;
CREATE DATABASE ict371;

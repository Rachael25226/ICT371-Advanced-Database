-- =====================================================================
-- Question 7 - Water Meter Readings and Billing
-- (a) Database: tables and constraints
--   * meter values are non-negative numerics;
--   * reading_month must be the first date of a month;
--   * one reading per customer per month;
--   * one bill per reading; amount_paid between zero and the charge.
-- "current_reading >= previous_reading" is enforced by the BEFORE
-- INSERT OR UPDATE trigger in (d), as the question requires.
-- =====================================================================
DROP SCHEMA IF EXISTS q07_water_billing CASCADE;
CREATE SCHEMA q07_water_billing;
SET search_path TO q07_water_billing;

CREATE TABLE customers (
    customer_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    varchar(100) NOT NULL
);

CREATE TABLE readings (
    reading_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id       integer       NOT NULL REFERENCES customers (customer_id),
    reading_month     date          NOT NULL
                      CONSTRAINT chk_readings_month_start CHECK (reading_month = date_trunc('month', reading_month)::date),
    previous_reading  numeric(12,2) NOT NULL
                      CONSTRAINT chk_readings_previous_non_negative CHECK (previous_reading >= 0),
    current_reading   numeric(12,2) NOT NULL
                      CONSTRAINT chk_readings_current_non_negative  CHECK (current_reading >= 0),
    CONSTRAINT uq_readings_customer_month UNIQUE (customer_id, reading_month)
);

CREATE TABLE bills (
    bill_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reading_id   integer       NOT NULL UNIQUE REFERENCES readings (reading_id),
    charge       numeric(12,2) NOT NULL CHECK (charge >= 0),
    amount_paid  numeric(12,2) NOT NULL DEFAULT 0,
    due_on       date          NOT NULL,
    CONSTRAINT chk_bills_amount_paid_range CHECK (amount_paid BETWEEN 0 AND charge)
);

CREATE TABLE receivable_snapshot (
    snapshot_date  date          PRIMARY KEY,
    total_due      numeric(14,2) NOT NULL CHECK (total_due >= 0)
);

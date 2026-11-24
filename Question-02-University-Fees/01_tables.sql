-- =====================================================================
-- Question 2 - University Fee Payments
-- (a) Database: tables and constraints
-- (PostgreSQL folds unquoted identifiers to lower case, so the PDF's
--  "Students" and "Payments" are created as students and payments.)
-- Credit balances are not allowed: the payment procedure (c) refuses any
-- payment larger than the outstanding balance.
-- =====================================================================
DROP SCHEMA IF EXISTS q02_university_fees CASCADE;
CREATE SCHEMA q02_university_fees;
SET search_path TO q02_university_fees;

CREATE TABLE students (
    student_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_number  varchar(20)   NOT NULL UNIQUE,
    full_name       varchar(100)  NOT NULL,
    fee_due         numeric(12,2) NOT NULL
                    CONSTRAINT chk_students_fee_due_non_negative CHECK (fee_due >= 0)
);

CREATE TABLE payments (
    payment_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id  integer       NOT NULL REFERENCES students (student_id),
    amount      numeric(12,2) NOT NULL
                CONSTRAINT chk_payments_amount_positive CHECK (amount > 0),
    paid_on     date          NOT NULL
);

CREATE TABLE payment_audit (
    audit_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id  integer       NOT NULL UNIQUE REFERENCES payments (payment_id),
    student_id  integer       NOT NULL REFERENCES students (student_id),
    amount      numeric(12,2) NOT NULL,
    logged_at   timestamptz   NOT NULL DEFAULT now()
);

CREATE TABLE daily_collections (
    collection_date  date          PRIMARY KEY,
    payment_count    integer       NOT NULL CHECK (payment_count >= 0),
    total_amount     numeric(14,2) NOT NULL CHECK (total_amount >= 0)
);

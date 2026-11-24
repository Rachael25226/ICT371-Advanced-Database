-- =====================================================================
-- Question 10 - Scholarship Application Assessment
-- (a) Database: tables and constraints
--   * monthly income non-negative, age positive, marks 0 to 100;
--   * status is PENDING, APPROVED or REJECTED.
-- Eligibility (fictional scheme): age 18-25 inclusive, monthly household
-- income at most K3,000 and average mark at least 70.
-- =====================================================================
DROP SCHEMA IF EXISTS q10_scholarships CASCADE;
CREATE SCHEMA q10_scholarships;
SET search_path TO q10_scholarships;

CREATE TABLE students (
    student_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_number  varchar(20)  NOT NULL UNIQUE,
    full_name       varchar(100) NOT NULL
);

CREATE TABLE applications (
    application_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id          integer       NOT NULL REFERENCES students (student_id),
    age_at_application  integer       NOT NULL
                        CONSTRAINT chk_applications_age_positive CHECK (age_at_application > 0),
    monthly_income      numeric(12,2) NOT NULL
                        CONSTRAINT chk_applications_income_non_negative CHECK (monthly_income >= 0),
    average_mark        numeric(5,2)  NOT NULL
                        CONSTRAINT chk_applications_mark_range CHECK (average_mark BETWEEN 0 AND 100),
    submitted_on        date          NOT NULL DEFAULT CURRENT_DATE,
    status              varchar(8)    NOT NULL DEFAULT 'PENDING'
                        CONSTRAINT chk_applications_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE TABLE decision_audit (
    audit_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id  integer     NOT NULL REFERENCES applications (application_id),
    old_status      varchar(8)  NOT NULL,
    new_status      varchar(8)  NOT NULL,
    changed_at      timestamptz NOT NULL DEFAULT now()
);

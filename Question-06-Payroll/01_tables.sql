-- =====================================================================
-- Question 6 - Monthly Payroll Processing
-- (a) Database: tables and constraints
--   gross pay = basic salary + allowance
--   net pay   = gross pay - fixed deduction
-- Money inputs are non-negative; active is boolean; pay_month must be
-- the first date of a month; one payroll row per employee per month.
-- =====================================================================
DROP SCHEMA IF EXISTS q06_payroll CASCADE;
CREATE SCHEMA q06_payroll;
SET search_path TO q06_payroll;

CREATE TABLE employees (
    employee_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     varchar(100)  NOT NULL,
    basic_salary  numeric(12,2) NOT NULL CONSTRAINT chk_employees_salary_non_negative    CHECK (basic_salary >= 0),
    allowance     numeric(12,2) NOT NULL DEFAULT 0
                                CONSTRAINT chk_employees_allowance_non_negative CHECK (allowance >= 0),
    deduction     numeric(12,2) NOT NULL DEFAULT 0
                                CONSTRAINT chk_employees_deduction_non_negative CHECK (deduction >= 0),
    active        boolean       NOT NULL DEFAULT true
);

CREATE TABLE payroll (
    payroll_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id  integer       NOT NULL REFERENCES employees (employee_id),
    pay_month    date          NOT NULL
                 CONSTRAINT chk_payroll_month_start CHECK (pay_month = date_trunc('month', pay_month)::date),
    gross_pay    numeric(12,2) NOT NULL CHECK (gross_pay >= 0),
    net_pay      numeric(12,2) NOT NULL CHECK (net_pay >= 0),
    CONSTRAINT uq_payroll_employee_month UNIQUE (employee_id, pay_month)
);

CREATE TABLE salary_audit (
    audit_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id  integer       NOT NULL REFERENCES employees (employee_id),
    old_salary   numeric(12,2) NOT NULL,
    new_salary   numeric(12,2) NOT NULL,
    changed_at   timestamptz   NOT NULL DEFAULT now()
);

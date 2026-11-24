-- =====================================================================
-- Question 3 - Library Returns and Overdue Fines
-- (a) Database: tables and constraints
-- Fine rule: K2 for each day after due_on; returning ON the due date
-- costs nothing; a returned loan stops accumulating fines.
-- =====================================================================
DROP SCHEMA IF EXISTS q03_library CASCADE;
CREATE SCHEMA q03_library;
SET search_path TO q03_library;

CREATE TABLE books (
    book_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title    varchar(200) NOT NULL
);

CREATE TABLE loans (
    loan_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id        integer       NOT NULL REFERENCES books (book_id),
    borrower_name  varchar(100)  NOT NULL,
    borrowed_on    date          NOT NULL,
    due_on         date          NOT NULL,
    returned_on    date          NULL,
    fine_amount    numeric(10,2) NOT NULL DEFAULT 0
                   CONSTRAINT chk_loans_fine_non_negative CHECK (fine_amount >= 0),
    CONSTRAINT chk_loans_due_after_borrowed     CHECK (due_on >= borrowed_on),
    CONSTRAINT chk_loans_return_after_borrowed  CHECK (returned_on IS NULL OR returned_on >= borrowed_on)
);

CREATE TABLE loan_audit (
    audit_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loan_id          integer     NOT NULL REFERENCES loans (loan_id),
    old_returned_on  date        NULL,
    new_returned_on  date        NULL,
    changed_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE overdue_summary (
    snapshot_date  date          PRIMARY KEY,
    overdue_count  integer       NOT NULL CHECK (overdue_count >= 0),
    total_fine     numeric(12,2) NOT NULL CHECK (total_fine >= 0)
);

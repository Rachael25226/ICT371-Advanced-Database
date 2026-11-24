-- =====================================================================
-- Question 3 (d) AFTER UPDATE row trigger on loans.
-- Logs changes to returned_on in loan_audit using OLD and NEW.
-- IS DISTINCT FROM treats NULL correctly (NULL -> date is a change,
-- NULL -> NULL is not), so no audit row is created when the date is
-- unchanged - e.g. when only the fine or borrower name is updated.
-- =====================================================================
SET search_path TO q03_library;

CREATE OR REPLACE FUNCTION fn_trg_loans_return_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.returned_on IS DISTINCT FROM OLD.returned_on THEN
        INSERT INTO loan_audit (loan_id, old_returned_on, new_returned_on, changed_at)
        VALUES (NEW.loan_id, OLD.returned_on, NEW.returned_on, now());
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_loans_return_audit
AFTER UPDATE ON loans
FOR EACH ROW
WHEN (OLD.returned_on IS DISTINCT FROM NEW.returned_on)
EXECUTE FUNCTION fn_trg_loans_return_audit();

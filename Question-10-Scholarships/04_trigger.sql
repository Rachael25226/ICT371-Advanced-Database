-- =====================================================================
-- Question 10 (d) AFTER UPDATE row trigger on applications.
-- Records ACTUAL status changes in decision_audit with the OLD status,
-- the NEW status and a timestamp. An update that leaves the status
-- unchanged creates no audit entry.
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE OR REPLACE FUNCTION fn_trg_applications_decision_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO decision_audit (application_id, old_status, new_status, changed_at)
        VALUES (NEW.application_id, OLD.status, NEW.status, now());
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_applications_decision_audit
AFTER UPDATE ON applications
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION fn_trg_applications_decision_audit();

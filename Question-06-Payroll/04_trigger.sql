-- =====================================================================
-- Question 6 (d) AFTER UPDATE row trigger on employees.
-- Logs an ACTUAL basic_salary change (OLD and NEW values) in
-- salary_audit. Updates that leave basic_salary unchanged - e.g.
-- changing the allowance or deactivating the employee - produce no entry.
-- =====================================================================
SET search_path TO q06_payroll;

CREATE OR REPLACE FUNCTION fn_trg_employees_salary_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.basic_salary IS DISTINCT FROM OLD.basic_salary THEN
        INSERT INTO salary_audit (employee_id, old_salary, new_salary, changed_at)
        VALUES (NEW.employee_id, OLD.basic_salary, NEW.basic_salary, now());
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_employees_salary_audit
AFTER UPDATE ON employees
FOR EACH ROW
WHEN (OLD.basic_salary IS DISTINCT FROM NEW.basic_salary)
EXECUTE FUNCTION fn_trg_employees_salary_audit();

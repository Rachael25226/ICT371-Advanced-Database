-- =====================================================================
-- Question 6 (b) Function fn_net_pay(p_employee_id)
-- Returns net pay from the employee's CURRENT basic salary, allowance and
-- deduction: (basic_salary + allowance) - deduction.
-- Rejects an unknown employee and a negative computed net pay.
-- =====================================================================
SET search_path TO q06_payroll;

CREATE OR REPLACE FUNCTION fn_net_pay(p_employee_id integer)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_emp  employees%ROWTYPE;
    v_net  numeric;
BEGIN
    SELECT * INTO v_emp
    FROM employees
    WHERE employee_id = p_employee_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown employee_id %', p_employee_id;
    END IF;

    v_net := (v_emp.basic_salary + v_emp.allowance) - v_emp.deduction;

    IF v_net < 0 THEN
        RAISE EXCEPTION 'Negative net pay % for employee %: deduction % exceeds gross pay %',
              v_net, p_employee_id, v_emp.deduction, v_emp.basic_salary + v_emp.allowance;
    END IF;

    RETURN v_net;
END;
$$;

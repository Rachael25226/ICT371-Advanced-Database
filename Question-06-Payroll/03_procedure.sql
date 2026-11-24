-- =====================================================================
-- Question 6 (c) Procedure pr_process_payroll(p_month)
--   * requires a month-start date (e.g. 2026-10-01);
--   * uses a query FOR loop over ACTIVE employees;
--   * inserts each MISSING employee/month payroll row;
--   * leaves an existing row unchanged (ON CONFLICT ... DO NOTHING on the
--     employee/month unique key), so a month can be processed again safely;
--   * any invalid employee calculation (fn_net_pay raises for a negative
--     net pay) is not caught, so the exception aborts the WHOLE call and
--     every row inserted earlier in the loop is rolled back.
-- SET search_path lets pg_cron run it (see 09_job_schedule.sql).
-- =====================================================================
SET search_path TO q06_payroll;

CREATE OR REPLACE PROCEDURE pr_process_payroll(p_month date)
LANGUAGE plpgsql
SET search_path = q06_payroll, pg_temp
AS $$
DECLARE
    r      record;
    v_net  numeric;
BEGIN
    IF p_month IS NULL OR p_month <> date_trunc('month', p_month)::date THEN
        RAISE EXCEPTION 'Invalid pay month %: p_month must be the first date of a month', p_month;
    END IF;

    FOR r IN
        SELECT employee_id, basic_salary, allowance
        FROM employees
        WHERE active
        ORDER BY employee_id
    LOOP
        v_net := fn_net_pay(r.employee_id);      -- raises on an invalid calculation

        INSERT INTO payroll (employee_id, pay_month, gross_pay, net_pay)
        VALUES (r.employee_id, p_month, r.basic_salary + r.allowance, v_net)
        ON CONFLICT (employee_id, pay_month) DO NOTHING;
    END LOOP;
END;
$$;

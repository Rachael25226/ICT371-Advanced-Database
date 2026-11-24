-- =====================================================================
-- Question 2 (b) Function fn_fee_balance(p_student_id)
-- Returns fee_due minus total payments. COALESCE returns the full fee
-- when the student has no payments. An unknown student is rejected.
-- =====================================================================
SET search_path TO q02_university_fees;

CREATE OR REPLACE FUNCTION fn_fee_balance(p_student_id integer)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_fee_due  students.fee_due%TYPE;
    v_paid     numeric;
BEGIN
    SELECT fee_due INTO v_fee_due
    FROM students
    WHERE student_id = p_student_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown student_id %', p_student_id;
    END IF;

    SELECT COALESCE(SUM(amount), 0) INTO v_paid
    FROM payments
    WHERE student_id = p_student_id;

    RETURN v_fee_due - v_paid;
END;
$$;

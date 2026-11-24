-- =====================================================================
-- Question 2 (c) Procedure pr_receive_payment(p_student_id, p_amount, p_paid_on)
--   * rejects NULL, zero or negative amounts;
--   * rejects an unknown student and a missing payment date;
--   * rejects a payment above the outstanding balance (no credit balances);
--   * inserts a valid payment WITHOUT changing students.fee_due.
-- The student row is locked (FOR UPDATE) so two concurrent payments for
-- the same student cannot both pass the balance check.
-- The audit row is NOT written here - the AFTER INSERT trigger (d) does it.
-- =====================================================================
SET search_path TO q02_university_fees;

CREATE OR REPLACE PROCEDURE pr_receive_payment(p_student_id integer,
                                               p_amount     numeric,
                                               p_paid_on    date)
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance numeric;
BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Invalid payment amount %: amount must be greater than zero', p_amount;
    END IF;

    IF p_paid_on IS NULL THEN
        RAISE EXCEPTION 'Payment date (p_paid_on) is required';
    END IF;

    PERFORM 1 FROM students WHERE student_id = p_student_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown student_id %', p_student_id;
    END IF;

    v_balance := fn_fee_balance(p_student_id);

    IF p_amount > v_balance THEN
        RAISE EXCEPTION 'Payment of % exceeds the outstanding balance of % for student % (credit balances are not allowed)',
              p_amount, v_balance, p_student_id;
    END IF;

    INSERT INTO payments (student_id, amount, paid_on)
    VALUES (p_student_id, p_amount, p_paid_on);
END;
$$;

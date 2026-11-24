-- =====================================================================
-- Question 3 (c) Procedure pr_return_loan(p_loan_id, p_returned_on)
--   * rejects an unknown loan, an already returned loan, a missing return
--     date and a return date before borrowed_on;
--   * calculates the final fine with fn_loan_fine as of the return date;
--   * stores returned_on and fine_amount TOGETHER in one UPDATE.
-- The loan row is locked (FOR UPDATE) so the same loan cannot be
-- returned twice by concurrent sessions.
-- =====================================================================
SET search_path TO q03_library;

CREATE OR REPLACE PROCEDURE pr_return_loan(p_loan_id integer, p_returned_on date)
LANGUAGE plpgsql
AS $$
DECLARE
    v_borrowed  loans.borrowed_on%TYPE;
    v_returned  loans.returned_on%TYPE;
    v_fine      numeric;
BEGIN
    IF p_returned_on IS NULL THEN
        RAISE EXCEPTION 'Return date (p_returned_on) is required';
    END IF;

    SELECT borrowed_on, returned_on INTO v_borrowed, v_returned
    FROM loans
    WHERE loan_id = p_loan_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown loan_id %', p_loan_id;
    END IF;

    IF v_returned IS NOT NULL THEN
        RAISE EXCEPTION 'Loan % was already returned on %', p_loan_id, v_returned;
    END IF;

    IF p_returned_on < v_borrowed THEN
        RAISE EXCEPTION 'Return date % is before the borrow date % for loan %',
              p_returned_on, v_borrowed, p_loan_id;
    END IF;

    -- loan is still open, so the fine is measured up to the return date
    v_fine := fn_loan_fine(p_loan_id, p_returned_on);

    UPDATE loans
       SET returned_on = p_returned_on,
           fine_amount = v_fine
     WHERE loan_id = p_loan_id;
END;
$$;

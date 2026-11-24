-- =====================================================================
-- Question 3 (b) Function fn_loan_fine(p_loan_id, p_as_of)
-- Returns K2 x overdue days, never below zero.
-- The fine is measured up to p_as_of, or up to returned_on if the loan
-- was returned earlier than p_as_of (the earlier of the two dates), so a
-- returned loan stops accumulating fines. An unknown loan is rejected.
-- =====================================================================
SET search_path TO q03_library;

CREATE OR REPLACE FUNCTION fn_loan_fine(p_loan_id integer, p_as_of date)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_due       loans.due_on%TYPE;
    v_returned  loans.returned_on%TYPE;
    v_end       date;
BEGIN
    IF p_as_of IS NULL THEN
        RAISE EXCEPTION 'p_as_of date is required';
    END IF;

    SELECT due_on, returned_on INTO v_due, v_returned
    FROM loans
    WHERE loan_id = p_loan_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown loan_id %', p_loan_id;
    END IF;

    IF v_returned IS NOT NULL THEN
        v_end := LEAST(p_as_of, v_returned);
    ELSE
        v_end := p_as_of;
    END IF;

    -- date - date gives whole days; GREATEST(..., 0) gives the minimum of zero
    RETURN 2.00 * GREATEST(v_end - v_due, 0);
END;
$$;

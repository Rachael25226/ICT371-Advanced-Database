-- =====================================================================
-- Question 2 (d) AFTER INSERT row trigger on payments.
-- Automatically writes the payment ID, student ID, amount and a
-- timestamp to payment_audit for every new payment, whether it comes
-- from pr_receive_payment or from direct SQL.
-- =====================================================================
SET search_path TO q02_university_fees;

CREATE OR REPLACE FUNCTION fn_trg_payments_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO payment_audit (payment_id, student_id, amount, logged_at)
    VALUES (NEW.payment_id, NEW.student_id, NEW.amount, now());
    RETURN NULL;   -- ignored for AFTER row triggers
END;
$$;

CREATE TRIGGER trg_payments_audit
AFTER INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION fn_trg_payments_audit();

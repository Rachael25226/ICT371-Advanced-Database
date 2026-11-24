-- =====================================================================
-- Question 1 (d) AFTER UPDATE row trigger on medicines.
-- Records the OLD and NEW stock_qty in stock_audit only when stock_qty
-- actually changes. IS DISTINCT FROM is used so the comparison is also
-- NULL-safe. Updating only the price or name produces no audit row.
-- =====================================================================
SET search_path TO q01_pharmacy;

CREATE OR REPLACE FUNCTION fn_trg_medicines_stock_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stock_qty IS DISTINCT FROM OLD.stock_qty THEN
        INSERT INTO stock_audit (medicine_id, old_qty, new_qty, changed_at)
        VALUES (NEW.medicine_id, OLD.stock_qty, NEW.stock_qty, now());
    END IF;
    RETURN NULL;   -- the return value of an AFTER row trigger is ignored
END;
$$;

CREATE TRIGGER trg_medicines_stock_audit
AFTER UPDATE ON medicines
FOR EACH ROW
WHEN (OLD.stock_qty IS DISTINCT FROM NEW.stock_qty)
EXECUTE FUNCTION fn_trg_medicines_stock_audit();

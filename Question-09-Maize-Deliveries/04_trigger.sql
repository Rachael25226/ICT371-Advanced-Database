-- =====================================================================
-- Question 9 (d) BEFORE INSERT OR UPDATE row trigger on deliveries.
--   * rejects a missing or non-positive weight;
--   * calls fn_maize_rate (which also rejects an unsupported grade);
--   * sets NEW.unit_rate and NEW.total_value = weight x rate.
-- Any unit_rate / total_value supplied by direct SQL is overwritten, so
-- every insert and update follows the same pricing rule.
-- =====================================================================
SET search_path TO q09_maize;

CREATE OR REPLACE FUNCTION fn_trg_deliveries_pricing()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.weight_kg IS NULL OR NEW.weight_kg <= 0 THEN
        RAISE EXCEPTION 'Invalid weight %: weight must be greater than zero', NEW.weight_kg;
    END IF;

    NEW.grade       := upper(trim(NEW.grade));
    NEW.unit_rate   := fn_maize_rate(NEW.grade);
    NEW.total_value := round(NEW.weight_kg * NEW.unit_rate, 2);

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_deliveries_pricing
BEFORE INSERT OR UPDATE ON deliveries
FOR EACH ROW
EXECUTE FUNCTION fn_trg_deliveries_pricing();

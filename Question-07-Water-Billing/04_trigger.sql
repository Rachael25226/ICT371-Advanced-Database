-- =====================================================================
-- Question 7 (d) BEFORE INSERT OR UPDATE row trigger on readings.
-- Rejects current_reading below previous_reading for every change,
-- including direct SQL imports. Raising an exception in a BEFORE trigger
-- aborts the statement, so a rejected reading is never stored.
-- =====================================================================
SET search_path TO q07_water_billing;

CREATE OR REPLACE FUNCTION fn_trg_readings_validate()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.current_reading < NEW.previous_reading THEN
        RAISE EXCEPTION 'Invalid meter reading for customer % (%): current % is below previous %',
              NEW.customer_id, NEW.reading_month, NEW.current_reading, NEW.previous_reading;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_readings_validate
BEFORE INSERT OR UPDATE ON readings
FOR EACH ROW
EXECUTE FUNCTION fn_trg_readings_validate();

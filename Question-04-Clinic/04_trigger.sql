-- =====================================================================
-- Question 4 (d) BEFORE INSERT OR UPDATE row trigger on appointments.
-- Rejects a clash: another NON-cancelled appointment for the same
-- doctor, date and slot. On UPDATE the row being changed is excluded
-- from the search (appointment_id <> OLD.appointment_id), so an
-- appointment never clashes with itself (e.g. BOOKED -> ATTENDED).
-- A row whose new status is CANCELLED never clashes.
-- pg_advisory_xact_lock serialises bookings for the same doctor and day,
-- so two concurrent transactions cannot both pass the check.
-- =====================================================================
SET search_path TO q04_clinic;

CREATE OR REPLACE FUNCTION fn_trg_appointments_no_clash()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status <> 'CANCELLED' THEN
        PERFORM pg_advisory_xact_lock(NEW.doctor_id, NEW.appointment_day - DATE '2000-01-01');

        IF EXISTS (
            SELECT 1
            FROM appointments a
            WHERE a.doctor_id       = NEW.doctor_id
              AND a.appointment_day = NEW.appointment_day
              AND a.slot_time       = NEW.slot_time
              AND a.status         <> 'CANCELLED'
              AND (TG_OP = 'INSERT' OR a.appointment_id <> OLD.appointment_id)
        ) THEN
            RAISE EXCEPTION 'Slot clash: doctor % already has a non-cancelled appointment on % at %',
                  NEW.doctor_id, NEW.appointment_day, NEW.slot_time;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_appointments_no_clash
BEFORE INSERT OR UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION fn_trg_appointments_no_clash();

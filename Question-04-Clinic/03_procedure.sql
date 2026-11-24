-- =====================================================================
-- Question 4 (c) Procedure pr_book_appointment(p_patient_id, p_doctor_id, p_day, p_slot)
--   * validates the patient and doctor IDs;
--   * rejects a missing or past date;
--   * rejects a slot other than 09:00, 10:00, 11:00 or 12:00;
--   * inserts a BOOKED appointment.
-- A clash with another non-cancelled appointment is rejected by the
-- BEFORE INSERT OR UPDATE trigger (d), which also protects direct SQL.
-- =====================================================================
SET search_path TO q04_clinic;

CREATE OR REPLACE PROCEDURE pr_book_appointment(p_patient_id integer,
                                                p_doctor_id  integer,
                                                p_day        date,
                                                p_slot       time)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM patients WHERE patient_id = p_patient_id) THEN
        RAISE EXCEPTION 'Unknown patient_id %', p_patient_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM doctors WHERE doctor_id = p_doctor_id) THEN
        RAISE EXCEPTION 'Unknown doctor_id %', p_doctor_id;
    END IF;

    IF p_day IS NULL OR p_day < CURRENT_DATE THEN
        RAISE EXCEPTION 'Invalid appointment date %: a past date cannot be booked', p_day;
    END IF;

    IF p_slot IS NULL OR p_slot NOT IN (TIME '09:00', TIME '10:00', TIME '11:00', TIME '12:00') THEN
        RAISE EXCEPTION 'Unsupported slot %: choose 09:00, 10:00, 11:00 or 12:00', p_slot;
    END IF;

    INSERT INTO appointments (patient_id, doctor_id, appointment_day, slot_time, status)
    VALUES (p_patient_id, p_doctor_id, p_day, p_slot, 'BOOKED');
END;
$$;

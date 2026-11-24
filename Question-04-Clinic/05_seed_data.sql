-- =====================================================================
-- Question 4 (a) Seed data: three patients, three doctors and six
-- appointments that respect the slot rule.
-- Yesterday's appointments are historical (ATTENDED / CANCELLED), so
-- they are inserted directly - the trigger still checks them for clashes.
-- Appointment 3 uses the same doctor/date/slot as the CANCELLED
-- appointment 2, which is allowed because cancelled rows do not occupy
-- a slot. Today's and tomorrow's appointments are booked through
-- pr_book_appointment.
-- =====================================================================
SET search_path TO q04_clinic;

INSERT INTO patients (full_name) VALUES
    ('Alice Mulenga'),     -- 1
    ('Brian Kunda'),       -- 2
    ('Charity Mumba');     -- 3

INSERT INTO doctors (full_name) VALUES
    ('Dr. Esther Ngoma'),  -- 1
    ('Dr. Felix Mwansa'),  -- 2
    ('Dr. Ruth Chanda');   -- 3

INSERT INTO appointments (patient_id, doctor_id, appointment_day, slot_time, status) VALUES
    (1, 1, CURRENT_DATE - 1, '09:00', 'ATTENDED'),    -- 1
    (2, 1, CURRENT_DATE - 1, '10:00', 'CANCELLED'),   -- 2
    (3, 1, CURRENT_DATE - 1, '10:00', 'ATTENDED');    -- 3 (same slot as cancelled 2)

CALL pr_book_appointment(2, 1, CURRENT_DATE,     '09:00');   -- 4
CALL pr_book_appointment(3, 2, CURRENT_DATE,     '11:00');   -- 5
CALL pr_book_appointment(1, 3, CURRENT_DATE + 1, '12:00');   -- 6

SELECT a.appointment_id, p.full_name AS patient, d.full_name AS doctor,
       a.appointment_day, a.slot_time, a.status
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN doctors  d ON d.doctor_id  = a.doctor_id
ORDER BY a.appointment_id;

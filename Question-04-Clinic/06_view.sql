-- =====================================================================
-- Question 4 (e) View v_today_appointments
-- Today's BOOKED appointments with patient name, doctor name and slot.
-- Only those columns are exposed - no patient IDs or other patient data,
-- and no appointments for other days or other statuses.
-- =====================================================================
SET search_path TO q04_clinic;

CREATE OR REPLACE VIEW v_today_appointments AS
SELECT a.slot_time,
       p.full_name AS patient_name,
       d.full_name AS doctor_name
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN doctors  d ON d.doctor_id  = a.doctor_id
WHERE a.appointment_day = CURRENT_DATE
  AND a.status = 'BOOKED';

SELECT * FROM v_today_appointments ORDER BY slot_time, doctor_name;

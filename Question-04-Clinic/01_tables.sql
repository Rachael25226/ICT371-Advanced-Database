-- =====================================================================
-- Question 4 - Clinic Appointment Scheduling
-- (a) Database: tables and constraints
-- Each doctor has four slots per day: 09:00, 10:00, 11:00, 12:00.
-- slot_time uses the time type; status is BOOKED, ATTENDED or CANCELLED.
-- The "no two non-cancelled appointments in the same doctor/date/slot"
-- rule is enforced by the BEFORE INSERT OR UPDATE trigger in (d).
-- =====================================================================
DROP SCHEMA IF EXISTS q04_clinic CASCADE;
CREATE SCHEMA q04_clinic;
SET search_path TO q04_clinic;

CREATE TABLE patients (
    patient_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   varchar(100) NOT NULL
);

CREATE TABLE doctors (
    doctor_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name  varchar(100) NOT NULL
);

CREATE TABLE appointments (
    appointment_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id       integer     NOT NULL REFERENCES patients (patient_id),
    doctor_id        integer     NOT NULL REFERENCES doctors (doctor_id),
    appointment_day  date        NOT NULL,
    slot_time        time        NOT NULL
                     CONSTRAINT chk_appointments_slot
                     CHECK (slot_time IN (TIME '09:00', TIME '10:00', TIME '11:00', TIME '12:00')),
    status           varchar(10) NOT NULL DEFAULT 'BOOKED'
                     CONSTRAINT chk_appointments_status
                     CHECK (status IN ('BOOKED', 'ATTENDED', 'CANCELLED'))
);

CREATE TABLE clinic_summary (
    summary_date     date    PRIMARY KEY,
    booked_count     integer NOT NULL CHECK (booked_count >= 0),
    attended_count   integer NOT NULL CHECK (attended_count >= 0),
    cancelled_count  integer NOT NULL CHECK (cancelled_count >= 0)
);

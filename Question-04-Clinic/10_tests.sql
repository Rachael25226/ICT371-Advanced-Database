-- =====================================================================
-- Question 4 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q04_clinic;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    IF p_ok IS TRUE THEN RETURN 'PASS: ' || p_label; END IF;
    RAISE EXCEPTION 'FAIL: %', p_label;
END $$;

CREATE OR REPLACE FUNCTION pg_temp.expect_error(p_sql text, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'PASS: ' || p_label || '  [rejected: ' || SQLERRM || ']';
    END;
    RAISE EXCEPTION 'FAIL: % (statement was accepted)', p_label;
END $$;

\echo '--- (a) constraints and seed data ---'
SELECT pg_temp.expect_error($q$INSERT INTO appointments (patient_id, doctor_id, appointment_day, slot_time, status) VALUES (1, 2, CURRENT_DATE + 5, '09:00', 'NOSHOW')$q$,
                            'status outside BOOKED/ATTENDED/CANCELLED rejected');
SELECT pg_temp.expect_error($q$INSERT INTO appointments (patient_id, doctor_id, appointment_day, slot_time) VALUES (1, 2, CURRENT_DATE + 5, '13:00')$q$,
                            'unsupported slot rejected by CHECK on direct insert');
SELECT pg_temp.assert_true((SELECT count(*) FROM patients) = 3 AND (SELECT count(*) FROM doctors) = 3
                       AND (SELECT count(*) FROM appointments) = 6,
                           'three patients, three doctors, six appointments');
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT doctor_id, appointment_day, slot_time FROM appointments
         WHERE status <> 'CANCELLED'
         GROUP BY doctor_id, appointment_day, slot_time HAVING count(*) > 1),
         'seed data contains no slot clash');

\echo '--- (b) fn_daily_load ---'
SELECT pg_temp.assert_true(fn_daily_load(1, CURRENT_DATE - 1) = 2, 'doctor 1 yesterday: 2 (cancelled appointment not counted)');
SELECT pg_temp.assert_true(fn_daily_load(1, CURRENT_DATE) = 1,     'doctor 1 today: 1');
SELECT pg_temp.assert_true(fn_daily_load(2, CURRENT_DATE + 30) = 0, 'a day with no bookings returns 0');
SELECT pg_temp.expect_error('SELECT fn_daily_load(99, CURRENT_DATE)', 'unknown doctor rejected');

\echo '--- (c) pr_book_appointment ---'
SELECT count(*) AS appt_before FROM appointments \gset
SELECT pg_temp.expect_error($q$CALL pr_book_appointment(99, 1, CURRENT_DATE + 2, '09:00')$q$, 'unknown patient rejected');
SELECT pg_temp.expect_error($q$CALL pr_book_appointment(1, 99, CURRENT_DATE + 2, '09:00')$q$, 'unknown doctor rejected');
SELECT pg_temp.expect_error($q$CALL pr_book_appointment(1, 1, CURRENT_DATE - 1, '11:00')$q$, 'past date rejected');
SELECT pg_temp.expect_error($q$CALL pr_book_appointment(1, 1, CURRENT_DATE + 2, '09:30')$q$, 'unsupported slot 09:30 rejected');
SELECT pg_temp.expect_error($q$CALL pr_book_appointment(1, 1, CURRENT_DATE + 2, '14:00')$q$, 'unsupported slot 14:00 rejected');
SELECT pg_temp.expect_error($q$CALL pr_book_appointment(3, 1, CURRENT_DATE, '09:00')$q$,     'clash with appointment 4 rejected (by the trigger)');
SELECT pg_temp.assert_true((SELECT count(*) FROM appointments) = :appt_before, 'no row stored by the rejected bookings');
CALL pr_book_appointment(1, 1, CURRENT_DATE + 2, '10:00');
SELECT pg_temp.assert_true((SELECT status = 'BOOKED' FROM appointments ORDER BY appointment_id DESC LIMIT 1),
                           'valid booking inserted with status BOOKED');

\echo '--- (d) trigger ---'
SELECT pg_temp.expect_error($q$INSERT INTO appointments (patient_id, doctor_id, appointment_day, slot_time) VALUES (1, 2, CURRENT_DATE, '11:00')$q$,
                            'direct SQL insert clashing with appointment 5 rejected');
SELECT pg_temp.expect_error($q$UPDATE appointments SET doctor_id = 1, slot_time = '09:00' WHERE appointment_id = 5$q$,
                            'UPDATE moving appointment 5 onto doctor 1 09:00 today rejected');
SELECT pg_temp.expect_error($q$UPDATE appointments SET status = 'BOOKED' WHERE appointment_id = 2$q$,
                            'un-cancelling appointment 2 into the slot now used by appointment 3 rejected');
UPDATE appointments SET status = 'ATTENDED' WHERE appointment_id = 4;
SELECT pg_temp.assert_true((SELECT status FROM appointments WHERE appointment_id = 4) = 'ATTENDED',
                           'UPDATE of the same appointment does not clash with itself');
UPDATE appointments SET status = 'BOOKED' WHERE appointment_id = 4;
INSERT INTO appointments (patient_id, doctor_id, appointment_day, slot_time, status)
VALUES (2, 2, CURRENT_DATE, '11:00', 'CANCELLED');
SELECT pg_temp.assert_true(true, 'a CANCELLED row may share a slot with a booked appointment');
UPDATE appointments SET status = 'CANCELLED' WHERE appointment_id = 5;
CALL pr_book_appointment(2, 2, CURRENT_DATE, '11:00');
SELECT pg_temp.assert_true((SELECT count(*) FROM appointments
                            WHERE doctor_id = 2 AND appointment_day = CURRENT_DATE
                              AND slot_time = '11:00' AND status = 'BOOKED') = 1,
                           'after cancellation the slot can be booked again');

\echo '--- (e) view ---'
SELECT pg_temp.assert_true((SELECT count(*) FROM v_today_appointments) =
                           (SELECT count(*) FROM appointments WHERE appointment_day = CURRENT_DATE AND status = 'BOOKED'),
                           'view shows exactly today''s BOOKED appointments');
SELECT pg_temp.assert_true(
         (SELECT array_agg(column_name::text ORDER BY ordinal_position) FROM information_schema.columns
          WHERE table_schema = 'q04_clinic' AND table_name = 'v_today_appointments')
         = ARRAY['slot_time', 'patient_name', 'doctor_name'],
         'view exposes only slot, patient name and doctor name');
SELECT * FROM v_today_appointments ORDER BY slot_time, doctor_name;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q04_clinic'
                                     AND indexname = 'idx_appointments_day_doctor'
                                     AND indexdef NOT ILIKE '%UNIQUE%'),
                           'non-unique idx_appointments_day_doctor exists');

\echo '--- (g) pr_refresh_clinic_summary ---'
CALL pr_refresh_clinic_summary(CURRENT_DATE - 1);
CALL pr_refresh_clinic_summary(CURRENT_DATE - 1);
SELECT pg_temp.assert_true((SELECT count(*) FROM clinic_summary WHERE summary_date = CURRENT_DATE - 1) = 1,
                           'rerun keeps one row for the date');
SELECT pg_temp.assert_true((SELECT booked_count = 0 AND attended_count = 2 AND cancelled_count = 1
                            FROM clinic_summary WHERE summary_date = CURRENT_DATE - 1),
                           'yesterday: 0 booked, 2 attended, 1 cancelled');
CALL pr_refresh_clinic_summary(CURRENT_DATE);
UPDATE appointments SET status = 'ATTENDED' WHERE appointment_id = 4;
CALL pr_refresh_clinic_summary(CURRENT_DATE);
SELECT pg_temp.assert_true((SELECT booked_count = 1 AND attended_count = 1 AND cancelled_count = 2
                            FROM clinic_summary WHERE summary_date = CURRENT_DATE),
                           'rerun after a status change replaces today''s counts');
SELECT * FROM clinic_summary ORDER BY summary_date;

\echo '=== Question 4: all tests passed ==='

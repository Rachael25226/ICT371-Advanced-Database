-- =====================================================================
-- Question 8 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q08_transport;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    IF p_ok IS TRUE THEN RETURN 'PASS: ' || p_label; END IF;
    RAISE EXCEPTION 'FAIL: %', p_label;
END $$;

-- expect_error(sql, label, expected text in the error message)
CREATE OR REPLACE FUNCTION pg_temp.expect_error(p_sql text, p_label text, p_expect text)
RETURNS text LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        IF position(lower(p_expect) IN lower(SQLERRM)) = 0 THEN
            RAISE EXCEPTION 'FAIL: % (rejected for the wrong reason: %)', p_label, SQLERRM;
        END IF;
        RETURN 'PASS: ' || p_label || '  [rejected: ' || SQLERRM || ']';
    END;
    RAISE EXCEPTION 'FAIL: % (statement was accepted)', p_label;
END $$;

\echo '--- (a) constraints and seed data ---'
SELECT pg_temp.expect_error($q$INSERT INTO vehicles (registration, current_odometer, last_service_odometer) VALUES ('XYZ 9999', -1, 0)$q$,
                            'negative odometer rejected', 'chk_vehicles_current_non_negative');
SELECT pg_temp.expect_error($q$INSERT INTO vehicles (registration, current_odometer, last_service_odometer) VALUES ('XYZ 9999', 100, 200)$q$,
                            'last service beyond current odometer rejected', 'chk_vehicles_service_not_after_current');
SELECT pg_temp.expect_error($q$INSERT INTO vehicles (registration, current_odometer, last_service_odometer) VALUES ('ABC 1234', 0, 0)$q$,
                            'duplicate registration rejected', 'vehicles_registration_key');
SELECT pg_temp.assert_true((SELECT count(*) FROM vehicles) = 3 AND (SELECT count(*) FROM trips) = 6,
                           'three vehicles and six trips');
SELECT pg_temp.assert_true((SELECT count(DISTINCT current_odometer - last_service_odometer) FROM vehicles) = 3,
                           'vehicles are at different service positions');

\echo '--- (b) fn_service_due ---'
SELECT pg_temp.assert_true(fn_service_due(1) = false, 'vehicle 1 (2,600 km) not due');
SELECT pg_temp.assert_true(fn_service_due(2) = true,  'vehicle 2 (5,250 km) due');
SELECT pg_temp.assert_true(fn_service_due(3) = true,  'vehicle 3 (6,900 km) due');
SELECT pg_temp.expect_error('SELECT fn_service_due(99)', 'unknown vehicle rejected', 'Unknown vehicle_id');

\echo '--- (c) pr_record_trip ---'
SELECT count(*) AS trips_before, (SELECT current_odometer FROM vehicles WHERE vehicle_id = 1) AS odo1_before FROM trips \gset
SELECT pg_temp.expect_error('CALL pr_record_trip(99, CURRENT_DATE, 0, 10)',        'unknown vehicle rejected', 'Unknown vehicle_id');
SELECT pg_temp.expect_error('CALL pr_record_trip(1, CURRENT_DATE, 12600, 12600)',  'end equal to start rejected', 'must be greater');
SELECT pg_temp.expect_error('CALL pr_record_trip(1, CURRENT_DATE, 12600, 12500)',  'end below start rejected', 'must be greater');
SELECT pg_temp.expect_error('CALL pr_record_trip(1, NULL, 12600, 12700)',          'missing trip date rejected', 'Trip date');
SELECT pg_temp.expect_error('CALL pr_record_trip(1, CURRENT_DATE, 12000, 12100)',  'start not equal to current odometer rejected (by the trigger)', 'current odometer');
SELECT pg_temp.assert_true((SELECT count(*) FROM trips) = :trips_before
                       AND (SELECT current_odometer FROM vehicles WHERE vehicle_id = 1) = :odo1_before,
                           'rejected trips stored nothing and left the odometer unchanged');
SELECT pg_temp.assert_true(
         (SELECT prosrc NOT ILIKE '%UPDATE%vehicles%' FROM pg_proc
          WHERE proname = 'pr_record_trip' AND pronamespace = 'q08_transport'::regnamespace),
         'pr_record_trip contains no UPDATE of vehicles');

\echo '--- (d) trigger ---'
CALL pr_record_trip(1, CURRENT_DATE, 12600, 15000);
SELECT pg_temp.assert_true((SELECT current_odometer FROM vehicles WHERE vehicle_id = 1) = 15000,
                           'odometer moved to the trip end (15,000) - exactly once, not 15,000 + 2,400');
SELECT pg_temp.assert_true(fn_service_due(1) = true, 'vehicle 1 now exactly 5,000 km since service -> due (boundary)');
SELECT pg_temp.expect_error($q$INSERT INTO trips (vehicle_id, trip_on, start_odometer, end_odometer) VALUES (2, CURRENT_DATE, 55000, 55500)$q$,
                            'direct SQL trip starting at the wrong odometer rejected', 'current odometer');
SELECT pg_temp.expect_error($q$INSERT INTO trips (vehicle_id, trip_on, start_odometer, end_odometer) VALUES (2, CURRENT_DATE, 55250, 55200)$q$,
                            'direct SQL trip with invalid mileage rejected', 'Invalid mileage');
INSERT INTO trips (vehicle_id, trip_on, start_odometer, end_odometer) VALUES (2, CURRENT_DATE, 55250, 55400);
SELECT pg_temp.assert_true((SELECT current_odometer FROM vehicles WHERE vehicle_id = 2) = 55400,
                           'a valid direct SQL trip also updates the odometer');
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT 1 FROM (SELECT vehicle_id, start_odometer,
                               lag(end_odometer) OVER (PARTITION BY vehicle_id ORDER BY trip_id) AS prev_end
                        FROM trips) t
         WHERE prev_end IS NOT NULL AND start_odometer <> prev_end),
         'every trip starts exactly where the previous trip of that vehicle ended');

\echo '--- (e) view ---'
SELECT pg_temp.assert_true((SELECT array_agg(registration::text ORDER BY registration) FROM v_service_due)
                           = ARRAY['ABC 1234', 'BCD 2345', 'CDE 3456'],
                           'all three vehicles now meet the threshold');
UPDATE vehicles SET last_service_odometer = current_odometer WHERE vehicle_id = 2;   -- serviced
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_service_due WHERE vehicle_id = 2),
                           'a serviced vehicle leaves the view');
SELECT * FROM v_service_due ORDER BY registration;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q08_transport'
                                     AND indexname = 'idx_trips_vehicle_trip_on'),
                           'idx_trips_vehicle_trip_on exists');

\echo '--- (g) pr_refresh_service_alerts ---'
CALL pr_refresh_service_alerts();
CALL pr_refresh_service_alerts();
SELECT pg_temp.assert_true((SELECT array_agg(vehicle_id ORDER BY vehicle_id) FROM service_alerts) = ARRAY[1, 3],
                           'alerts for due vehicles 1 and 3 only; vehicle 2 alert removed after its service');
SELECT pg_temp.assert_true((SELECT count(*) FROM service_alerts) = (SELECT count(DISTINCT vehicle_id) FROM service_alerts),
                           'one alert per vehicle after reruns');
CALL pr_record_trip(3, CURRENT_DATE, 86900, 87000);
CALL pr_refresh_service_alerts();
SELECT pg_temp.assert_true((SELECT km_since_service FROM service_alerts WHERE vehicle_id = 3) = 7000,
                           'existing alert updated with the new distance (7,000 km)');
UPDATE vehicles SET last_service_odometer = current_odometer WHERE vehicle_id = 3;   -- serviced
CALL pr_refresh_service_alerts();
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM service_alerts WHERE vehicle_id = 3),
                           'alert removed once service makes vehicle 3 no longer due');
SELECT * FROM service_alerts ORDER BY vehicle_id;

\echo '=== Question 8: all tests passed ==='

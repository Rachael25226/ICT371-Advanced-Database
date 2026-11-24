-- =====================================================================
-- Question 5 - Automated tests ("PASS: ..." or the script stops on "FAIL: ...")
-- =====================================================================
SET search_path TO q05_hostel;

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
SELECT pg_temp.expect_error($q$INSERT INTO rooms (room_number, capacity) VALUES ('Z999', 0)$q$,
                            'zero capacity rejected');
SELECT pg_temp.expect_error($q$INSERT INTO allocations (student_id, room_id, allocated_on, released_on, status) VALUES (6, 3, CURRENT_DATE, CURRENT_DATE, 'ACTIVE')$q$,
                            'ACTIVE with a release date rejected');
SELECT pg_temp.expect_error($q$INSERT INTO allocations (student_id, room_id, allocated_on, released_on, status) VALUES (6, 3, CURRENT_DATE, NULL, 'ENDED')$q$,
                            'ENDED without a release date rejected');
SELECT pg_temp.expect_error($q$INSERT INTO allocations (student_id, room_id, allocated_on, status) VALUES (6, 3, CURRENT_DATE, 'MOVED')$q$,
                            'status other than ACTIVE/ENDED rejected');
SELECT pg_temp.assert_true((SELECT free_beds FROM v_room_occupancy WHERE room_number = 'A101') = 0,  'room A101 is full');
SELECT pg_temp.assert_true((SELECT occupied_beds FROM v_room_occupancy WHERE room_number = 'A102') BETWEEN 1 AND 2,
                           'room A102 is partly occupied');
SELECT pg_temp.assert_true((SELECT occupied_beds FROM v_room_occupancy WHERE room_number = 'B201') = 0, 'room B201 is empty');

\echo '--- (b) fn_free_beds ---'
SELECT pg_temp.assert_true(fn_free_beds(1) = 0, 'A101: 2 - 2 = 0');
SELECT pg_temp.assert_true(fn_free_beds(2) = 2, 'A102: 3 - 1 = 2 (the ENDED allocation does not count)');
SELECT pg_temp.assert_true(fn_free_beds(3) = 2, 'B201: 2 - 0 = 2 (ENDED history only)');
SELECT pg_temp.expect_error('SELECT fn_free_beds(99)', 'unknown room rejected');

\echo '--- (c) pr_allocate_room ---'
SELECT count(*) AS alloc_before FROM allocations \gset
SELECT pg_temp.expect_error('CALL pr_allocate_room(99, 2, CURRENT_DATE)', 'unknown student rejected');
SELECT pg_temp.expect_error('CALL pr_allocate_room(6, 99, CURRENT_DATE)', 'unknown room rejected');
SELECT pg_temp.expect_error('CALL pr_allocate_room(6, 1, CURRENT_DATE)',  'full room A101 rejected');
SELECT pg_temp.expect_error('CALL pr_allocate_room(1, 2, CURRENT_DATE)',  'student 1 already ACTIVE rejected');
SELECT pg_temp.expect_error('CALL pr_allocate_room(6, 2, NULL)',          'missing allocation date rejected');
SELECT pg_temp.assert_true((SELECT count(*) FROM allocations) = :alloc_before, 'no allocation stored by the rejected calls');
CALL pr_allocate_room(4, 3, CURRENT_DATE);   -- student 4 (ENDED history) returns, room B201
SELECT pg_temp.assert_true((SELECT status = 'ACTIVE' AND released_on IS NULL FROM allocations
                            ORDER BY allocation_id DESC LIMIT 1),
                           'student with only ENDED history gets one ACTIVE allocation, released_on NULL');

\echo '--- (d) trigger (direct SQL) ---'
SELECT pg_temp.expect_error($q$INSERT INTO allocations (student_id, room_id, allocated_on) VALUES (6, 1, CURRENT_DATE)$q$,
                            'direct insert into full room A101 rejected');
SELECT pg_temp.expect_error($q$INSERT INTO allocations (student_id, room_id, allocated_on) VALUES (3, 3, CURRENT_DATE)$q$,
                            'direct insert of a second ACTIVE allocation for student 3 rejected');
SELECT pg_temp.expect_error($q$UPDATE allocations SET room_id = 1 WHERE student_id = 3 AND status = 'ACTIVE'$q$,
                            'direct UPDATE moving student 3 into full room A101 rejected');
SELECT pg_temp.expect_error($q$UPDATE allocations SET status = 'ACTIVE', released_on = NULL WHERE student_id = 4 AND status = 'ENDED'$q$,
                            'reactivating student 4''s old ENDED allocation while student 4 is ACTIVE in B201 rejected');
UPDATE allocations SET allocated_on = allocated_on - 1 WHERE student_id = 1 AND status = 'ACTIVE';
SELECT pg_temp.assert_true(true, 'updating an ACTIVE allocation in a FULL room is allowed (row excluded from its own count)');
UPDATE allocations SET status = 'ENDED', released_on = CURRENT_DATE WHERE student_id = 2 AND status = 'ACTIVE';
INSERT INTO allocations (student_id, room_id, allocated_on) VALUES (6, 1, CURRENT_DATE);
SELECT pg_temp.assert_true(fn_free_beds(1) = 0, 'after a release, a direct insert may take the freed bed');

\echo '--- (e) view ---'
SELECT pg_temp.assert_true((SELECT count(*) FROM v_room_occupancy) = (SELECT count(*) FROM rooms),
                           'view lists every room');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM v_room_occupancy v WHERE v.free_beds <> fn_free_beds(v.room_id)),
                           'view free beds agree with fn_free_beds');
SELECT * FROM v_room_occupancy ORDER BY room_number;

\echo '--- (f) index ---'
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'q05_hostel'
                                     AND indexname = 'idx_allocations_active_room'),
                           'idx_allocations_active_room exists');

\echo '--- (g) pr_refresh_occupancy ---'
CALL pr_refresh_occupancy();
CALL pr_refresh_occupancy();
SELECT pg_temp.assert_true((SELECT count(*) FROM occupancy_snapshot WHERE snapshot_date = CURRENT_DATE) = (SELECT count(*) FROM rooms),
                           'one row per room for today after reruns');
SELECT pg_temp.assert_true(NOT EXISTS (
         SELECT 1 FROM occupancy_snapshot o JOIN v_room_occupancy v ON v.room_id = o.room_id
         WHERE o.snapshot_date = CURRENT_DATE
           AND (o.occupied_beds <> v.occupied_beds OR o.free_beds <> v.free_beds)),
         'snapshot values replaced with the current occupancy');
SELECT * FROM occupancy_snapshot ORDER BY snapshot_date, room_id;

\echo '=== Question 5: all tests passed ==='

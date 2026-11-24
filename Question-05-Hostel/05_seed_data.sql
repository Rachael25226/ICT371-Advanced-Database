-- =====================================================================
-- Question 5 (a) Seed data showing a FULL, a PARTLY OCCUPIED and an
-- EMPTY room:
--   A101 capacity 2 -> students 1 and 2 ACTIVE            = full
--   A102 capacity 3 -> student 3 ACTIVE, student 4 ENDED  = partly occupied
--   B201 capacity 2 -> student 5 ENDED only               = empty
--   student 6 has no allocation (available for testing)
-- Active allocations are made through pr_allocate_room; the ENDED ones
-- are allocated and then released (status ENDED + released_on).
-- =====================================================================
SET search_path TO q05_hostel;

INSERT INTO rooms (room_number, capacity) VALUES
    ('A101', 2),   -- 1
    ('A102', 3),   -- 2
    ('B201', 2);   -- 3

INSERT INTO students (student_number, full_name) VALUES
    ('H2025-001', 'Daniel Mubanga'),    -- 1
    ('H2025-002', 'Esther Kalaba'),     -- 2
    ('H2025-003', 'Francis Mwale'),     -- 3
    ('H2025-004', 'Gift Siame'),        -- 4
    ('H2025-005', 'Hope Nyirenda'),     -- 5
    ('H2025-006', 'Isaac Chisenga');    -- 6

CALL pr_allocate_room(1, 1, CURRENT_DATE - 60);
CALL pr_allocate_room(2, 1, CURRENT_DATE - 60);
CALL pr_allocate_room(3, 2, CURRENT_DATE - 45);
CALL pr_allocate_room(4, 2, CURRENT_DATE - 45);
CALL pr_allocate_room(5, 3, CURRENT_DATE - 30);

-- students 4 and 5 move out: their allocations become history
UPDATE allocations SET status = 'ENDED', released_on = CURRENT_DATE - 10 WHERE student_id = 4;
UPDATE allocations SET status = 'ENDED', released_on = CURRENT_DATE - 5  WHERE student_id = 5;

SELECT a.allocation_id, s.student_number, r.room_number, a.allocated_on, a.released_on, a.status
FROM allocations a
JOIN students s ON s.student_id = a.student_id
JOIN rooms    r ON r.room_id    = a.room_id
ORDER BY a.allocation_id;

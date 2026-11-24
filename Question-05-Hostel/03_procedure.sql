-- =====================================================================
-- Question 5 (c) Procedure pr_allocate_room(p_student_id, p_room_id, p_allocated_on)
--   * validates the student and room IDs and the allocation date;
--   * ensures the student has no ACTIVE allocation;
--   * checks availability with fn_free_beds;
--   * creates one ACTIVE allocation with released_on NULL.
-- The room and student rows are locked (FOR UPDATE) so concurrent calls
-- cannot overfill a room or give a student two beds.
-- =====================================================================
SET search_path TO q05_hostel;

CREATE OR REPLACE PROCEDURE pr_allocate_room(p_student_id   integer,
                                             p_room_id      integer,
                                             p_allocated_on date)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_allocated_on IS NULL THEN
        RAISE EXCEPTION 'Allocation date (p_allocated_on) is required';
    END IF;

    PERFORM 1 FROM students WHERE student_id = p_student_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown student_id %', p_student_id;
    END IF;

    PERFORM 1 FROM rooms WHERE room_id = p_room_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown room_id %', p_room_id;
    END IF;

    IF EXISTS (SELECT 1 FROM allocations
               WHERE student_id = p_student_id AND status = 'ACTIVE') THEN
        RAISE EXCEPTION 'Student % already has an ACTIVE allocation', p_student_id;
    END IF;

    IF fn_free_beds(p_room_id) <= 0 THEN
        RAISE EXCEPTION 'Room % is full', p_room_id;
    END IF;

    INSERT INTO allocations (student_id, room_id, allocated_on, released_on, status)
    VALUES (p_student_id, p_room_id, p_allocated_on, NULL, 'ACTIVE');
END;
$$;

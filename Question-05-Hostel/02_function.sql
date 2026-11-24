-- =====================================================================
-- Question 5 (b) Function fn_free_beds(p_room_id)
-- Returns room capacity minus the number of ACTIVE allocations in that
-- room. ENDED allocations are history and do not reduce availability.
-- An unknown room is rejected.
-- =====================================================================
SET search_path TO q05_hostel;

CREATE OR REPLACE FUNCTION fn_free_beds(p_room_id integer)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_capacity  rooms.capacity%TYPE;
    v_active    integer;
BEGIN
    SELECT capacity INTO v_capacity
    FROM rooms
    WHERE room_id = p_room_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown room_id %', p_room_id;
    END IF;

    SELECT COUNT(*) INTO v_active
    FROM allocations
    WHERE room_id = p_room_id
      AND status = 'ACTIVE';

    RETURN v_capacity - v_active;
END;
$$;

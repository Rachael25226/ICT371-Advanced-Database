-- =====================================================================
-- Question 5 (d) BEFORE INSERT OR UPDATE row trigger on allocations.
-- Enforces the same rules for direct SQL changes:
--   * room capacity is never exceeded by ACTIVE allocations;
--   * a student has at most one ACTIVE allocation.
-- Only rows whose NEW status is ACTIVE need checking (ENDED rows do not
-- occupy a bed). When counting OTHER allocations the row being updated
-- is excluded (allocation_id <> OLD.allocation_id), so updating an
-- active allocation does not count it against itself.
-- The room and student rows are locked to serialise concurrent changes.
-- =====================================================================
SET search_path TO q05_hostel;

CREATE OR REPLACE FUNCTION fn_trg_allocations_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacity      rooms.capacity%TYPE;
    v_other_active  integer;
BEGIN
    IF NEW.status = 'ACTIVE' THEN
        SELECT capacity INTO v_capacity
        FROM rooms
        WHERE room_id = NEW.room_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Unknown room_id %', NEW.room_id;
        END IF;

        PERFORM 1 FROM students WHERE student_id = NEW.student_id FOR UPDATE;

        -- capacity: other ACTIVE allocations already in this room
        SELECT COUNT(*) INTO v_other_active
        FROM allocations a
        WHERE a.room_id = NEW.room_id
          AND a.status  = 'ACTIVE'
          AND (TG_OP = 'INSERT' OR a.allocation_id <> OLD.allocation_id);

        IF v_other_active >= v_capacity THEN
            RAISE EXCEPTION 'Room % is full: capacity %, already % active allocation(s)',
                  NEW.room_id, v_capacity, v_other_active;
        END IF;

        -- one ACTIVE allocation per student
        IF EXISTS (
            SELECT 1
            FROM allocations a
            WHERE a.student_id = NEW.student_id
              AND a.status     = 'ACTIVE'
              AND (TG_OP = 'INSERT' OR a.allocation_id <> OLD.allocation_id)
        ) THEN
            RAISE EXCEPTION 'Student % already has an ACTIVE allocation', NEW.student_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_allocations_rules
BEFORE INSERT OR UPDATE ON allocations
FOR EACH ROW
EXECUTE FUNCTION fn_trg_allocations_rules();

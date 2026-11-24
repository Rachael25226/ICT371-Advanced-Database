-- =====================================================================
-- Question 5 (g) Procedure pr_refresh_occupancy()
-- Stores CURRENT_DATE occupancy for EVERY room (rooms with no
-- allocations included) in occupancy_snapshot. The primary key
-- (snapshot_date, room_id) gives one row per date and room, and
-- ON CONFLICT DO UPDATE replaces the values when the procedure is rerun.
-- =====================================================================
SET search_path TO q05_hostel;

CREATE OR REPLACE PROCEDURE pr_refresh_occupancy()
LANGUAGE plpgsql
SET search_path = q05_hostel, pg_temp
AS $$
BEGIN
    INSERT INTO occupancy_snapshot (snapshot_date, room_id, occupied_beds, free_beds)
    SELECT CURRENT_DATE,
           r.room_id,
           COUNT(a.allocation_id),
           r.capacity - COUNT(a.allocation_id)
    FROM rooms r
    LEFT JOIN allocations a
           ON a.room_id = r.room_id
          AND a.status  = 'ACTIVE'
    GROUP BY r.room_id, r.capacity
    ON CONFLICT (snapshot_date, room_id) DO UPDATE
        SET occupied_beds = EXCLUDED.occupied_beds,
            free_beds     = EXCLUDED.free_beds;
END;
$$;

CALL pr_refresh_occupancy();
SELECT * FROM occupancy_snapshot ORDER BY snapshot_date, room_id;

-- rerun: still one row per room for today
CALL pr_refresh_occupancy();
SELECT * FROM occupancy_snapshot ORDER BY snapshot_date, room_id;

-- =====================================================================
-- Question 5 (e) View v_room_occupancy
-- Every room with its capacity, occupied beds and free beds. The LEFT
-- JOIN (with the ACTIVE condition inside the ON clause) keeps rooms that
-- have no allocations or only ENDED allocations, showing 0 occupied.
-- =====================================================================
SET search_path TO q05_hostel;

CREATE OR REPLACE VIEW v_room_occupancy AS
SELECT r.room_id,
       r.room_number,
       r.capacity,
       COUNT(a.allocation_id)              AS occupied_beds,
       r.capacity - COUNT(a.allocation_id) AS free_beds
FROM rooms r
LEFT JOIN allocations a
       ON a.room_id = r.room_id
      AND a.status  = 'ACTIVE'
GROUP BY r.room_id, r.room_number, r.capacity;

SELECT * FROM v_room_occupancy ORDER BY room_number;

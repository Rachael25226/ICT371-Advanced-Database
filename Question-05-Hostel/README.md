# Question 5: Hostel Room Allocation

Schema: `q05_hostel`. Tables: `students`, `rooms`, `allocations`, `occupancy_snapshot`, the last with a composite PK `(snapshot_date, room_id)`.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | `capacity > 0`; status ACTIVE or ENDED; a CHECK that ACTIVE has `released_on IS NULL` and ENDED has a release date; release date not before the allocation date. Seed: A101 **full** (2 of 2), A102 **partly occupied** (1 of 3, plus an ENDED record), B201 **empty** (ENDED history only). |
| (b) | 6 | `02_function.sql` | `fn_free_beds(p_room_id)` = capacity minus ACTIVE allocations; ENDED rows are ignored. Rejects an unknown room. |
| (c) | 8 | `03_procedure.sql` | `pr_allocate_room(p_student_id, p_room_id, p_allocated_on)` validates the IDs and date, refuses a second ACTIVE allocation and checks `fn_free_beds`. It inserts one ACTIVE row with `released_on NULL`. The student and room rows are locked. |
| (d) | 8 | `04_trigger.sql` | `trg_allocations_rules`: `BEFORE INSERT OR UPDATE`. For ACTIVE rows it enforces capacity and one ACTIVE allocation per student, excluding the row being updated (`allocation_id <> OLD.allocation_id`). The room and student rows are locked. |
| (e) | 5 | `06_view.sql` | `v_room_occupancy`: every room, including empty ones, through a `LEFT JOIN` with `status = 'ACTIVE'` inside the `ON` clause. Shows capacity, occupied beds and free beds. |
| (f) | 5 | `07_index.sql` | Partial index `idx_allocations_active_room ON allocations (room_id) WHERE status = 'ACTIVE'`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_occupancy()` writes CURRENT_DATE occupancy for every room. Scheduled `'55 23 * * *'` (23:55 daily). |

## Index justification (f)
Only current occupants are indexed, at most the number of beds. ENDED history keeps growing but never enters the index. The capacity checks, `fn_free_beds` and the view all ask for one room's ACTIVE allocations, which is exactly what this index holds.

## Rerun behaviour (g)
The primary key `(snapshot_date, room_id)` guarantees one row per date and room. `ON CONFLICT … DO UPDATE` replaces the values.

## Tests
29 checks, all passing. The tests cover:
- the capacity, status and release-date CHECKs;
- the full, partly occupied and empty rooms;
- free beds ignoring ENDED rows;
- the procedure's rejections: unknown IDs, a full room, an existing ACTIVE allocation and a missing date;
- direct SQL inserts and updates blocked for capacity and for a second ACTIVE allocation;
- updating a row in a full room allowed, because the row is excluded from its own count;
- a freed bed reusable;
- the view agreeing with `fn_free_beds`;
- the snapshot rerun.

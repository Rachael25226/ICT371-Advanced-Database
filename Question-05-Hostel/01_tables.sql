-- =====================================================================
-- Question 5 - Hostel Room Allocation
-- (a) Database: tables and constraints
--   * room capacity must be positive;
--   * status is ACTIVE or ENDED;
--   * ACTIVE requires released_on NULL, ENDED requires a release date;
--   * a release date cannot be before the allocation date.
-- Capacity and "one ACTIVE allocation per student" span several rows,
-- so they are enforced by the procedure (c) and the trigger (d).
-- =====================================================================
DROP SCHEMA IF EXISTS q05_hostel CASCADE;
CREATE SCHEMA q05_hostel;
SET search_path TO q05_hostel;

CREATE TABLE students (
    student_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_number  varchar(20)  NOT NULL UNIQUE,
    full_name       varchar(100) NOT NULL
);

CREATE TABLE rooms (
    room_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_number  varchar(10) NOT NULL UNIQUE,
    capacity     integer     NOT NULL
                 CONSTRAINT chk_rooms_capacity_positive CHECK (capacity > 0)
);

CREATE TABLE allocations (
    allocation_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id     integer     NOT NULL REFERENCES students (student_id),
    room_id        integer     NOT NULL REFERENCES rooms (room_id),
    allocated_on   date        NOT NULL,
    released_on    date        NULL,
    status         varchar(6)  NOT NULL DEFAULT 'ACTIVE'
                   CONSTRAINT chk_allocations_status CHECK (status IN ('ACTIVE', 'ENDED')),
    CONSTRAINT chk_allocations_status_release CHECK (
        (status = 'ACTIVE' AND released_on IS NULL) OR
        (status = 'ENDED'  AND released_on IS NOT NULL)
    ),
    CONSTRAINT chk_allocations_release_after_allocation CHECK (
        released_on IS NULL OR released_on >= allocated_on
    )
);

CREATE TABLE occupancy_snapshot (
    snapshot_date  date    NOT NULL,
    room_id        integer NOT NULL REFERENCES rooms (room_id),
    occupied_beds  integer NOT NULL CHECK (occupied_beds >= 0),
    free_beds      integer NOT NULL CHECK (free_beds >= 0),
    PRIMARY KEY (snapshot_date, room_id)
);

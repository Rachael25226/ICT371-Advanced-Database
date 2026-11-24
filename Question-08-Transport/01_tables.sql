-- =====================================================================
-- Question 8 - Transport Fleet Maintenance
-- (a) Database: tables and constraints
--   * odometers are non-negative;
--   * last_service_odometer can never exceed current_odometer;
--   * a trip must end beyond where it started;
--   * at most one service alert per vehicle (vehicle_id is the PK).
-- A vehicle is due for service at 5,000 km or more since its last service.
-- =====================================================================
DROP SCHEMA IF EXISTS q08_transport CASCADE;
CREATE SCHEMA q08_transport;
SET search_path TO q08_transport;

CREATE TABLE vehicles (
    vehicle_id             integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    registration           varchar(15) NOT NULL UNIQUE,
    current_odometer       integer     NOT NULL
                           CONSTRAINT chk_vehicles_current_non_negative CHECK (current_odometer >= 0),
    last_service_odometer  integer     NOT NULL
                           CONSTRAINT chk_vehicles_service_non_negative CHECK (last_service_odometer >= 0),
    CONSTRAINT chk_vehicles_service_not_after_current CHECK (last_service_odometer <= current_odometer)
);

CREATE TABLE trips (
    trip_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_id      integer NOT NULL REFERENCES vehicles (vehicle_id),
    trip_on         date    NOT NULL,
    start_odometer  integer NOT NULL CONSTRAINT chk_trips_start_non_negative CHECK (start_odometer >= 0),
    end_odometer    integer NOT NULL,
    CONSTRAINT chk_trips_end_after_start CHECK (end_odometer > start_odometer)
);

CREATE TABLE service_alerts (
    vehicle_id        integer PRIMARY KEY REFERENCES vehicles (vehicle_id),
    km_since_service  integer NOT NULL CHECK (km_since_service >= 0),
    flagged_on        date    NOT NULL DEFAULT CURRENT_DATE
);

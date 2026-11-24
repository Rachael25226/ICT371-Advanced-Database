# Question 8: Transport Fleet Maintenance

Schema: `q08_transport`. Tables: `vehicles` (with `registration UNIQUE`), `trips`, `service_alerts` (with `vehicle_id` as both PK and FK).

A vehicle is due for service at 5,000 km or more since its last service.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | Non-negative odometers; `CHECK (last_service_odometer <= current_odometer)`; `CHECK (end_odometer > start_odometer)`. Three vehicles at 2,000, 4,800 and 6,000 km since service. Six trips are added through `pr_record_trip` after the trigger is installed. |
| (b) | 6 | `02_function.sql` | `fn_service_due(p_vehicle_id)` returns `current − last_service >= 5000` as a boolean. Rejects an unknown vehicle. |
| (c) | 8 | `03_procedure.sql` | `pr_record_trip(p_vehicle_id, p_trip_on, p_start, p_end)` validates the vehicle, the date and that end is greater than start, then inserts the trip. It does **not** update the odometer (verified by a test). |
| (d) | 8 | `04_trigger.sql` | `trg_trips_odometer`: `BEFORE INSERT` row trigger. It locks the vehicle, rejects invalid mileage and a start that differs from `current_odometer`, then sets `current_odometer = NEW.end_odometer` once. |
| (e) | 5 | `06_view.sql` | `v_service_due`: registration and km since service for vehicles at or above 5,000 km. |
| (f) | 5 | `07_index.sql` | `idx_trips_vehicle_trip_on (vehicle_id, trip_on)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_service_alerts()` upserts one alert per due vehicle and deletes alerts for vehicles no longer due. Scheduled `'0 6 * * 1'` (Mondays at 06:00). |

## Index justification (f)
The query uses equality on `vehicle_id` and a range on `trip_on`. With the equality column first, one vehicle's trips are contiguous and in date order, so the range is read as a single slice. The index also covers the foreign key.

## Rerun behaviour (g)
`vehicle_id` is the alerts table's primary key, so there is at most one alert per vehicle. `ON CONFLICT DO UPDATE` refreshes the kilometres and keeps `flagged_on` as the date the vehicle was first flagged. The `DELETE` removes an alert once a service brings the vehicle under 5,000 km.

## Tests
29 checks, all passing. The tests cover:
- the odometer CHECKs and the UNIQUE registration;
- `fn_service_due` both ways, and the exact 5,000 km boundary;
- the procedure's rejections, including a trip that does not start at the current odometer;
- rejected trips changing nothing;
- the odometer set to the trip end once (not added twice);
- direct SQL inserts checked the same way;
- every trip starting where the vehicle's previous trip ended;
- the view after a service;
- alerts inserted, updated and removed after a service;
- no duplicate alerts on rerun.

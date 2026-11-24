# Question 4: Clinic Appointment Scheduling

Schema: `q04_clinic`. Tables: `patients`, `doctors`, `appointments`, `clinic_summary`.

Slots: 09:00, 10:00, 11:00 and 12:00. Two non-cancelled appointments may never share a doctor, date and slot.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | `slot_time time` with a CHECK for the four slots; `status` CHECK for BOOKED, ATTENDED or CANCELLED. Three patients, three doctors, six appointments with no clash. One ATTENDED appointment shares a slot with a CANCELLED one, which the rule allows. |
| (b) | 6 | `02_function.sql` | `fn_daily_load(p_doctor_id, p_day)` counts the doctor's non-cancelled appointments that day, returning 0 when there are none. Rejects an unknown doctor. |
| (c) | 8 | `03_procedure.sql` | `pr_book_appointment(p_patient_id, p_doctor_id, p_day, p_slot)` validates both IDs and rejects a NULL or past date and any unsupported slot. It inserts a BOOKED row. |
| (d) | 8 | `04_trigger.sql` | `trg_appointments_no_clash`: `BEFORE INSERT OR UPDATE` row trigger. It rejects a clash with another non-cancelled appointment. On UPDATE the row itself is excluded (`appointment_id <> OLD.appointment_id`). An advisory lock per doctor and day serialises concurrent bookings. |
| (e) | 5 | `06_view.sql` | `v_today_appointments`: only `slot_time`, `patient_name` and `doctor_name` for today's BOOKED appointments, with no other patient data. |
| (f) | 5 | `07_index.sql` | Non-unique `idx_appointments_day_doctor (appointment_day, doctor_id)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_clinic_summary(p_day)` counts each status with `COUNT(*) FILTER`. Scheduled `'0 1 * * *'` (01:00 daily) for the previous day. |

## Index justification (f)
Day sheets, `fn_daily_load` and the clash trigger all search by date and doctor. The date leads because it is also used on its own (today's list, the daily summary). The index must be non-unique: a doctor has several appointments a day, and cancelled rows can share a slot.

## Rerun behaviour (g)
`ON CONFLICT (summary_date) DO UPDATE` replaces that date's counts.

## Tests
28 checks, all passing. The tests cover:
- the status and slot CHECKs;
- the daily load excluding cancelled appointments, and 0 for an empty day;
- an unknown patient or doctor, a past date, the slots 09:30 and 14:00, and a clash, all rejected with nothing stored;
- clashes rejected for direct INSERT, for UPDATE and for un-cancelling;
- a self-update not counted as a clash;
- a cancelled slot becoming bookable again;
- the view's columns and contents;
- summary counts after a status change, and the rerun.

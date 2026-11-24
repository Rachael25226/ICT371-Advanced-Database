# Question 9: Farmer Cooperative Maize Deliveries

Schema: `q09_maize`. Tables: `farmers` (with `farmer_number UNIQUE`), `deliveries`, `daily_purchases`.

Prices per kg: grade A K5, grade B K4, grade C K3.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | Numeric weight and money columns; grade CHECK for A, B or C; `weight_kg > 0`. Three farmers and six deliveries covering grades A, B and C, both paid and unpaid. They are loaded through the procedure after the trigger is installed, then some are marked paid. |
| (b) | 6 | `02_function.sql` | `fn_maize_rate(p_grade)` returns 5, 4 or 3 and accepts lower case or padded input. Rejects NULL and unsupported grades. |
| (c) | 8 | `03_procedure.sql` | `pr_receive_delivery(p_farmer_id, p_grade, p_weight, p_date)` rejects an unknown farmer, a bad grade, a non-positive weight and a NULL date. It inserts only the basic fields with `is_paid = false`, and the trigger prices the delivery. |
| (d) | 8 | `04_trigger.sql` | `trg_deliveries_pricing`: `BEFORE INSERT OR UPDATE` rejects a non-positive weight, calls `fn_maize_rate` and sets `NEW.unit_rate` and `NEW.total_value`. Any values supplied by direct SQL are overwritten. |
| (e) | 5 | `06_view.sql` | `v_farmer_amount_due`: farmer number, name and `COALESCE(SUM(total_value) FILTER (WHERE NOT is_paid), 0)`. A `LEFT JOIN` keeps farmers with nothing unpaid, who show 0. |
| (f) | 5 | `07_index.sql` | Composite `idx_deliveries_farmer_delivered_on (farmer_id, delivered_on)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_purchases(p_day)` stores the day's total weight and value. Scheduled `'30 1 * * *'` (01:30 daily) for the previous day. |

## Index justification (f)
The query uses equality on `farmer_id` and a date range on `delivered_on`. The equality column leads, so one farmer's deliveries between two dates form one contiguous index slice. The index also covers the foreign key used by the view.

## Rerun behaviour (g)
The totals are recalculated and written with `ON CONFLICT (purchase_date) DO UPDATE`. Repeated runs replace the totals instead of adding to them (tested with three runs).

## Tests
35 checks, all passing. The tests cover:
- the seed coverage and the UNIQUE farmer number;
- the rates, and NULL, empty and unsupported grades;
- the procedure's six rejection cases with nothing stored;
- the trigger pricing procedure inserts;
- the trigger correcting a direct insert with a wrong rate or value;
- re-pricing when the grade changes;
- an attempt to override `total_value` blocked;
- zero or negative weights and a bad grade rejected for direct SQL;
- every row following the pricing rule;
- the view showing 0 for farmers with nothing unpaid;
- daily totals not tripled after three runs.

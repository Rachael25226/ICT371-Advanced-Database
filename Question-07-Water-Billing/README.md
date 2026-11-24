# Question 7: Water Meter Readings and Billing

Schema: `q07_water_billing`. Tables: `customers`, `readings` (with `UNIQUE (customer_id, reading_month)`), `bills` (with `reading_id UNIQUE`), `receivable_snapshot`.

Tariff: the first 10 units cost K5 each, and units above 10 cost K8 each.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | Non-negative numeric meter values; month-start `reading_month`; `CHECK (amount_paid BETWEEN 0 AND charge)`. Three customers and six readings of 0, 10, 15, 25, 7 and 10.5 units, each billed through the procedure. |
| (b) | 6 | `02_function.sql` | `fn_water_charge(p_units)` = `round(LEAST(units, 10) × 5 + GREATEST(units − 10, 0) × 8, 2)`, an exact numeric with two decimals. Rejects NULL or negative units. |
| (c) | 8 | `03_procedure.sql` | `pr_generate_bill(p_reading_id, p_due_on)` works out consumption, calls the function and inserts the bill with `amount_paid = 0`. Rejects an unknown reading or one already billed. The reading row is locked. |
| (d) | 8 | `04_trigger.sql` | `trg_readings_validate`: `BEFORE INSERT OR UPDATE` raises when `current_reading < previous_reading`. The statement is aborted, so the reading is never stored. |
| (e) | 5 | `06_view.sql` | `v_overdue_bills`: customer name, due date and outstanding amount (`charge − amount_paid`) where `due_on < CURRENT_DATE AND amount_paid < charge`. |
| (f) | 5 | `07_index.sql` | Partial index `idx_bills_unpaid_due_on ON bills (due_on) WHERE amount_paid < charge`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_receivables()` stores today's total unpaid balance. Scheduled `'30 0 * * *'` (00:30 daily). |

## Index justification (f)
An overdue search is "due before a date and not fully paid". Indexing `due_on` only for unpaid bills leaves out the growing number of paid bills. A range scan on the small index then returns only candidate overdue bills.

## Rerun behaviour (g)
`ON CONFLICT (snapshot_date) DO UPDATE` replaces the same date's total.

## Tests
32 checks, all passing. The tests cover:
- the month-start, non-negative, UNIQUE and `amount_paid` range constraints;
- tariff values of 0, 7, 10, 10.5 and 25 units, and rounding to exactly two decimals;
- NULL and negative units rejected;
- every seeded bill matching the tariff;
- an unknown reading, a duplicate bill and a missing due date rejected;
- the trigger blocking a backwards reading on direct INSERT and on UPDATE, with nothing stored;
- the view's contents;
- receivables replaced after a payment.

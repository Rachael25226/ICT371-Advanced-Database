# Question 2: University Fee Payments

Schema: `q02_university_fees`. Tables: `students`, `payments`, `payment_audit`, `daily_collections`. PostgreSQL stores the PDF's "Students" and "Payments" in lower case.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | `student_number UNIQUE`, `fee_due >= 0`, `amount > 0`, foreign keys, and `payment_audit.payment_id UNIQUE` (one audit row per payment). Three students with balances K3,000, K0 (settled) and K9,000. Six payments; student 3 has none. |
| (b) | 6 | `02_function.sql` | `fn_fee_balance(p_student_id)` = `fee_due - COALESCE(SUM(amount), 0)`, which returns the full fee when there are no payments. Rejects an unknown student. |
| (c) | 8 | `03_procedure.sql` | `pr_receive_payment(p_student_id, p_amount, p_paid_on)` rejects a NULL, zero or negative amount, an unknown student and any amount above the outstanding balance (no credit balances). It inserts the payment and never changes `fee_due`. The student row is locked to stop two concurrent payments overpaying. |
| (d) | 8 | `04_trigger.sql` | `trg_payments_audit`: `AFTER INSERT … FOR EACH ROW` writes the payment ID, student ID, amount and `now()` to `payment_audit`. The procedure contains no audit insert (verified by a test). |
| (e) | 5 | `06_view.sql` | `v_fee_balances`: student number, full name and outstanding balance, only where the balance is above 0. |
| (f) | 5 | `07_index.sql` | Composite `idx_payments_student_paid_on (student_id, paid_on)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_collections(p_day)` stores the count and total, scheduled `'0 1 * * *'` (01:00 daily) for the previous day. |

## Index justification (f)
`student_id` is an equality filter and `paid_on` a range, so the equality column leads. Each student's payments are contiguous and in date order. The same index also speeds up `fn_fee_balance` and the procedure's balance check, which filter on `student_id`.

## Rerun behaviour (g)
`INSERT … ON CONFLICT (collection_date) DO UPDATE` replaces the existing summary row with freshly calculated values.

## Tests
33 checks, all passing. The tests cover:
- the UNIQUE, CHECK and foreign-key constraints;
- the balance with and without payments;
- a NULL, zero or negative amount, an overpayment, a payment by a settled student and an unknown student, all rejected with no rows stored;
- paying exactly the balance;
- `fee_due` unchanged by payments;
- one matching audit row per payment, including direct SQL inserts;
- the view excluding settled students;
- the refresh rerun.

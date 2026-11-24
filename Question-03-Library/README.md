# Question 3: Library Returns and Overdue Fines

Schema: `q03_library`. Tables: `books`, `loans`, `loan_audit`, `overdue_summary`.

Fine rule: K2 per day after `due_on`. A return on the due date costs K0, and a returned loan stops accumulating fines.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | `CHECK (due_on >= borrowed_on)` and `CHECK (returned_on IS NULL OR returned_on >= borrowed_on)`. Three books and six loans: an open overdue loan, an open loan not yet due, a loan due today, a late return, an on-time return (on the due date, K0) and a second overdue loan. |
| (b) | 6 | `02_function.sql` | `fn_loan_fine(p_loan_id, p_as_of)` = `2 × GREATEST(end_date - due_on, 0)`, where `end_date` is `LEAST(p_as_of, returned_on)` if the loan was returned, otherwise `p_as_of`. Rejects an unknown loan. |
| (c) | 8 | `03_procedure.sql` | `pr_return_loan(p_loan_id, p_returned_on)` rejects an unknown loan, an already returned loan, a NULL date and a date before `borrowed_on`. It sets `returned_on` and `fine_amount` together in one `UPDATE`, with the fine calculated by `fn_loan_fine`. |
| (d) | 8 | `04_trigger.sql` | `trg_loans_return_audit`: `AFTER UPDATE … WHEN (OLD.returned_on IS DISTINCT FROM NEW.returned_on)` logs the old and new dates. |
| (e) | 5 | `06_view.sql` | `v_overdue_loans`: title, borrower, due date and fine as of today for loans where `returned_on IS NULL AND due_on < CURRENT_DATE`. |
| (f) | 5 | `07_index.sql` | Partial index `idx_loans_open_by_book ON loans (book_id) WHERE returned_on IS NULL`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_overdue(p_as_of)`, scheduled `'10 0 * * *'` (00:10 daily) for `CURRENT_DATE`. |

## Index justification (f)
The index holds only open loans, so it stays small as books are returned. Every entry is an unreturned loan, so a search for one book's open loans reads nothing else. The query repeats `returned_on IS NULL` so the planner can use the partial index.

## Interpretation used in (g)
A loan counts as "still unreturned as of `p_as_of`" if it was borrowed on or before that date and was not returned by then: `returned_on IS NULL` or `returned_on > p_as_of`. This keeps historical snapshots correct. Because the table records an `overdue_count`, only those loans already past their due date (`due_on < p_as_of`) are counted. They are the only loans that carry a fine, so the sum of fines is the same either way. The fines are calculated with `fn_loan_fine(loan_id, p_as_of)`. `ON CONFLICT (snapshot_date) DO UPDATE` replaces the snapshot on a rerun.

## Tests
31 checks, all passing. The tests cover:
- fines for open, not-yet-due, due-today, late-returned and on-time loans;
- a fine that stops growing after return, and an earlier `p_as_of` taking precedence;
- the procedure's four rejection cases;
- the fine and date stored together;
- audit rows written only when `returned_on` actually changes;
- the view's contents;
- snapshots for today and yesterday, and the rerun.

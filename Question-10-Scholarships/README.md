# Question 10: Scholarship Application Assessment

Schema: `q10_scholarships`. Tables: `students` (with `student_number UNIQUE`), `applications`, `decision_audit`.

Eligibility: age 18 to 25 inclusive, monthly household income at most K3,000, and average mark at least 70.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | `age > 0`, `income >= 0`, `mark BETWEEN 0 AND 100`, and a status CHECK. Six PENDING applications across three students. Three qualify, two of them at the boundaries (age 18 with income exactly 3000 and mark exactly 70; age 25). Three just miss: age 26, income 3000.01 and mark 69.99. |
| (b) | 6 | `02_function.sql` | `fn_scholarship_eligible(p_age, p_income, p_mark)` returns true only when all three rules hold. Rejects NULLs, negative income, a non-positive age and marks outside 0 to 100. |
| (c) | 8 | `03_procedure.sql` | `pr_assess_application(p_application_id)` locks the row and requires it to exist and be PENDING, with clear messages "Application N does not exist" and "Application N has already been assessed (status X)". It calls the function and sets APPROVED or REJECTED. |
| (d) | 8 | `04_trigger.sql` | `trg_applications_decision_audit`: `AFTER UPDATE … WHEN (OLD.status IS DISTINCT FROM NEW.status)` records the old status, new status and timestamp. |
| (e) | 5 | `06_view.sql` | `v_approved_applicants`: student number, full name, average mark and status for APPROVED applications only. Income is omitted. |
| (f) | 5 | `07_index.sql` | Composite `idx_applications_status_submitted (status, submitted_on)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_assess_pending()` uses a query `FOR` loop over `WHERE status = 'PENDING'` that calls `pr_assess_application`. Scheduled `'0 8 * * 1'` (Mondays at 08:00). |

## Index justification (f)
`status` is an equality filter and `submitted_on` a range. With status first, all applications of one status sit together in date order, so the range is a single slice. Status alone has only three values and would not be selective enough. The job's `WHERE status = 'PENDING'` loop uses the same index.

## Rerun behaviour (g)
Only PENDING rows are selected, so completed applications are never reassessed. Their status does not change, so the trigger writes no duplicate audit rows.

## Tests
37 checks, all passing. The tests cover:
- the constraints;
- eligibility at every boundary (17, 18, 25 and 26; 3000 and 3000.01; 69.99 and 70);
- every invalid-input rejection;
- the seeded decisions;
- unknown and already assessed applications rejected;
- audit rows only for real status changes, including direct SQL;
- the view showing only APPROVED rows without income;
- the job processing only new PENDING applications, with reruns adding no audit rows.

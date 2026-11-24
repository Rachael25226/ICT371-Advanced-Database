# ICT371 Advanced Database

Complete solutions to all ten ICT371 Advanced Database questions. Each question is answered in full, parts (a) to (g):

| Part | What is delivered |
|------|-------------------|
| (a) | Tables, keys, data types, constraints and seed data |
| (b) | The required PL/pgSQL function |
| (c) | The required stored procedure |
| (d) | The required trigger |
| (e) | The required view |
| (f) | The required index, its justification, a matching query and its `EXPLAIN` plan |
| (g) | The required scheduled procedure, its pg_cron schedule and its rerun behaviour |

Every question also has an automated test script and the actual output of running it.

## Database platform

**PostgreSQL** (developed and tested on PostgreSQL 18.7), using **PL/pgSQL** for the functions, procedures and triggers, and the **pg_cron** extension for the scheduled jobs.

The assignment names no DBMS, but its requirements match PostgreSQL:

- stored procedures called with `CALL` (PostgreSQL 11+);
- row triggers that use `OLD` and `NEW`;
- "query FOR loop" (`FOR r IN SELECT ... LOOP`) in Questions 6 and 10;
- `CURRENT_DATE`, `boolean` columns and `EXPLAIN` plans;
- jobs that run at a time of day and show "the job and its run history" (Question 6). That is what pg_cron's `cron.job` and `cron.job_run_details` tables provide.

All scripts use only PostgreSQL syntax. No other SQL dialect is mixed in.

## Repository structure

```
ICT371-Advanced-Database/
├── README.md                      this file
├── run_all.sql                    builds and tests all ten questions in order
├── setup/
│   ├── 00_create_database.sql     creates the ict371 database
│   └── 01_enable_pg_cron.sql      optional: enables pg_cron for part (g)
├── Question-01-Pharmacy/
├── Question-02-University-Fees/
├── Question-03-Library/
├── Question-04-Clinic/
├── Question-05-Hostel/
├── Question-06-Payroll/
├── Question-07-Water-Billing/
├── Question-08-Transport/
├── Question-09-Maize-Deliveries/
└── Question-10-Scholarships/
```

Every question folder has the same layout:

| File | Part | Contents |
|------|------|----------|
| `01_tables.sql` | (a) | Creates the question's schema, tables, keys and constraints |
| `02_function.sql` | (b) | The function |
| `03_procedure.sql` | (c) | The procedure |
| `04_trigger.sql` | (d) | The trigger function and trigger |
| `05_seed_data.sql` | (a) | Seed data (loaded through the procedure where the question asks) |
| `06_view.sql` | (e) | The view, plus a query of it |
| `07_index.sql` | (f) | The index, written justification, matching query and `EXPLAIN` |
| `08_job_procedure.sql` | (g) | The scheduled procedure, plus a demonstration run and rerun |
| `09_job_schedule.sql` | (g) | The pg_cron schedule and the queries that inspect the job and its run history |
| `10_tests.sql` | all | Automated tests with valid and invalid inputs |
| `run_question.sql` | — | Runs files 01 to 10 in the correct order |
| `test_output.txt` | — | The actual output of `run_question.sql` |
| `README.md` | — | Summary of the answers and design decisions for that question |

### One database, one schema per question

Several questions reuse table names (`students` appears in Questions 2, 5 and 10). Each question therefore lives in its own schema inside a single `ict371` database: `q01_pharmacy`, `q02_university_fees`, `q03_library`, `q04_clinic`, `q05_hostel`, `q06_payroll`, `q07_water_billing`, `q08_transport`, `q09_maize` and `q10_scholarships`.

Every script starts with `SET search_path TO <schema>;`, so the table and routine names are exactly the ones in the assignment. `01_tables.sql` drops and recreates its schema, so any question can be rebuilt independently at any time.

## How to run

You need PostgreSQL 11 or later (tested on 18) and `psql`.

**1. Create the database** (connected to the default `postgres` database):

```
psql -U postgres -d postgres -f setup/00_create_database.sql
```

**2. Optional: enable pg_cron.** This step is only needed if you want part (g)'s schedules created for real. Add the following lines to `postgresql.conf` and restart PostgreSQL:

```
shared_preload_libraries = 'pg_cron'
cron.database_name       = 'ict371'
```

Then run:

```
psql -U postgres -d ict371 -f setup/01_enable_pg_cron.sql
```

**3. Build and test everything** (from the repository root):

```
psql -U postgres -d ict371 -v ON_ERROR_STOP=1 -f run_all.sql
```

To build and test only one question, run its runner:

```
psql -U postgres -d ict371 -v ON_ERROR_STOP=1 -f Question-03-Library/run_question.sql
```

You can also run the numbered files of a question one by one in pgAdmin's Query Tool or in `psql`, in the order 01 to 10. `09_job_schedule.sql` needs pg_cron. `run_question.sql` detects whether pg_cron is installed and skips that one file when it is not.

### Execution order and why it matters

Within each question the order is: tables, function, procedure, trigger, seed data, view, index, scheduled procedure, schedule, tests.

Seed data comes **after** the procedure and trigger because several questions require it. For example, Q1 says to load sales "through your completed procedure", and Q8 and Q9 say to load data "after the trigger is installed". Seed dates are relative to `CURRENT_DATE`, so overdue, today and previous-day scenarios stay correct whenever the scripts are run.

## Testing

`10_tests.sql` in each folder checks every part of the question:

- constraints, with valid and invalid rows;
- the function, with normal, boundary and invalid inputs;
- the procedure, including a check that a rejected call leaves the tables unchanged;
- the trigger, including the "no audit row when nothing changed" rules;
- the view's contents;
- that the index exists;
- the scheduled procedure, run several times to prove it replaces values rather than duplicating or double-counting them.

Each check prints `PASS: ...`. Any failure raises `FAIL: ...` and, with `ON_ERROR_STOP=1`, stops the run. Rejection tests show the actual database error message.

**Results:** the full suite was run on a fresh database and passed: **308 checks, 0 failures**. It was then run a second time over the existing database and passed again, showing that every script can be rerun safely. Each question's real output is in its `test_output.txt`.

## What was and was not verified

| Item | Status |
|------|--------|
| All tables, constraints, functions, procedures, triggers, views and indexes (Q1–Q10) | Executed and tested on PostgreSQL 18.7 |
| Valid and invalid inputs, audit rows, rerun behaviour of every scheduled procedure | Executed and tested (`10_tests.sql`) |
| `EXPLAIN` plans showing each index matching its query | Executed (see `07_index.sql` output in `test_output.txt`) |
| Each pg_cron job command run exactly as scheduled, from a new session without the question's schema on the search path (as pg_cron runs it) | Executed and succeeded for all ten jobs |
| `09_job_schedule.sql` files | Checked for syntax and run against a temporary stand-in for pg_cron's `cron` catalogue. Scheduling twice kept one job per name. |
| Real pg_cron firing the jobs at the scheduled clock times | **Not tested.** pg_cron is not available for the Windows test server used. It requires the extension (normally on Linux) set up as described above. |

## Notes and limitations

- **EXPLAIN on small data.** The seed tables have only a few rows, so PostgreSQL correctly prefers a sequential scan for them. Each `07_index.sql` therefore shows two plans: the plan on the seed data, and the same query with `enable_seqscan` switched off for that transaction only. The second plan proves that the index matches the query's conditions; it is the plan used once the table holds realistic volumes.
- **Table-name case.** PostgreSQL folds unquoted names to lower case, so names written with capitals in the PDF (`Students`, `Payments`, `Books`, `Loans`, …) are created in lower case.
- **pg_cron time zone.** pg_cron uses the server's time zone (GMT unless `cron.timezone` is set). Set `cron.timezone` to the local zone if the schedule times must follow local time.
- **Scheduled procedures and search_path.** The procedures that pg_cron calls carry `SET search_path = <schema>`, so they work even though a pg_cron session does not have the question's schema on its search path.
- **Data.** All names and figures in the seed data are fictitious.

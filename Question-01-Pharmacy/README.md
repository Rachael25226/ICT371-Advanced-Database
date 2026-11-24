# Question 1: Pharmacy Stock and Daily Sales

Schema: `q01_pharmacy`. Tables: `medicines`, `sales`, `stock_audit`, `daily_sales`.

| Part | Marks | File | Answer |
|------|-------|------|--------|
| (a) | 6 | `01_tables.sql`, `05_seed_data.sql` | Four tables with identity primary keys and foreign keys to `medicines`. `CHECK (unit_price > 0)` and `CHECK (stock_qty >= 0)`. Four medicines; six sales loaded **through `pr_record_sale`**. |
| (b) | 6 | `02_function.sql` | `fn_sale_value(p_medicine_id, p_quantity)` returns the current `unit_price × quantity`. Rejects a NULL, zero or negative quantity and an unknown medicine. |
| (c) | 8 | `03_procedure.sql` | `pr_record_sale(p_medicine_id, p_quantity, p_sold_on)` locks the medicine row (`FOR UPDATE`) and checks stock. It stores the current price in the sale and deducts stock with one `UPDATE`. All checks run before any change, and an exception rolls back the whole call. |
| (d) | 8 | `04_trigger.sql` | `trg_medicines_stock_audit`: `AFTER UPDATE … FOR EACH ROW WHEN (OLD.stock_qty IS DISTINCT FROM NEW.stock_qty)` writes `old_qty`/`new_qty` to `stock_audit`. |
| (e) | 5 | `06_view.sql` | `v_low_stock`: name, price and remaining stock where `stock_qty < 10`. Queried before and after a sale that drops Cough Syrup from 11 to 9. |
| (f) | 5 | `07_index.sql` | `idx_sales_medicine_sold_on (medicine_id, sold_on)`, with `EXPLAIN`. |
| (g) | 6 | `08_job_procedure.sql`, `09_job_schedule.sql` | `pr_refresh_sales(p_day)`, scheduled `'15 0 * * *'` (00:15 daily) for `CURRENT_DATE - 1`. |

## Index justification (f)
The query uses equality on `medicine_id` and a range on `sold_on`. Putting the equality column first keeps one medicine's sales together in date order, so PostgreSQL seeks to the start date and reads only to the end date. The index also covers the `medicine_id` foreign key.

## Rerun behaviour (g)
The totals are recalculated from `sales` and written with `INSERT … ON CONFLICT (sales_date) DO UPDATE`. A rerun replaces the day's row; it never adds a second row or doubles the totals. A day with no sales is stored as zeros.

## Tests
`10_tests.sql`: 27 checks, all passing (see `test_output.txt`). The tests cover:
- the constraints;
- function values and rejections;
- overselling, an unknown medicine, a zero quantity and a NULL date, each leaving both tables unchanged;
- that the current price is stored after a price change;
- that the stock is deducted exactly once;
- no audit row for price-only or same-value updates;
- the view's contents;
- three reruns of the refresh producing one correct row.

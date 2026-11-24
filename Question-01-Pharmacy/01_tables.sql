-- =====================================================================
-- Question 1 - Pharmacy Stock and Daily Sales
-- (a) Database: tables, keys, types and constraints
-- =====================================================================
DROP SCHEMA IF EXISTS q01_pharmacy CASCADE;
CREATE SCHEMA q01_pharmacy;
SET search_path TO q01_pharmacy;

CREATE TABLE medicines (
    medicine_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medicine_name  varchar(100)  NOT NULL UNIQUE,
    unit_price     numeric(10,2) NOT NULL
                   CONSTRAINT chk_medicines_price_positive CHECK (unit_price > 0),
    stock_qty      integer       NOT NULL
                   CONSTRAINT chk_medicines_stock_non_negative CHECK (stock_qty >= 0)
);

CREATE TABLE sales (
    sale_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medicine_id  integer       NOT NULL REFERENCES medicines (medicine_id),
    quantity     integer       NOT NULL
                 CONSTRAINT chk_sales_quantity_positive CHECK (quantity > 0),
    unit_price   numeric(10,2) NOT NULL
                 CONSTRAINT chk_sales_price_positive CHECK (unit_price > 0),
    sold_on      date          NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE stock_audit (
    audit_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medicine_id  integer     NOT NULL REFERENCES medicines (medicine_id),
    old_qty      integer     NOT NULL,
    new_qty      integer     NOT NULL,
    changed_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE daily_sales (
    sales_date    date          PRIMARY KEY,
    total_qty     integer       NOT NULL CHECK (total_qty >= 0),
    total_amount  numeric(12,2) NOT NULL CHECK (total_amount >= 0)
);

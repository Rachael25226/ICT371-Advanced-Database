-- =====================================================================
-- Question 9 - Farmer Cooperative Maize Deliveries
-- (a) Database: tables using numeric weight and money fields.
-- Hypothetical prices per kg: grade A K5, grade B K4, grade C K3.
-- unit_rate and total_value are always set by the BEFORE INSERT OR
-- UPDATE trigger (d), so they are consistent even for direct SQL.
-- =====================================================================
DROP SCHEMA IF EXISTS q09_maize CASCADE;
CREATE SCHEMA q09_maize;
SET search_path TO q09_maize;

CREATE TABLE farmers (
    farmer_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    farmer_number  varchar(20)  NOT NULL UNIQUE,
    full_name      varchar(100) NOT NULL
);

CREATE TABLE deliveries (
    delivery_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    farmer_id     integer       NOT NULL REFERENCES farmers (farmer_id),
    grade         char(1)       NOT NULL
                  CONSTRAINT chk_deliveries_grade CHECK (grade IN ('A', 'B', 'C')),
    weight_kg     numeric(10,2) NOT NULL
                  CONSTRAINT chk_deliveries_weight_positive CHECK (weight_kg > 0),
    unit_rate     numeric(8,2)  NOT NULL,
    total_value   numeric(14,2) NOT NULL,
    delivered_on  date          NOT NULL,
    is_paid       boolean       NOT NULL DEFAULT false
);

CREATE TABLE daily_purchases (
    purchase_date  date          PRIMARY KEY,
    total_weight   numeric(14,2) NOT NULL CHECK (total_weight >= 0),
    total_value    numeric(16,2) NOT NULL CHECK (total_value >= 0)
);

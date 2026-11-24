-- =====================================================================
-- Question 1 (c) Procedure pr_record_sale(p_medicine_id, p_quantity, p_sold_on)
--   * locks the medicine row (SELECT ... FOR UPDATE) so two concurrent
--     sales cannot both pass the stock check and oversell;
--   * checks the available stock;
--   * stores the CURRENT price of the medicine in the sale;
--   * deducts the stock exactly once (a single UPDATE).
-- All checks run before any change is made, and any exception aborts
-- the whole CALL, so an invalid sale leaves both sales and medicines
-- unchanged.
-- =====================================================================
SET search_path TO q01_pharmacy;

CREATE OR REPLACE PROCEDURE pr_record_sale(p_medicine_id integer,
                                           p_quantity    integer,
                                           p_sold_on     date)
LANGUAGE plpgsql
AS $$
DECLARE
    v_price  medicines.unit_price%TYPE;
    v_stock  medicines.stock_qty%TYPE;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity %: quantity must be positive', p_quantity;
    END IF;

    IF p_sold_on IS NULL THEN
        RAISE EXCEPTION 'Sale date (p_sold_on) is required';
    END IF;

    SELECT unit_price, stock_qty
      INTO v_price, v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown medicine_id %', p_medicine_id;
    END IF;

    IF v_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock for medicine %: requested %, available %',
              p_medicine_id, p_quantity, v_stock;
    END IF;

    INSERT INTO sales (medicine_id, quantity, unit_price, sold_on)
    VALUES (p_medicine_id, p_quantity, v_price, p_sold_on);

    UPDATE medicines
       SET stock_qty = stock_qty - p_quantity
     WHERE medicine_id = p_medicine_id;
END;
$$;

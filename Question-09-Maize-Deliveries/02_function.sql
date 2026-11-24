-- =====================================================================
-- Question 9 (b) Function fn_maize_rate(p_grade)
-- Returns the price per kilogram: A = K5.00, B = K4.00, C = K3.00.
-- Surrounding spaces and lower case are tolerated ('a' -> 'A').
-- Rejects NULL or any unsupported grade.
-- =====================================================================
SET search_path TO q09_maize;

CREATE OR REPLACE FUNCTION fn_maize_rate(p_grade text)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_grade IS NULL THEN
        RAISE EXCEPTION 'Grade is required (A, B or C)';
    END IF;

    CASE upper(trim(p_grade))
        WHEN 'A' THEN RETURN 5.00;
        WHEN 'B' THEN RETURN 4.00;
        WHEN 'C' THEN RETURN 3.00;
        ELSE
            RAISE EXCEPTION 'Unsupported grade "%": use A, B or C', p_grade;
    END CASE;
END;
$$;

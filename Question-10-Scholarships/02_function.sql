-- =====================================================================
-- Question 10 (b) Function fn_scholarship_eligible(p_age, p_income, p_mark)
-- Returns TRUE only when ALL three rules hold:
--   age 18 to 25 inclusive, income <= 3000, average mark >= 70.
-- Rejects NULL inputs, negative income, non-positive age and marks
-- outside 0 to 100.
-- =====================================================================
SET search_path TO q10_scholarships;

CREATE OR REPLACE FUNCTION fn_scholarship_eligible(p_age    integer,
                                                   p_income numeric,
                                                   p_mark   numeric)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_age IS NULL OR p_income IS NULL OR p_mark IS NULL THEN
        RAISE EXCEPTION 'Age, income and mark are all required (got %, %, %)', p_age, p_income, p_mark;
    END IF;

    IF p_age <= 0 THEN
        RAISE EXCEPTION 'Invalid age %: age must be positive', p_age;
    END IF;

    IF p_income < 0 THEN
        RAISE EXCEPTION 'Invalid income %: income cannot be negative', p_income;
    END IF;

    IF p_mark < 0 OR p_mark > 100 THEN
        RAISE EXCEPTION 'Invalid mark %: mark must be between 0 and 100', p_mark;
    END IF;

    RETURN p_age BETWEEN 18 AND 25
       AND p_income <= 3000
       AND p_mark >= 70;
END;
$$;

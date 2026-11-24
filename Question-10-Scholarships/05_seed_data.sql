-- =====================================================================
-- Question 10 (a) Seed data: six PENDING applications across three
-- students, covering qualifying, non-qualifying and boundary cases.
--   app  student  age  income    mark   expected  reason
--   1    1        20   2500.00   75.00  APPROVE   clearly qualifies
--   2    2        18   3000.00   70.00  APPROVE   boundary: minimum age, maximum income, minimum mark
--   3    3        25   2999.99   88.00  APPROVE   boundary: maximum age
--   4    1        26   2000.00   80.00  REJECT    age one year too old
--   5    2        22   3000.01   85.00  REJECT    income K0.01 over the limit
--   6    3        19   1500.00   69.99  REJECT    mark 0.01 below 70
-- =====================================================================
SET search_path TO q10_scholarships;

INSERT INTO students (student_number, full_name) VALUES
    ('SCH-2026-01', 'Agnes Mwamba'),     -- 1
    ('SCH-2026-02', 'Benson Zimba'),     -- 2
    ('SCH-2026-03', 'Clara Musonda');    -- 3

INSERT INTO applications (student_id, age_at_application, monthly_income, average_mark, submitted_on, status) VALUES
    (1, 20, 2500.00, 75.00, CURRENT_DATE - 10, 'PENDING'),
    (2, 18, 3000.00, 70.00, CURRENT_DATE - 9,  'PENDING'),
    (3, 25, 2999.99, 88.00, CURRENT_DATE - 8,  'PENDING'),
    (1, 26, 2000.00, 80.00, CURRENT_DATE - 7,  'PENDING'),
    (2, 22, 3000.01, 85.00, CURRENT_DATE - 6,  'PENDING'),
    (3, 19, 1500.00, 69.99, CURRENT_DATE - 5,  'PENDING');

SELECT * FROM applications ORDER BY application_id;

-- =============================================================================
-- GOLD VALIDATION 5: Expenditure Validation
-- Purpose: Confirm expenditure fields are internally consistent and reasonable.
--          Verify instruction spending does not exceed total expenditure,
--          per-pupil figures are within plausible range, and no negative values.
-- Pass criteria: defined per check below.
-- =============================================================================

-- -------------------------------------------------------------------------
-- 5.1  Instruction spending > total expenditure (impossible — data error)
-- -------------------------------------------------------------------------
SELECT
    'Instruction_exceeds_total_exp'  AS check_name,
    COUNT(*)                         AS error_rows,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL'
    END                              AS result
FROM gold.FactFinance
WHERE
    instruction_spending IS NOT NULL
    AND total_expenditure IS NOT NULL
    AND instruction_spending > total_expenditure;

-- -------------------------------------------------------------------------
-- 5.2  Administration spending > total expenditure (impossible)
-- -------------------------------------------------------------------------
SELECT
    'Admin_exceeds_total_exp'        AS check_name,
    COUNT(*)                         AS error_rows,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL'
    END                              AS result
FROM gold.FactFinance
WHERE
    administration_spending IS NOT NULL
    AND total_expenditure    IS NOT NULL
    AND administration_spending > total_expenditure;

-- -------------------------------------------------------------------------
-- 5.3  Negative expenditure values (flag — should be zero or positive)
-- -------------------------------------------------------------------------
SELECT
    'Negative_total_expenditure'    AS check_name,
    COUNT(*)                        AS flagged_rows,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW'
    END                             AS result
FROM gold.FactFinance
WHERE total_expenditure < 0

UNION ALL

SELECT
    'Negative_instruction_spending',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM gold.FactFinance
WHERE instruction_spending < 0

UNION ALL

SELECT
    'Negative_capital_spending',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM gold.FactFinance
WHERE capital_spending < 0;

-- -------------------------------------------------------------------------
-- 5.4  Per-pupil spending plausibility (districts with enrollment > 0)
--      U.S. avg FY2014 ~$11,000 per pupil; flag <$1,000 or >$100,000
-- -------------------------------------------------------------------------
SELECT
    'Per_pupil_below_1000'          AS check_name,
    COUNT(*)                        AS flagged_rows,
    CASE WHEN COUNT(*) < 50         -- small number may be legitimate edge cases
         THEN 'REVIEW' ELSE 'FAIL'
    END                             AS result
FROM gold.FactFinance
WHERE enrollment > 0
  AND per_pupil_spending < 1000

UNION ALL

SELECT
    'Per_pupil_above_100000',
    COUNT(*),
    CASE WHEN COUNT(*) < 20 THEN 'REVIEW' ELSE 'FAIL' END
FROM gold.FactFinance
WHERE enrollment > 0
  AND per_pupil_spending > 100000;

-- -------------------------------------------------------------------------
-- 5.5  Instruction spending percentage distribution
--      NCES benchmark: ~60% of current spending goes to instruction nationally
-- -------------------------------------------------------------------------
SELECT
    'Instruction_pct_distribution'  AS check_name,
    COUNT(*)                        AS districts_with_data,
    ROUND(MIN(instruction_spending_pct), 1) AS min_pct,
    ROUND(AVG(instruction_spending_pct), 1) AS avg_pct,   -- expect ~55-65%
    ROUND(MAX(instruction_spending_pct), 1) AS max_pct,
    COUNT(CASE WHEN instruction_spending_pct BETWEEN 40 AND 80 THEN 1 END)
                                    AS in_normal_range,
    COUNT(CASE WHEN instruction_spending_pct NOT BETWEEN 40 AND 80 THEN 1 END)
                                    AS outside_normal_range
FROM gold.FactFinance
WHERE instruction_spending_pct IS NOT NULL;

-- -------------------------------------------------------------------------
-- 5.6  State-level per-pupil spending summary (informational)
-- -------------------------------------------------------------------------
SELECT
    ds.state_abbrev,
    ds.state_name,
    COUNT(f.fact_key)               AS district_count,
    SUM(f.enrollment)               AS total_enrollment,
    ROUND(SUM(f.total_expenditure * 1000.0)
          / NULLIF(SUM(f.enrollment), 0), 0) AS state_per_pupil_spending,
    ROUND(AVG(f.instruction_spending_pct), 1) AS avg_instruction_pct
FROM gold.FactFinance   AS f
JOIN gold.DimState      AS ds ON f.state_key = ds.state_key
WHERE f.enrollment > 0
GROUP BY ds.state_abbrev, ds.state_name
ORDER BY state_per_pupil_spending DESC;

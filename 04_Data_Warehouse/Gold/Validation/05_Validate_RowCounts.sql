-- =============================================================================
-- GOLD VALIDATION 1: Row Counts
-- Purpose: Confirm each Gold object has the expected row population.
-- Run after all Gold build scripts complete.
-- Pass criteria listed next to each assertion.
-- =============================================================================

-- -------------------------------------------------------------------------
-- 1.1  DimState — must be exactly 51
-- -------------------------------------------------------------------------
SELECT
    'DimState'                      AS object_name,
    COUNT(*)                        AS actual_rows,
    51                              AS expected_rows,
    CASE WHEN COUNT(*) = 51
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM gold.DimState

UNION ALL

-- -------------------------------------------------------------------------
-- 1.2  DimDistrict — must match source row count (expect ~14,400)
-- -------------------------------------------------------------------------
SELECT
    'DimDistrict'                   AS object_name,
    COUNT(*)                        AS actual_rows,
    (SELECT COUNT(DISTINCT nces_district_id)
     FROM silver.silver_district_finance) AS expected_rows,
    CASE WHEN COUNT(*) =
              (SELECT COUNT(DISTINCT nces_district_id)
               FROM silver.silver_district_finance)
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM gold.DimDistrict

UNION ALL

-- -------------------------------------------------------------------------
-- 1.3  DimDate — 366 daily rows + 1 annual summary = 367
-- -------------------------------------------------------------------------
SELECT
    'DimDate'                       AS object_name,
    COUNT(*)                        AS actual_rows,
    367                             AS expected_rows,
    CASE WHEN COUNT(*) = 367
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM gold.DimDate

UNION ALL

-- -------------------------------------------------------------------------
-- 1.4  FactFinance — one row per district (must match DimDistrict count)
-- -------------------------------------------------------------------------
SELECT
    'FactFinance'                   AS object_name,
    COUNT(*)                        AS actual_rows,
    (SELECT COUNT(*) FROM gold.DimDistrict) AS expected_rows,
    CASE WHEN COUNT(*) =
              (SELECT COUNT(*) FROM gold.DimDistrict)
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM gold.FactFinance;

-- -------------------------------------------------------------------------
-- 1.5  FactFinance — all 51 states represented
-- -------------------------------------------------------------------------
SELECT
    'FactFinance_states'            AS check_name,
    COUNT(DISTINCT state_key)       AS distinct_states,
    51                              AS expected_states,
    CASE WHEN COUNT(DISTINCT state_key) = 51
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM gold.FactFinance;

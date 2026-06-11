-- =============================================================================
-- GOLD VALIDATION 2: Duplicate District Check
-- Purpose: Confirm DimDistrict and FactFinance have no duplicate district rows.
-- A duplicate here means the same nces_district_id appears more than once.
-- Pass criteria: 0 duplicate rows in both objects.
-- =============================================================================

-- -------------------------------------------------------------------------
-- 2.1  DimDistrict — duplicate nces_district_id check
-- -------------------------------------------------------------------------
SELECT
    'DimDistrict_nces_duplicates'   AS check_name,
    COUNT(*)                        AS duplicate_group_count,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM (
    SELECT nces_district_id, COUNT(*) AS cnt
    FROM   gold.DimDistrict
    GROUP BY nces_district_id
    HAVING COUNT(*) > 1
) AS dups;

-- List the duplicates if any (for investigation)
SELECT
    nces_district_id,
    COUNT(*) AS occurrence_count
FROM gold.DimDistrict
GROUP BY nces_district_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- -------------------------------------------------------------------------
-- 2.2  FactFinance — duplicate district_key check (grain violation)
-- -------------------------------------------------------------------------
SELECT
    'FactFinance_district_key_duplicates' AS check_name,
    COUNT(*)                        AS duplicate_group_count,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM (
    SELECT district_key, COUNT(*) AS cnt
    FROM   gold.FactFinance
    GROUP BY district_key
    HAVING COUNT(*) > 1
) AS dups;

-- -------------------------------------------------------------------------
-- 2.3  FactFinance — duplicate census_district_id check (alternate key)
-- -------------------------------------------------------------------------
SELECT
    'FactFinance_census_id_duplicates' AS check_name,
    COUNT(*)                        AS duplicate_group_count,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM (
    SELECT census_district_id, COUNT(*) AS cnt
    FROM   gold.FactFinance
    GROUP BY census_district_id
    HAVING COUNT(*) > 1
) AS dups;

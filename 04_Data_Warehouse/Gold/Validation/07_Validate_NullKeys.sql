-- =============================================================================
-- GOLD VALIDATION 3: Null Key Check
-- Purpose: Confirm all foreign keys and natural keys in FactFinance are populated
--          and reference valid dimension rows (referential integrity).
-- Pass criteria: 0 null key rows, 0 orphaned FK rows.
-- =============================================================================

-- -------------------------------------------------------------------------
-- 3.1  Null foreign key check in FactFinance
-- -------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN district_key       IS NULL THEN 1 ELSE 0 END) AS null_district_key,
    SUM(CASE WHEN state_key          IS NULL THEN 1 ELSE 0 END) AS null_state_key,
    SUM(CASE WHEN date_key           IS NULL THEN 1 ELSE 0 END) AS null_date_key,
    SUM(CASE WHEN fiscal_year        IS NULL THEN 1 ELSE 0 END) AS null_fiscal_year,
    SUM(CASE WHEN nces_district_id   IS NULL THEN 1 ELSE 0 END) AS null_nces_id,
    SUM(CASE WHEN census_district_id IS NULL THEN 1 ELSE 0 END) AS null_census_id,
    COUNT(*)                                                     AS total_rows
FROM gold.FactFinance;

-- -------------------------------------------------------------------------
-- 3.2  Orphaned district_key (FK → DimDistrict)
-- -------------------------------------------------------------------------
SELECT
    'FactFinance_orphaned_district_key' AS check_name,
    COUNT(*)                            AS orphaned_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM gold.FactFinance AS f
LEFT JOIN gold.DimDistrict AS d ON f.district_key = d.district_key
WHERE d.district_key IS NULL;

-- -------------------------------------------------------------------------
-- 3.3  Orphaned state_key (FK → DimState)
-- -------------------------------------------------------------------------
SELECT
    'FactFinance_orphaned_state_key' AS check_name,
    COUNT(*)                         AS orphaned_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM gold.FactFinance AS f
LEFT JOIN gold.DimState AS s ON f.state_key = s.state_key
WHERE s.state_key IS NULL;

-- -------------------------------------------------------------------------
-- 3.4  Orphaned date_key (FK → DimDate)
-- -------------------------------------------------------------------------
SELECT
    'FactFinance_orphaned_date_key' AS check_name,
    COUNT(*)                        AS orphaned_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM gold.FactFinance AS f
LEFT JOIN gold.DimDate AS dd ON f.date_key = dd.date_key
WHERE dd.date_key IS NULL;

-- -------------------------------------------------------------------------
-- 3.5  DimDistrict state_code FK → DimState
-- -------------------------------------------------------------------------
SELECT
    'DimDistrict_orphaned_state_code' AS check_name,
    COUNT(*)                          AS orphaned_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM gold.DimDistrict AS dd
LEFT JOIN gold.DimState AS ds ON dd.state_code = ds.state_key
WHERE ds.state_key IS NULL;

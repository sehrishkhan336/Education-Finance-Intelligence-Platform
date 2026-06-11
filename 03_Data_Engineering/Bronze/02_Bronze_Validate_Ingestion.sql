-- =============================================================================
-- BRONZE VALIDATION: Verify ELSEC14 ingestion quality
-- Run after loading bronze.ELSEC14 from source CSV
-- Expected: ~14,400 rows, STATE codes 1-51, YRDATA = 14
-- =============================================================================

-- 1. Row count
SELECT
    COUNT(*)            AS total_rows,           -- expected ~14,400
    COUNT(DISTINCT STATE) AS distinct_states,    -- expected 51
    COUNT(DISTINCT NCESID) AS distinct_districts,
    MIN(STATE)          AS min_state_code,       -- expected 1
    MAX(STATE)          AS max_state_code,       -- expected 51
    MIN(YRDATA)         AS min_year,             -- expected 14
    MAX(YRDATA)         AS max_year              -- expected 14
FROM bronze.ELSEC14;

-- 2. Null check on critical columns
SELECT
    SUM(CASE WHEN STATE    IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN IDCENSUS IS NULL THEN 1 ELSE 0 END) AS null_idcensus,
    SUM(CASE WHEN NAME     IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN NCESID   IS NULL THEN 1 ELSE 0 END) AS null_ncesid,
    SUM(CASE WHEN YRDATA   IS NULL THEN 1 ELSE 0 END) AS null_yrdata
FROM bronze.ELSEC14;

-- 3. District count per state (should be reasonable, not 0 for any state)
SELECT
    STATE,
    COUNT(*) AS district_count
FROM bronze.ELSEC14
GROUP BY STATE
ORDER BY STATE;

-- 4. Revenue consistency check: components should sum to total
SELECT
    COUNT(*) AS revenue_mismatch_count
FROM bronze.ELSEC14
WHERE ABS(TOTALREV - COALESCE(TFEDREV,0) - COALESCE(TSTREV,0) - COALESCE(TLOCREV,0)) > 1;

-- 5. Negative financial values (flag for review)
SELECT COUNT(*) AS negative_total_rev_count
FROM bronze.ELSEC14 WHERE TOTALREV < 0;

SELECT COUNT(*) AS negative_total_exp_count
FROM bronze.ELSEC14 WHERE TOTALEXP < 0;

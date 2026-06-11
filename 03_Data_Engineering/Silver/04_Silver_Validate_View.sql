-- =============================================================================
-- SILVER VALIDATION: silver_district_finance view
-- =============================================================================

-- 1. Row and state count
SELECT
    COUNT(*)                AS total_rows,
    COUNT(DISTINCT state_code) AS distinct_states,
    MIN(state_code)         AS min_state,
    MAX(state_code)         AS max_state,
    MIN(fiscal_year)        AS fiscal_year_check
FROM silver.silver_district_finance;

-- 2. Revenue reconciliation in silver layer
SELECT
    COUNT(*) AS revenue_gap_rows
FROM silver.silver_district_finance
WHERE ABS(total_revenue - COALESCE(federal_revenue,0)
                        - COALESCE(state_revenue,0)
                        - COALESCE(local_revenue,0)) > 1;

-- 3. Districts with null or zero enrollment (flag — some may be valid admin-only units)
SELECT
    COUNT(*) AS zero_enrollment_districts
FROM silver.silver_district_finance
WHERE enrollment = 0 OR enrollment IS NULL;

-- 4. Per-state row count (sanity check)
SELECT
    state_code,
    COUNT(*) AS district_count,
    SUM(enrollment) AS total_enrollment,
    SUM(total_revenue) AS total_revenue_000s
FROM silver.silver_district_finance
GROUP BY state_code
ORDER BY state_code;

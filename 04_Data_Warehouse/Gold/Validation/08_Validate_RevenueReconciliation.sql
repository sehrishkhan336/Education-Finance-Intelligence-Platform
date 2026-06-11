-- =============================================================================
-- GOLD VALIDATION 4: Revenue Component Reconciliation
-- Purpose: Confirm federal + state + local revenue sums to total_revenue.
--          Flag districts where the revenue components diverge from the total.
--          Tolerance: $1,000 (1 unit in source scale) to allow for rounding.
-- Pass criteria: 0 rows exceed tolerance.
-- =============================================================================

-- -------------------------------------------------------------------------
-- 4.1  Revenue reconciliation: component sum vs total
-- -------------------------------------------------------------------------
SELECT
    'Revenue_reconciliation'        AS check_name,
    COUNT(*)                        AS mismatch_rows,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL'
    END                             AS result
FROM gold.FactFinance
WHERE
    total_revenue IS NOT NULL
    AND ABS(
        total_revenue
        - COALESCE(federal_revenue, 0)
        - COALESCE(state_revenue, 0)
        - COALESCE(local_revenue, 0)
    ) > 1;   -- tolerance: $1K (one source unit)

-- -------------------------------------------------------------------------
-- 4.2  Detail: districts with revenue component mismatch (top 20)
-- -------------------------------------------------------------------------
SELECT TOP 20
    f.nces_district_id,
    d.district_name,
    ds.state_abbrev,
    f.total_revenue,
    f.federal_revenue,
    f.state_revenue,
    f.local_revenue,
    (f.federal_revenue + f.state_revenue + f.local_revenue) AS component_sum,
    ABS(f.total_revenue
        - COALESCE(f.federal_revenue, 0)
        - COALESCE(f.state_revenue, 0)
        - COALESCE(f.local_revenue, 0))                     AS gap_amount
FROM gold.FactFinance      AS f
JOIN gold.DimDistrict      AS d  ON f.district_key = d.district_key
JOIN gold.DimState         AS ds ON f.state_key    = ds.state_key
WHERE
    f.total_revenue IS NOT NULL
    AND ABS(
        f.total_revenue
        - COALESCE(f.federal_revenue, 0)
        - COALESCE(f.state_revenue, 0)
        - COALESCE(f.local_revenue, 0)
    ) > 1
ORDER BY gap_amount DESC;

-- -------------------------------------------------------------------------
-- 4.3  Revenue percentage check: federal + state + local pct ≈ 100%
-- -------------------------------------------------------------------------
SELECT
    'Revenue_pct_sum_check'         AS check_name,
    COUNT(*)                        AS rows_with_pct_not_100,
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'REVIEW'
    END                             AS result
FROM gold.FactFinance
WHERE
    federal_revenue_pct IS NOT NULL
    AND ABS(
        COALESCE(federal_revenue_pct, 0)
        + COALESCE(state_revenue_pct, 0)
        + COALESCE(local_revenue_pct, 0)
        - 100.0
    ) > 0.1;   -- tolerance: 0.1%

-- -------------------------------------------------------------------------
-- 4.4  National revenue breakdown (informational)
-- -------------------------------------------------------------------------
SELECT
    SUM(total_revenue)                              AS national_total_rev_000s,
    SUM(federal_revenue)                            AS national_fed_rev_000s,
    SUM(state_revenue)                              AS national_state_rev_000s,
    SUM(local_revenue)                              AS national_local_rev_000s,
    ROUND(AVG(federal_revenue_pct), 2)              AS avg_fed_pct,
    ROUND(AVG(state_revenue_pct), 2)                AS avg_state_pct,
    ROUND(AVG(local_revenue_pct), 2)                AS avg_local_pct,
    ROUND(SUM(federal_revenue) * 100.0
          / NULLIF(SUM(total_revenue), 0), 2)       AS national_fed_pct,
    ROUND(SUM(state_revenue) * 100.0
          / NULLIF(SUM(total_revenue), 0), 2)       AS national_state_pct,
    ROUND(SUM(local_revenue) * 100.0
          / NULLIF(SUM(total_revenue), 0), 2)       AS national_local_pct
FROM gold.FactFinance
WHERE total_revenue > 0;

-- =============================================================================
-- GOLD FACT TABLE: FactFinance
-- Grain:    One row per school district per fiscal year
-- Keys:     FK → DimDistrict, DimState, DimDate
-- Measures: Revenue, expenditure, enrollment, debt (all dollars in $1,000s)
-- Calculated: Per-pupil ratios, revenue mix %, instruction % of spending
-- Dependencies: DimState, DimDistrict, DimDate must exist
-- Source:   silver.silver_district_finance
-- =============================================================================

IF OBJECT_ID('gold.FactFinance', 'U') IS NOT NULL
    DROP TABLE gold.FactFinance;
GO

CREATE TABLE gold.FactFinance (
    -- -------------------------------------------------------------------------
    -- Surrogate key
    -- -------------------------------------------------------------------------
    fact_key                INT             NOT NULL,

    -- -------------------------------------------------------------------------
    -- Dimension foreign keys
    -- -------------------------------------------------------------------------
    district_key            INT             NOT NULL,   -- FK → DimDistrict
    state_key               INT             NOT NULL,   -- FK → DimState
    date_key                INT             NOT NULL,   -- FK → DimDate (annual row = 20140000)
    fiscal_year             INT             NOT NULL,   -- 2014

    -- -------------------------------------------------------------------------
    -- Natural / business keys (degenerate dimensions — no separate dim needed)
    -- -------------------------------------------------------------------------
    nces_district_id        VARCHAR(12)     NOT NULL,
    census_district_id      VARCHAR(15)     NOT NULL,

    -- -------------------------------------------------------------------------
    -- ENROLLMENT
    -- -------------------------------------------------------------------------
    enrollment              DECIMAL(18,2)   NULL,   -- Fall pupil membership (V33)

    -- -------------------------------------------------------------------------
    -- REVENUE ($1,000s)
    -- -------------------------------------------------------------------------
    total_revenue           DECIMAL(18,2)   NULL,
    federal_revenue         DECIMAL(18,2)   NULL,
    state_revenue           DECIMAL(18,2)   NULL,
    local_revenue           DECIMAL(18,2)   NULL,

    -- -------------------------------------------------------------------------
    -- EXPENDITURE ($1,000s)
    -- -------------------------------------------------------------------------
    total_expenditure       DECIMAL(18,2)   NULL,
    instruction_spending    DECIMAL(18,2)   NULL,   -- TCURINST: total instruction
    administration_spending DECIMAL(18,2)   NULL,   -- E08 + E09: gen + school admin
    capital_spending        DECIMAL(18,2)   NULL,   -- TCAPOUT: total capital outlay
    support_services        DECIMAL(18,2)   NULL,   -- TCURSSVC: total support services

    -- -------------------------------------------------------------------------
    -- DEBT ($1,000s)
    -- -------------------------------------------------------------------------
    debt_outstanding        DECIMAL(18,2)   NULL,   -- Z32: long-term debt end of year

    -- -------------------------------------------------------------------------
    -- CALCULATED MEASURES (stored for query performance)
    -- NULL when enrollment = 0 or measures are NULL/zero to avoid divide-by-zero
    -- -------------------------------------------------------------------------
    per_pupil_spending      DECIMAL(18,2)   NULL,   -- total_expenditure / enrollment * 1000
    revenue_per_student     DECIMAL(18,2)   NULL,   -- total_revenue     / enrollment * 1000
    federal_revenue_pct     DECIMAL(8,4)    NULL,   -- federal / total_revenue * 100
    state_revenue_pct       DECIMAL(8,4)    NULL,   -- state   / total_revenue * 100
    local_revenue_pct       DECIMAL(8,4)    NULL,   -- local   / total_revenue * 100
    instruction_spending_pct DECIMAL(8,4)   NULL,   -- instruction / total_expenditure * 100

    -- Audit
    load_timestamp          DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT PK_FactFinance    PRIMARY KEY (fact_key),
    CONSTRAINT FK_Fact_District  FOREIGN KEY (district_key) REFERENCES gold.DimDistrict (district_key),
    CONSTRAINT FK_Fact_State     FOREIGN KEY (state_key)    REFERENCES gold.DimState    (state_key),
    CONSTRAINT FK_Fact_Date      FOREIGN KEY (date_key)     REFERENCES gold.DimDate     (date_key)
);
GO

-- =============================================================================
-- POPULATE FactFinance
-- Joins silver view → DimDistrict → DimState, pins date_key to 20140000 (annual)
-- Calculated fields use NULLIF to prevent divide-by-zero.
-- Dollar amounts stay in $1,000s (matching source); per-pupil figures are in
-- actual dollars (multiply by 1,000 to convert from $1K units).
-- =============================================================================
INSERT INTO gold.FactFinance (
    fact_key,
    district_key,
    state_key,
    date_key,
    fiscal_year,
    nces_district_id,
    census_district_id,
    enrollment,
    total_revenue,
    federal_revenue,
    state_revenue,
    local_revenue,
    total_expenditure,
    instruction_spending,
    administration_spending,
    capital_spending,
    support_services,
    debt_outstanding,
    per_pupil_spending,
    revenue_per_student,
    federal_revenue_pct,
    state_revenue_pct,
    local_revenue_pct,
    instruction_spending_pct
)
SELECT
    ROW_NUMBER() OVER (ORDER BY dd.district_key)        AS fact_key,
    dd.district_key,
    dd.state_code                                       AS state_key,
    20140000                                            AS date_key,
    s.fiscal_year,
    s.nces_district_id,
    s.census_district_id,

    -- Enrollment
    s.enrollment,

    -- Revenue
    s.total_revenue,
    s.federal_revenue,
    s.state_revenue,
    s.local_revenue,

    -- Expenditure
    s.total_expenditure,
    s.instruction_spending,
    s.administration_spending,
    s.capital_spending,
    s.total_support_services                            AS support_services,
    s.debt_outstanding,

    -- -------------------------------------------------------------------------
    -- Per-pupil spending (actual $, not $1,000s)
    -- enrollment is raw count; financials are in $1,000s → multiply by 1000
    -- -------------------------------------------------------------------------
    CASE
        WHEN NULLIF(s.enrollment, 0) IS NULL THEN NULL
        ELSE ROUND((s.total_expenditure * 1000.0) / s.enrollment, 2)
    END                                                 AS per_pupil_spending,

    CASE
        WHEN NULLIF(s.enrollment, 0) IS NULL THEN NULL
        ELSE ROUND((s.total_revenue * 1000.0) / s.enrollment, 2)
    END                                                 AS revenue_per_student,

    -- Revenue mix percentages
    CASE
        WHEN NULLIF(s.total_revenue, 0) IS NULL THEN NULL
        ELSE ROUND((s.federal_revenue / s.total_revenue) * 100.0, 4)
    END                                                 AS federal_revenue_pct,

    CASE
        WHEN NULLIF(s.total_revenue, 0) IS NULL THEN NULL
        ELSE ROUND((s.state_revenue / s.total_revenue) * 100.0, 4)
    END                                                 AS state_revenue_pct,

    CASE
        WHEN NULLIF(s.total_revenue, 0) IS NULL THEN NULL
        ELSE ROUND((s.local_revenue / s.total_revenue) * 100.0, 4)
    END                                                 AS local_revenue_pct,

    -- Instruction as % of total expenditure
    CASE
        WHEN NULLIF(s.total_expenditure, 0) IS NULL THEN NULL
        ELSE ROUND((s.instruction_spending / s.total_expenditure) * 100.0, 4)
    END                                                 AS instruction_spending_pct

FROM (
    -- Deduplicate silver (same pattern as DimDistrict)
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY nces_district_id
               ORDER BY census_district_id
           ) AS rn
    FROM silver.silver_district_finance
) AS s
INNER JOIN gold.DimDistrict AS dd
    ON s.nces_district_id = dd.nces_district_id
WHERE s.rn = 1;
GO

-- =============================================================================
-- QUICK VALIDATION SUMMARY
-- =============================================================================
SELECT
    COUNT(*)                        AS total_fact_rows,
    COUNT(DISTINCT district_key)    AS distinct_districts,
    COUNT(DISTINCT state_key)       AS distinct_states,
    MIN(fiscal_year)                AS min_fiscal_year,
    MAX(fiscal_year)                AS max_fiscal_year,
    SUM(CASE WHEN enrollment IS NULL OR enrollment = 0 THEN 1 ELSE 0 END)
                                    AS zero_enrollment_rows,
    SUM(CASE WHEN per_pupil_spending IS NULL THEN 1 ELSE 0 END)
                                    AS null_per_pupil_rows
FROM gold.FactFinance;
GO

-- National totals sanity check
SELECT
    SUM(enrollment)             AS national_enrollment,
    SUM(total_revenue)          AS national_total_revenue_000s,
    SUM(federal_revenue)        AS national_fed_revenue_000s,
    SUM(state_revenue)          AS national_state_revenue_000s,
    SUM(local_revenue)          AS national_local_revenue_000s,
    SUM(total_expenditure)      AS national_total_exp_000s,
    SUM(instruction_spending)   AS national_instruction_000s,
    AVG(per_pupil_spending)     AS avg_per_pupil_spending,
    AVG(instruction_spending_pct) AS avg_instruction_pct
FROM gold.FactFinance
WHERE enrollment > 0;
GO

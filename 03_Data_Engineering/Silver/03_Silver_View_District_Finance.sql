-- =============================================================================
-- SILVER LAYER: silver_district_finance view
-- Source: bronze.ELSEC14
-- Purpose: Clean column names, cast types, expose business-readable fields
-- Grain: One row per school district per fiscal year
-- Notes:
--   - STATE is a sequential census code 1-51 (NOT FIPS)
--   - All dollar amounts in $1,000s (matching source)
--   - administration_spending = E08 + E09 (general + school administration)
--   - YRDATA = 14 maps to fiscal_year = 2014
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC ('CREATE SCHEMA silver');
GO

CREATE OR ALTER VIEW silver.silver_district_finance AS
SELECT
    -- Identifiers
    CAST(STATE      AS INT)         AS state_code,
    CAST(IDCENSUS   AS VARCHAR(15)) AS census_district_id,
    CAST(NCESID     AS VARCHAR(12)) AS nces_district_id,
    CAST(NAME       AS VARCHAR(150))AS district_name,
    CAST(CONUM      AS VARCHAR(6))  AS county_fips,
    CAST(SCHLEV     AS INT)         AS school_level,
    CAST(YRDATA     AS INT)         AS yrdata_code,
    2014                            AS fiscal_year,

    -- Enrollment
    CAST(V33        AS DECIMAL(18,2)) AS enrollment,

    -- Revenue ($1,000s)
    CAST(TOTALREV   AS DECIMAL(18,2)) AS total_revenue,
    CAST(TFEDREV    AS DECIMAL(18,2)) AS federal_revenue,
    CAST(TSTREV     AS DECIMAL(18,2)) AS state_revenue,
    CAST(TLOCREV    AS DECIMAL(18,2)) AS local_revenue,

    -- Expenditure — primary aggregates ($1,000s)
    CAST(TOTALEXP   AS DECIMAL(18,2)) AS total_expenditure,
    CAST(TCURINST   AS DECIMAL(18,2)) AS instruction_spending,
    CAST(
        COALESCE(E08, 0) + COALESCE(E09, 0)
    AS DECIMAL(18,2))                 AS administration_spending,
    CAST(TCAPOUT    AS DECIMAL(18,2)) AS capital_spending,

    -- Debt
    CAST(Z32        AS DECIMAL(18,2)) AS debt_outstanding,

    -- Support services detail ($1,000s)
    CAST(TCURSSVC   AS DECIMAL(18,2)) AS total_support_services,
    CAST(E17        AS DECIMAL(18,2)) AS student_support_spending,
    CAST(E07        AS DECIMAL(18,2)) AS instructional_staff_support_spending,
    CAST(V90        AS DECIMAL(18,2)) AS operations_maintenance_spending,
    CAST(V85        AS DECIMAL(18,2)) AS transportation_spending,

    -- Staffing
    CAST(V13        AS DECIMAL(18,2)) AS teacher_fte,
    CAST(V11        AS DECIMAL(18,2)) AS total_staff_fte,

    -- Salaries ($1,000s)
    CAST(W01        AS DECIMAL(18,2)) AS total_salaries,
    CAST(W31        AS DECIMAL(18,2)) AS instruction_salaries,
    CAST(W61        AS DECIMAL(18,2)) AS employee_benefits,

    -- Audit
    load_timestamp,
    source_file

FROM bronze.ELSEC14;
GO

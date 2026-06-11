-- =============================================================================
-- GOLD DIMENSION: DimDistrict
-- Source: silver.silver_district_finance
-- Grain: One row per unique school district (natural key = nces_district_id)
-- Dependency: gold.DimState must exist (01_DimState.sql)
-- Validation target: one row per district_key, no duplicate nces_district_id
-- =============================================================================

IF OBJECT_ID('gold.DimDistrict', 'U') IS NOT NULL
    DROP TABLE gold.DimDistrict;
GO

CREATE TABLE gold.DimDistrict (
    district_key        INT             NOT NULL,   -- Surrogate PK (generated)
    nces_district_id    VARCHAR(12)     NOT NULL,   -- NCES 7-char LEA ID (business key)
    census_district_id  VARCHAR(15)     NOT NULL,   -- Census 13-digit IDCENSUS
    district_name       VARCHAR(150)    NOT NULL,
    state_code          INT             NOT NULL,   -- FK → gold.DimState.state_key
    state_name          VARCHAR(50)     NOT NULL,   -- Denormalized for convenience
    state_abbrev        CHAR(2)         NOT NULL,   -- Denormalized for convenience
    county_fips         VARCHAR(6)      NULL,       -- 5-digit FIPS county code (SSCCC)
    school_level        INT             NOT NULL,   -- 1=Elem, 2=Secondary, 3=Unified
    school_level_desc   VARCHAR(20)     NOT NULL,   -- Human-readable school level
    is_current          BIT             NOT NULL DEFAULT 1,  -- SCD placeholder
    effective_date      DATE            NOT NULL DEFAULT '2014-07-01',
    expiry_date         DATE            NULL,

    CONSTRAINT PK_DimDistrict PRIMARY KEY (district_key),
    CONSTRAINT FK_DimDistrict_DimState
        FOREIGN KEY (state_code) REFERENCES gold.DimState (state_key)
);
GO

-- =============================================================================
-- POPULATE DimDistrict
-- Uses ROW_NUMBER() as surrogate key (IDENTITY not used here for portability).
-- Deduplication: take the single row per nces_district_id (all FY2014 — one year only).
-- =============================================================================
INSERT INTO gold.DimDistrict (
    district_key,
    nces_district_id,
    census_district_id,
    district_name,
    state_code,
    state_name,
    state_abbrev,
    county_fips,
    school_level,
    school_level_desc
)
SELECT
    ROW_NUMBER() OVER (ORDER BY s.state_code, sdf.nces_district_id) AS district_key,
    sdf.nces_district_id,
    sdf.census_district_id,
    sdf.district_name,
    sdf.state_code,
    ds.state_name,
    ds.state_abbrev,
    CASE
        WHEN sdf.county_fips = 'N' OR sdf.county_fips = '' THEN NULL
        ELSE REPLACE(LTRIM(RTRIM(sdf.county_fips)), '.0', '')
    END                     AS county_fips,
    sdf.school_level,
    CASE sdf.school_level
        WHEN 1 THEN 'Elementary'
        WHEN 2 THEN 'Secondary'
        WHEN 3 THEN 'Unified'
        WHEN 5 THEN 'Vocational'
        WHEN 6 THEN 'Other'
        ELSE        'Unknown'
    END                     AS school_level_desc
FROM (
    -- Deduplicate: one row per nces_district_id (in case of duplicates in source)
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY nces_district_id
               ORDER BY census_district_id
           ) AS rn
    FROM silver.silver_district_finance
) AS sdf
INNER JOIN gold.DimState AS ds
    ON sdf.state_code = ds.state_key
WHERE sdf.rn = 1;
GO

-- =============================================================================
-- VALIDATION: One row per district_key and per nces_district_id
-- =============================================================================
DECLARE @total       INT = (SELECT COUNT(*)             FROM gold.DimDistrict);
DECLARE @distinct_nk INT = (SELECT COUNT(DISTINCT nces_district_id) FROM gold.DimDistrict);
DECLARE @dup_count   INT = (
    SELECT COUNT(*) FROM (
        SELECT nces_district_id, COUNT(*) AS cnt
        FROM gold.DimDistrict
        GROUP BY nces_district_id
        HAVING COUNT(*) > 1
    ) AS dups
);

PRINT 'DimDistrict total rows          : ' + CAST(@total       AS VARCHAR);
PRINT 'DimDistrict distinct NCES IDs   : ' + CAST(@distinct_nk AS VARCHAR);
PRINT 'DimDistrict duplicate NCES IDs  : ' + CAST(@dup_count   AS VARCHAR) +
      ' (expected 0)';

IF @dup_count > 0
    RAISERROR('DimDistrict has %d duplicate nces_district_id values.', 16, 1, @dup_count);
ELSE
    PRINT 'DimDistrict PASSED: no duplicate nces_district_id values.';
GO

-- Row count per state (quick audit)
SELECT
    ds.state_abbrev,
    ds.state_name,
    COUNT(dd.district_key) AS district_count
FROM gold.DimDistrict   AS dd
JOIN gold.DimState      AS ds ON dd.state_code = ds.state_key
GROUP BY ds.state_abbrev, ds.state_name
ORDER BY ds.state_name;
GO

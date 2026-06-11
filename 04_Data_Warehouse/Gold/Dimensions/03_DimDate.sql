-- =============================================================================
-- GOLD DIMENSION: DimDate
-- Scope: Fiscal Year 2014 (July 1, 2013 – June 30, 2014)
-- Convention: U.S. public school fiscal year runs July–June.
--             date_key format: YYYYMMDD (INT) for fast joining.
-- Note: Currently loaded for FY2014 only. Schema supports multi-year expansion.
-- =============================================================================

IF OBJECT_ID('gold.DimDate', 'U') IS NOT NULL
    DROP TABLE gold.DimDate;
GO

CREATE TABLE gold.DimDate (
    date_key            INT         NOT NULL,   -- PK: YYYYMMDD integer
    full_date           DATE        NOT NULL,
    day_of_week         INT         NOT NULL,   -- 1=Sunday … 7=Saturday
    day_name            VARCHAR(10) NOT NULL,
    day_of_month        INT         NOT NULL,
    day_of_year         INT         NOT NULL,
    week_of_year        INT         NOT NULL,
    month_number        INT         NOT NULL,
    month_name          VARCHAR(10) NOT NULL,
    month_abbrev        CHAR(3)     NOT NULL,
    quarter_number      INT         NOT NULL,   -- Calendar quarter
    calendar_year       INT         NOT NULL,
    fiscal_year         INT         NOT NULL,   -- U.S. school fiscal year (July–June)
    fiscal_quarter      INT         NOT NULL,   -- Q1=Jul-Sep, Q2=Oct-Dec, Q3=Jan-Mar, Q4=Apr-Jun
    fiscal_month        INT         NOT NULL,   -- Fiscal month 1=July … 12=June
    fiscal_year_label   VARCHAR(10) NOT NULL,   -- e.g. 'FY2014'
    is_weekend          BIT         NOT NULL,
    is_fiscal_year_start BIT        NOT NULL,   -- July 1
    is_fiscal_year_end   BIT        NOT NULL,   -- June 30

    CONSTRAINT PK_DimDate PRIMARY KEY (date_key)
);
GO

-- =============================================================================
-- POPULATE: FY2014 = July 1, 2013 through June 30, 2014
-- Uses a recursive CTE to generate one row per calendar day.
-- =============================================================================
WITH date_spine AS (
    SELECT CAST('2013-07-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM   date_spine
    WHERE  dt < '2014-06-30'
)
INSERT INTO gold.DimDate (
    date_key,
    full_date,
    day_of_week,
    day_name,
    day_of_month,
    day_of_year,
    week_of_year,
    month_number,
    month_name,
    month_abbrev,
    quarter_number,
    calendar_year,
    fiscal_year,
    fiscal_quarter,
    fiscal_month,
    fiscal_year_label,
    is_weekend,
    is_fiscal_year_start,
    is_fiscal_year_end
)
SELECT
    CAST(FORMAT(dt, 'yyyyMMdd') AS INT)         AS date_key,
    dt                                          AS full_date,
    DATEPART(WEEKDAY, dt)                       AS day_of_week,
    DATENAME(WEEKDAY, dt)                       AS day_name,
    DATEPART(DAY,     dt)                       AS day_of_month,
    DATEPART(DAYOFYEAR, dt)                     AS day_of_year,
    DATEPART(WEEK,    dt)                       AS week_of_year,
    DATEPART(MONTH,   dt)                       AS month_number,
    DATENAME(MONTH,   dt)                       AS month_name,
    LEFT(DATENAME(MONTH, dt), 3)                AS month_abbrev,
    DATEPART(QUARTER, dt)                       AS quarter_number,
    DATEPART(YEAR,    dt)                       AS calendar_year,
    -- Fiscal year: July–June, so Jul-Dec 2013 → FY2014, Jan-Jun 2014 → FY2014
    CASE WHEN DATEPART(MONTH, dt) >= 7
         THEN DATEPART(YEAR, dt) + 1
         ELSE DATEPART(YEAR, dt)
    END                                         AS fiscal_year,
    -- Fiscal quarter
    CASE
        WHEN DATEPART(MONTH, dt) IN (7, 8, 9)   THEN 1   -- Q1: Jul–Sep
        WHEN DATEPART(MONTH, dt) IN (10, 11, 12) THEN 2   -- Q2: Oct–Dec
        WHEN DATEPART(MONTH, dt) IN (1, 2, 3)   THEN 3   -- Q3: Jan–Mar
        WHEN DATEPART(MONTH, dt) IN (4, 5, 6)   THEN 4   -- Q4: Apr–Jun
    END                                         AS fiscal_quarter,
    -- Fiscal month (1=July … 12=June)
    CASE
        WHEN DATEPART(MONTH, dt) >= 7
        THEN DATEPART(MONTH, dt) - 6
        ELSE DATEPART(MONTH, dt) + 6
    END                                         AS fiscal_month,
    'FY2014'                                    AS fiscal_year_label,
    CASE WHEN DATEPART(WEEKDAY, dt) IN (1, 7)
         THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
    END                                         AS is_weekend,
    CASE WHEN FORMAT(dt, 'MM-dd') = '07-01'
         THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
    END                                         AS is_fiscal_year_start,
    CASE WHEN FORMAT(dt, 'MM-dd') = '06-30'
         THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
    END                                         AS is_fiscal_year_end
FROM date_spine
OPTION (MAXRECURSION 400);
GO

-- =============================================================================
-- FISCAL YEAR SUMMARY ROW (date_key = 20140000 for fact-level joining)
-- One special row used by FactFinance as the "annual" date_key.
-- =============================================================================
INSERT INTO gold.DimDate (
    date_key, full_date, day_of_week, day_name, day_of_month, day_of_year,
    week_of_year, month_number, month_name, month_abbrev, quarter_number,
    calendar_year, fiscal_year, fiscal_quarter, fiscal_month, fiscal_year_label,
    is_weekend, is_fiscal_year_start, is_fiscal_year_end
)
VALUES (
    20140000,           -- Special annual summary key
    '2014-06-30',       -- End of fiscal year anchor date
    0, 'Annual', 0, 0,
    0, 0, 'Annual', 'ANN', 0,
    2014, 2014, 0, 0, 'FY2014',
    0, 0, 1
);
GO

-- VALIDATION
DECLARE @total_rows  INT = (SELECT COUNT(*) FROM gold.DimDate);
DECLARE @fy_rows     INT = (SELECT COUNT(*) FROM gold.DimDate WHERE fiscal_year = 2014 AND date_key <> 20140000);
DECLARE @annual_key  INT = (SELECT COUNT(*) FROM gold.DimDate WHERE date_key = 20140000);

PRINT 'DimDate total rows        : ' + CAST(@total_rows AS VARCHAR);
PRINT 'DimDate FY2014 daily rows : ' + CAST(@fy_rows AS VARCHAR) + ' (expected 366)';
PRINT 'DimDate annual key row    : ' + CAST(@annual_key AS VARCHAR) + ' (expected 1)';
GO

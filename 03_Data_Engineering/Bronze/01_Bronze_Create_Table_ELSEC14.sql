-- =============================================================================
-- BRONZE LAYER: Raw ingestion table for ELSEC14 (F-33 FY2014 District Finance)
-- Source: U.S. Census Bureau Annual Survey of School System Finances (F-33)
-- Fiscal Year: 2014  |  Grain: One row per school district
-- Target: Microsoft Fabric Warehouse  |  Schema: bronze
-- All financial figures in $1,000s unless noted
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
    EXEC ('CREATE SCHEMA bronze');
GO

IF OBJECT_ID('bronze.ELSEC14', 'U') IS NOT NULL
    DROP TABLE bronze.ELSEC14;
GO

CREATE TABLE bronze.ELSEC14 (
    -- Row identity
    source_row_id       INT,

    -- Geographic / administrative identifiers
    STATE               INT,            -- Census sequential state code 1-51 (NOT FIPS)
    IDCENSUS            VARCHAR(15),    -- 13-digit Census district identifier
    NAME                VARCHAR(150),   -- District name
    CONUM               VARCHAR(6),     -- County FIPS code (5-digit, zero-padded: SSCCC)
    CSA                 VARCHAR(10),    -- Combined Statistical Area code
    CBSA                VARCHAR(10),    -- Core Based Statistical Area code
    SCHLEV              INT,            -- School level: 1=Elem, 2=Secondary, 3=Unified
    NCESID              VARCHAR(12),    -- NCES 7-digit Local Education Agency (LEA) ID
    YRDATA              INT,            -- Fiscal year reported (14 = 2014)

    -- Enrollment
    V33                 DECIMAL(18,2),  -- Total pupil membership (fall enrollment)

    -- -------------------------------------------------------------------------
    -- REVENUE
    -- -------------------------------------------------------------------------
    TOTALREV            DECIMAL(18,2),  -- Total revenue from all sources
    TFEDREV             DECIMAL(18,2),  -- Total federal revenue
        C14             DECIMAL(18,2),  -- Title I
        C15             DECIMAL(18,2),  -- Children with Disabilities (IDEA)
        C16             DECIMAL(18,2),  -- Impact Aid
        C17             DECIMAL(18,2),  -- Vocational/Career & Technical Ed
        C19             DECIMAL(18,2),  -- Other federal through state
        B11             DECIMAL(18,2),  -- Federal free/reduced lunch
        C20             DECIMAL(18,2),  -- Federal bilingual/migrant
        C25             DECIMAL(18,2),  -- Drug-free schools federal
        C36             DECIMAL(18,2),  -- Federal homeland security
        B10             DECIMAL(18,2),  -- Head Start
        B12             DECIMAL(18,2),  -- Indian Education
        B13             DECIMAL(18,2),  -- Other federal direct
    TSTREV              DECIMAL(18,2),  -- Total state revenue
        C01             DECIMAL(18,2),  -- General formula assistance (state)
        C04             DECIMAL(18,2),  -- Staff improvement programs (state)
        C05             DECIMAL(18,2),  -- Special education (state)
        C06             DECIMAL(18,2),  -- Compensatory / basic skills (state)
        C07             DECIMAL(18,2),  -- Bilingual education (state)
        C08             DECIMAL(18,2),  -- Gifted and talented (state)
        C09             DECIMAL(18,2),  -- Vocational education (state)
        C10             DECIMAL(18,2),  -- School lunch/nutrition (state)
        C11             DECIMAL(18,2),  -- Capital outlay and debt service (state)
        C12             DECIMAL(18,2),  -- Transportation (state)
        C13             DECIMAL(18,2),  -- Other state revenue
        C24             DECIMAL(18,2),  -- Employee benefits (state)
        C35             DECIMAL(18,2),  -- State revenue for community services
        C38             DECIMAL(18,2),  -- State revenue for adult education
        C39             DECIMAL(18,2),  -- State revenue — other
    TLOCREV             DECIMAL(18,2),  -- Total local revenue
        T02             DECIMAL(18,2),  -- Local property taxes
        T06             DECIMAL(18,2),  -- General sales taxes (local)
        T09             DECIMAL(18,2),  -- Other local taxes
        T15             DECIMAL(18,2),  -- Individual income taxes (local)
        T40             DECIMAL(18,2),  -- Tuition and transportation fees
        T99             DECIMAL(18,2),  -- Other local revenue
        D11             DECIMAL(18,2),  -- Local revenue from county sources
        D23             DECIMAL(18,2),  -- Local revenue from city/municipal
        A07             DECIMAL(18,2),  -- Local revenue from special districts
        A08             DECIMAL(18,2),  -- Local revenue from states (pass-through)
        A09             DECIMAL(18,2),  -- School lunch revenue (local)
        A11             DECIMAL(18,2),  -- Textbook revenue (local)
        A13             DECIMAL(18,2),  -- Student activities revenue
        A15             DECIMAL(18,2),  -- Other current charges
        A20             DECIMAL(18,2),  -- Interest earnings
        A40             DECIMAL(18,2),  -- Sale of property
        U11             DECIMAL(18,2),  -- Enterprise operations
        U22             DECIMAL(18,2),  -- Impact Aid from U.S. Gov. (local share)
        U30             DECIMAL(18,2),  -- Private contributions
        U50             DECIMAL(18,2),  -- Other local — miscellaneous
        U97             DECIMAL(18,2),  -- Local revenue from cities and counties (inter-govt)

    -- -------------------------------------------------------------------------
    -- EXPENDITURE — CURRENT OPERATIONS
    -- -------------------------------------------------------------------------
    TOTALEXP            DECIMAL(18,2),  -- Total expenditure
    TCURELSC            DECIMAL(18,2),  -- Total current expenditure (elem/secondary)
    TCURINST            DECIMAL(18,2),  -- Total current instruction expenditure
        E13             DECIMAL(18,2),  -- Instruction — current charges
        J13             DECIMAL(18,2),  -- Instruction — interest
        J12             DECIMAL(18,2),  -- Instruction — other
        J14             DECIMAL(18,2),  -- Instruction — capital outlay
        V91             DECIMAL(18,2),  -- Instruction — other 1
        V92             DECIMAL(18,2),  -- Instruction — other 2
    TCURSSVC            DECIMAL(18,2),  -- Total current support services
        E17             DECIMAL(18,2),  -- Pupil support services
        E07             DECIMAL(18,2),  -- Instructional staff support
        E08             DECIMAL(18,2),  -- General administration
        E09             DECIMAL(18,2),  -- School administration
        V40             DECIMAL(18,2),  -- General administration (total)
        V45             DECIMAL(18,2),  -- School administration (total)
        V90             DECIMAL(18,2),  -- Operations and maintenance
        V85             DECIMAL(18,2),  -- Student transportation
        J17             DECIMAL(18,2),  -- Pupil support — interest
        J07             DECIMAL(18,2),  -- Instructional staff — interest
        J08             DECIMAL(18,2),  -- General admin — interest
        J09             DECIMAL(18,2),  -- School admin — interest
        J40             DECIMAL(18,2),  -- General admin — capital
        J45             DECIMAL(18,2),  -- School admin — capital
        J90             DECIMAL(18,2),  -- Operations — interest
        J11             DECIMAL(18,2),  -- Other support — interest
        J96             DECIMAL(18,2),  -- Support services — other
    TCUROTH             DECIMAL(18,2),  -- Other current expenditure
        E11             DECIMAL(18,2),  -- Food services
        V60             DECIMAL(18,2),  -- Enterprise operations
        V65             DECIMAL(18,2),  -- Community services
        J10             DECIMAL(18,2),  -- Food services — interest
        J97             DECIMAL(18,2),  -- Other current — interest
    NONELSEC            DECIMAL(18,2),  -- Non-elementary/secondary programs
        V70             DECIMAL(18,2),  -- Adult education
        V75             DECIMAL(18,2),  -- Community colleges
        V80             DECIMAL(18,2),  -- Other non-K12 programs
        J98             DECIMAL(18,2),  -- Non-K12 — interest

    -- -------------------------------------------------------------------------
    -- EXPENDITURE — CAPITAL OUTLAY
    -- -------------------------------------------------------------------------
    TCAPOUT             DECIMAL(18,2),  -- Total capital outlay
        F12             DECIMAL(18,2),  -- Construction
        G15             DECIMAL(18,2),  -- Land and existing structures
        K09             DECIMAL(18,2),  -- Instructional equipment
        K10             DECIMAL(18,2),  -- Non-instructional equipment
        K11             DECIMAL(18,2),  -- Technology equipment
        J99             DECIMAL(18,2),  -- Capital outlay — interest
        L12             DECIMAL(18,2),  -- Capital outlay — other
        M12             DECIMAL(18,2),  -- Capital outlay — property
        Q11             DECIMAL(18,2),  -- Capital outlay — other 2
        I86             DECIMAL(18,2),  -- Interest on long-term debt

    -- -------------------------------------------------------------------------
    -- DEBT
    -- -------------------------------------------------------------------------
    Z32                 DECIMAL(18,2),  -- Long-term debt outstanding end of year
    Z33                 DECIMAL(18,2),  -- Short-term debt outstanding end of year

    -- -------------------------------------------------------------------------
    -- STAFFING (full-time equivalents)
    -- -------------------------------------------------------------------------
    V11                 DECIMAL(18,2),  -- Total FTE staff
    V13                 DECIMAL(18,2),  -- Teachers FTE
    V15                 DECIMAL(18,2),  -- Instructional aides FTE
    V17                 DECIMAL(18,2),  -- Instructional coordinators FTE
    V21                 DECIMAL(18,2),  -- Principals FTE
    V23                 DECIMAL(18,2),  -- Library/media staff FTE
    V37                 DECIMAL(18,2),  -- Guidance counselors FTE
    V29                 DECIMAL(18,2),  -- Support staff FTE
    Z34                 DECIMAL(18,2),  -- Student/teacher ratio
    V10                 DECIMAL(18,2),  -- Total staff headcount
    V12                 DECIMAL(18,2),  -- Teacher headcount
    V14                 DECIMAL(18,2),  -- Instructional aides headcount
    V16                 DECIMAL(18,2),  -- Instructional coordinators headcount
    V18                 DECIMAL(18,2),  -- Principals headcount
    V22                 DECIMAL(18,2),  -- Library/media headcount
    V24                 DECIMAL(18,2),  -- Guidance counselors headcount
    V38                 DECIMAL(18,2),  -- Other support headcount
    V30                 DECIMAL(18,2),  -- Administrative headcount
    V32                 DECIMAL(18,2),  -- Administrative FTE

    -- -------------------------------------------------------------------------
    -- ADDITIONAL METRICS
    -- -------------------------------------------------------------------------
    _19H                DECIMAL(18,2),
    _21F                DECIMAL(18,2),
    _31F                DECIMAL(18,2),
    _41F                DECIMAL(18,2),
    _61V                DECIMAL(18,2),
    _66V                DECIMAL(18,2),
    W01                 DECIMAL(18,2),  -- Total salaries
    W31                 DECIMAL(18,2),  -- Instruction salaries
    W61                 DECIMAL(18,2),  -- Employee benefits

    -- Audit columns
    load_timestamp      DATETIME2       DEFAULT GETUTCDATE(),
    source_file         VARCHAR(50)     DEFAULT 'elsec14.csv'
);
GO

-- =============================================================================
-- NOTE: Load via Fabric COPY INTO or pipeline from ADLS Gen2 path:
--   COPY INTO bronze.ELSEC14
--   FROM 'https://<storage>.dfs.core.windows.net/<container>/raw/elsec14.csv'
--   WITH (FILE_TYPE = 'CSV', FIRSTROW = 2);
-- =============================================================================

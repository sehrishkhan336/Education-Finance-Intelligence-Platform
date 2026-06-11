-- =============================================================================
-- GOLD DIMENSION: DimState
-- Source: Static reference — Census Bureau sequential state codes 1–51
-- Note: STATE codes in ELSEC14 are sequential alphabetical order (NOT FIPS).
--       50 U.S. states + District of Columbia = 51 rows.
--       state_key = state_code (no separate surrogate needed; values are 1–51).
-- Validation target: 51 rows exactly
-- =============================================================================

IF OBJECT_ID('gold.DimState', 'U') IS NOT NULL
    DROP TABLE gold.DimState;
GO

CREATE TABLE gold.DimState (
    state_key       INT             NOT NULL,   -- PK = sequential census code 1–51
    state_code      INT             NOT NULL,   -- Same as state_key; kept for readability
    state_name      VARCHAR(50)     NOT NULL,
    state_abbrev    CHAR(2)         NOT NULL,
    fips_code       CHAR(2)         NOT NULL,   -- Federal FIPS code (different from state_code)
    census_region   VARCHAR(20)     NOT NULL,   -- Northeast / Midwest / South / West
    census_division VARCHAR(35)     NOT NULL,   -- Census Bureau geographic division

    CONSTRAINT PK_DimState PRIMARY KEY (state_key)
);
GO

-- =============================================================================
-- INSERT: All 51 rows (50 states + DC)
-- Ordered by Census sequential code (alphabetical by state name)
-- Columns: state_key, state_code, state_name, state_abbrev, fips_code, region, division
-- =============================================================================
INSERT INTO gold.DimState
    (state_key, state_code, state_name, state_abbrev, fips_code, census_region, census_division)
VALUES
    ( 1,  1, 'Alabama',              'AL', '01', 'South',     'East South Central'),
    ( 2,  2, 'Alaska',               'AK', '02', 'West',      'Pacific'),
    ( 3,  3, 'Arizona',              'AZ', '04', 'West',      'Mountain'),
    ( 4,  4, 'Arkansas',             'AR', '05', 'South',     'West South Central'),
    ( 5,  5, 'California',           'CA', '06', 'West',      'Pacific'),
    ( 6,  6, 'Colorado',             'CO', '08', 'West',      'Mountain'),
    ( 7,  7, 'Connecticut',          'CT', '09', 'Northeast', 'New England'),
    ( 8,  8, 'Delaware',             'DE', '10', 'South',     'South Atlantic'),
    ( 9,  9, 'District of Columbia', 'DC', '11', 'South',     'South Atlantic'),
    (10, 10, 'Florida',              'FL', '12', 'South',     'South Atlantic'),
    (11, 11, 'Georgia',              'GA', '13', 'South',     'South Atlantic'),
    (12, 12, 'Hawaii',               'HI', '15', 'West',      'Pacific'),
    (13, 13, 'Idaho',                'ID', '16', 'West',      'Mountain'),
    (14, 14, 'Illinois',             'IL', '17', 'Midwest',   'East North Central'),
    (15, 15, 'Indiana',              'IN', '18', 'Midwest',   'East North Central'),
    (16, 16, 'Iowa',                 'IA', '19', 'Midwest',   'West North Central'),
    (17, 17, 'Kansas',               'KS', '20', 'Midwest',   'West North Central'),
    (18, 18, 'Kentucky',             'KY', '21', 'South',     'East South Central'),
    (19, 19, 'Louisiana',            'LA', '22', 'South',     'West South Central'),
    (20, 20, 'Maine',                'ME', '23', 'Northeast', 'New England'),
    (21, 21, 'Maryland',             'MD', '24', 'South',     'South Atlantic'),
    (22, 22, 'Massachusetts',        'MA', '25', 'Northeast', 'New England'),
    (23, 23, 'Michigan',             'MI', '26', 'Midwest',   'East North Central'),
    (24, 24, 'Minnesota',            'MN', '27', 'Midwest',   'West North Central'),
    (25, 25, 'Mississippi',          'MS', '28', 'South',     'East South Central'),
    (26, 26, 'Missouri',             'MO', '29', 'Midwest',   'West North Central'),
    (27, 27, 'Montana',              'MT', '30', 'West',      'Mountain'),
    (28, 28, 'Nebraska',             'NE', '31', 'Midwest',   'West North Central'),
    (29, 29, 'Nevada',               'NV', '32', 'West',      'Mountain'),
    (30, 30, 'New Hampshire',        'NH', '33', 'Northeast', 'New England'),
    (31, 31, 'New Jersey',           'NJ', '34', 'Northeast', 'Mid-Atlantic'),
    (32, 32, 'New Mexico',           'NM', '35', 'West',      'Mountain'),
    (33, 33, 'New York',             'NY', '36', 'Northeast', 'Mid-Atlantic'),
    (34, 34, 'North Carolina',       'NC', '37', 'South',     'South Atlantic'),
    (35, 35, 'North Dakota',         'ND', '38', 'Midwest',   'West North Central'),
    (36, 36, 'Ohio',                 'OH', '39', 'Midwest',   'East North Central'),
    (37, 37, 'Oklahoma',             'OK', '40', 'South',     'West South Central'),
    (38, 38, 'Oregon',               'OR', '41', 'West',      'Pacific'),
    (39, 39, 'Pennsylvania',         'PA', '42', 'Northeast', 'Mid-Atlantic'),
    (40, 40, 'Rhode Island',         'RI', '44', 'Northeast', 'New England'),
    (41, 41, 'South Carolina',       'SC', '45', 'South',     'South Atlantic'),
    (42, 42, 'South Dakota',         'SD', '46', 'Midwest',   'West North Central'),
    (43, 43, 'Tennessee',            'TN', '47', 'South',     'East South Central'),
    (44, 44, 'Texas',                'TX', '48', 'South',     'West South Central'),
    (45, 45, 'Utah',                 'UT', '49', 'West',      'Mountain'),
    (46, 46, 'Vermont',              'VT', '50', 'Northeast', 'New England'),
    (47, 47, 'Virginia',             'VA', '51', 'South',     'South Atlantic'),
    (48, 48, 'Washington',           'WA', '53', 'West',      'Pacific'),
    (49, 49, 'West Virginia',        'WV', '54', 'South',     'South Atlantic'),
    (50, 50, 'Wisconsin',            'WI', '55', 'Midwest',   'East North Central'),
    (51, 51, 'Wyoming',              'WY', '56', 'West',      'Mountain');
GO

-- =============================================================================
-- VALIDATION: Row count must equal 51
-- =============================================================================
DECLARE @row_count INT = (SELECT COUNT(*) FROM gold.DimState);
IF @row_count <> 51
    RAISERROR('DimState row count = %d. Expected 51.', 16, 1, @row_count);
ELSE
    PRINT 'DimState PASSED: ' + CAST(@row_count AS VARCHAR) + ' rows (expected 51)';
GO

-- Quick review
SELECT
    state_key,
    state_code,
    state_name,
    state_abbrev,
    fips_code,
    census_region,
    census_division
FROM gold.DimState
ORDER BY state_key;
GO

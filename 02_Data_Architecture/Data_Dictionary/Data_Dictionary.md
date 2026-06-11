# Data Dictionary — Education Finance Intelligence Platform

## Document Information
- **Source:** U.S. Census Bureau F-33, Annual Survey of School System Finances, FY2014  
- **Platform:** Microsoft Fabric Warehouse  
- **Layers:** Bronze (raw) → Silver (view) → Gold (star schema)  
- **Last Updated:** 2026-06-10

---

## Layer Descriptions

| Layer | Object | Type | Purpose |
|---|---|---|---|
| Bronze | bronze.ELSEC14 | Table | Raw ingestion of elsec14.csv; no transformations |
| Silver | silver.silver_district_finance | View | Renamed columns, cast types, derived fiscal_year |
| Gold | gold.DimState | Table | State reference dimension, 51 rows |
| Gold | gold.DimDistrict | Table | District dimension, ~14,400 rows |
| Gold | gold.DimDate | Table | Date dimension for FY2014 (366 daily + 1 annual) |
| Gold | gold.FactFinance | Table | Central fact table, district-year grain |

---

## Bronze: bronze.ELSEC14

Raw column mapping from the Census Bureau F-33 codebook.

| Source Column | Business Name | Data Type | Unit | Notes |
|---|---|---|---|---|
| STATE | state_code | INT | — | Sequential 1–51 (NOT FIPS) |
| IDCENSUS | census_district_id | VARCHAR(15) | — | 13-digit Census district ID |
| NAME | district_name | VARCHAR(150) | — | Official district name |
| CONUM | county_fips | VARCHAR(6) | — | 5-digit FIPS county code |
| SCHLEV | school_level | INT | — | 1=Elem, 2=Secondary, 3=Unified |
| NCESID | nces_district_id | VARCHAR(12) | — | NCES 7-char LEA ID |
| YRDATA | yrdata_code | INT | — | 14 = FY2014 |
| V33 | enrollment | DECIMAL(18,2) | Students | Fall pupil membership |
| TOTALREV | total_revenue | DECIMAL(18,2) | $1,000s | Revenue all sources |
| TFEDREV | federal_revenue | DECIMAL(18,2) | $1,000s | Federal revenue |
| TSTREV | state_revenue | DECIMAL(18,2) | $1,000s | State revenue |
| TLOCREV | local_revenue | DECIMAL(18,2) | $1,000s | Local revenue |
| TOTALEXP | total_expenditure | DECIMAL(18,2) | $1,000s | Total expenditure |
| TCURINST | instruction_spending | DECIMAL(18,2) | $1,000s | Current instruction |
| E08 | general_admin_spending | DECIMAL(18,2) | $1,000s | General administration |
| E09 | school_admin_spending | DECIMAL(18,2) | $1,000s | School administration |
| TCAPOUT | capital_spending | DECIMAL(18,2) | $1,000s | Capital outlay total |
| Z32 | debt_outstanding | DECIMAL(18,2) | $1,000s | Long-term debt, end of year |
| TCURSSVC | total_support_services | DECIMAL(18,2) | $1,000s | Total support services |
| V13 | teacher_fte | DECIMAL(18,2) | FTEs | Teacher full-time equivalents |
| W01 | total_salaries | DECIMAL(18,2) | $1,000s | Total salaries |
| W31 | instruction_salaries | DECIMAL(18,2) | $1,000s | Instruction salaries |
| W61 | employee_benefits | DECIMAL(18,2) | $1,000s | Employee benefits |

---

## Silver: silver.silver_district_finance

View over bronze.ELSEC14 with cleaned column names and derived fields.

| Column | Type | Source | Description |
|---|---|---|---|
| state_code | INT | STATE | Census sequential code 1–51 |
| census_district_id | VARCHAR(15) | IDCENSUS | 13-digit Census district ID |
| nces_district_id | VARCHAR(12) | NCESID | NCES 7-char LEA ID |
| district_name | VARCHAR(150) | NAME | District name |
| county_fips | VARCHAR(6) | CONUM | FIPS county code |
| school_level | INT | SCHLEV | School type code |
| yrdata_code | INT | YRDATA | Source year code (14) |
| fiscal_year | INT | Derived (=2014) | Fiscal year |
| enrollment | DECIMAL(18,2) | V33 | Fall pupil membership |
| total_revenue | DECIMAL(18,2) | TOTALREV | Total revenue ($1K) |
| federal_revenue | DECIMAL(18,2) | TFEDREV | Federal revenue ($1K) |
| state_revenue | DECIMAL(18,2) | TSTREV | State revenue ($1K) |
| local_revenue | DECIMAL(18,2) | TLOCREV | Local revenue ($1K) |
| total_expenditure | DECIMAL(18,2) | TOTALEXP | Total expenditure ($1K) |
| instruction_spending | DECIMAL(18,2) | TCURINST | Current instruction ($1K) |
| administration_spending | DECIMAL(18,2) | E08+E09 | Gen + school admin ($1K) |
| capital_spending | DECIMAL(18,2) | TCAPOUT | Capital outlay ($1K) |
| debt_outstanding | DECIMAL(18,2) | Z32 | Long-term debt ($1K) |
| total_support_services | DECIMAL(18,2) | TCURSSVC | Total support services ($1K) |
| student_support_spending | DECIMAL(18,2) | E17 | Student support ($1K) |
| instructional_staff_support_spending | DECIMAL(18,2) | E07 | Staff support ($1K) |
| operations_maintenance_spending | DECIMAL(18,2) | V90 | O&M spending ($1K) |
| transportation_spending | DECIMAL(18,2) | V85 | Transportation ($1K) |
| teacher_fte | DECIMAL(18,2) | V13 | Teacher FTEs |
| total_staff_fte | DECIMAL(18,2) | V11 | Total staff FTEs |
| total_salaries | DECIMAL(18,2) | W01 | Total salaries ($1K) |
| instruction_salaries | DECIMAL(18,2) | W31 | Instruction salaries ($1K) |
| employee_benefits | DECIMAL(18,2) | W61 | Benefits ($1K) |

---

## Gold: DimState

| Column | Type | PK/FK | Description |
|---|---|---|---|
| state_key | INT | PK | Sequential Census code 1–51 |
| state_code | INT | — | Same as state_key |
| state_name | VARCHAR(50) | — | Full state name |
| state_abbrev | CHAR(2) | — | Two-letter abbreviation |
| fips_code | CHAR(2) | — | Federal FIPS code (differs from state_code) |
| census_region | VARCHAR(20) | — | Northeast / Midwest / South / West |
| census_division | VARCHAR(35) | — | Census division name |

---

## Gold: DimDistrict

| Column | Type | PK/FK | Description |
|---|---|---|---|
| district_key | INT | PK | Surrogate key |
| nces_district_id | VARCHAR(12) | BK | NCES LEA ID (unique business key) |
| census_district_id | VARCHAR(15) | — | Census 13-digit ID |
| district_name | VARCHAR(150) | — | District name |
| state_code | INT | FK→DimState | Census sequential state code |
| state_name | VARCHAR(50) | — | Denormalized state name |
| state_abbrev | CHAR(2) | — | Denormalized abbreviation |
| county_fips | VARCHAR(6) | — | 5-digit FIPS county code (nullable) |
| school_level | INT | — | School type code |
| school_level_desc | VARCHAR(20) | — | Elementary / Secondary / Unified / Vocational / Other |
| is_current | BIT | — | SCD Type 2 active flag (=1 for all FY2014) |
| effective_date | DATE | — | 2014-07-01 |
| expiry_date | DATE | — | NULL = active |

---

## Gold: DimDate

| Column | Type | PK/FK | Description |
|---|---|---|---|
| date_key | INT | PK | YYYYMMDD integer; 20140000=annual summary |
| full_date | DATE | — | Calendar date |
| fiscal_year | INT | — | 2014 (U.S. school fiscal year July–June) |
| fiscal_quarter | INT | — | 1=Jul–Sep, 2=Oct–Dec, 3=Jan–Mar, 4=Apr–Jun |
| fiscal_month | INT | — | 1=July … 12=June |
| fiscal_year_label | VARCHAR(10) | — | 'FY2014' |
| calendar_year | INT | — | 2013 or 2014 |
| month_number | INT | — | 1–12 |
| month_name | VARCHAR(10) | — | Full month name |
| is_weekend | BIT | — | 1 = Saturday or Sunday |
| is_fiscal_year_start | BIT | — | 1 = July 1 |
| is_fiscal_year_end | BIT | — | 1 = June 30 |

---

## Gold: FactFinance

### Keys
| Column | Type | FK | Description |
|---|---|---|---|
| fact_key | INT | PK | Surrogate |
| district_key | INT | DimDistrict | District FK |
| state_key | INT | DimState | State FK |
| date_key | INT | DimDate | Annual row FK (=20140000) |
| fiscal_year | INT | — | 2014 |
| nces_district_id | VARCHAR(12) | — | Degenerate dimension |
| census_district_id | VARCHAR(15) | — | Degenerate dimension |

### Measures — Enrollment
| Column | Type | Unit | Source | Description |
|---|---|---|---|---|
| enrollment | DECIMAL(18,2) | Students | V33 | Fall pupil membership |

### Measures — Revenue ($1,000s)
| Column | Type | Unit | Source | Description |
|---|---|---|---|---|
| total_revenue | DECIMAL(18,2) | $1K | TOTALREV | Revenue from all sources |
| federal_revenue | DECIMAL(18,2) | $1K | TFEDREV | Federal government revenue |
| state_revenue | DECIMAL(18,2) | $1K | TSTREV | State government revenue |
| local_revenue | DECIMAL(18,2) | $1K | TLOCREV | Local sources (property tax, fees) |

### Measures — Expenditure ($1,000s)
| Column | Type | Unit | Source | Description |
|---|---|---|---|---|
| total_expenditure | DECIMAL(18,2) | $1K | TOTALEXP | All expenditures |
| instruction_spending | DECIMAL(18,2) | $1K | TCURINST | Teacher salaries, materials, classroom |
| administration_spending | DECIMAL(18,2) | $1K | E08+E09 | General + school administration |
| capital_spending | DECIMAL(18,2) | $1K | TCAPOUT | Buildings, equipment, technology |
| support_services | DECIMAL(18,2) | $1K | TCURSSVC | Pupil, instructional, operational support |

### Measures — Debt
| Column | Type | Unit | Source | Description |
|---|---|---|---|---|
| debt_outstanding | DECIMAL(18,2) | $1K | Z32 | Long-term debt at end of fiscal year |

### Calculated Fields
| Column | Type | Unit | Formula | Description |
|---|---|---|---|---|
| per_pupil_spending | DECIMAL(18,2) | $ | (total_expenditure × 1000) ÷ enrollment | Actual dollars per enrolled student |
| revenue_per_student | DECIMAL(18,2) | $ | (total_revenue × 1000) ÷ enrollment | Actual dollars of revenue per student |
| federal_revenue_pct | DECIMAL(8,4) | % | federal_revenue ÷ total_revenue × 100 | Federal share of total revenue |
| state_revenue_pct | DECIMAL(8,4) | % | state_revenue ÷ total_revenue × 100 | State share of total revenue |
| local_revenue_pct | DECIMAL(8,4) | % | local_revenue ÷ total_revenue × 100 | Local share of total revenue |
| instruction_spending_pct | DECIMAL(8,4) | % | instruction_spending ÷ total_expenditure × 100 | Instruction as % of total spending |

---

## Business Rules

1. **Revenue identity:** `total_revenue = federal_revenue + state_revenue + local_revenue` (±$1K tolerance)
2. **Enrollment scope:** Zero-enrollment districts exist in the source (administrative/fiscal-only entities). Per-pupil fields are NULL for these districts — not zero.
3. **Dollar units:** All stored financial measures are in $1,000s. Per-pupil measures are stored in actual dollars for Power BI usability.
4. **STATE code ≠ FIPS:** Census sequential codes 1–51 must be resolved through DimState to obtain FIPS codes.
5. **administration_spending** is E08 + E09 only (current expenditure classification). It does not include interest or capital outlays for administration.
6. **Fiscal year definition:** July 1 through June 30 of the following calendar year. FY2014 = July 1, 2013 – June 30, 2014.

---

## Known Data Quality Notes

| Issue | Scope | Handling |
|---|---|---|
| Zero-enrollment districts | ~small subset | Per-pupil fields set to NULL (not zero) |
| CSA/CBSA coded as 'N' | Nationwide | Treated as non-metropolitan; not loaded to Gold |
| CONUM decimal suffix (.0) | Raw CSV | Stripped in DimDistrict SQL (`REPLACE(..., '.0', '')`) |
| Negative financial values | Rare | Flagged in 09_Validate_Expenditure.sql; not filtered out |

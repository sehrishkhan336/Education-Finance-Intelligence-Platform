# Star Schema Design — Education Finance Intelligence Platform

## Overview

Architecture: Kimball Star Schema  
Warehouse: Microsoft Fabric Warehouse (T-SQL)  
Data source: U.S. Census Bureau F-33 Annual Survey of School System Finances, FY2014  
Fact grain: **One row per school district per fiscal year**  
Total districts: ~14,400 | States: 51 (50 states + DC)

---

## Schema Diagram

```
                         ┌──────────────┐
                         │  DimDate     │
                         │  (date_key)  │
                         └──────┬───────┘
                                │ FK: date_key
                                │
┌──────────────┐    FK:  ┌──────┴────────────────────────────┐    FK:  ┌───────────────┐
│  DimState    ├─────────┤           FactFinance              ├─────────┤  DimDistrict  │
│  (state_key) │state_key│  (fact_key, district_key,          │district │  (district_key│
│              │         │   state_key, date_key,             │  _key   │   state_code) │
└──────────────┘         │   fiscal_year)                     │         └───────────────┘
                         │                                    │
                         │  MEASURES:                         │
                         │   enrollment                       │
                         │   total_revenue                    │
                         │   federal_revenue                  │
                         │   state_revenue                    │
                         │   local_revenue                    │
                         │   total_expenditure                │
                         │   instruction_spending             │
                         │   administration_spending          │
                         │   capital_spending                 │
                         │   support_services                 │
                         │   debt_outstanding                 │
                         │                                    │
                         │  CALCULATED:                       │
                         │   per_pupil_spending               │
                         │   revenue_per_student              │
                         │   federal_revenue_pct              │
                         │   state_revenue_pct                │
                         │   local_revenue_pct                │
                         │   instruction_spending_pct         │
                         └────────────────────────────────────┘
```

---

## Dimension Tables

### DimState
| Column | Type | Description |
|---|---|---|
| state_key | INT (PK) | Sequential Census code 1–51 (also used as surrogate) |
| state_code | INT | Same as state_key; retained for readability |
| state_name | VARCHAR(50) | Full state name |
| state_abbrev | CHAR(2) | USPS two-letter abbreviation |
| fips_code | CHAR(2) | Federal FIPS state code (different from state_code) |
| census_region | VARCHAR(20) | Northeast / Midwest / South / West |
| census_division | VARCHAR(35) | Census Bureau geographic division |

**Row count:** 51 (50 states + District of Columbia)  
**Important:** `state_code` is the Census Bureau sequential ordering (alphabetical), **not** the FIPS code. STATE=1 → Alabama, STATE=51 → Wyoming.

---

### DimDistrict
| Column | Type | Description |
|---|---|---|
| district_key | INT (PK) | Surrogate key (ROW_NUMBER) |
| nces_district_id | VARCHAR(12) | NCES 7-character LEA ID (business key) |
| census_district_id | VARCHAR(15) | Census 13-digit IDCENSUS |
| district_name | VARCHAR(150) | Official district name |
| state_code | INT (FK) | FK → DimState.state_key |
| state_name | VARCHAR(50) | Denormalized from DimState |
| state_abbrev | CHAR(2) | Denormalized from DimState |
| county_fips | VARCHAR(6) | 5-digit FIPS county code (SSCCC format) |
| school_level | INT | 1=Elementary, 2=Secondary, 3=Unified, 5=Vocational, 6=Other |
| school_level_desc | VARCHAR(20) | Human-readable school level |
| is_current | BIT | SCD placeholder (always 1 for single-year load) |
| effective_date | DATE | 2014-07-01 |
| expiry_date | DATE | NULL (active record) |

**Row count:** ~14,400 (one per unique district in FY2014)

---

### DimDate
| Column | Type | Description |
|---|---|---|
| date_key | INT (PK) | YYYYMMDD integer key; 20140000 = annual summary row |
| full_date | DATE | Calendar date |
| day_of_week | INT | 1=Sunday … 7=Saturday |
| day_name | VARCHAR(10) | Full weekday name |
| day_of_month | INT | 1–31 |
| day_of_year | INT | 1–366 |
| week_of_year | INT | ISO week |
| month_number | INT | 1–12 |
| month_name | VARCHAR(10) | Full month name |
| month_abbrev | CHAR(3) | Jan–Dec |
| quarter_number | INT | Calendar quarter 1–4 |
| calendar_year | INT | 2013 or 2014 |
| fiscal_year | INT | 2014 (U.S. school fiscal year July–June) |
| fiscal_quarter | INT | Q1=Jul–Sep, Q2=Oct–Dec, Q3=Jan–Mar, Q4=Apr–Jun |
| fiscal_month | INT | 1=July … 12=June |
| fiscal_year_label | VARCHAR(10) | 'FY2014' |
| is_weekend | BIT | 1 if Saturday or Sunday |
| is_fiscal_year_start | BIT | 1 if July 1 |
| is_fiscal_year_end | BIT | 1 if June 30 |

**Row count:** 367 (366 daily rows for FY2014 + 1 annual summary row at date_key=20140000)

---

## Fact Table

### FactFinance
**Grain:** One row per school district per fiscal year  
**Dollar unit:** $1,000s (matching Census Bureau source)  
**Per-pupil fields:** Actual dollars (source $1,000s × 1000 ÷ enrollment)

| Column | Type | Source | Description |
|---|---|---|---|
| fact_key | INT (PK) | Generated | Surrogate key |
| district_key | INT (FK) | Lookup | FK → DimDistrict |
| state_key | INT (FK) | Lookup | FK → DimState |
| date_key | INT (FK) | Fixed=20140000 | FK → DimDate annual row |
| fiscal_year | INT | Derived | 2014 |
| nces_district_id | VARCHAR(12) | NCESID | Degenerate dimension |
| census_district_id | VARCHAR(15) | IDCENSUS | Degenerate dimension |
| enrollment | DECIMAL(18,2) | V33 | Fall pupil membership |
| total_revenue | DECIMAL(18,2) | TOTALREV | Total revenue all sources ($1K) |
| federal_revenue | DECIMAL(18,2) | TFEDREV | Federal revenue ($1K) |
| state_revenue | DECIMAL(18,2) | TSTREV | State revenue ($1K) |
| local_revenue | DECIMAL(18,2) | TLOCREV | Local revenue ($1K) |
| total_expenditure | DECIMAL(18,2) | TOTALEXP | Total expenditure ($1K) |
| instruction_spending | DECIMAL(18,2) | TCURINST | Current instruction ($1K) |
| administration_spending | DECIMAL(18,2) | E08+E09 | General + school admin ($1K) |
| capital_spending | DECIMAL(18,2) | TCAPOUT | Capital outlay ($1K) |
| support_services | DECIMAL(18,2) | TCURSSVC | Total support services ($1K) |
| debt_outstanding | DECIMAL(18,2) | Z32 | Long-term debt end of year ($1K) |
| per_pupil_spending | DECIMAL(18,2) | Calculated | total_exp × 1000 ÷ enrollment |
| revenue_per_student | DECIMAL(18,2) | Calculated | total_rev × 1000 ÷ enrollment |
| federal_revenue_pct | DECIMAL(8,4) | Calculated | federal ÷ total_revenue × 100 |
| state_revenue_pct | DECIMAL(8,4) | Calculated | state ÷ total_revenue × 100 |
| local_revenue_pct | DECIMAL(8,4) | Calculated | local ÷ total_revenue × 100 |
| instruction_spending_pct | DECIMAL(8,4) | Calculated | instruction ÷ total_exp × 100 |

---

## Relationships

| Relationship | Type | Cardinality |
|---|---|---|
| FactFinance → DimDistrict | Many-to-One | Many facts per district (1 here — single year) |
| FactFinance → DimState | Many-to-One | Many districts per state |
| FactFinance → DimDate | Many-to-One | All facts share date_key=20140000 |
| DimDistrict → DimState | Many-to-One | Many districts per state |

No many-to-many relationships exist in this schema.

---

## Key Design Decisions

1. **STATE code is sequential (1–51), not FIPS.** DimState maps sequential codes to FIPS codes and state metadata. This distinction is critical — never join directly to FIPS-based lookups using `STATE`.

2. **date_key=20140000** is a special annual summary row in DimDate. FactFinance uses this key because data is reported at annual (fiscal year) grain, not daily grain.

3. **Calculated fields are stored** in FactFinance (not computed at query time) for Power BI performance. NULL protection uses `NULLIF` to avoid divide-by-zero on zero-enrollment districts.

4. **Dollar unit:** All financial measures are in $1,000s in the warehouse (matching the Census Bureau source). Per-pupil fields convert to actual dollars to enable intuitive filtering in Power BI (e.g., "districts spending over $12,000 per student").

5. **DimDistrict denormalizes** state_name and state_abbrev from DimState for convenience in Power BI slicer panels. This is intentional in Kimball design.

6. **administration_spending = E08 + E09** (general administration + school administration from F-33 current expenditure columns). This represents district-level and school-level management overhead, which is the standard NCES benchmark for administrative spending.

---

## Validation Checklist

| Check | Expected | Script |
|---|---|---|
| DimState row count | 51 | 05_Validate_RowCounts.sql |
| DimDistrict row count | ~14,400 | 05_Validate_RowCounts.sql |
| DimDate row count | 367 | 05_Validate_RowCounts.sql |
| FactFinance row count | = DimDistrict count | 05_Validate_RowCounts.sql |
| Duplicate district check | 0 duplicates | 06_Validate_DuplicateDistrict.sql |
| Null foreign keys | 0 nulls | 07_Validate_NullKeys.sql |
| Revenue reconciliation | 0 mismatches | 08_Validate_RevenueReconciliation.sql |
| Instruction ≤ total expenditure | 0 violations | 09_Validate_Expenditure.sql |
| Per-pupil range ($1K–$100K) | <50 outliers | 09_Validate_Expenditure.sql |

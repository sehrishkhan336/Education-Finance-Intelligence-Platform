# Source-to-Target Mapping — Education Finance Intelligence Platform

## Document Information
- **Source system:** U.S. Census Bureau F-33 Survey file `elsec14.csv`
- **Target:** Microsoft Fabric Warehouse (bronze → silver → gold)
- **Last Updated:** 2026-06-10

---

## Medallion Architecture Flow

```
ADLS Gen2 (Raw)              Bronze                     Silver                    Gold
────────────────    ──────────────────────    ─────────────────────    ─────────────────────
elsec14.csv    ──► bronze.ELSEC14 (table) ──► silver.silver_district ──► gold.DimState
                                               _finance (view)          gold.DimDistrict
                                                                         gold.DimDate
                                                                         gold.FactFinance
```

---

## Source → Bronze: bronze.ELSEC14

| Source File | Source Column | Target Column | Transform | Notes |
|---|---|---|---|---|
| elsec14.csv | index | source_row_id | Direct | Row index from source |
| elsec14.csv | STATE | STATE | CAST INT | Sequential 1–51, NOT FIPS |
| elsec14.csv | IDCENSUS | IDCENSUS | CAST VARCHAR(15) | 13-digit Census ID |
| elsec14.csv | NAME | NAME | CAST VARCHAR(150) | District name |
| elsec14.csv | CONUM | CONUM | CAST VARCHAR(6) | County FIPS (may have .0 suffix) |
| elsec14.csv | SCHLEV | SCHLEV | CAST INT | School level code |
| elsec14.csv | NCESID | NCESID | CAST VARCHAR(12) | NCES LEA identifier |
| elsec14.csv | YRDATA | YRDATA | CAST INT | 14 = FY2014 |
| elsec14.csv | V33 | V33 | CAST DECIMAL(18,2) | Enrollment |
| elsec14.csv | TOTALREV | TOTALREV | CAST DECIMAL(18,2) | Total revenue $1K |
| elsec14.csv | TFEDREV | TFEDREV | CAST DECIMAL(18,2) | Federal revenue $1K |
| elsec14.csv | TSTREV | TSTREV | CAST DECIMAL(18,2) | State revenue $1K |
| elsec14.csv | TLOCREV | TLOCREV | CAST DECIMAL(18,2) | Local revenue $1K |
| elsec14.csv | TOTALEXP | TOTALEXP | CAST DECIMAL(18,2) | Total expenditure $1K |
| elsec14.csv | TCURINST | TCURINST | CAST DECIMAL(18,2) | Instruction spending $1K |
| elsec14.csv | E08 | E08 | CAST DECIMAL(18,2) | General admin $1K |
| elsec14.csv | E09 | E09 | CAST DECIMAL(18,2) | School admin $1K |
| elsec14.csv | TCAPOUT | TCAPOUT | CAST DECIMAL(18,2) | Capital outlay $1K |
| elsec14.csv | TCURSSVC | TCURSSVC | CAST DECIMAL(18,2) | Support services $1K |
| elsec14.csv | Z32 | Z32 | CAST DECIMAL(18,2) | Long-term debt $1K |
| — | load_timestamp | load_timestamp | GETUTCDATE() | Audit column |
| — | source_file | source_file | 'elsec14.csv' | Audit column |

---

## Bronze → Silver: silver.silver_district_finance (View)

| Source Column | Target Column | Transform | Notes |
|---|---|---|---|
| STATE | state_code | CAST(STATE AS INT) | Sequential code |
| IDCENSUS | census_district_id | CAST VARCHAR(15) | |
| NCESID | nces_district_id | CAST VARCHAR(12) | Business key |
| NAME | district_name | CAST VARCHAR(150) | |
| CONUM | county_fips | CAST VARCHAR(6) | |
| SCHLEV | school_level | CAST INT | |
| YRDATA | yrdata_code | CAST INT | |
| — | fiscal_year | Literal 2014 | Derived from YRDATA=14 |
| V33 | enrollment | CAST DECIMAL(18,2) | |
| TOTALREV | total_revenue | CAST DECIMAL(18,2) | |
| TFEDREV | federal_revenue | CAST DECIMAL(18,2) | |
| TSTREV | state_revenue | CAST DECIMAL(18,2) | |
| TLOCREV | local_revenue | CAST DECIMAL(18,2) | |
| TOTALEXP | total_expenditure | CAST DECIMAL(18,2) | |
| TCURINST | instruction_spending | CAST DECIMAL(18,2) | |
| E08 + E09 | administration_spending | COALESCE(E08,0)+COALESCE(E09,0) | Combined admin |
| TCAPOUT | capital_spending | CAST DECIMAL(18,2) | |
| Z32 | debt_outstanding | CAST DECIMAL(18,2) | |
| TCURSSVC | total_support_services | CAST DECIMAL(18,2) | |
| E17 | student_support_spending | CAST DECIMAL(18,2) | |
| E07 | instructional_staff_support_spending | CAST DECIMAL(18,2) | |
| V90 | operations_maintenance_spending | CAST DECIMAL(18,2) | |
| V85 | transportation_spending | CAST DECIMAL(18,2) | |
| V13 | teacher_fte | CAST DECIMAL(18,2) | |
| V11 | total_staff_fte | CAST DECIMAL(18,2) | |
| W01 | total_salaries | CAST DECIMAL(18,2) | |
| W31 | instruction_salaries | CAST DECIMAL(18,2) | |
| W61 | employee_benefits | CAST DECIMAL(18,2) | |

---

## Silver → Gold: DimState

| Source | Target Column | Transform | Notes |
|---|---|---|---|
| Static reference | state_key | Hard-coded 1–51 | Census sequential ordering |
| Static reference | state_code | Same as state_key | |
| Static reference | state_name | Hard-coded | Alphabetical state names |
| Static reference | state_abbrev | Hard-coded | USPS two-letter code |
| Static reference | fips_code | Hard-coded | Federal FIPS (differs from state_code) |
| Static reference | census_region | Hard-coded | Census 4-region classification |
| Static reference | census_division | Hard-coded | Census 9-division classification |

**Key mapping reference (STATE sequential → FIPS):**
| STATE | State | FIPS |
|---|---|---|
| 1 | Alabama | 01 |
| 2 | Alaska | 02 |
| 3 | Arizona | 04 |
| 4 | Arkansas | 05 |
| 5 | California | 06 |
| … | … | … |
| 9 | District of Columbia | 11 |
| … | … | … |
| 51 | Wyoming | 56 |

---

## Silver → Gold: DimDistrict

| Source Column | Target Column | Transform | Notes |
|---|---|---|---|
| ROW_NUMBER() | district_key | Ordered by state_code, nces_district_id | Surrogate key |
| nces_district_id | nces_district_id | Direct | Business key — must be unique |
| census_district_id | census_district_id | Direct | |
| district_name | district_name | Direct | |
| state_code | state_code | Direct | FK → DimState |
| DimState.state_name | state_name | Lookup join | Denormalized |
| DimState.state_abbrev | state_abbrev | Lookup join | Denormalized |
| county_fips | county_fips | REPLACE '.0' suffix; NULL if 'N' | Clean FIPS code |
| school_level | school_level | Direct | |
| school_level | school_level_desc | CASE translation | Elementary/Secondary/Unified/etc. |
| — | is_current | Default 1 | SCD placeholder |
| — | effective_date | Default '2014-07-01' | Start of FY2014 |
| — | expiry_date | NULL | Active record |

**Deduplication rule:** When nces_district_id appears more than once, keep the row with the lowest census_district_id (earliest Census assignment).

---

## Silver → Gold: DimDate

| Source | Target | Transform | Notes |
|---|---|---|---|
| Date spine (CTE) | date_key | FORMAT(dt, 'yyyyMMdd') → INT | YYYYMMDD integer |
| Date spine | full_date | Direct | |
| Date spine | fiscal_year | YEAR+1 if MONTH>=7 else YEAR | July–June definition |
| Date spine | fiscal_quarter | CASE WHEN MONTH IN (7,8,9)→1… | |
| Date spine | fiscal_month | MONTH-6 or MONTH+6 | July=1, June=12 |
| Literal | fiscal_year_label | 'FY2014' | |
| Special row | date_key=20140000 | Manual INSERT | Annual summary row for FactFinance |

**Date spine range:** 2013-07-01 to 2014-06-30 (FY2014)

---

## Silver → Gold: FactFinance

| Source | Target Column | Transform | Notes |
|---|---|---|---|
| ROW_NUMBER() | fact_key | Ordered by district_key | Surrogate |
| DimDistrict | district_key | Lookup on nces_district_id | FK |
| DimDistrict.state_code | state_key | Via DimDistrict join | FK |
| Literal 20140000 | date_key | Fixed annual key | FK → DimDate |
| Literal 2014 | fiscal_year | Derived | |
| nces_district_id | nces_district_id | Direct | Degenerate dim |
| census_district_id | census_district_id | Direct | Degenerate dim |
| enrollment | enrollment | Direct | |
| total_revenue | total_revenue | Direct | $1K |
| federal_revenue | federal_revenue | Direct | $1K |
| state_revenue | state_revenue | Direct | $1K |
| local_revenue | local_revenue | Direct | $1K |
| total_expenditure | total_expenditure | Direct | $1K |
| instruction_spending | instruction_spending | Direct | $1K |
| administration_spending | administration_spending | Direct | $1K (E08+E09) |
| capital_spending | capital_spending | Direct | $1K |
| total_support_services | support_services | Direct | $1K |
| debt_outstanding | debt_outstanding | Direct | $1K |
| — | per_pupil_spending | (total_expenditure × 1000) / enrollment | Actual $ |
| — | revenue_per_student | (total_revenue × 1000) / enrollment | Actual $ |
| — | federal_revenue_pct | federal_revenue / total_revenue × 100 | % |
| — | state_revenue_pct | state_revenue / total_revenue × 100 | % |
| — | local_revenue_pct | local_revenue / total_revenue × 100 | % |
| — | instruction_spending_pct | instruction_spending / total_expenditure × 100 | % |

**NULL guard:** All calculated fields use `NULLIF(denominator, 0)` — result is NULL (not error) when enrollment or total measure is zero.

**Deduplication:** Same rule as DimDistrict — one row per nces_district_id, lowest census_district_id wins.

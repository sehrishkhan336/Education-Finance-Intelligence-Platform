-- =============================================================================
-- GOLD LAYER: Schema and object setup
-- Target: Microsoft Fabric Warehouse
-- Architecture: Kimball Star Schema
-- Fact grain: One row per school district per fiscal year
-- =============================================================================

-- Create gold schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC ('CREATE SCHEMA gold');
GO

-- =============================================================================
-- BUILD ORDER (run in sequence):
--   1.  Dimensions/01_DimState.sql
--   2.  Dimensions/02_DimDistrict.sql
--   3.  Dimensions/03_DimDate.sql
--   4.  Facts/04_FactFinance.sql
-- =============================================================================

-- Dependency check: silver view must exist before Gold build
IF OBJECT_ID('silver.silver_district_finance', 'V') IS NULL
BEGIN
    RAISERROR(
        'silver.silver_district_finance view not found. Run silver layer scripts first.',
        16, 1);
END
GO

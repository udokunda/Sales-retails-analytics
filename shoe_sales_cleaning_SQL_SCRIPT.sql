-- =============================================================
-- SHOE SALES DATASET — SQL CLEANING & ANALYSIS TRANSCRIPT
-- Dataset: shoes_sales_dataset.csv
-- Rows: 1,000 | Columns: 10
-- Author: Maleka Shellton
-- =============================================================


CREATE TABLE IF NOT EXISTS shoe_sales_raw (
    Sale_ID       VARCHAR(10),
    Date          VARCHAR(20),     
    Brand         VARCHAR(50),
    Shoe_Type     VARCHAR(50),
    Color         VARCHAR(30),
    Country       VARCHAR(50),
    Sales_Channel VARCHAR(50),
    Price_USD     DECIMAL(10, 2),
    Units_Sold    INT,
    Revenue_USD   DECIMAL(10, 2)
);

-- 2a. Row count
SELECT COUNT(*) AS total_rows FROM shoe_sales_raw;
-- Expected: 1000

-- 2b. Check for NULL values in every column
SELECT
    SUM(CASE WHEN Sale_ID       IS NULL THEN 1 ELSE 0 END) AS null_sale_id,
    SUM(CASE WHEN Date          IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN Brand         IS NULL THEN 1 ELSE 0 END) AS null_brand,
    SUM(CASE WHEN Shoe_Type     IS NULL THEN 1 ELSE 0 END) AS null_shoe_type,
    SUM(CASE WHEN Color         IS NULL THEN 1 ELSE 0 END) AS null_color,
    SUM(CASE WHEN Country       IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN Sales_Channel IS NULL THEN 1 ELSE 0 END) AS null_sales_channel,
    SUM(CASE WHEN Price_USD     IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Units_Sold    IS NULL THEN 1 ELSE 0 END) AS null_units,
    SUM(CASE WHEN Revenue_USD   IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM shoe_sales_raw;
-- Result: 0 NULLs across all columns 

-- 2c. Check for duplicate Sale_IDs
SELECT Sale_ID, COUNT(*) AS occurrences
FROM shoe_sales_raw
GROUP BY Sale_ID
HAVING COUNT(*) > 1;
-- Result: 0 duplicates 

-- 2d. Inspect distinct categorical values
SELECT DISTINCT Brand         FROM shoe_sales_raw ORDER BY Brand;
SELECT DISTINCT Shoe_Type     FROM shoe_sales_raw ORDER BY Shoe_Type;
SELECT DISTINCT Color         FROM shoe_sales_raw ORDER BY Color;
SELECT DISTINCT Country       FROM shoe_sales_raw ORDER BY Country;
SELECT DISTINCT Sales_Channel FROM shoe_sales_raw ORDER BY Sales_Channel;
-- All clean — no typos or rogue values found 

-- 2e. Validate date range
SELECT
    MIN(Date) AS earliest_date,
    MAX(Date) AS latest_date
FROM shoe_sales_raw;
-- Result: 2025-01-03 to 2025-12-31   (full calendar year)

-- 2f. Validate revenue integrity: Revenue should equal Price × Units
SELECT
    Sale_ID,
    Price_USD,
    Units_Sold,
    Revenue_USD,
    ROUND(Price_USD * Units_Sold, 2) AS calculated_revenue,
    ROUND(Revenue_USD - (Price_USD * Units_Sold), 2) AS discrepancy
FROM shoe_sales_raw
WHERE ROUND(Revenue_USD, 2) <> ROUND(Price_USD * Units_Sold, 2);
-- Result: 0 mismatches — revenue is arithmetically consistent 

-- 2g. Numeric range sanity check
SELECT
    MIN(Price_USD)    AS min_price,
    MAX(Price_USD)    AS max_price,
    AVG(Price_USD)    AS avg_price,
    MIN(Units_Sold)   AS min_units,
    MAX(Units_Sold)   AS max_units,
    AVG(Units_Sold)   AS avg_units,
    MIN(Revenue_USD)  AS min_revenue,
    MAX(Revenue_USD)  AS max_revenue
FROM shoe_sales_raw;
-- Price: $31.02 – $249.94 | Units: 1 – 20 | Revenue: $32.38 – $4,938.40
-- Low-end prices are legitimate budget/sale items, not data errors ✓


-- =============================================================
-- STEP 3: CREATE CLEANED TABLE
-- =============================================================
-- Cleaning actions applied:
--   TRIM whitespace from all string fields
--   Cast Date from VARCHAR → DATE type
--   Derive Month, Quarter, Year for time-series analysis
--   Standardise Sales_Channel label (e.g. "Retail Store" kept as-is)
--   Round Price_USD and Revenue_USD to 2 decimal places
--   All other columns confirmed clean — no changes needed

CREATE TABLE shoe_sales_clean AS
SELECT
    TRIM(Sale_ID)                           AS Sale_ID,
    CAST(Date AS DATE)                      AS Sale_Date,
    EXTRACT(YEAR  FROM CAST(Date AS DATE))  AS Sale_Year,
    EXTRACT(MONTH FROM CAST(Date AS DATE))  AS Sale_Month,
    CASE EXTRACT(MONTH FROM CAST(Date AS DATE))
        WHEN 1  THEN 'Jan' WHEN 2  THEN 'Feb' WHEN 3  THEN 'Mar'
        WHEN 4  THEN 'Apr' WHEN 5  THEN 'May' WHEN 6  THEN 'Jun'
        WHEN 7  THEN 'Jul' WHEN 8  THEN 'Aug' WHEN 9  THEN 'Sep'
        WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dec'
    END                                     AS Month_Name,
    CASE
        WHEN EXTRACT(MONTH FROM CAST(Date AS DATE)) BETWEEN 1 AND 3  THEN 'Q1'
        WHEN EXTRACT(MONTH FROM CAST(Date AS DATE)) BETWEEN 4 AND 6  THEN 'Q2'
        WHEN EXTRACT(MONTH FROM CAST(Date AS DATE)) BETWEEN 7 AND 9  THEN 'Q3'
        ELSE 'Q4'
    END                                     AS Quarter,
    TRIM(Brand)                             AS Brand,
    TRIM(Shoe_Type)                         AS Shoe_Type,
    TRIM(Color)                             AS Color,
    TRIM(Country)                           AS Country,
    TRIM(Sales_Channel)                     AS Sales_Channel,
    ROUND(Price_USD, 2)                     AS Price_USD,
    Units_Sold,
    ROUND(Revenue_USD, 2)                   AS Revenue_USD
FROM shoe_sales_raw;

-- Verify cleaned table
SELECT COUNT(*) AS cleaned_rows FROM shoe_sales_clean;
-- Expected: 1000 


-- =============================================================
-- STEP 4: BUSINESS ANALYSIS QUERIES
-- =============================================================

-- 4a. Total revenue, units, and transactions overall
SELECT
    COUNT(*)                    AS total_transactions,
    SUM(Units_Sold)             AS total_units_sold,
    ROUND(SUM(Revenue_USD), 2)  AS total_revenue_usd,
    ROUND(AVG(Revenue_USD), 2)  AS avg_revenue_per_transaction,
    ROUND(AVG(Price_USD),   2)  AS avg_price_usd
FROM shoe_sales_clean;

-- 4b. Revenue by Brand (ranked)
SELECT
    Brand,
    COUNT(*)                    AS transactions,
    SUM(Units_Sold)             AS total_units,
    ROUND(SUM(Revenue_USD), 2)  AS total_revenue,
    ROUND(AVG(Price_USD),   2)  AS avg_price,
    ROUND(AVG(Units_Sold),  1)  AS avg_units_per_sale
FROM shoe_sales_clean
GROUP BY Brand
ORDER BY total_revenue DESC;

-- 4c. Revenue by Country (ranked)
SELECT
    Country,
    COUNT(*)                    AS transactions,
    SUM(Units_Sold)             AS total_units,
    ROUND(SUM(Revenue_USD), 2)  AS total_revenue,
    ROUND(AVG(Price_USD),   2)  AS avg_price
FROM shoe_sales_clean
GROUP BY Country
ORDER BY total_revenue DESC;

-- 4d. Revenue by Sales Channel
SELECT
    Sales_Channel,
    COUNT(*)                                            AS transactions,
    ROUND(SUM(Revenue_USD), 2)                          AS total_revenue,
    ROUND(100.0 * SUM(Revenue_USD) /
          SUM(SUM(Revenue_USD)) OVER (), 2)             AS pct_of_total
FROM shoe_sales_clean
GROUP BY Sales_Channel
ORDER BY total_revenue DESC;

-- 4e. Revenue by Shoe Type
SELECT
    Shoe_Type,
    COUNT(*)                    AS transactions,
    SUM(Units_Sold)             AS total_units,
    ROUND(SUM(Revenue_USD), 2)  AS total_revenue,
    ROUND(AVG(Price_USD),   2)  AS avg_price
FROM shoe_sales_clean
GROUP BY Shoe_Type
ORDER BY total_revenue DESC;

-- 4f. Monthly revenue trend
SELECT
    Sale_Month,
    Month_Name,
    Quarter,
    COUNT(*)                    AS transactions,
    SUM(Units_Sold)             AS total_units,
    ROUND(SUM(Revenue_USD), 2)  AS monthly_revenue
FROM shoe_sales_clean
GROUP BY Sale_Month, Month_Name, Quarter
ORDER BY Sale_Month;

-- 4g. Quarterly performance
SELECT
    Quarter,
    COUNT(*)                    AS transactions,
    SUM(Units_Sold)             AS total_units,
    ROUND(SUM(Revenue_USD), 2)  AS quarterly_revenue
FROM shoe_sales_clean
GROUP BY Quarter
ORDER BY Quarter;

-- 4h. Brand × Country revenue heatmap
SELECT
    Brand,
    Country,
    ROUND(SUM(Revenue_USD), 2) AS revenue
FROM shoe_sales_clean
GROUP BY Brand, Country
ORDER BY Brand, revenue DESC;

-- 4i. Brand × Sales Channel cross-tab
SELECT
    Brand,
    Sales_Channel,
    COUNT(*)                    AS transactions,
    ROUND(SUM(Revenue_USD), 2)  AS revenue
FROM shoe_sales_clean
GROUP BY Brand, Sales_Channel
ORDER BY Brand, revenue DESC;

-- 4j. Top 10 highest-revenue transactions
SELECT
    Sale_ID, Sale_Date, Brand, Shoe_Type,
    Country, Sales_Channel,
    Price_USD, Units_Sold, Revenue_USD
FROM shoe_sales_clean
ORDER BY Revenue_USD DESC
LIMIT 10;

-- 4k. Average price by Brand and Shoe Type
SELECT
    Brand,
    Shoe_Type,
    ROUND(AVG(Price_USD),  2) AS avg_price,
    ROUND(AVG(Units_Sold), 1) AS avg_units
FROM shoe_sales_clean
GROUP BY Brand, Shoe_Type
ORDER BY Brand, avg_price DESC;

-- 4l. Color popularity by units sold
SELECT
    Color,
    SUM(Units_Sold)             AS total_units,
    ROUND(SUM(Revenue_USD), 2)  AS total_revenue
FROM shoe_sales_clean
GROUP BY Color
ORDER BY total_units DESC;


-- =============================================================
-- STEP 5: FINAL QUALITY CHECK ON CLEANED TABLE
-- =============================================================

-- Confirm no nulls crept in after transformation
SELECT
    SUM(CASE WHEN Sale_ID       IS NULL THEN 1 ELSE 0 END) AS null_sale_id,
    SUM(CASE WHEN Sale_Date     IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN Brand         IS NULL THEN 1 ELSE 0 END) AS null_brand,
    SUM(CASE WHEN Revenue_USD   IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM shoe_sales_clean;
-- Expected: all 0 

-- Confirm row count unchanged
SELECT COUNT(*) FROM shoe_sales_clean;
-- Expected: 1000 


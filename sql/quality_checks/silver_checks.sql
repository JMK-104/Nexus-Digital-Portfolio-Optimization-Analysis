-- ============================================================================
-- Data Quality Validation Script for Silver Sales Table
-- ============================================================================


-- ============================================================================
-- SECTION 1: RECORD COUNT AND BASIC STATISTICS
-- ============================================================================

-- 1.1 Total record count
SELECT 
    'Total Records' AS metric,
    COUNT(*) AS value,
    'Expected ~100,000 after deduplication' AS note
FROM silver.sales
;

-- 1.2 Date range validation
SELECT 
    'Data Date Range' AS metric,
    MIN(order_date) AS earliest_date,
    MAX(order_date) AS latest_date,
    MAX(order_date) - MIN(order_date) AS days_span,
    ROUND((MAX(order_date) - MIN(order_date)) / 365.25, 1) AS years_span
FROM silver.sales
;
-- Expected: 6 year data range

-- 1.3 Record distribution by year
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    COUNT(*) AS record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM silver.sales
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year
;

-- ============================================================================
-- SECTION 2: PRIMARY KEY AND UNIQUENESS CHECKS
-- ============================================================================

-- 2.1 Check for duplicate order_ids (should return 0)
SELECT 
    'Duplicate Order IDs' AS check_name,
    COUNT(*) AS duplicate_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM (
    SELECT order_id, COUNT(*) AS cnt
    FROM silver.sales
    GROUP BY order_id
    HAVING COUNT(*) > 1
) duplicates
;

-- 2.2 Check for NULL primary keys (should return 0)
SELECT 
    'NULL Order IDs' AS check_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    CASE WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM silver.sales
;

-- 2.3 List any duplicate order_ids if they exist
SELECT 
    order_id,
    COUNT(*) AS occurrence_count,
    STRING_AGG(DISTINCT order_date::TEXT, ', ') AS order_dates
FROM silver.sales
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
;

-- ============================================================================
-- SECTION 3: NULL VALUE ANALYSIS
-- ============================================================================

-- 3.1 Comprehensive NULL count for all columns
SELECT 
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE ship_date IS NULL) AS null_ship_date,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_signup_date IS NULL) AS null_customer_signup_date,
    COUNT(*) FILTER (WHERE customer_age_group IS NULL) AS null_age_group,
    COUNT(*) FILTER (WHERE customer_gender IS NULL) AS null_gender,
    COUNT(*) FILTER (WHERE customer_country IS NULL) AS null_country,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_state,
    COUNT(*) FILTER (WHERE loyalty_tier IS NULL) AS null_loyalty_tier,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS null_product_name,
    COUNT(*) FILTER (WHERE product_category IS NULL) AS null_product_category,
    COUNT(*) FILTER (WHERE marketing_channel IS NULL) AS null_marketing_channel,
    COUNT(*) FILTER (WHERE customer_satisfaction IS NULL) AS null_satisfaction,
    COUNT(*) FILTER (WHERE delivery_days IS NULL) AS null_delivery_days
FROM silver.sales
;

-- 3.2 NULL percentage report (formatted)
SELECT 
    'order_id' AS column_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    ROUND(COUNT(*) FILTER (WHERE order_id IS NULL) * 100.0 / COUNT(*), 2) AS null_percentage,
    CASE WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN '✓' ELSE '✗' END AS status
FROM silver.sales
UNION ALL
SELECT 'order_date', COUNT(*) FILTER (WHERE order_date IS NULL), ROUND(COUNT(*) FILTER (WHERE order_date IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE order_date IS NULL) = 0 THEN '✓' ELSE '✗' END FROM silver.sales
UNION ALL
SELECT 'customer_id', COUNT(*) FILTER (WHERE customer_id IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_id IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN '✓' ELSE '✗' END FROM silver.sales
UNION ALL
SELECT 'product_id', COUNT(*) FILTER (WHERE product_id IS NULL), ROUND(COUNT(*) FILTER (WHERE product_id IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN '✓' ELSE '✗' END FROM silver.sales
UNION ALL
SELECT 'customer_age_group', COUNT(*) FILTER (WHERE customer_age_group IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_age_group IS NULL) * 100.0 / COUNT(*), 2), '○' FROM silver.sales
UNION ALL
SELECT 'customer_gender', COUNT(*) FILTER (WHERE customer_gender IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_gender IS NULL) * 100.0 / COUNT(*), 2), '○' FROM silver.sales
UNION ALL
SELECT 'loyalty_tier', COUNT(*) FILTER (WHERE loyalty_tier IS NULL), ROUND(COUNT(*) FILTER (WHERE loyalty_tier IS NULL) * 100.0 / COUNT(*), 2), '○' FROM silver.sales
UNION ALL
SELECT 'marketing_channel', COUNT(*) FILTER (WHERE marketing_channel IS NULL), ROUND(COUNT(*) FILTER (WHERE marketing_channel IS NULL) * 100.0 / COUNT(*), 2), '○' FROM silver.sales
ORDER BY null_percentage DESC
;

-- ============================================================================
-- SECTION 4: DATA STANDARDIZATION CHECKS
-- ============================================================================

-- 4.1 Verify order_status standardization (should only show proper case)
SELECT 
    order_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN order_status IN ('Completed', 'Shipped', 'Processing', 'Cancelled', 'Returned', 'Pending') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM silver.sales
WHERE order_status IS NOT NULL
GROUP BY order_status
ORDER BY count DESC
;

-- 4.2 Verify customer_gender standardization
SELECT 
    customer_gender,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN customer_gender IN ('Male', 'Female', 'Other', 'Prefer Not To Say', 'Unknown') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM silver.sales
WHERE customer_gender IS NOT NULL
GROUP BY customer_gender
ORDER BY count DESC
;

-- 4.3 Verify customer_age_group values
SELECT 
    customer_age_group,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN customer_age_group IN ('18-24', '25-34', '35-44', '45-54', '55-64', '65+', 'Unknown') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM silver.sales
WHERE customer_age_group IS NOT NULL
GROUP BY customer_age_group
ORDER BY count DESC
;

-- 4.4 Verify loyalty_tier values
SELECT 
    loyalty_tier,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN loyalty_tier IN ('Bronze', 'Silver', 'Gold', 'Platinum', 'None') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM silver.sales
WHERE loyalty_tier IS NOT NULL
GROUP BY loyalty_tier
ORDER BY count DESC
;

-- ============================================================================
-- SECTION 5: DATE LOGIC VALIDATION
-- ============================================================================

-- 5.1 Check for illogical dates (ship_date before order_date) - should return 0
SELECT 
    'Ship Date Before Order Date' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM silver.sales
WHERE ship_date < order_date
;


-- 5.2 Check for future dates (dates beyond today) - should return 0
SELECT 
    'Future Order Dates' AS check_name,
    COUNT(*) FILTER (WHERE order_date > CURRENT_DATE) AS future_order_dates,
    COUNT(*) FILTER (WHERE ship_date > CURRENT_DATE) AS future_ship_dates,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_date > CURRENT_DATE OR ship_date > CURRENT_DATE) = 0 
        THEN '✓ PASS' 
        ELSE '✗ FAIL' 
    END AS status
FROM silver.sales
;

-- 5.3 Check for signup dates after order dates
SELECT 
    'Signup After Order' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM silver.sales
WHERE customer_signup_date > order_date
;

-- 5.4 Delivery days validation (should match ship_date - order_date)
SELECT 
    'Delivery Days Mismatch' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM silver.sales
WHERE ship_date IS NOT NULL 
  AND delivery_days IS NOT NULL
  AND delivery_days != (ship_date - order_date)
;

-- 5.5 Check for negative delivery days (should return 0)
SELECT 
    'Negative Delivery Days' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM silver.sales
WHERE delivery_days < 0
;

-- ============================================================================
-- SECTION 6: NUMERIC VALUE VALIDATION
-- ============================================================================

-- 6.1 Check for negative or zero values where they shouldn't exist
SELECT 
    COUNT(*) FILTER (WHERE quantity <= 0) AS invalid_quantity,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS invalid_unit_price,
    COUNT(*) FILTER (WHERE total_amount <= 0) AS invalid_total_amount,
    COUNT(*) FILTER (WHERE discount_percentage < 0 OR discount_percentage > 1) AS invalid_discount,
    COUNT(*) FILTER (WHERE customer_satisfaction < 0 OR customer_satisfaction > 5) AS invalid_satisfaction,
    CASE 
        WHEN COUNT(*) FILTER (WHERE quantity <= 0 OR unit_price <= 0 OR total_amount <= 0) = 0
        THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM silver.sales
;

-- 6.2 Validate financial calculations (subtotal = unit_price * quantity)
SELECT 
    'Subtotal Calculation' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) <= 10 THEN '✓ PASS (minor rounding)' ELSE '⚠ WARNING' END AS status
FROM silver.sales
WHERE ABS(subtotal - (unit_price * quantity)) > 0.02
; -- Allow 2 cent rounding difference

-- 6.3 Validate total_amount calculation (subtotal + tax + shipping)
SELECT 
    'Total Amount Calculation' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) <= 10 THEN '✓ PASS (minor rounding)' ELSE '⚠ WARNING' END AS status
FROM silver.sales
WHERE ABS(total_amount - (subtotal + COALESCE(tax_amount, 0) + COALESCE(shipping_cost, 0))) > 0.02
;

-- 6.4 Validate profit calculation (total_amount - total_cost)
SELECT 
    'Profit Calculation' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) <= 10 THEN '✓ PASS (minor rounding)' ELSE '⚠ WARNING' END AS status
FROM silver.sales
WHERE total_cost IS NOT NULL 
  AND profit IS NOT NULL
  AND ABS(profit - (total_amount - total_cost)) > 0.02
;

-- 6.5 Validate profit margin calculation
SELECT 
    'Profit Margin Calculation' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) <= 100 THEN '✓ PASS (minor rounding)' ELSE '⚠ WARNING' END AS status
FROM silver.sales
WHERE total_amount > 0 
  AND profit IS NOT NULL
  AND profit_margin_percent IS NOT NULL
  AND ABS(profit_margin_percent - ((profit / total_amount) * 100)) > 0.5
;

-- ============================================================================
-- SECTION 7: REFERENTIAL INTEGRITY CHECKS
-- ============================================================================

-- 7.1 Count distinct customers
SELECT 
    'Distinct Customers' AS metric,
    COUNT(DISTINCT customer_id) AS value,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT customer_id), 2) AS avg_orders_per_customer
FROM silver.sales
;

-- 7.2 Count distinct products
SELECT 
    'Distinct Products' AS metric,
    COUNT(DISTINCT product_id) AS value,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT product_id), 2) AS avg_orders_per_product
FROM silver.sales
;

-- 7.3 Validate product_id and product_name consistency
SELECT 
    'Product ID/Name Consistency' AS check_name,
    COUNT(*) AS inconsistent_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM (
    SELECT product_id, COUNT(DISTINCT product_name) AS name_count
    FROM silver.sales
    GROUP BY product_id
    HAVING COUNT(DISTINCT product_name) > 1
) inconsistencies
;

-- 7.4 Validate product_id and product_category consistency
SELECT 
    'Product ID/Category Consistency' AS check_name,
    COUNT(*) AS inconsistent_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM (
    SELECT product_id, COUNT(DISTINCT product_category) AS category_count
    FROM silver.sales
    GROUP BY product_id
    HAVING COUNT(DISTINCT product_category) > 1
) inconsistencies
;

-- ============================================================================
-- SECTION 8: BUSINESS LOGIC VALIDATION
-- ============================================================================

-- 8.1 Validate refund logic (is_refunded should match refund_amount)
SELECT 
    'Refund Logic Consistency' AS check_name,
    COUNT(*) FILTER (WHERE is_refunded = TRUE AND refund_amount = 0) AS refunded_but_zero_amount,
    COUNT(*) FILTER (WHERE is_refunded = FALSE AND refund_amount > 0) AS not_refunded_but_has_amount,
    CASE 
        WHEN COUNT(*) FILTER (WHERE 
            (is_refunded = TRUE AND refund_amount = 0) OR 
            (is_refunded = FALSE AND refund_amount > 0)
        ) = 0 
        THEN '✓ PASS' 
        ELSE '✗ FAIL' 
    END AS status
FROM silver.sales
;

-- 8.2 Validate refund amounts don't exceed total amounts
SELECT 
    'Refund Amount Validation' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM silver.sales
WHERE refund_amount > total_amount
;

-- 8.3 Check for completed orders without ship dates
SELECT 
    'Completed Orders Missing Ship Date' AS check_name,
    COUNT(*) AS count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM silver.sales
WHERE order_status = 'Completed' AND ship_date IS NULL
;

-- 8.4 Validate USA-specific state data
SELECT 
    'USA State Data Validation' AS check_name,
    COUNT(*) FILTER (WHERE customer_country = 'USA' AND customer_state = 'Outside USA') AS usa_without_state,
    COUNT(*) FILTER (WHERE customer_country != 'USA' AND customer_state != 'Outside USA') AS non_usa_with_state,
    CASE 
        WHEN COUNT(*) FILTER (WHERE 
            (customer_country = 'USA' AND customer_state = 'Outside USA') OR
            (customer_country != 'USA' AND customer_state != 'Outside USA' AND customer_state IS NOT NULL)
        ) = 0 
        THEN '✓ PASS' 
        ELSE '⚠ WARNING' 
    END AS status
FROM silver.sales
;

-- ============================================================================
-- SECTION 9: DATA DISTRIBUTION CHECKS
-- ============================================================================

-- 9.1 Order status distribution
SELECT 
    'Order Status Distribution' AS metric,
    order_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM silver.sales
GROUP BY order_status
ORDER BY count DESC
;

-- 9.2 Product category distribution
SELECT 
    'Product Category Distribution' AS metric,
    product_category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM silver.sales
GROUP BY product_category
ORDER BY count DESC
;

-- 9.3 Country distribution
SELECT 
    'Country Distribution' AS metric,
    customer_country,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM silver.sales
GROUP BY customer_country
ORDER BY count DESC
;

-- 9.4 Marketing channel distribution
SELECT 
    'Marketing Channel Distribution' AS metric,
    marketing_channel,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM silver.sales
GROUP BY marketing_channel
ORDER BY count DESC
;

-- ============================================================================
-- SECTION 10: OUTLIER DETECTION
-- ============================================================================


-- 10.1 Find orders with unusually high amounts (top 0.1%)
SELECT 
    order_id,
    order_date,
    product_name,
    quantity,
    total_amount,
    profit
FROM silver.sales
WHERE total_amount > (SELECT PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY total_amount) FROM silver.sales)
ORDER BY total_amount DESC
LIMIT 20
;

-- 10.2 Find orders with unusually high quantities
SELECT 
    order_id,
    order_date,
    product_name,
    quantity,
    total_amount
FROM silver.sales
WHERE quantity > (SELECT PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY quantity) FROM silver.sales)
ORDER BY quantity DESC
LIMIT 20
;

-- 10.3 Detect unusually long delivery times
SELECT 
    order_id,
    order_date,
    ship_date,
    delivery_days,
    order_status,
    customer_country
FROM silver.sales
WHERE delivery_days > 30
ORDER BY delivery_days DESC
LIMIT 20
;

-- ============================================================================
-- SECTION 11: VALIDATE NEW CUSTOMER KEY
-- ============================================================================

SELECT
    COUNT(*)                                        AS total_rows,
    COUNT(customer_key)                             AS rows_with_key,
    COUNT(*) FILTER (WHERE customer_key IS NULL)    AS rows_missing_key,
    CASE
        WHEN COUNT(*) FILTER (WHERE customer_key IS NULL) = 0
        THEN '✓ PASS - All rows assigned a customer_key'
        ELSE '✗ FAIL - Some rows could not be matched'
    END AS status
FROM silver.sales
;

-- If rows_missing_key > 0, run this to investigate unmatched rows
SELECT DISTINCT
    s.customer_id,
    s.customer_signup_date,
    s.customer_age_group,
    s.customer_gender,
    s.customer_country,
    s.customer_state,
    s.loyalty_tier
FROM silver.sales s
LEFT JOIN silver.customers c
       ON s.customer_id          = c.customer_id
      AND s.customer_signup_date = c.customer_signup_date
      AND s.customer_age_group   = c.customer_age_group
      AND s.customer_gender      = c.customer_gender
      AND s.customer_country     = c.customer_country
      AND s.customer_state       = c.customer_state
      AND s.loyalty_tier         = c.loyalty_tier
WHERE c.customer_key IS NULL
;


-- ============================================================================
-- SECTION 12: COMPREHENSIVE SUMMARY REPORT
-- ============================================================================

-- 12.1 Overall data quality scorecard
WITH quality_checks AS (
    SELECT 
        'No Duplicate Order IDs' AS check_name,
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END AS pass_flag
    FROM (SELECT order_id FROM silver.sales GROUP BY order_id HAVING COUNT(*) > 1) d
    
    UNION ALL
    
    SELECT 
        'No NULL Primary Keys',
        CASE WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN 1 ELSE 0 END
    FROM silver.sales
    
    UNION ALL
    
    SELECT 
        'No Illogical Ship Dates',
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
    FROM silver.sales WHERE ship_date < order_date
    
    UNION ALL
    
    SELECT 
        'No Negative Delivery Days',
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
    FROM silver.sales WHERE delivery_days < 0
    
    UNION ALL
    
    SELECT 
        'No Invalid Quantities',
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
    FROM silver.sales WHERE quantity <= 0
    
    UNION ALL
    
    SELECT 
        'Standardized Order Status',
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
    FROM silver.sales 
    WHERE order_status IS NOT NULL 
      AND order_status NOT IN ('Completed', 'Shipped', 'Processing', 'Cancelled', 'Returned', 'Pending')
    
    UNION ALL
    
    SELECT 
        'Standardized Gender Values',
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
    FROM silver.sales 
    WHERE customer_gender IS NOT NULL 
      AND customer_gender NOT IN ('Male', 'Female', 'Other', 'Prefer Not To Say', 'Unknown')
    
    UNION ALL
    
    SELECT 
        'Valid Refund Logic',
        CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
    FROM silver.sales 
    WHERE (is_refunded = TRUE AND refund_amount = 0) OR (is_refunded = FALSE AND refund_amount > 0)
)
SELECT 
    check_name,
    CASE WHEN pass_flag = 1 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM quality_checks
ORDER BY pass_flag, check_name
;

-- 12.2 Final summary statistics
SELECT 
    'FINAL SUMMARY' AS section,
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    MIN(order_date) AS date_from,
    MAX(order_date) AS date_to,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    COUNT(*) FILTER (WHERE is_refunded = TRUE) AS refunded_orders,
    ROUND(COUNT(*) FILTER (WHERE is_refunded = TRUE) * 100.0 / COUNT(*), 2) AS refund_rate_percent
FROM silver.sales
;

-- ============================================================================
-- End of Data Quality Validation Script
-- ============================================================================
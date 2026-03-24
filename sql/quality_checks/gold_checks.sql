-- ============================================================================
-- Gold Layer Data Quality Validation
-- ============================================================================

-- ============================================================================
-- PART A: gold.orders
-- ============================================================================


-- ============================================================================
-- SECTION 1: RECORD COUNT AND BASIC STATISTICS  [gold.orders]
-- ============================================================================

-- 1.1 Total record count and alignment with silver
SELECT 
    'gold.orders' AS view_name,
    (SELECT COUNT(*) FROM gold.orders) AS gold_order_count,
    (SELECT COUNT(*) FROM silver.sales) AS silver_record_count,
    (SELECT COUNT(*) FROM gold.orders) - (SELECT COUNT(*) FROM silver.sales) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM gold.orders) = (SELECT COUNT(*) FROM silver.sales) 
        THEN '✓ PASS' ELSE '✗ FAIL - Count mismatch with silver' 
    END AS status
    ;

-- 1.2 Date range validation
SELECT 
    'gold.orders Date Range' AS metric,
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    MAX(order_date) - MIN(order_date) AS days_span,
    ROUND((MAX(order_date) - MIN(order_date)) / 365.25, 1) AS years_span
FROM gold.orders
;

-- 1.3 Record distribution by year
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    COUNT(*) AS record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM gold.orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year
;

-- ============================================================================
-- SECTION 2: PRIMARY KEY AND UNIQUENESS CHECKS  [gold.orders]
-- ============================================================================

-- 2.1 Check for duplicate order_ids (should return 0 - view inherits PK from silver)
SELECT 
    'Duplicate Order IDs' AS check_name,
    COUNT(*) AS duplicate_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM (
    SELECT order_id, COUNT(*) AS cnt
    FROM gold.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) duplicates
;

-- 2.2 Check for NULL order_ids (should return 0)
SELECT
    'NULL Order IDs' AS check_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    CASE WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders
;

-- 2.3 Check for NULL foreign keys (customer_id, product_id)
SELECT
    'NULL Foreign Keys' AS check_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_id IS NULL OR product_id IS NULL) = 0 
        THEN '✓ PASS' ELSE '✗ FAIL' 
    END AS status
FROM gold.orders
;

-- ============================================================================
-- SECTION 3: NULL VALUE ANALYSIS  [gold.orders]
-- ============================================================================

-- 3.1 Comprehensive NULL count for all columns
SELECT 
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE ship_date IS NULL) AS null_ship_date,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS null_unit_price,
    COUNT(*) FILTER (WHERE total_amount IS NULL) AS null_total_amount,
    COUNT(*) FILTER (WHERE payment_method IS NULL) AS null_payment_method,
    COUNT(*) FILTER (WHERE marketing_channel IS NULL) AS null_marketing_channel,
    COUNT(*) FILTER (WHERE device_type IS NULL) AS null_device_type,
    COUNT(*) FILTER (WHERE customer_satisfaction IS NULL) AS null_satisfaction,
    COUNT(*) FILTER (WHERE delivery_days IS NULL) AS null_delivery_days,
    COUNT(*) FILTER (WHERE region IS NULL) AS null_region
FROM gold.orders
;

-- 3.2 NULL percentage report (formatted)
SELECT 'order_id' AS column_name, COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count, ROUND(COUNT(*) FILTER (WHERE order_id IS NULL) * 100.0 / COUNT(*), 2) AS null_pct, CASE WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN '✓' ELSE '✗' END AS status FROM gold.orders
UNION ALL
SELECT 'order_date', COUNT(*) FILTER (WHERE order_date IS NULL), ROUND(COUNT(*) FILTER (WHERE order_date IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE order_date IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.orders
UNION ALL
SELECT 'customer_id', COUNT(*) FILTER (WHERE customer_id IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_id IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.orders
UNION ALL
SELECT 'product_id', COUNT(*) FILTER (WHERE product_id IS NULL), ROUND(COUNT(*) FILTER (WHERE product_id IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.orders
UNION ALL
SELECT 'quantity', COUNT(*) FILTER (WHERE quantity IS NULL), ROUND(COUNT(*) FILTER (WHERE quantity IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE quantity IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.orders
UNION ALL
SELECT 'total_amount', COUNT(*) FILTER (WHERE total_amount IS NULL), ROUND(COUNT(*) FILTER (WHERE total_amount IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE total_amount IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.orders
UNION ALL
SELECT 'ship_date', COUNT(*) FILTER (WHERE ship_date IS NULL), ROUND(COUNT(*) FILTER (WHERE ship_date IS NULL) * 100.0 / COUNT(*), 2), '○' FROM gold.orders
UNION ALL
SELECT 'marketing_channel', COUNT(*) FILTER (WHERE marketing_channel IS NULL), ROUND(COUNT(*) FILTER (WHERE marketing_channel IS NULL) * 100.0 / COUNT(*), 2), '○' FROM gold.orders
UNION ALL
SELECT 'customer_satisfaction', COUNT(*) FILTER (WHERE customer_satisfaction IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_satisfaction IS NULL) * 100.0 / COUNT(*), 2), '○' FROM gold.orders
UNION ALL
SELECT 'delivery_days', COUNT(*) FILTER (WHERE delivery_days IS NULL), ROUND(COUNT(*) FILTER (WHERE delivery_days IS NULL) * 100.0 / COUNT(*), 2), '○' FROM gold.orders
ORDER BY null_pct DESC
;

-- ============================================================================
-- SECTION 4: DATA STANDARDIZATION CHECKS  [gold.orders]
-- ============================================================================

-- 4.1 Verify order_status values
SELECT 
    order_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN order_status IN ('Completed', 'Shipped', 'Processing', 'Cancelled', 'Returned', 'Pending') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM gold.orders
WHERE order_status IS NOT NULL
GROUP BY order_status
ORDER BY count DESC
;

-- 4.2 Verify marketing_channel values
SELECT 
    marketing_channel,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN marketing_channel IN ('Social Media', 'Email', 'Organic Search', 'Paid Search', 
                                   'Direct', 'Referral', 'Display Ads', 'Affiliate', 'Unknown') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM gold.orders
WHERE marketing_channel IS NOT NULL
GROUP BY marketing_channel
ORDER BY count DESC
;

-- 4.3 Verify device_type values
SELECT 
    device_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN device_type IN ('Desktop', 'Mobile', 'Tablet') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM gold.orders
WHERE device_type IS NOT NULL
GROUP BY device_type
ORDER BY count DESC
;

-- 4.4 Verify region values
SELECT 
    region,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN region IN ('North America', 'Europe', 'Asia-Pacific', 'Latin America', 'Other') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM gold.orders
WHERE region IS NOT NULL
GROUP BY region
ORDER BY count DESC
;

-- ============================================================================
-- SECTION 5: DATE LOGIC VALIDATION  [gold.orders]
-- ============================================================================

-- 5.1 Check for illogical dates (ship_date before order_date) - should return 0
SELECT 
    'Ship Date Before Order Date' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders
WHERE ship_date < order_date
;

-- 5.2 Check for future dates
SELECT 
    'Future Dates' AS check_name,
    COUNT(*) FILTER (WHERE order_date > CURRENT_DATE) AS future_order_dates,
    COUNT(*) FILTER (WHERE ship_date > CURRENT_DATE) AS future_ship_dates,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_date > CURRENT_DATE OR ship_date > CURRENT_DATE) = 0 
        THEN '✓ PASS' ELSE '✗ FAIL' 
    END AS status
FROM gold.orders
;

-- 5.3 Check for negative delivery days - should return 0
SELECT 
    'Negative Delivery Days' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders
WHERE delivery_days < 0
;

-- 5.4 Delivery days consistency with ship and order dates
SELECT 
    'Delivery Days Mismatch' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM gold.orders
WHERE ship_date IS NOT NULL
  AND delivery_days IS NOT NULL
  AND delivery_days != (ship_date - order_date)
;

-- ============================================================================
-- SECTION 6: NUMERIC VALUE VALIDATION  [gold.orders]
-- ============================================================================

-- 6.1 Check for invalid numeric values
SELECT 
    'Invalid Numeric Values' AS check_name,
    COUNT(*) FILTER (WHERE quantity <= 0) AS invalid_quantity,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS invalid_unit_price,
    COUNT(*) FILTER (WHERE total_amount <= 0) AS invalid_total_amount,
    COUNT(*) FILTER (WHERE refund_amount < 0) AS negative_refund,
    COUNT(*) FILTER (WHERE customer_satisfaction NOT BETWEEN 0 AND 5) AS invalid_satisfaction,
    CASE 
        WHEN COUNT(*) FILTER (WHERE quantity <= 0 OR unit_price <= 0 OR total_amount <= 0 OR refund_amount < 0) = 0
        THEN '✓ PASS' ELSE '✗ FAIL'
    END AS status
FROM gold.orders
;

-- ============================================================================
-- SECTION 7: BUSINESS LOGIC VALIDATION  [gold.orders]
-- ============================================================================

-- 7.1 Validate refund logic
SELECT 
    'Refund Logic Consistency' AS check_name,
    COUNT(*) FILTER (WHERE is_refunded = TRUE AND refund_amount = 0) AS refunded_no_amount,
    COUNT(*) FILTER (WHERE is_refunded = FALSE AND refund_amount > 0) AS not_refunded_has_amount,
    CASE 
        WHEN COUNT(*) FILTER (WHERE 
            (is_refunded = TRUE AND refund_amount = 0) OR 
            (is_refunded = FALSE AND refund_amount > 0)) = 0 
        THEN '✓ PASS' ELSE '✗ FAIL' 
    END AS status
FROM gold.orders
;

-- 7.2 Check refund amounts do not exceed order totals
SELECT 
    'Refund Amount Exceeds Total' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders
WHERE refund_amount > total_amount
;

-- 7.3 Check completed orders all have a ship date
SELECT 
    'Completed Orders Without Ship Date' AS check_name,
    COUNT(*) AS violation_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM gold.orders
WHERE order_status = 'Completed' AND ship_date IS NULL
;

-- 7.4 Validate satisfaction score is only present for completed orders
SELECT 
    order_status,
    COUNT(*) AS orders_with_rating,
    ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction
FROM gold.orders
WHERE customer_satisfaction IS NOT NULL AND customer_satisfaction > 0
GROUP BY order_status
ORDER BY orders_with_rating DESC
;

-- ============================================================================
-- SECTION 8: SILVER ALIGNMENT CHECKS  [gold.orders]
-- ============================================================================

-- 8.1 Verify all silver order_ids are present in gold.orders
SELECT 
    'Missing Orders from Silver' AS check_name,
    COUNT(*) AS missing_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM silver.sales s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.orders g WHERE g.order_id = s.order_id
)
;

-- 8.2 Verify gold.orders has no order_ids absent from silver
SELECT 
    'Orphaned Orders in Gold' AS check_name,
    COUNT(*) AS orphaned_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders g
WHERE NOT EXISTS (
    SELECT 1 FROM silver.sales s WHERE s.order_id = g.order_id
)
;

-- 8.3 Verify total revenue matches between gold and silver
SELECT 
    'Total Revenue Reconciliation' AS check_name,
    ROUND((SELECT SUM(total_amount) FROM gold.orders), 2) AS gold_total,
    ROUND((SELECT SUM(total_amount) FROM silver.sales), 2) AS silver_total,
    ROUND(ABS((SELECT SUM(total_amount) FROM gold.orders) - (SELECT SUM(total_amount) FROM silver.sales)), 2) AS difference,
    CASE 
        WHEN ABS((SELECT SUM(total_amount) FROM gold.orders) - (SELECT SUM(total_amount) FROM silver.sales)) < 0.01
        THEN '✓ PASS' ELSE '✗ FAIL' 
    END AS status
;

-- 8.4 Verify total refund amount matches between gold and silver
SELECT 
    'Total Refund Reconciliation' AS check_name,
    ROUND((SELECT SUM(refund_amount) FROM gold.orders), 2) AS gold_refunds,
    ROUND((SELECT SUM(refund_amount) FROM silver.sales), 2) AS silver_refunds,
    CASE 
        WHEN ABS((SELECT SUM(refund_amount) FROM gold.orders) - (SELECT SUM(refund_amount) FROM silver.sales)) < 0.01
        THEN '✓ PASS' ELSE '✗ FAIL' 
    END AS status
;

-- ============================================================================
-- SECTION 9: DISTRIBUTION CHECKS  [gold.orders]
-- ============================================================================

-- 9.1 Order status distribution
SELECT 
    'Order Status Distribution' AS metric,
    order_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM gold.orders
GROUP BY order_status
ORDER BY count DESC
;

-- 9.2 Refund rate by order status
SELECT 
    order_status,
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE is_refunded = TRUE) AS refunded,
    ROUND(COUNT(*) FILTER (WHERE is_refunded = TRUE) * 100.0 / COUNT(*), 2) AS refund_rate_pct
FROM gold.orders
GROUP BY order_status
ORDER BY refund_rate_pct DESC
;

-- 9.3 Payment method distribution
SELECT 
    payment_method,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM gold.orders
GROUP BY payment_method
ORDER BY count DESC
;

-- 9.4 Orders by region
SELECT 
    region,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM gold.orders
GROUP BY region
ORDER BY count DESC
;

-- ============================================================================
-- SECTION 10: OUTLIER DETECTION  [gold.orders]
-- ============================================================================

-- 10.1 Orders with unusually high total amounts (top 0.1%)
SELECT 
    order_id,
    order_date,
    product_id,
    quantity,
    unit_price,
    total_amount
FROM gold.orders
WHERE total_amount > (SELECT PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY total_amount) FROM gold.orders)
ORDER BY total_amount DESC
LIMIT 20
;

-- 10.2 Orders with unusually high quantities
SELECT 
    order_id,
    order_date,
    product_id,
    quantity,
    total_amount
FROM gold.orders
WHERE quantity > (SELECT PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY quantity) FROM gold.orders)
ORDER BY quantity DESC
LIMIT 20
;

-- 10.3 Unusually long delivery times
SELECT 
    order_id,
    order_date,
    ship_date,
    delivery_days,
    order_status,
    region
FROM gold.orders
WHERE delivery_days > 30
ORDER BY delivery_days DESC
LIMIT 20
;


-- ============================================================================
-- PART B: gold.products
-- ============================================================================

-- ============================================================================
-- SECTION 1: RECORD COUNT AND BASIC STATISTICS  [gold.products]
-- ============================================================================

-- 1.1 Total distinct products and alignment with silver
SELECT 
    'gold.products' AS view_name,
    (SELECT COUNT(*) FROM gold.products) AS gold_product_count,
    (SELECT COUNT(DISTINCT product_id) FROM silver.sales) AS silver_distinct_products,
    (SELECT COUNT(*) FROM gold.products) - (SELECT COUNT(DISTINCT product_id) FROM silver.sales) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM gold.products) = (SELECT COUNT(DISTINCT product_id) FROM silver.sales)
        THEN '✓ PASS' ELSE '✗ FAIL - Count mismatch with silver'
    END AS status
;

-- ============================================================================
-- SECTION 2: PRIMARY KEY AND UNIQUENESS CHECKS  [gold.products]
-- ============================================================================

-- 2.1 Check for duplicate product_ids (should return 0)
SELECT 
    'Duplicate Product IDs' AS check_name,
    COUNT(*) AS duplicate_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM (
    SELECT product_id, COUNT(*) AS cnt
    FROM gold.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) duplicates
;

-- 2.2 List any duplicate product_ids with conflicting details
SELECT 
    product_id,
    COUNT(DISTINCT product_name) AS distinct_names,
    COUNT(DISTINCT product_category) AS distinct_categories,
    STRING_AGG(DISTINCT product_name, ' | ') AS names_found,
    STRING_AGG(DISTINCT product_category, ' | ') AS categories_found
FROM gold.products
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY product_id
;

-- 2.3 Check for NULL product_ids (should return 0)
SELECT 
    'NULL Product IDs' AS check_name,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_count,
    CASE WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.products
;

-- ============================================================================
-- SECTION 3: NULL VALUE ANALYSIS  [gold.products]
-- ============================================================================

-- 3.1 NULL counts across all columns
SELECT 
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS null_product_name,
    COUNT(*) FILTER (WHERE product_category IS NULL) AS null_product_category
FROM gold.products
;

-- 3.2 NULL percentage report
SELECT 'product_id' AS column_name, COUNT(*) FILTER (WHERE product_id IS NULL) AS null_count, ROUND(COUNT(*) FILTER (WHERE product_id IS NULL) * 100.0 / COUNT(*), 2) AS null_pct, CASE WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN '✓' ELSE '✗' END AS status FROM gold.products
UNION ALL
SELECT 'product_name', COUNT(*) FILTER (WHERE product_name IS NULL), ROUND(COUNT(*) FILTER (WHERE product_name IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE product_name IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.products
UNION ALL
SELECT 'product_category', COUNT(*) FILTER (WHERE product_category IS NULL), ROUND(COUNT(*) FILTER (WHERE product_category IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE product_category IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.products
ORDER BY null_pct DESC
;

-- ============================================================================
-- SECTION 4: DATA STANDARDIZATION CHECKS  [gold.products]
-- ============================================================================

-- 4.1 Verify product_category values
SELECT 
    product_category,
    COUNT(*) AS product_count,
    CASE 
        WHEN product_category IN ('Laptops', 'Smartphones', 'Tablets', 'Audio', 
                                  'Wearables', 'Cameras', 'Monitors', 'Accessories') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM gold.products
GROUP BY product_category
ORDER BY product_count DESC
;

-- 4.2 Verify product naming consistency (no trailing spaces, mixed case anomalies)
SELECT 
    'Product Name Anomalies' AS check_name,
    COUNT(*) FILTER (WHERE product_name != TRIM(product_name)) AS trailing_spaces,
    COUNT(*) FILTER (WHERE product_name != INITCAP(product_name)) AS case_anomalies,
    CASE 
        WHEN COUNT(*) FILTER (WHERE product_name != TRIM(product_name)) = 0
        THEN '✓ PASS' ELSE '⚠ WARNING'
    END AS status
FROM gold.products
;


-- ============================================================================
-- SECTION 5: SILVER ALIGNMENT CHECKS  [gold.products]
-- ============================================================================

-- 5.1 All silver product_ids are present in gold.products
SELECT 
    'Missing Products from Silver' AS check_name,
    COUNT(*) AS missing_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM (SELECT DISTINCT product_id FROM silver.sales) s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.products g WHERE g.product_id = s.product_id
)
;

-- 5.2 No orphaned products in gold not present in silver
SELECT 
    'Orphaned Products in Gold' AS check_name,
    COUNT(*) AS orphaned_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.products g
WHERE NOT EXISTS (
    SELECT 1 FROM silver.sales s WHERE s.product_id = g.product_id
)
;

-- 5.3 Check product names match between gold and silver
SELECT 
    'Product Name Mismatch with Silver' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM gold.products g
JOIN (SELECT DISTINCT product_id, product_name FROM silver.sales) s 
    USING (product_id)
WHERE g.product_name != s.product_name
;

-- ============================================================================
-- SECTION 6: DISTRIBUTION CHECKS  [gold.products]
-- ============================================================================

-- 6.1 Product count by category
SELECT 
    product_category,
    COUNT(*) AS product_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM gold.products
GROUP BY product_category
ORDER BY product_count DESC
;

-- 6.2 Full product catalogue listing
SELECT
    product_id,
    product_name,
    product_category
FROM gold.products
ORDER BY product_category, product_name
;


-- ============================================================================
-- PART C: gold.customers
-- ============================================================================


-- ============================================================================
-- SECTION 1: RECORD COUNT AND BASIC STATISTICS  [gold.customers]
-- ============================================================================

-- 1.1 Total distinct customers and alignment with silver
SELECT 
    'gold.customers' AS view_name,
    (SELECT COUNT(DISTINCT customer_id) FROM gold.customers) AS gold_customer_count,
    (SELECT COUNT(DISTINCT customer_key) FROM silver.sales) AS silver_distinct_customers,
    (SELECT COUNT(*) FROM gold.customers) - (SELECT COUNT(DISTINCT customer_key) FROM silver.sales) AS difference,
    CASE 
        WHEN (SELECT COUNT(DISTINCT customer_id) FROM gold.customers) = (SELECT COUNT(DISTINCT customer_key) FROM silver.sales)
        THEN '✓ PASS' ELSE '✗ FAIL - Count mismatch with silver'
    END AS status
;

-- ============================================================================
-- SECTION 2: PRIMARY KEY AND UNIQUENESS CHECKS  [gold.customers]
-- ============================================================================

-- 2.1 Check for duplicate customer_ids (should return 0)
-- NOTE: If a customer has multiple age_group values in silver, DISTINCT will
-- create multiple rows per customer here. This check catches that.
SELECT 
    'Duplicate Customer IDs' AS check_name,
    COUNT(*) AS duplicate_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM (
    SELECT customer_id, COUNT(*) AS cnt
    FROM gold.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) duplicates
;

-- 2.2 List duplicate customer_ids with conflicting attribute details
SELECT 
    customer_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT customer_signup_date) AS distinct_signup_dates,
    COUNT(DISTINCT customer_age_group) AS distinct_age_groups,
    STRING_AGG(DISTINCT customer_age_group, ' | ') AS age_groups_found,
    STRING_AGG(DISTINCT customer_signup_date::TEXT, ' | ') AS signup_dates_found
FROM gold.customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20
;

-- 2.3 Check for NULL customer_ids (should return 0)
SELECT 
    'NULL Customer IDs' AS check_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_count,
    CASE WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.customers
;

-- ============================================================================
-- SECTION 3: NULL VALUE ANALYSIS  [gold.customers]
-- ============================================================================

-- 3.1 NULL counts across all columns
SELECT 
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_signup_date IS NULL) AS null_signup_date,
    COUNT(*) FILTER (WHERE customer_age_group IS NULL) AS null_age_group
FROM gold.customers
;

-- 3.2 NULL percentage report
SELECT 'customer_id' AS column_name, COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_count, ROUND(COUNT(*) FILTER (WHERE customer_id IS NULL) * 100.0 / COUNT(*), 2) AS null_pct, CASE WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN '✓' ELSE '✗' END AS status FROM gold.customers
UNION ALL
SELECT 'customer_signup_date', COUNT(*) FILTER (WHERE customer_signup_date IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_signup_date IS NULL) * 100.0 / COUNT(*), 2), CASE WHEN COUNT(*) FILTER (WHERE customer_signup_date IS NULL) = 0 THEN '✓' ELSE '✗' END FROM gold.customers
UNION ALL
SELECT 'customer_age_group', COUNT(*) FILTER (WHERE customer_age_group IS NULL), ROUND(COUNT(*) FILTER (WHERE customer_age_group IS NULL) * 100.0 / COUNT(*), 2), '○' FROM gold.customers
ORDER BY null_pct DESC
;

-- ============================================================================
-- SECTION 4: DATA STANDARDIZATION CHECKS  [gold.customers]
-- ============================================================================

-- 4.1 Verify customer_age_group values
SELECT 
    customer_age_group,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    CASE 
        WHEN customer_age_group IN ('18-24', '25-34', '35-44', '45-54', '55-64', '65+', 'Unknown') THEN '✓'
        ELSE '✗ Non-standard value'
    END AS validation
FROM gold.customers
WHERE customer_age_group IS NOT NULL
GROUP BY customer_age_group
ORDER BY customer_count DESC
;

-- ============================================================================
-- SECTION 5: DATE LOGIC VALIDATION  [gold.customers]
-- ============================================================================

-- 5.1 Check for future signup dates
SELECT 
    'Future Signup Dates' AS check_name,
    COUNT(*) FILTER (WHERE customer_signup_date > CURRENT_DATE) AS violation_count,
    CASE WHEN COUNT(*) FILTER (WHERE customer_signup_date > CURRENT_DATE) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.customers
;

-- 5.2 Signup date distribution by year
SELECT 
    EXTRACT(YEAR FROM customer_signup_date) AS signup_year,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM gold.customers
WHERE customer_signup_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM customer_signup_date)
ORDER BY signup_year
;

-- ============================================================================
-- SECTION 6: SILVER ALIGNMENT CHECKS  [gold.customers]
-- ============================================================================

-- 6.1 All silver customer_ids are present in gold.customers
SELECT 
    'Missing Customers from Silver' AS check_name,
    COUNT(*) AS missing_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM (SELECT DISTINCT customer_key FROM silver.sales) s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.customers g WHERE g.customer_id = s.customer_key
)
;

-- 6.2 No orphaned customers in gold not present in silver
SELECT 
    'Orphaned Customers in Gold' AS check_name,
    COUNT(*) AS orphaned_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.customers g
WHERE NOT EXISTS (
    SELECT 1 FROM silver.sales s WHERE s.customer_key = g.customer_id
)
;

-- 6.3 Customers in gold.orders with no matching record in gold.customers
SELECT 
    'Orders with No Customer Record' AS check_name,
    COUNT(DISTINCT o.customer_id) AS unmatched_customers,
    CASE WHEN COUNT(DISTINCT o.customer_id) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders o
WHERE NOT EXISTS (
    SELECT 1 FROM gold.customers c WHERE c.customer_id = o.customer_id
)
;

-- 6.4 Customers in gold.customers with no orders in gold.orders
SELECT 
    'Customers with No Orders' AS check_name,
    COUNT(DISTINCT c.customer_id) AS customers_without_orders,
    CASE WHEN COUNT(DISTINCT c.customer_id) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM gold.customers c
WHERE NOT EXISTS (
    SELECT 1 FROM gold.orders o WHERE o.customer_id = c.customer_id
)
;

-- ============================================================================
-- SECTION 7: DISTRIBUTION CHECKS  [gold.customers]
-- ============================================================================

-- 7.1 Customer distribution by age group
SELECT 
    COALESCE(customer_age_group, 'NULL') AS customer_age_group,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM gold.customers
GROUP BY customer_age_group
ORDER BY customer_count DESC
;

-- ============================================================================
-- SECTION 8: GOLD LAYER JOIN INTEGRITY CHECK (all 3 views)
-- ============================================================================

-- 8.1 Full join test - orders, products, and customers should all link correctly
SELECT 
    'Full Gold Join Integrity' AS check_name,
    COUNT(*) AS joinable_rows,
    (SELECT COUNT(*) FROM gold.orders) AS total_orders,
    CASE 
        WHEN COUNT(*) = (SELECT COUNT(*) FROM gold.orders) 
        THEN '✓ PASS' ELSE '✗ FAIL - Some orders cannot join to product or customer'
    END AS status
FROM gold.orders o
INNER JOIN gold.products p USING (product_id)
INNER JOIN gold.customers c USING (customer_id)
;

-- 8.2 Identify any orders that cannot join to gold.products
SELECT 
    'Orders Missing From gold.products' AS check_name,
    COUNT(DISTINCT o.product_id) AS unmatched_product_ids,
    CASE WHEN COUNT(DISTINCT o.product_id) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders o
LEFT JOIN gold.products p USING (product_id)
WHERE p.product_id IS NULL
;

-- 8.3 Identify any orders that cannot join to gold.customers
SELECT 
    'Orders Missing From gold.customers' AS check_name,
    COUNT(DISTINCT o.customer_id) AS unmatched_customer_ids,
    CASE WHEN COUNT(DISTINCT o.customer_id) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM gold.orders o
LEFT JOIN gold.customers c USING (customer_id)
WHERE c.customer_id IS NULL
;

-- ============================================================================
-- SECTION 9: COMPREHENSIVE SUMMARY SCORECARD (all 3 views)
-- ============================================================================

-- 9.1 Final summary across all three gold views
SELECT 
    'gold.orders' AS view_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(SUM(refund_amount), 2) AS total_refunds
FROM gold.orders
UNION ALL
SELECT 
    'gold.products',
    COUNT(*), NULL, NULL, NULL, NULL
FROM gold.products
UNION ALL
SELECT 
    'gold.customers',
    COUNT(*), NULL, NULL, NULL, NULL
FROM gold.customers
;

-- ============================================================================
-- End of Gold Layer Data Quality Validation Script
-- ============================================================================
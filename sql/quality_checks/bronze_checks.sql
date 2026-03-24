-- ============================================================================
-- STEP 3: IDENTIFY ADDITIONAL DATA QUALITY ISSUES
-- ============================================================================

-- 3.1 Find duplicate Order IDs (these are true duplicates that need removal)
SELECT 
    order_id, 
    COUNT(*) AS occurrence_count
FROM bronze.sales
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- 3.2 Check for NULL values in each column
SELECT 
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE ship_date IS NULL) AS null_ship_date,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_age_group IS NULL) AS null_age_group,
    COUNT(*) FILTER (WHERE customer_gender IS NULL) AS null_gender,
    COUNT(*) FILTER (WHERE loyalty_tier IS NULL) AS null_loyalty_tier,
    COUNT(*) FILTER (WHERE marketing_channel IS NULL) AS null_marketing_channel,
    COUNT(*) FILTER (WHERE customer_satisfaction IS NULL) AS null_satisfaction
FROM bronze.sales;

-- 3.3 Find inconsistent Order Status values (case sensitivity, typos)
SELECT 
    order_status,
    COUNT(*) AS count
FROM bronze.sales
GROUP BY order_status
ORDER BY order_status, count DESC;
-- Expected issues: mixed case like 'completed', 'COMPLETED', 'Complete', 'Completed'
-- Expected issues: 'PENDING', 'Pending'

-- 3.4 Find inconsistent Gender values
SELECT 
    customer_gender,
    COUNT(*) AS count
FROM bronze.sales
GROUP BY customer_gender
ORDER BY count DESC;
-- Expected issues: 'M', 'F', 'male', 'female', 'Male', 'Female', etc.
-- Recommended Format: 'Female', 'Male', 'Other', 'Prefer not to say', 'Unknown' (if applicable)

-- 3.5 Find illogical dates (ship_date before order_date)
SELECT 
    order_id,
    order_date,
    ship_date,
    ship_date - order_date AS days_difference
FROM bronze.sales
WHERE ship_date < order_date
ORDER BY days_difference
;
-- Expected issues: ship_date before order_date, which is illogical.

-- 3.6 Check for negative or zero values where they shouldn't exist
SELECT 
    COUNT(*) FILTER (WHERE quantity <= 0) AS invalid_quantity,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS invalid_unit_price,
    COUNT(*) FILTER (WHERE total_amount <= 0) AS invalid_total_amount,
    COUNT(*) FILTER (WHERE discount_percentage < 0 OR discount_percentage > 1) AS invalid_discount
FROM bronze.sales;
-- No negative or zero values should exist for quantity, unit_price, total_amount. Discount percentage should be between 0 and 1 (0% to 100%).
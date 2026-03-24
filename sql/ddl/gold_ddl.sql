-- Create gold schema: Will contain denormalized tables and views optimized for business intelligence and reporting
CREATE SCHEMA IF NOT EXISTS gold;

-- Three distinct views: orders, products, customers
-- Create view for orders with all relevant information for analysis and reporting
CREATE OR REPLACE VIEW gold.orders AS
SELECT
    order_id,
    order_date,
    ship_date,
    order_status,
    customer_key AS customer_id,         -- surrogate key for reliable joins
    product_id,
    quantity,
    unit_price,
    unit_cost,
    total_cost,
    discount_percentage,
    tax_amount,
    shipping_cost,
    total_amount,
    profit,
    profit_margin_percent,
    payment_method,
    marketing_channel,
    device_type,
    is_first_purchase,
    is_refunded,
    refund_amount,
    customer_satisfaction,
    delivery_days,
    region
FROM silver.sales
;


-- Create view for products with distinct product information
CREATE OR REPLACE VIEW gold.products AS
    SELECT DISTINCT
        product_id,
        product_name,
        product_category
    FROM silver.sales
;

-- Create view for customers with distinct customer information
CREATE OR REPLACE VIEW gold.customers AS
SELECT
    customer_key AS customer_id,
    customer_signup_date,
    customer_age_group,
    customer_gender,
    customer_country,
    customer_state,
    loyalty_tier
FROM silver.customers
;
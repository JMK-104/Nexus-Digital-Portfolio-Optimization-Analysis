-- Create silver schema
CREATE SCHEMA IF NOT EXISTS silver;

-- Create silver sales table
CREATE TABLE IF NOT EXISTS silver.sales (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL,
    ship_date DATE,
    order_status VARCHAR(50),
    customer_id VARCHAR(20) NOT NULL,
    customer_signup_date DATE,
    customer_age_group VARCHAR(20),
    customer_gender VARCHAR(50),
    customer_country VARCHAR(50),
    customer_state VARCHAR(50),
    loyalty_tier VARCHAR(20),
    is_first_purchase BOOLEAN,
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100),
    product_category VARCHAR(50),
    quantity NUMERIC NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_percentage DECIMAL(5, 2) CHECK (discount_percentage >= 0 AND discount_percentage <= 1),
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2),
    shipping_cost DECIMAL(10, 2),
    total_amount DECIMAL(10, 2) NOT NULL,
    unit_cost DECIMAL(10, 2),
    total_cost DECIMAL(10, 2),
    profit DECIMAL(10, 2),
    profit_margin_percent DECIMAL(5, 2),
    payment_method VARCHAR(50),
    marketing_channel VARCHAR(50),
    device_type VARCHAR(20),
    is_refunded BOOLEAN DEFAULT FALSE,
    refund_amount DECIMAL(10, 2) DEFAULT 0.00,
    customer_satisfaction NUMERIC CHECK (customer_satisfaction >= 0 AND customer_satisfaction <= 5),
    delivery_days NUMERIC,
    region VARCHAR(50)
)
;

DROP TABLE silver.sales;

-- Populate silver table with cleaned and transformed data from bronze.sales
INSERT INTO silver.sales (
    order_id,
    order_date,
    ship_date,
    order_status,
    customer_id,
    customer_signup_date,
    customer_age_group,
    customer_gender,
    customer_country,
    customer_state,
    loyalty_tier,
    is_first_purchase,
    product_id,
    product_name,
    product_category,
    quantity,
    unit_price,
    discount_percentage,
    subtotal,
    tax_amount,
    shipping_cost,
    total_amount,
    unit_cost,
    total_cost,
    profit,
    profit_margin_percent,
    payment_method,
    marketing_channel,
    device_type,
    is_refunded,
    refund_amount,
    customer_satisfaction,
    delivery_days,
    region
)
WITH prelim_table AS (
    SELECT
        ROW_NUMBER() OVER() AS order_id,
        order_date,
        ship_date,
        CASE order_status
            WHEN 'completed' THEN 'Completed'
            WHEN 'COMPLETED' THEN 'Completed'
            WHEN 'Complete' THEN 'Completed'
            WHEN 'PENDING' THEN 'Pending'
            WHEN 'shipped' THEN 'Shipped'
            ELSE order_status
        END AS order_status,
        customer_id,
        customer_signup_date,
        CASE 
            WHEN customer_age_group IS NULL THEN 'Unknown'
            ELSE customer_age_group
        END AS customer_age_group,
        CASE
            WHEN customer_gender = 'female' THEN 'Female'
            WHEN customer_gender = 'male' THEN 'Male'
            WHEN customer_gender = 'F' THEN 'Female'
            WHEN customer_gender = 'M' THEN 'Male'
            WHEN customer_gender = 'Prefer not to say' THEN 'Prefer Not To Say'
            WHEN customer_gender IS NULL THEN 'Unknown'
            ELSE customer_gender
        END AS customer_gender,
        customer_country,
        CASE
            WHEN customer_state IS NULL THEN 'Outside USA'
            ELSE customer_state
        END AS customer_state,
        CASE 
            WHEN loyalty_tier IS NULL THEN 'None'
            ELSE loyalty_tier
        END AS loyalty_tier,
        is_first_purchase,
        product_id,
        product_name,
        product_category,
        quantity,
        unit_price,
        discount_percentage,
        subtotal,
        tax_amount,
        shipping_cost,
        total_amount,
        unit_cost,
        total_cost,
        profit,
        profit_margin_percent,
        payment_method,
        CASE
            WHEN marketing_channel IS NULL THEN 'Unknown'
            ELSE marketing_channel
        END AS marketing_channel,
        device_type,
        is_refunded,
        refund_amount,
        CASE
            WHEN customer_satisfaction IS NULL THEN 0
            ELSE customer_satisfaction
        END AS customer_satisfaction,
        CASE
            WHEN delivery_days IS NULL THEN ship_date - order_date
            ELSE delivery_days
        END as delivery_days,
        region
    FROM bronze.sales
    WHERE delivery_days >= 0 OR delivery_days IS NULL
    ORDER BY order_date ASC
)
SELECT
    *
FROM prelim_table
WHERE ship_date >= order_date OR ship_date IS NULL
;

-- Create silver customers table to handle broken customer_id column

CREATE TABLE silver.customers AS
SELECT
    CONCAT('CUST_', ROW_NUMBER() OVER (
        ORDER BY customer_id, customer_signup_date, customer_age_group
    ))                           AS customer_key,
    customer_id,                -- Retained for traceability back to source
    customer_signup_date,
    customer_age_group,
    customer_gender,
    customer_country,
    customer_state,
    loyalty_tier
FROM (
    SELECT DISTINCT
        customer_id,
        customer_signup_date,
        customer_age_group,
        customer_gender,
        customer_country,
        customer_state,
        loyalty_tier
    FROM silver.sales
) unique_customers
;

-- Add primary key constraint on the new surrogate key
ALTER TABLE silver.customers
    ADD CONSTRAINT pk_customers PRIMARY KEY (customer_key)
;

-- Add new customer key to silver.sales
ALTER TABLE silver.sales
    ADD COLUMN customer_key VARCHAR(50)
;


-- Populate customer_key column with values from silver.customers table

UPDATE silver.sales AS s
SET customer_key = c.customer_key
FROM silver.customers AS c
WHERE s.customer_id           = c.customer_id
  AND s.customer_signup_date  = c.customer_signup_date
  AND s.customer_age_group    = c.customer_age_group
  AND s.customer_gender       = c.customer_gender
  AND s.customer_country      = c.customer_country
  AND s.customer_state        = c.customer_state
  AND s.loyalty_tier          = c.loyalty_tier
;

-- Test to see if key has applied correctly
SELECT 
    customer_key,
    customer_id,
    customer_signup_date,
    customer_age_group,
    customer_gender,
    customer_country,
    customer_state,
    loyalty_tier
FROM silver.sales
;

-- Add FK constraint to newly created key
ALTER TABLE silver.sales
    ALTER COLUMN customer_key SET NOT NULL
;

ALTER TABLE silver.sales
    ADD CONSTRAINT fk_sales_customer
    FOREIGN KEY (customer_key) REFERENCES silver.customers(customer_key)
;
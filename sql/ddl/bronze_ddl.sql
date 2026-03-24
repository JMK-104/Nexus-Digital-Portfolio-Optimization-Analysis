-- Create bronze schema
CREATE SCHEMA IF NOT EXISTS bronze;

-- Create bronze table
CREATE TABLE IF NOT EXISTS bronze.sales (
    order_id VARCHAR(20),
    order_date DATE NOT NULL,
    ship_date DATE,
    order_status VARCHAR(50),
    customer_id VARCHAR(20) NOT NULL,
    customer_signup_date DATE,
    customer_age_group VARCHAR(20),
    customer_gender VARCHAR(50),
    customer_country VARCHAR(50),
    customer_state VARCHAR(10),
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
    customer_satisfaction NUMERIC CHECK (customer_satisfaction >= 1 AND customer_satisfaction <= 5),
    delivery_days NUMERIC,
    region VARCHAR(50)
)
;

-- Populate sales table with data from csv
COPY bronze.sales (
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
FROM '/Users/justinkakuyo/Desktop/Dev/Data Analytics/Projects/Nexus Digital/Excel/Original Dataset/nexus_digital_sales_original.csv'
DELIMITER ','
CSV HEADER
;
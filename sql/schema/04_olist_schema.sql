-- Brazilian Olist E-Commerce Schema
-- Purpose: Store industry benchmark data from Brazilian e-commerce marketplace
-- Business Context: Industry comparison metrics for market performance analysis
-- Data Source: Olist Brazilian E-commerce dataset (100k orders from 2016-2018)

-- Use industry schema
SET search_path TO industry;

-- Customers dataset: Customer information
CREATE TABLE IF NOT EXISTS olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

COMMENT ON TABLE olist_customers_dataset IS 'Customer data from Brazilian e-commerce marketplace';
COMMENT ON COLUMN olist_customers_dataset.customer_id IS 'Order-specific customer ID (unique per order)';
COMMENT ON COLUMN olist_customers_dataset.customer_unique_id IS 'Unique customer identifier across all orders';

-- Orders dataset: Core order information
CREATE TABLE IF NOT EXISTS olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES olist_customers_dataset(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

COMMENT ON TABLE olist_orders_dataset IS 'Order transactions from 2016-2018 Brazilian e-commerce';
COMMENT ON COLUMN olist_orders_dataset.order_status IS 'Status: delivered, shipped, canceled, invoiced, processing, approved, created, unavailable';
COMMENT ON COLUMN olist_orders_dataset.order_purchase_timestamp IS 'Order placement timestamp';
COMMENT ON COLUMN olist_orders_dataset.order_delivered_customer_date IS 'Actual delivery timestamp';

-- Order items dataset: Order line items
CREATE TABLE IF NOT EXISTS olist_order_items_dataset (
    order_id VARCHAR(50) REFERENCES olist_orders_dataset(order_id),
    order_item_id INTEGER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

COMMENT ON TABLE olist_order_items_dataset IS 'Order line items with product and seller information';
COMMENT ON COLUMN olist_order_items_dataset.price IS 'Item price in Brazilian Real (BRL)';
COMMENT ON COLUMN olist_order_items_dataset.freight_value IS 'Shipping cost for the item';

-- Products dataset: Product catalog
CREATE TABLE IF NOT EXISTS olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

COMMENT ON TABLE olist_products_dataset IS 'Product catalog with physical attributes';
COMMENT ON COLUMN olist_products_dataset.product_category_name IS 'Product category in Portuguese';

-- Sellers dataset: Marketplace sellers
CREATE TABLE IF NOT EXISTS olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

COMMENT ON TABLE olist_sellers_dataset IS 'Seller information for marketplace analysis';

-- Order payments dataset: Payment information
CREATE TABLE IF NOT EXISTS olist_order_payments_dataset (
    order_id VARCHAR(50) REFERENCES olist_orders_dataset(order_id),
    payment_sequential INTEGER,
    payment_type VARCHAR(20),
    payment_installments INTEGER,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

COMMENT ON TABLE olist_order_payments_dataset IS 'Payment methods and values for orders';
COMMENT ON COLUMN olist_order_payments_dataset.payment_type IS 'Payment method: credit_card, boleto, voucher, debit_card';
COMMENT ON COLUMN olist_order_payments_dataset.payment_installments IS 'Number of payment installments';

-- Order reviews dataset: Customer feedback
CREATE TABLE IF NOT EXISTS olist_order_reviews_dataset (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES olist_orders_dataset(order_id),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

COMMENT ON TABLE olist_order_reviews_dataset IS 'Customer reviews and ratings';
COMMENT ON COLUMN olist_order_reviews_dataset.review_score IS 'Rating score 1-5';

-- Geolocation dataset: Brazilian zip codes
CREATE TABLE IF NOT EXISTS olist_geolocation_dataset (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);

COMMENT ON TABLE olist_geolocation_dataset IS 'Geographic coordinates for Brazilian zip codes';

-- Product category translation: Portuguese to English
CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

COMMENT ON TABLE product_category_name_translation IS 'Translation of product categories from Portuguese to English';

-- Create indexes for performance
CREATE INDEX idx_orders_customer ON olist_orders_dataset(customer_id);
CREATE INDEX idx_orders_status ON olist_orders_dataset(order_status);
CREATE INDEX idx_orders_purchase_date ON olist_orders_dataset(order_purchase_timestamp);
CREATE INDEX idx_order_items_product ON olist_order_items_dataset(product_id);
CREATE INDEX idx_order_items_seller ON olist_order_items_dataset(seller_id);
CREATE INDEX idx_products_category ON olist_products_dataset(product_category_name);
CREATE INDEX idx_payments_type ON olist_order_payments_dataset(payment_type);
CREATE INDEX idx_reviews_score ON olist_order_reviews_dataset(review_score);
CREATE INDEX idx_geo_zip ON olist_geolocation_dataset(geolocation_zip_code_prefix);

-- Create materialized view for order summary
CREATE MATERIALIZED VIEW olist_order_summary AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    DATE_PART('day', o.order_delivered_customer_date - o.order_purchase_timestamp) as delivery_days,
    DATE_PART('day', o.order_delivered_customer_date - o.order_estimated_delivery_date) as delivery_delay_days,
    COUNT(DISTINCT oi.order_item_id) as item_count,
    COUNT(DISTINCT oi.product_id) as product_count,
    COUNT(DISTINCT oi.seller_id) as seller_count,
    SUM(oi.price) as order_value,
    SUM(oi.freight_value) as total_freight,
    AVG(r.review_score) as avg_review_score
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
GROUP BY o.order_id, o.customer_id, o.order_status, o.order_purchase_timestamp, 
         o.order_delivered_customer_date, o.order_estimated_delivery_date;

COMMENT ON MATERIALIZED VIEW olist_order_summary IS 'Pre-calculated order metrics for performance analysis';

-- Create view for customer purchase behavior
CREATE OR REPLACE VIEW customer_purchase_behavior AS
WITH customer_stats AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) as order_count,
        MIN(o.order_purchase_timestamp) as first_purchase,
        MAX(o.order_purchase_timestamp) as last_purchase,
        DATE_PART('day', MAX(o.order_purchase_timestamp) - MIN(o.order_purchase_timestamp)) as customer_lifetime_days,
        SUM(oi.price) as total_spent,
        AVG(oi.price) as avg_order_value
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    *,
    CASE 
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count = 2 THEN 'Returning'
        ELSE 'Loyal'
    END as customer_type
FROM customer_stats;

COMMENT ON VIEW customer_purchase_behavior IS 'Customer segmentation based on purchase history';

-- Function to convert BRL to USD (historical rate ~4 BRL = 1 USD)
CREATE OR REPLACE FUNCTION convert_brl_to_usd(price_brl DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    RETURN ROUND(price_brl / 4, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION convert_brl_to_usd IS 'Converts Brazilian Real to USD for comparison (1 USD = 4 BRL approx)';

-- Data quality constraints
ALTER TABLE olist_orders_dataset 
    ADD CONSTRAINT check_order_dates CHECK (
        order_purchase_timestamp <= COALESCE(order_approved_at, order_purchase_timestamp) AND
        order_purchase_timestamp <= COALESCE(order_delivered_carrier_date, order_purchase_timestamp) AND
        order_purchase_timestamp <= COALESCE(order_delivered_customer_date, order_purchase_timestamp)
    );

ALTER TABLE olist_order_reviews_dataset 
    ADD CONSTRAINT check_review_score CHECK (review_score >= 1 AND review_score <= 5);

ALTER TABLE olist_order_payments_dataset 
    ADD CONSTRAINT check_payment_value CHECK (payment_value > 0);

-- Create staging tables for bulk import
CREATE TABLE IF NOT EXISTS olist_import_staging (
    table_name VARCHAR(50),
    row_data JSONB,
    import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE olist_import_staging IS 'Staging table for Olist data imports';

-- Import log
CREATE TABLE IF NOT EXISTS olist_import_log (
    import_id SERIAL PRIMARY KEY,
    import_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50),
    rows_imported INTEGER,
    import_status VARCHAR(20),
    error_message TEXT
);

COMMENT ON TABLE olist_import_log IS 'Track Olist data import operations';

-- Notification for successful schema creation
DO $$
BEGIN
    RAISE NOTICE 'Olist Brazilian e-commerce schema created successfully!';
    RAISE NOTICE 'Tables: customers, orders, order_items, products, sellers, payments, reviews, geolocation';
    RAISE NOTICE 'Views: order_summary, customer_purchase_behavior';
    RAISE NOTICE 'Ready for data import from Kaggle dataset';
END $$;
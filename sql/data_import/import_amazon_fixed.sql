-- Amazon Data Import - Robust Version
-- Handles all encoding and data format issues systematically

-- Set schema and encoding
SET search_path TO competitive;
SET client_encoding = 'UTF8';

-- Drop and recreate tables for clean import
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- Create products table
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name TEXT,
    category_hierarchy TEXT,
    price_inr DECIMAL(10,2),
    price_usd DECIMAL(10,2),
    original_price_inr DECIMAL(10,2),
    original_price_usd DECIMAL(10,2),
    discount_percentage INTEGER,
    rating DECIMAL(3,2),
    rating_count INTEGER,
    description TEXT,
    img_link TEXT,
    product_link TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create reviews table
CREATE TABLE reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) REFERENCES products(product_id),
    user_id VARCHAR(100),
    user_name VARCHAR(200),
    review_title TEXT,
    review_text TEXT,
    review_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_products_category ON products(category_hierarchy);
CREATE INDEX idx_products_price ON products(price_usd);
CREATE INDEX idx_products_rating ON products(rating);
CREATE INDEX idx_reviews_product ON reviews(product_id);

-- Create staging table (not temporary this time)
DROP TABLE IF EXISTS amazon_staging;
CREATE TABLE amazon_staging (
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    discounted_price TEXT,
    actual_price TEXT,
    discount_percentage TEXT,
    rating TEXT,
    rating_count TEXT,
    about_product TEXT,
    user_id TEXT,
    user_name TEXT,
    review_id TEXT,
    review_title TEXT,
    review_content TEXT,
    img_link TEXT,
    product_link TEXT
);

\echo 'Importing Amazon CSV data...'
\copy amazon_staging FROM 'examples/amazon.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');

\echo 'Amazon staging data imported successfully. Processing data transformations...'
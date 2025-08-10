-- Amazon Competitive Intelligence Schema
-- Purpose: Store Amazon product catalog data for competitive pricing and sentiment analysis
-- Business Context: Market intelligence for price positioning and customer sentiment tracking
-- Data Source: Amazon product CSV with Indian Rupee pricing and customer reviews

-- Use competitive schema
SET search_path TO competitive;

-- Products table: Amazon product catalog
CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name TEXT NOT NULL,
    category TEXT,
    category_hierarchy TEXT[], -- Array to store category path
    discounted_price_inr TEXT, -- Original format with ₹ symbol
    discounted_price DECIMAL(10,2), -- Converted to decimal
    actual_price_inr TEXT, -- Original format
    actual_price DECIMAL(10,2), -- Converted to decimal
    discount_percentage INTEGER,
    rating DECIMAL(3,2),
    rating_count INTEGER,
    about_product TEXT,
    img_link TEXT,
    product_link TEXT,
    data_import_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE products IS 'Amazon product catalog for competitive pricing analysis';
COMMENT ON COLUMN products.category_hierarchy IS 'Category path split by | for hierarchy analysis';
COMMENT ON COLUMN products.discounted_price_inr IS 'Original price string with ₹ symbol for audit';
COMMENT ON COLUMN products.discounted_price IS 'Converted price in decimal for calculations';
COMMENT ON COLUMN products.discount_percentage IS 'Percentage discount offered';
COMMENT ON COLUMN products.rating IS 'Average product rating (1-5 scale)';

-- Reviews table: Customer feedback (normalized)
CREATE TABLE IF NOT EXISTS reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(20) REFERENCES products(product_id),
    user_id VARCHAR(50),
    user_name TEXT,
    review_title TEXT,
    review_content TEXT,
    review_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sentiment_score DECIMAL(3,2), -- To be calculated later
    data_import_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reviews IS 'Customer reviews for sentiment analysis and product feedback';
COMMENT ON COLUMN reviews.sentiment_score IS 'Calculated sentiment score (-1 to 1) for analysis';

-- Product categories table (normalized from hierarchy)
CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    parent_category_id INTEGER REFERENCES categories(category_id),
    category_level INTEGER NOT NULL,
    full_path TEXT
);

COMMENT ON TABLE categories IS 'Normalized category hierarchy for better analysis';

-- Create indexes for performance
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price_range ON products(discounted_price);
CREATE INDEX idx_products_rating ON products(rating DESC);
CREATE INDEX idx_products_discount ON products(discount_percentage DESC);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_categories_parent ON categories(parent_category_id);

-- Create text search indexes for product search
CREATE INDEX idx_products_name_search ON products USING gin(to_tsvector('english', product_name));
CREATE INDEX idx_reviews_content_search ON reviews USING gin(to_tsvector('english', review_content));

-- Materialized view for price analysis by category
CREATE MATERIALIZED VIEW category_price_analysis AS
SELECT 
    COALESCE(category, 'Uncategorized') as category,
    COUNT(*) as product_count,
    AVG(discounted_price) as avg_discounted_price,
    AVG(actual_price) as avg_actual_price,
    AVG(discount_percentage) as avg_discount_pct,
    MIN(discounted_price) as min_price,
    MAX(discounted_price) as max_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY discounted_price) as median_price,
    AVG(rating) as avg_rating,
    SUM(rating_count) as total_reviews
FROM products
WHERE discounted_price IS NOT NULL
GROUP BY COALESCE(category, 'Uncategorized');

COMMENT ON MATERIALIZED VIEW category_price_analysis IS 'Pre-calculated price metrics by category for fast analysis';

-- Create index on materialized view
CREATE INDEX idx_category_price_analysis_cat ON category_price_analysis(category);

-- View for top-rated products by category
CREATE OR REPLACE VIEW top_rated_products AS
SELECT 
    category,
    product_id,
    product_name,
    rating,
    rating_count,
    discounted_price,
    discount_percentage,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY rating DESC, rating_count DESC) as rank_in_category
FROM products
WHERE rating IS NOT NULL AND rating_count > 10;

COMMENT ON VIEW top_rated_products IS 'Top-rated products by category with minimum review threshold';

-- Trigger to parse category hierarchy on insert/update
CREATE OR REPLACE FUNCTION parse_category_hierarchy()
RETURNS TRIGGER AS $$
BEGIN
    -- Split category string by | and store as array
    IF NEW.category IS NOT NULL THEN
        NEW.category_hierarchy := string_to_array(NEW.category, '|');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_parse_categories
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION parse_category_hierarchy();

-- Function to calculate price in USD (assuming 1 USD = 83 INR)
CREATE OR REPLACE FUNCTION convert_inr_to_usd(price_inr DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    RETURN ROUND(price_inr / 83, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION convert_inr_to_usd IS 'Converts Indian Rupees to USD for global comparison (1 USD = 83 INR)';

-- Data quality constraints
ALTER TABLE products ADD CONSTRAINT check_rating_range CHECK (rating >= 0 AND rating <= 5);
ALTER TABLE products ADD CONSTRAINT check_discount_range CHECK (discount_percentage >= 0 AND discount_percentage <= 100);
ALTER TABLE products ADD CONSTRAINT check_price_consistency CHECK (
    discounted_price IS NULL OR actual_price IS NULL OR discounted_price <= actual_price
);

-- Create staging table for CSV import
CREATE TABLE IF NOT EXISTS products_staging (
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

COMMENT ON TABLE products_staging IS 'Temporary staging table for CSV import before normalization';

-- Create import log table
CREATE TABLE IF NOT EXISTS import_log (
    import_id SERIAL PRIMARY KEY,
    import_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    file_name TEXT,
    products_imported INTEGER,
    reviews_imported INTEGER,
    errors_count INTEGER,
    error_details JSONB
);

COMMENT ON TABLE import_log IS 'Track Amazon data imports for audit and debugging';

-- Notification for successful schema creation
DO $$
BEGIN
    RAISE NOTICE 'Amazon competitive intelligence schema created successfully!';
    RAISE NOTICE 'Tables: products, reviews, categories, products_staging';
    RAISE NOTICE 'Views: category_price_analysis, top_rated_products';
    RAISE NOTICE 'Functions: Currency conversion and category parsing included';
END $$;
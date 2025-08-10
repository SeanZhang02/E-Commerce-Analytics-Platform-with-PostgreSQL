-- Performance Optimization Indexes
-- Purpose: Create comprehensive indexes for optimal query performance
-- Business Context: Enable sub-second analytics queries for business intelligence

-- Internal schema indexes (Northwind)
SET search_path TO internal;

-- Order analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_date 
    ON orders(customer_id, order_date DESC);
    
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_employee_date 
    ON orders(employee_id, order_date DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_date_range 
    ON orders(order_date) WHERE order_date >= '1996-01-01';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_year_month 
    ON orders(DATE_TRUNC('month', order_date));

-- Order details for revenue calculations
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_details_product_date 
    ON order_details(product_id, (SELECT order_date FROM orders WHERE orders.order_id = order_details.order_id));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_details_revenue 
    ON order_details((unit_price * quantity * (1 - discount)));

-- Product analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_price 
    ON products(category_id, unit_price DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_supplier_stock 
    ON products(supplier_id, units_in_stock);

-- Customer analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_country_city 
    ON customers(country, city);

-- Composite index for RFM analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_rfm_analysis 
    ON orders(customer_id, order_date DESC, (SELECT SUM(unit_price * quantity * (1 - discount)) FROM order_details WHERE order_details.order_id = orders.order_id));

-- Competitive schema indexes (Amazon)
SET search_path TO competitive;

-- Price analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_price_discount 
    ON products(discounted_price, discount_percentage) 
    WHERE discounted_price IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_rating_reviews 
    ON products(rating DESC, rating_count DESC) 
    WHERE rating IS NOT NULL;

-- Category performance indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_performance 
    ON products(category, rating DESC, rating_count DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_price 
    ON products(category, discounted_price);

-- Text search performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_search_gin 
    ON products USING gin(to_tsvector('english', product_name || ' ' || COALESCE(about_product, '')));

-- Review analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_product_sentiment 
    ON reviews(product_id, sentiment_score) 
    WHERE sentiment_score IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_date_sentiment 
    ON reviews(review_date, sentiment_score);

-- Industry schema indexes (Olist)
SET search_path TO industry;

-- Order timeline indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_orders_purchase_timeline 
    ON olist_orders_dataset(order_purchase_timestamp DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_orders_delivery_performance 
    ON olist_orders_dataset(order_purchase_timestamp, order_delivered_customer_date, order_estimated_delivery_date);

-- Customer behavior indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_customers_unique 
    ON olist_customers_dataset(customer_unique_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_orders_customer_status 
    ON olist_orders_dataset(customer_id, order_status, order_purchase_timestamp);

-- Order value and freight analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_order_items_value 
    ON olist_order_items_dataset(order_id, price DESC, freight_value);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_order_items_product_seller 
    ON olist_order_items_dataset(product_id, seller_id, price);

-- Payment analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_payments_type_value 
    ON olist_order_payments_dataset(payment_type, payment_value DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_payments_installments 
    ON olist_order_payments_dataset(payment_installments, payment_value);

-- Review performance indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_reviews_score_date 
    ON olist_order_reviews_dataset(review_score, review_creation_date DESC);

-- Geographic analysis indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_geo_location 
    ON olist_geolocation_dataset(geolocation_state, geolocation_city);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_customers_location 
    ON olist_customers_dataset(customer_state, customer_city);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_olist_sellers_location 
    ON olist_sellers_dataset(seller_state, seller_city);

-- Cross-schema analytical indexes for benchmarking
-- Composite indexes for competitive analysis
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_internal_monthly_revenue 
    ON internal.orders(DATE_TRUNC('month', order_date), 
                      (SELECT SUM(unit_price * quantity * (1 - discount)) 
                       FROM internal.order_details 
                       WHERE order_details.order_id = orders.order_id));

-- Partial indexes for active data
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_competitive_active_products 
    ON competitive.products(rating, rating_count) 
    WHERE rating >= 3.0 AND rating_count >= 10;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_industry_delivered_orders 
    ON industry.olist_orders_dataset(order_purchase_timestamp, order_delivered_customer_date) 
    WHERE order_status = 'delivered';

-- Index maintenance and statistics
-- Create function to refresh index statistics
CREATE OR REPLACE FUNCTION refresh_index_statistics()
RETURNS TEXT AS $$
BEGIN
    -- Update statistics for all tables
    ANALYZE internal.orders;
    ANALYZE internal.order_details;
    ANALYZE internal.products;
    ANALYZE internal.customers;
    
    ANALYZE competitive.products;
    ANALYZE competitive.reviews;
    ANALYZE competitive.categories;
    
    ANALYZE industry.olist_orders_dataset;
    ANALYZE industry.olist_order_items_dataset;
    ANALYZE industry.olist_customers_dataset;
    
    RETURN 'Index statistics refreshed successfully';
END;
$$ LANGUAGE plpgsql;

-- Create monitoring view for index usage
CREATE OR REPLACE VIEW public.index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan,
    CASE WHEN idx_scan = 0 THEN 'UNUSED'
         WHEN idx_scan < 10 THEN 'LOW_USAGE'
         ELSE 'ACTIVE'
    END as usage_status
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

COMMENT ON VIEW public.index_usage_stats IS 'Monitor index usage for optimization';

-- Performance tuning recommendations view
CREATE OR REPLACE VIEW public.performance_recommendations AS
WITH table_stats AS (
    SELECT 
        schemaname,
        tablename,
        n_tup_ins + n_tup_upd + n_tup_del as total_modifications,
        n_dead_tup,
        n_live_tup,
        CASE WHEN n_live_tup = 0 THEN 0 
             ELSE (n_dead_tup::float / n_live_tup) * 100 
        END as dead_tuple_ratio
    FROM pg_stat_user_tables
)
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN dead_tuple_ratio > 20 THEN 'VACUUM recommended'
        WHEN total_modifications > 1000 THEN 'ANALYZE recommended'
        ELSE 'OK'
    END as recommendation,
    dead_tuple_ratio,
    total_modifications
FROM table_stats
WHERE dead_tuple_ratio > 10 OR total_modifications > 500
ORDER BY dead_tuple_ratio DESC;

COMMENT ON VIEW public.performance_recommendations IS 'Automated performance tuning recommendations';

-- Create maintenance scheduling
CREATE OR REPLACE FUNCTION schedule_maintenance()
RETURNS TEXT AS $$
BEGIN
    -- Refresh materialized views
    REFRESH MATERIALIZED VIEW competitive.category_price_analysis;
    REFRESH MATERIALIZED VIEW industry.olist_order_summary;
    
    -- Update statistics
    PERFORM refresh_index_statistics();
    
    -- Log maintenance
    INSERT INTO public.data_import_log (table_name, rows_imported, rows_rejected, import_duration_seconds)
    VALUES ('maintenance_scheduled', 0, 0, 0);
    
    RETURN 'Maintenance completed successfully';
END;
$$ LANGUAGE plpgsql;

-- Notification for successful index creation
DO $$
DECLARE
    internal_indexes INTEGER;
    competitive_indexes INTEGER;
    industry_indexes INTEGER;
BEGIN
    -- Count indexes by schema
    SELECT COUNT(*) INTO internal_indexes
    FROM pg_indexes 
    WHERE schemaname = 'internal';
    
    SELECT COUNT(*) INTO competitive_indexes
    FROM pg_indexes 
    WHERE schemaname = 'competitive';
    
    SELECT COUNT(*) INTO industry_indexes
    FROM pg_indexes 
    WHERE schemaname = 'industry';
    
    RAISE NOTICE 'Performance indexes created successfully!';
    RAISE NOTICE 'Internal schema: % indexes', internal_indexes;
    RAISE NOTICE 'Competitive schema: % indexes', competitive_indexes;
    RAISE NOTICE 'Industry schema: % indexes', industry_indexes;
    RAISE NOTICE 'Monitoring views and maintenance functions available';
END $$;
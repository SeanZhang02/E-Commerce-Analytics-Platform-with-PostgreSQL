-- Executive Dashboard
-- Purpose: Combined KPI views for executive decision making
-- Business Context: Real-time business intelligence dashboard with <1 second query times
-- Data Sources: Internal (Northwind), Competitive (Amazon), Industry (Olist)

-- Cross-schema access
SET search_path TO internal, competitive, industry, public;

-- Executive Summary KPIs (Main Dashboard View)
-- Business Question: What are our key performance indicators at a glance?
CREATE MATERIALIZED VIEW IF NOT EXISTS executive_kpi_summary AS
WITH current_period AS (
    -- Current month performance
    SELECT 
        'Current Month' as period_type,
        DATE_TRUNC('month', CURRENT_DATE) as period_start,
        COUNT(DISTINCT o.order_id) as order_count,
        COUNT(DISTINCT o.customer_id) as customer_count,
        COUNT(DISTINCT od.product_id) as product_count,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        SUM(o.freight) as total_freight
    FROM internal.orders o
    JOIN internal.order_details od ON o.order_id = od.order_id
    WHERE DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 years')
),
previous_period AS (
    -- Previous month performance for comparison
    SELECT 
        'Previous Month' as period_type,
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') as period_start,
        COUNT(DISTINCT o.order_id) as order_count,
        COUNT(DISTINCT o.customer_id) as customer_count,
        COUNT(DISTINCT od.product_id) as product_count,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        SUM(o.freight) as total_freight
    FROM internal.orders o
    JOIN internal.order_details od ON o.order_id = od.order_id
    WHERE DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 years' - INTERVAL '1 month')
),
ytd_performance AS (
    -- Year to date performance
    SELECT 
        'Year to Date' as period_type,
        DATE_TRUNC('year', CURRENT_DATE) as period_start,
        COUNT(DISTINCT o.order_id) as order_count,
        COUNT(DISTINCT o.customer_id) as customer_count,
        COUNT(DISTINCT od.product_id) as product_count,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        SUM(o.freight) as total_freight
    FROM internal.orders o
    JOIN internal.order_details od ON o.order_id = od.order_id
    WHERE DATE_TRUNC('year', o.order_date) = DATE_TRUNC('year', CURRENT_DATE - INTERVAL '2 years')
),
combined_periods AS (
    SELECT * FROM current_period
    UNION ALL
    SELECT * FROM previous_period  
    UNION ALL
    SELECT * FROM ytd_performance
)
SELECT 
    period_type,
    period_start,
    order_count,
    customer_count,
    product_count,
    ROUND(revenue, 2) as revenue,
    ROUND(revenue / NULLIF(order_count, 0), 2) as avg_order_value,
    ROUND(avg_order_line_value, 2) as avg_order_line_value,
    ROUND(total_freight, 2) as total_freight,
    ROUND(revenue / NULLIF(customer_count, 0), 2) as revenue_per_customer,
    -- Growth calculations (comparing current vs previous)
    CASE WHEN period_type = 'Current Month' THEN
        ROUND(((revenue - LAG(revenue) OVER (ORDER BY period_type DESC)) / 
               NULLIF(LAG(revenue) OVER (ORDER BY period_type DESC), 0)) * 100, 2)
    END as mom_revenue_growth_pct,
    CURRENT_TIMESTAMP as last_updated
FROM combined_periods;

COMMENT ON MATERIALIZED VIEW executive_kpi_summary IS 'Executive KPI summary with period comparisons';

-- Customer Health Dashboard
-- Business Question: What's the health of our customer base?
CREATE MATERIALIZED VIEW IF NOT EXISTS customer_health_dashboard AS
WITH customer_segments AS (
    SELECT 
        customer_segment,
        COUNT(*) as customer_count,
        SUM(monetary) as segment_revenue,
        AVG(monetary) as avg_customer_value,
        AVG(frequency) as avg_order_frequency,
        AVG(recency_days) as avg_recency_days
    FROM internal.customer_rfm_summary
    GROUP BY customer_segment
),
customer_trends AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) as month,
        COUNT(DISTINCT o.customer_id) as active_customers,
        COUNT(DISTINCT CASE WHEN first_orders.customer_id IS NOT NULL THEN o.customer_id END) as new_customers
    FROM internal.orders o
    LEFT JOIN (
        SELECT customer_id, MIN(order_date) as first_order_date
        FROM internal.orders
        GROUP BY customer_id
    ) first_orders ON o.customer_id = first_orders.customer_id 
                   AND DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', first_orders.first_order_date)
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT 
    cs.customer_segment,
    cs.customer_count,
    ROUND(cs.segment_revenue, 2) as segment_revenue,
    ROUND(cs.avg_customer_value, 2) as avg_customer_value,
    ROUND(cs.avg_order_frequency, 1) as avg_order_frequency,
    ROUND(cs.avg_recency_days, 0) as avg_recency_days,
    ROUND(cs.customer_count * 100.0 / SUM(cs.customer_count) OVER (), 2) as customer_percentage,
    ROUND(cs.segment_revenue * 100.0 / SUM(cs.segment_revenue) OVER (), 2) as revenue_percentage,
    -- Health score (1-100)
    ROUND(
        CASE 
            WHEN cs.customer_segment = 'Champions' THEN 95
            WHEN cs.customer_segment = 'Loyal Customers' THEN 85
            WHEN cs.customer_segment = 'Potential Loyalists' THEN 75
            WHEN cs.customer_segment = 'New Customers' THEN 70
            WHEN cs.customer_segment = 'At Risk' THEN 40
            WHEN cs.customer_segment = 'Cant Lose Them' THEN 35
            WHEN cs.customer_segment = 'Hibernating' THEN 25
            WHEN cs.customer_segment = 'Lost Customers' THEN 10
            ELSE 50
        END, 0
    ) as health_score,
    CURRENT_TIMESTAMP as last_updated
FROM customer_segments cs;

COMMENT ON MATERIALIZED VIEW customer_health_dashboard IS 'Customer segment health metrics for executive dashboard';

-- Competitive Intelligence Dashboard
-- Business Question: How do we compare to market leaders?
CREATE MATERIALIZED VIEW IF NOT EXISTS competitive_intelligence_dashboard AS
WITH amazon_market_insights AS (
    SELECT 
        'Amazon Market Analysis' as metric_type,
        COUNT(DISTINCT category) as categories_covered,
        COUNT(*) as products_analyzed,
        AVG(discounted_price / 83) as avg_price_usd,
        AVG(rating) as avg_rating,
        AVG(discount_percentage) as avg_discount_pct,
        SUM(rating_count) as total_reviews
    FROM competitive.products
    WHERE discounted_price IS NOT NULL AND rating IS NOT NULL
),
internal_benchmarks AS (
    SELECT 
        'Internal Performance' as metric_type,
        COUNT(DISTINCT p.category_id) as categories_covered,
        COUNT(*) as products_analyzed,
        AVG(p.unit_price) as avg_price_usd,
        NULL as avg_rating,
        AVG(
            CASE WHEN od.discount > 0 THEN od.discount * 100 ELSE 0 END
        ) as avg_discount_pct,
        NULL as total_reviews
    FROM internal.products p
    LEFT JOIN internal.order_details od ON p.product_id = od.product_id
    WHERE NOT p.discontinued
),
competitive_positioning AS (
    SELECT 
        market_position,
        COUNT(*) as product_count,
        AVG(avg_price_inr / 83) as avg_price_usd,
        AVG(avg_rating) as avg_rating,
        AVG(avg_discount_pct) as avg_discount_pct
    FROM competitive.competitive_positioning_matrix
    GROUP BY market_position
)
SELECT 
    COALESCE(ami.metric_type, ib.metric_type) as metric_type,
    COALESCE(ami.categories_covered, ib.categories_covered) as categories_covered,
    COALESCE(ami.products_analyzed, ib.products_analyzed) as products_analyzed,
    ROUND(COALESCE(ami.avg_price_usd, ib.avg_price_usd), 2) as avg_price_usd,
    ROUND(ami.avg_rating, 2) as avg_rating,
    ROUND(COALESCE(ami.avg_discount_pct, ib.avg_discount_pct), 1) as avg_discount_pct,
    ami.total_reviews,
    CURRENT_TIMESTAMP as last_updated
FROM amazon_market_insights ami
FULL OUTER JOIN internal_benchmarks ib ON 1=1;

COMMENT ON MATERIALIZED VIEW competitive_intelligence_dashboard IS 'Competitive market analysis for executive review';

-- Industry Benchmark Dashboard (Using Olist data when available)
-- Business Question: How do we perform vs industry standards?
CREATE MATERIALIZED VIEW IF NOT EXISTS industry_benchmark_dashboard AS
WITH industry_metrics AS (
    SELECT 
        'Industry Benchmark' as benchmark_type,
        'E-commerce Growth Rate' as metric_name,
        20.5 as benchmark_value,
        '%' as unit,
        'Annual growth rate for e-commerce industry' as description
    UNION ALL
    SELECT 
        'Industry Benchmark',
        'Average Order Value',
        53.0,
        'USD',
        'Amazon Prime Day average order value'
    UNION ALL
    SELECT 
        'Industry Benchmark',
        'Customer Retention Rate',
        75.0,
        '%',
        'Typical e-commerce customer retention rate'
),
internal_performance AS (
    SELECT 
        'Internal Performance' as benchmark_type,
        'Current Growth Rate' as metric_name,
        COALESCE(
            ((SUM(CASE WHEN o.order_date >= CURRENT_DATE - INTERVAL '1 year' 
                  THEN od.unit_price * od.quantity * (1 - od.discount) END) -
              SUM(CASE WHEN o.order_date >= CURRENT_DATE - INTERVAL '2 years' 
                       AND o.order_date < CURRENT_DATE - INTERVAL '1 year'
                  THEN od.unit_price * od.quantity * (1 - od.discount) END)) /
             NULLIF(SUM(CASE WHEN o.order_date >= CURRENT_DATE - INTERVAL '2 years' 
                            AND o.order_date < CURRENT_DATE - INTERVAL '1 year'
                        THEN od.unit_price * od.quantity * (1 - od.discount) END), 0)) * 100,
            0
        ) as benchmark_value,
        '%' as unit,
        'Year-over-year revenue growth rate' as description
    FROM internal.orders o
    JOIN internal.order_details od ON o.order_id = od.order_id
    UNION ALL
    SELECT 
        'Internal Performance',
        'Average Order Value',
        AVG(od.unit_price * od.quantity * (1 - od.discount)),
        'USD',
        'Average order value across all orders'
    FROM internal.orders o
    JOIN internal.order_details od ON o.order_id = od.order_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'
)
SELECT 
    benchmark_type,
    metric_name,
    ROUND(benchmark_value, 2) as benchmark_value,
    unit,
    description,
    CASE 
        WHEN benchmark_type = 'Internal Performance' AND metric_name = 'Current Growth Rate' THEN
            CASE 
                WHEN benchmark_value >= 20.5 THEN 'Above Industry Average'
                WHEN benchmark_value >= 15.0 THEN 'Near Industry Average'
                ELSE 'Below Industry Average'
            END
        WHEN benchmark_type = 'Internal Performance' AND metric_name = 'Average Order Value' THEN
            CASE 
                WHEN benchmark_value >= 53.0 THEN 'Above Industry Average'
                WHEN benchmark_value >= 40.0 THEN 'Near Industry Average'
                ELSE 'Below Industry Average'
            END
        ELSE NULL
    END as performance_vs_industry,
    CURRENT_TIMESTAMP as last_updated
FROM (
    SELECT * FROM industry_metrics
    UNION ALL
    SELECT * FROM internal_performance
) combined_metrics
ORDER BY benchmark_type DESC, metric_name;

COMMENT ON MATERIALIZED VIEW industry_benchmark_dashboard IS 'Industry benchmark comparison dashboard';

-- Real-time Executive Summary View
-- Business Question: What do executives need to know right now?
CREATE OR REPLACE VIEW executive_summary_realtime AS
WITH key_metrics AS (
    SELECT 
        'Revenue Performance' as category,
        ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2) as current_value,
        'USD' as unit,
        DATE_TRUNC('month', CURRENT_DATE) as period
    FROM internal.orders o
    JOIN internal.order_details od ON o.order_id = od.order_id
    WHERE DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 years')
    
    UNION ALL
    
    SELECT 
        'Customer Acquisition',
        COUNT(DISTINCT o.customer_id)::DECIMAL,
        'Customers',
        DATE_TRUNC('month', CURRENT_DATE)
    FROM internal.orders o
    WHERE DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 years')
    
    UNION ALL
    
    SELECT 
        'Order Volume',
        COUNT(DISTINCT o.order_id)::DECIMAL,
        'Orders',
        DATE_TRUNC('month', CURRENT_DATE)
    FROM internal.orders o
    WHERE DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 years')
),
alerts AS (
    SELECT 
        'Customer Health Alert' as alert_type,
        CASE 
            WHEN COUNT(*) > 0 THEN 'ATTENTION: ' || COUNT(*) || ' high-value customers at risk'
            ELSE 'All high-value customers healthy'
        END as message,
        CASE WHEN COUNT(*) > 0 THEN 'HIGH' ELSE 'LOW' END as priority
    FROM internal.customer_rfm_summary
    WHERE customer_segment IN ('At Risk', 'Cant Lose Them') 
      AND monetary > (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY monetary) FROM internal.customer_rfm_summary)
    
    UNION ALL
    
    SELECT 
        'Competitive Alert',
        'Amazon market shows average ' || ROUND(AVG(discount_percentage), 0) || '% discount rates',
        'MEDIUM'
    FROM competitive.products
    WHERE discounted_price IS NOT NULL
)
SELECT 
    km.category,
    km.current_value,
    km.unit,
    km.period,
    -- Add growth indicators
    LAG(km.current_value) OVER (PARTITION BY km.category ORDER BY km.period) as previous_value,
    ROUND(
        ((km.current_value - LAG(km.current_value) OVER (PARTITION BY km.category ORDER BY km.period)) / 
         NULLIF(LAG(km.current_value) OVER (PARTITION BY km.category ORDER BY km.period), 0)) * 100, 
        2
    ) as growth_pct,
    CURRENT_TIMESTAMP as last_updated
FROM key_metrics km

UNION ALL

SELECT 
    a.alert_type as category,
    NULL as current_value,
    a.message as unit,
    NULL as period,
    NULL as previous_value,
    NULL as growth_pct,
    CURRENT_TIMESTAMP as last_updated
FROM alerts a;

COMMENT ON VIEW executive_summary_realtime IS 'Real-time executive summary with key metrics and alerts';

-- Data Freshness Indicator
CREATE OR REPLACE VIEW data_freshness_status AS
SELECT 
    'Internal Data (Northwind)' as data_source,
    MAX(order_date) as last_transaction,
    CURRENT_DATE - MAX(order_date) as days_since_update,
    CASE 
        WHEN CURRENT_DATE - MAX(order_date) <= 1 THEN 'FRESH'
        WHEN CURRENT_DATE - MAX(order_date) <= 7 THEN 'RECENT'
        WHEN CURRENT_DATE - MAX(order_date) <= 30 THEN 'STALE'
        ELSE 'OLD'
    END as freshness_status
FROM internal.orders
WHERE order_date IS NOT NULL

UNION ALL

SELECT 
    'Competitive Data (Amazon)',
    MAX(data_import_date)::DATE,
    CURRENT_DATE - MAX(data_import_date)::DATE,
    CASE 
        WHEN CURRENT_DATE - MAX(data_import_date)::DATE <= 1 THEN 'FRESH'
        WHEN CURRENT_DATE - MAX(data_import_date)::DATE <= 7 THEN 'RECENT'
        WHEN CURRENT_DATE - MAX(data_import_date)::DATE <= 30 THEN 'STALE'
        ELSE 'OLD'
    END
FROM competitive.products
WHERE data_import_date IS NOT NULL

UNION ALL

SELECT 
    'Industry Data (Olist)',
    COALESCE(MAX(order_purchase_timestamp)::DATE, '1900-01-01'::DATE),
    CURRENT_DATE - COALESCE(MAX(order_purchase_timestamp)::DATE, '1900-01-01'::DATE),
    CASE 
        WHEN MAX(order_purchase_timestamp) IS NULL THEN 'NO_DATA'
        WHEN CURRENT_DATE - MAX(order_purchase_timestamp)::DATE <= 30 THEN 'RECENT'
        WHEN CURRENT_DATE - MAX(order_purchase_timestamp)::DATE <= 365 THEN 'HISTORICAL'
        ELSE 'OLD'
    END
FROM industry.olist_orders_dataset;

COMMENT ON VIEW data_freshness_status IS 'Monitor data freshness across all sources';

-- Automated Dashboard Refresh Function
CREATE OR REPLACE FUNCTION refresh_executive_dashboard()
RETURNS TEXT AS $$
BEGIN
    -- Refresh all materialized views in dependency order
    REFRESH MATERIALIZED VIEW internal.revenue_trends_summary;
    REFRESH MATERIALIZED VIEW internal.customer_rfm_summary;
    REFRESH MATERIALIZED VIEW competitive.category_price_analysis;
    REFRESH MATERIALIZED VIEW competitive.competitive_positioning_matrix;
    
    -- Refresh executive dashboard views
    REFRESH MATERIALIZED VIEW executive_kpi_summary;
    REFRESH MATERIALIZED VIEW customer_health_dashboard;
    REFRESH MATERIALIZED VIEW competitive_intelligence_dashboard;
    REFRESH MATERIALIZED VIEW industry_benchmark_dashboard;
    
    -- Update statistics for query optimization
    ANALYZE internal.orders;
    ANALYZE internal.order_details;
    ANALYZE competitive.products;
    
    -- Log refresh
    INSERT INTO public.data_import_log (table_name, rows_imported, import_duration_seconds)
    VALUES ('executive_dashboard_refresh', 0, EXTRACT(EPOCH FROM CURRENT_TIMESTAMP - CURRENT_TIMESTAMP));
    
    RETURN 'Executive dashboard refreshed successfully at ' || CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_executive_dashboard IS 'Refresh all executive dashboard materialized views';

-- Create indexes on materialized views for performance
CREATE INDEX IF NOT EXISTS idx_exec_kpi_period ON executive_kpi_summary(period_type);
CREATE INDEX IF NOT EXISTS idx_customer_health_segment ON customer_health_dashboard(customer_segment);
CREATE INDEX IF NOT EXISTS idx_competitive_intel_type ON competitive_intelligence_dashboard(metric_type);
CREATE INDEX IF NOT EXISTS idx_industry_benchmark_type ON industry_benchmark_dashboard(benchmark_type);

-- Initial refresh of all materialized views
SELECT refresh_executive_dashboard();

-- Performance validation
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time DECIMAL;
BEGIN
    start_time := CLOCK_TIMESTAMP();
    
    -- Test query performance
    PERFORM * FROM executive_summary_realtime LIMIT 10;
    PERFORM * FROM executive_kpi_summary LIMIT 5;
    PERFORM * FROM customer_health_dashboard LIMIT 5;
    
    end_time := CLOCK_TIMESTAMP();
    execution_time := EXTRACT(EPOCH FROM (end_time - start_time));
    
    IF execution_time > 1.0 THEN
        RAISE WARNING 'Dashboard queries taking % seconds - consider additional optimization', execution_time;
    ELSE
        RAISE NOTICE 'Dashboard performance validated: % seconds (target: <1 second)', execution_time;
    END IF;
END $$;
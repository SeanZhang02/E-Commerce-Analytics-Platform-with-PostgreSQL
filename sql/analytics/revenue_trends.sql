-- Revenue Trends Analysis (Clean Version)
-- Purpose: Monthly/quarterly revenue analysis with YoY comparisons and seasonality
-- Business Question: What are our revenue trends, growth rates, and seasonal patterns?

-- Use internal schema for Northwind transactional data
SET search_path TO internal;

-- Monthly Revenue Trends with Growth Analysis
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) as month,
        COUNT(DISTINCT o.order_id) as order_count,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        COUNT(DISTINCT od.product_id) as unique_products,
        SUM(od.quantity) as total_units_sold,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        SUM(o.freight) as total_freight
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', o.order_date)
),
revenue_with_growth AS (
    SELECT 
        month,
        order_count,
        unique_customers,
        unique_products,
        total_units_sold,
        revenue,
        avg_order_line_value,
        total_freight,
        ROUND(CAST(revenue / NULLIF(order_count, 0) AS NUMERIC), 2) as avg_order_value,
        LAG(revenue, 12) OVER (ORDER BY month) as revenue_year_ago,
        LAG(revenue, 1) OVER (ORDER BY month) as revenue_month_ago,
        LAG(revenue, 3) OVER (ORDER BY month) as revenue_quarter_ago,
        AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as revenue_3mo_avg,
        SUM(revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING) as cumulative_revenue,
        RANK() OVER (ORDER BY revenue DESC) as revenue_rank,
        PERCENT_RANK() OVER (ORDER BY revenue) as revenue_percentile
    FROM monthly_revenue
)
SELECT 
    month,
    TO_CHAR(month, 'Mon YYYY') as month_name,
    EXTRACT(QUARTER FROM month) as quarter,
    EXTRACT(YEAR FROM month) as year,
    order_count,
    unique_customers,
    unique_products,
    total_units_sold,
    ROUND(CAST(revenue AS NUMERIC), 2) as revenue,
    avg_order_value,
    ROUND(CAST(total_freight AS NUMERIC), 2) as total_freight,
    ROUND(CAST(((revenue - revenue_year_ago) / NULLIF(revenue_year_ago, 0)) * 100 AS NUMERIC), 2) as yoy_growth_pct,
    ROUND(CAST(((revenue - revenue_month_ago) / NULLIF(revenue_month_ago, 0)) * 100 AS NUMERIC), 2) as mom_growth_pct,
    ROUND(CAST(((revenue - revenue_quarter_ago) / NULLIF(revenue_quarter_ago, 0)) * 100 AS NUMERIC), 2) as qoq_growth_pct,
    ROUND(CAST(revenue_3mo_avg AS NUMERIC), 2) as revenue_3mo_avg,
    ROUND(CAST(cumulative_revenue AS NUMERIC), 2) as cumulative_revenue,
    revenue_rank,
    ROUND(CAST(revenue_percentile * 100 AS NUMERIC), 1) as revenue_percentile_rank
FROM revenue_with_growth
ORDER BY month DESC;

-- Quarterly Revenue Analysis with Seasonality
WITH quarterly_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM o.order_date) as year,
        EXTRACT(QUARTER FROM o.order_date) as quarter,
        CONCAT('Q', EXTRACT(QUARTER FROM o.order_date), ' ', EXTRACT(YEAR FROM o.order_date)) as quarter_label,
        COUNT(DISTINCT o.order_id) as order_count,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_transaction_value
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM o.order_date), EXTRACT(QUARTER FROM o.order_date)
),
quarterly_growth AS (
    SELECT 
        *,
        LAG(revenue, 4) OVER (ORDER BY year, quarter) as revenue_year_ago,
        LAG(revenue, 1) OVER (ORDER BY year, quarter) as revenue_quarter_ago,
        AVG(revenue) OVER (PARTITION BY quarter ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as seasonal_avg
    FROM quarterly_revenue
)
SELECT 
    quarter_label,
    year,
    quarter,
    order_count,
    unique_customers,
    ROUND(CAST(revenue AS NUMERIC), 2) as revenue,
    ROUND(CAST(avg_transaction_value AS NUMERIC), 2) as avg_transaction_value,
    ROUND(CAST(((revenue - revenue_year_ago) / NULLIF(revenue_year_ago, 0)) * 100 AS NUMERIC), 2) as yoy_growth_pct,
    ROUND(CAST(((revenue - revenue_quarter_ago) / NULLIF(revenue_quarter_ago, 0)) * 100 AS NUMERIC), 2) as qoq_growth_pct,
    ROUND(CAST(seasonal_avg AS NUMERIC), 2) as seasonal_avg,
    ROUND(CAST(ABS(revenue - seasonal_avg) / NULLIF(seasonal_avg, 0) * 100 AS NUMERIC), 2) as seasonal_variance_pct,
    CASE quarter
        WHEN 1 THEN 'Q1-Winter'
        WHEN 2 THEN 'Q2-Spring'
        WHEN 3 THEN 'Q3-Summer'
        WHEN 4 THEN 'Q4-Holiday'
    END as season_name
FROM quarterly_growth
ORDER BY year DESC, quarter DESC;

-- Daily Revenue Patterns (Top 20 Days)
WITH daily_revenue AS (
    SELECT 
        o.order_date,
        TO_CHAR(o.order_date, 'Day') as day_name,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_line_value
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date IS NOT NULL
    GROUP BY o.order_date
),
daily_with_trends AS (
    SELECT 
        *,
        AVG(revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as weekly_moving_avg,
        LAG(revenue, 7) OVER (ORDER BY order_date) as revenue_week_ago,
        RANK() OVER (ORDER BY revenue DESC) as daily_rank
    FROM daily_revenue
)
SELECT 
    order_date,
    TRIM(day_name) as day_name,
    order_count,
    ROUND(CAST(revenue AS NUMERIC), 2) as revenue,
    ROUND(CAST(avg_line_value AS NUMERIC), 2) as avg_line_value,
    ROUND(CAST(weekly_moving_avg AS NUMERIC), 2) as weekly_moving_avg,
    ROUND(CAST(((revenue - revenue_week_ago) / NULLIF(revenue_week_ago, 0)) * 100 AS NUMERIC), 2) as wow_growth_pct,
    daily_rank,
    CASE 
        WHEN TRIM(day_name) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type
FROM daily_with_trends
WHERE revenue > 0
ORDER BY revenue DESC
LIMIT 20;

-- Revenue Summary (Simple version without materialized view)
\echo 'Revenue Summary Dashboard:'
SELECT 
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as total_customers,
    COUNT(DISTINCT od.product_id) as total_products,
    ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount)) AS NUMERIC), 2) as total_revenue,
    ROUND(CAST(AVG(od.unit_price * od.quantity * (1 - od.discount)) AS NUMERIC), 2) as avg_transaction_value,
    ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount)) / NULLIF(COUNT(DISTINCT o.order_id), 0) AS NUMERIC), 2) as avg_order_value,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
WHERE o.order_date IS NOT NULL;

\echo 'Revenue trends analysis completed successfully!'
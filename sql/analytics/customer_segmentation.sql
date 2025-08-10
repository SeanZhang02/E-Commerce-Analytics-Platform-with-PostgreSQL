-- Customer Segmentation & RFM Analysis (Clean Version)
-- Purpose: Segment customers using RFM methodology and calculate lifetime value
-- Business Question: Who are our most valuable customers and how should we target them?

-- Use internal schema for Northwind transactional data
SET search_path TO internal;

-- Simple Customer RFM Analysis (without complex date arithmetic)
\echo 'Customer RFM Analysis:'
WITH customer_base AS (
    SELECT 
        o.customer_id,
        c.company_name,
        c.country,
        c.city,
        COUNT(DISTINCT o.order_id) as frequency,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as monetary,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        COUNT(DISTINCT od.product_id) as unique_products_purchased,
        SUM(od.quantity) as total_units_purchased
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_date IS NOT NULL
    GROUP BY o.customer_id, c.company_name, c.country, c.city
),
rfm_scores AS (
    SELECT 
        customer_id,
        company_name,
        country,
        city,
        frequency,
        monetary,
        first_order_date,
        last_order_date,
        avg_order_line_value,
        unique_products_purchased,
        total_units_purchased,
        NTILE(4) OVER (ORDER BY last_order_date DESC) as recency_score,
        NTILE(4) OVER (ORDER BY frequency DESC) as frequency_score,
        NTILE(4) OVER (ORDER BY monetary DESC) as monetary_score
    FROM customer_base
),
segments AS (
    SELECT 
        *,
        CONCAT(recency_score, frequency_score, monetary_score) as rfm_segment,
        CASE 
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Champions'
            WHEN recency_score >= 2 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'Loyal Customers'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score >= 2 THEN 'Potential Loyalists'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'New Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 1 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Cant Lose Them'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 2 THEN 'Hibernating'
            ELSE 'Lost Customers'
        END as customer_segment,
        ROUND(CAST(monetary / NULLIF(frequency, 0) AS NUMERIC), 2) as avg_order_value
    FROM rfm_scores
)
SELECT 
    customer_id,
    company_name,
    country,
    city,
    frequency,
    ROUND(CAST(monetary AS NUMERIC), 2) as monetary,
    recency_score,
    frequency_score,
    monetary_score,
    rfm_segment,
    customer_segment,
    first_order_date,
    last_order_date,
    avg_order_value,
    unique_products_purchased,
    total_units_purchased,
    ROUND(CAST(PERCENT_RANK() OVER (ORDER BY monetary) * 100 AS NUMERIC), 1) as monetary_percentile,
    ROUND(CAST(PERCENT_RANK() OVER (ORDER BY frequency) * 100 AS NUMERIC), 1) as frequency_percentile
FROM segments
ORDER BY monetary DESC, frequency DESC;

-- Customer Segment Summary Analysis
\echo 'Customer Segment Summary:'
WITH customer_base AS (
    SELECT 
        o.customer_id,
        COUNT(DISTINCT o.order_id) as frequency,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as monetary
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date IS NOT NULL
    GROUP BY o.customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY frequency DESC) as frequency_score,
        NTILE(4) OVER (ORDER BY monetary DESC) as monetary_score
    FROM customer_base
),
segments AS (
    SELECT 
        customer_id,
        monetary,
        frequency,
        CASE 
            WHEN frequency_score >= 3 AND monetary_score >= 3 THEN 'Champions'
            WHEN frequency_score >= 2 AND monetary_score >= 2 THEN 'Loyal Customers'
            WHEN frequency_score <= 2 AND monetary_score >= 2 THEN 'Potential Loyalists'
            WHEN frequency_score >= 3 AND monetary_score <= 2 THEN 'At Risk'
            ELSE 'Others'
        END as customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(CAST(SUM(monetary) AS NUMERIC), 2) as total_segment_value,
    ROUND(CAST(AVG(monetary) AS NUMERIC), 2) as avg_customer_value,
    ROUND(CAST(AVG(frequency) AS NUMERIC), 1) as avg_order_frequency,
    ROUND(CAST(MIN(monetary) AS NUMERIC), 2) as min_customer_value,
    ROUND(CAST(MAX(monetary) AS NUMERIC), 2) as max_customer_value,
    ROUND(CAST(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER () AS NUMERIC), 1) as revenue_percentage,
    CASE customer_segment
        WHEN 'Champions' THEN 'Reward with loyalty programs and early access'
        WHEN 'Loyal Customers' THEN 'Upsell premium products and increase frequency'
        WHEN 'Potential Loyalists' THEN 'Create engagement campaigns to increase frequency'
        WHEN 'At Risk' THEN 'Win-back campaigns with targeted offers'
        ELSE 'Standard marketing campaigns'
    END as recommended_action
FROM segments
GROUP BY customer_segment
ORDER BY total_segment_value DESC;

-- Geographic Customer Analysis
\echo 'Geographic Customer Distribution:'
SELECT 
    country,
    city,
    COUNT(DISTINCT o.customer_id) as customer_count,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount)) AS NUMERIC), 2) as total_revenue,
    ROUND(CAST(AVG(od.unit_price * od.quantity * (1 - od.discount)) AS NUMERIC), 2) as avg_order_line_value,
    ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount)) / NULLIF(COUNT(DISTINCT o.customer_id), 0) AS NUMERIC), 2) as revenue_per_customer,
    ROUND(CAST(COUNT(DISTINCT o.customer_id) * 100.0 / SUM(COUNT(DISTINCT o.customer_id)) OVER () AS NUMERIC), 2) as customer_concentration_pct,
    RANK() OVER (ORDER BY SUM(od.unit_price * od.quantity * (1 - od.discount)) DESC) as revenue_rank,
    CASE 
        WHEN COUNT(DISTINCT o.customer_id) >= 3 THEN 'High Concentration'
        WHEN COUNT(DISTINCT o.customer_id) = 2 THEN 'Medium Concentration'
        ELSE 'Low Concentration'
    END as market_concentration
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date IS NOT NULL
GROUP BY country, city
ORDER BY total_revenue DESC;

-- Customer Health Summary (Simple version)
\echo 'Customer Health Summary:'
SELECT 
    COUNT(DISTINCT o.customer_id) as total_customers,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount)) AS NUMERIC), 2) as total_revenue,
    ROUND(CAST(AVG(od.unit_price * od.quantity * (1 - od.discount)) AS NUMERIC), 2) as avg_transaction_value,
    ROUND(CAST(COUNT(DISTINCT o.order_id) / NULLIF(COUNT(DISTINCT o.customer_id), 0) AS NUMERIC), 2) as avg_orders_per_customer,
    ROUND(CAST(SUM(od.unit_price * od.quantity * (1 - od.discount)) / NULLIF(COUNT(DISTINCT o.customer_id), 0) AS NUMERIC), 2) as avg_revenue_per_customer
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
WHERE o.order_date IS NOT NULL;

\echo 'Customer segmentation analysis completed successfully!'
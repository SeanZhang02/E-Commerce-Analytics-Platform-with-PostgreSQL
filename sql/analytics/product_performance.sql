-- Product Performance Analytics
-- Purpose: Category and margin analysis, product ranking, and inventory insights
-- Business Question: Which products and categories are driving the most value?
-- Data Source: internal.products, order_details, categories

-- Use internal schema for Northwind transactional data
SET search_path TO internal;

-- Product Revenue Performance Analysis
-- Business Question: Which products generate the most revenue and profit?
WITH product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.unit_price as current_unit_price,
        p.units_in_stock,
        p.units_on_order,
        p.reorder_level,
        p.discontinued,
        -- Sales metrics
        COUNT(DISTINCT od.order_id) as order_count,
        SUM(od.quantity) as total_units_sold,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as total_revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        AVG(od.discount) as avg_discount_applied,
        -- Price analysis
        MIN(od.unit_price) as min_selling_price,
        MAX(od.unit_price) as max_selling_price,
        AVG(od.unit_price) as avg_selling_price,
        -- Time analysis
        MIN(o.order_date) as first_sale_date,
        MAX(o.order_date) as last_sale_date,
        DATE_PART('day', MAX(o.order_date) - MIN(o.order_date)) as active_selling_days
    FROM products p
    LEFT JOIN order_details od ON p.product_id = od.product_id
    LEFT JOIN orders o ON od.order_id = o.order_id
    LEFT JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.unit_price, 
             p.units_in_stock, p.units_on_order, p.reorder_level, p.discontinued
),
product_metrics AS (
    SELECT 
        *,
        -- Performance calculations
        ROUND(total_revenue / NULLIF(total_units_sold, 0), 2) as revenue_per_unit,
        ROUND(total_revenue / NULLIF(active_selling_days, 0), 2) as daily_avg_revenue,
        ROUND(total_units_sold / NULLIF(active_selling_days, 0), 2) as daily_avg_units,
        -- Inventory metrics
        CASE 
            WHEN units_in_stock = 0 THEN 'Out of Stock'
            WHEN units_in_stock <= reorder_level THEN 'Low Stock'
            WHEN units_in_stock > reorder_level * 3 THEN 'Overstocked'
            ELSE 'Normal'
        END as stock_status,
        -- Performance ranking
        RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
        RANK() OVER (ORDER BY total_units_sold DESC) as units_sold_rank,
        RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) as category_revenue_rank
    FROM product_performance
    WHERE total_revenue IS NOT NULL
)
SELECT 
    product_id,
    product_name,
    category_name,
    ROUND(current_unit_price, 2) as current_unit_price,
    units_in_stock,
    stock_status,
    order_count,
    total_units_sold,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_order_line_value, 2) as avg_order_line_value,
    ROUND(avg_discount_applied * 100, 1) as avg_discount_pct,
    ROUND(revenue_per_unit, 2) as revenue_per_unit,
    ROUND(daily_avg_revenue, 2) as daily_avg_revenue,
    revenue_rank,
    category_revenue_rank,
    first_sale_date,
    last_sale_date,
    -- Performance indicators
    CASE 
        WHEN total_revenue >= PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Top Performer'
        WHEN total_revenue >= PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Good Performer'
        WHEN total_revenue >= PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Average Performer'
        WHEN total_revenue >= PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Below Average'
        ELSE 'Poor Performer'
    END as performance_tier,
    -- Business recommendations
    CASE 
        WHEN discontinued = TRUE THEN 'Product Discontinued'
        WHEN stock_status = 'Out of Stock' AND revenue_rank <= 20 THEN 'URGENT: Restock Top Performer'
        WHEN stock_status = 'Low Stock' AND revenue_rank <= 50 THEN 'Monitor: Popular Item Low Stock'
        WHEN stock_status = 'Overstocked' AND revenue_rank > 100 THEN 'Consider: Discount to Clear Inventory'
        WHEN daily_avg_revenue < 1 AND units_in_stock > 50 THEN 'Review: Slow Moving Inventory'
        ELSE 'Continue Monitoring'
    END as recommendation
FROM product_metrics
ORDER BY total_revenue DESC;

-- Category Performance Analysis
-- Business Question: Which categories are most profitable and growing?
WITH category_performance AS (
    SELECT 
        c.category_id,
        c.category_name,
        c.description as category_description,
        COUNT(DISTINCT p.product_id) as product_count,
        COUNT(DISTINCT CASE WHEN NOT p.discontinued THEN p.product_id END) as active_product_count,
        COUNT(DISTINCT od.order_id) as order_count,
        SUM(od.quantity) as total_units_sold,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as total_revenue,
        AVG(od.unit_price * od.quantity * (1 - od.discount)) as avg_order_line_value,
        AVG(p.unit_price) as avg_product_price,
        AVG(od.discount) as avg_discount_rate,
        -- Inventory metrics
        SUM(p.units_in_stock) as total_stock_units,
        SUM(p.units_on_order) as total_units_on_order,
        AVG(p.units_in_stock) as avg_stock_per_product
    FROM categories c
    LEFT JOIN products p ON c.category_id = p.category_id
    LEFT JOIN order_details od ON p.product_id = od.product_id
    LEFT JOIN orders o ON od.order_id = o.order_id
    GROUP BY c.category_id, c.category_name, c.description
),
category_trends AS (
    SELECT 
        c.category_name,
        EXTRACT(YEAR FROM o.order_date) as year,
        EXTRACT(QUARTER FROM o.order_date) as quarter,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as quarterly_revenue,
        COUNT(DISTINCT od.order_id) as quarterly_orders
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    JOIN orders o ON od.order_id = o.order_id
    WHERE o.order_date IS NOT NULL
    GROUP BY c.category_name, EXTRACT(YEAR FROM o.order_date), EXTRACT(QUARTER FROM o.order_date)
),
category_growth AS (
    SELECT 
        category_name,
        AVG(quarterly_revenue) as avg_quarterly_revenue,
        STDDEV(quarterly_revenue) as revenue_volatility,
        -- Calculate growth trend (simple linear approximation)
        CORR(
            EXTRACT(YEAR FROM make_date(year::INTEGER, quarter::INTEGER * 3, 1)),
            quarterly_revenue
        ) as growth_correlation
    FROM category_trends
    GROUP BY category_name
)
SELECT 
    cp.category_name,
    cp.category_description,
    cp.product_count,
    cp.active_product_count,
    cp.order_count,
    cp.total_units_sold,
    ROUND(cp.total_revenue, 2) as total_revenue,
    ROUND(cp.avg_order_line_value, 2) as avg_order_line_value,
    ROUND(cp.avg_product_price, 2) as avg_product_price,
    ROUND(cp.avg_discount_rate * 100, 1) as avg_discount_pct,
    cp.total_stock_units,
    ROUND(cp.avg_stock_per_product, 0) as avg_stock_per_product,
    -- Market share and performance metrics
    ROUND(cp.total_revenue * 100.0 / SUM(cp.total_revenue) OVER (), 2) as revenue_market_share_pct,
    ROUND(cp.order_count * 100.0 / SUM(cp.order_count) OVER (), 2) as order_market_share_pct,
    ROUND(cp.total_revenue / NULLIF(cp.product_count, 0), 2) as revenue_per_product,
    RANK() OVER (ORDER BY cp.total_revenue DESC) as revenue_rank,
    -- Growth and volatility metrics
    ROUND(cg.avg_quarterly_revenue, 2) as avg_quarterly_revenue,
    ROUND(cg.revenue_volatility, 2) as revenue_volatility,
    ROUND(cg.growth_correlation, 3) as growth_trend_score,
    -- Category health assessment
    CASE 
        WHEN cg.growth_correlation > 0.5 THEN 'Growing'
        WHEN cg.growth_correlation > -0.2 THEN 'Stable'
        ELSE 'Declining'
    END as growth_trend,
    CASE 
        WHEN cp.total_revenue >= PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY cp.total_revenue) OVER ()
             AND cg.growth_correlation > 0 THEN 'Star Category'
        WHEN cp.total_revenue >= PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY cp.total_revenue) OVER ()
             AND cg.growth_correlation <= 0 THEN 'Cash Cow'
        WHEN cp.total_revenue < PERCENTILE_CONT(0.3) WITHIN GROUP (ORDER BY cp.total_revenue) OVER ()
             AND cg.growth_correlation > 0 THEN 'Question Mark'
        ELSE 'Dog'
    END as bcg_matrix_position
FROM category_performance cp
LEFT JOIN category_growth cg ON cp.category_name = cg.category_name
WHERE cp.total_revenue IS NOT NULL
ORDER BY cp.total_revenue DESC;

-- Product Margin Analysis
-- Business Question: Which products have the best profit margins?
WITH product_margins AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.unit_price as list_price,
        AVG(od.unit_price) as avg_selling_price,
        AVG(od.discount) as avg_discount,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) as total_revenue,
        SUM(od.quantity) as total_units_sold,
        -- Margin calculations (assuming cost is 60% of list price)
        p.unit_price * 0.6 as estimated_cost,
        AVG(od.unit_price) - (p.unit_price * 0.6) as estimated_margin_per_unit,
        ((AVG(od.unit_price) - (p.unit_price * 0.6)) / NULLIF(AVG(od.unit_price), 0)) * 100 as estimated_margin_pct
    FROM products p
    JOIN order_details od ON p.product_id = od.product_id
    LEFT JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.unit_price
    HAVING SUM(od.quantity) > 0
)
SELECT 
    product_id,
    product_name,
    category_name,
    ROUND(list_price, 2) as list_price,
    ROUND(avg_selling_price, 2) as avg_selling_price,
    ROUND(avg_discount * 100, 1) as avg_discount_pct,
    total_units_sold,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(estimated_cost, 2) as estimated_cost,
    ROUND(estimated_margin_per_unit, 2) as estimated_margin_per_unit,
    ROUND(estimated_margin_pct, 1) as estimated_margin_pct,
    ROUND(estimated_margin_per_unit * total_units_sold, 2) as total_estimated_profit,
    -- Performance indicators
    CASE 
        WHEN estimated_margin_pct >= 50 THEN 'High Margin'
        WHEN estimated_margin_pct >= 30 THEN 'Good Margin'
        WHEN estimated_margin_pct >= 20 THEN 'Average Margin'
        WHEN estimated_margin_pct >= 10 THEN 'Low Margin'
        ELSE 'Very Low Margin'
    END as margin_category,
    RANK() OVER (ORDER BY estimated_margin_per_unit * total_units_sold DESC) as profit_rank,
    RANK() OVER (ORDER BY estimated_margin_pct DESC) as margin_rank
FROM product_margins
ORDER BY estimated_margin_per_unit * total_units_sold DESC;

-- Inventory Optimization Analysis
-- Business Question: How can we optimize our inventory levels?
WITH inventory_analysis AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.units_in_stock,
        p.units_on_order,
        p.reorder_level,
        p.discontinued,
        -- Sales velocity (last 90 days equivalent)
        COUNT(DISTINCT od.order_id) as recent_order_count,
        SUM(od.quantity) as recent_units_sold,
        COALESCE(
            SUM(od.quantity) / NULLIF(
                DATE_PART('day', MAX(o.order_date) - MIN(o.order_date)) + 1, 0
            ), 0
        ) as daily_sales_velocity,
        MAX(o.order_date) as last_sale_date,
        CURRENT_DATE - MAX(o.order_date) as days_since_last_sale
    FROM products p
    LEFT JOIN order_details od ON p.product_id = od.product_id
    LEFT JOIN orders o ON od.order_id = o.order_id
    LEFT JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.product_id, p.product_name, c.category_name, 
             p.units_in_stock, p.units_on_order, p.reorder_level, p.discontinued
)
SELECT 
    product_id,
    product_name,
    category_name,
    units_in_stock,
    units_on_order,
    reorder_level,
    recent_units_sold,
    ROUND(daily_sales_velocity, 2) as daily_sales_velocity,
    last_sale_date,
    days_since_last_sale,
    -- Inventory calculations
    CASE 
        WHEN daily_sales_velocity > 0 
        THEN ROUND(units_in_stock / NULLIF(daily_sales_velocity, 0), 0)
        ELSE NULL
    END as days_of_inventory,
    CASE 
        WHEN daily_sales_velocity > 0 
        THEN ROUND(reorder_level / NULLIF(daily_sales_velocity, 0), 0)
        ELSE NULL
    END as reorder_point_days,
    -- Status and recommendations
    CASE 
        WHEN discontinued THEN 'Discontinued'
        WHEN units_in_stock = 0 THEN 'Out of Stock'
        WHEN units_in_stock <= reorder_level THEN 'Reorder Needed'
        WHEN daily_sales_velocity = 0 AND units_in_stock > 20 THEN 'Dead Stock'
        WHEN days_since_last_sale > 90 THEN 'Slow Moving'
        WHEN units_in_stock > reorder_level * 5 AND daily_sales_velocity > 0 THEN 'Overstocked'
        ELSE 'Normal'
    END as inventory_status,
    CASE 
        WHEN discontinued THEN 'Clear remaining inventory'
        WHEN units_in_stock = 0 AND recent_units_sold > 0 THEN 'URGENT: Restock popular item'
        WHEN units_in_stock <= reorder_level THEN 'Place reorder soon'
        WHEN daily_sales_velocity = 0 AND units_in_stock > 20 THEN 'Consider clearance sale'
        WHEN days_since_last_sale > 90 THEN 'Review product relevance'
        WHEN units_in_stock > reorder_level * 5 THEN 'Reduce future orders'
        ELSE 'Monitor normal operations'
    END as recommendation
FROM inventory_analysis
ORDER BY 
    CASE 
        WHEN units_in_stock = 0 AND recent_units_sold > 0 THEN 1
        WHEN units_in_stock <= reorder_level AND NOT discontinued THEN 2
        WHEN daily_sales_velocity = 0 AND units_in_stock > 20 THEN 3
        ELSE 4
    END,
    recent_units_sold DESC;

-- Create materialized view for product dashboard
CREATE MATERIALIZED VIEW IF NOT EXISTS product_performance_summary AS
WITH product_summary AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.unit_price,
        p.units_in_stock,
        p.discontinued,
        COALESCE(SUM(od.unit_price * od.quantity * (1 - od.discount)), 0) as total_revenue,
        COALESCE(SUM(od.quantity), 0) as total_units_sold,
        COUNT(DISTINCT od.order_id) as order_count,
        RANK() OVER (ORDER BY COALESCE(SUM(od.unit_price * od.quantity * (1 - od.discount)), 0) DESC) as revenue_rank
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN order_details od ON p.product_id = od.product_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.unit_price, p.units_in_stock, p.discontinued
)
SELECT 
    product_id,
    product_name,
    category_name,
    ROUND(unit_price, 2) as unit_price,
    units_in_stock,
    discontinued,
    ROUND(total_revenue, 2) as total_revenue,
    total_units_sold,
    order_count,
    revenue_rank,
    CASE 
        WHEN total_revenue >= PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Top 20%'
        WHEN total_revenue >= PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Top 40%'
        WHEN total_revenue >= PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Middle 40%'
        WHEN total_revenue >= PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY total_revenue) OVER () THEN 'Bottom 40%'
        ELSE 'Bottom 20%'
    END as performance_quintile
FROM product_summary;

COMMENT ON MATERIALIZED VIEW product_performance_summary IS 'Product performance metrics for dashboard';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW product_performance_summary;
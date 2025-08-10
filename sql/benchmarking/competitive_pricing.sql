-- Competitive Pricing Analysis (Fixed)
-- Purpose: Compare internal pricing vs Amazon market prices by category
-- Business Question: How do our prices compare to Amazon and where are opportunities?
-- Data Sources: internal.products (Northwind) vs competitive.products (Amazon)

-- Cross-schema analysis combining internal and competitive data
SET search_path TO internal, competitive, industry;

-- Amazon Price Analysis by Category
-- Business Question: What's the pricing landscape on Amazon by category?
\echo 'Amazon Market Analysis by Category:'
WITH amazon_pricing AS (
    SELECT 
        SPLIT_PART(category_hierarchy, '|', 1) as main_category,
        COUNT(*) as product_count,
        AVG(price_inr) as avg_price_inr,
        AVG(price_usd) as avg_price_usd,
        MIN(price_usd) as min_price_usd,
        MAX(price_usd) as max_price_usd,
        STDDEV(price_usd) as price_stddev_usd,
        AVG(discount_percentage) as avg_discount_pct,
        AVG(rating) as avg_rating,
        SUM(rating_count) as total_reviews
    FROM competitive.products
    WHERE price_usd IS NOT NULL AND category_hierarchy IS NOT NULL
    GROUP BY SPLIT_PART(category_hierarchy, '|', 1)
)
SELECT 
    main_category,
    product_count,
    ROUND(avg_price_usd, 2) as avg_price_usd,
    ROUND(min_price_usd, 2) as min_price_usd,
    ROUND(max_price_usd, 2) as max_price_usd,
    ROUND(price_stddev_usd, 2) as price_stddev_usd,
    ROUND(avg_discount_pct, 1) as avg_discount_pct,
    ROUND(avg_rating, 2) as avg_rating,
    total_reviews,
    -- Price competitiveness index
    CASE 
        WHEN avg_discount_pct >= 50 THEN 'Highly Competitive'
        WHEN avg_discount_pct >= 30 THEN 'Competitive'
        WHEN avg_discount_pct >= 15 THEN 'Moderately Competitive'
        ELSE 'Premium Pricing'
    END as competitiveness_level,
    -- Quality indicator
    CASE 
        WHEN avg_rating >= 4.5 THEN 'Excellent'
        WHEN avg_rating >= 4.0 THEN 'Very Good'
        WHEN avg_rating >= 3.5 THEN 'Good'
        WHEN avg_rating >= 3.0 THEN 'Average'
        ELSE 'Below Average'
    END as quality_level
FROM amazon_pricing
ORDER BY product_count DESC;

-- Internal vs Amazon Price Comparison
\echo 'Internal vs Amazon Price Comparison:'
\echo 'Note: Different business domains - Northwind (food/retail) vs Amazon (electronics/tech)'
WITH internal_summary AS (
    SELECT 
        c.category_name,
        COUNT(*) as internal_product_count,
        AVG(p.unit_price) as avg_internal_price,
        MIN(p.unit_price) as min_internal_price,
        MAX(p.unit_price) as max_internal_price
    FROM internal.products p
    JOIN internal.categories c ON p.category_id = c.category_id
    WHERE NOT p.discontinued
    GROUP BY c.category_name
),
amazon_categories AS (
    SELECT 
        'Electronics' as category_name,
        AVG(price_usd) as avg_amazon_price,
        COUNT(*) as amazon_product_count
    FROM competitive.products 
    WHERE category_hierarchy LIKE 'Electronics%'
    
    UNION ALL
    
    SELECT 
        'Computers&Accessories',
        AVG(price_usd),
        COUNT(*)
    FROM competitive.products 
    WHERE category_hierarchy LIKE 'Computers&Accessories%'
    
    UNION ALL
    
    SELECT 
        'Home&Kitchen',
        AVG(price_usd),
        COUNT(*)
    FROM competitive.products 
    WHERE category_hierarchy LIKE 'Home&Kitchen%'
)
SELECT 
    COALESCE(i.category_name, a.category_name) as category,
    COALESCE(i.internal_product_count, 0) as internal_products,
    COALESCE(a.amazon_product_count, 0) as amazon_products,
    ROUND(COALESCE(i.avg_internal_price, 0), 2) as avg_internal_price,
    ROUND(COALESCE(a.avg_amazon_price, 0), 2) as avg_amazon_price,
    CASE 
        WHEN i.avg_internal_price IS NULL THEN 'No Internal Products'
        WHEN a.avg_amazon_price IS NULL THEN 'No Amazon Comparison'
        WHEN i.avg_internal_price < a.avg_amazon_price * 0.8 THEN 'Significantly Below Market'
        WHEN i.avg_internal_price < a.avg_amazon_price * 1.2 THEN 'Competitive'
        ELSE 'Above Market'
    END as price_positioning,
    CASE 
        WHEN i.avg_internal_price IS NOT NULL AND a.avg_amazon_price IS NOT NULL 
        THEN ROUND(((i.avg_internal_price - a.avg_amazon_price) / a.avg_amazon_price) * 100, 1)
        ELSE NULL
    END as price_difference_pct
FROM internal_summary i
FULL OUTER JOIN amazon_categories a ON i.category_name = a.category_name
ORDER BY internal_products DESC, amazon_products DESC;

-- Overall Market Positioning Summary
\echo 'Overall Market Positioning Summary:'
SELECT 
    'Internal Portfolio' as source,
    COUNT(*) as product_count,
    ROUND(AVG(unit_price), 2) as avg_price_usd,
    ROUND(MIN(unit_price), 2) as min_price,
    ROUND(MAX(unit_price), 2) as max_price,
    NULL as avg_rating,
    'Internal Data' as data_source
FROM internal.products
WHERE NOT discontinued

UNION ALL

SELECT 
    'Amazon Market',
    COUNT(*),
    ROUND(AVG(price_usd), 2),
    ROUND(MIN(price_usd), 2),
    ROUND(MAX(price_usd), 2),
    ROUND(AVG(rating), 2),
    'Competitive Intelligence'
FROM competitive.products
WHERE price_usd > 0;

-- Price Gap Analysis - Opportunities
\echo 'Price Gap Analysis - Market Opportunities:'
WITH price_segments AS (
    SELECT 
        CASE 
            WHEN price_usd <= 10 THEN 'Budget ($0-10)'
            WHEN price_usd <= 25 THEN 'Low ($10-25)'
            WHEN price_usd <= 50 THEN 'Mid ($25-50)'
            WHEN price_usd <= 100 THEN 'High ($50-100)'
            ELSE 'Premium ($100+)'
        END as price_segment,
        COUNT(*) as amazon_products,
        AVG(rating) as avg_rating,
        AVG(rating_count) as avg_review_volume
    FROM competitive.products
    WHERE price_usd > 0
    GROUP BY 
        CASE 
            WHEN price_usd <= 10 THEN 'Budget ($0-10)'
            WHEN price_usd <= 25 THEN 'Low ($10-25)'
            WHEN price_usd <= 50 THEN 'Mid ($25-50)'
            WHEN price_usd <= 100 THEN 'High ($50-100)'
            ELSE 'Premium ($100+)'
        END
),
internal_segments AS (
    SELECT 
        CASE 
            WHEN unit_price <= 10 THEN 'Budget ($0-10)'
            WHEN unit_price <= 25 THEN 'Low ($10-25)'
            WHEN unit_price <= 50 THEN 'Mid ($25-50)'
            WHEN unit_price <= 100 THEN 'High ($50-100)'
            ELSE 'Premium ($100+)'
        END as price_segment,
        COUNT(*) as internal_products
    FROM internal.products
    WHERE NOT discontinued
    GROUP BY 
        CASE 
            WHEN unit_price <= 10 THEN 'Budget ($0-10)'
            WHEN unit_price <= 25 THEN 'Low ($10-25)'
            WHEN unit_price <= 50 THEN 'Mid ($25-50)'
            WHEN unit_price <= 100 THEN 'High ($50-100)'
            ELSE 'Premium ($100+)'
        END
)
SELECT 
    COALESCE(a.price_segment, i.price_segment) as price_segment,
    COALESCE(i.internal_products, 0) as internal_products,
    COALESCE(a.amazon_products, 0) as amazon_products,
    ROUND(COALESCE(a.avg_rating, 0), 2) as market_avg_rating,
    ROUND(COALESCE(a.avg_review_volume, 0), 0) as market_review_volume,
    CASE 
        WHEN i.internal_products IS NULL AND a.amazon_products > 50 THEN 'High Opportunity'
        WHEN i.internal_products < a.amazon_products * 0.1 AND a.amazon_products > 20 THEN 'Growth Opportunity'
        WHEN i.internal_products > 0 AND a.amazon_products > 0 THEN 'Competitive Segment'
        WHEN a.amazon_products = 0 THEN 'Niche Segment'
        ELSE 'Monitor Segment'
    END as opportunity_level
FROM price_segments a
FULL OUTER JOIN internal_segments i ON a.price_segment = i.price_segment
ORDER BY 
    CASE a.price_segment
        WHEN 'Budget ($0-10)' THEN 1
        WHEN 'Low ($10-25)' THEN 2  
        WHEN 'Mid ($25-50)' THEN 3
        WHEN 'High ($50-100)' THEN 4
        WHEN 'Premium ($100+)' THEN 5
        ELSE 6
    END;

-- Strategic Recommendations
\echo 'Strategic Pricing Recommendations:'
WITH market_analysis AS (
    SELECT 
        AVG(price_usd) as market_avg_price,
        AVG(rating) as market_avg_rating,
        COUNT(*) as total_market_products
    FROM competitive.products
    WHERE price_usd > 0
),
internal_analysis AS (
    SELECT 
        AVG(unit_price) as internal_avg_price,
        COUNT(*) as total_internal_products
    FROM internal.products
    WHERE NOT discontinued
)
SELECT 
    'Market Intelligence Summary' as analysis_type,
    ROUND(m.market_avg_price, 2) as market_avg_price_usd,
    ROUND(m.market_avg_rating, 2) as market_avg_rating,
    m.total_market_products,
    ROUND(i.internal_avg_price, 2) as internal_avg_price_usd,
    i.total_internal_products,
    ROUND(((i.internal_avg_price - m.market_avg_price) / m.market_avg_price) * 100, 1) as price_gap_pct,
    CASE 
        WHEN i.internal_avg_price < m.market_avg_price * 0.7 THEN 'Consider Premium Product Line'
        WHEN i.internal_avg_price < m.market_avg_price * 0.9 THEN 'Opportunity for Selective Price Increases'
        WHEN i.internal_avg_price > m.market_avg_price * 1.2 THEN 'Review High Pricing Strategy'
        ELSE 'Pricing Aligned with Market'
    END as strategic_recommendation
FROM market_analysis m
CROSS JOIN internal_analysis i;

\echo 'Competitive pricing analysis completed!'
\echo 'Key insights: Price positioning, market gaps, and strategic opportunities identified.'
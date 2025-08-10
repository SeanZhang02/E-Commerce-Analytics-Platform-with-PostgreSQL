-- Process Amazon Data - Clean and Insert
-- Run this after importing CSV into staging table

SET search_path TO competitive;

-- Function to safely extract numbers from text
CREATE OR REPLACE FUNCTION extract_number(input_text TEXT) 
RETURNS DECIMAL AS $$
BEGIN
    IF input_text IS NULL OR input_text = '' OR input_text = '|' THEN
        RETURN NULL;
    END IF;
    
    -- Extract only digits and decimal points
    DECLARE
        cleaned_text TEXT;
    BEGIN
        cleaned_text := regexp_replace(input_text, '[^0-9.]', '', 'g');
        IF cleaned_text = '' THEN
            RETURN NULL;
        END IF;
        RETURN CAST(cleaned_text AS DECIMAL);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$ LANGUAGE plpgsql;

-- Clean and insert products (handle duplicates)
INSERT INTO products (
    product_id,
    product_name,
    category_hierarchy,
    price_inr,
    price_usd,
    original_price_inr,
    original_price_usd,
    discount_percentage,
    rating,
    rating_count,
    description,
    img_link,
    product_link
)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    CAST(regexp_replace(COALESCE(discounted_price, '0'), '[^0-9]', '', 'g') AS DECIMAL(10,2)) as price_inr,
    ROUND(CAST(regexp_replace(COALESCE(discounted_price, '0'), '[^0-9]', '', 'g') AS DECIMAL(10,2)) / 83, 2) as price_usd,
    CAST(regexp_replace(COALESCE(actual_price, '0'), '[^0-9]', '', 'g') AS DECIMAL(10,2)) as original_price_inr,
    ROUND(CAST(regexp_replace(COALESCE(actual_price, '0'), '[^0-9]', '', 'g') AS DECIMAL(10,2)) / 83, 2) as original_price_usd,
    CASE WHEN discount_percentage ~ '[0-9]' THEN CAST(regexp_replace(discount_percentage, '[^0-9]', '', 'g') AS INTEGER) ELSE NULL END as discount_percentage,
    CASE 
        WHEN rating IS NOT NULL AND rating != '|' AND rating ~ '^[0-5]' 
        THEN CAST(rating AS DECIMAL(3,2))
        ELSE NULL 
    END as rating,
    CASE WHEN rating_count ~ '[0-9]' THEN CAST(regexp_replace(rating_count, '[^0-9]', '', 'g') AS INTEGER) ELSE NULL END as rating_count,
    about_product,
    img_link,
    product_link
FROM amazon_staging
WHERE product_id IS NOT NULL 
  AND product_id != ''
  AND product_name IS NOT NULL 
  AND product_name != ''
ON CONFLICT (product_id) DO NOTHING;

-- Insert reviews (simplified - one review per product for now)
INSERT INTO reviews (
    review_id,
    product_id,
    user_id,
    user_name,
    review_title,
    review_text
)
SELECT 
    product_id || '_review_1' as review_id,
    product_id,
    SPLIT_PART(COALESCE(user_id, ''), ',', 1) as user_id,
    SPLIT_PART(COALESCE(user_name, ''), ',', 1) as user_name,
    SPLIT_PART(COALESCE(review_title, ''), ',', 1) as review_title,
    SPLIT_PART(COALESCE(review_content, ''), ',', 1) as review_text
FROM amazon_staging
WHERE product_id IS NOT NULL 
  AND product_id != ''
  AND COALESCE(review_id, '') != ''
  AND COALESCE(review_id, '') != '|'
ON CONFLICT (review_id) DO NOTHING;

-- Validation and summary
\echo 'Import Summary:'
SELECT 
    'Products' as table_name,
    COUNT(*) as records,
    COUNT(CASE WHEN price_usd IS NOT NULL THEN 1 END) as with_price,
    COUNT(CASE WHEN rating IS NOT NULL THEN 1 END) as with_rating
FROM products
UNION ALL
SELECT 
    'Reviews',
    COUNT(*),
    COUNT(CASE WHEN review_text IS NOT NULL THEN 1 END),
    0
FROM reviews;

\echo 'Sample products:'
SELECT 
    product_id,
    LEFT(product_name, 40) as name,
    price_inr,
    price_usd,
    rating,
    rating_count
FROM products 
WHERE price_usd IS NOT NULL
ORDER BY price_usd DESC
LIMIT 5;

-- Clean up
DROP FUNCTION IF EXISTS extract_number(TEXT);

\echo 'Amazon data import completed successfully!'
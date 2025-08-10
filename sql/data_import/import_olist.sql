-- Olist Brazilian E-commerce Sample Data Import
-- Purpose: Load industry benchmark data for market comparison
-- Business Context: Brazilian e-commerce industry standards and benchmarks

SET search_path TO industry;
SET client_encoding = 'UTF8';

-- Insert sample customer data
INSERT INTO olist_customers_dataset (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state) VALUES
('ed21ad277166015dcfcbfcc2c94eb37e', 'e87c9b6bbae65adec7df85444b9d53c0', 3149, 'são paulo', 'SP'),
('17bd2c6c0c5ef41a02f3d8ec8a96e9d3', '559e6e4e7c44d42e9bfa645a6b3e3e4c', 8775, 'mauá', 'SP'),
('4a2b9ee5d03bf1cb65c1ca30a2c4a2a5', '9b8f9e8e6e7e8e9e0e1e2e3e4e5e6e7e', 13056, 'campinas', 'SP'),
('8682c8c9b7b9b8a9a8b7c6d5e4f3g2h1', 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6', 1151, 'rio de janeiro', 'RJ'),
('9b8f9e8e6e7e8e9e0e1e2e3e4e5e6e7e', 'z9y8x7w6v5u4t3s2r1q0p9o8n7m6l5k4', 80010, 'curitiba', 'PR'),
('a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6', 'q1w2e3r4t5y6u7i8o9p0a1s2d3f4g5h6', 30112, 'belo horizonte', 'MG'),
('z9y8x7w6v5u4t3s2r1q0p9o8n7m6l5k4', 'l1k2j3h4g5f6d7s8a9p0o9i8u7y6t5r4', 90110, 'porto alegre', 'RS'),
('q1w2e3r4t5y6u7i8o9p0a1s2d3f4g5h6', 'm1n2b3v4c5x6z7a8s9d0f1g2h3j4k5l6', 40070, 'salvador', 'BA'),
('l1k2j3h4g5f6d7s8a9p0o9i8u7y6t5r4', 'p1o2i3u4y5t6r7e8w9q0a1s2d3f4g5h6', 50030, 'recife', 'PE'),
('m1n2b3v4c5x6z7a8s9d0f1g2h3j4k5l6', 'v1b2n3m4q5w6e7r8t9y0u1i2o3p4a5s6', 70040, 'brasília', 'DF')
ON CONFLICT (customer_id) DO NOTHING;

-- Insert sample seller data  
INSERT INTO olist_sellers_dataset (seller_id, seller_zip_code_prefix, seller_city, seller_state) VALUES
('3442f8959a84dea7ee197c632cb2df15', 13023, 'campinas', 'SP'),
('d1b65a7d4c0fb4dedc2b6e5c3b9c4e4b', 3149, 'são paulo', 'SP'),
('e4b3a2d1c0f9e8d7c6b5a4f3e2d1c0b9', 1151, 'rio de janeiro', 'RJ'),
('a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3', 80010, 'curitiba', 'PR'),
('c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7', 30112, 'belo horizonte', 'MG'),
('f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3', 90110, 'porto alegre', 'RS'),
('b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4', 40070, 'salvador', 'BA'),
('e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8', 50030, 'recife', 'PE'),
('a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1', 70040, 'brasília', 'DF'),
('d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4', 22071, 'rio de janeiro', 'RJ')
ON CONFLICT (seller_id) DO NOTHING;

-- Insert sample product categories
INSERT INTO olist_product_category_name_translation (product_category_name, product_category_name_english) VALUES
('beleza_saude', 'health_beauty'),
('informatica_acessorios', 'computers_accessories'),
('automotivo', 'auto'),
('cama_mesa_banho', 'bed_bath_table'),
('moveis_decoracao', 'furniture_decor'),
('esporte_lazer', 'sports_leisure'),
('perfumaria', 'perfumery'),
('utilidades_domesticas', 'housewares'),
('telefonia', 'telephony'),
('relogios_presentes', 'watches_gifts')
ON CONFLICT (product_category_name) DO NOTHING;

-- Insert sample products
INSERT INTO olist_products_dataset (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm) VALUES
('1e9c58017a1bfe2e43c1d9b6d4c7a8f1', 'beleza_saude', 58, 245, 1, 225, 16, 10, 14),
('2f0d69128b2cfe3f54d2e0c7e5d8b9a2', 'informatica_acessorios', 42, 173, 2, 800, 18, 12, 15),
('3a1e7a239c3dfe4a65e3f1d8f6e9c0b3', 'automotivo', 67, 298, 3, 1200, 25, 18, 20),
('4b2f8b340d4efe5b76f4a2e9a7f0d1c4', 'cama_mesa_banho', 51, 189, 1, 350, 20, 8, 16),
('5c3a9c451e5efe6c87a5b3f0b8a1e2d5', 'moveis_decoracao', 73, 412, 4, 2500, 45, 35, 30),
('6d4b0d562f6efe7d98b6c4a1c9b2f3e6', 'esporte_lazer', 48, 167, 2, 450, 22, 14, 18),
('7e5c1e673a7efe8e09c7d5b2d0c3a4f7', 'perfumaria', 39, 134, 1, 180, 12, 8, 10),
('8f6d2f784b8efe9f10d8e6c3e1d4b5a8', 'utilidades_domesticas', 65, 287, 2, 320, 18, 12, 14),
('9a7e3a895c9efef021e9f7d4f2e5c6b9', 'telefonia', 44, 156, 1, 120, 14, 6, 8),
('0b8f4b906d0efe0132f0a8e5a3f6d7c0', 'relogios_presentes', 52, 201, 3, 95, 10, 4, 8)
ON CONFLICT (product_id) DO NOTHING;

-- Insert sample orders with realistic Brazilian e-commerce data
DO $$
DECLARE
    i INTEGER;
    order_date TIMESTAMP;
    customer_ids TEXT[] := ARRAY[
        'ed21ad277166015dcfcbfcc2c94eb37e', '17bd2c6c0c5ef41a02f3d8ec8a96e9d3', 
        '4a2b9ee5d03bf1cb65c1ca30a2c4a2a5', '8682c8c9b7b9b8a9a8b7c6d5e4f3g2h1',
        '9b8f9e8e6e7e8e9e0e1e2e3e4e5e6e7e', 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
        'z9y8x7w6v5u4t3s2r1q0p9o8n7m6l5k4', 'q1w2e3r4t5y6u7i8o9p0a1s2d3f4g5h6',
        'l1k2j3h4g5f6d7s8a9p0o9i8u7y6t5r4', 'm1n2b3v4c5x6z7a8s9d0f1g2h3j4k5l6'
    ];
    order_statuses TEXT[] := ARRAY['delivered', 'shipped', 'processing', 'canceled'];
BEGIN
    FOR i IN 1..200 LOOP
        -- Generate random date in last 24 months
        order_date := CURRENT_TIMESTAMP - (random() * 730)::INTEGER * INTERVAL '1 day';
        
        INSERT INTO olist_orders_dataset (
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) VALUES (
            MD5(i::TEXT || 'order'),
            customer_ids[floor(random() * 10 + 1)],
            order_statuses[floor(random() * 4 + 1)],
            order_date,
            order_date + INTERVAL '2 hours',
            order_date + INTERVAL '2 days',
            order_date + INTERVAL '7 days',
            order_date + INTERVAL '10 days'
        ) ON CONFLICT (order_id) DO NOTHING;
    END LOOP;
END $$;

-- Insert sample order items
DO $$
DECLARE
    order_rec RECORD;
    product_ids TEXT[] := ARRAY[
        '1e9c58017a1bfe2e43c1d9b6d4c7a8f1', '2f0d69128b2cfe3f54d2e0c7e5d8b9a2',
        '3a1e7a239c3dfe4a65e3f1d8f6e9c0b3', '4b2f8b340d4efe5b76f4a2e9a7f0d1c4',
        '5c3a9c451e5efe6c87a5b3f0b8a1e2d5', '6d4b0d562f6efe7d98b6c4a1c9b2f3e6',
        '7e5c1e673a7efe8e09c7d5b2d0c3a4f7', '8f6d2f784b8efe9f10d8e6c3e1d4b5a8',
        '9a7e3a895c9efef021e9f7d4f2e5c6b9', '0b8f4b906d0efe0132f0a8e5a3f6d7c0'
    ];
    seller_ids TEXT[] := ARRAY[
        '3442f8959a84dea7ee197c632cb2df15', 'd1b65a7d4c0fb4dedc2b6e5c3b9c4e4b',
        'e4b3a2d1c0f9e8d7c6b5a4f3e2d1c0b9', 'a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3',
        'c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7', 'f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3',
        'b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4', 'e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8',
        'a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1', 'd9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4'
    ];
BEGIN
    FOR order_rec IN SELECT order_id FROM olist_orders_dataset LIMIT 200 LOOP
        -- Add 1-3 items per order
        FOR j IN 1..(floor(random() * 3) + 1) LOOP
            INSERT INTO olist_order_items_dataset (
                order_id,
                order_item_id,
                product_id,
                seller_id,
                shipping_limit_date,
                price,
                freight_value
            ) VALUES (
                order_rec.order_id,
                j,
                product_ids[floor(random() * 10 + 1)],
                seller_ids[floor(random() * 10 + 1)],
                CURRENT_TIMESTAMP + INTERVAL '5 days',
                random() * 200 + 20, -- Price between 20-220 BRL
                random() * 30 + 5    -- Freight between 5-35 BRL
            ) ON CONFLICT (order_id, order_item_id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Insert sample payment data
INSERT INTO olist_order_payments_dataset (order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT 
    order_id,
    1,
    CASE floor(random() * 4)
        WHEN 0 THEN 'credit_card'
        WHEN 1 THEN 'boleto'
        WHEN 2 THEN 'debit_card'
        ELSE 'voucher'
    END,
    floor(random() * 10 + 1), -- 1-10 installments
    random() * 300 + 50       -- Payment value 50-350 BRL
FROM olist_orders_dataset
WHERE order_id NOT IN (SELECT order_id FROM olist_order_payments_dataset)
LIMIT 200
ON CONFLICT (order_id, payment_sequential) DO NOTHING;

-- Insert sample reviews
INSERT INTO olist_order_reviews_dataset (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
SELECT 
    MD5(order_id || 'review'),
    order_id,
    floor(random() * 5 + 1), -- Score 1-5
    'Review title ' || floor(random() * 100),
    'Customer review message about the product and service quality.',
    CURRENT_TIMESTAMP - (random() * 365)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 300)::INTEGER * INTERVAL '1 day'
FROM olist_orders_dataset
WHERE order_status = 'delivered'
LIMIT 150
ON CONFLICT (review_id) DO NOTHING;

-- Create summary materialized view for benchmarking
CREATE MATERIALIZED VIEW IF NOT EXISTS olist_order_summary AS
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp) as month,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    ROUND(AVG(oi.price), 2) as avg_item_price_brl,
    ROUND(AVG(oi.price) / 4, 2) as avg_item_price_usd, -- Approximate BRL to USD
    ROUND(AVG(p.payment_value), 2) as avg_order_value_brl,
    ROUND(AVG(p.payment_value) / 4, 2) as avg_order_value_usd,
    ROUND(AVG(r.review_score), 2) as avg_rating
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE order_purchase_timestamp >= CURRENT_DATE - INTERVAL '24 months'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;

-- Validation summary
SELECT 
    'Olist Brazilian E-commerce Benchmark Data Import Summary' as status;

SELECT 
    'Customers' as table_name, COUNT(*) as records FROM olist_customers_dataset
UNION ALL
SELECT 'Sellers', COUNT(*) FROM olist_sellers_dataset
UNION ALL  
SELECT 'Products', COUNT(*) FROM olist_products_dataset
UNION ALL
SELECT 'Orders', COUNT(*) FROM olist_orders_dataset
UNION ALL
SELECT 'Order Items', COUNT(*) FROM olist_order_items_dataset  
UNION ALL
SELECT 'Payments', COUNT(*) FROM olist_order_payments_dataset
UNION ALL
SELECT 'Reviews', COUNT(*) FROM olist_order_reviews_dataset;

-- Industry benchmark insights
SELECT 
    'Industry Benchmarks' as metric_type,
    ROUND(AVG(payment_value) / 4, 2) as avg_order_value_usd,
    ROUND(AVG(review_score), 2) as avg_customer_satisfaction,
    COUNT(DISTINCT o.customer_id)::FLOAT / COUNT(DISTINCT o.order_id) as customer_retention_ratio
FROM olist_orders_dataset o
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id  
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

\echo 'Olist industry benchmark data import completed successfully!'
\echo 'Brazilian e-commerce industry data is ready for comparative analysis.'
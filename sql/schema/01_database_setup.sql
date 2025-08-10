-- E-Commerce Analytics Database Setup
-- Purpose: Create database, schemas, users, and enable required extensions
-- PostgreSQL 17 compatible
-- Business Context: Foundation for multi-source e-commerce analytics platform

-- Create database (run as superuser)
-- Note: This needs to be run separately before the rest of the script
-- CREATE DATABASE ecommerce_analytics
--     WITH 
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1;

-- Connect to the database
\c ecommerce_analytics

-- Set client encoding for proper UTF-8 handling (critical for review text)
SET client_encoding = 'UTF8';

-- Create schemas for data isolation
CREATE SCHEMA IF NOT EXISTS internal;      -- Northwind transactional data
CREATE SCHEMA IF NOT EXISTS competitive;   -- Amazon market intelligence  
CREATE SCHEMA IF NOT EXISTS industry;      -- Brazilian e-commerce benchmarks

-- Add schema comments for documentation
COMMENT ON SCHEMA internal IS 'Internal transactional data from Northwind database - orders, customers, products';
COMMENT ON SCHEMA competitive IS 'Competitive intelligence data from Amazon product catalog with pricing and reviews';
COMMENT ON SCHEMA industry IS 'Industry benchmark data from Brazilian Olist e-commerce dataset';

-- Create analytics user with appropriate permissions
-- CREATE USER analytics_user WITH PASSWORD 'your_secure_password';

-- Grant permissions
-- GRANT CONNECT ON DATABASE ecommerce_analytics TO analytics_user;
-- GRANT USAGE ON SCHEMA internal, competitive, industry TO analytics_user;
-- GRANT CREATE ON SCHEMA internal, competitive, industry TO analytics_user;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA internal, competitive, industry TO analytics_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA internal, competitive, industry TO analytics_user;

-- Set default privileges for future objects
-- ALTER DEFAULT PRIVILEGES IN SCHEMA internal, competitive, industry 
--     GRANT ALL PRIVILEGES ON TABLES TO analytics_user;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA internal, competitive, industry 
--     GRANT ALL PRIVILEGES ON SEQUENCES TO analytics_user;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- Query performance monitoring
CREATE EXTENSION IF NOT EXISTS tablefunc;           -- Crosstab functions for pivot tables
CREATE EXTENSION IF NOT EXISTS uuid-ossp;          -- UUID generation for unique identifiers

-- Create custom types for consistent data handling
CREATE TYPE competitive.price_currency AS ENUM ('INR', 'USD', 'EUR', 'BRL');

-- Create utility functions for data processing
CREATE OR REPLACE FUNCTION competitive.convert_rupee_to_decimal(price_text TEXT)
RETURNS DECIMAL(10,2) AS $$
BEGIN
    -- Remove currency symbol and commas, then cast to decimal
    -- Handles formats like '₹1,099' or '₹399'
    RETURN CAST(
        REPLACE(REPLACE(REPLACE(price_text, '₹', ''), ',', ''), ' ', '') 
        AS DECIMAL(10,2)
    );
EXCEPTION WHEN OTHERS THEN
    -- Return NULL for invalid formats
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION competitive.convert_rupee_to_decimal IS 'Converts Indian Rupee price strings to decimal values for calculations';

-- Create function for consistent timestamp handling across time zones
CREATE OR REPLACE FUNCTION public.normalize_timestamp(ts TIMESTAMP, source_tz TEXT DEFAULT 'UTC')
RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
    RETURN ts AT TIME ZONE source_tz AT TIME ZONE 'UTC';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.normalize_timestamp IS 'Normalizes timestamps to UTC for consistent cross-dataset analysis';

-- Set default search path to include all schemas
ALTER DATABASE ecommerce_analytics SET search_path TO internal, competitive, industry, public;

-- Create audit table for data quality tracking
CREATE TABLE IF NOT EXISTS public.data_import_log (
    import_id SERIAL PRIMARY KEY,
    import_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    table_name TEXT NOT NULL,
    rows_imported INTEGER,
    rows_rejected INTEGER,
    import_duration_seconds DECIMAL(10,2),
    error_messages TEXT[],
    import_user TEXT DEFAULT CURRENT_USER
);

COMMENT ON TABLE public.data_import_log IS 'Tracks all data import operations for quality assurance and debugging';

-- Performance settings for analytics workloads
-- Note: These should be adjusted based on available system resources
-- ALTER SYSTEM SET shared_buffers = '1GB';
-- ALTER SYSTEM SET work_mem = '256MB';
-- ALTER SYSTEM SET maintenance_work_mem = '512MB';
-- ALTER SYSTEM SET effective_cache_size = '4GB';
-- ALTER SYSTEM SET random_page_cost = 1.1;  -- For SSD storage

-- Create notification for successful setup
DO $$
BEGIN
    RAISE NOTICE 'Database setup completed successfully!';
    RAISE NOTICE 'Schemas created: internal, competitive, industry';
    RAISE NOTICE 'Extensions enabled: pg_stat_statements, tablefunc, uuid-ossp';
    RAISE NOTICE 'Utility functions created for data processing';
END $$;
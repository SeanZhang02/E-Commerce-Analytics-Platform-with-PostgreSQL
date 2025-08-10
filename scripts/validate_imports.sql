-- Data Quality Validation Scripts
-- Purpose: Comprehensive validation of all imported data across schemas
-- Business Context: Ensure data integrity before analytics and reporting
-- Run after: All data imports are complete

-- Cross-schema validation
SET search_path TO internal, competitive, industry, public;

-- Create validation results table
CREATE TABLE IF NOT EXISTS public.data_validation_results (
    validation_id SERIAL PRIMARY KEY,
    validation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    schema_name TEXT,
    table_name TEXT,
    validation_type TEXT,
    validation_description TEXT,
    expected_result TEXT,
    actual_result TEXT,
    status TEXT, -- PASS, FAIL, WARNING
    severity TEXT, -- CRITICAL, HIGH, MEDIUM, LOW
    recommendation TEXT
);

-- Clear previous validation results
DELETE FROM public.data_validation_results 
WHERE validation_timestamp < CURRENT_TIMESTAMP - INTERVAL '7 days';

-- Validation Function
CREATE OR REPLACE FUNCTION validate_data_quality()
RETURNS TABLE(
    schema_name TEXT,
    table_name TEXT,
    validation_type TEXT,
    status TEXT,
    message TEXT
) AS $$
DECLARE
    validation_count INTEGER := 0;
BEGIN
    -- Schema 1: Internal (Northwind) Validation
    
    -- Row count validations
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'internal' as schema_name,
        'orders' as table_name,
        'row_count' as validation_type,
        'Minimum expected orders in Northwind dataset',
        '830+' as expected_result,
        COUNT(*)::TEXT as actual_result,
        CASE WHEN COUNT(*) >= 830 THEN 'PASS' ELSE 'FAIL' END as status,
        CASE WHEN COUNT(*) >= 830 THEN 'LOW' ELSE 'CRITICAL' END as severity,
        CASE WHEN COUNT(*) < 830 THEN 'Import complete Northwind dataset' ELSE 'Data count validated' END
    FROM internal.orders;
    
    -- Data integrity checks for internal schema
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'internal',
        'orders',
        'null_check',
        'Critical fields should not have NULL values',
        '0 nulls',
        COUNT(*)::TEXT || ' nulls',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'CRITICAL',
        CASE WHEN COUNT(*) > 0 THEN 'Fix NULL values in order_date and customer_id' ELSE 'NULL validation passed' END
    FROM internal.orders
    WHERE order_date IS NULL OR customer_id IS NULL;
    
    -- Revenue calculation validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    WITH revenue_check AS (
        SELECT 
            COUNT(*) as total_records,
            COUNT(CASE WHEN od.unit_price * od.quantity * (1 - od.discount) <= 0 THEN 1 END) as invalid_revenue
        FROM internal.order_details od
    )
    SELECT 
        'internal',
        'order_details',
        'business_logic',
        'Revenue calculations should be positive',
        '0 invalid',
        invalid_revenue::TEXT || ' invalid',
        CASE WHEN invalid_revenue = 0 THEN 'PASS' ELSE 'FAIL' END,
        'HIGH',
        CASE WHEN invalid_revenue > 0 THEN 'Review pricing and discount data' ELSE 'Revenue calculations valid' END
    FROM revenue_check;
    
    -- Schema 2: Competitive (Amazon) Validation
    
    -- Amazon data volume validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'competitive',
        'products',
        'row_count',
        'Expected Amazon products from CSV',
        '1467+',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 1467 THEN 'PASS' ELSE 'WARNING' END,
        CASE WHEN COUNT(*) >= 1467 THEN 'LOW' ELSE 'MEDIUM' END,
        CASE WHEN COUNT(*) < 1467 THEN 'Verify CSV import completeness' ELSE 'Product import validated' END
    FROM competitive.products;
    
    -- Currency conversion validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    WITH currency_check AS (
        SELECT 
            COUNT(*) as total_products,
            COUNT(CASE WHEN discounted_price_inr IS NOT NULL AND discounted_price IS NULL THEN 1 END) as conversion_failures
        FROM competitive.products
        WHERE discounted_price_inr IS NOT NULL
    )
    SELECT 
        'competitive',
        'products',
        'data_transformation',
        'Currency conversion should work for all valid prices',
        '0 failures',
        conversion_failures::TEXT || ' failures',
        CASE WHEN conversion_failures = 0 THEN 'PASS' ELSE 'FAIL' END,
        'HIGH',
        CASE WHEN conversion_failures > 0 THEN 'Fix currency conversion function' ELSE 'Currency conversion working' END
    FROM currency_check;
    
    -- Rating validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'competitive',
        'products',
        'data_range',
        'Ratings should be between 1 and 5',
        '0 invalid',
        COUNT(*)::TEXT || ' invalid',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'MEDIUM',
        CASE WHEN COUNT(*) > 0 THEN 'Clean rating data outside valid range' ELSE 'Rating ranges valid' END
    FROM competitive.products
    WHERE rating IS NOT NULL AND (rating < 1 OR rating > 5);
    
    -- Review data validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'competitive',
        'reviews',
        'row_count',
        'Should have reviews imported from Amazon data',
        '1000+',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 1000 THEN 'PASS' ELSE 'WARNING' END,
        'MEDIUM',
        CASE WHEN COUNT(*) < 1000 THEN 'Verify review extraction from CSV' ELSE 'Review import successful' END
    FROM competitive.reviews;
    
    -- Schema 3: Industry (Olist) Validation
    
    -- Olist data availability check
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'industry',
        'olist_orders_dataset',
        'data_availability',
        'Olist dataset should be available for benchmarking',
        'Data present',
        CASE WHEN COUNT(*) > 0 THEN 'Available (' || COUNT(*) || ' orders)' ELSE 'Not available' END,
        CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'WARNING' END,
        CASE WHEN COUNT(*) > 0 THEN 'LOW' ELSE 'MEDIUM' END,
        CASE WHEN COUNT(*) = 0 THEN 'Import Olist dataset for industry benchmarking' ELSE 'Industry data available' END
    FROM industry.olist_orders_dataset;
    
    -- Cross-schema referential integrity
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    WITH orphan_details AS (
        SELECT COUNT(*) as orphan_count
        FROM internal.order_details od
        LEFT JOIN internal.orders o ON od.order_id = o.order_id
        WHERE o.order_id IS NULL
    )
    SELECT 
        'internal',
        'order_details',
        'referential_integrity',
        'All order details should reference valid orders',
        '0 orphans',
        orphan_count::TEXT || ' orphans',
        CASE WHEN orphan_count = 0 THEN 'PASS' ELSE 'FAIL' END,
        'CRITICAL',
        CASE WHEN orphan_count > 0 THEN 'Fix foreign key relationships' ELSE 'Referential integrity maintained' END
    FROM orphan_details;
    
    -- Materialized view validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    WITH mv_check AS (
        SELECT 
            COUNT(*) as revenue_trends_count
        FROM internal.revenue_trends_summary
    )
    SELECT 
        'internal',
        'revenue_trends_summary',
        'materialized_view',
        'Revenue trends materialized view should have data',
        '1+ records',
        revenue_trends_count::TEXT || ' records',
        CASE WHEN revenue_trends_count > 0 THEN 'PASS' ELSE 'FAIL' END,
        'HIGH',
        CASE WHEN revenue_trends_count = 0 THEN 'Refresh materialized views' ELSE 'Materialized views populated' END
    FROM mv_check;
    
    -- Data freshness validation
    INSERT INTO public.data_validation_results (
        schema_name, table_name, validation_type, validation_description,
        expected_result, actual_result, status, severity, recommendation
    )
    SELECT 
        'internal',
        'orders',
        'data_freshness',
        'Most recent order date should be reasonable',
        'Within expected range',
        'Latest: ' || MAX(order_date)::TEXT,
        CASE 
            WHEN MAX(order_date) >= CURRENT_DATE - INTERVAL '5 years' THEN 'PASS'
            ELSE 'WARNING'
        END,
        'MEDIUM',
        CASE 
            WHEN MAX(order_date) < CURRENT_DATE - INTERVAL '5 years' THEN 'Data may be outdated for current analysis'
            ELSE 'Data freshness acceptable'
        END
    FROM internal.orders;
    
    -- Return summary
    RETURN QUERY
    SELECT 
        dvr.schema_name::TEXT,
        dvr.table_name::TEXT,
        dvr.validation_type::TEXT,
        dvr.status::TEXT,
        dvr.validation_description::TEXT
    FROM public.data_validation_results dvr
    WHERE dvr.validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
    ORDER BY 
        CASE dvr.severity 
            WHEN 'CRITICAL' THEN 1
            WHEN 'HIGH' THEN 2  
            WHEN 'MEDIUM' THEN 3
            ELSE 4
        END,
        dvr.schema_name,
        dvr.table_name;
        
END;
$$ LANGUAGE plpgsql;

-- Validation Summary Report
CREATE OR REPLACE VIEW validation_summary_report AS
WITH validation_stats AS (
    SELECT 
        schema_name,
        status,
        severity,
        COUNT(*) as validation_count
    FROM public.data_validation_results
    WHERE validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    GROUP BY schema_name, status, severity
),
overall_stats AS (
    SELECT 
        COUNT(*) as total_validations,
        COUNT(CASE WHEN status = 'PASS' THEN 1 END) as passed,
        COUNT(CASE WHEN status = 'FAIL' THEN 1 END) as failed,
        COUNT(CASE WHEN status = 'WARNING' THEN 1 END) as warnings,
        COUNT(CASE WHEN severity = 'CRITICAL' THEN 1 END) as critical_issues
    FROM public.data_validation_results
    WHERE validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
)
SELECT 
    COALESCE(vs.schema_name, 'OVERALL') as schema_name,
    COALESCE(vs.status, 'SUMMARY') as status,
    COALESCE(vs.severity, 'ALL') as severity,
    COALESCE(vs.validation_count, os.total_validations) as count,
    ROUND(
        COALESCE(vs.validation_count, os.total_validations) * 100.0 / 
        NULLIF(os.total_validations, 0), 2
    ) as percentage
FROM validation_stats vs
FULL OUTER JOIN overall_stats os ON 1=1
UNION ALL
SELECT 
    'HEALTH_SCORE' as schema_name,
    'OVERALL' as status,
    'SYSTEM' as severity,
    ROUND(
        (COUNT(CASE WHEN status = 'PASS' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0))
    )::INTEGER as count,
    100.0 as percentage
FROM public.data_validation_results
WHERE validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY schema_name, status, severity;

-- Critical Issues Alert
CREATE OR REPLACE VIEW critical_data_issues AS
SELECT 
    schema_name,
    table_name,
    validation_type,
    validation_description,
    actual_result,
    recommendation,
    validation_timestamp
FROM public.data_validation_results
WHERE severity IN ('CRITICAL', 'HIGH') 
  AND status IN ('FAIL')
  AND validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY 
    CASE severity WHEN 'CRITICAL' THEN 1 ELSE 2 END,
    validation_timestamp DESC;

-- Run comprehensive validation
DO $$
DECLARE
    validation_results RECORD;
    total_validations INTEGER := 0;
    failed_validations INTEGER := 0;
    critical_issues INTEGER := 0;
BEGIN
    RAISE NOTICE 'Starting comprehensive data quality validation...';
    
    -- Execute validation function
    FOR validation_results IN 
        SELECT * FROM validate_data_quality()
    LOOP
        total_validations := total_validations + 1;
        
        IF validation_results.status = 'FAIL' THEN
            failed_validations := failed_validations + 1;
            RAISE NOTICE 'FAILED: %.% - %', 
                validation_results.schema_name, 
                validation_results.table_name,
                validation_results.message;
        END IF;
    END LOOP;
    
    -- Count critical issues
    SELECT COUNT(*) INTO critical_issues
    FROM public.data_validation_results
    WHERE severity = 'CRITICAL' 
      AND status = 'FAIL'
      AND validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour';
    
    -- Summary report
    RAISE NOTICE '=== DATA VALIDATION SUMMARY ===';
    RAISE NOTICE 'Total Validations: %', total_validations;
    RAISE NOTICE 'Failed Validations: %', failed_validations;
    RAISE NOTICE 'Critical Issues: %', critical_issues;
    RAISE NOTICE 'Success Rate: %%%', 
        ROUND((total_validations - failed_validations) * 100.0 / NULLIF(total_validations, 0), 2);
    
    IF critical_issues > 0 THEN
        RAISE WARNING 'CRITICAL ISSUES FOUND! Check critical_data_issues view for details.';
    ELSIF failed_validations > 0 THEN
        RAISE NOTICE 'Some validations failed. Review data_validation_results table.';
    ELSE
        RAISE NOTICE 'All data quality validations PASSED!';
    END IF;
    
    RAISE NOTICE 'Validation completed at %', CURRENT_TIMESTAMP;
END $$;

-- Display validation results
SELECT 
    'Validation Summary' as report_type,
    schema_name,
    status,
    count,
    percentage
FROM validation_summary_report
WHERE schema_name != 'HEALTH_SCORE'
ORDER BY schema_name, 
    CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END;

-- Display critical issues (if any)
SELECT 
    'Critical Issues' as issue_type,
    schema_name || '.' || table_name as affected_table,
    validation_description as issue_description,
    recommendation as action_required
FROM critical_data_issues
LIMIT 10;
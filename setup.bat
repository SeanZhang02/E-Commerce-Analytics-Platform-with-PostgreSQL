@echo off
echo =====================================
echo E-Commerce Analytics Platform Setup
echo =====================================

set PSQL="C:\Program Files\PostgreSQL\17\bin\psql"
set DB=ecommerce_analytics

echo.
echo [1/5] Creating database...
%PSQL% -U postgres -c "DROP DATABASE IF EXISTS %DB%;"
%PSQL% -U postgres -c "CREATE DATABASE %DB% WITH ENCODING='UTF8';"
if %errorlevel% neq 0 (
    echo ERROR: Database creation failed
    pause
    exit /b 1
)

echo.
echo [2/5] Setting up database schemas...
echo   - Setting up core database structure...
%PSQL% -U postgres -d %DB% -f "sql\schema\01_database_setup.sql"
echo   - Creating Northwind schema...
%PSQL% -U postgres -d %DB% -f "sql\schema\02_northwind_schema.sql"
echo   - Creating Amazon schema...
%PSQL% -U postgres -d %DB% -f "sql\schema\03_amazon_schema.sql"
echo   - Creating Olist schema...
%PSQL% -U postgres -d %DB% -f "sql\schema\04_olist_schema.sql"
echo   - Creating indexes...
%PSQL% -U postgres -d %DB% -f "sql\schema\05_indexes.sql"

echo.
echo [3/5] Importing all data sources...
echo   - Importing Northwind transactional data...
%PSQL% -U postgres -d %DB% -f "sql\data_import\import_northwind.sql"
echo   - Importing Amazon competitive data with processing...
%PSQL% -U postgres -d %DB% -f "sql\data_import\import_amazon_fixed.sql"
%PSQL% -U postgres -d %DB% -f "sql\data_import\process_amazon_data.sql"
echo   - Importing Olist industry benchmark data...
%PSQL% -U postgres -d %DB% -f "sql\data_import\import_olist.sql"

echo.
echo [4/5] Running analytics suite...
echo   - Revenue trends analysis...
%PSQL% -U postgres -d %DB% -f "sql\analytics\revenue_trends.sql"
echo   - Customer segmentation analysis...
%PSQL% -U postgres -d %DB% -f "sql\analytics\customer_segmentation.sql"
echo   - Competitive pricing analysis...
%PSQL% -U postgres -d %DB% -f "sql\benchmarking\competitive_pricing.sql"

echo.
echo [5/5] Validating data integrity...
%PSQL% -U postgres -d %DB% -f "scripts\validate_imports.sql"

echo.
echo =====================================
echo Setup Complete Successfully!
echo =====================================
echo.
echo Data Sources Loaded:
echo   - Northwind (Internal): Orders and customer data
echo   - Amazon (Competitive): Product catalog and pricing
echo   - Olist (Industry): Benchmark e-commerce data
echo.
echo Analytics Available:
echo   - Revenue Trends with YoY comparisons
echo   - Customer Segmentation (RFM Analysis)
echo   - Competitive Pricing Intelligence
echo.
echo To connect to the database:
echo %PSQL% -U postgres -d %DB%
echo.
echo To run individual analytics:
echo   Revenue Trends: \i sql\analytics\revenue_trends.sql
echo   Customer Segmentation: \i sql\analytics\customer_segmentation.sql
echo   Competitive Pricing: \i sql\benchmarking\competitive_pricing.sql
echo.
pause
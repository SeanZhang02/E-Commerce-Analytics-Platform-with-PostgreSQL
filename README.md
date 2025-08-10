# E-Commerce Sales Analytics & Competitive Intelligence Platform

A comprehensive PostgreSQL-based analytics solution that integrates multiple data sources to deliver actionable business intelligence for e-commerce growth strategy. This platform combines internal transactional data with competitive market intelligence and industry benchmarks to provide strategic insights for mid-sized e-commerce companies competing with market leaders like Amazon.

## Overview

This analytics platform addresses critical business challenges including price competitiveness gaps, customer retention issues, and product mix optimization through data-driven insights. The solution processes and analyzes data from three complementary sources to provide a holistic view of business performance and market positioning.

## Key Features

### Multi-Source Data Integration
- **Internal Analytics**: Northwind transactional database for core business metrics
- **Competitive Intelligence**: Amazon product catalog with pricing and customer reviews
- **Industry Benchmarking**: Brazilian Olist e-commerce dataset for market comparison

### Advanced Analytics Capabilities
- **Revenue Trend Analysis**: Monthly and quarterly performance with year-over-year comparisons
- **Customer Segmentation**: RFM (Recency, Frequency, Monetary) analysis with 8 distinct customer segments
- **Product Performance**: Category analysis, margin calculations, and inventory optimization
- **Competitive Pricing**: Price positioning analysis against Amazon market data
- **Executive Dashboard**: Real-time KPIs with sub-second query performance

### Business Intelligence Features
- **Customer Lifetime Value**: Predictive modeling based on historical purchase patterns
- **Market Positioning Matrix**: Price-quality analysis with strategic recommendations
- **Anomaly Detection**: Statistical outlier identification for transaction patterns
- **Industry Benchmarks**: Performance comparison against 20.5% e-commerce growth standard

## Technical Architecture

### Database Design
- **PostgreSQL 17**: Advanced features including improved CTEs and window functions
- **Schema Organization**: Modular structure with internal, competitive, and industry schemas
- **Performance Optimization**: Strategic indexing for sub-second query execution
- **Data Quality**: Comprehensive validation with automated integrity checks

### Query Structure
```
sql/
├── schema/          Database setup and table definitions
├── data_import/     CSV processing and data loading scripts
├── analytics/       Core business intelligence queries
├── benchmarking/    Competitive analysis queries
└── reporting/       Executive dashboard and KPI views
```

### Key Metrics and Calculations
- **Revenue Formula**: `SUM(unit_price * quantity * (1 - discount))`
- **Average Order Value**: Total Revenue / Order Count
- **Customer Segments**: Champions, Loyal Customers, At Risk, Lost Customers
- **Growth Rates**: Year-over-year and month-over-month comparisons
- **Price Positioning**: Premium, Competitive, Value positioning analysis

## Getting Started

### Prerequisites
- PostgreSQL 17 or higher
- Database with at least 2GB available space
- CSV data files for Amazon product catalog

### Quick Setup (Automated)

Run the automated setup script:
```bash
setup.bat
```

### Manual Installation (Command Line)

1. **Create Database**
   ```bash
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -c "DROP DATABASE IF EXISTS ecommerce_analytics;"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -c "CREATE DATABASE ecommerce_analytics WITH ENCODING='UTF8';"
   ```

2. **Database Schema Setup**
   ```bash
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\schema\01_database_setup.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\schema\02_northwind_schema.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\schema\03_amazon_schema.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\schema\04_olist_schema.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\schema\05_indexes.sql"
   ```

3. **Data Import (All Sources)**
   ```bash
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\data_import\import_northwind.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\data_import\import_amazon_fixed.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\data_import\process_amazon_data.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\data_import\import_olist.sql"
   ```

4. **Run Analytics**
   ```bash
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\analytics\revenue_trends.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\analytics\customer_segmentation.sql"
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "sql\benchmarking\competitive_pricing.sql"
   ```

5. **Validation**
   ```bash
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres -d ecommerce_analytics -f "scripts\validate_imports.sql"
   ```

### Manual Installation (Inside PostgreSQL)

1. **Connect to PostgreSQL**
   ```bash
   "C:\Program Files\PostgreSQL\17\bin\psql" -U postgres
   ```

2. **Setup Database and Connect**
   ```sql
   DROP DATABASE IF EXISTS ecommerce_analytics;
   CREATE DATABASE ecommerce_analytics WITH ENCODING='UTF8';
   \c ecommerce_analytics
   ```

3. **Setup Database Schemas**
   ```sql
   \i sql/schema/01_database_setup.sql
   \i sql/schema/02_northwind_schema.sql
   \i sql/schema/03_amazon_schema.sql
   \i sql/schema/04_olist_schema.sql
   \i sql/schema/05_indexes.sql
   ```

4. **Import All Data Sources**
   ```sql
   \i sql/data_import/import_northwind.sql
   \i sql/data_import/import_amazon_fixed.sql
   \i sql/data_import/process_amazon_data.sql
   \i sql/data_import/import_olist.sql
   ```

5. **Run Analytics Suite**
   ```sql
   \i sql/analytics/revenue_trends.sql
   \i sql/analytics/customer_segmentation.sql
   \i sql/benchmarking/competitive_pricing.sql
   ```

6. **Validate Data Integrity**
   ```sql
   \i scripts/validate_imports.sql
   ```

### Cleanup (If Needed)

To start fresh, run the cleanup script:
```bash
cleanup.bat
```

Or manually drop the database:
```sql
DROP DATABASE IF EXISTS ecommerce_analytics;
```

### Sample Queries

#### Revenue Trends Analysis
```sql
SELECT 
    month,
    revenue,
    yoy_growth_pct,
    avg_order_value
FROM revenue_trends_summary
ORDER BY month DESC
LIMIT 12;
```

#### Customer Segmentation
```sql
SELECT 
    customer_segment,
    customer_count,
    segment_revenue,
    avg_customer_value
FROM customer_health_dashboard
ORDER BY segment_revenue DESC;
```

#### Competitive Pricing Analysis
```sql
SELECT 
    category,
    avg_price_usd,
    competitiveness_level,
    quality_indicator
FROM competitive_positioning_matrix
WHERE market_position = 'Value (High Quality, Low Price)';
```

## Data Sources

### Amazon Product Catalog
- **Volume**: 1,467 products with comprehensive market data
- **Content**: Product pricing in Indian Rupees, customer ratings, reviews
- **Analysis**: Price competitiveness, customer sentiment, discount strategies

### Northwind Transactional Database
- **Purpose**: Internal business metrics and customer behavior analysis
- **Content**: Orders, customers, products, categories, employees
- **Timeframe**: Historical transaction data for trend analysis

### Brazilian Olist Dataset (Optional)
- **Volume**: 100,000+ real e-commerce orders from 2016-2018
- **Purpose**: Industry benchmarking and market comparison
- **Content**: Customer orders, payments, reviews, seller information

## Business Intelligence Outputs

### Executive Dashboard
- Monthly revenue performance with growth indicators
- Customer acquisition and retention metrics
- Top-performing products and categories
- Competitive price positioning alerts
- Data freshness status across all sources

### Customer Analytics
- RFM segmentation with actionable recommendations
- Customer lifetime value projections
- Cohort analysis for retention tracking
- Geographic performance analysis

### Product Intelligence
- Revenue and margin analysis by product and category
- Inventory optimization recommendations
- Competitive price positioning
- Product performance trends

### Market Intelligence
- Amazon pricing strategy analysis
- Discount effectiveness studies
- Market positioning opportunities
- Industry benchmark comparisons

## Performance Specifications

### Query Performance
- **Dashboard Queries**: Sub-second execution time
- **Complex Analytics**: Under 5 seconds for comprehensive analysis
- **Data Processing**: Optimized for datasets up to 120MB

### Data Quality Standards
- Automated validation with 20+ quality checks
- Currency conversion accuracy (INR to USD)
- UTF-8 encoding support for international data
- Referential integrity maintenance across schemas

## Documentation

### Business Calculations
Complete documentation of all KPIs, formulas, and business logic is available in `docs/business_calculations.md`, including:
- Revenue and growth rate calculations
- Customer segmentation methodology
- Competitive analysis frameworks
- Industry benchmark standards

### Data Validation
Comprehensive validation scripts ensure data integrity and business logic consistency across all analytics outputs.

## Industry Context

### Market Positioning
Designed for mid-sized e-commerce companies competing in a market where:
- E-commerce growth projected at 20.5% annually
- Amazon Prime Day generates $24.1B with $53 average order value
- Customer retention rates average 75% across the industry

### Competitive Advantage
This platform provides strategic insights typically available only to large enterprises, enabling smaller companies to make data-driven decisions for:
- Pricing optimization
- Customer retention strategies
- Product mix decisions
- Market positioning

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome. Please ensure all SQL queries follow the established patterns for performance and maintainability. New analytics should include corresponding validation tests and documentation updates.
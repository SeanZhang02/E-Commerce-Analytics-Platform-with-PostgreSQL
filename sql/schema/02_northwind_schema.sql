-- Northwind Schema for E-Commerce Analytics
-- Purpose: Create internal transactional tables based on classic Northwind structure
-- Business Context: Foundation for revenue, customer, and product analytics
-- Reference: https://github.com/pthom/northwind_psql

-- Use internal schema for transactional data
SET search_path TO internal;

-- Categories table: Product categorization
CREATE TABLE IF NOT EXISTS categories (
    category_id SMALLINT PRIMARY KEY,
    category_name VARCHAR(15) NOT NULL,
    description TEXT,
    picture BYTEA
);

COMMENT ON TABLE categories IS 'Product categories for classification and analysis';
COMMENT ON COLUMN categories.category_name IS 'Display name for product category';

-- Suppliers table: Vendor management
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id SMALLINT PRIMARY KEY,
    company_name VARCHAR(40) NOT NULL,
    contact_name VARCHAR(30),
    contact_title VARCHAR(30),
    address VARCHAR(60),
    city VARCHAR(15),
    region VARCHAR(15),
    postal_code VARCHAR(10),
    country VARCHAR(15),
    phone VARCHAR(24),
    fax VARCHAR(24),
    homepage TEXT
);

COMMENT ON TABLE suppliers IS 'Product suppliers for vendor analysis and sourcing metrics';

-- Products table: Product catalog
CREATE TABLE IF NOT EXISTS products (
    product_id SMALLINT PRIMARY KEY,
    product_name VARCHAR(40) NOT NULL,
    supplier_id SMALLINT REFERENCES suppliers(supplier_id),
    category_id SMALLINT REFERENCES categories(category_id),
    quantity_per_unit VARCHAR(20),
    unit_price DECIMAL(10,2),
    units_in_stock SMALLINT,
    units_on_order SMALLINT,
    reorder_level SMALLINT,
    discontinued BOOLEAN NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE products IS 'Product catalog with pricing and inventory data';
COMMENT ON COLUMN products.unit_price IS 'Current selling price per unit';
COMMENT ON COLUMN products.discontinued IS 'Flag for products no longer sold';

-- Customers table: Customer master data
CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(5) PRIMARY KEY,
    company_name VARCHAR(40) NOT NULL,
    contact_name VARCHAR(30),
    contact_title VARCHAR(30),
    address VARCHAR(60),
    city VARCHAR(15),
    region VARCHAR(15),
    postal_code VARCHAR(10),
    country VARCHAR(15),
    phone VARCHAR(24),
    fax VARCHAR(24)
);

COMMENT ON TABLE customers IS 'Customer master data for segmentation and lifetime value analysis';

-- Employees table: Sales staff
CREATE TABLE IF NOT EXISTS employees (
    employee_id SMALLINT PRIMARY KEY,
    last_name VARCHAR(20) NOT NULL,
    first_name VARCHAR(10) NOT NULL,
    title VARCHAR(30),
    title_of_courtesy VARCHAR(25),
    birth_date DATE,
    hire_date DATE,
    address VARCHAR(60),
    city VARCHAR(15),
    region VARCHAR(15),
    postal_code VARCHAR(10),
    country VARCHAR(15),
    home_phone VARCHAR(24),
    extension VARCHAR(4),
    photo BYTEA,
    notes TEXT,
    reports_to SMALLINT REFERENCES employees(employee_id),
    photo_path VARCHAR(255)
);

COMMENT ON TABLE employees IS 'Employee data for sales performance analysis';

-- Shippers table: Logistics providers
CREATE TABLE IF NOT EXISTS shippers (
    shipper_id SMALLINT PRIMARY KEY,
    company_name VARCHAR(40) NOT NULL,
    phone VARCHAR(24)
);

COMMENT ON TABLE shippers IS 'Shipping companies for logistics cost analysis';

-- Orders table: Transaction headers
CREATE TABLE IF NOT EXISTS orders (
    order_id SMALLINT PRIMARY KEY,
    customer_id VARCHAR(5) REFERENCES customers(customer_id),
    employee_id SMALLINT REFERENCES employees(employee_id),
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    ship_via SMALLINT REFERENCES shippers(shipper_id),
    freight DECIMAL(10,2) DEFAULT 0,
    ship_name VARCHAR(40),
    ship_address VARCHAR(60),
    ship_city VARCHAR(15),
    ship_region VARCHAR(15),
    ship_postal_code VARCHAR(10),
    ship_country VARCHAR(15)
);

COMMENT ON TABLE orders IS 'Order headers for transaction analysis and customer behavior';
COMMENT ON COLUMN orders.freight IS 'Shipping cost for the order';
COMMENT ON COLUMN orders.order_date IS 'Transaction date - critical for time series analysis';

-- Order Details table: Transaction line items
CREATE TABLE IF NOT EXISTS order_details (
    order_id SMALLINT REFERENCES orders(order_id),
    product_id SMALLINT REFERENCES products(product_id),
    unit_price DECIMAL(10,2) NOT NULL,
    quantity SMALLINT NOT NULL DEFAULT 1,
    discount DECIMAL(4,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (order_id, product_id)
);

COMMENT ON TABLE order_details IS 'Order line items - foundation for revenue calculations';
COMMENT ON COLUMN order_details.unit_price IS 'Historical price at time of sale';
COMMENT ON COLUMN order_details.discount IS 'Discount percentage (0.15 = 15% off)';

-- Region table: Sales territories
CREATE TABLE IF NOT EXISTS region (
    region_id SMALLINT PRIMARY KEY,
    region_description VARCHAR(50) NOT NULL
);

COMMENT ON TABLE region IS 'Sales regions for geographic analysis';

-- Territories table: Sales territories detail
CREATE TABLE IF NOT EXISTS territories (
    territory_id VARCHAR(20) PRIMARY KEY,
    territory_description VARCHAR(50) NOT NULL,
    region_id SMALLINT REFERENCES region(region_id)
);

COMMENT ON TABLE territories IS 'Sales territories for performance tracking';

-- Employee Territories: Many-to-many relationship
CREATE TABLE IF NOT EXISTS employee_territories (
    employee_id SMALLINT REFERENCES employees(employee_id),
    territory_id VARCHAR(20) REFERENCES territories(territory_id),
    PRIMARY KEY (employee_id, territory_id)
);

COMMENT ON TABLE employee_territories IS 'Employee territory assignments';

-- Create indexes for performance
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_details_product ON order_details(product_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_supplier ON products(supplier_id);

-- Create calculated views for common analytics
CREATE OR REPLACE VIEW order_summary AS
SELECT 
    o.order_id,
    o.customer_id,
    o.employee_id,
    o.order_date,
    o.shipped_date,
    o.freight,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) as order_subtotal,
    COUNT(DISTINCT od.product_id) as product_count,
    SUM(od.quantity) as total_quantity
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_id, o.customer_id, o.employee_id, o.order_date, o.shipped_date, o.freight;

COMMENT ON VIEW order_summary IS 'Pre-calculated order totals for performance';

-- Create data quality check constraints
ALTER TABLE order_details ADD CONSTRAINT check_unit_price_positive CHECK (unit_price > 0);
ALTER TABLE order_details ADD CONSTRAINT check_quantity_positive CHECK (quantity > 0);
ALTER TABLE order_details ADD CONSTRAINT check_discount_range CHECK (discount >= 0 AND discount <= 1);
ALTER TABLE products ADD CONSTRAINT check_product_price_positive CHECK (unit_price >= 0);
ALTER TABLE orders ADD CONSTRAINT check_order_dates CHECK (shipped_date IS NULL OR shipped_date >= order_date);

-- Create notification for successful schema creation
DO $$
BEGIN
    RAISE NOTICE 'Northwind schema created successfully in internal schema!';
    RAISE NOTICE 'Tables created: categories, suppliers, products, customers, employees, orders, order_details, etc.';
    RAISE NOTICE 'Indexes created for optimal query performance';
    RAISE NOTICE 'Data quality constraints applied';
END $$;
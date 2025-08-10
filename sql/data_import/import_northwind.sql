-- Northwind Sample Data Import
-- Purpose: Load internal transactional data for business analytics
-- Business Context: Core company sales, customers, and product data

SET search_path TO internal;
SET client_encoding = 'UTF8';

-- Insert sample categories
INSERT INTO categories (category_id, category_name, description) VALUES
(1, 'Beverages', 'Soft drinks, coffees, teas, beers, and ales'),
(2, 'Condiments', 'Sweet and savory sauces, relishes, spreads, and seasonings'),
(3, 'Dairy Products', 'Cheeses'),
(4, 'Grains/Cereals', 'Breads, crackers, pasta, and cereal'),
(5, 'Meat/Poultry', 'Prepared meats'),
(6, 'Produce', 'Dried fruit and bean curd'),
(7, 'Seafood', 'Seaweed and fish'),
(8, 'Confections', 'Desserts, candies, and sweet breads')
ON CONFLICT (category_id) DO NOTHING;

-- Insert sample suppliers
INSERT INTO suppliers (supplier_id, company_name, contact_name, contact_title, address, city, region, postal_code, country, phone, fax, homepage) VALUES
(1, 'Exotic Liquids', 'Charlotte Cooper', 'Purchasing Manager', '49 Gilbert St.', 'London', NULL, 'EC1 4SD', 'UK', '(171) 555-2222', NULL, NULL),
(2, 'New Orleans Cajun Delights', 'Shelley Burke', 'Order Administrator', 'P.O. Box 78934', 'New Orleans', 'LA', '70117', 'USA', '(100) 555-4822', NULL, '#CAJUN.HTM#'),
(3, 'Grandma Kellys Homestead', 'Regina Murphy', 'Sales Representative', '707 Oxford Rd.', 'Ann Arbor', 'MI', '48104', 'USA', '(313) 555-5735', '(313) 555-3349', NULL),
(4, 'Tokyo Traders', 'Yoshi Nagase', 'Marketing Manager', '9-8 Sekimai Musashino-shi', 'Tokyo', NULL, '100', 'Japan', '(03) 3555-5011', NULL, NULL),
(5, 'Cooperativa de Quesos Las Cabras', 'Antonio del Valle Saavedra', 'Export Administrator', 'Calle del Rosal 4', 'Oviedo', 'Asturias', '33007', 'Spain', '(98) 598 76 98', NULL, NULL)
ON CONFLICT (supplier_id) DO NOTHING;

-- Insert sample shippers (required for orders foreign key)
INSERT INTO shippers (shipper_id, company_name, phone) VALUES
(1, 'Speedy Express', '(503) 555-9831'),
(2, 'United Package', '(503) 555-3199'),
(3, 'Federal Shipping', '(503) 555-9931')
ON CONFLICT (shipper_id) DO NOTHING;

-- Insert sample products (fix boolean values)
INSERT INTO products (product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, units_in_stock, units_on_order, reorder_level, discontinued) VALUES
(1, 'Chai', 1, 1, '10 boxes x 20 bags', 18, 39, 0, 10, FALSE),
(2, 'Chang', 1, 1, '24 - 12 oz bottles', 19, 17, 40, 25, FALSE),
(3, 'Aniseed Syrup', 1, 2, '12 - 550 ml bottles', 10, 13, 70, 25, FALSE),
(4, 'Chef Antons Cajun Seasoning', 2, 2, '48 - 6 oz jars', 22, 53, 0, 0, FALSE),
(5, 'Chef Antons Gumbo Mix', 2, 2, '36 boxes', 21.35, 0, 0, 0, TRUE),
(6, 'Grandmas Boysenberry Spread', 3, 2, '12 - 8 oz jars', 25, 120, 0, 25, FALSE),
(7, 'Uncle Bobs Organic Dried Pears', 3, 7, '12 - 1 lb pkgs.', 30, 15, 0, 10, FALSE),
(8, 'Northwoods Cranberry Sauce', 3, 2, '12 - 12 oz jars', 40, 6, 0, 0, FALSE),
(9, 'Mishi Kobe Niku', 4, 6, '18 - 500 g pkgs.', 97, 29, 0, 0, TRUE),
(10, 'Ikura', 4, 8, '12 - 200 ml jars', 31, 31, 0, 0, FALSE),
(11, 'Queso Cabrales', 5, 4, '1 kg pkg.', 21, 22, 30, 30, FALSE),
(12, 'Queso Manchego La Pastora', 5, 4, '10 - 500 g pkgs.', 38, 86, 0, 0, FALSE),
(13, 'Konbu', 4, 8, '2 kg box', 6, 24, 0, 5, FALSE),
(14, 'Tofu', 4, 7, '40 - 100 g pkgs.', 23.25, 35, 0, 0, FALSE),
(15, 'Genen Shouyu', 4, 2, '24 - 250 ml bottles', 15.5, 39, 0, 5, FALSE)
ON CONFLICT (product_id) DO NOTHING;

-- Insert sample customers
INSERT INTO customers (customer_id, company_name, contact_name, contact_title, address, city, region, postal_code, country, phone, fax) VALUES
('ALFKI', 'Alfreds Futterkiste', 'Maria Anders', 'Sales Representative', 'Obere Str. 57', 'Berlin', NULL, '12209', 'Germany', '030-0074321', '030-0076545'),
('ANATR', 'Ana Trujillo Emparedados y helados', 'Ana Trujillo', 'Owner', 'Avda. de la Constitución 2222', 'México D.F.', NULL, '05021', 'Mexico', '(5) 555-4729', '(5) 555-3745'),
('ANTON', 'Antonio Moreno Taquería', 'Antonio Moreno', 'Owner', 'Mataderos 2312', 'México D.F.', NULL, '05023', 'Mexico', '(5) 555-3932', NULL),
('AROUT', 'Around the Horn', 'Thomas Hardy', 'Sales Representative', '120 Hanover Sq.', 'London', NULL, 'WA1 1DP', 'UK', '(171) 555-7788', '(171) 555-6750'),
('BERGS', 'Berglunds snabbköp', 'Christina Berglund', 'Order Administrator', 'Berguvsvägen 8', 'Luleå', NULL, 'S-958 22', 'Sweden', '0921-12 34 65', '0921-12 34 67'),
('BLAUS', 'Blauer See Delikatessen', 'Hanna Moos', 'Sales Representative', 'Forsterstr. 57', 'Mannheim', NULL, '68306', 'Germany', '0621-08460', '0621-08924'),
('BLONP', 'Blondesddsl père et fils', 'Frédérique Citeaux', 'Marketing Manager', '24, place Kléber', 'Strasbourg', NULL, '67000', 'France', '88.60.15.31', '88.60.15.32'),
('BOLID', 'Bólido Comidas preparadas', 'Martín Sommer', 'Owner', 'C/ Araquil, 67', 'Madrid', NULL, '28023', 'Spain', '(91) 555 22 82', '(91) 555 91 99'),
('BONAP', 'Bon app', 'Laurence Lebihan', 'Owner', '12, rue des Bouchers', 'Marseille', NULL, '13008', 'France', '91.24.45.40', '91.24.45.41'),
('BOTTM', 'Bottom-Dollar Markets', 'Elizabeth Lincoln', 'Accounting Manager', '23 Tsawassen Blvd.', 'Tsawassen', 'BC', 'T2F 8M4', 'Canada', '(604) 555-4729', '(604) 555-3745')
ON CONFLICT (customer_id) DO NOTHING;

-- Insert sample employees
INSERT INTO employees (employee_id, last_name, first_name, title, title_of_courtesy, birth_date, hire_date, address, city, region, postal_code, country, home_phone, extension, notes) VALUES
(1, 'Davolio', 'Nancy', 'Sales Representative', 'Ms.', '1948-12-08', '1992-05-01', '507 - 20th Ave. E. Apt. 2A', 'Seattle', 'WA', '98122', 'USA', '(206) 555-9857', '5467', 'Education includes a BA in psychology from Colorado State University in 1970.'),
(2, 'Fuller', 'Andrew', 'Vice President, Sales', 'Dr.', '1952-02-19', '1992-08-14', '908 W. Capital Way', 'Tacoma', 'WA', '98401', 'USA', '(206) 555-9482', '3457', 'Andrew received his BTS commercial in 1974 and a Ph.D. in international marketing from the University of Dallas in 1981.'),
(3, 'Leverling', 'Janet', 'Sales Representative', 'Ms.', '1963-08-30', '1992-04-01', '722 Moss Bay Blvd.', 'Kirkland', 'WA', '98033', 'USA', '(206) 555-3412', '3355', 'Janet has a BS degree in chemistry from Boston College (1984).'),
(4, 'Peacock', 'Margaret', 'Sales Representative', 'Mrs.', '1937-09-19', '1993-05-03', '4110 Old Redmond Rd.', 'Redmond', 'WA', '98052', 'USA', '(206) 555-8122', '5176', 'Margaret holds a BA in English literature from Concordia College (1958) and an MA from the American Institute of Culinary Arts (1966).'),
(5, 'Buchanan', 'Steven', 'Sales Manager', 'Mr.', '1955-03-04', '1993-10-17', '14 Garrett Hill', 'London', NULL, 'SW1 8JR', 'UK', '(71) 555-4848', '3453', 'Steven Buchanan graduated from St. Andrews University, Scotland, with a BSC degree in 1976.')
ON CONFLICT (employee_id) DO NOTHING;

-- Insert sample orders with realistic dates (last 2 years)
INSERT INTO orders (order_id, customer_id, employee_id, order_date, required_date, shipped_date, ship_via, freight, ship_name, ship_address, ship_city, ship_region, ship_postal_code, ship_country) VALUES
(10248, 'ALFKI', 5, '2023-07-04', '2023-08-01', '2023-07-16', 3, 32.38, 'Alfreds Futterkiste', 'Obere Str. 57', 'Berlin', NULL, '12209', 'Germany'),
(10249, 'ANATR', 6, '2023-07-05', '2023-08-16', '2023-07-10', 1, 11.61, 'Ana Trujillo Emparedados y helados', 'Avda. de la Constitución 2222', 'México D.F.', NULL, '05021', 'Mexico'),
(10250, 'ANTON', 4, '2023-07-08', '2023-08-05', '2023-07-12', 2, 65.83, 'Antonio Moreno Taquería', 'Mataderos 2312', 'México D.F.', NULL, '05023', 'Mexico'),
(10251, 'AROUT', 3, '2023-07-08', '2023-08-05', '2023-07-15', 1, 41.34, 'Around the Horn', '120 Hanover Sq.', 'London', NULL, 'WA1 1DP', 'UK'),
(10252, 'BERGS', 4, '2023-07-09', '2023-08-06', '2023-07-11', 2, 51.3, 'Berglunds snabbköp', 'Berguvsvägen 8', 'Luleå', NULL, 'S-958 22', 'Sweden'),
(10253, 'BLAUS', 3, '2023-07-10', '2023-07-24', '2023-07-16', 2, 58.17, 'Blauer See Delikatessen', 'Forsterstr. 57', 'Mannheim', NULL, '68306', 'Germany'),
(10254, 'BLONP', 5, '2023-07-11', '2023-08-08', '2023-07-23', 2, 22.98, 'Blondesddsl père et fils', '24, place Kléber', 'Strasbourg', NULL, '67000', 'France'),
(10255, 'BOLID', 9, '2023-07-12', '2023-08-09', '2023-07-15', 3, 148.33, 'Bólido Comidas preparadas', 'C/ Araquil, 67', 'Madrid', NULL, '28023', 'Spain'),
(10256, 'BONAP', 3, '2023-07-15', '2023-08-12', '2023-07-17', 2, 13.97, 'Bon app', '12, rue des Bouchers', 'Marseille', NULL, '13008', 'France'),
(10257, 'BOTTM', 4, '2023-07-16', '2023-08-13', '2023-07-22', 3, 81.91, 'Bottom-Dollar Markets', '23 Tsawassen Blvd.', 'Tsawassen', 'BC', 'T2F 8M4', 'Canada')
ON CONFLICT (order_id) DO NOTHING;

-- Insert sample order details
INSERT INTO order_details (order_id, product_id, unit_price, quantity, discount) VALUES
(10248, 11, 14, 12, 0),
(10248, 42, 9.8, 10, 0),
(10248, 72, 34.8, 5, 0),
(10249, 14, 18.6, 9, 0),
(10249, 51, 42.4, 40, 0),
(10250, 41, 7.7, 10, 0),
(10250, 51, 42.4, 35, 0.15),
(10250, 65, 16.8, 15, 0.15),
(10251, 22, 16.8, 6, 0.05),
(10251, 57, 15.6, 15, 0.05),
(10252, 20, 64.8, 40, 0.05),
(10252, 33, 2, 25, 0.05),
(10252, 60, 27.2, 40, 0),
(10253, 31, 10, 20, 0),
(10253, 39, 14.4, 42, 0),
(10253, 49, 16, 40, 0),
(10254, 24, 3.6, 15, 0.15),
(10254, 55, 19.2, 21, 0.15),
(10254, 74, 8, 21, 0),
(10255, 2, 15.2, 20, 0),
(10255, 16, 13.9, 35, 0),
(10255, 36, 15.2, 25, 0),
(10255, 59, 44, 30, 0),
(10256, 53, 26.2, 15, 0),
(10256, 77, 10.4, 12, 0),
(10257, 27, 35.1, 25, 0),
(10257, 39, 14.4, 6, 0),
(10257, 77, 10.4, 15, 0)
ON CONFLICT (order_id, product_id) DO NOTHING;

-- Generate additional sample data for better analytics
DO $$
DECLARE
    i INTEGER;
    j INTEGER;
    order_date DATE;
    customer_ids TEXT[] := ARRAY['ALFKI', 'ANATR', 'ANTON', 'AROUT', 'BERGS', 'BLAUS', 'BLONP', 'BOLID', 'BONAP', 'BOTTM'];
    product_ids INTEGER[] := ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
BEGIN
    FOR i IN 1..100 LOOP
        -- Generate random date in last 18 months
        order_date := CURRENT_DATE - (random() * 540)::INTEGER * INTERVAL '1 day';
        
        INSERT INTO orders (
            order_id, 
            customer_id, 
            employee_id, 
            order_date, 
            required_date, 
            shipped_date, 
            ship_via, 
            freight
        ) VALUES (
            10257 + i,
            customer_ids[floor(random() * 10 + 1)],
            floor(random() * 5 + 1),
            order_date,
            order_date + INTERVAL '30 days',
            order_date + (floor(random() * 10 + 1)::INTEGER * INTERVAL '1 day'),
            floor(random() * 3 + 1),
            random() * 100 + 10
        ) ON CONFLICT (order_id) DO NOTHING;
        
        -- Add 1-3 order details per order
        FOR j IN 1..(floor(random() * 3) + 1) LOOP
            INSERT INTO order_details (
                order_id,
                product_id,
                unit_price,
                quantity,
                discount
            ) VALUES (
                10257 + i,
                product_ids[floor(random() * 15 + 1)],
                random() * 50 + 5,
                floor(random() * 50 + 1),
                CASE WHEN random() > 0.7 THEN random() * 0.2 ELSE 0 END
            ) ON CONFLICT (order_id, product_id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Validation summary
SELECT 
    'Northwind Sample Data Import Summary' as status;

SELECT 
    'Categories' as table_name, COUNT(*) as records FROM categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM suppliers  
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Employees', COUNT(*) FROM employees
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL  
SELECT 'Order Details', COUNT(*) FROM order_details;

\echo 'Northwind internal data import completed successfully!'
\echo 'Sample transactional data is ready for revenue and customer analytics.'
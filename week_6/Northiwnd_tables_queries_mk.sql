CREATE DATABASE max_northwind

DROP TABLE IF EXISTS shippers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS employee_territories;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS regions CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_details CASCADE;
DROP TABLE IF EXISTS territories;
DROP TABLE IF EXISTS latlong;

--- create all tables

CREATE TABLE shippers(
  shipper_id SERIAL PRIMARY KEY,
  company_name VARCHAR(100) NOT NULL,
  phone VARCHAR(15)
);

COPY shippers FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/shippers.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE categories(
  category_id SERIAL PRIMARY KEY,
  catagory_name VARCHAR(50) NOT NULL,
  description VARCHAR(100),
  picture BYTEA
);

COPY categories FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/categories.csv'
DELIMITER ',' CSV HEADER;


CREATE TABLE customers(
  customer_id CHAR(5) PRIMARY KEY,
  company_name VARCHAR(100) NOT NULL,
  contact_name VARCHAR(100) NOT NULL,
  contact_title VARCHAR(50),
  address VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  region VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NOT NULL,
  country VARCHAR(20) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  fax VARCHAR(20)
);

COPY customers FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/customers.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE employee_territories(
  employee_id INTEGER NOT NULL,
  territory_id INTEGER NOT NULL,
  FOREIGN KEY (territory_id) REFERENCES territories,
  FOREIGN KEY (employee_id) REFERENCES employees
);

COPY employee_territories FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/employee_territories.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE employees(
  employee_id SMALLINT PRIMARY KEY,
  last_name VARCHAR(20) NOT NULL,
  first_name VARCHAR(20) NOT NULL,
  employee_title VARCHAR(50) NOT NULL,
  title VARCHAR(5),
  date_of_birth TIMESTAMP,
  date_of_hire TIMESTAMP,
  address VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  region VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NOT NULL,
  country VARCHAR(20) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  extension SMALLINT,
  photo BYTEA,
  notes TEXT,
  reports_to VARCHAR(5),
  path_to_photo VARCHAR(50)
);

COPY employees FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/employees.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE products(
  product_id SERIAL PRIMARY KEY,
  product_name VARCHAR(50),
  supplier_id SMALLINT NOT NULL,
  category_id SMALLINT NOT NULL,
  quantity VARCHAR(30) NOT NULL,
  price_per_unit MONEY,
  units_in_stock INTEGER,
  units_on_order INTEGER,
  reorder_level SMALLINT,
  discontinued BOOLEAN
);

COPY products FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/products.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE regions(
  regions_id SERIAL PRIMARY KEY,
  regions_description VARCHAR(10)
);

COPY regions FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/regions.csv'
DELIMITER ',' CSV HEADER;


CREATE TABLE suppliers(
  supplier_id SERIAL PRIMARY KEY,
  company_name VARCHAR(100) NOT NULL,
  contact_name VARCHAR(100) NOT NULL,
  contact_title VARCHAR(50),
  address VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  region VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NOT NULL,
  country VARCHAR(20) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  fax VARCHAR(20),
  homepage TEXT
);

COPY suppliers FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/suppliers.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE orders(
  order_id SERIAL PRIMARY KEY,
  customer_id CHAR(5) NOT NULL,
  employee_id SMALLINT NOT NULL,
  date_of_order TIMESTAMP,
  date_of_requirement TIMESTAMP,
  date_of_shipment TEXT,
  shipped_via SMALLINT,
  freight REAL,
  shipment_name VARCHAR(100) NOT NULL,
  shipment_address VARCHAR(100) NOT NULL,
  shipment_city VARCHAR(50) NOT NULL,
  shipment_region VARCHAR(50),
  shipment_postal_code VARCHAR(10) NOT NULL,
  shipment_country VARCHAR(20) NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers,
  FOREIGN KEY (employee_id) REFERENCES employees
);

COPY orders FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/orders.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE order_details(
  order_id SMALLINT NOT NULL,
  product_id SMALLINT NOT NULL,
  unit_price REAL NOT NULL,
  quantity SMALLINT NOT NULL,
  discount REAL,
  FOREIGN KEY (product_id) REFERENCES products,
  FOREIGN KEY (order_id) REFERENCES orders
);

COPY order_details FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/order_details.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE territories(
  territory_id INTEGER PRIMARY KEY,
  territory_description VARCHAR(15),
  regions_id SMALLINT NOT NULL,
  FOREIGN KEY (regions_id) REFERENCES regions
);

COPY territories FROM '/Users/maxkoeppel/SPICED/Week_06/northwind_data_clean/data/territories.csv'
DELIMITER ',' CSV HEADER;

---- include a non-northwind table with latitude/ longitude and countries

  CREATE TABLE latlong(
country_code VARCHAR(3),
latitude REAL,
longitude REAL,
country TEXT
);

COPY latlong FROM '/Users/maxkoeppel/SPICED/Week_06/latlog_countries.csv' DELIMITER ',' CSV HEADER;


-- start with sql-queries on the northwind

-- check  content of some of the tables
SELECT *
FROM orders
LIMIT 3;

SELECT COUNT(*), employee_id
FROM orders
GROUP BY employee_id
;

SELECT *
FROM orders
LIMIT 2;

-- number of products
SELECT DISTINCT COUNT(*)
FROM products
;

-- number of products discontinued
SELECT DISTINCT COUNT(*)
FROM products
WHERE discontinued = TRUE
;

-- which product is sold how often
SELECT COUNT(*) as count, product_name
FROM products AS p
JOIN order_details AS od ON od.product_id = p.product_id
GROUP BY p.product_id
ORDER BY count DESC;


CREATE VIEW best_customer_view AS -- VIEW automatically updates, tables not, but only on command (VIEW has to rerun query each time; computational intense, materialized view updates only in given intervalls)

SELECT  c.company_name, SUM(od.quantity * od.unit_price) AS revenue
FROM customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id
JOIN order_details AS od ON od.order_id = o.order_id
GROUP BY c.company_name
ORDER BY revenue DESC
;


--- revenue per country and year
SELECT  c.country, EXTRACT(year FROM o.date_of_order) AS order_year, SUM(od.quantity * od.unit_price) AS revenue_per_country_year
FROM customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id
JOIN order_details AS od ON od.order_id = o.order_id
GROUP BY c.country, order_year
ORDER BY revenue_per_country_year DESC
;


---- order volume per country and global map display
WITH orders_per_country AS(
  SELECT  c.country, SUM(od.quantity * od.unit_price) AS total_per_country
  FROM customers AS c
  JOIN orders AS o ON c.customer_id = o.customer_id
  JOIN order_details AS od ON od.order_id = o.order_id
  GROUP BY c.country
)
SELECT  opc.country, total_per_country, ll.latitude, ll.longitude
FROM latlong AS ll
JOIN orders_per_country AS opc ON opc.country = ll.country
ORDER BY total_per_country DESC;

--- amount of dairy products produced and consumed per country
SELECT su.country AS producers, c.country AS consumers , SUM(od.quantity) AS produced_amount
FROM suppliers AS su
JOIN products AS p ON p.supplier_id = su.supplier_id
JOIN categories AS ct ON ct.category_id = p.category_id
JOIN order_details AS od ON od.product_id = p.product_id
JOIN orders AS o ON o.order_id = od.order_id
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE ct.catagory_name = 'Dairy Products'
GROUP BY producers, consumers
HAVING SUM(od.quantity) > 100
ORDER BY producers DESC
;

-- sold product quantities per yearsSELECT SUM(od.quantity), p.product_name, c.country
FROM order_details AS od
JOIN products AS p ON p.product_id = od.product_id
JOIN orders AS o ON o.order_id = od.order_id
JOIN customers AS c ON c.customer_id = o.customer_id
GROUP BY c.country, p.product_name
ORDER BY SUM(od.quantity) DESC;


-- revenue per employee and yearsSELECT SUM(od.quantity *od.unit_price) AS revenue, e.first_name, EXTRACT(year from o.date_of_order) AS year
FROM order_details AS od
JOIN orders AS o ON o.order_id = od.order_id
JOIN employees AS e ON e.employee_id = o.employee_id
GROUP BY e.first_name, year
ORDER BY revenue DESC;


-- generated revue related to years employees are in company
WITH years_in_company AS (
  SELECT e.first_name, e.employee_id, 1998 - EXTRACT(Year FROM e.date_of_hire) as company_years
  FROM employees AS e)
SELECT yic.first_name, ROUND(SUM(od.quantity * od.unit_price)) AS revenue, yic.company_years
FROM years_in_company AS yic
JOIN orders AS o ON o.employee_id = yic.employee_id
JOIN order_details AS od ON od.order_id = o.order_id
GROUP BY yic.first_name, yic.company_years
ORDER BY company_years DESC
;


--- territories per employee
SELECT COUNT(t.territory_description) AS number_of_territories, e.first_name
FROM territories AS t
JOIN employee_territories AS et ON et.territory_id = t.territory_id
JOIN employees AS e ON e.employee_id = et.employee_id
GROUP BY e.first_name;


---- countries per employee
SELECT e.first_name, COUNT(c.country)
FROM employees AS e
JOIN orders AS o ON o.employee_id = e.employee_id
JOIN customers AS c ON c.customer_id = o.customer_id
GROUP BY e.first_name
ORDER BY COUNT(c.country);

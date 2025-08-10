CREATE DATABASE ecommerce_db;
USE ecommerce_db;

CREATE TABLE amazon_sales (
    id INT PRIMARY KEY,
    order_id VARCHAR(50),
    order_date DATE,
    status VARCHAR(100),
    fulfilment VARCHAR(50),
    sales_channel VARCHAR(50),
    ship_service_level VARCHAR(50),
    style VARCHAR(100),
    sku VARCHAR(100),
    category VARCHAR(100),
    size VARCHAR(50),
    asin VARCHAR(20),
    courier_status VARCHAR(100),
    qty INT,
    currency VARCHAR(10),
    amount DECIMAL(10,2),
    ship_city VARCHAR(100),
    ship_state VARCHAR(100),
    ship_postal_code VARCHAR(20),
    ship_country VARCHAR(50),
    promotion_ids TEXT,
    b2b VARCHAR(50),
    fulfilled_by VARCHAR(50)
);




SHOW VARIABLES LIKE 'secure_file_priv';

SET GLOBAL local_infile = 1;

SHOW COLUMNS FROM amazon_sales;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AmazonSaleReportClean.csv'
INTO TABLE amazon_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    id,
    order_id,
    @order_date_str,
    status,
    fulfilment,
    sales_channel,
    ship_service_level,
    style,
    sku,
    category,
    size,
    asin,
    courier_status,
    @qty_str,
    currency,
    @amount_str,
    ship_city,
    ship_state,
    ship_postal_code,
    ship_country,
    promotion_ids,
    @b2b_str,
    fulfilled_by
)
SET
    order_date = STR_TO_DATE(@order_date_str, '%m-%d-%y'),
    qty = CAST(@qty_str AS UNSIGNED),
    amount = CAST(@amount_str AS DECIMAL(10,2)),
    b2b = CASE 
            WHEN LOWER(@b2b_str) IN ('yes', 'true', '1') THEN 1 
            ELSE 0 
          END;
          
SELECT * FROM amazon_sales;

-- Total sales per category (only Shipped orders)

SELECT category, SUM(amount) AS total_sales
FROM amazon_sales
WHERE status LIKE 'Shipped%'
GROUP BY category
ORDER BY total_sales DESC;

-- Number of orders per city

SELECT ship_city, COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY ship_city
ORDER BY total_orders DESC;



SELECT order_id, order_date, qty, amount
FROM amazon_sales
WHERE amount > 100
ORDER BY amount DESC;


-- TOTAL SALES PER DATE

SELECT order_date, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY order_date
ORDER BY order_date;


-- JOINS

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);

INSERT INTO products (product_id, product_name, category) VALUES
(1, 'Phone Case', 'Electronics'),
(2, 'USB Cable', 'Electronics'),
(3, 'Water Bottle', 'Home & Kitchen');

ALTER TABLE amazon_sales ADD product_id INT;
UPDATE amazon_sales SET product_id = FLOOR(1 + (RAND() * 3)) WHERE id > 0;


-- Only matching records (INNER JOIN) 

SELECT a.order_id, p.product_name, a.qty, a.amount
FROM amazon_sales a
INNER JOIN products p
    ON a.product_id = p.product_id;
    
    
-- All from amazon_sales even if no match in products (LEFT JOIN)
 
SELECT a.order_id, p.product_name
FROM amazon_sales a
LEFT JOIN products p
    ON a.product_id = p.product_id;
    
    
    
-- All from products even if no match in amazon_sales (RIGHT JOIN)
SELECT a.order_id, p.product_name
FROM amazon_sales a
RIGHT JOIN products p
    ON a.product_id = p.product_id;


-- Orders above average amount ( Using Subqueries)

SELECT *
FROM amazon_sales
WHERE amount > (
    SELECT AVG(amount) FROM amazon_sales
);


-- Categories with total sales above category average
SELECT category, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY category
HAVING total_sales > (
    SELECT AVG(total_amt)
    FROM (
        SELECT SUM(amount) AS total_amt
        FROM amazon_sales
        GROUP BY category
    ) AS subquery
);


-- Total sales and average quantity ( Using aggregate functions)

SELECT 
    SUM(amount) AS total_revenue,
    AVG(qty) AS avg_qty,
    MAX(amount) AS highest_order
FROM amazon_sales;

-- Created Views for Analysis

CREATE VIEW daily_sales AS
SELECT order_date, SUM(amount) AS total_sales
FROM amazon_sales
GROUP BY order_date;

SELECT * FROM daily_sales WHERE total_sales > 500;



-- Added index on order_date for faster filtering

CREATE INDEX idx_order_date ON amazon_sales(order_date);

-- Added index on amount for faster range queries

CREATE INDEX idx_amount ON amazon_sales(amount);







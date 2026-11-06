Create Database Olist;
Use Olist;
CREATE TABLE customers (customer_id VARCHAR(50) PRIMARY KEY,customer_unique_id VARCHAR(50),customer_zip_code_prefix VARCHAR(10),
customer_city VARCHAR(100),customer_state VARCHAR(5));
CREATE TABLE orders (order_id VARCHAR(50) PRIMARY KEY,customer_id VARCHAR(50),order_status VARCHAR(20),order_purchase_timestamp DATETIME,
order_approved_at DATETIME,order_delivered_carrier_date DATETIME,order_delivered_customer_date DATETIME,order_estimated_delivery_date DATETIME);
CREATE TABLE order_items (order_id VARCHAR(50),order_item_id INT,product_id VARCHAR(50),seller_id VARCHAR(50),
  shipping_limit_date DATETIME,price DECIMAL(10,2),freight_value DECIMAL(10,2),PRIMARY KEY (order_id, order_item_id));
  CREATE TABLE payments (order_id VARCHAR(50),payment_sequential INT,payment_type VARCHAR(30),payment_installments INT,
  payment_value DECIMAL(10,2),PRIMARY KEY (order_id, payment_sequential));
  CREATE TABLE reviews (review_id VARCHAR(50),order_id VARCHAR(50),review_score INT,review_comment_title VARCHAR(255),
  review_comment_message TEXT,review_creation_date DATETIME,review_answer_timestamp DATETIME);
  CREATE TABLE products (product_id VARCHAR(50) PRIMARY KEY,product_category_name VARCHAR(100),product_name_lenght INT,
  product_description_lenght INT,product_photos_qty INT,product_weight_g INT,product_length_cm INT,
  product_height_cm INT,product_width_cm INT);
  CREATE TABLE sellers (seller_id VARCHAR(50) PRIMARY KEY,seller_zip_code_prefix VARCHAR(10),
  seller_city VARCHAR(100),seller_state VARCHAR(5));
  CREATE TABLE category_translation (product_category_name VARCHAR(100) PRIMARY KEY,
  product_category_name_english VARCHAR(100));
  Truncate Customers;
  SET GLOBAL local_infile = 1;
  LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_orders_dataset.csv'
  INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES (order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp = NULLIF(@purchase,''),
    order_approved_at = NULLIF(@approved,''),
    order_delivered_carrier_date = NULLIF(@carrier,''),
    order_delivered_customer_date = NULLIF(@delivered,''),
    order_estimated_delivery_date = NULLIF(@estimated,'');
    Select * from Orders;
     LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_orders_dataset.csv'
  INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES (order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp = NULLIF(@purchase,''),
    order_approved_at = NULLIF(@approved,''),
    order_delivered_carrier_date = NULLIF(@carrier,''),
    order_delivered_customer_date = NULLIF(@delivered,''),
    order_estimated_delivery_date = NULLIF(@estimated,'');
    LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);
LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(order_id, order_item_id, product_id, seller_id, @shipping_limit, price, freight_value)
SET shipping_limit_date = NULLIF(@shipping_limit, '');
LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(order_id, payment_sequential, payment_type, payment_installments, payment_value);
LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(review_id, order_id, review_score, @title, @msg, @created, @answered)
SET review_comment_title = NULLIF(@title, ''),
    review_comment_message = NULLIF(@msg, ''),
    review_creation_date = NULLIF(@created, ''),
    review_answer_timestamp = NULLIF(@answered, '');
    LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(product_id, @cat, @name_len, @desc_len, @photos, @weight, @len, @height, @width)
SET product_category_name = NULLIF(@cat, ''),
    product_name_lenght = NULLIF(@name_len, ''),
    product_description_lenght = NULLIF(@desc_len, ''),
    product_photos_qty = NULLIF(@photos, ''),
    product_weight_g = NULLIF(@weight, ''),
    product_length_cm = NULLIF(@len, ''),
    product_height_cm = NULLIF(@height, ''),
    product_width_cm = NULLIF(@width, '');
    LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(seller_id, seller_zip_code_prefix, seller_city, seller_state);
LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES 
(product_category_name, product_category_name_english);
truncate Table reviews;
LOAD DATA LOCAL INFILE 'D:/Projects_Data/Olist_E_Commerce/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(review_id, order_id, review_score, @title, @msg, @created, @answered)
SET review_comment_title = NULLIF(@title, ''),
    review_comment_message = NULLIF(@msg, ''),
    review_creation_date = NULLIF(@created, ''),
    review_answer_timestamp = NULLIF(@answered, '');
UPDATE customers SET customer_state = TRIM(TRAILING '\r' FROM customer_state);
UPDATE sellers SET seller_state = TRIM(TRAILING '\r' FROM seller_state);
SELECT 'customers' t , COUNT(*) n FROM customers UNION ALL
SELECT 'orders', COUNT(*) FROM orders UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items UNION ALL
SELECT 'payments', COUNT(*) FROM payments UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews UNION ALL
SELECT 'products', COUNT(*) FROM products UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers;
SELECT order_status, COUNT(*) FROM orders GROUP BY order_status ORDER BY 2 DESC;
Select count(*) from orders where order_status = 'delivered' AND order_delivered_customer_date IS NULL;
SELECT COUNT(*) FROM order_items oi LEFT JOIN orders o ON o.order_id = oi.order_id WHERE o.order_id IS NULL;







    
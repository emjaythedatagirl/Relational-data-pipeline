SELECT COUNT(*)geolocation_zip_code_prefix
FROM olist_geolocation_dataset;

SELECT * FROM olist_geolocation_dataset;
## Cleaning the olist brazilian ecommerce dataset

-- 1. schema integration & merging
CREATE TABLE olist_cleaned_orders AS
SELECT
	o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.product_id,
    oi.freight_value,
    p.product_category_name,
    t.product_category_name_english,
    c.customer_city,
    c.customer_state
FROM olist_orders_dataset AS o
JOIN olist_order_items_dataset AS oi
ON o.order_id = oi.order_id
JOIN olist_products_dataset AS 	p
ON oi.product_id = p.product_id
JOIN olist_customers_dataset AS c
ON o.customer_id = c.customer_id
LEFT JOIN product_category_name_translation AS t
ON p.product_category_name = t.product_category_name
;
-- 2. correct column name 
alter table  product_category_name_translation
rename column ï»¿product_category_name to product_category_name;

SELECT * 
FROM olist_cleaned_orders;

-- 3. standardizing the timestamp
-- convert string timestamps to proper DATETIME  format
UPDATE olist_cleaned_orders
SET
    order_purchase_timestamp = STR_TO_DATE(NULLIF(order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s'),
    
    order_delivered_customer_date = STR_TO_DATE(NULLIF(order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
    
    order_estimated_delivery_date = STR_TO_DATE(NULLIF(order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
WHERE order_id IS NOT NULL;

-- 4. modify the column type permanently
ALTER TABLE olist_cleaned_orders
MODIFY COLUMN order_purchase_timestamp DATETIME,
MODIFY COLUMN order_delivered_customer_date DATETIME,
MODIFY COLUMN order_estimated_delivery_date DATETIME;

-- 5. Handling missing values & nulls
-- filing missing english category names with the portugese name or 'unknown'
UPDATE olist_cleaned_orders
SET product_category_name_english = COALESCE(product_category_name_english, product_category_name, 'unknown')
WHERE product_category_name_english IS NULL;

-- Flagging cancelled orders with missing delivery dates(this prevents them from skewing delivery time average)
DELETE FROM olist_cleaned_orders
WHERE order_status= 'canceled' AND order_delivered_customer_date IS NULL;

-- 6. Text standardization (city &state)
-- convert city names to lowercase and trim whitespace
UPDATE olist_cleaned_orders
SET customer_city= LOWER(TRIM(customer_city));

-- simple accent removal for common brazillian city characters
UPDATE olist_cleaned_orders
SET customer_city = REPLACE(customer_city, 'sÃ£o paulo', 'sao paulo')
WHERE customer_city IS NOT NULL;

UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE (geolocation_city, 'sÃ£o paulo','sao paulo')
WHERE geolocation_city IS NOT NULL;

-- 7. Remove logical errors: Delivery date cannot be before the purchase date
DELETE FROM olist_orders_dataset
WHERE order_delivered_customer_date<order_purchase_timestamp;

-- Create some metrics
-- add a column for delivery lead time (in days)
ALTER TABLE olist_cleaned_orders
ADD COLUMN delivery_days INT;

UPDATE olist_cleaned_orders
SET delivery_days = DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
WHERE order_delivered_customer_date IS NOT NULL;
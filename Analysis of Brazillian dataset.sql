-- ANALYSIS OF THE DATASET

-- 1. Geographic Revenue Concentration
-- Business Question: Which are the top 5 states contributing the highest total revenue, and how does their average order value (AOV) compare?

SELECT 
    c.customer_state,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS average_order_value,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 5;

-- 2. Delivery Efficiency vs. Geography
-- Business Question: What is the average "delivery friction" (difference between estimated and actual delivery date) per state?
SELECT 
    c.customer_state,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 2) AS avg_days_diff
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_days_diff DESC;

-- 3. High-Value Product Category Distribution
-- Business Question: Which product categories generate the most revenue, and what is the average number of items per order in those categories?
SELECT 
    t.product_category_name_english,
    COUNT(oi.order_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- 4. Customer Retention & Loyalty
-- Business Question: How many customers have made more than one purchase, and what is the "Repeat Purchase Rate"?
WITH CustomerPurchases AS (
    SELECT 
        customer_unique_id, 
        COUNT(order_id) AS order_count
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY customer_unique_id
)
SELECT 
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate_percentage
FROM CustomerPurchases;

-- 5. Seller Performance and Geography
-- Business Question: Are sellers concentrated in the same states as customers, or are we dealing with high cross-state shipping costs?
SELECT 
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS seller_count,
    ROUND(SUM(oi.price), 2) AS total_sales_volume
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY seller_count DESC;

-- 6. Freight Impact on Conversion
-- Business Question: What is the average freight-to-price ratio for each state?
SELECT 
    c.customer_state,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(AVG(oi.freight_value / oi.price) * 100, 2) AS freight_ratio_percentage
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY freight_ratio_percentage DESC;

-- 7. Payment Preference Trends
-- Business Question: What is the most popular payment method by order volume, and which method leads to the highest transaction value?
SELECT 
    payment_type,
    COUNT(order_id) AS count_of_transactions,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY count_of_transactions DESC;

-- 8. Seasonality and Order Growth
-- Business Question: What is the month-over-month (MoM) growth in order volume and revenue across the entire timeframe?
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month_year,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS monthly_revenue
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month_year
ORDER BY month_year;
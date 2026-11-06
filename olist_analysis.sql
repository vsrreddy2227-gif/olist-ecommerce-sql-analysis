### Data Base - Olist
### Datasource - Kaggle - olist_E_Commerce
### Rules - Revenue means sum of item price excluding freight, and only delivered orders unless stated.


##-----1. Monthly revenue and orders (aggregation, date functions)
Select date_format(o.order_purchase_timestamp, '%Y-%m') As order_month,
count(Distinct o.order_id) as orders, round(sum(oi.price),2) as Revenue from orders o 
join order_items oi on oi.order_id = o.order_id WHERE o.order_status = 'delivered'
GROUP BY order_month ORDER BY order_month;

##-----2. Top 10 product categories by revenue (multi-table joins, LEFT JOIN, COALESCE)
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
COUNT(DISTINCT oi.order_id) AS orders, ROUND(SUM(oi.price), 2) AS revenue FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category ORDER BY revenue DESC LIMIT 10;


###----3. Delivery time vs estimate by customer state (date math, conditional average)
SELECT c.customer_state, COUNT(*) AS delivered_orders,
ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)), 1) AS avg_estimated_days,
ROUND(100 * AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date), 1) AS pct_late
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state HAVING COUNT(*) >= 100 ORDER BY pct_late DESC;

###---4. Late delivery rate by seller (CTE, HAVING)
WITH seller_orders AS
(SELECT DISTINCT oi.seller_id, o.order_id,
(o.order_delivered_customer_date > o.order_estimated_delivery_date) AS is_late FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL)
SELECT seller_id, COUNT(*) AS orders, ROUND(100 * AVG(is_late), 1) AS pct_late FROM seller_orders
GROUP BY seller_id HAVING COUNT(*) >= 50 ORDER BY pct_late DESC LIMIT 10;

###----5. Does late delivery hurt review scores? (CASE, CTE, pre-aggregation to avoid duplicates)
WITH r AS (
  SELECT order_id, AVG(review_score) AS score FROM reviews GROUP BY order_id)
  SELECT CASE
  WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN '1. On time or early'
WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 7 THEN '2. 1-7 days late'
ELSE '3. 8+ days late'
END AS delivery_bucket, COUNT(*) AS orders, ROUND(AVG(r.score), 2) AS avg_review_score
FROM orders o
JOIN r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_bucket ORDER BY delivery_bucket;

###----6. Repeat vs one-time customers (CTE, window function over an aggregate)
WITH cust AS (
SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS orders FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' GROUP BY c.customer_unique_id)
SELECT CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
COUNT(*) AS customers,
ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM cust
GROUP BY customer_type;

###----7. Month-over-month revenue growth (LAG)
WITH monthly AS (SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
SUM(oi.price) AS revenue FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered' GROUP BY order_month)
SELECT order_month,ROUND(revenue, 2) AS revenue,ROUND (100 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
/ LAG(revenue) OVER (ORDER BY order_month), 1) AS mom_growth_pct FROM monthly 
ORDER BY order_month;

###-----8. Top 3 sellers in each state (RANK, PARTITION BY)
WITH seller_rev AS (
select s.seller_state, s.seller_id, ROUND(SUM(oi.price), 2) AS revenue FROM order_items oi
JOIN sellers s ON s.seller_id = oi.seller_id JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered' GROUP BY s.seller_state, s.seller_id),
ranked AS (SELECT *, RANK() OVER (PARTITION BY seller_state ORDER BY revenue DESC) AS rnk FROM seller_rev)
Select * from ranked where rnk<= 3 
ORDER BY seller_state, rnk;

###----9. Customer segments with an RFM-style analysis (multiple CTEs, NTILE)
WIth base as
(SELECT c.customer_unique_id,DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders),
MAX(o.order_purchase_timestamp)) AS recency_days, COUNT(DISTINCT o.order_id) AS frequency,
SUM(oi.price) AS monetary FROM customers c
JOIN orders o ON o.customer_id = c.customer_id JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered' GROUP BY c.customer_unique_id),
scored AS (SELECT *,NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
NTILE(4) OVER (ORDER BY monetary) AS m_score FROM base)
SELECT CASE
         WHEN frequency > 1 AND r_score >= 3 THEN 'Loyal / recent repeat'
         WHEN r_score = 4 AND m_score >= 3 THEN 'Recent high spenders'
         WHEN r_score = 1 THEN 'Lapsed' ELSE 'Other' END AS segment,
         COUNT(*) AS customers, ROUND(AVG(monetary), 2) AS avg_spend
FROM scored GROUP BY segment ORDER BY customers DESC;

###------10. Payment type share and installments (aggregation over a window)
SELECT payment_type,COUNT(DISTINCT order_id) AS orders,ROUND(SUM(payment_value), 2) AS total_value,
ROUND(100 * SUM(payment_value) / SUM(SUM(payment_value)) OVER (), 1) AS pct_of_value,
ROUND(AVG(payment_installments), 1) AS avg_installments
FROM payments
GROUP BY payment_type ORDER BY total_value DESC;

         
         

-- Calculate the average payment value for each payment type.
-- Round the average payment value to the nearest integer
-- and display the results in ascending order.

SELECT
    payment_type,
    ROUND(AVG(payment_value), 0) AS rounded_avg_payment
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment;
-- Calculate the percentage of total orders for each payment type.
-- Round the percentage to one decimal place
-- and display the results in descending order.

SELECT
    payment_type,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM amazon_brazil.payments),
        1
    ) AS percentage_orders
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY percentage_orders DESC; 

-- Find products priced between 100 and 500 BRL
-- whose category name contains the word 'smart'.
-- Display the product ID and price in descending order.

SELECT
    oi.product_id,
    oi.price
FROM amazon_brazil.order_items oi
INNER JOIN amazon_brazil.product p
ON oi.product_id = p.product_id
WHERE oi.price BETWEEN 100 AND 500
AND LOWER(p.product_category_name) LIKE '%smart%'
ORDER BY oi.price DESC;

-- Determine the top 3 months with the highest total sales value.
-- Round the total sales to the nearest integer.

SELECT
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value), 0) AS total_sales
FROM amazon_brazil.orders o
INNER JOIN amazon_brazil.payments p
ON o.order_id = p.order_id
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY total_sales DESC
LIMIT 3;


-- Find product categories where the difference between
-- the maximum and minimum product prices is greater than 500 BRL.

SELECT
    p.product_category_name,
    MAX(oi.price) - MIN(oi.price) AS price_difference
FROM amazon_brazil.product p
INNER JOIN amazon_brazil.order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
HAVING MAX(oi.price) - MIN(oi.price) > 500
ORDER BY price_difference DESC;


-- Find the payment types with the least variation in transaction amounts.
-- Calculate the standard deviation of payment values
-- and display the results in ascending order.

SELECT
    payment_type,
    ROUND(STDDEV(payment_value), 2) AS std_deviation
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY std_deviation;

-- Retrieve products where the product category name
-- is missing or contains only a single character.

SELECT
    product_id,
    product_category_name
FROM amazon_brazil.product
WHERE product_category_name IS NULL
   OR LENGTH(TRIM(product_category_name)) = 1;


   -- Segment order values into Low, Medium, and High.
-- Count the number of each payment type within each segment.
SELECT
    CASE
        WHEN payment_value < 200 THEN 'Low (<200 BRL)'
        WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium (200-1000 BRL)'
        ELSE 'High (>1000 BRL)'
    END AS order_value_segment,
    payment_type,
    COUNT(*) AS count
FROM amazon_brazil.payments
GROUP BY
    CASE
        WHEN payment_value < 200 THEN 'Low (<200 BRL)'
        WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium (200-1000 BRL)'
        ELSE 'High (>1000 BRL)'
    END,
    payment_type
ORDER BY count DESC;


-- Calculate the minimum, maximum, and average price
-- for each product category and sort by average price.

SELECT
    p.product_category_name,
    MIN(oi.price) AS min_price,
    MAX(oi.price) AS max_price,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM amazon_brazil.product p
INNER JOIN amazon_brazil.order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC;




-- Find customers who have placed more than one order.
-- Display their customer unique ID and total number of orders.

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM amazon_brazil.customers c
INNER JOIN amazon_brazil.orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;


-- Categorize customers as New, Returning, or Loyal
-- based on the number of orders using a temporary table (CTE).

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM amazon_brazil.customers c
    INNER JOIN amazon_brazil.orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    CASE
        WHEN order_count = 1 THEN 'New'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Returning'
        ELSE 'Loyal'
    END AS customer_type
FROM customer_orders
ORDER BY customer_unique_id;




-- Calculate the total revenue for each product category.
-- Display the top 5 product categories by total revenue.

SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM amazon_brazil.product p
INNER JOIN amazon_brazil.order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;



-- Calculate total sales for each season
-- using a subquery based on order purchase dates.

SELECT
    season,
    ROUND(SUM(payment_value), 2) AS total_sales
FROM
(
    SELECT
        p.payment_value,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3,4,5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6,7,8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9,10,11) THEN 'Autumn'
            ELSE 'Winter'
        END AS season
    FROM amazon_brazil.orders o
    INNER JOIN amazon_brazil.payments p
        ON o.order_id = p.order_id
) AS seasonal_sales
GROUP BY season
ORDER BY total_sales DESC;



-- Find products whose total quantity sold
-- is greater than the overall average quantity sold.

SELECT
    product_id,
    total_quantity_sold
FROM
(
    SELECT
        product_id,
        COUNT(*) AS total_quantity_sold
    FROM amazon_brazil.order_items
    GROUP BY product_id
) product_sales
WHERE total_quantity_sold >
(
    SELECT AVG(product_count)
    FROM
    (
        SELECT COUNT(*) AS product_count
        FROM amazon_brazil.order_items
        GROUP BY product_id
    ) avg_sales
)
ORDER BY total_quantity_sold DESC;  




-- Calculate total monthly revenue for the year 2018.

SELECT
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM amazon_brazil.orders o
INNER JOIN amazon_brazil.payments p
    ON o.order_id = p.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY month;



-- Classify customers into Occasional, Regular, and Loyal
-- using a CTE and count customers in each segment.

WITH customer_segments AS
(
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM amazon_brazil.customers c
    INNER JOIN amazon_brazil.orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN order_count BETWEEN 1 AND 2 THEN 'Occasional'
        WHEN order_count BETWEEN 3 AND 5 THEN 'Regular'
        ELSE 'Loyal'
    END AS customer_type,
    COUNT(*) AS count
FROM customer_segments
GROUP BY customer_type
ORDER BY count DESC;


-- Rank customers based on their average order value.
-- Display the top 20 customers.

WITH customer_avg AS
(
    SELECT
        o.customer_id,
        ROUND(AVG(p.payment_value), 2) AS avg_order_value
    FROM amazon_brazil.orders o
    INNER JOIN amazon_brazil.payments p
        ON o.order_id = p.order_id
    GROUP BY o.customer_id
)

SELECT
    customer_id,
    avg_order_value,
    RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM customer_avg
ORDER BY customer_rank
LIMIT 20;




-- Calculate monthly cumulative sales for each product.

WITH monthly_sales AS
(
    SELECT
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS sale_month,
        SUM(oi.price) AS monthly_sales
    FROM amazon_brazil.order_items oi
    INNER JOIN amazon_brazil.orders o
        ON oi.order_id = o.order_id
    GROUP BY
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date
)

SELECT
    product_id,
    sale_month,
    SUM(monthly_sales) OVER
    (
        PARTITION BY product_id
        ORDER BY sale_month
    ) AS total_sales
FROM monthly_sales
ORDER BY product_id, sale_month;



-- Calculate monthly sales and month-over-month growth
-- for each payment type in the year 2018.

WITH monthly_sales AS
(
    SELECT
        p.payment_type,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS sale_month,
        SUM(p.payment_value) AS monthly_total
    FROM amazon_brazil.orders o
    INNER JOIN amazon_brazil.payments p
        ON o.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
    GROUP BY
        p.payment_type,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date
)

SELECT
    payment_type,
    sale_month,
    ROUND(monthly_total, 2) AS monthly_total,

    ROUND(
        (
            monthly_total -
            LAG(monthly_total) OVER
            (
                PARTITION BY payment_type
                ORDER BY sale_month
            )
        )
        /
        NULLIF(
            LAG(monthly_total) OVER
            (
                PARTITION BY payment_type
                ORDER BY sale_month
            ),
            0
        )
        * 100,
        2
    ) AS monthly_change

FROM monthly_sales
ORDER BY payment_type, sale_month;













     



   
   








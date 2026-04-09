/* =====================
 join dim tables to create master order table
====================== */

CREATE OR REPLACE VIEW fact_sales AS
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.company_name,
    p.product_id,
    p.product_name,
    p.category_id,
    od.quantity,
    od.unit_price,
    od.discount,
    od.unit_price * od.quantity * (1 - od.discount) AS revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_details od
    ON o.order_id = od.order_id
JOIN products p
    ON od.product_id = p.product_id;

/* Q.1 - 10 latest orders */
SELECT DISTINCT
order_id,
company_name,
order_date
FROM fact_sales
ORDER BY order_date DESC
LIMIT 10;

/* Q.2 - total # order per each customer */
SELECT
	ROW_NUMBER() OVER (ORDER BY total_orders DESC) AS cus_rank,
	customer_id, company_name, total_orders
FROM (
	SELECT customer_id, company_name,
	COUNT(DISTINCT order_id) AS total_orders
	FROM fact_sales
	GROUP BY customer_id, company_name
	) AS t
ORDER BY 4 DESC;

/* Q.3 - total revenue by product ID */
SELECT *,
		ROUND(SUM(revenue) OVER(),2) AS total_revenue,
        ROUND(revenue / SUM(revenue) OVER () * 100,2) AS revenue_pct
FROM (
	SELECT 
		product_id,
		product_name,
        SUM(quantity) AS total_sold,
        SUM(revenue) AS revenue
	FROM fact_sales
    GROUP BY product_id, product_name
    ) r
ORDER BY revenue DESC;

/* Q.4 - Revenue by product category */
SELECT
	f.category_id,
	c.category_name,
	ROUND(SUM(f.revenue),2) AS category_revenue,
    ROUND(
        SUM(f.revenue) /
        SUM(SUM(f.revenue)) OVER () * 100, 2
    ) AS revenue_pct
FROM fact_sales f
JOIN categories c
ON f.category_id = c.category_id
GROUP BY 1,2
ORDER BY category_revenue DESC;

/* Q.5 - Best-seller of each category */
SELECT *
FROM (
    SELECT
    f.category_id,
    c.category_name,
    f.product_name,
    SUM(f.quantity) AS total_quantity,
    RANK() OVER(
        PARTITION BY f.category_id
        ORDER BY SUM(f.quantity) DESC
    ) AS rnk
    FROM fact_sales f
    JOIN categories c
    ON f.category_id = c.category_id
    GROUP BY f.category_id, c.category_name, f.product_name
) t
WHERE rnk = 1;
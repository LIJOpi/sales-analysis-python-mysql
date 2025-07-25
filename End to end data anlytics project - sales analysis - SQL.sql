CREATE DATABASE mynewprojectsdb;
SELECT database();

SHOW TABLES;

CREATE TABLE `orders` (
  `order_id` int NOT NULL,
  `order_date` date DEFAULT NULL,
  `ship_mode` varchar(20) DEFAULT NULL,
  `segment` varchar(20) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `city` varchar(20) DEFAULT NULL,
  `state` varchar(20) DEFAULT NULL,
  `postal_code` int DEFAULT NULL,
  `region` varchar(10) DEFAULT NULL,
  `category` varchar(20) DEFAULT NULL,
  `sub_category` varchar(20) DEFAULT NULL,
  `product_id` varchar(20) DEFAULT NULL,
  `quantity` int DEFAULT NULL,
  `discount` decimal(7,2) DEFAULT NULL,
  `sale_price` decimal(7,2) DEFAULT NULL,
  `profit` decimal(7,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM orders;

-- find top 10 highest reveue generating products 
SELECT product_id, SUM(quantity*sale_price) as revenue
FROM orders
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;

-- find top 5 highest selling products in each region
WITH cte as(
SELECT region, product_id, SUM(quantity*sale_price) as revenue
FROM orders
GROUP BY region, product_id
)
SELECT *
FROM (SELECT*,
ROW_NUMBER() OVER(PARTITION BY region ORDER BY revenue) as rn
FROM cte) as ranked
WHERE rn<=5;

-- find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
SELECT*
FROM orders;

WITH cte as (
SELECT
year(order_date) as order_year,
month(order_date) as order_month,
SUM(quantity*sale_price) as revenue
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month
)
SELECT
order_month,
SUM(CASE WHEN order_year=2022 THEN revenue ELSE 0 end) as 2022_revenue,
SUM(CASE WHEN order_year=2023 THEN revenue ELSE 0 end) as 2023_revenue
FROM cte
GROUP BY order_month
ORDER BY order_month;

-- for each category which month had highest sales 
SELECT*
FROM orders;

WITH cte2022 as (
SELECT category,
monthname(order_date) as order_month_2022,
SUM(sale_price*quantity) as revenue_2022,
rank() OVER(PARTITION BY category order by SUM(sale_price*quantity) desc) as rn22
FROM orders
WHERE year(order_date)=2022
GROUP BY category, order_month_2022
),
cte2023 as (
SELECT category,
monthname(order_date) as order_month_2023,
SUM(sale_price*quantity) as revenue_2023,
rank() OVER(PARTITION BY category order by SUM(sale_price*quantity) desc) as rn23
FROM orders
WHERE year(order_date)=2023
GROUP BY category, order_month_2023
)
SELECT
c1.category,
c1.order_month_2022 as top_2022_month,
c1.revenue_2022,
c2.order_month_2023 as top_2023_month,
c2.revenue_2023
FROM cte2022 c1
LEFT JOIN cte2023 c2
ON c1.category=c2.category
WHERE c1.rn22=1
AND c2.rn23=1;


-- which sub category had highest growth by profit in 2023 compare to 2022

WITH cte1 AS(
SELECT sub_category,
sum(profit) as profit_2022,
rank() OVER(ORDER BY sum(profit) DESC) as rn22
FROM orders
WHERE year(order_date)=2022
GROUP BY sub_category
),
cte2 AS(
SELECT sub_category,
sum(profit) as profit_2023,
rank() OVER(ORDER BY sum(profit) DESC) as rn23
FROM orders
WHERE year(order_date)=2023
GROUP BY sub_category
)
SELECT
c1.sub_category,
c1.profit_2022,
c2.profit_2023,
ROUND(
  (COALESCE(c2.profit_2023, 0) - COALESCE(c1.profit_2022, 0)) / NULLIF(c1.profit_2022, 0) * 100,
  2
) AS profit_growth_percentage
FROM cte1 c1
LEFT JOIN cte2 c2
ON c1.sub_category=c2.sub_category
ORDER BY profit_growth_percentage DESC
LIMIT 5;













-- =============================================================
-- Retail Sales Analysis  |  Oracle SQL (Oracle Database 12c+)
-- =============================================================

-- Table setup
-- Oracle has no TIME type, so sale_time is stored as 'HH24:MI:SS' text.
CREATE TABLE retail_sales
(
    transactions_id  NUMBER(10)    PRIMARY KEY,
    sale_date        DATE,
    sale_time        VARCHAR2(8),
    customer_id      NUMBER(10),
    gender           VARCHAR2(10),
    age              NUMBER(3),
    category         VARCHAR2(35),
    quantity         NUMBER(5),
    price_per_unit   NUMBER(10,2),
    cogs             NUMBER(10,2),
    total_sale       NUMBER(10,2)
);


-- =============================================================
-- Exploration
-- =============================================================

SELECT COUNT(*) AS total_records FROM retail_sales;

SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM retail_sales;

SELECT DISTINCT category FROM retail_sales;


-- =============================================================
-- Data cleaning: find and remove rows with missing values
-- =============================================================

SELECT *
FROM retail_sales
WHERE sale_date      IS NULL
   OR sale_time      IS NULL
   OR customer_id    IS NULL
   OR gender         IS NULL
   OR age            IS NULL
   OR category       IS NULL
   OR quantity       IS NULL
   OR price_per_unit IS NULL
   OR cogs           IS NULL;

DELETE FROM retail_sales
WHERE sale_date      IS NULL
   OR sale_time      IS NULL
   OR customer_id    IS NULL
   OR gender         IS NULL
   OR age            IS NULL
   OR category       IS NULL
   OR quantity       IS NULL
   OR price_per_unit IS NULL
   OR cogs           IS NULL;

COMMIT;


-- =============================================================
-- Business questions
-- =============================================================

-- 1. All sales made on 2022-11-05
SELECT *
FROM retail_sales
WHERE sale_date = DATE '2022-11-05';


-- 2. Clothing transactions with quantity >= 4 in November 2022
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
  AND TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
  AND quantity >= 4;


-- 3. Total sales and order count per category
SELECT category,
       SUM(total_sale) AS net_sale,
       COUNT(*)        AS total_orders
FROM retail_sales
GROUP BY category;


-- 4. Average age of customers who bought from 'Beauty'
SELECT ROUND(AVG(age), 2) AS avg_age
FROM retail_sales
WHERE category = 'Beauty';


-- 5. Transactions where total_sale is greater than 1000
SELECT *
FROM retail_sales
WHERE total_sale > 1000;


-- 6. Number of transactions by gender in each category
SELECT category,
       gender,
       COUNT(*) AS total_trans
FROM retail_sales
GROUP BY category, gender
ORDER BY category;


-- 7. Average sale per month, and the best-selling month in each year
SELECT sale_year,
       sale_month,
       avg_sale
FROM (
    SELECT EXTRACT(YEAR  FROM sale_date) AS sale_year,
           EXTRACT(MONTH FROM sale_date) AS sale_month,
           AVG(total_sale)               AS avg_sale,
           RANK() OVER (
               PARTITION BY EXTRACT(YEAR FROM sale_date)
               ORDER BY AVG(total_sale) DESC
           )                             AS rnk
    FROM retail_sales
    GROUP BY EXTRACT(YEAR FROM sale_date),
             EXTRACT(MONTH FROM sale_date)
) t1
WHERE rnk = 1;


-- 8. Top 5 customers by total sales
SELECT customer_id,
       SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY total_sales DESC
FETCH FIRST 5 ROWS ONLY;


-- 9. Unique customers who bought from each category
SELECT category,
       COUNT(DISTINCT customer_id) AS cnt_unique_cs
FROM retail_sales
GROUP BY category;


-- 10. Orders per shift (Morning < 12, Afternoon 12-17, Evening > 17)
WITH hourly_sales AS (
    SELECT r.*,
           CASE
               WHEN TO_NUMBER(SUBSTR(sale_time, 1, 2)) < 12 THEN 'Morning'
               WHEN TO_NUMBER(SUBSTR(sale_time, 1, 2)) BETWEEN 12 AND 17 THEN 'Afternoon'
               ELSE 'Evening'
           END AS shift
    FROM retail_sales r
)
SELECT shift,
       COUNT(*) AS total_orders
FROM hourly_sales
GROUP BY shift;

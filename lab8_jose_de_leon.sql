--Part 1: Complete the CTE, BI and Git tasks

-- Task 1: Single CTE
-- Goal: customers whose total spend is above the average of all customer totals
WITH customer_totals AS (
    -- Total spend per customer
    SELECT customer_id, SUM(amount) AS total_spent
    FROM `Sakila.payment`
    GROUP BY customer_id
)
SELECT
    ct.customer_id, c.first_name, c.last_name,
    ROUND(ct.total_spent, 2) AS total_spent
FROM customer_totals AS ct
JOIN `Sakila.customer` AS c
    ON ct.customer_id = c.customer_id
WHERE ct.total_spent > (SELECT AVG(total_spent) FROM customer_totals)
ORDER BY ct.total_spent DESC;


-- Task 2. Chained CTEs
--Question: top five stores by number of above-average-spending customers, with each store's revenue from those customers.
WITH customer_totals AS (
    -- total spend per customer
    SELECT customer_id,SUM(amount) AS total_spent
    FROM `Sakila.payment`
    GROUP BY customer_id
),
overall_average AS (
    -- one number, the average customer total
    SELECT AVG(total_spent) AS avg_customer_spend
    FROM customer_totals
),
above_average_customers AS (
    -- overall_average has one row, so CROSS JOIN attaches it to every customer
    SELECT ct.customer_id,ct.total_spent
    FROM customer_totals AS ct
    CROSS JOIN overall_average AS oa
    WHERE ct.total_spent > oa.avg_customer_spend
),
above_average_by_store AS (
    -- attach each customer's home store and its location
    SELECT s.store_id,ci.city AS store_city, aac.customer_id,aac.total_spent
    FROM above_average_customers AS aac
    JOIN `Sakila.customer` AS cu ON aac.customer_id = cu.customer_id
    JOIN `Sakila.store`    AS s  ON cu.store_id     = s.store_id
    JOIN `Sakila.address`  AS a  ON s.address_id    = a.address_id
    JOIN `Sakila.city`     AS ci ON a.city_id       = ci.city_id
)
-- aggregate by store, rank, keep top five
SELECT store_id, store_city,COUNT(DISTINCT customer_id) AS above_average_customer_count,
    round(SUM(total_spent),2) AS revenue_from_above_average_customers,
    RANK() OVER (ORDER BY COUNT(DISTINCT customer_id) DESC) AS store_rank
FROM above_average_by_store
GROUP BY store_id, store_city
ORDER BY store_rank, revenue_from_above_average_customers DESC
LIMIT 5;


SELECT customer_id, node_id, start_date
  FROM dbo.customer_nodes
  ORDER BY customer_id;
  -- Remove Duplicate Rows in sql
WITH DuplicateRows AS (
    SELECT customer_id, node_id, start_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id, node_id, start_date ORDER BY (SELECT NULL)) AS RowNum
    FROM dbo.customer_nodes
)
DELETE FROM DuplicateRows WHERE RowNum > 1;



SELECT * FROM dbo.customer_transactions;
-- Check Duplicate Rows
SELECT * FROM dbo.customer_transactions;
SELECT customer_id, txn_date, txn_type, COUNT(*) as count
  FROM dbo.customer_transactions
  GROUP BY customer_id, txn_date, txn_type
  HAVING COUNT(*)>1;
-- Remove duplicate Rows
WITH DuplicateRows1 AS (
SELECT customer_id, txn_date, txn_type,txn_amount,
 ROW_NUMBER() over(PARTITION BY customer_id, txn_date, txn_type, txn_amount ORDER BY (SELECT NULL)) AS rowNumber
  from dbo.customer_transactions)
  DELETE FROM DuplicateRows1
  WHERE rowNumber>1;

SELECT COUNT(*)
  FROM dbo.customer_transactions;
SELECT *
  FROM dbo.regions;
 SELECT * FROM dbo.customer_nodes;
  -- Challenge Question
  -- Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id)
  FROM dbo.customer_nodes;
--What is the number of nodes per region?
SELECT r.region_name, COUNT(c.node_id) as nodes
  FROM customer_nodes c
  INNER JOIN regions r
  ON c.region_id = r.region_id
  GROUP BY r.region_name;
--How many customers are allocated to each region?
SELECT r.region_name, COUNT(DISTINCT c.customer_id) as customers
  FROM customer_nodes c
  INNER JOIN regions r
  ON c.region_id = r.region_id
  GROUP BY r.region_name;

--How many days on average are customers reallocated to a different node?
SELECT AVG(DATEDIFF(DAY, start_date, end_date)) AS avg_days
  FROM customer_nodes
  WHERE end_date != '9999-12-31';
--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH date_diff AS(
SELECT  c.customer_id,
		r.region_name,
		r.region_id,
		DATEDIFF(DAY, start_date, end_date) AS reallocation_days
  FROM customer_nodes c
  INNER JOIN regions r
  ON c.region_id = r.region_id
  WHERE end_date != '9999-12-31'
  )
SELECT DISTINCT region_id,
	   region_name,
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reallocation_days) OVER (PARTITION BY region_name ) AS median_days,
	   PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY reallocation_days) OVER (PARTITION BY region_name ) AS eighty_perc_days,
	   PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY reallocation_days) OVER (PARTITION BY region_name ) AS nine5_perc_days
  FROM date_diff
  ORDER BY region_name;

--B. Customer Transactions
--What is the unique count and total amount for each transaction type?
SELECT txn_type, 
		COUNT(*) AS unique_transactions,
		SUM(txn_amount) AS total_amount
  FROM customer_transactions
  GROUP BY txn_type;
--What is the average total historical deposit counts and amounts for all customers?
WITH customer_deposits AS (
SELECT  customer_id,
		COUNT(txn_type) as deposit_count,
		SUM(txn_amount) as deposit_amount
FROM customer_transactions
WHERE txn_type='deposit'
GROUP BY customer_id
)
 SELECT 
		AVG(deposit_count) AS avg_count,
		AVG(deposit_amount) AS avg_amount
	FROM customer_deposits;

--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customer_trends AS (
SELECT customer_id,
	   DATEPART(MONTH, txn_date) AS month_id,
	   DATENAME(MONTH, txn_date) AS month_name,
	   COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
	   COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
	   COUNT(CASE WHEN txn_type='withdrawal' THEN 1 END) AS withdrawal_count
FROM customer_transactions
GROUP BY customer_id, DATEPART(MONTH, txn_date),DATENAME(MONTH, txn_date)
)
SELECT  month_id,
		month_name,
		COUNT(DISTINCT customer_id) AS total_customers
	FROM customer_trends
	WHERE deposit_count>1 AND (purchase_count>0 OR withdrawal_count>0)
	GROUP BY month_id, month_name
	ORDER BY month_id, month_name;
;
--What is the closing balance for each customer at the end of the month?
WITH cashflows AS
(SELECT customer_id,
		DATENAME(MONTH, txn_date) AS month_name,
		SUM( CASE WHEN txn_type='deposit' THEN txn_amount ELSE -txn_amount END) AS inflow
 FROM customer_transactions
 GROUP BY customer_id, DATENAME(MONTH, txn_date)

 )
 SELECT customer_id, 
		month_name, 
		SUM(inflow) OVER (PARTITION BY customer_id ORDER BY month_name ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
   FROM cashflows
   GROUP BY customer_id, month_name, inflow
   ORDER BY customer_id;
 ;

--What is the percentage of customers who increase their closing balance by more than 5%?
WITH cashflows AS
(SELECT customer_id,
		DATENAME(MONTH, txn_date) AS month_name,
		SUM( CASE WHEN txn_type='deposit' THEN txn_amount ELSE -txn_amount END) AS inflow
 FROM customer_transactions
 GROUP BY customer_id, DATENAME(MONTH, txn_date)
),
ClosingBalance AS(
SELECT customer_id, 
		month_name, 
		SUM(inflow) OVER (PARTITION BY customer_id ORDER BY month_name ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
   FROM cashflows
   GROUP BY customer_id, month_name, inflow
   
),
PercentChange AS(
SELECT customer_id,
		month_name,
		closing_balance,
		100 * (closing_balance - LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month_name))/NULLIF(LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY month_name), 2) AS percent_increase
FROM ClosingBalance
)
SELECT 100* COUNT(DISTINCT customer_id)/ CAST((SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS float) AS percent_customers
  FROM PercentChange
  WHERE percent_increase>5;


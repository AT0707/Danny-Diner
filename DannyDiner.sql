-- Use the database 

USE DannyDiner;


CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

-- Import Data 

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


SELECT * FROM DannyDiner.dbo.members 
SELECT * FROM DannyDiner.dbo.menu
SELECT * FROM DannyDiner.dbo.sales 


-- What is the total amount each customer spent at the restaurant? 
SELECT customer_id, SUM(price) as total_amount 
FROM DannyDiner.dbo.sales 
INNER JOIN DannyDiner.dbo.menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- How many days has each customer visited the restuarant? 
SELECT customer_id, COUNT(DISTINCT order_date) as number_of_visits  
FROM DannyDiner.dbo.sales 
GROUP BY customer_id;

-- What was the first item from the menu purchased by each customer? 
WITH FirstPurchase AS (
SELECT customer_id, product_name, 
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS purchase_rank 
FROM DannyDiner.dbo.sales
INNER JOIN DannyDiner.dbo.menu
ON sales.product_id = menu.product_id)

SELECT customer_id, product_name 
FROM FirstPurchase
WHERE purchase_rank = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers? 

 -- Most Purchased Item
SELECT product_name, COUNT(sales.product_id) AS NumberOfPurchases
FROM DannyDiner.dbo.menu
INNER JOIN DannyDiner.dbo.sales
ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY NumberOfPurchases DESC
OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;


-- Most purchased item by customer.
SELECT customer_id, COUNT(product_name) as NumberOfPurchases
FROM DannyDiner.dbo.sales
INNER JOIN DannyDiner.dbo.menu
ON sales.product_id = menu.product_id 
WHERE product_name = 'ramen'
GROUP BY customer_id;

-- Which item was purchased first by the customer after they became a member? 

WITH MemberOrder AS (
SELECT sales.customer_id, product_name,
ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY order_date) AS MemberRank
FROM DannyDiner.dbo.members
INNER JOIN DannyDiner.dbo.sales ON members.customer_id = sales.customer_id
INNER JOIN DannyDiner.dbo.menu ON sales.product_id = menu.product_id
WHERE join_date <= order_date)

SELECT customer_id, product_name 
FROM MemberOrder
WHERE MemberRank = 1;

-- Which item was purchased just before the customer became a member? 
WITH MemberOrder AS (
SELECT sales.customer_id, product_name,order_date,
ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY order_date) AS MemberRank
FROM DannyDiner.dbo.members
INNER JOIN DannyDiner.dbo.sales ON members.customer_id = sales.customer_id
INNER JOIN DannyDiner.dbo.menu ON sales.product_id = menu.product_id
WHERE join_date > order_date)

SELECT customer_id, product_name
FROM MemberOrder
ORDER BY MemberRank DESC, customer_id ASC
OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY;



-- What is the total items and amount spent for each member before they became a member? 

SELECT sales.customer_id, COUNT(sales.product_id) AS TotalNumberofItems, SUM(price) AS TotalAmount
FROM DannyDiner.dbo.menu 
INNER JOIN DannyDiner.dbo.sales ON menu.product_id = sales.product_id
INNER JOIN DannyDiner.dbo.members ON sales.customer_id = members.customer_id
WHERE join_date > order_date
GROUP BY sales.customer_id;

-- Only Customers A and B have became members, but here in C just in case. 

SELECT sales.customer_id, COUNT(sales.product_id) AS TotalNumberofItems, SUM(price) AS TotalAmount
FROM DannyDiner.dbo.sales 
INNER JOIN DannyDiner.dbo.menu ON sales.product_id = menu.product_id
WHERE customer_id = 'C'
GROUP BY customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH TotalPoints AS (
SELECT sales.customer_id, menu.product_name,
CASE WHEN menu.product_name != 'sushi' THEN price*(10)
WHEN menu.product_name = 'sushi' THEN price*(10*2)
ELSE 'There is not a price'
END AS Points 
FROM DannyDiner.dbo.sales 
INNER JOIN DannyDiner.dbo.menu on sales.product_id = menu.product_id)

SELECT customer_id, SUM(Points) AS CustomerPoints
FROM TotalPoints
GROUP BY customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - How many point do customer A and B have at the end of January? 

SELECT * 
FROM DannyDiner.dbo.sales 
INNER JOIN DannyDiner.dbo.members
ON sales.customer_id = members.customer_id
WHERE order_date BETWEEN join_date AND EOMONTH(join_date)



WITH UpdatedTotalPoints AS (
SELECT sales.customer_id, menu.product_name, order_date,
CASE 
WHEN order_date > '2021-01-31' THEN 0
WHEN menu.product_name = 'sushi' THEN price*(10*2)
WHEN order_date BETWEEN join_date AND DATEADD(Day,6,join_date) THEN price*(10*2)
WHEN menu.product_name != 'sushi' THEN price*(10)
ELSE 'N/A'
END AS Points 
FROM DannyDiner.dbo.menu 
INNER JOIN DannyDiner.dbo.sales ON menu.product_id = sales.product_id
INNER JOIN DannyDiner.dbo.members ON sales.customer_id = members.customer_id)


SELECT customer_id, SUM(Points) AS CustomerPoints
FROM UpdatedTotalPoints
GROUP BY customer_id;


-- Join All The Things: The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

WITH JoinAll AS (
SELECT sales.customer_id, order_date, product_name, price, 
CASE 
	WHEN order_date < join_date THEN 'N'
	WHEN order_date >= join_date THEN 'Y'
ELSE 'N' 
END AS member_status 
FROM DannyDiner.dbo.sales 
LEFT JOIN DannyDiner.dbo.menu on sales.product_id = menu.product_id
LEFT JOIN DannyDiner.dbo.members on members.customer_id = sales.customer_id)

SELECT * FROM JoinAll
ORDER BY customer_id, order_date;



-- 




























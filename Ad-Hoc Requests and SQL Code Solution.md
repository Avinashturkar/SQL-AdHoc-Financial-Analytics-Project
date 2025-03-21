## Ad-Hoc Requests and SQL Code Solutions

### Prerequisite - The `get_fiscal_year()` Function

**Ad-Hoc Request:** Many of the SQL queries in this project rely on a user-defined function called `get_fiscal_year()`. To ensure accurate and consistent reporting, this project utilizes `get_fiscal_year()` function. This function calculates the fiscal year from a given calendar date, based on AtliQ's specific fiscal year definition.

**SQL Query:**

```sql
CREATE FUNCTION get_fiscal_year(calendar_date DATE)
RETURNS int
DETERMINISTIC
BEGIN
DECLARE fiscal_year INT;
SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
RETURN fiscal_year;
END
```

### 1. Croma India Product Wise Sales Report

**Ad-Hoc Request:** Generate a report of individual product sales (aggregated on a monthly basis at the product code level) for Croma India customer for FY-2021 to track individual product sales and run further product analytics on it.

The report should have the following fields:
- Month
- Product Name
- Variant
- Sold Quantity
- Gross Price Per Item
- Gross Price Total

**SQL Query:**

```sql
SELECT
s.date,
s.product_code,
p.product,
p.variant,
s.sold_quantity,
g.gross_price AS gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price, 2) as gross_price_total
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=get_fiscal_year(s.date)
AND g.product_code=s.product_code
WHERE
customer_code=90002002 AND
get_fiscal_year(s.date)=2021
LIMIT 1000000;
```

### 2. Gross Monthly Total Sales Report for Croma

**Ad-Hoc Request:** Need an aggregate monthly gross sales report for Croma India customer to track how much sales this particular customer is generating for AtliQ and manage our relationships accordingly.

The report should have the following fields:
- Month
- Total gross sales amount to Croma India in this month

**SQL Query:**

```sql
SELECT
s.date,
SUM(ROUND(s.sold_quantity*g.gross_price, 2)) as monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
WHERE
customer_code=90002002
GROUP BY date;
```

### 3. Stored Procedure for Monthly Gross Sales Report

**Ad-Hoc Request:** Create a stored proc for monthly gross sales report so that a user doesn't have to manually modify the query every time. This stored proc can be run by other users too who have limited access to database and they can generate this report without needing to involve the data analytics team.

The report should have the following columns:
- Month
- Total gross sales in that month from a given customer.

**SQL Query:**

```sql
CREATE PROCEDURE get_monthly_gross_sales_for_customer(
in_customer_codes TEXT
)
BEGIN
SELECT
s.date,
SUM(ROUND(s.sold_quantity*g.gross_price, 2)) as monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON g.fiscal_year=get_fiscal_year(s.date)
AND g.product_code=s.product_code
WHERE
FIND_IN_SET(s.customer_code, in_customer_codes) > 0
GROUP BY s.date
ORDER BY s.date DESC;
END
```

### 4. Stored Procedure for Market Badge

**Ad-Hoc Request:** Create a stored procedure that can determine the market badge based on the following logic: If total sold quantity > 5 million that market is considered Gold else it is Silver.

Input:
- Market
- Fiscal Year

Output:
- Market Badge

**SQL Query:**

```sql
CREATE PROCEDURE get_market_badge(
IN in_market VARCHAR(45),
IN in_fiscal_year YEAR,
OUT out_level VARCHAR(45)
)
BEGIN
DECLARE qty INT DEFAULT 0;
IF in_market = "" THEN
SET in_market="India";
END IF;
SELECT
SUM(s.sold_quantity) INTO qty
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code=c.customer_code
WHERE
get_fiscal_year(s.date)=in_fiscal_year AND
c.market=in_market;
IF qty > 5000000 THEN
SET out_level = 'Gold';
ELSE
SET out_level = 'Silver';
END IF;
END
```

### 5. Improving Data Structure for Analysis

**Ad-Hoc Request:** To streamline queries, promote code reuse, and ensure accurate calculations, a series of database views were created. These views encapsulate the logic for calculating net sales by incorporating pre- and post-invoice discounts.

#### 5.1 Creating the `sales_preinv_discount` View

```sql
CREATE VIEW sales_preinv_discount AS
SELECT
s.date,
s.fiscal_year,
s.customer_code,
c.market,
s.product_code,
p.product,
p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN dim_product p
ON s.product_code=p.product_code
JOIN fact_gross_price g
ON g.fiscal_year=s.fiscal_year
AND g.product_code=s.product_code
JOIN fact_pre_invoice_deductions as pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=s.fiscal_year;
```

#### 5.2 Creating the `sales_postinv_discount` View

```sql
CREATE VIEW sales_postinv_discount AS
SELECT *,
ROUND(gross_price_total * (1 - pre_invoice_discount_pct / 100), 2) AS net_invoice_sales
FROM sales_preinv_discount
JOIN fact_post_invoice_deductions post
ON sales_preinv_discount.customer_code = post.customer_code
AND sales_preinv_discount.fiscal_year = post.fiscal_year;
```

#### 5.3 Creating the `net_sales` View

```sql
CREATE VIEW net_sales AS
SELECT *,
ROUND(net_invoice_sales * (1 - post_invoice_discount_pct / 100), 2) AS net_sales_amount
FROM sales_postinv_discount;
```

### 6. Top Markets, Products, Customers for a Given Financial Year

**Ad-Hoc Request:** A report is needed for top markets, products, and customers by net sales for a given financial year so that a user can have a holistic view of financial performance and can take appropriate actions to address any potential issues.

To facilitate reuse and simplify report generation, create stored procedures for each of these reports

- Report for Top Markets.
- Report for Top Products.
- Report for Top Customers.


#### 6.1 Creating Stored Procedure to Get Top n Markets by Net Sales

```sql
CREATE PROCEDURE get_top_n_markets_by_net_sales(
in_fiscal_year INT,
in_top_n INT
)
BEGIN
SELECT
market,
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM net_sales
where fiscal_year=in_fiscal_year
group by market
order by net_sales_mln desc
limit in_top_n;
END
```

#### 6.2 Creating Stored Procedure to Get Top n Customers by Net Sales

```sql
CREATE PROCEDURE get_top_n_customers_by_net_sales(
in_market VARCHAR(45),
in_fiscal_year INT,
in_top_n INT
)
BEGIN
select
customer,
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code=c.customer_code
where
s.fiscal_year=in_fiscal_year
and s.market=in_market
group by customer
order by net_sales_mln desc
limit in_top_n;
END
```

---
### 7. Net Sales % Share Global

**Ad-Hoc Request:** Develop a bar chart report to display the top 10 markets in FY-2021, ranked by their percentage contribution to total net sales.

**SQL Query:**

```sql
WITH cte1 AS (
SELECT
customer,
ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln
FROM net_sales s
JOIN dim_customer c
ON s.customer_code=c.customer_code
WHERE s.fiscal_year=2021
GROUP BY customer)
SELECT
customer,
net_sales_mln*100/SUM(net_sales_mln) OVER () AS pct_net_sales
FROM cte1
ORDER BY net_sales_mln DESC;
```

### 8. Net Sales % Share by Region

**Ad-Hoc Request:** Develop a set of pie charts showing the percentage breakdown of net sales by the top 10 customers within each region (APAC, EU, LATAM, etc.) for FY-2021.

This will enable regional analysis of company's financial performance, focusing on te key contibutors to sales in each region.

**SQL Query:**

```sql
WITH cte1 AS (
SELECT
c.customer,
c.region,
ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln
FROM net_sales n
JOIN dim_customer c
ON n.customer_code=c.customer_code
WHERE fiscal_year=2021
GROUP BY c.customer, c.region)
SELECT
region,
customer,
net_sales_mln*100/SUM(net_sales_mln) OVER (PARTITION BY region) AS pct_share_region
FROM cte1
ORDER BY region, pct_share_region DESC;
```

# Ad-Hoc Requests and SQL Code Solutions

## Prerequisite - The `get_fiscal_year()` Function

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

---

## 1. Croma India Product Wise Sales Report

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

---

## 2. Gross Monthly Total Sales Report for Croma

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

---

## 3. Stored Procedure for Monthly Gross Sales Report

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

---

## 4. Stored Procedure for Market Badge

**Ad-Hoc Request:** Create a stored procedure that can determine the market badge based on the following logic: If total sold quantity > 5 million that market is considered Gold else it is Silver.

Input will be: 
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

  # Default market is India
  IF in_market = "" THEN
    SET in_market="India";
  END IF;

  # Retrieve total sold quantity for a given market in a given year
  SELECT
    SUM(s.sold_quantity) INTO qty
  FROM fact_sales_monthly s
  JOIN dim_customer c
    ON s.customer_code=c.customer_code
  WHERE
    get_fiscal_year(s.date)=in_fiscal_year AND
    c.market=in_market;

  # Determine Gold vs Silver status
  IF qty > 5000000 THEN
    SET out_level = 'Gold';
  ELSE
    SET out_level = 'Silver';
  END IF;
END
```

---

## 5. Improving Data Structure for Analysis

### 5.1 Creating the `sales_preinv_discount` View

**Ad-Hoc Request:** To simplify calculations and create a reusable object, a view is created that encapsulates the logic for calculating gross sales and applying pre-invoice discounts. This view will be used to create further required views.

**SQL Query:**

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

---

## 6. Net Sales % Share by Region

**Ad-Hoc Request:** Develop a set of pie charts showing the percentage breakdown of net sales by the top 10 customers within each region (APAC, EU, LATAM, etc.) for FY-2021.

This will enable regional analysis of the company's financial performance, focusing on the key contributors to sales in each region.

**SQL Query:**

```sql
WITH cte1 AS (
  SELECT
    c.customer,
    c.region,
    round(sum(net_sales)/1000000,2) as net_sales_mln
  FROM net_sales n
  JOIN dim_customer c
    ON n.customer_code=c.customer_code
  WHERE fiscal_year=2021
  group by c.customer, c.region
)
SELECT
  region,
  customer,
  net_sales_mln*100/sum(net_sales_mln) OVER (PARTITION BY region) as pct_share_region
FROM cte1
order by region, pct_share_region desc;
```

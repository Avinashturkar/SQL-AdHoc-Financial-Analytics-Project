CREATE FUNCTION get_fiscal_year(calendar_date DATE)
RETURNS int
DETERMINISTIC
BEGIN
  DECLARE fiscal_year INT;
  SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
  RETURN fiscal_year;
END;

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

SELECT
  s.date,
  SUM(ROUND(s.sold_quantity*g.gross_price, 2)) as monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
  ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
WHERE
  customer_code=90002002
GROUP BY date;

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
END;

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
END;

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

CREATE VIEW sales_postinv_discount AS
SELECT
  s.date, s.fiscal_year,
  s.customer_code, s.market,
  s.product_code, s.product, s.variant,
  s.sold_quantity, s.gross_price_total,
  s.pre_invoice_discount_pct,
  (s.gross_price_total-s.pre_invoice_discount_pct*s.gross_price_total) as net_invoice_sales,
  (po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct
FROM sales_preinv_discount s
JOIN fact_post_invoice_deductions po
  ON po.customer_code = s.customer_code AND
  po.product_code = s.product_code AND
  po.date = s.date;

CREATE VIEW net_sales AS
SELECT
  *,
  net_invoice_sales*(1-post_invoice_discount_pct) as net_sales
FROM gdb0041.sales_postinv_discount;

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
END;

CREATE PROCEDURE get_top_n_customers_by_net_sales(
  in_market VARCHAR(45),
  in_fiscal_year INT,
  in_top_n INT
)
BEGIN
  select
    customer,
    round(sum(net_sales)/1000000,2) as net_sales_mln
  FROM net_sales s
  JOIN dim_customer c
    ON s.customer_code=c.customer_code
  where
    s.fiscal_year=in_fiscal_year
    and s.market=in_market
  group by customer
  order by net_sales_mln desc
  limit in_top_n;
END;

CREATE PROCEDURE get_top_n_products_by_net_sales(
  in_fiscal_year INT,
  in_top_n INT
)
BEGIN
  select
    p.product,
    round(sum(net_sales)/1000000,2) as net_sales_mln
  FROM net_sales s
  JOIN dim_product p
    ON p.product_code=s.product_code
  where fiscal_year=in_fiscal_year
  group by p.product
  order by net_sales_mln desc
  limit in_top_n;
END;

WITH cte1 AS (
  SELECT
    customer,
    round(sum(net_sales)/1000000,2) as net_sales_mln
  FROM net_sales s
  JOIN dim_customer c
    ON s.customer_code=c.customer_code
  WHERE s.fiscal_year=2021
  group by customer
)
SELECT
  customer,
  net_sales_mln*100/sum(net_sales_mln) OVER () as pct_net_sales
FROM cte1
order by net_sales_mln desc;

WITH cte1 AS (
  SELECT
    c.customer,
    c.region,
    round(sum(net_sales)/1000000,2) as net_sales_mln
  FROM gdb0041.net_sales n
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
\## Ad-Hoc Requests and SQL Code Solutions

\### Prerequisite - The \`get_fiscal_year()\` Function

\*\*Ad-Hoc Request:\*\* Many of the SQL queries in this project rely on
a user-defined function called \`get_fiscal_year()\`. To ensure accurate
and consistent reporting, this project utilizes \`get_fiscal_year()\`
function. This function calculates the fiscal year from a given calendar
date, based on AtliQ\'s specific fiscal year definition

\*\*SQL Query:\*\*

\`\`\`sql CREATE FUNCTION get_fiscal_year(calendar_date DATE) RETURNS
int DETERMINISTIC BEGIN DECLARE fiscal_year INT; SET fiscal_year =
YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH)); RETURN fiscal_year; END
Use code with caution. Markdown 1. Croma India Product Wise Sales Report
Ad-Hoc Request: Generate a report of individual product sales
(aggregated on a monthly basis at the product code level) for Croma
India customer for FY-2021 to track individual product sales and run
further product analytics on it. The report should have the following
fields: Month Product Name Variant Sold Quantity Gross Price Per Item
Gross Price Total SQL Query: SELECT s.date, s.product_code, p.product,
p.variant, s.sold_quantity, g.gross_price AS gross_price_per_item,
ROUND(s.sold_quantity\*g.gross_price, 2) as gross_price_total FROM
fact_sales_monthly s JOIN dim_product p ON s.product_code=p.product_code
JOIN fact_gross_price g ON g.fiscal_year=get_fiscal_year(s.date) AND
g.product_code=s.product_code WHERE customer_code=90002002 AND
get_fiscal_year(s.date)=2021 LIMIT 1000000; Use code with caution. SQL
2. Gross Monthly Total Sales Report for Croma Ad-Hoc Request: Need an
aggregate monthly gross sales report for Croma India customer to track
how much sales this particular customer is generating for AtliQ and
manage our relationships accordingly. The report should have the
following fields: Month Total gross sales amount to Croma India in this
month SQL Query: SELECT s.date,
SUM(ROUND(s.sold_quantity\*g.gross_price, 2)) as monthly_sales FROM
fact_sales_monthly s JOIN fact_gross_price g ON
g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
WHERE customer_code=90002002 GROUP BY date; Use code with caution. SQL
3. Stored Procedure for Monthly Gross Sales Report Ad-Hoc Request:
Create a stored proc for monthly gross sales report so that a user
doesn\'t have to manually modify the query every time. This stored proc
can be run by other users too who have limited access to database and
they can generate this report without needing to involve the data
analytics team. The report should have the following columns: Month
Total gross sales in that month from a given customer. SQL Query: CREATE
PROCEDURE get_monthly_gross_sales_for_customer( in_customer_codes TEXT )
BEGIN SELECT s.date, SUM(ROUND(s.sold_quantity\*g.gross_price, 2)) as
monthly_sales FROM fact_sales_monthly s JOIN fact_gross_price g ON
g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
WHERE FIND_IN_SET(s.customer_code, in_customer_codes) \> 0 GROUP BY
s.date ORDER BY s.date DESC; END Use code with caution. SQL 4. Stored
Procedure for Market Badge: Ad-Hoc Request: Create a stored procedure
that can determine the market badge based on the following logic: If
total sold quantity \> 5 million that market is considered Gold else it
is Silver. Input will be: market, fiscal year. Output: market badge. SQL
Query: CREATE PROCEDURE get_market_badge( IN in_market VARCHAR(45), IN
in_fiscal_year YEAR, OUT out_level VARCHAR(45) ) BEGIN DECLARE qty INT
DEFAULT 0; \# Default market is India IF in_market = \"\" THEN SET
in_market=\"India\"; END IF;

\# Retrieve total sold quantity for a given market in a given year
SELECT SUM(s.sold_quantity) INTO qty FROM fact_sales_monthly s JOIN
dim_customer c ON s.customer_code=c.customer_code WHERE
get_fiscal_year(s.date)=in_fiscal_year AND c.market=in_market;

\# Determine Gold vs Silver status IF qty \> 5000000 THEN SET out_level
= \'Gold\'; ELSE SET out_level = \'Silver\'; END IF; END Use code with
caution. SQL 5. Improving Data Structure for Analysis To streamline
queries, promote code reuse, and ensure accurate calculations, a series
of database views were created. These views encapsulate the logic for
calculating net sales by incorporating pre- and post-invoice discounts.
5.1 Creating the sales_preinv_discount View Ad-hoc request: To simplify
calculations and create a reusable object, a view is created that
encapsulates the logic for calculating gross sales and applying
pre-invoice discounts. This view will be used to create further required
views. SQL Query: CREATE VIEW sales_preinv_discount AS SELECT s.date,
s.fiscal_year, s.customer_code, c.market, s.product_code, p.product,
p.variant, s.sold_quantity, g.gross_price as gross_price_per_item,
ROUND(s.sold_quantity\*g.gross_price,2) as gross_price_total,
pre.pre_invoice_discount_pct FROM fact_sales_monthly s JOIN dim_customer
c ON s.customer_code = c.customer_code JOIN dim_product p ON
s.product_code=p.product_code JOIN fact_gross_price g ON
g.fiscal_year=s.fiscal_year AND g.product_code=s.product_code JOIN
fact_pre_invoice_deductions as pre ON pre.customer_code =
s.customer_code AND pre.fiscal_year=s.fiscal_year Use code with caution.
SQL 5.2 Creating the sales_postinv_discount View Ad-hoc request: To
extend the previous view to include post-invoice discounts and calculate
net invoice sales, a view has been created. This view will be used to
create the final view of net_sales. SQL Query: CREATE VIEW
sales_postinv_discount AS SELECT s.date, s.fiscal_year, s.customer_code,
s.market, s.product_code, s.product, s.variant, s.sold_quantity,
s.gross_price_total, s.pre_invoice_discount_pct,
(s.gross_price_total-s.pre_invoice_discount_pct\*s.gross_price_total) as
net_invoice_sales, (po.discounts_pct+po.other_deductions_pct) as
post_invoice_discount_pct FROM sales_preinv_discount s JOIN
fact_post_invoice_deductions po ON po.customer_code = s.customer_code
AND po.product_code = s.product_code AND po.date = s.date; Use code with
caution. SQL 5.3 Creating the net_sales View SQL Query: CREATE VIEW
net_sales AS SELECT \*, net_invoice_sales\*(1-post_invoice_discount_pct)
as net_sales FROM gdb0041.sales_postinv_discount; Use code with caution.
SQL 6. Top Markets, Products, Customers for a Given Financial Year
Ad-Hoc Request: A report is needed for top markets, products, and
customers by net sales for a given financial year so that a user can
have a holistic view of our financial performance and can take
appropriate actions. To facilitate reuse and simplify report generation,
stored procedures should be created for each of these reports: Report
for top markets Report for top products Report for top customers 6.1
Creating Stored Procedure to Get Top n Markets by Net Sales for a Given
Year SQL Query: CREATE PROCEDURE get_top_n\_markets_by_net_sales(
in_fiscal_year INT, in_top_n INT ) BEGIN SELECT market,
round(sum(net_sales)/1000000,2) as net_sales_mln FROM net_sales where
fiscal_year=in_fiscal_year group by market order by net_sales_mln desc
limit in_top_n; END Use code with caution. SQL 6.2 Creating Stored
Procedure to Get Top n Customers by Net Sales SQL Query: CREATE
PROCEDURE get_top_n\_customers_by_net_sales( in_market VARCHAR(45),
in_fiscal_year INT, in_top_n INT ) BEGIN select customer,
round(sum(net_sales)/1000000,2) as net_sales_mln FROM net_sales s JOIN
dim_customer c ON s.customer_code=c.customer_code where
s.fiscal_year=in_fiscal_year and s.market=in_market group by customer
order by net_sales_mln desc limit in_top_n; END Use code with caution.
SQL 6.3 Creating Stored Procedure to Get Top n Products by Net Sales SQL
Query: CREATE PROCEDURE get_top_n\_products_by_net_sales( in_fiscal_year
INT, in_top_n INT ) BEGIN select p.product,
round(sum(net_sales)/1000000,2) as net_sales_mln FROM net_sales s JOIN
dim_product p ON p.product_code=s.product_code where
fiscal_year=in_fiscal_year group by p.product order by net_sales_mln
desc limit in_top_n; END Use code with caution. SQL 7. Net Sales % Share
Global Ad-Hoc Request: Develop a bar chart report to display the top 10
markets in FY-2021, ranked by their percentage contribution to total net
sales. SQL Query: with cte1 as ( select customer,
round(sum(net_sales)/1000000,2) as net_sales_mln from net_sales s join
dim_customer c on s.customer_code=c.customer_code where
s.fiscal_year=2021 group by customer) select customer,
net_sales_mln\*100/sum(net_sales_mln) over () as pct_net_sales from cte1
order by net_sales_mln desc Use code with caution. SQL 8. Net Sales %
Share by Region Ad-Hoc Request: Develop a set of pie charts showing the
percentage breakdown of net sales by the top 10 customers within each
region (APAC, EU, LATAM, etc.) for FY-2021. This will enable regional
analysis of the company\'s financial performance, focusing on the key
contributors to sales in each region. SQL Query: with cte1 as ( select
c.customer, c.region, round(sum(net_sales)/1000000,2) as net_sales_mln
from gdb0041.net_sales n join dim_customer c on
n.customer_code=c.customer_code where fiscal_year=2021 group by
c.customer, c.region) select region, customer,
net_sales_mln\*100/sum(net_sales_mln) over (partition by region) as
pct_share_region from cte1 order by region, pct_share_region desc

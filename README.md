# AtliQ Hardware Financial Analytics Project


## Table of Contents

1.  [Project Overview](#project-overview)
2.  [Objectives](#objectives)
3.  [Problem Statement](#problem-statement)
4.  [Data Understanding](#data-understanding)
5.  [Ad-Hoc Requests and SQL Code Solutions](#ad-hoc-requests-and-sql-code-solutions)
6.  [Tools Used](#tools-used)
7.  [Demonstrated SQL Skills](#demonstrated-sql-skills)
8.  [Key Findings and Insights](#key-findings-and-insights)
9.  [Recommendations](#recommendations)
10. [Impact](#impact)
11. [Performance Improvements](#performance-improvements)
12. [Showcase](#showcase)
13. [LinkedIn](#linkedin)

## Project Overview

AtliQ Hardware is a prominent player in the computer hardware industry, offering a diverse range of products such as PCs, storage devices, peripherals, and networking equipment. With a global reach, the company serves customers through various channels, including retailers like Croma and Amazon, its own direct platforms like the AtliQ e-store and exclusive outlets, and distributors such as Neptune. Whether you're shopping in physical stores or online, AtliQ Hardware ensures its products are easily accessible through both Brick&Mortar and E-Commerce platforms.

## Problem Statement

The current sales reporting processes at AtliQ Hardware are inefficient and require significant manual effort from the data analytics team. The complex SQL queries used for analysis are difficult to maintain and execute, limiting the ability of business users to access timely and relevant sales information. The database schema requires optimization to improve query performance and enable scalable reporting.

## Objectives

This project was designed with focus on below SQL analysis area:

*   To determine the top-performing markets, products, and customers based on net sales.
*   To efficiently address specific, Ad-Hoc data requests from stakeholders.
*   To build reusable SQL components to simplify sales reporting and analysis.
*   To create stored procedures that can be executed by users with limited database access.

## Data Understanding

This project utilizes a relational database stored in a **MySQL (gdb0041)** server, and **Microsoft Excel was selected for data visualization**.

The database schema contains the following tables:

*   `dim_customer`: Customer information (customer\_code, customer, market, region, platform, channel, sub\_zone).
*   `dim_date`: Date related information (calendar\_date, fiscal\_year).
*   `dim_product`: Product information (product\_code, product, variant, division, segment, category, product\_varchar).
*   `fact_act_est`: Forecast quantity and actual sales quantity (date, fiscal\_year, product\_code, customer\_code, sold\_quantity, forecast\_quantity).
*   `fact_forecast_monthly`: Forecasted sales quantity (date, product\_code, customer\_code, forecast\_quantity).
*   `fact_freight_cost`: Freight cost data (market, fiscal\_year, freight\_pct, other\_cost\_pct).
*   `fact_gross_price`: Gross price of each product per fiscal year (product\_code, fiscal\_year, gross\_price).
*   `fact_manufacturing_cost`: Manufacturing cost data (product\_code, cost\_year, manufacturing\_cost).
*   `fact_post_invoice_deductions`: Post-invoice discounts (customer\_code, product\_code, date, discounts\_pct, other\_deductions\_pct).
*   `fact_pre_invoice_deductions`: Pre-invoice discounts per customer and fiscal year (customer\_code, fiscal\_year, pre\_invoice\_discount\_pct).
*   `fact_sales_monthly`: Core sales transaction data (date, product\_code, fiscal\_year, customer\_code, sold\_quantity).

Views used:

*   Creates three views table which helps for analytics and saves redundant calculations.

`fact sales monthly` is in main focus.

## Ad-Hoc Requests and SQL Code Solutions

The following section contains the Ad-Hoc Requests and the SQL code developed for each request.

*See the separate file: [Ad-Hoc Requests and SQL Solutions](Adhoc_Requests_And_SQL_Solutions.md) for a detailed view of the implemented solution.

## Tools Used

*   SQL (MySQL)
*   Microsoft Excel (for data visualization)

## Demonstrated SQL Skills

This project demonstrates proficiency in a range of SQL skills relevant to data analysis, including:

*   **Data Definition Language (DDL):**
    *   Created a User-Defined Function (UDF): `get_fiscal_year()` using `CREATE FUNCTION` to calculate the fiscal year from a given date.
    *   Created reusable views using `CREATE VIEW` statements to enhance data structures.
    * Created the stored procedures using create store procedure.
*   **Data Querying:**
    *   Performed complex data aggregations and transformations by:
          * Leveraging the created View tables to easily perform analysis, by selecting and calling the View tables .
             * Used `JOIN` Operations, specifically `INNER JOIN`, to combine data from multiple tables.
       * Used Aggregate Functions: `SUM()`, `AVG()`, and `ROUND()`, for calculations.
          * Utilized the User-Defined Function (UDF): `get_fiscal_year()` to convert date into fiscal year in query for generating reports.
            * Used `FIND_IN_SET` statements in SQL query
         * Applying the `WITH` Clause for performance optimization.

*   Also implemented Window Functions by partitoning with `OVER` clause for regional analytics.
      * Used String manipulation techniques, creating a `LIKE` statement for checking Croma like values and matching on values of string.
        *   Calculated date with operations such as `DATE_ADD` for calculating fiscal year..
        * Utilized Date and Time Functions such as `MONTH` for extracting month to generate different monthly report.
     * Utilized input and output parameters within the Stored Procedures.
    * Implemented control flow with if else statements for actions..
*   Used String manipulation techniques for LIKE statement.
      * Utilized Input and output parameters within the stored procedure.

## Key Findings and Insights

1.  Top Markets, Products, and Customers (from Stored Procedure Results):

    *   Market Concentration: The "get\_top\_n\_markets\_by\_net\_sales" result reveals that India and the USA are significantly larger markets for AtliQ than other regions. A substantial portion of revenue is generated from these two areas.
    *   Customer Dependency: From the get\_top\_n\_customers\_by\_net_sales screenshot, Amazon and Atliq Exclusive are key customers of atliq across the market.
    *   Dominant Products: The "get\_top\_n\_products\_by\_net_sales" result clearly identifies "AQ BZ Allin1" and "AQ Qwerty" as the top-selling products.

2.  Overall Customer Contribution (Bar Chart - "Net Sales Contribution by Customers: Top 10 (FY-2021)")

    *   Top-Heavy Revenue Distribution: The bar chart visually confirms that AtliQ Hardware's revenue is heavily weighted towards a few top customers, with Amazon and AtliQ Exclusive contributing a substantial portion of the total.
    *   Atliq Exclusive Channel : The results for Net Sales contribution by Customers show that Atliq Exclusive contribute 9.7% net sales.

3.  Regional Customer Breakdown (Pie Charts - "Net Sales % Share by Customer: NA, EU, APAC, LATAM Regions (FY 2021)")

    *   Varying Regional Dynamics: The pie charts demonstrate that the distribution of sales across customers differs considerably from region to region.

        *   Some observations:

            *   LATAM sales heavily concentrated with Amazon and Atliq E Store.
            *   North America shows a more diversified customer base compared to LATAM, but still relies on Amazon, Atliq Exclusive, Walmart and Atliq e Store.
            *   EU has wider revenue sources compared to north america and latam.
            *   APAC is dependent on Amazon and Atliq Exclusive, but it does not seem as bad as latam.

## Recommendations

Based on the findings of this analysis, I recommend that AtliQ Hardware take the following actions to improve its sales performance and strategic decision-making:

*   Prioritize Top Customer Relationships: Implement a program to proactively manage and nurture relationships with top customers, such as Croma India, Amazon, and AtliQ Exclusive. This can involve:

    *   Dedicated personnel responsible for these accounts.
    *   Regular communication and collaboration.
    *   Tailored product offerings and marketing campaigns.
    *   Monitoring customer satisfaction and loyalty.

*   Pursue Customer Diversification: Actively seek to expand the customer base beyond the top accounts by targeting new segments and markets. This could include:

    *   Expanding into new geographic regions.
    *   Establishing partnerships with distributors and resellers.

*   Customize Regional Sales Strategies: Develop region-specific sales and marketing plans that reflect the unique customer characteristics of each market.

*   Automate Performance Monitoring: Regularly monitor automated reports using the created views and stored procedures. This enables AtliQ Hardware to:

    *   Identify trends and anomalies quickly.
    *   Make decisions based on current, readily available data.

*   Refine Pricing Strategies: Re-evaluate its pricing and discount approach to make better data driven decisions.

## Impact

This data analytics project has the potential to deliver significant value to AtliQ Hardware by providing actionable insights, improving reporting efficiency, and enabling data-driven decision-making across the organization. Specifically, the implementation of the project's findings and solutions could lead to the following positive impacts:

*   Improved Strategic Decision-Making: By identifying top-performing markets, products, and customers, AtliQ Hardware can make more informed decisions about where to focus its efforts and investments.

*   Enhanced Customer Relationships: Understanding regional customer dynamics and individual customer contributions enables AtliQ to better tailor its sales and marketing activities to different customer groups.

*   Optimized Pricing Strategies: By quantifying the impact of pre- and post-invoice discounts on net sales, AtliQ can refine its pricing strategies to maximize profitability.

*   Increased Reporting Efficiency: The creation of reusable views and stored procedures streamlines the sales reporting process, reducing the time and effort required to generate key reports.

*   Democratized Data Access: By enabling users with limited database access to execute stored procedures and generate reports, AtliQ can empower business users to make data-driven decisions more easily.
*   Enhanced Scalability: By adding the `fiscal_year` column to `fact_sales_monthly`, it increases data access. Scalability ensures it can support business without performance impact.

## Performance Improvements

Several strategies were implemented to optimize the SQL queries for performance, ensuring efficient data retrieval and report generation:

*   **Adding `fiscal_year` Column:** To avoid repeatedly calculating the fiscal year using the user-defined function `get_fiscal_year()`, a `fiscal_year` column was added directly to the `fact_sales_monthly` table. This eliminated the need to execute the function for every row during querying, significantly improving query speed.

*   **Utilizing Views:** Complex calculations, such as those involving pre- and post-invoice discounts, were encapsulated within views (`sales_preinv_discount`, `sales_postinv_discount`, and `net_sales`). This approach offered several performance benefits:
    *   The views are well structured, which avoids redundant data retrieval and calculations.
    *   Precalculated table joins mean simpler queries with faster analysis.

*   **Leveraging the `WITH` Clause:** The `WITH` clause creates common table expressions (CTEs), simplifying data structure and increasing code readability, and enabling more efficient query planning and execution.

## Showcase

* A copy of the project in PPT form can also be viewed: [AtliQ Hardware Financial Analytics Project.pdf]() is available.

## LinkedIn

LinkedIn profile [Here](https://www.linkedin.com/in/your_linkedin_profile)

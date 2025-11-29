# HDI PCB Manufacturing Analytics: A Data-Driven Approach to Operational Excellence

## Objective

Analyze production, quality, and financial data from a fictional High-Density Interconnect (HDI) PCB manufacturer to uncover actionable insights for operational excellence and profitability optimization using advanced PostgreSQL.

This project demonstrates end-to-end SQL analytics: data modeling, data transformation, KPI generation, root cause analysis, and strategic profitability assessment.

---

## Data Model Overview

The analysis is built upon a robust **Star Schema** design.

| Table Type | Table Name | Key Columns | Purpose |
| :--- | :--- | :--- | :--- |
| **Fact** | `fact_production` | `order_id`, `customer_id`, `product_id`, `machine_id` | Contains production metrics, costs, revenue, and quality attributes (scrap, delay). |
| **Fact** | `fact_maintenance` | `maintenance_id`, `machine_id` | Records maintenance events, type (Corrective/Preventive), and costs. |
| **Dimension** | `dim_customer` | `customer_id` | Customer details, region, and country. |
| **Dimension** | `dim_product` | `product_id` | PCB specifications like `layer_count` and `board_complexity`. |
| **Dimension** | `dim_material` | `material_id` | Material details, supplier, and unit cost. |
| **Dimension** | `dim_machine` | `machine_id` | Machine details and maintenance cost per hour. |

---

## Tools & Techniques

- **Database:** PostgreSQL
- **Skills:** Advanced SQL (CTEs, Window Functions, Conditional Aggregation), Data Modeling, Data Transformation.
- **Data Transformation:** Applied custom SQL to introduce realistic year-over-year growth, cost reduction, and seasonality to the synthetic data.

---

## Key Analyses

| Query Section | Focus | SQL Skills Used |
| :--- | :--- | :--- |
| **Financial Overview** | Yearly Revenue, Cost, Profit, and Profit Margin % | Conditional Aggregation, `ROUND()` |
| **Trend Analysis** | Monthly Profit Trend (MoM Change and Cumulative Profit) | `LAG()` Window Function, `TO_CHAR()` |
| **Quality Control** | Most Common Scrap Reason Per Year | `ROW_NUMBER()` Window Function, CTEs |
| **Operational Impact** | Impact of Corrective Maintenance on Scrap/Delay Rates | Date Arithmetic (`INTERVAL`), Multiple CTEs |
| **Product Profitability** | Average Profit Margin by Board Complexity | `JOIN` on `dim_product`, `NULLIF()` |
| **Delivery Performance** | Percentage of Delayed Orders Grouped by Scrap Reason | `COALESCE()`, Conditional Aggregation |
| **Customer Segmentation** | Top 20 Customers by Revenue and Order Frequency | `LIMIT`, `HAVING`, `JOIN` |

---

## Key Insights

### 1. Financial & Growth Insights

- **Strong Year-over-Year (YoY) Growth:** The data shows a clear, positive trend in **Total Net Profit**, driven by a combination of increased production volume and improved cost efficiency from 2023 (Ramp-Up) to 2025 (Expansion).
- **Cost Efficiency is Key:** The **Profit Margin %** shows a significant increase over the years, confirming that process optimization and economies of scale (simulated by cost reduction) are the primary drivers of profitability.
- **Clear Seasonality:** Monthly profit trends confirm a strong **Q4 spike** (October-December) and a noticeable **Q1 slump** (January-February), which is critical for inventory and labor planning.

### 2. Quality & Operational Insights

- **Maintenance Risk:** Analysis of the **Machine Downtime Impact** reveals that orders immediately following corrective maintenance events have a **higher scrap rate** than the overall average. This suggests that post-maintenance calibration or rush to production is a significant quality risk.
- **Scrap-Delay Correlation:** The **Percentage of Delayed Orders Grouped by Scrap Reason** identifies specific quality failures that are most likely to impact delivery schedules, allowing management to prioritize fixing the most time-sensitive quality issues.
- **Remake Cost is Significant:** The accurate calculation of **Estimated Remake Cost** highlights that rework is a major hidden expense, justifying investment in preventative quality measures.

### 3. Strategic Profitability Insights

- **Complexity vs. Profit:** The analysis of **Profit Margin by Board Complexity** will reveal whether the high cost and risk associated with complex boards are justified by a proportionally higher profit margin, guiding future sales and pricing strategies.
- **Customer Value:** The **Top 20 Customers by Revenue** analysis confirms a concentration of sales, emphasizing the need for a dedicated Customer Lifetime Value (CLV) program to secure these key accounts.

---

## Recommendations for Management

- **Implement Post-Maintenance Protocol:** Introduce a mandatory, documented quality check and calibration period ( 24-48 hours) after any corrective maintenance to mitigate the observed spike in scrap rates.
- **Targeted Quality Improvement:** Focus immediate quality control efforts on the **top 2-3 scrap reasons** identified as having the highest correlation with delivery delays.
- **Strategic Pricing:** Review the pricing model for **low-complexity boards** if their profit margin is found to be disproportionately high, and consider raising prices on **high-complexity boards** if their margin does not justify the risk.

---

## Key SQL Concepts

`CTE`, `JOIN`, `RANK()`, `LAG()`, `SUM() OVER`, `NULLIF()`, `COALESCE()`, `Conditional Aggregation`, `Date Arithmetic (INTERVAL)`

---
##  Author
**Abdelkarim Mars**  
Aspiring Data Analyst | PhD in Physics | R&D Professional |
[GitHub: KarimTheAnalyst](https://github.com/KarimTheAnalyst)  
[LinkedIn](https://www.linkedin.com)




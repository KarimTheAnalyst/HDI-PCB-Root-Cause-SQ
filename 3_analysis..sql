
-- SECTION 3: PRODUCTION & FINANCIAL OVERVIEW (Yearly & Monthly)
-- 1.1 Yearly Executive Summary (Orders, Revenue, Cost, Profit, Margin)
-- This query provides the top-level performance metrics by year.
SELECT
    EXTRACT(YEAR FROM start_date) AS year,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(sales_price_per_board_usd * quantity_shipped)::numeric, 2) AS total_revenue,
    ROUND(SUM(material_cost_usd + maintenance_cost_usd + labor_cost_usd)::numeric, 2) AS total_cost,
    ROUND((SUM(sales_price_per_board_usd * quantity_shipped) - SUM(material_cost_usd + maintenance_cost_usd + labor_cost_usd))::numeric, 2) AS total_net_profit,
    ROUND(((SUM(sales_price_per_board_usd * quantity_shipped) - SUM(material_cost_usd + maintenance_cost_usd + labor_cost_usd)) * 100.0 / NULLIF(SUM(sales_price_per_board_usd * quantity_shipped), 0))::numeric, 2) AS profit_margin_percentage
FROM
    fact_production
GROUP BY
    year
ORDER BY
    year ASC;

-- 1.2 Monthly Profit Trend Analysis (MoM Change and Cumulative Profit)
-- This query directly answers the question: "Is the profit trend declining?"
WITH monthly_profit AS (
    SELECT 
        EXTRACT(YEAR FROM start_date) AS years,
        EXTRACT(MONTH FROM start_date) AS months,
        TO_CHAR(start_date, 'YYYY-MM') AS year_month,
        SUM((sales_price_per_board_usd * quantity_shipped) - (material_cost_usd + labor_cost_usd + maintenance_cost_usd)) AS net_profit
    FROM fact_production
    GROUP BY years, months, year_month
)
SELECT
    year_month,
    ROUND(net_profit::numeric, 2) AS net_profit,
    ROUND((net_profit - LAG(net_profit, 1) OVER (ORDER BY year_month))::numeric, 2) AS mom_profit_change,
    ROUND(SUM(net_profit) OVER (ORDER BY year_month)::numeric, 2) AS cumulative_profit
FROM monthly_profit
ORDER BY year_month;

-- 1.3 Monthly Production Volume
-- Provides boards shipped by month and year, useful for spotting seasonality.
SELECT  
    EXTRACT(YEAR FROM start_date) AS year,
    EXTRACT(MONTH FROM start_date) AS month_num,
    TO_CHAR(start_date, 'Month') AS month_name,
    SUM(quantity_shipped) AS total_boards_shipped
FROM fact_production
GROUP BY year, month_num, month_name
ORDER BY year, month_num ASC;

-- SECTION 4: QUALITY & OPERATIONS ANALYSIS

-- 2.1 Delayed Orders and Percentage of Delayed Orders Per Year (Conditional Aggregation)
-- Measures on-time delivery performance.
SELECT
    EXTRACT(YEAR FROM start_date) AS years,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) AS orders_delayed,
    ROUND(
        (SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
        2
    ) AS percentage_orders_delayed
FROM
    fact_production
GROUP BY
    years
ORDER BY
    years;
-- 2.2 Most Common Scrap Reason Per Year (Window Function)
-- Identifies the primary quality issue driving waste.
WITH tot_scrapped AS ( 
    SELECT 
        EXTRACT(YEAR FROM start_date) AS years,
        SUM(quantity_scrapped) AS tot_boards_scrapped, 
        scrap_reason 
    FROM fact_production
    GROUP BY scrap_reason, years
),
rw_num AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (PARTITION BY years ORDER BY tot_boards_scrapped DESC) AS rw_number 
    FROM tot_scrapped
)
SELECT years, tot_boards_scrapped, scrap_reason AS most_common_scrap_reason
FROM rw_num 
WHERE rw_number = 1
ORDER BY years DESC;

-- 2.3 Impact of Remakes on Cost and Delay (Accurate Cost Per Board Calculation)
-- Quantifies the financial and delivery impact of quality issues requiring rework.
WITH order_costs AS (
    SELECT
        order_id,
        customer_id,
        quantity_remade,
        quantity_shipped,
        shipping_date,
        deadline_date,
        -- Calculate Cost Per Board (CPB)
        (material_cost_usd + maintenance_cost_usd + labor_cost_usd) / NULLIF(quantity_shipped, 0) AS cost_per_board
    FROM fact_production
    WHERE quantity_remade > 0 AND quantity_shipped > 0
)
SELECT
    oc.order_id,
    c.customer_name,
    oc.quantity_remade,
    oc.quantity_shipped,
    ROUND((oc.cost_per_board * oc.quantity_remade)::numeric, 2) AS estimated_remake_cost,
    CASE WHEN oc.shipping_date > oc.deadline_date THEN 'Delayed' ELSE 'On Time' END AS delivery_status,
    (oc.shipping_date - oc.deadline_date) AS days_delayed
FROM order_costs oc
JOIN dim_customer c ON oc.customer_id = c.customer_id
ORDER BY estimated_remake_cost DESC
LIMIT 50;

-- 2.4 Corrective Maintenance Cost Per Machine (Ranked by Cost)
-- Identifies the most problematic machines requiring the most expensive corrective maintenance.
WITH machine_yearly_cost AS (	
    SELECT 
        machine_id, 
        EXTRACT(YEAR FROM maintenance_date) AS years,
        SUM(parts_cost_usd + labor_cost_usd) AS total_corrective_cost
    FROM fact_maintenance
    WHERE maintenance_type = 'Corrective'
    GROUP BY machine_id, years
),
ranked_machines AS (
    SELECT 
        *, 
        RANK() OVER(PARTITION BY years ORDER BY total_corrective_cost DESC) AS cost_rank
    FROM machine_yearly_cost
)
SELECT 
    years, 
    machine_id, 
    total_corrective_cost
FROM ranked_machines
WHERE cost_rank = 1
ORDER BY years DESC;

-- SECTION 5: CUSTOMER & REGIONAL ANALYSIS

-- 3.1 Total Unique Customers
SELECT 
	COUNT(DISTINCT customer_id) AS total_unique_customers 
FROM dim_customer;


-- 3.2 Top 20 Customers by Revenue
SELECT 
	c.customer_id,
	c.customer_name,
	ROUND(SUM(p.sales_price_per_board_usd * p.quantity_shipped)::numeric, 2) AS total_revenue
FROM dim_customer c 
	JOIN fact_production p ON c.customer_id = p.customer_id
GROUP BY 
	c.customer_id, 
	c.customer_name
ORDER BY 
	total_revenue DESC
LIMIT 20;


-- 3.3 Customer Order Frequency (Customers with >1 Order)
SELECT 
	c.customer_id,
	c.customer_name,
	COUNT(p.order_id) AS total_orders
FROM dim_customer c
	JOIN fact_production p ON c.customer_id = p.customer_id
GROUP BY 
	c.customer_id,
	c.customer_name
HAVING 
	COUNT(p.order_id) > 1
ORDER BY 
	total_orders DESC;

-- 3.4 Regional Distribution of Customers
SELECT  
    region,
    country,
    COUNT(*) AS total_customers
FROM dim_customer 
GROUP BY region, country 
ORDER BY region, country;
--SECTION 6 Product Profitability Deep Dive
-- Most Profitable Products,
SELECT
    p.product_id,
    dp.layer_count,
    dp.board_complexity,
    ROUND(SUM(p.sales_price_per_board_usd * p.quantity_shipped)::numeric, 2) AS total_revenue,
    ROUND(SUM(p.sales_price_per_board_usd * p.quantity_shipped - (p.material_cost_usd + p.labor_cost_usd + p.maintenance_cost_usd))::numeric, 2) AS total_profit,
    ROUND((SUM(p.sales_price_per_board_usd * p.quantity_shipped - (p.material_cost_usd + p.labor_cost_usd + p.maintenance_cost_usd)) * 100.0 / NULLIF(SUM(p.sales_price_per_board_usd * p.quantity_shipped), 0))::numeric, 2) AS profit_margin_pct
FROM fact_production p
JOIN dim_product dp ON p.product_id = dp.product_id
GROUP BY 1, 2, 3
ORDER BY total_profit DESC
LIMIT 10;
-- Strategic Question: Is the complexity of the board justified by the profit margin?
SELECT
    dp.board_complexity,
    COUNT(p.order_id) AS total_orders,
    ROUND(SUM(p.sales_price_per_board_usd * p.quantity_shipped)::numeric, 2) AS total_revenue,
    -- Calculate Total Profit for the complexity group
    SUM(p.sales_price_per_board_usd * p.quantity_shipped - (p.material_cost_usd + p.labor_cost_usd + p.maintenance_cost_usd)) AS total_profit,
    -- Calculate Average Profit Margin (%) for the complexity group
    ROUND(
        (SUM(p.sales_price_per_board_usd * p.quantity_shipped - (p.material_cost_usd + p.labor_cost_usd + p.maintenance_cost_usd)) * 100.0 
        / NULLIF(SUM(p.sales_price_per_board_usd * p.quantity_shipped), 0))::numeric, 
        2
    ) AS average_profit_margin_pct
FROM fact_production p
JOIN dim_product dp ON p.product_id = dp.product_id
GROUP BY dp.board_complexity
ORDER BY average_profit_margin_pct DESC;


--SECTION 7 : Root Cause Analysis (Quality & Operations)
--scrap rate by material 
SELECT
    dm.material_name,
    dm.resin_system,
    SUM(fp.quantity_started) AS total_started,
    SUM(fp.quantity_scrapped) AS total_scrapped,
    ROUND((SUM(fp.quantity_scrapped) * 100.0 / NULLIF(SUM(fp.quantity_started), 0))::numeric, 2) AS scrap_rate_pct
FROM fact_production fp
JOIN dim_material dm ON fp.material_id = dm.material_id
GROUP BY 1, 2
HAVING SUM(fp.quantity_started) > 0
ORDER BY scrap_rate_pct DESC;

-- Query: Percentage of Delayed Orders Grouped by Scrap Reason
--  Do specific quality issues (scrap reasons) lead to delivery delays?

SELECT
    -- Use COALESCE to group orders with no scrap reason (NULL) into a category
    COALESCE(scrap_reason, 'No Scrap Recorded') AS scrap_reason_group,
    COUNT(order_id) AS total_orders_in_group,
    -- Use Conditional Aggregation to count delayed orders
    SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) AS delayed_orders_count,
    -- Calculate the percentage of delayed orders within this scrap reason group
    ROUND(
        (SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(COUNT(order_id), 0))::numeric, 
        2
    ) AS percentage_delayed_in_group
FROM fact_production
GROUP BY scrap_reason_group
ORDER BY percentage_delayed_in_group DESC;
 Query: Impact of Corrective Maintenance on Production Quality (Scrap & Delay)
 
--  Do orders immediately following corrective maintenance perform worse?


-- Step 1: Calculate the overall average scrap rate and delay rate for comparison
WITH overall_performance AS (
    SELECT
        ROUND(SUM(quantity_scrapped) * 100.0 / NULLIF(SUM(quantity_started), 0), 2) AS overall_scrap_rate_pct,
        ROUND(SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS overall_delay_rate_pct
    FROM fact_production
),
-- Step 2: Identify production orders that ran immediately after a corrective maintenance event
post_maintenance_orders AS (
    SELECT
        fp.order_id,
        fp.quantity_started,
        fp.quantity_scrapped,
        fp.is_delayed,
        fm.maintenance_date,
        fp.start_date
    FROM fact_production fp
    JOIN fact_maintenance fm ON fp.machine_id = fm.machine_id
    WHERE 
        fm.maintenance_type = 'Corrective' -- Only interested in unplanned maintenance
        AND fp.start_date > fm.maintenance_date -- Production started after maintenance
        -- Production started within 7 days of maintenance (The "immediate" window)
        AND fp.start_date <= fm.maintenance_date + INTERVAL '7 days' 
),
-- Step 3: Aggregate the performance of the post-maintenance orders
post_maintenance_performance AS (
    SELECT
        COUNT(order_id) AS total_post_maint_orders,
        ROUND(SUM(quantity_scrapped) * 100.0 / NULLIF(SUM(quantity_started), 0), 2) AS post_maint_scrap_rate_pct,
        ROUND(SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS post_maint_delay_rate_pct
    FROM post_maintenance_orders
)
-- Step 4: Combine and present the comparison
SELECT
    pmp.total_post_maint_orders,
    pmp.post_maint_scrap_rate_pct,
    op.overall_scrap_rate_pct,
    pmp.post_maint_delay_rate_pct,
    op.overall_delay_rate_pct,
    -- Calculate the difference (Impact)
    ROUND(pmp.post_maint_scrap_rate_pct - op.overall_scrap_rate_pct, 2) AS scrap_rate_impact,
    ROUND(pmp.post_maint_delay_rate_pct - op.overall_delay_rate_pct, 2) AS delay_rate_impact
FROM post_maintenance_performance pmp, overall_performance op;
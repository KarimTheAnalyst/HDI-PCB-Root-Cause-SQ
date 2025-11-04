
-- ============================================================
--  HDI PCB Manufacturing Analytics 
-- Author: Abdelkarim Mars
-- Goal: Demonstrate SQL data analysis for a HDI PCB manufacturing 
-- Section 1 Create Database PCB_manufacturing 
--Create tables 
-- Create dim_customer table 
CREATE TABLE dim_customer (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(200) NOT NULL,
    customer_type VARCHAR(100),
    country VARCHAR(100),
    country_code VARCHAR(10),
    region VARCHAR(50),
    status VARCHAR(20)
);
--Create dim_machine table 
CREATE TABLE dim_machine(
machine_id VARCHAR(50) PRIMARY KEY,
machine_name VARCHAR(30) NOT NULL, 
machine_type VARCHAR(30),
manufacturer VARCHAR(50),
installation_date DATE, 
status	VARCHAR(50),
maintenance_cost_per_hour DECIMAL(10,2)
);
--Create dim_material table 

CREATE TABLE dim_material(
material_id	VARCHAR(50) PRIMARY KEY,
material_name VARCHAR(100) NOT NULL, 
supplier VARCHAR(50),
resin_system VARCHAR(50),
dielectric_type	VARCHAR(50),
unit_cost_per_m2 DECIMAL( 10,2),
material_category VARCHAR(50)
);
 --Create dim_operator table 
CREATE TABLE dim_operator(
operator_id VARCHAR(50) PRIMARY KEY, 
first_name VARCHAR(100) NOT NULL,
last_name	VARCHAR(100) NOT NULL,
department	VARCHAR(50),
shift	VARCHAR(30),
experience_years INTEGER, 	
status	VARCHAR(30),
full_name VARCHAR(100),	
hourly_rate_usd DECIMAL(10,2)
);
 --Create dim_process table
CREATE TABLE dim_process(
process_id VARCHAR(50) PRIMARY KEY,	
process_step VARCHAR(100),	
process_category VARCHAR(50),	
standard_cycle_time_min INTEGER, 
quality_check_required BOOLEAN 
);

--Create dim_product table
 CREATE TABLE dim_product(
product_id VARCHAR(50) PRIMARY KEY,
layer_count int,
surface_finish VARCHAR(70),
board_complexity VARCHAR(50),
technology_type VARCHAR(50)
);
-- Create Fact Tables 
 --Create fact_production table
 CREATE TABLE fact_production(
 order_id VARCHAR(50) PRIMARY KEY, 
 --Foreign keys
 customer_id VARCHAR(50) NOT NULL,
 material_id VARCHAR(50) NOT NULL,
 machine_id VARCHAR(50) NOT NULL,
 product_id VARCHAR(50) NOT NULL,
 customer_name VARCHAR(200),
 layer_count int,
 surface_finish VARCHAR(50),
 start_date DATE NOT NULL, 
 end_date DATE, 
 deadline_date	DATE, 
 shipping_date	DATE, 
 --Quantity metrics 
  quantity_requested INT NOT NULL,
  quantity_started INT NOT NULL,
  quantity_scrapped INT DEFAULT 0,
  quantity_remade INT DEFAULT 0,
  quantity_shipped INT NOT NULL,
  --Cost metrics 
 material_cost_usd	DECIMAL(10,2),
 labor_cost_usd	DECIMAL(10,2),
 maintenance_cost_usd DECIMAL(10,2),
 --Revenue metrics 
 sales_price_per_board_usd	DECIMAL(10,2),
 production_duration_days int,	
 is_delayed	INT DEFAULT 0,
 delay_days	INT DEFAULT 0,
 remake_needed	INT DEFAULT 0,
   -- Quality Attributes
  scrap_reason VARCHAR(100),
    -- Foreign Key Constraints
FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
FOREIGN KEY (material_id) REFERENCES dim_material(material_id),
FOREIGN KEY (machine_id) REFERENCES dim_machine(machine_id),
FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);
-- create table fact_maintenance 
DROP TABLE fact_maintenance;
CREATE TABLE fact_maintenance (
    maintenance_id VARCHAR(20) PRIMARY KEY,
    machine_id VARCHAR(20) NOT NULL,
    maintenance_date DATE NOT NULL,
    maintenance_type VARCHAR(50),
    downtime_hours DECIMAL(10,2),
    parts_cost_usd DECIMAL(10,2),
    labor_cost_usd DECIMAL(10,2),
	maintenance_description VARCHAR(250),
	next_maintenance_date DATE,
    
    FOREIGN KEY (machine_id) REFERENCES dim_machine(machine_id)
);

-- INDEXES FOR PERFORMANCE

-- fact_production indexes
CREATE INDEX idx_fact_production_customer ON fact_production(customer_id);
CREATE INDEX idx_fact_production_material ON fact_production(material_id);
CREATE INDEX idx_fact_production_machine ON fact_production(machine_id);
CREATE INDEX idx_fact_production_product ON fact_production(product_id);
CREATE INDEX idx_fact_production_start_date ON fact_production(start_date);
CREATE INDEX idx_fact_production_layer_count ON fact_production(layer_count);
CREATE INDEX idx_fact_production_remake ON fact_production(remake_needed);
CREATE INDEX idx_fact_production_delayed ON fact_production(is_delayed);

-- fact_maintenance indexes
CREATE INDEX idx_fact_maintenance_machine ON fact_maintenance(machine_id);
CREATE INDEX idx_fact_maintenance_date ON fact_maintenance(maintenance_date);
CREATE INDEX idx_fact_maintenance_type ON fact_maintenance(maintenance_type);

-- Setion 2 : Data quality check 
-- Check row counts
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dim_customer
UNION ALL
SELECT 'dim_material', COUNT(*) FROM dim_material
UNION ALL
SELECT 'dim_operator', COUNT(*) FROM dim_operator
UNION ALL
SELECT 'dim_machine', COUNT(*) FROM dim_machine
UNION ALL
SELECT 'dim_process', COUNT(*) FROM dim_process
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'fact_production', COUNT(*) FROM fact_production
UNION ALL
SELECT 'fact_maintenance', COUNT(*) FROM fact_maintenance;

-- Verify quantity logic
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN quantity_shipped = quantity_requested THEN 1 ELSE 0 END) AS orders_fulfilled,
    SUM(CASE WHEN quantity_shipped != quantity_requested THEN 1 ELSE 0 END) AS orders_not_fulfilled
FROM fact_production;
--Are there any NULL values where there shouldn't be?
SELECT * FROM dim_customer 
SELECT * FROM dim_customer 
WHERE customer_id IS NULL;
SELECT * FROM dim_material
WHERE material_id IS NULL;
SELECT * FROM dim_machine
WHERE machine_id IS NULL;
SELECT * FROM dim_process
WHERE process_id IS NULL;
--Are there any duplicates values where there shouldn't be?
SELECT COUNT(*) FROM dim_customer 
GROUP BY customer_id 
HAVING COUNT(*)>1;
SELECT COUNT(*) FROM dim_material 
GROUP BY material_id 
HAVING COUNT(*)>1;
SELECT COUNT(*) FROM dim_machine
GROUP BY machine_id 
HAVING COUNT(*)>1;
SELECT COUNT(*) FROM dim_process
GROUP BY process_id 
HAVING COUNT(*)>1;
-- Are data types appropriate?
SELECT 
    column_name, 
    data_type, 
    character_maximum_length, 
    numeric_precision, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'fact_production'
ORDER BY ordinal_position;

SELECT 
    column_name, 
    data_type, 
    character_maximum_length, 
    numeric_precision, 
    is_nullable
FROM information_schema.columns
	WHERE table_name = 'fact_maintenance'
	ORDER BY ordinal_position;
-- check unusual values (outliers) 
SELECT 
	MAX(layer_count) AS maximum_layers, 
	MAX(sales_price_per_board_usd) AS maximum_board_price,
	MAX(production_duration_days) AS maximum_production_days,
	MIN(layer_count) AS minimum_layers, 
	MIN(sales_price_per_board_usd) AS minimum_board_price,
	MIN(production_duration_days) AS minimum_production_days
FROM fact_production ;

SELECT 
	MAX(unit_cost_per_m2) AS maximum_unit_price
	FROM dim_material;

SELECT
MAX(standard_cycle_time_min) AS maximum_cycle_time,
MIN(standard_cycle_time_min) AS minimum_cycle_time
FROM dim_process;

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

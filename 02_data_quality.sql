-- ============================================================
--  HDI PCB Manufacturing Analytics 
-- Author: Abdelkarim Mars
-- Section 2: Data Quality Checks
-- ============================================================

-- Row counts per table
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

-- NULL checks
SELECT * FROM dim_customer WHERE customer_id IS NULL;
SELECT * FROM dim_material WHERE material_id IS NULL;
SELECT * FROM dim_machine WHERE machine_id IS NULL;
SELECT * FROM dim_process WHERE process_id IS NULL;

-- Duplicate checks
SELECT COUNT(*) FROM dim_customer GROUP BY customer_id HAVING COUNT(*)>1;
SELECT COUNT(*) FROM dim_material GROUP BY material_id HAVING COUNT(*)>1;
SELECT COUNT(*) FROM dim_machine GROUP BY machine_id HAVING COUNT(*)>1;
SELECT COUNT(*) FROM dim_process GROUP BY process_id HAVING COUNT(*)>1;

-- Data type check
SELECT column_name, data_type, character_maximum_length, numeric_precision, is_nullable
FROM information_schema.columns
WHERE table_name = 'fact_production'
ORDER BY ordinal_position;

SELECT column_name, data_type, character_maximum_length, numeric_precision, is_nullable
FROM information_schema.columns
WHERE table_name = 'fact_maintenance'
ORDER BY ordinal_position;

-- Outlier detection
SELECT 
	MAX(layer_count) AS maximum_layers, 
	MAX(sales_price_per_board_usd) AS maximum_board_price,
	MAX(production_duration_days) AS maximum_production_days,
	MIN(layer_count) AS minimum_layers, 
	MIN(sales_price_per_board_usd) AS minimum_board_price,
	MIN(production_duration_days) AS minimum_production_days
FROM fact_production ;

SELECT MAX(unit_cost_per_m2) AS maximum_unit_price FROM dim_material;

SELECT
MAX(standard_cycle_time_min) AS maximum_cycle_time,
MIN(standard_cycle_time_min) AS minimum_cycle_time
FROM dim_process;

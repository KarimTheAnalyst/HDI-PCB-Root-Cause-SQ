-- ============================================================
--  HDI PCB Manufacturing Analytics 
-- Author: Abdelkarim Mars
-- Goal: Demonstrate SQL data analysis for a HDI PCB manufacturing 
-- Section 1 Create Database PCB_manufacturing 
-- ============================================================

-- Create Dimension Tables

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

-- Create dim_machine table 
CREATE TABLE dim_machine(
    machine_id VARCHAR(50) PRIMARY KEY,
    machine_name VARCHAR(30) NOT NULL, 
    machine_type VARCHAR(30),
    manufacturer VARCHAR(50),
    installation_date DATE, 
    status VARCHAR(50),
    maintenance_cost_per_hour DECIMAL(10,2)
);

-- Create dim_material table 
CREATE TABLE dim_material(
    material_id VARCHAR(50) PRIMARY KEY,
    material_name VARCHAR(100) NOT NULL, 
    supplier VARCHAR(50),
    resin_system VARCHAR(50),
    dielectric_type VARCHAR(50),
    unit_cost_per_m2 DECIMAL(10,2),
    material_category VARCHAR(50)
);

-- Create dim_operator table 
CREATE TABLE dim_operator(
    operator_id VARCHAR(50) PRIMARY KEY, 
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    shift VARCHAR(30),
    experience_years INTEGER, 	
    status VARCHAR(30),
    full_name VARCHAR(100),	
    hourly_rate_usd DECIMAL(10,2)
);

-- Create dim_process table
CREATE TABLE dim_process(
    process_id VARCHAR(50) PRIMARY KEY,	
    process_step VARCHAR(100),	
    process_category VARCHAR(50),	
    standard_cycle_time_min INTEGER, 
    quality_check_required BOOLEAN 
);

-- Create dim_product table
CREATE TABLE dim_product(
    product_id VARCHAR(50) PRIMARY KEY,
    layer_count INT,
    surface_finish VARCHAR(70),
    board_complexity VARCHAR(50),
    technology_type VARCHAR(50)
);


-- Create Fact Tables

CREATE TABLE fact_production(
    order_id VARCHAR(50) PRIMARY KEY, 
    customer_id VARCHAR(50) NOT NULL,
    material_id VARCHAR(50) NOT NULL,
    machine_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(200),
    layer_count INT,
    surface_finish VARCHAR(50),
    start_date DATE NOT NULL, 
    end_date DATE, 
    deadline_date DATE, 
    shipping_date DATE, 
    quantity_requested INT NOT NULL,
    quantity_started INT NOT NULL,
    quantity_scrapped INT DEFAULT 0,
    quantity_remade INT DEFAULT 0,
    quantity_shipped INT NOT NULL,
    material_cost_usd DECIMAL(10,2),
    labor_cost_usd DECIMAL(10,2),
    maintenance_cost_usd DECIMAL(10,2),
    sales_price_per_board_usd DECIMAL(10,2),
    production_duration_days INT,	
    is_delayed INT DEFAULT 0,
    delay_days INT DEFAULT 0,
    remake_needed INT DEFAULT 0,
    scrap_reason VARCHAR(100),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (material_id) REFERENCES dim_material(material_id),
    FOREIGN KEY (machine_id) REFERENCES dim_machine(machine_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

DROP TABLE IF EXISTS fact_maintenance;
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

-- Indexes for performance

CREATE INDEX idx_fact_production_customer ON fact_production(customer_id);
CREATE INDEX idx_fact_production_material ON fact_production(material_id);
CREATE INDEX idx_fact_production_machine ON fact_production(machine_id);
CREATE INDEX idx_fact_production_product ON fact_production(product_id);
CREATE INDEX idx_fact_production_start_date ON fact_production(start_date);
CREATE INDEX idx_fact_production_layer_count ON fact_production(layer_count);
CREATE INDEX idx_fact_production_remake ON fact_production(remake_needed);
CREATE INDEX idx_fact_production_delayed ON fact_production(is_delayed);

CREATE INDEX idx_fact_maintenance_machine ON fact_maintenance(machine_id);
CREATE INDEX idx_fact_maintenance_date ON fact_maintenance(maintenance_date);
CREATE INDEX idx_fact_maintenance_type ON fact_maintenance(maintenance_type);

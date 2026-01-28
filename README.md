# HDI PCB Manufacturing Root Cause Analysis (SQL)

## 1. Business Problem
In manufacturing, defects, scrap, and rework directly impact **yield, cost, and delivery time**.  
This project uses an HDI PCB production scenario as a **high-complexity example** to demonstrate a transferable root cause analytics approach.


This analysis is designed to help **manufacturing, quality, and engineering teams** prioritize corrective actions based on measurable business impact.

---

## 2. Manufacturing Context & Assumptions
- The project represents a **typical HDI PCB production environment**.
- Data includes production lots, defect types, process steps, maintenance events, and cost information.
- The dataset is **synthetic but industry-realistic**, created to reflect real manufacturing behavior and constraints.
- Manufacturing assumptions are based on:
  - Multi-step HDI PCB processes
  - Common defect categories (e.g. opens, shorts, registration issues)
  - Scrap and rework driven by process instability and equipment conditions

The analytical structure and logic are **production-ready** and transferable to real factory data.

Although the case scenario is HDI PCB, the workflow and SQL logic are designed to be **transferable to other manufacturing environments** (electronics, aerospace, automotive, medical devices).


---

## 3. Analytical Approach (SQL Logic)
The analysis was performed using **PostgreSQL**, following an end-to-end manufacturing analytics workflow:

- Data modeling using **staging, dimension, and fact tables**
- **Data quality checks** to validate production and defect records
- **Root cause analysis** by linking defects to:
  - process steps
  - defect categories
  - maintenance events
- **Yield and cost calculations** at lot and process level
- Aggregation and trend analysis to identify **high-impact drivers**

The focus is on understanding **why defects occur**, not just how many.

---

## 4. Key Findings
- A small number of **defect categories** account for a disproportionate share of scrap and rework.
- Certain **process steps** show consistently higher defect concentration, indicating process variability.
- **Maintenance-related events** correlate strongly with defect spikes during specific production periods.
- Yield loss is unevenly distributed: a limited number of lots drive most of the cost impact.

These insights enable **focused and prioritized actions**, rather than broad, inefficient interventions.

---

## 5. Business Impact (Quality / Yield / Cost)
If applied in a real manufacturing environment, this analysis would support:

- **Yield improvement** by targeting the highest-impact defect drivers
- **Reduction of scrap and rework costs**
- **Improved maintenance planning** based on defect correlations
- **Faster, data-driven decisions** for quality and process engineering teams

Overall, the approach helps shift from reactive quality control to **proactive process improvement**.

---

## 6. Recommendations
- Prioritize corrective actions on **top defect–process combinations**
- Strengthen **process monitoring** on high-variability steps
- Integrate defect analytics with **maintenance planning**
- Use this framework as a **recurring quality review tool** in manufacturing operations

---

## Tools & Skills Demonstrated
- **SQL (PostgreSQL):** data modeling, root cause analysis, yield and cost metrics  
- **Manufacturing analytics:** quality, yield, process improvement  
- **Industrial data thinking:** decision-focused analysis  

---
## Final Note
This project demonstrates a transferable manufacturing analytics workflow that turns production data into actionable insights for quality improvement and operational excellence.

This project demonstrates how **manufacturing data analysis** can transform raw production data into **actionable insights** that support quality improvement and operational excellence in HDI PCB manufacturing.

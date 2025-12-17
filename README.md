# Omni Retail – SQL Final Project

## 1. Overview

This project implements an **omnichannel retail database** (online + physical stores) for analytics and machine learning use cases.

The database supports:

- Customer profiles and addresses  
- Stores (online and physical)  
- Product catalog with **XML specs stored as TEXT**  
- Categories with a self-referencing hierarchy  
- Orders, order items, inventory  
- Promotions with **JSON rules**  
- Customer interactions (web, email, store) with JSON metadata  
- Automatic order status logs tracked via a trigger  

The main script is:

- `omni_retail_full_project.sql` – creates the schema, constraints, views, stored procedures, trigger, demo DML, and analytical queries.

---

## 2. Requirements

- **MySQL 8.0+** (tested conceptually against MySQL 8.x features)
- Recommended: **MySQL Workbench** for:
  - Running the main `.sql` script
  - Importing CSV files via the Table Data Import Wizard

Features used:

- `JSON` data type and JSON functions (JSON_OBJECT, JSON_SET, JSON_EXTRACT, JSON_CONTAINS)
- Window functions (e.g., `SUM() OVER (...)`)
- CTEs (`WITH ... AS (...)`)
- `FULLTEXT` index on InnoDB tables
- Triggers and stored procedures
- XML-like content stored in `TEXT` and manipulated with string functions

---

## 3. Files

Suggested structure of the final submission folder:

```text
/FinalProject
   |-- omni_retail_full_project.sql      -- main SQL script (this project)
   |-- csv/
   |     |-- customers_*.csv
   |     |-- customer_profiles_*.csv
   |     |-- addresses_*.csv
   |     |-- stores_*.csv
   |     |-- products_*.csv
   |     |-- inventory_*.csv
   |     |-- orders_*.csv
   |     |-- order_items_*.csv
   |     |-- promotions_*.csv
   |     |-- order_promotions_*.csv
   |     |-- interactions_*.csv
   |
   |-- diagrams/
   |     |-- ERD_omni_retail.png        -- ERD diagram
   |
   |-- report.pdf                       -- final project report (separate document)
   |-- README.md                        -- this file
```

> Note: The **categories** table is pre-populated inside the SQL script (20 categories), so no CSV import is required for that table.

---

## 4. How to Run the SQL Script

1. Open **MySQL Workbench**.
2. Create a new SQL tab.
3. Open / paste the contents of `omni_retail_full_project.sql`.
4. Execute the entire script (or “Run all”).

What the script will do:

1. `DROP DATABASE IF EXISTS omni_retail;`
2. `CREATE DATABASE omni_retail; USE omni_retail;`
3. Create all tables:
   - `customers, customer_profiles, addresses, stores, categories, products, inventory, orders, order_items, promotions, order_promotions, interactions, order_status_logs`
4. Insert an initial set of 20 **categories**.
5. Create:
   - Trigger: `trg_orders_status_log`
   - Views: `vw_orders_enriched`, `vw_product_sales_summary`
   - Indexes (including `FULLTEXT` on products)
   - Stored procedures:
     - `sp_apply_promotion_to_order`
     - `sp_update_inventory_for_order`
6. Run demo DML for:
   - A lab product with XML specs
   - A lab promotion with JSON rules
   - A lab interaction with JSON metadata
   - JSON and XML updates
   - A controlled DELETE
7. Define analytical / ML queries (DQL) at the end of the file.

---

## 5. Loading CSV Data (Table Data Import Wizard)

After running `omni_retail_full_project.sql`, load the bulk data from CSV files using **MySQL Workbench – Table Data Import Wizard**.

### 5.1. General steps (Workbench)

For each table:

1. Right-click the schema `omni_retail` → “Table Data Import Wizard”.
2. Select the corresponding CSV file.
3. Use **“First row contains column names”**.
4. Map CSV columns to table columns (usually automatic if names match).
5. Finish the import.

### 5.2. Recommended import order (due to foreign keys)

Because of FK dependencies, import in this order:

1. `customers`  
2. `customer_profiles`  
3. `addresses`  
4. `stores`  
5. `products`  *(categories are already inserted by the script)*  
6. `inventory`  
7. `orders`  
8. `order_items`  
9. `promotions`  
10. `order_promotions`  
11. `interactions`  

**order_status_logs**  
- This table is intentionally left empty initially.  
- It will be filled automatically by the trigger `trg_orders_status_log` whenever an order’s status changes.

> If any CSV import fails with FK errors, check whether all referenced parent tables have already been loaded and whether IDs in the CSV match the sampled IDs (e.g., orders_800, products, etc.).

---

## 6. Key Schema Features (for the report)

- **1:1 relationship**:  
  - `customers` ↔ `customer_profiles` (PK = FK)
- **1:N relationships**:  
  - `customers` → `addresses`, `orders`  
  - `stores` → `orders`, `inventory`  
  - `categories` (self-FK) → `categories`
- **N:N relationship**:  
  - `orders` ↔ `promotions` through `order_promotions`
- **Semi-structured data**:  
  - `products.specs_xml` (`TEXT`) storing XML-like product specs  
  - `promotions.rules_json` (`JSON`) storing flexible promotion rules  
  - `interactions.metadata_json` (`JSON`) storing interaction metadata
- **Trigger**:  
  - `trg_orders_status_log` logs status changes in `orders` into `order_status_logs`
- **Views**:
  - `vw_orders_enriched`: joins orders with customers and stores (for reporting)
  - `vw_product_sales_summary`: aggregates sales per product, including units sold, revenue, discounts, and number of orders
- **Stored Procedures**:
  - `sp_apply_promotion_to_order(p_order_id, p_promo_code)`:
    - Validates promotion using JSON rules and dates
    - Inserts into `order_promotions`
    - Updates `orders.total_amount`
  - `sp_update_inventory_for_order(p_order_id)`:
    - Decreases inventory per store/product based on `order_items`
    - Returns updated inventory rows
- **Indexes**:
  - Composite index on `orders(customer_id, status, order_date)`
  - Index on `order_items(product_id)`
  - `FULLTEXT` index on `products(name, description)` to support search

---

## 7. Example: Testing Stored Procedures and Trigger

### 7.1. Apply a promotion to an order

```sql
CALL sp_apply_promotion_to_order(101, 'LAB_CLEARANCE5');

SELECT *
FROM order_promotions
WHERE order_id = 101;
```

### 7.2. Update order status and check the status log

```sql
UPDATE orders
SET status = 'shipped'
WHERE order_id = 101;

SELECT *
FROM order_status_logs
WHERE order_id = 101
ORDER BY changed_at DESC;
```

### 7.3. Update inventory for an order

```sql
CALL sp_update_inventory_for_order(101);

SELECT *
FROM inventory i
JOIN orders o
  ON o.store_id = i.store_id
JOIN order_items oi
  ON oi.order_id = o.order_id
 AND oi.product_id = i.product_id
WHERE o.order_id = 101;
```

---

## 8. Analytical / ML Queries

The script includes several analytical queries that can be exported as CSV:

- **3.1** Monthly revenue by channel and store type (with running total per channel using `SUM() OVER`).
- **3.2** Sales by product brand extracted from `specs_xml` using string functions.
- **3.3** Promotion usage summary, reading JSON fields from `rules_json`.
- **3.4** **Customer churn dataset**:
  - Grain: customer  
  - Target: `churned_90d` (churn flag based on last order date)
- **3.5** **Order value regression dataset**:
  - Grain: order  
  - Target: `target_total_amount`
- **3.6** **Product performance / inventory dataset**:
  - Grain: product  
  - Includes XML-derived specs, sales, and inventory metrics
- **3.7** Full-text search demo on products using `MATCH ... AGAINST`.

These queries can be run directly from the end of `omni_retail_full_project.sql` and exported to CSV through MySQL Workbench for further analysis in Python/R.

---

## 9. Notes

- This project was designed for **teaching/academic purposes**: clarity, integrity, and feature coverage (JSON, XML, triggers, views, SPs, window functions) were prioritized over extreme normalization or performance tuning.
- All demo DML statements (lab product, lab promotion, lab interaction) are **idempotent**: they can be run multiple times without creating duplicates, thanks to `WHERE NOT EXISTS` or controlled keys.

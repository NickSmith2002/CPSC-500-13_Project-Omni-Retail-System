/* ============================================================
   SECTION 3 – Data Query Language (DQL) and Analytics
   This section covers:
     - Analytical queries with joins, GROUP BY, and window
       functions (SUM() OVER).
     - Examples of using XML stored in TEXT
       (products.specs_xml).
     - Examples of using JSON columns
       (promotions.rules_json).
     - Datasets for machine learning / analytics.
   ============================================================ */


/* ------------------------------------------------------------
   3.1 – Monthly revenue by channel (with running total)
   Goals:
     - Join orders, order_items, stores.
     - Aggregate monthly revenue by channel and store_type.
     - Use a window function (SUM() OVER) for running totals.
   Assumptions:
     - Completed orders are those with status in
       ('paid','shipped','delivered').
   ------------------------------------------------------------ */

WITH monthly_stats AS (
    SELECT
        YEAR(o.order_date)  AS order_year,
        MONTH(o.order_date) AS order_month,
        o.channel,
        s.store_type,
        SUM(oi.total_line_amount) AS monthly_revenue,
        COUNT(DISTINCT o.order_id) AS num_orders,
        COUNT(DISTINCT o.customer_id) AS unique_customers
    FROM orders o
    JOIN order_items oi
      ON oi.order_id = o.order_id
    JOIN stores s
      ON s.store_id = o.store_id
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY
        order_year,
        order_month,
        o.channel,
        s.store_type
)
SELECT
    order_year,
    order_month,
    channel,
    store_type,
    monthly_revenue,
    num_orders,
    unique_customers,

    -- Running total of revenue per channel over time
    SUM(monthly_revenue) OVER (
        PARTITION BY channel, store_type
        ORDER BY order_year, order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue_channel
FROM monthly_stats
ORDER BY
    order_year,
    order_month,
    channel,
    store_type;
    
    
/* ------------------------------------------------------------
   3.2 – Simple XML example: sales by product brand
   Goals:
     - Extract <brand>...</brand> from specs_xml (TEXT).
     - Aggregate units sold and total revenue by brand.
   Notes:
     - specs_xml is stored as TEXT, not as native XML.
       We use string functions to extract the brand tag.
   ------------------------------------------------------------ */

WITH product_brands AS (
    SELECT
        p.product_id,
        -- Extract <brand>...</brand> from specs_xml using string functions
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(p.specs_xml, '<brand>', -1),
            '</brand>',
            1
        ) AS brand
    FROM products p
)
SELECT
    pb.brand,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.total_line_amount) AS total_revenue
FROM product_brands pb
JOIN order_items oi
  ON oi.product_id = pb.product_id
JOIN orders o
  ON o.order_id = oi.order_id
WHERE o.status IN ('paid','shipped','delivered')
GROUP BY
    pb.brand
ORDER BY
    total_revenue DESC;


/* ------------------------------------------------------------
   3.3 – Simple JSON example: promotion usage summary
   Goals:
     - Read JSON fields from promotions.rules_json
       (type, discount_pct).
     - Count how many orders used each promotion.
     - Sum the total applied amount per promotion.
   Example rules_json structure:
     {
       "type": "percentage",
       "discount_pct": 10,
       "min_order_value": 200,
       "eligible_channels": ["online","store"]
     }
   ------------------------------------------------------------ */

SELECT
    pr.promotion_id,
    pr.code,
    pr.name AS promotion_name,
    pr.discount_type,
    pr.discount_value,

    -- Read simple fields from JSON rules_json
    JSON_UNQUOTE(JSON_EXTRACT(pr.rules_json, '$.type')) AS rule_type,
    JSON_EXTRACT(pr.rules_json, '$.discount_pct') AS rule_discount_pct,

    COUNT(DISTINCT op.order_id) AS num_orders_with_promo,
    SUM(op.applied_amount) AS total_promo_applied
FROM promotions pr
LEFT JOIN order_promotions op
  ON op.promotion_id = pr.promotion_id
GROUP BY
    pr.promotion_id,
    pr.code,
    pr.name,
    pr.discount_type,
    pr.discount_value,
    rule_type,
    rule_discount_pct
ORDER BY
    num_orders_with_promo DESC;


/* ============================================================
	ML / Analytics Datasets
   The following SELECT statements produce "clean" datasets
   that can be exported to CSV or loaded into Python/R for
   machine learning or analytical tasks.
   ============================================================ */


/* ------------------------------------------------------------
   3.4 – ML Dataset 1: Customer churn classification
   Grain: one row per customer.
   Target:
     - churned_90d:
         1 = customer has no orders, or last order is older
             than 90 days.
         0 = customer has at least one order in the last 90 days.
   Features:
     - Order-based: num_orders, total_revenue, first_order_date,
       last_order_date, days_since_last_order.
     - Channel-based: count of online vs store orders.
     - Profile: gender, marketing_opt_in, preferred_language,
       preferred_channel, lifetime_value, risk_score.
   ------------------------------------------------------------ */

WITH customer_orders AS (
    SELECT
        c.customer_id,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS num_orders,
        SUM(o.total_amount) AS total_revenue
    FROM customers c
    LEFT JOIN orders o
      ON o.customer_id = c.customer_id
     AND o.status IN ('paid','shipped','delivered')
    GROUP BY c.customer_id
),
channel_stats AS (
    SELECT
        o.customer_id,
        SUM(CASE WHEN o.channel = 'online' THEN 1 ELSE 0 END) AS online_orders,
        SUM(CASE WHEN o.channel = 'store'  THEN 1 ELSE 0 END) AS store_orders
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    cp.gender,
    cp.marketing_opt_in,
    cp.preferred_language,
    cp.preferred_channel,
    cp.lifetime_value,
    cp.risk_score,

    co.first_order_date,
    co.last_order_date,
    co.num_orders,
    co.total_revenue,

    TIMESTAMPDIFF(
        DAY,
        co.last_order_date,
        NOW()
    ) AS days_since_last_order,

    cs.online_orders,
    cs.store_orders,

    CASE
        WHEN co.last_order_date IS NULL THEN 1
        WHEN TIMESTAMPDIFF(DAY, co.last_order_date, NOW()) > 90 THEN 1
        ELSE 0
    END AS churned_90d
FROM customers c
LEFT JOIN customer_orders co
  ON co.customer_id = c.customer_id
LEFT JOIN channel_stats cs
  ON cs.customer_id = c.customer_id
LEFT JOIN customer_profiles cp
  ON cp.customer_id = c.customer_id;


/* ------------------------------------------------------------
   3.5 – ML Dataset 2: Order value regression
   Grain: one row per order.
   Target:
     - target_total_amount = orders.total_amount
   Features:
     - Order-level: status, channel, payment_method.
     - Time: order_date, day_of_week, hour_of_day.
     - Store: store_type.
     - Customer location: city, province (shipping address).
     - Line items: num_items, total_quantity, total_line_amount,
       total_discount_amount.
     - Promotions: num_promotions_applied (count), independent
       of JSON.
   ------------------------------------------------------------ */

WITH order_line_agg AS (
    SELECT
        oi.order_id,
        COUNT(*) AS num_items,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_line_amount) AS total_line_amount,
        SUM(oi.discount_amount) AS total_discount_amount
    FROM order_items oi
    GROUP BY oi.order_id
),
promo_stats AS (
    SELECT
        op.order_id,
        COUNT(DISTINCT op.promotion_id) AS num_promotions_applied
    FROM order_promotions op
    GROUP BY op.order_id
)
SELECT
    o.order_id,
    o.customer_id,
    o.store_id,
    s.store_type,
    o.status,
    o.channel,
    o.payment_method,

    o.order_date,
    DAYOFWEEK(o.order_date) AS day_of_week,
    HOUR(o.order_date)      AS hour_of_day,

    ship.city     AS shipping_city,
    ship.province AS shipping_province,

    la.num_items,
    la.total_quantity,
    la.total_line_amount,
    la.total_discount_amount,

    IFNULL(ps.num_promotions_applied, 0) AS num_promotions_applied,

    o.total_amount AS target_total_amount
FROM orders o
LEFT JOIN stores s
  ON s.store_id = o.store_id
LEFT JOIN order_line_agg la
  ON la.order_id = o.order_id
LEFT JOIN promo_stats ps
  ON ps.order_id = o.order_id
LEFT JOIN addresses ship
  ON ship.address_id = o.shipping_address_id;


/* ------------------------------------------------------------
   3.6 – ML Dataset 3: Product performance and inventory clustering
   Grain: one row per product.
   Features:
     - Category: category_name.
     - Specs (XML in TEXT): brand, size, refresh_rate.
     - Pricing: list_price, active flag.
     - Sales: units_sold, net_revenue, total_discount_amount,
       num_orders.
     - Inventory: num_stores_carrying, avg_stock_on_hand.
   ------------------------------------------------------------ */

WITH sales_agg AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.total_line_amount) AS net_revenue,
        SUM(oi.discount_amount) AS total_discount_amount,
        COUNT(DISTINCT oi.order_id) AS num_orders
    FROM order_items oi
    JOIN orders o
      ON o.order_id = oi.order_id
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY oi.product_id
),
inventory_agg AS (
    SELECT
        i.product_id,
        COUNT(DISTINCT i.store_id) AS num_stores_carrying,
        AVG(i.quantity) AS avg_stock_on_hand
    FROM inventory i
    GROUP BY i.product_id
)
SELECT
    p.product_id,
    p.sku,
    p.name AS product_name,
    c.name AS category_name,

    -- Extract brand from specs_xml
    SUBSTRING_INDEX(
        SUBSTRING_INDEX(p.specs_xml, '<brand>', -1),
        '</brand>',
        1
    ) AS brand,

    -- Extract size from specs_xml
    SUBSTRING_INDEX(
        SUBSTRING_INDEX(p.specs_xml, '<size>', -1),
        '</size>',
        1
    ) AS size,

    -- Extract refresh_rate from specs_xml
    SUBSTRING_INDEX(
        SUBSTRING_INDEX(p.specs_xml, '<refresh_rate>', -1),
        '</refresh_rate>',
        1
    ) AS refresh_rate,

    p.list_price,
    p.active,

    sa.units_sold,
    sa.net_revenue,
    sa.total_discount_amount,
    sa.num_orders,

    ia.num_stores_carrying,
    ia.avg_stock_on_hand
FROM products p
LEFT JOIN categories c
  ON c.category_id = p.category_id
LEFT JOIN sales_agg sa
  ON sa.product_id = p.product_id
LEFT JOIN inventory_agg ia
  ON ia.product_id = p.product_id;
  
/* ------------------------------------------------------------
   3.7 – Full-text search on products (name + description)
  
   ------------------------------------------------------------ */

SELECT
    p.product_id,
    p.sku,
    p.name,
    p.description,
    p.list_price,
    p.active,
    MATCH(p.name, p.description)
      AGAINST ('gaming monitor 34 inch curved' IN NATURAL LANGUAGE MODE)
      AS relevance_score
FROM products p
WHERE MATCH(p.name, p.description)
      AGAINST ('gaming monitor 34 inch curved' IN NATURAL LANGUAGE MODE)
ORDER BY
    relevance_score DESC,
    p.list_price DESC
LIMIT 20;



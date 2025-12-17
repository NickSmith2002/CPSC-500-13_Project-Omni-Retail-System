/* -----------------------------------------------------------
   SECTION 2 – DML (Data Loading and Manipulation)
   Note: The following statements are designed to be SAFE:
     - They use WHERE NOT EXISTS for inserts, so they can be
       executed multiple times without causing duplicate keys.
     - They assume the database has already been populated
       from CSV files using the MySQL Import Wizard.
   ----------------------------------------------------------- */


/* ------------------------------------------------------------
   2.1 – INSERT a lab PRODUCT with XML specs (safe / idempotent)
   - Creates one extra product only if the SKU does not exist yet.
   - Uses specs_xml as TEXT containing XML-like structure.
   ------------------------------------------------------------ */

INSERT INTO products (
    category_id,
    sku,
    name,
    description,
    list_price,
    active,
    specs_xml
)
SELECT
    c.category_id,                         
    'LAB-MON-34-CURVED-240',              -- lab SKU 
    'LAB 34"" Curved Gaming Monitor',
    'Lab product for DML demo: 34-inch curved gaming monitor 240Hz.',
    549.99,
    1,
    '<specs>
       <brand>LG</brand>
       <color>Black</color>
       <size>34""</size>
       <panel>IPS</panel>
       <refresh_rate>240Hz</refresh_rate>
     </specs>'
FROM categories c
WHERE NOT EXISTS (
        SELECT 1 FROM products
        WHERE sku = 'LAB-MON-34-CURVED-240'
      )
ORDER BY c.category_id
LIMIT 1;


/* ------------------------------------------------------------
   2.2 – INSERT a lab PROMOTION with JSON rules (safe / idempotent)
   - Creates a promotion only if the code does not exist yet.
   - Demonstrates JSON_OBJECT and JSON_ARRAY usage.
   ------------------------------------------------------------ */

INSERT INTO promotions (
    code,
    name,
    description,
    start_date,
    end_date,
    discount_type,
    discount_value,
    rules_json,
    is_active
)
SELECT
    'LAB_CLEARANCE5',
    'Lab Clearance Extra 5%',
    'Lab promotion for DML demo: extra 5% clearance on selected items.',
    '2025-01-01',
    '2026-01-01',
    'percentage',
    5.00,
    JSON_OBJECT(
        'type', 'percentage',
        'discount_pct', 5,
        'min_order_value', 100,
        'eligible_channels', JSON_ARRAY('online','store'),
        'notes', 'Created for SQL DML lab demo'
    ),
    1
FROM (SELECT 1 AS dummy) AS x
WHERE NOT EXISTS (
        SELECT 1 FROM promotions
        WHERE code = 'LAB_CLEARANCE5'
      );


/* ------------------------------------------------------------
   2.3 – INSERT a lab INTERACTION with JSON metadata (safe)
   - Links to an existing customer and store.
   - Creates exactly one row with a distinctive subject.
   ------------------------------------------------------------ */

INSERT INTO interactions (
    customer_id,
    order_id,
    store_id,
    interaction_type,
    channel,
    subject,
    message,
    rating,
    metadata_json,
    created_at,
    updated_at
)
SELECT
    c.customer_id,
    NULL,                       -- no order linked, just a generic interaction
    s.store_id,
    'page_view',
    'web',
    'LAB - Sample interaction for DML',
    'Sample interaction created by the DML lab script.',
    NULL,
    JSON_OBJECT(
        'source', 'dml_lab_script',
        'initial_tag', 'lab_created'
    ),
    NOW(),
    NOW()
FROM
    (SELECT MIN(customer_id) AS customer_id FROM customers) AS c
    CROSS JOIN
    (SELECT MIN(store_id) AS store_id FROM stores) AS s
WHERE NOT EXISTS (
        SELECT 1 FROM interactions
        WHERE subject = 'LAB - Sample interaction for DML'
      );


/* ------------------------------------------------------------
   2.4 – UPDATE example: change status for one customer
   - Marks the customer with the smallest customer_id as 'inactive'.
   - Uses a JOIN with a subquery to avoid the "You can’t specify
     target table for update in FROM clause" limitation.
   ------------------------------------------------------------ */

UPDATE customers c
JOIN (
    SELECT MIN(customer_id) AS cid
    FROM customers
) AS x
  ON c.customer_id = x.cid
SET
    c.status     = 'inactive',
    c.updated_at = CURRENT_TIMESTAMP;


/* ------------------------------------------------------------
   2.5 – UPDATE example: adjust JSON rules in the lab promotion
   - Uses JSON_SET and COALESCE on rules_json.
   ------------------------------------------------------------ */

UPDATE promotions
SET
    rules_json = JSON_SET(
        COALESCE(rules_json, JSON_OBJECT()),
        '$.min_order_value', 150,
        '$.campaign_name',   'Lab Clearance Campaign',
        '$.priority',        2
    ),
    updated_at = CURRENT_TIMESTAMP
WHERE code = 'LAB_CLEARANCE5';


/* ------------------------------------------------------------
   2.6 – UPDATE example: tag the lab interaction in metadata_json
   - Demonstrates JSON_SET on interactions.metadata_json.
   ------------------------------------------------------------ */

UPDATE interactions
SET
    metadata_json = JSON_SET(
        COALESCE(metadata_json, JSON_OBJECT()),
        '$.campaign', 'SQL_DML_LAB_2025',
        '$.device',   'desktop'
    ),
    updated_at = CURRENT_TIMESTAMP
WHERE subject = 'LAB - Sample interaction for DML';


/* ------------------------------------------------------------
   2.7 – XML manipulation example on products.specs_xml
   - 2.7.1: Change <brand>LG</brand> to <brand>Samsung</brand>
            for the lab product SKU.
   - 2.7.2: Add <hdr_support>Yes</hdr_support> before </specs>
            if the tag is not present yet.
   ------------------------------------------------------------ */

-- 2.7.1: Update brand tag
UPDATE products
SET
    specs_xml  = REPLACE(
                    specs_xml,
                    '<brand>LG</brand>',
                    '<brand>Samsung</brand>'
                 ),
    updated_at = CURRENT_TIMESTAMP
WHERE sku = 'LAB-MON-34-CURVED-240'
  AND specs_xml LIKE '%<brand>LG</brand>%';


-- 2.7.2: Add HDR support tag if not present
UPDATE products
SET
    specs_xml  = REPLACE(
                    specs_xml,
                    '</specs>',
                    '<hdr_support>Yes</hdr_support></specs>'
                 ),
    updated_at = CURRENT_TIMESTAMP
WHERE sku = 'LAB-MON-34-CURVED-240'
  AND specs_xml NOT LIKE '%<hdr_support>%';


/* ------------------------------------------------------------
   2.8 – DELETE example: remove the lab interaction
   - Demonstrates a controlled DELETE using a specific subject.
   - Safe: it only affects the lab row, and will remove at most
     one record created by this script.
   ------------------------------------------------------------ */

DELETE FROM interactions
WHERE subject = 'LAB - Sample interaction for DML'
LIMIT 1;
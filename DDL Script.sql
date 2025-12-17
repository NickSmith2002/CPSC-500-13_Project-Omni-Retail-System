/* ---------------------------
   SECTION 0 — RESET / CREATE
   --------------------------- */
DROP DATABASE IF EXISTS omni_retail;
CREATE DATABASE omni_retail CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; 
USE omni_retail;

/* ---------------------------
   SECTION 1 (DDL) — TABLES
   --------------------------- */
   
-- 1) customers
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id     INT NOT NULL AUTO_INCREMENT,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(255) NOT NULL,
    phone           VARCHAR(20),
    date_of_birth   DATE,
    status          ENUM('active','inactive','blocked') NOT NULL DEFAULT 'active',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email),

    -- CHECK sem usar CURRENT_DATE (só evita datas totalmente absurdas)
    CONSTRAINT chk_customers_dob
        CHECK (date_of_birth IS NULL 
               OR (date_of_birth >= '1900-01-01' AND date_of_birth <= '2100-01-01'))
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
  
  DROP TABLE IF EXISTS addresses;
  CREATE TABLE addresses (
    address_id      INT NOT NULL AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    address_type    ENUM('billing','shipping','other') NOT NULL,
    line1           VARCHAR(150) NOT NULL,
    line2           VARCHAR(150),
    city            VARCHAR(100) NOT NULL,
    province        VARCHAR(100) NOT NULL,
    postal_code     VARCHAR(20)  NOT NULL,
    country         VARCHAR(50)  NOT NULL DEFAULT 'Canada',
    is_default      BOOLEAN      NOT NULL DEFAULT 0,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_addresses PRIMARY KEY (address_id),

    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_addresses_country
        CHECK (country <> ''),

    CONSTRAINT chk_addresses_postal_code
        CHECK (postal_code <> '')
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
  
DROP TABLE IF EXISTS customer_profiles;
CREATE TABLE customer_profiles (
    customer_id         INT NOT NULL,
    gender              ENUM('male','female','other','prefer_not_to_say'),
    marketing_opt_in    BOOLEAN NOT NULL DEFAULT 1,
    preferred_language  CHAR(2),   -- ex: 'en', 'pt'
    preferred_channel   ENUM('online','store','both') DEFAULT 'both',
    lifetime_value      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    risk_score          TINYINT,
    notes               TEXT,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP,

    -- 1:1:  PK is FK
    CONSTRAINT pk_customer_profiles PRIMARY KEY (customer_id),

    CONSTRAINT fk_customer_profiles_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_customer_profiles_ltv
        CHECK (lifetime_value >= 0),

    CONSTRAINT chk_customer_profiles_risk
        CHECK (risk_score IS NULL OR (risk_score >= 0 AND risk_score <= 100))
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP TABLE IF EXISTS stores;
CREATE TABLE stores (
    store_id      INT NOT NULL AUTO_INCREMENT,
    name          VARCHAR(100) NOT NULL,
    store_type    ENUM('physical','online') NOT NULL,
    phone         VARCHAR(20),
    email         VARCHAR(255),
    city          VARCHAR(100),
    province      VARCHAR(100),
    postal_code   VARCHAR(20),
    country       VARCHAR(50) NOT NULL DEFAULT 'Canada',
    is_active     BOOLEAN NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_stores PRIMARY KEY (store_id),

    CONSTRAINT chk_stores_country
        CHECK (country <> '')
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
    category_id         INT NOT NULL AUTO_INCREMENT,
    parent_category_id  INT NULL,
    name                VARCHAR(100) NOT NULL,
    description         VARCHAR(255),
    is_active           BOOLEAN NOT NULL DEFAULT 1,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_categories PRIMARY KEY (category_id),

    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT uq_categories_name UNIQUE (name)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

INSERT INTO categories (category_id, parent_category_id, name, description, is_active)
VALUES
  (1, NULL, 'Electronics',              'Electronics products',                         1),
  (2, NULL, 'Home & Kitchen',           'Home & Kitchen products',                      1),
  (3, NULL, 'Fashion',                  'Fashion products',                             1),
  (4, NULL, 'Sports & Outdoors',        'Sports & Outdoors products',                   1),
  (5, NULL, 'Beauty & Personal Care',   'Beauty & Personal Care products',              1),
  (6, NULL, 'Toys & Games',             'Toys & Games products',                        1),
  (7,  1,  'Smartphones',               'Smartphones under electronics',                1),
  (8,  1,  'Laptops',                   'Laptops under electronics',                    1),
  (9,  1,  'TV & Home Theater',         'TV & Home Theater under electronics',          1),
  (10, 2,  'Appliances',                'Appliances under home & kitchen',              1),
  (11, 2,  'Cookware',                  'Cookware under home & kitchen',                1),
  (12, 3,  'Men''s Clothing',           'Men''s Clothing under fashion',                1),
  (13, 3,  'Women''s Clothing',         'Women''s Clothing under fashion',              1),
  (14, 3,  'Shoes',                     'Shoes under fashion',                          1),
  (15, 4,  'Fitness Equipment',         'Fitness Equipment under sports & outdoors',    1),
  (16, 4,  'Camping & Hiking',          'Camping & Hiking under sports & outdoors',     1),
  (17, 5,  'Skincare',                  'Skincare under beauty & personal care',        1),
  (18, 5,  'Hair Care',                 'Hair Care under beauty & personal care',       1),
  (19, 6,  'Board Games',               'Board Games under toys & games',               1),
  (20, 6,  'Educational Toys',          'Educational Toys under toys & games',          1)
ON DUPLICATE KEY UPDATE
  parent_category_id = VALUES(parent_category_id),
  name               = VALUES(name),
  description        = VALUES(description),
  is_active          = VALUES(is_active);


DROP TABLE IF EXISTS products;
CREATE TABLE products (   -- HERE WE USE XML 
    product_id   INT NOT NULL AUTO_INCREMENT,
    category_id  INT NOT NULL,
    sku          VARCHAR(50)  NOT NULL,
    name         VARCHAR(150) NOT NULL,
    description  TEXT,
    list_price   DECIMAL(10,2) NOT NULL,
    active       BOOLEAN NOT NULL DEFAULT 1,
    specs_xml    TEXT NOT NULL,  -- XML stored as TEXT
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_products PRIMARY KEY (product_id),

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT uq_products_sku UNIQUE (sku),

    CONSTRAINT chk_products_price
        CHECK (list_price >= 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
  
 DROP TABLE IF EXISTS inventory;
 CREATE TABLE inventory (
    store_id          INT NOT NULL,
    product_id        INT NOT NULL,
    quantity          INT NOT NULL DEFAULT 0,
    safety_stock      INT NOT NULL DEFAULT 0,
    last_restocked_at DATETIME,

    CONSTRAINT pk_inventory PRIMARY KEY (store_id, product_id),

    CONSTRAINT fk_inventory_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_inventory_qty
        CHECK (quantity >= 0),

    CONSTRAINT chk_inventory_safety
        CHECK (safety_stock >= 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id            BIGINT NOT NULL AUTO_INCREMENT,
    customer_id         INT NOT NULL,
    store_id            INT NOT NULL,
    order_date          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status              ENUM('pending','confirmed','paid','shipped','delivered','cancelled','returned')
                            NOT NULL DEFAULT 'pending',
    total_amount        DECIMAL(10,2) NOT NULL,
    shipping_address_id INT,
    billing_address_id  INT,
    channel             ENUM('online','store') NOT NULL,
    payment_method      ENUM('credit_card','debit','cash','gift_card','paypal','other') NOT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_orders PRIMARY KEY (order_id),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_shipping_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES addresses(address_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_billing_address
        FOREIGN KEY (billing_address_id)
        REFERENCES addresses(address_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_orders_amount
        CHECK (total_amount >= 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_item_id    BIGINT NOT NULL AUTO_INCREMENT,
    order_id         BIGINT NOT NULL,
    product_id       INT NOT NULL,
    quantity         INT NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL,
    discount_amount  DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_line_amount DECIMAL(10,2) NOT NULL,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                   ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_order_items_qty
        CHECK (quantity > 0),

    CONSTRAINT chk_order_items_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_order_items_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_order_items_total
        CHECK (total_line_amount >= 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
  


DROP TABLE IF EXISTS promotions;
CREATE TABLE promotions (
    promotion_id    INT NOT NULL AUTO_INCREMENT,
    code            VARCHAR(50) NOT NULL,
    name            VARCHAR(150) NOT NULL,
    description     VARCHAR(255),
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    discount_type   ENUM('percentage','fixed_amount','free_shipping','bogo') NOT NULL,
    discount_value  DECIMAL(10,2) NOT NULL DEFAULT 0,
    rules_json      JSON,  -- JSON column with flexible rules
    is_active       BOOLEAN NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,
-- rules_json is where we store flexible promotion rules (min order, eligible channels, categories, stores, etc.).

    CONSTRAINT pk_promotions PRIMARY KEY (promotion_id),
    CONSTRAINT uq_promotions_code UNIQUE (code),

    CONSTRAINT chk_promotions_discount_value
        CHECK (discount_value >= 0),

    CONSTRAINT chk_promotions_dates
        CHECK (start_date <= end_date)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP TABLE IF EXISTS order_promotions;
CREATE TABLE order_promotions ( -- This table lets an order have multiple promotions, and a promotion apply to many orders.
    order_id       BIGINT NOT NULL,
    promotion_id   INT NOT NULL,
    applied_amount DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT pk_order_promotions PRIMARY KEY (order_id, promotion_id),

    CONSTRAINT fk_order_promotions_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_promotions_promotion
        FOREIGN KEY (promotion_id)
        REFERENCES promotions(promotion_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_order_promotions_amount
        CHECK (applied_amount >= 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP TABLE IF EXISTS interactions;
CREATE TABLE interactions (
    interaction_id   BIGINT NOT NULL AUTO_INCREMENT,
    customer_id      INT NOT NULL,
    order_id         BIGINT NULL,
    store_id         INT NULL,
    interaction_type ENUM(
                        'page_view',
                        'add_to_cart',
                        'purchase',
                        'review',
                        'support_ticket',
                        'email_open',
                        'email_click',
                        'store_visit'
                      ) NOT NULL,
    channel          ENUM('web','mobile_app','email','store','support') NOT NULL,
    subject          VARCHAR(255),
    message          TEXT,
    rating           TINYINT,
    metadata_json    JSON,  -- JSON metadata for flexible attributes, It can hold things like device, browser, campaign, session duration, etc.
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                   ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_interactions PRIMARY KEY (interaction_id),

    CONSTRAINT fk_interactions_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_interactions_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_interactions_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_interactions_rating
        CHECK (rating IS NULL OR (rating BETWEEN 1 AND 5))
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

  DROP TABLE IF EXISTS order_status_logs;
  CREATE TABLE order_status_logs (
    log_id      BIGINT NOT NULL AUTO_INCREMENT,
    order_id    BIGINT NOT NULL,
    old_status  ENUM('pending','confirmed','paid','shipped','delivered','cancelled','returned') NULL,
    new_status  ENUM('pending','confirmed','paid','shipped','delivered','cancelled','returned') NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(100),  -- optional: system / user / batch job

    CONSTRAINT pk_order_status_logs PRIMARY KEY (log_id),

    CONSTRAINT fk_order_status_logs_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
  
DELIMITER $$
CREATE TRIGGER trg_orders_status_log
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO order_status_logs (
            order_id,
            old_status,
            new_status,
            changed_at,
            changed_by
        )
        VALUES (
            NEW.order_id,
            OLD.status,
            NEW.status,
            CURRENT_TIMESTAMP,
            'system'
        );
    END IF;
END$$

DELIMITER ;

/* -----------------------------------------------------------
   SECTION 1B – Views
   ----------------------------------------------------------- */

USE omni_retail;

/* -----------------------------------------------------------
   View 1 – vw_orders_enriched
   Purpose:
     - Provide an enriched view of orders with customer and store
       information for reporting and analytics.
   ----------------------------------------------------------- */

DROP VIEW IF EXISTS vw_orders_enriched;

CREATE VIEW vw_orders_enriched AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    o.channel,
    o.payment_method,
    o.total_amount,
    o.customer_id,
    c.first_name,
    c.last_name,
    c.email AS customer_email,
    o.store_id,
    s.name  AS store_name,
    s.store_type,
    s.city  AS store_city,
    s.province AS store_province
FROM orders o
JOIN customers c
  ON c.customer_id = o.customer_id
JOIN stores s
  ON s.store_id = o.store_id;


/* -----------------------------------------------------------
   View 2 – vw_product_sales_summary
   Purpose:
     - Summarize sales per product, combining products,
       categories, and order_items.
   ----------------------------------------------------------- */

DROP VIEW IF EXISTS vw_product_sales_summary;

USE omni_retail;

DROP VIEW IF EXISTS vw_product_sales_summary;

CREATE VIEW vw_product_sales_summary AS
SELECT
    ps.product_id,
    ps.sku,
    ps.product_name,
    ps.category_name,
    ps.list_price,
    ps.active,
    ps.units_sold,
    ps.total_revenue,
    ps.total_discount_amount,
    ps.num_orders
FROM (
    SELECT
        p.product_id,
        p.sku,
        p.name        AS product_name,
        c.name        AS category_name,
        p.list_price,
        p.active,
        COALESCE(SUM(oi.quantity), 0)           AS units_sold,
        COALESCE(SUM(oi.total_line_amount), 0)  AS total_revenue,
        COALESCE(SUM(oi.discount_amount), 0)    AS total_discount_amount,
        COUNT(DISTINCT oi.order_id)             AS num_orders
    FROM products p
    LEFT JOIN categories   c  ON c.category_id = p.category_id
    LEFT JOIN order_items  oi ON oi.product_id = p.product_id
    LEFT JOIN orders       o  ON o.order_id = oi.order_id
                             AND o.status IN ('paid','shipped','delivered')
    GROUP BY
        p.product_id,
        p.sku,
        p.name,
        c.name,
        p.list_price,
        p.active
) AS ps;

    
    /* -----------------------------------------------------------
   SECTION 1C – Indexes
   Notes:
     - Additional indexes to improve query performance.
     - Includes a FULLTEXT index for product search.
   ----------------------------------------------------------- */

USE omni_retail;

/* -----------------------------------------------------------
   1C.1 – Regular composite index on orders
   Purpose:
     - Speed up lookups of orders by customer, status, and date.
   ----------------------------------------------------------- */

CREATE INDEX idx_orders_customer_status_date
ON orders (customer_id, status, order_date);


/* -----------------------------------------------------------
   1C.2 – Index on order_items by product_id
   Purpose:
     - Speed up aggregations and lookups by product_id.
   ----------------------------------------------------------- */

CREATE INDEX idx_order_items_product
ON order_items (product_id);


/* -----------------------------------------------------------
   1C.3 – FULLTEXT index on products (name, description)
   Purpose:
     - Support full-text search queries on products.
   ----------------------------------------------------------- */

CREATE FULLTEXT INDEX idx_ft_products_name_description
ON products (name, description);

/* -----------------------------------------------------------
   SECTION 1D – Stored Procedures
   ----------------------------------------------------------- */

USE omni_retail;

DELIMITER $$

/* -----------------------------------------------------------
   1D.1 – sp_apply_promotion_to_order
   Purpose:
     - Apply a promotion code to an existing order.
     - Validate that the promotion is active, within valid dates,
       and respects JSON rules (min_order_value, eligible_channels).
     - Insert into order_promotions and decrease orders.total_amount.
   ----------------------------------------------------------- */
CREATE PROCEDURE sp_apply_promotion_to_order (
    IN p_order_id   BIGINT,
    IN p_promo_code VARCHAR(50)
)
BEGIN
    DECLARE v_promotion_id   INT;
    DECLARE v_discount_type  VARCHAR(20);
    DECLARE v_discount_value DECIMAL(10,2);
    DECLARE v_is_active      BOOLEAN;
    DECLARE v_start_date     DATE;
    DECLARE v_end_date       DATE;
    DECLARE v_rules_json     JSON;

    DECLARE v_order_total    DECIMAL(10,2);
    DECLARE v_order_channel  VARCHAR(20);
    DECLARE v_min_order_value DECIMAL(10,2);
    DECLARE v_allowed_channel_flag TINYINT;
    DECLARE v_applied_amount DECIMAL(10,2);

    /* 1) Fetch promotion by code */
    SELECT
        promotion_id,
        discount_type,
        discount_value,
        is_active,
        start_date,
        end_date,
        rules_json
    INTO
        v_promotion_id,
        v_discount_type,
        v_discount_value,
        v_is_active,
        v_start_date,
        v_end_date,
        v_rules_json
    FROM promotions
    WHERE code = p_promo_code
    LIMIT 1;

    IF v_promotion_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Promotion code not found';
    END IF;

    /* 2) Basic validity checks (active + dates) */
    IF v_is_active = 0 OR CURDATE() NOT BETWEEN v_start_date AND v_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Promotion is not active or outside valid dates';
    END IF;

    /* 3) Fetch order info */
    SELECT
        total_amount,
        channel
    INTO
        v_order_total,
        v_order_channel
    FROM orders
    WHERE order_id = p_order_id;

    IF v_order_total IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order not found';
    END IF;

    /* 4) Do not apply the same promotion twice to the same order */
    IF EXISTS (
        SELECT 1
        FROM order_promotions op
        WHERE op.order_id = p_order_id
          AND op.promotion_id = v_promotion_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Promotion already applied to this order';
    END IF;

    /* 5) Read JSON rules (optional) */
    -- Example rules_json:
    -- {
    --   "type": "percentage",
    --   "discount_pct": 10,
    --   "min_order_value": 200,
    --   "eligible_channels": ["online","store"]
    -- }

    -- Minimum order value rule
    SET v_min_order_value = CAST(
        JSON_UNQUOTE(JSON_EXTRACT(v_rules_json, '$.min_order_value')) AS DECIMAL(10,2)
    );

    IF v_min_order_value IS NOT NULL AND v_order_total < v_min_order_value THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order total is below minimum value for this promotion';
    END IF;

    -- Eligible channels rule
    SET v_allowed_channel_flag = COALESCE(
        JSON_CONTAINS(
            JSON_EXTRACT(v_rules_json, '$.eligible_channels'),
            JSON_QUOTE(v_order_channel)
        ),
        1  -- if eligible_channels is not defined, allow all channels
    );

    IF v_allowed_channel_flag = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order channel is not eligible for this promotion';
    END IF;

    /* 6) Calculate applied_amount based on discount_type */
    SET v_applied_amount = 0;

    IF v_discount_type = 'percentage' THEN
        SET v_applied_amount = ROUND(v_order_total * (v_discount_value / 100), 2);
    ELSEIF v_discount_type = 'fixed_amount' THEN
        SET v_applied_amount = v_discount_value;
    ELSEIF v_discount_type = 'free_shipping' THEN
        -- In a real system we would apply this to shipping cost.
        -- Here we just keep applied_amount = 0 and still record usage.
        SET v_applied_amount = 0;
    ELSE
        -- Other types (like bogo) are not calculated here.
        SET v_applied_amount = 0;
    END IF;

    -- Never let the discount exceed the order total.
    SET v_applied_amount = LEAST(v_applied_amount, v_order_total);

    /* 7) Insert into order_promotions */
    INSERT INTO order_promotions (order_id, promotion_id, applied_amount)
    VALUES (p_order_id, v_promotion_id, v_applied_amount);

    /* 8) Decrease the order total_amount */
    UPDATE orders
    SET total_amount = GREATEST(0, total_amount - v_applied_amount),
        updated_at   = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
END$$


/* -----------------------------------------------------------
   1D.2 – sp_update_inventory_for_order
   Purpose:
     - After an order is confirmed/paid, decrease inventory
       quantities per store and product.
     - Returns the updated inventory rows for that order.
   ----------------------------------------------------------- */
CREATE PROCEDURE sp_update_inventory_for_order (
    IN p_order_id BIGINT
)
BEGIN
    /* 1) Check that the order exists */
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order not found';
    END IF;

    /* 2) Decrease inventory quantities based on order_items */
    UPDATE inventory i
    JOIN orders o
      ON o.store_id = i.store_id
    JOIN order_items oi
      ON oi.order_id = o.order_id
     AND oi.product_id = i.product_id
    SET i.quantity = GREATEST(0, i.quantity - oi.quantity)
    WHERE o.order_id = p_order_id;

    /* 3) Return the updated inventory rows for this order */
    SELECT
        i.store_id,
        i.product_id,
        i.quantity,
        i.safety_stock,
        i.last_restocked_at
    FROM inventory i
    JOIN orders o
      ON o.store_id = i.store_id
    JOIN order_items oi
      ON oi.order_id = o.order_id
     AND oi.product_id = i.product_id
    WHERE o.order_id = p_order_id;
END$$

DELIMITER ;





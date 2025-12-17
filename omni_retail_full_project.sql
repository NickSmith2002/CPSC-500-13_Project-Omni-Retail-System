/* ============================================================
   OMNI_RETAIL – FULL PROJECT SCRIPT
   - SECTION 0: Reset / Create DB
   - SECTION 1: DDL (tables, views, indexes, triggers, SPs)
   - SECTION 2: DML (demo inserts/updates/deletes)
   - SECTION 3: DQL (analytics / ML datasets / full-text)
   ============================================================ */


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

    CONSTRAINT chk_customers_dob
        CHECK (date_of_birth IS NULL
               OR (date_of_birth >= '1900-01-01' AND date_of_birth <= '2100-01-01'))
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;


-- 2) addresses
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


-- 3) customer_profiles (1:1 com customers)
DROP TABLE IF EXISTS customer_profiles;
CREATE TABLE customer_profiles (
    customer_id         INT NOT NULL,
    gender              ENUM('male','female','other','prefer_not_to_say'),
    marketing_opt_in    BOOLEAN NOT NULL DEFAULT 1,
    preferred_language  CHAR(2),
    preferred_channel   ENUM('online','store','both') DEFAULT 'both',
    lifetime_value      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    risk_score          TINYINT,
    notes               TEXT,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP,

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


-- 4) stores
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


-- 5) categories (hierarquia self-FK)
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


-- carga inicial de categorias (pequena, feita via DML aqui)
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


-- 6) products (usa XML em TEXT)
DROP TABLE IF EXISTS products;
CREATE TABLE products (
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


-- 7) inventory
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


-- 8) orders
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


-- 9) order_items
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_item_id     BIGINT NOT NULL AUTO_INCREMENT,
    order_id          BIGINT NOT NULL,
    product_id        INT NOT NULL,
    quantity          INT NOT NULL,
    unit_price        DECIMAL(10,2) NOT NULL,
    discount_amount   DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_line_amount DECIMAL(10,2) NOT NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
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


-- 10) promotions (usa JSON)
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
    rules_json      JSON,
    is_active       BOOLEAN NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_promotions PRIMARY KEY (promotion_id),
    CONSTRAINT uq_promotions_code UNIQUE (code),

    CONSTRAINT chk_promotions_discount_value
        CHECK (discount_value >= 0),

    CONSTRAINT chk_promotions_dates
        CHECK (start_date <= end_date)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;


-- 11) order_promotions (N:N orders x promotions)
DROP TABLE IF EXISTS order_promotions;
CREATE TABLE order_promotions (
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


-- 12) interactions (usa JSON)
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
    metadata_json    JSON,
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


-- 13) order_status_logs (para trigger de log de status de pedido)
DROP TABLE IF EXISTS order_status_logs;
CREATE TABLE order_status_logs (
    log_id      BIGINT NOT NULL AUTO_INCREMENT,
    order_id    BIGINT NOT NULL,
    old_status  ENUM('pending','confirmed','paid','shipped','delivered','cancelled','returned') NULL,
    new_status  ENUM('pending','confirmed','paid','shipped','delivered','cancelled','returned') NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by  VARCHAR(100),

    CONSTRAINT pk_order_status_logs PRIMARY KEY (log_id),

    CONSTRAINT fk_order_status_logs_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;


/* -----------------------------------------------------------
   SECTION 1A – Trigger (status change logging)
   ----------------------------------------------------------- */
DELIMITER $$

DROP TRIGGER IF EXISTS trg_orders_status_log$$
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

-- View 1 – vw_orders_enriched
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
    s.name      AS store_name,
    s.store_type,
    s.city      AS store_city,
    s.province  AS store_province
FROM orders o
JOIN customers c
  ON c.customer_id = o.customer_id
JOIN stores s
  ON s.store_id = o.store_id;


-- View 2 – vw_product_sales_summary
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
   ----------------------------------------------------------- */

-- 1C.1 – composite index em orders
CREATE INDEX idx_orders_customer_status_date
ON orders (customer_id, status, order_date);

-- 1C.2 – index em order_items por product_id
CREATE INDEX idx_order_items_product
ON order_items (product_id);

-- 1C.3 – FULLTEXT em products (name, description)
CREATE FULLTEXT INDEX idx_ft_products_name_description
ON products (name, description);


/* -----------------------------------------------------------
   SECTION 1D – Stored Procedures
   ----------------------------------------------------------- */

DELIMITER $$

-- 1D.1 – sp_apply_promotion_to_order
DROP PROCEDURE IF EXISTS sp_apply_promotion_to_order$$
CREATE PROCEDURE sp_apply_promotion_to_order (
    IN p_order_id   BIGINT,
    IN p_promo_code VARCHAR(50)
)
BEGIN
    DECLARE v_promotion_id    INT;
    DECLARE v_discount_type   VARCHAR(20);
    DECLARE v_discount_value  DECIMAL(10,2);
    DECLARE v_is_active       BOOLEAN;
    DECLARE v_start_date      DATE;
    DECLARE v_end_date        DATE;
    DECLARE v_rules_json      JSON;

    DECLARE v_order_total     DECIMAL(10,2);
    DECLARE v_order_channel   VARCHAR(20);
    DECLARE v_min_order_value DECIMAL(10,2);
    DECLARE v_allowed_channel_flag TINYINT;
    DECLARE v_applied_amount  DECIMAL(10,2);

    -- 1) Fetch promotion by code
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

    -- 2) Validity checks (active + dates)
    IF v_is_active = 0 OR CURDATE() NOT BETWEEN v_start_date AND v_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Promotion is not active or outside valid dates';
    END IF;

    -- 3) Fetch order info
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

    -- 4) Avoid applying same promo twice
    IF EXISTS (
        SELECT 1
        FROM order_promotions op
        WHERE op.order_id = p_order_id
          AND op.promotion_id = v_promotion_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Promotion already applied to this order';
    END IF;

    -- 5) JSON rules (optional)
    SET v_min_order_value = CAST(
        JSON_UNQUOTE(JSON_EXTRACT(v_rules_json, '$.min_order_value')) AS DECIMAL(10,2)
    );

    IF v_min_order_value IS NOT NULL AND v_order_total < v_min_order_value THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order total is below minimum value for this promotion';
    END IF;

    SET v_allowed_channel_flag = COALESCE(
        JSON_CONTAINS(
            JSON_EXTRACT(v_rules_json, '$.eligible_channels'),
            JSON_QUOTE(v_order_channel)
        ),
        1
    );

    IF v_allowed_channel_flag = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order channel is not eligible for this promotion';
    END IF;

    -- 6) Calculate discount amount
    SET v_applied_amount = 0;

    IF v_discount_type = 'percentage' THEN
        SET v_applied_amount = ROUND(v_order_total * (v_discount_value / 100), 2);
    ELSEIF v_discount_type = 'fixed_amount' THEN
        SET v_applied_amount = v_discount_value;
    ELSEIF v_discount_type = 'free_shipping' THEN
        SET v_applied_amount = 0;
    ELSE
        SET v_applied_amount = 0;
    END IF;

    SET v_applied_amount = LEAST(v_applied_amount, v_order_total);

    -- 7) Insert into order_promotions
    INSERT INTO order_promotions (order_id, promotion_id, applied_amount)
    VALUES (p_order_id, v_promotion_id, v_applied_amount);

    -- 8) Update order total_amount
    UPDATE orders
    SET total_amount = GREATEST(0, total_amount - v_applied_amount),
        updated_at   = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
END$$


-- 1D.2 – sp_update_inventory_for_order
DROP PROCEDURE IF EXISTS sp_update_inventory_for_order$$
CREATE PROCEDURE sp_update_inventory_for_order (
    IN p_order_id BIGINT
)
BEGIN
    -- 1) Check order exists
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order not found';
    END IF;

    -- 2) Decrease inventory based on order_items
    UPDATE inventory i
    JOIN orders o
      ON o.store_id = i.store_id
    JOIN order_items oi
      ON oi.order_id = o.order_id
     AND oi.product_id = i.product_id
    SET i.quantity = GREATEST(0, i.quantity - oi.quantity)
    WHERE o.order_id = p_order_id;

    -- 3) Return updated inventory rows for this order
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


/* ============================================================
   SECTION 2 – DML (Data Loading and Manipulation)
   Nota:
     - Este bloco é de DML de demonstração (não inclui CSV).
     - Scripts de carga em massa vêm dos CSV via Import Wizard.
   ============================================================ */


-- 2.1 – INSERT de produto "lab" com XML em specs_xml
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
    'LAB-MON-34-CURVED-240',
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


-- 2.2 – INSERT de promoção "lab" com JSON rules_json
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


-- 2.3 – INSERT de interação "lab" com JSON metadata_json
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
    NULL,
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


-- 2.4 – UPDATE: marca o menor customer_id como 'inactive'
UPDATE customers c
JOIN (
    SELECT MIN(customer_id) AS cid
    FROM customers
) AS x
  ON c.customer_id = x.cid
SET
    c.status     = 'inactive',
    c.updated_at = CURRENT_TIMESTAMP;


-- 2.5 – UPDATE JSON em promotions.rules_json (lab promo)
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


-- 2.6 – UPDATE JSON em interactions.metadata_json (lab interaction)
UPDATE interactions
SET
    metadata_json = JSON_SET(
        COALESCE(metadata_json, JSON_OBJECT()),
        '$.campaign', 'SQL_DML_LAB_2025',
        '$.device',   'desktop'
    ),
    updated_at = CURRENT_TIMESTAMP
WHERE subject = 'LAB - Sample interaction for DML';


-- 2.7 – XML em specs_xml (produto lab)
-- 2.7.1: Troca <brand>LG</brand> por <brand>Samsung</brand>
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

-- 2.7.2: Adiciona <hdr_support>Yes</hdr_support> antes de </specs>
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


-- 2.8 – DELETE: remove a interação "lab" (controlada)
DELETE FROM interactions
WHERE subject = 'LAB - Sample interaction for DML'
LIMIT 1;


/* ============================================================
   SECTION 3 – DQL (Analytics / ML Datasets / Full-text)
   ============================================================ */


-- 3.1 – Monthly revenue by channel (with running total)
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
    SUM(monthly_revenue) OVER (
        PARTITION BY channel
        ORDER BY order_year, order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue_channel
FROM monthly_stats
ORDER BY
    order_year,
    order_month,
    channel,
    store_type;


-- 3.2 – XML example: sales by product brand
WITH product_brands AS (
    SELECT
        p.product_id,
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


-- 3.3 – JSON example: promotion usage summary
SELECT
    pr.promotion_id,
    pr.code,
    pr.name AS promotion_name,
    pr.discount_type,
    pr.discount_value,
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


/* ML Dataset 1 – Customer churn classification */
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


-- 3.5 – ML Dataset 2: Order value regression
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


-- 3.6 – ML Dataset 3: Product performance / inventory clustering
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
    SUBSTRING_INDEX(
        SUBSTRING_INDEX(p.specs_xml, '<brand>', -1),
        '</brand>',
        1
    ) AS brand,
    SUBSTRING_INDEX(
        SUBSTRING_INDEX(p.specs_xml, '<size>', -1),
        '</size>',
        1
    ) AS size,
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


-- 3.7 – Full-text search on products (name + description)
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
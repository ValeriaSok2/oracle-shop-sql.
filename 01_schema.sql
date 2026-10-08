-- 01_schema.sql: схема интернет-магазина (Oracle 11g и новее)
-- Запускать под пользователем shop

CREATE SEQUENCE seq_categories  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_products    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_customers   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_orders      START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_price_audit START WITH 1 INCREMENT BY 1;

CREATE TABLE categories (
  category_id NUMBER PRIMARY KEY,
  name        VARCHAR2(100) NOT NULL,
  parent_id   NUMBER REFERENCES categories(category_id)
);

CREATE TABLE products (
  product_id  NUMBER PRIMARY KEY,
  name        VARCHAR2(200) NOT NULL,
  category_id NUMBER NOT NULL REFERENCES categories(category_id),
  price       NUMBER(10,2) NOT NULL CHECK (price > 0)
);

CREATE TABLE customers (
  customer_id NUMBER PRIMARY KEY,
  full_name   VARCHAR2(150) NOT NULL,
  email       VARCHAR2(150) NOT NULL UNIQUE,
  city        VARCHAR2(100),
  created_at  DATE DEFAULT SYSDATE NOT NULL
);

CREATE TABLE orders (
  order_id    NUMBER PRIMARY KEY,
  customer_id NUMBER NOT NULL REFERENCES customers(customer_id),
  order_date  DATE DEFAULT SYSDATE NOT NULL,
  status      VARCHAR2(20) DEFAULT 'NEW' NOT NULL
              CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED'))
);

CREATE TABLE order_items (
  order_id   NUMBER NOT NULL REFERENCES orders(order_id),
  product_id NUMBER NOT NULL REFERENCES products(product_id),
  quantity   NUMBER(5) NOT NULL CHECK (quantity > 0),
  unit_price NUMBER(10,2) NOT NULL,
  CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id)
);

CREATE TABLE price_audit (
  audit_id   NUMBER PRIMARY KEY,
  product_id NUMBER,
  old_price  NUMBER(10,2),
  new_price  NUMBER(10,2),
  changed_at DATE DEFAULT SYSDATE,
  changed_by VARCHAR2(100) DEFAULT USER
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_products_cat    ON products(category_id);

-- Проверка: должно вернуться 6 таблиц
SELECT table_name FROM user_tables ORDER BY table_name;

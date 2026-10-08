-- 02_data.sql: справочники и генерация тестовых данных

INSERT INTO categories VALUES (seq_categories.NEXTVAL, 'Электроника', NULL);
INSERT INTO categories VALUES (seq_categories.NEXTVAL, 'Смартфоны', 1);
INSERT INTO categories VALUES (seq_categories.NEXTVAL, 'Ноутбуки', 1);
INSERT INTO categories VALUES (seq_categories.NEXTVAL, 'Одежда', NULL);
INSERT INTO categories VALUES (seq_categories.NEXTVAL, 'Футболки', 4);
INSERT INTO categories VALUES (seq_categories.NEXTVAL, 'Куртки', 4);

INSERT INTO products VALUES (seq_products.NEXTVAL, 'Смартфон A1', 2, 29990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Смартфон B2', 2, 45990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Смартфон C3', 2, 62990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Ноутбук D4', 3, 54990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Ноутбук E5', 3, 89990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Футболка белая', 5, 990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Футболка чёрная', 5, 1090);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Футболка с принтом', 5, 1490);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Куртка осенняя', 6, 7990);
INSERT INTO products VALUES (seq_products.NEXTVAL, 'Куртка зимняя', 6, 12990);
COMMIT;

-- 200 клиентов, 2000 заказов за последний год, около 4000 позиций заказов
DECLARE
  TYPE t_city IS VARRAY(5) OF VARCHAR2(50);
  v_cities   t_city := t_city('Москва','Санкт-Петербург','Казань','Новосибирск','Екатеринбург');
  v_order_id NUMBER;
  v_prod     NUMBER;
  v_items    NUMBER;
BEGIN
  FOR i IN 1..200 LOOP
    INSERT INTO customers (customer_id, full_name, email, city)
    VALUES (seq_customers.NEXTVAL, 'Клиент ' || i, 'user' || i || '@example.com',
            v_cities(TRUNC(DBMS_RANDOM.VALUE(1, 6))));
  END LOOP;

  FOR i IN 1..2000 LOOP
    v_order_id := seq_orders.NEXTVAL;
    INSERT INTO orders (order_id, customer_id, order_date, status)
    VALUES (v_order_id,
            TRUNC(DBMS_RANDOM.VALUE(1, 201)),
            TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 365)),
            CASE TRUNC(DBMS_RANDOM.VALUE(1, 5))
              WHEN 1 THEN 'NEW' WHEN 2 THEN 'PAID'
              WHEN 3 THEN 'SHIPPED' ELSE 'CANCELLED' END);

    v_prod  := TRUNC(DBMS_RANDOM.VALUE(1, 11));
    v_items := TRUNC(DBMS_RANDOM.VALUE(1, 4));
    FOR k IN 0 .. v_items - 1 LOOP
      INSERT INTO order_items (order_id, product_id, quantity, unit_price)
      SELECT v_order_id, product_id, TRUNC(DBMS_RANDOM.VALUE(1, 4)), price
      FROM products
      WHERE product_id = MOD(v_prod + k - 1, 10) + 1;
    END LOOP;
  END LOOP;
  COMMIT;
END;
/

-- Проверка: 6 / 10 / 200 / 2000 / около 4000
SELECT (SELECT COUNT(*) FROM categories)  AS categories,
       (SELECT COUNT(*) FROM products)    AS products,
       (SELECT COUNT(*) FROM customers)   AS customers,
       (SELECT COUNT(*) FROM orders)      AS orders,
       (SELECT COUNT(*) FROM order_items) AS items
FROM dual;

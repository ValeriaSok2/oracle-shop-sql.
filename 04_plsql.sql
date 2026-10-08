-- 04_plsql.sql: процедура, функция, триггер

SET SERVEROUTPUT ON

-- Добавление позиции в заказ: цена берётся из каталога
CREATE OR REPLACE PROCEDURE add_order_item (
  p_order_id   IN NUMBER,
  p_product_id IN NUMBER,
  p_quantity   IN NUMBER
) AS
  v_price products.price%TYPE;
BEGIN
  SELECT price INTO v_price
  FROM products
  WHERE product_id = p_product_id;

  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  VALUES (p_order_id, p_product_id, p_quantity, v_price);

  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Товар не найден: ' || p_product_id);
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20002, 'Товар уже есть в заказе');
END add_order_item;
/

-- Сумма заказа
CREATE OR REPLACE FUNCTION order_total (p_order_id NUMBER) RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(quantity * unit_price), 0)
  INTO v_total
  FROM order_items
  WHERE order_id = p_order_id;
  RETURN v_total;
END order_total;
/

-- Аудит изменения цен
CREATE OR REPLACE TRIGGER trg_products_price_audit
AFTER UPDATE OF price ON products
FOR EACH ROW
WHEN (OLD.price <> NEW.price)
BEGIN
  INSERT INTO price_audit (audit_id, product_id, old_price, new_price)
  VALUES (seq_price_audit.NEXTVAL, :OLD.product_id, :OLD.price, :NEW.price);
END trg_products_price_audit;
/

-- Проверка триггера: в price_audit появится строка 29990 -> 27990
UPDATE products SET price = 27990 WHERE product_id = 1;
COMMIT;
SELECT * FROM price_audit;

-- Проверка процедуры и функции: сумма заказа = 2 * 27990 + 54990 = 110970
DECLARE
  v_id NUMBER;
BEGIN
  INSERT INTO orders (order_id, customer_id)
  VALUES (seq_orders.NEXTVAL, 1)
  RETURNING order_id INTO v_id;

  add_order_item(v_id, 1, 2);
  add_order_item(v_id, 4, 1);

  DBMS_OUTPUT.PUT_LINE('Заказ ' || v_id || ', сумма: ' || order_total(v_id));
END;
/

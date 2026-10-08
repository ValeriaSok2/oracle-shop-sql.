-- 05_optimization.sql: влияние составного индекса на план выполнения

-- Большая таблица для демонстрации (200 000 строк)
CREATE TABLE orders_big AS
SELECT LEVEL AS order_id,
       TRUNC(DBMS_RANDOM.VALUE(1, 201)) AS customer_id,
       TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 365)) AS order_date,
       CASE TRUNC(DBMS_RANDOM.VALUE(1, 5))
         WHEN 1 THEN 'NEW' WHEN 2 THEN 'PAID'
         WHEN 3 THEN 'SHIPPED' ELSE 'CANCELLED' END AS status
FROM dual
CONNECT BY LEVEL <= 200000;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDERS_BIG');

-- Запрос с широким фильтром (около 900 строк из 200 000): индекс не нужен
EXPLAIN PLAN FOR
SELECT * FROM orders_big
WHERE customer_id = 42 AND order_date >= DATE '2026-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Составной индекс: сначала столбец с равенством, затем диапазонный
CREATE INDEX idx_big_cust_date ON orders_big(customer_id, order_date);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDERS_BIG');

-- Селективный запрос (неделя по одному клиенту): индекс используется
EXPLAIN PLAN FOR
SELECT * FROM orders_big
WHERE customer_id = 42
  AND order_date BETWEEN DATE '2026-09-01' AND DATE '2026-09-07';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Тот же запрос с принудительным полным сканированием, для сравнения
EXPLAIN PLAN FOR
SELECT /*+ FULL(orders_big) */ * FROM orders_big
WHERE customer_id = 42
  AND order_date BETWEEN DATE '2026-09-01' AND DATE '2026-09-07';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

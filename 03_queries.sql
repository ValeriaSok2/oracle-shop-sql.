-- 03_queries.sql: аналитические запросы

-- 1. Топ-5 клиентов по выручке (JOIN, GROUP BY, ROWNUM)
SELECT * FROM (
  SELECT c.full_name, SUM(oi.quantity * oi.unit_price) AS revenue
  FROM customers c
  JOIN orders o       ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status <> 'CANCELLED'
  GROUP BY c.full_name
  ORDER BY revenue DESC
)
WHERE ROWNUM <= 5;

-- 2. Рейтинг товаров внутри категории (оконная функция RANK)
SELECT cat.name AS category, p.name AS product,
       SUM(oi.quantity) AS qty,
       RANK() OVER (PARTITION BY cat.category_id
                    ORDER BY SUM(oi.quantity) DESC) AS rnk
FROM order_items oi
JOIN products p     ON p.product_id = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
GROUP BY cat.category_id, cat.name, p.name
ORDER BY cat.name, rnk;

-- 3. Выручка по месяцам и рост к предыдущему месяцу (CTE + LAG)
WITH monthly AS (
  SELECT TRUNC(o.order_date, 'MM') AS month,
         SUM(oi.quantity * oi.unit_price) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status <> 'CANCELLED'
  GROUP BY TRUNC(o.order_date, 'MM')
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
             / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 1) AS growth_pct
FROM monthly
ORDER BY month;

-- 4. Дерево категорий (иерархический запрос)
SELECT LPAD(' ', 2 * (LEVEL - 1)) || name AS category_tree
FROM categories
START WITH parent_id IS NULL
CONNECT BY PRIOR category_id = parent_id
ORDER SIBLINGS BY name;

-- 5. Клиенты без заказов за последние 90 дней (NOT EXISTS)
SELECT c.full_name, c.email
FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id
    AND o.order_date >= SYSDATE - 90
);

-- 6. Обновление или добавление товара (MERGE)
MERGE INTO products p
USING (SELECT 'Смартфон A1' AS name, 2 AS category_id, 27990 AS price FROM dual) s
ON (p.name = s.name)
WHEN MATCHED THEN UPDATE SET p.price = s.price
WHEN NOT MATCHED THEN INSERT (product_id, name, category_id, price)
                      VALUES (seq_products.NEXTVAL, s.name, s.category_id, s.price);

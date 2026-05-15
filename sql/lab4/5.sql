EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT
    u.full_name,
    a.name AS account_name,
    c.name AS category_name,
    COUNT(t.id) AS transaction_count,
    SUM(t.amount) AS total_amount
FROM transactions t
         JOIN accounts a ON t.account_id = a.id
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON t.category_id = c.id
WHERE t.type = 'expense'
  AND t.amount > 100
  AND t.transaction_date >= '2025-01-01'
GROUP BY u.full_name, a.name, c.name
ORDER BY total_amount DESC
    LIMIT 20;



BEGIN;

CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_category_id ON transactions(category_id);
CREATE INDEX idx_transactions_type_amount_date ON transactions(type, amount, transaction_date);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT
    u.full_name,
    a.name AS account_name,
    c.name AS category_name,
    COUNT(t.id) AS transaction_count,
    SUM(t.amount) AS total_amount
FROM transactions t
         JOIN accounts a ON t.account_id = a.id
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON t.category_id = c.id
WHERE t.type = 'expense'
  AND t.amount > 100
  AND t.transaction_date >= '2025-01-01'
GROUP BY u.full_name, a.name, c.name
ORDER BY total_amount DESC
    LIMIT 20;

ROLLBACK;



BEGIN;

CREATE INDEX idx_transactions_covering ON transactions(type, amount, transaction_date, account_id, category_id);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT
    u.full_name,
    a.name AS account_name,
    c.name AS category_name,
    COUNT(t.id) AS transaction_count,
    SUM(t.amount) AS total_amount
FROM transactions t
         JOIN accounts a ON t.account_id = a.id
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON t.category_id = c.id
WHERE t.type = 'expense'
  AND t.amount > 100
  AND t.transaction_date >= '2025-01-01'
GROUP BY u.full_name, a.name, c.name
ORDER BY total_amount DESC
    LIMIT 20;

ROLLBACK;
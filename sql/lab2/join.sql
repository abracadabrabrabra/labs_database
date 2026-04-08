SELECT
    c.name as category,
    MAX(t.amount) as max_purchase,
    MIN(t.amount) as min_purchase,
    COUNT(*) as purchases_count
FROM transactions t
    JOIN categories c ON c.id = t.category_id
WHERE t.type = 'expense'
GROUP BY c.name
ORDER BY max_purchase DESC;

SELECT
    u.full_name,
    a.name as account_name,
    a.currency,
    a.initial_balance + COALESCE(SUM(
        CASE
        WHEN t.type = 'income' THEN t.amount
        WHEN t.type = 'expense' THEN -t.amount
        ELSE 0
        END
    ), 0) as current_balance
FROM accounts a
    LEFT JOIN users u ON u.id = a.user_id
    LEFT JOIN transactions t ON t.account_id = a.id
GROUP BY u.full_name, a.id, a.name, a.currency, a.initial_balance;

SELECT
    u.full_name,
    a.name as account_name,
    c.name as category_name,
    COUNT(t.id) as transaction_count
FROM users u
    LEFT JOIN accounts a ON a.user_id = u.id
    FULL OUTER JOIN transactions t ON t.account_id = a.id
    FULL OUTER JOIN categories c ON c.id = t.category_id
GROUP BY u.full_name, a.name, c.name;

SELECT
    u.email,
    currencies.currency,
    (
        SELECT COUNT(*)
        FROM accounts a
        WHERE a.user_id = u.id AND a.currency = currencies.currency
    ) as account_count
FROM users u
CROSS JOIN (VALUES ('RUB'), ('USD'), ('EUR')) AS currencies(currency)
ORDER BY u.email, currencies.currency;

SELECT a.name, COUNT(t.id)
FROM accounts a
    RIGHT JOIN transactions t ON t.account_id = a.id
GROUP BY a.name;
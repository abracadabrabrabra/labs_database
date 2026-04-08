SELECT
    transaction_date,
    COUNT(*) as transactions_per_day
FROM transactions
GROUP BY transaction_date
ORDER BY transaction_date DESC;

SELECT
    c.name as category,
    SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) as total_expense,
    SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END) as net
FROM transactions t
    JOIN categories c ON c.id = t.category_id
WHERE c.user_id = (SELECT id FROM users WHERE email = 'alex@example.com')
GROUP BY c.name
ORDER BY net DESC;

SELECT
    u.email,
    MIN(t.transaction_date) as first_transaction,
    MAX(t.transaction_date) as last_transaction,
    MIN(t.amount) as smallest_amount,
    MAX(t.amount) as largest_amount
FROM transactions t
    JOIN accounts a ON a.id = t.account_id
    JOIN users u ON u.id = a.user_id
GROUP BY u.email;

SELECT
    AVG(rows_processed) as avg_rows_processed,
    AVG(rows_succeeded) as avg_rows_succeeded,
    AVG(rows_succeeded::float / NULLIF(rows_processed, 0) * 100) as avg_success_rate
FROM import_logs
WHERE rows_succeeded > 0;
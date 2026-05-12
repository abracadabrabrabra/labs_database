\set ON_ERROR_STOP off

INSERT INTO users (email, password_hash, full_name)
VALUES ('john@example.com', 'hash', 'John Doe');

INSERT INTO accounts (user_id, name, currency, initial_balance, type)
SELECT id, 'Main Account', 'USD', 1000, 'checking'
FROM users
WHERE email = 'john@example.com';

INSERT INTO accounts (user_id, name, currency, initial_balance, type)
SELECT id, 'Vacation Savings', 'USD', 0, 'savings'
FROM users
WHERE email = 'john@example.com';

INSERT INTO categories (user_id, name)
SELECT id, 'Salary'
FROM users
WHERE email = 'john@example.com';

INSERT INTO categories (user_id, name)
SELECT id, 'Transfer'
FROM users
WHERE email = 'john@example.com';

INSERT INTO goals (account_id, name, target_amount)
SELECT a.id, 'Vacation', 5000
FROM accounts a
         JOIN users u ON a.user_id = u.id
WHERE u.email = 'john@example.com'
  AND a.name = 'Vacation Savings';


SELECT * FROM accounts;


--success

BEGIN;

INSERT INTO import_logs (user_id, file_name, rows_processed, rows_succeeded)
SELECT id, 'salary.csv', 1, 1
FROM users
WHERE email = 'john@example.com';

INSERT INTO transactions (account_id, category_id, import_log_id, amount, type, description, transaction_date)
SELECT a.id, c.id, il.id, 3000,
       'income', 'Monthly salary', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON c.user_id = u.id
         JOIN import_logs il ON il.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Main Account' AND c.name = 'Salary'
ORDER BY il.created_at DESC
    LIMIT 1;

INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
SELECT a.id, c.id, 500, 'expense',
       'Transfer to vacation savings', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Main Account' AND c.name = 'Transfer';

INSERT INTO transactions (account_id, category_id, goal_id, amount, type, description, transaction_date)
SELECT
    a.id, c.id, g.id, 500, 'income',
    'Vacation savings top-up', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN goals g ON g.account_id = a.id
         JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Vacation Savings' AND g.name = 'Vacation' AND c.name = 'Transfer';

COMMIT;

SELECT
    a.name,
    COALESCE(SUM(CASE t.type
                     WHEN 'income' THEN t.amount
                     WHEN 'expense' THEN -t.amount
                     ELSE 0
        END), 0) AS balance
FROM accounts a
         JOIN transactions t ON a.id = t.account_id
WHERE a.user_id = (SELECT id FROM users WHERE email = 'john@example.com')
GROUP BY a.name;



--full rollback

BEGIN;


INSERT INTO import_logs (user_id, file_name, rows_processed, rows_succeeded)
SELECT id, 'salary2.csv', 3, 2
FROM users
WHERE email = 'john@example.com';

--check violation (negative amount)
INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
SELECT a.id, c.id, -3000, 'income', 'second salary', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Main Account' AND c.name = 'Salary';

ROLLBACK;

SELECT
    a.name,
    COALESCE(SUM(CASE t.type
                     WHEN 'income' THEN t.amount
                     WHEN 'expense' THEN -t.amount
                     ELSE 0
        END), 0) AS balance
FROM accounts a
         JOIN transactions t ON a.id = t.account_id
WHERE a.user_id = (SELECT id FROM users WHERE email = 'john@example.com')
GROUP BY a.name;

--partial rollback

BEGIN;

INSERT INTO import_logs (user_id, file_name, rows_processed, rows_succeeded)
SELECT id, 'salary3.csv', 1, 1
FROM users
WHERE email = 'john@example.com';

INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
SELECT a.id, c.id, 5000, 'income',
    'Third salary', CURRENT_DATE
FROM accounts a
    JOIN users u ON a.user_id = u.id
    JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Main Account' AND c.name = 'Salary';

SAVEPOINT transfer_start;

INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
SELECT a.id, c.id, 1000,'expense',
    'Transfer to vacation savings', CURRENT_DATE
FROM accounts a
    JOIN users u ON a.user_id = u.id
    JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Main Account' AND c.name = 'Transfer';

--check violation (invalid_type)
INSERT INTO transactions (account_id, category_id, goal_id, amount, type, description, transaction_date)
SELECT a.id, c.id, g.id, 1000,
    'invalid', 'Broken savings transfer', CURRENT_DATE
FROM accounts a
    JOIN users u ON a.user_id = u.id
    JOIN goals g ON g.account_id = a.id
    JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com'
  AND a.name = 'Vacation Savings'
  AND g.name = 'Vacation'
  AND c.name = 'Transfer';

ROLLBACK TO SAVEPOINT transfer_start;
COMMIT;
SELECT
    a.name,
    COALESCE(SUM(CASE t.type
                     WHEN 'income' THEN t.amount
                     WHEN 'expense' THEN -t.amount
                     ELSE 0
        END), 0) AS balance
FROM accounts a
         JOIN transactions t ON a.id = t.account_id
WHERE a.user_id = (SELECT id FROM users WHERE email = 'john@example.com')
GROUP BY a.name;
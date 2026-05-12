\set ON_ERROR_STOP off

SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
    LEFT JOIN goals g
        ON g.account_id = a.id
    LEFT JOIN transactions t
        ON t.account_id = a.id
WHERE a.name = 'Vacation Savings';



--full rollback

BEGIN;

DELETE FROM accounts
WHERE id = (
    SELECT a.id
    FROM accounts a
        JOIN users u
        ON a.user_id = u.id
    WHERE u.email = 'john@example.com' AND a.name = 'Vacation Savings'
);

SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
         LEFT JOIN goals g
                   ON g.account_id = a.id
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.user_id = (
    SELECT id
    FROM users
    WHERE email = 'john@example.com'
);
SELECT * FROM goals;

ROLLBACK;



--success

BEGIN;

INSERT INTO import_logs (user_id, file_name, rows_processed, rows_succeeded)
SELECT id, 'close_vacation_account.csv', 2, 2
FROM users
WHERE email = 'john@example.com';

INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
SELECT main_acc.id, c.id, 500, 'income',
       'Returned vacation savings', CURRENT_DATE
FROM accounts main_acc
    JOIN users u ON main_acc.user_id = u.id
    JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND main_acc.name = 'Main Account' AND c.name = 'Transfer';

SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
         LEFT JOIN goals g
                   ON g.account_id = a.id
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.name = 'Main Account';

UPDATE goals
SET status = 'failed'
WHERE id = (
    SELECT g.id FROM goals g
        JOIN accounts a ON g.account_id = a.id
    WHERE a.name = 'Vacation Savings'
);
SELECT * FROM goals;

DELETE FROM accounts
WHERE id = (
    SELECT a.id FROM accounts a
        JOIN users u ON a.user_id = u.id
    WHERE u.email = 'john@example.com'
      AND a.name = 'Vacation Savings'
);

COMMIT;

SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
         LEFT JOIN goals g
                   ON g.account_id = a.id
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.user_id = (
    SELECT id
    FROM users
    WHERE email = 'john@example.com'
);
SELECT * FROM goals;



--partial rollback

INSERT INTO accounts (user_id, name, currency, initial_balance, type)
SELECT id, 'Vacation Savings', 'USD', 0, 'savings'
FROM users
WHERE email = 'john@example.com';

INSERT INTO goals (account_id, name, target_amount)
SELECT a.id, 'Vacation', 5000
FROM accounts a
         JOIN users u ON a.user_id = u.id
WHERE u.email = 'john@example.com'
  AND a.name = 'Vacation Savings';

INSERT INTO transactions (account_id, category_id, goal_id, amount, type, description, transaction_date)
SELECT
    a.id, c.id, g.id, 500, 'income',
    'Vacation savings top-up', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN goals g ON g.account_id = a.id
         JOIN categories c ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND a.name = 'Vacation Savings' AND g.name = 'Vacation' AND c.name = 'Transfer';


SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
         LEFT JOIN goals g
                   ON g.account_id = a.id
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.name = 'Vacation Savings';

BEGIN;

INSERT INTO import_logs (user_id, file_name, rows_processed, rows_succeeded)
SELECT id, 'close_attempt.csv', 1, 1
FROM users
WHERE email = 'john@example.com';

SAVEPOINT close_account;

INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
SELECT main_acc.id, c.id, 500, 'income',
       'Returned vacation savings 2', CURRENT_DATE
FROM accounts main_acc
    JOIN users u
        ON main_acc.user_id = u.id
    JOIN categories c
        ON c.user_id = u.id
WHERE u.email = 'john@example.com' AND main_acc.name = 'Main Account' AND c.name = 'Transfer';

--check violation(invalid status)
UPDATE goals
SET status = 'closed'
WHERE id = (
    SELECT g.id FROM goals g
        JOIN accounts a ON g.account_id = a.id
    WHERE a.name = 'Vacation Savings'
);

ROLLBACK TO SAVEPOINT close_account;
COMMIT;

SELECT * FROM import_logs;
SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
         LEFT JOIN goals g
                   ON g.account_id = a.id
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.name = 'Main Account';
SELECT a.name AS account, g.name AS goal, t.description, t.amount, t.type
FROM accounts a
         LEFT JOIN goals g
                   ON g.account_id = a.id
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.name = 'Vacation Savings';


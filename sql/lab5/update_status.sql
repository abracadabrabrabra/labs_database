\set ON_ERROR_STOP off

INSERT INTO users (email, password_hash, full_name)
VALUES ('alice@example.com', 'hash', 'Alice Johnson');

INSERT INTO accounts (user_id, name, currency, initial_balance, type)
SELECT id, 'Emergency Fund',
    'USD', 0, 'savings'
FROM users
WHERE email = 'alice@example.com';

INSERT INTO categories (user_id, name)
SELECT id, 'Goal Deposit'
FROM users
WHERE email = 'alice@example.com';

INSERT INTO goals (account_id, name, target_amount)
SELECT a.id, 'Emergency Cushion', 3000
FROM accounts a
    JOIN users u ON a.user_id = u.id
WHERE u.email = 'alice@example.com'
  AND a.name = 'Emergency Fund';



--success

BEGIN;

INSERT INTO transactions (account_id, category_id, goal_id,
    amount, type, description, transaction_date)
SELECT a.id, c.id, g.id, 3000,
    'income', 'Emergency fund top-up', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON c.user_id = u.id
         JOIN goals g ON g.account_id = a.id
WHERE u.email = 'alice@example.com'
  AND a.name = 'Emergency Fund' AND c.name = 'Goal Deposit' AND g.name = 'Emergency Cushion';

SELECT
    a.name,
    COALESCE(SUM(CASE t.type
                     WHEN 'income' THEN t.amount
                     WHEN 'expense' THEN -t.amount
                     ELSE 0
        END), 0) AS balance
FROM accounts a
         JOIN transactions t ON a.id = t.account_id
WHERE a.user_id = (SELECT id FROM users WHERE email = 'alice@example.com')
GROUP BY a.name;

UPDATE goals
SET status = 'achieved'
WHERE id = (
    SELECT g.id
    FROM goals g
             JOIN accounts a
                  ON g.account_id = a.id
             JOIN users u
                  ON a.user_id = u.id
    WHERE u.email = 'alice@example.com'
      AND g.name = 'Emergency Cushion'
);

COMMIT;

SELECT g.name, g.target_amount, g.status
FROM goals g
    JOIN accounts a
        ON g.account_id = a.id
    JOIN users u
        ON a.user_id = u.id
WHERE u.email = 'alice@example.com';



--full rollback

BEGIN;

--check violation (negative amount)
INSERT INTO transactions (account_id, category_id, goal_id, amount, type, description, transaction_date)
SELECT a.id, c.id, g.id, -1000,
    'income', 'Broken deposit', CURRENT_DATE
FROM accounts a
    JOIN users u
        ON a.user_id = u.id
    JOIN categories c
        ON c.user_id = u.id
    JOIN goals g
        ON g.account_id = a.id
WHERE u.email = 'alice@example.com' AND a.name = 'Emergency Fund'
  AND c.name = 'Goal Deposit' AND g.name = 'Emergency Cushion';

ROLLBACK;



SELECT
    a.name,
    COALESCE(SUM(CASE t.type
        WHEN 'income' THEN t.amount
            WHEN 'expense' THEN -t.amount
            ELSE 0
        END), 0) AS balance
FROM accounts a
    LEFT JOIN transactions t ON t.account_id = a.id
WHERE a.user_id = (SELECT id FROM users WHERE email = 'alice@example.com')
GROUP BY a.name;



--partial rollback

UPDATE goals
SET
    status = 'active',
    target_amount = 5000
WHERE name = 'Emergency Cushion';


BEGIN;
INSERT INTO transactions (account_id, category_id, goal_id, amount,
    type, description, transaction_date)
SELECT a.id, c.id, g.id, 500, 'income',
    'Additional emergency savings', CURRENT_DATE
FROM accounts a
    JOIN users u ON a.user_id = u.id
    JOIN categories c ON c.user_id = u.id
    JOIN goals g ON g.account_id = a.id
WHERE u.email = 'alice@example.com' AND a.name = 'Emergency Fund' AND c.name = 'Goal Deposit'
  AND g.name = 'Emergency Cushion';

SAVEPOINT goal_status_update;

--check violation (invalid status)
UPDATE goals
SET status = 'completed'
WHERE id = (
    SELECT g.id
    FROM goals g
        JOIN accounts a ON g.account_id = a.id
        JOIN users u ON a.user_id = u.id
    WHERE u.email = 'alice@example.com'
      AND g.name = 'Emergency Cushion'
);

ROLLBACK TO SAVEPOINT goal_status_update;

--correct update
UPDATE goals
SET status = 'active'
WHERE id = (
    SELECT g.id
    FROM goals g
        JOIN accounts a ON g.account_id = a.id
        JOIN users u ON a.user_id = u.id
    WHERE u.email = 'alice@example.com'
      AND g.name = 'Emergency Cushion'
);

COMMIT;

SELECT
    a.name,
    COALESCE(SUM(
                     CASE t.type
                         WHEN 'income' THEN t.amount
                         WHEN 'expense' THEN -t.amount
                         ELSE 0
                         END
             ), 0) AS balance
FROM accounts a
         LEFT JOIN transactions t
                   ON t.account_id = a.id
WHERE a.user_id = (
    SELECT id
    FROM users
    WHERE email = 'alice@example.com'
)
GROUP BY a.name;

SELECT
    g.name,
    g.target_amount,
    g.status
FROM goals g
         JOIN accounts a
              ON g.account_id = a.id
         JOIN users u
              ON a.user_id = u.id
WHERE u.email = 'alice@example.com';
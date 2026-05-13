SELECT pg_sleep(2);

BEGIN;

INSERT INTO transactions (account_id, category_id, goal_id, amount,
                          type, description, transaction_date)
SELECT a.id, c.id, g.id, 1000, 'income',
       'Parallel deposit', CURRENT_DATE
FROM accounts a
         JOIN users u ON a.user_id = u.id
         JOIN categories c ON c.user_id = u.id
         JOIN goals g ON g.account_id = a.id
WHERE u.email = 'alice@example.com'
  AND a.name = 'Emergency Fund'
  AND c.name = 'Goal Deposit'
  AND g.name = 'Emergency Cushion';

COMMIT;
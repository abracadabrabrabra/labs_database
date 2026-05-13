BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT
    COALESCE(SUM(amount),0) AS balance
FROM transactions t
         JOIN goals g ON g.id = t.goal_id
WHERE g.name = 'Emergency Cushion';

SELECT pg_sleep(10);

SELECT
    COALESCE(SUM(amount),0) AS balance
FROM transactions t
         JOIN goals g ON g.id = t.goal_id
WHERE g.name = 'Emergency Cushion';

COMMIT;
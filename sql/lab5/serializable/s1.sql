BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT *
FROM goals
WHERE name = 'Emergency Cushion';

SELECT pg_sleep(10);

UPDATE goals
SET status = 'achieved'
WHERE name = 'Emergency Cushion';

COMMIT;
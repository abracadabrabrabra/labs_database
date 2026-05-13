SELECT pg_sleep(2);

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE goals
SET target_amount = 500
WHERE name = 'Emergency Cushion';

COMMIT;
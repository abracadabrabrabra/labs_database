EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount
FROM transactions
WHERE description LIKE '%Purchase'
    LIMIT 100;

BEGIN;
CREATE INDEX idx_description ON transactions(description);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount
FROM transactions
WHERE description LIKE '%Purchase'
    LIMIT 100;

ROLLBACK;
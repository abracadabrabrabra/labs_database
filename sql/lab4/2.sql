EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, amount, type, description, transaction_date
FROM transactions
WHERE type = 'expense'
ORDER BY amount DESC
    LIMIT 10;

BEGIN;
CREATE INDEX idx_type_amount_desc ON transactions(type, amount DESC);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, amount, type, description, transaction_date
FROM transactions
WHERE type = 'expense'
ORDER BY amount DESC
    LIMIT 10;

ROLLBACK;

BEGIN;
CREATE INDEX idx_type_amount ON transactions(type, amount);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, amount, type, description, transaction_date
FROM transactions
WHERE type = 'expense'
ORDER BY amount DESC
    LIMIT 10;

ROLLBACK;

BEGIN;
CREATE INDEX idx_amount ON transactions(amount);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, amount, type, description, transaction_date
FROM transactions
WHERE type = 'expense'
ORDER BY amount DESC
    LIMIT 10;

ROLLBACK;
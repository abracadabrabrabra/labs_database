ALTER TABLE transactions ADD COLUMN description_tsv tsvector
    GENERATED ALWAYS AS (to_tsvector('english', COALESCE(description, ''))) STORED;

CREATE EXTENSION IF NOT EXISTS pg_trgm;


EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type, transaction_date
FROM transactions
WHERE description ILIKE '%Purchase%'
  AND transaction_date >= '2025-01-01'
ORDER BY transaction_date DESC
    LIMIT 100;


BEGIN;
CREATE INDEX idx_date_btree ON transactions(transaction_date);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type, transaction_date
FROM transactions
WHERE description ILIKE '%Purchase%'
  AND transaction_date >= '2025-01-01'
ORDER BY transaction_date DESC
    LIMIT 100;

ROLLBACK;


BEGIN;
CREATE INDEX idx_gin_tsv ON transactions USING gin(description_tsv);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type, transaction_date
FROM transactions
WHERE description_tsv @@ to_tsquery('english', 'Purchase')
  AND transaction_date >= '2025-01-01'
ORDER BY transaction_date DESC
    LIMIT 100;

ROLLBACK;


BEGIN;
CREATE INDEX idx_trgm ON transactions USING gin(description gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type, transaction_date
FROM transactions
WHERE description ILIKE '%Purchase%'
  AND transaction_date >= '2025-01-01'
ORDER BY transaction_date DESC
    LIMIT 100;

ROLLBACK;


BEGIN;
CREATE INDEX idx_date_btree ON transactions(transaction_date);
CREATE INDEX idx_trgm ON transactions USING gin(description gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type, transaction_date
FROM transactions
WHERE description ILIKE '%Purchase%'
  AND transaction_date >= '2025-01-01'
ORDER BY transaction_date DESC
    LIMIT 100;

ROLLBACK;
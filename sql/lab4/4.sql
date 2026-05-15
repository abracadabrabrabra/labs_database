CREATE EXTENSION IF NOT EXISTS pg_trgm;

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type
FROM transactions
WHERE description ILIKE '%Purchase%'
LIMIT 100;

BEGIN;
CREATE INDEX idx_trgm_substring ON transactions USING gin(description gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type
FROM transactions
WHERE description ILIKE '%Purchase%'
LIMIT 100;

ROLLBACK;


EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type
FROM transactions
WHERE description LIKE 'Purchase%'
    LIMIT 100;

BEGIN;
CREATE INDEX idx_btree_prefix ON transactions(description text_pattern_ops);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type
FROM transactions
WHERE description LIKE 'Purchase%'
    LIMIT 100;

ROLLBACK;

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type
FROM transactions
WHERE description LIKE '%Purchase'
    LIMIT 100;

BEGIN;
CREATE INDEX idx_trgm_suffix ON transactions USING gin(description gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type
FROM transactions
WHERE description LIKE '%Purchase'
    LIMIT 100;

ROLLBACK;

CREATE INDEX idx_gin_tsvector ON transactions USING gin(description_tsv);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT id, description, amount, type,
       ts_rank(description_tsv, to_tsquery('english', 'Purchase')) as rank
FROM transactions
WHERE description_tsv @@ to_tsquery('english', 'Purchase')
ORDER BY rank DESC
    LIMIT 100;
EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT * FROM transactions
WHERE type = 'expense'
  AND amount BETWEEN 100 AND 2000
  AND transaction_date >= CURRENT_DATE - 30;

BEGIN;
CREATE INDEX idx_test ON transactions(type, amount, transaction_date);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT * FROM transactions
WHERE type = 'expense'
  AND amount BETWEEN 100 AND 2000
  AND transaction_date >= CURRENT_DATE - 30;

ROLLBACK;


BEGIN;
CREATE INDEX idx_test ON transactions(amount, type, transaction_date);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT * FROM transactions
WHERE type = 'expense'
  AND amount BETWEEN 100 AND 2000
  AND transaction_date >= CURRENT_DATE - 30;

ROLLBACK;


BEGIN;
CREATE INDEX idx_test ON transactions(transaction_date, type, amount);

EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)
SELECT * FROM transactions
WHERE type = 'expense'
  AND amount BETWEEN 100 AND 2000
  AND transaction_date >= CURRENT_DATE - 30;

ROLLBACK;
DROP TABLE IF EXISTS test_transactions;
CREATE TABLE test_transactions (LIKE transactions INCLUDING ALL);

INSERT INTO test_transactions (account_id, category_id, amount, type, description, transaction_date, created_at)
SELECT account_id, category_id, amount, type, description, transaction_date, created_at
FROM transactions
         LIMIT 1000000;

SELECT COUNT(*) AS test_transactions_count FROM test_transactions;


DROP INDEX IF EXISTS idx_test_type_date;
DROP INDEX IF EXISTS idx_test_amount;
DROP INDEX IF EXISTS idx_test_account_id;
DROP INDEX IF EXISTS idx_test_category_id;

BEGIN;

EXPLAIN (ANALYZE, TIMING, BUFFERS)
INSERT INTO test_transactions (account_id, category_id, amount, type, description, transaction_date, created_at)
SELECT account_id, category_id, amount, type, description, transaction_date, created_at
FROM transactions
         OFFSET 1000000
LIMIT 10000;
SELECT COUNT(*) AS count_in_transaction FROM test_transactions;
ROLLBACK;

SELECT COUNT(*) AS count_after_rollback FROM test_transactions;

BEGIN;
EXPLAIN (ANALYZE, TIMING, BUFFERS)
UPDATE test_transactions
SET amount = amount * 1.1
WHERE type = 'expense' AND amount > 100;
SELECT COUNT(*) AS updated_rows FROM test_transactions
WHERE type = 'expense' AND amount > 100 AND amount::text LIKE '%1.1%';
ROLLBACK;


CREATE INDEX idx_test_type_date ON test_transactions(type, transaction_date);
CREATE INDEX idx_test_amount ON test_transactions(amount);
CREATE INDEX idx_test_account_id ON test_transactions(account_id);
CREATE INDEX idx_test_category_id ON test_transactions(category_id);

BEGIN;
EXPLAIN (ANALYZE, TIMING, BUFFERS)
INSERT INTO test_transactions (account_id, category_id, amount, type, description, transaction_date, created_at)
SELECT account_id, category_id, amount, type, description, transaction_date, created_at
FROM transactions
         OFFSET 1000000
LIMIT 10000;
ROLLBACK;


BEGIN;

EXPLAIN (ANALYZE, TIMING, BUFFERS)
UPDATE test_transactions
SET amount = amount * 1.1
WHERE type = 'expense' AND amount > 100;

ROLLBACK;

DROP INDEX idx_test_type_date;
DROP INDEX idx_test_amount;
DROP INDEX idx_test_account_id;
DROP INDEX idx_test_category_id;
DROP TABLE test_transactions;

INSERT INTO users (id, email, password_hash, full_name)
SELECT
    gen_random_uuid(),
    'user' || i || '@example.com',
    'hash_' || i,
    'User ' || i
FROM generate_series(1, 50) i;


DO $$
DECLARE
    user_record RECORD;
    account_types TEXT[] := ARRAY['checking', 'savings', 'credit_card'];
BEGIN
FOR user_record IN SELECT id FROM users LOOP
    FOR i IN 1..3 LOOP
        INSERT INTO accounts (user_id, name, currency, initial_balance, type)
            VALUES (
            user_record.id,
            'Account ' || i,
            CASE WHEN i = 1 THEN 'USD' ELSE 'EUR' END,
            (10000)::DECIMAL(15,2),
            account_types[floor(random() * array_length(account_types, 1))::INT + 1]
        );
    END LOOP;
END LOOP;
END $$;


INSERT INTO categories (user_id, name, description)
SELECT id, category_name, 'Category description'
FROM users
CROSS JOIN (VALUES
            ('Food'),
            ('Transport'),
            ('Shopping'),
            ('Entertainment'),
            ('Bills'),
            ('Salary'),
            ('Gifts')
) AS categories(category_name);

DO $$
DECLARE
    v_account_ids UUID[];
    v_category_ids UUID[];
    v_descriptions TEXT[] := ARRAY['Purchase', 'Salary', 'Transfer', 'Payment', 'Refund'];
    v_start_date DATE := '2000-01-01';
    v_end_date DATE := '2050-12-31';
    v_date_range INT := v_end_date - v_start_date;
    v_amount DECIMAL;
    v_type TEXT;
BEGIN
SELECT ARRAY(SELECT id FROM accounts) INTO v_account_ids;
SELECT ARRAY(SELECT id FROM categories) INTO v_category_ids;

FOR i IN 1..1001001 LOOP
        CASE (i % 4)
            WHEN 0 THEN
                v_type := 'income';
                v_amount := 5000.00;
            WHEN 1 THEN
                v_type := 'expense';
                v_amount := 50.00;
            WHEN 2 THEN
                v_type := 'income';
                v_amount := 1500.00;
            WHEN 3 THEN
                v_type := 'expense';
                v_amount := 300.00;
        END CASE;

        INSERT INTO transactions (
        account_id, category_id, amount, type,
        description, transaction_date, created_at
        ) VALUES (
             v_account_ids[floor(random() * array_length(v_account_ids, 1))::INT + 1],
             v_category_ids[floor(random() * array_length(v_category_ids, 1))::INT + 1],
             v_amount,
             v_type,
             v_descriptions[floor(random() * array_length(v_descriptions, 1))::INT + 1] || ' ' || i,
             v_start_date + (random() * v_date_range)::INT,
             NOW() - (random() * interval '365 days')
        );

        IF i % 100000 = 0 THEN
            RAISE NOTICE 'Inserted % transactions', i;
        END IF;
END LOOP;
END $$;

ANALYZE transactions;
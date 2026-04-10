CREATE OR REPLACE FUNCTION recalc_goal(p_goal_id UUID)
RETURNS VOID AS $$
DECLARE
    v_saved_amount DECIMAL;
    v_target_amount DECIMAL;
    v_deadline DATE;
    v_new_status VARCHAR(20);
BEGIN
    IF p_goal_id IS NULL THEN
        RETURN;
    END IF;

    SELECT target_amount, deadline
    INTO v_target_amount, v_deadline
    FROM goals
    WHERE id = p_goal_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT COALESCE(SUM(
        CASE
            WHEN type = 'income' THEN amount
            WHEN type = 'expense' THEN -amount
            ELSE 0
            END
    ), 0)
    INTO v_saved_amount
    FROM transactions
    WHERE goal_id = p_goal_id;

    IF v_saved_amount >= v_target_amount THEN
        v_new_status := 'achieved';
    ELSIF v_deadline IS NOT NULL AND CURRENT_DATE > v_deadline THEN
        v_new_status := 'failed';
    ELSE
        v_new_status := 'active';
    END IF;

    UPDATE goals
    SET status = v_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_goal_id
        AND status IS DISTINCT FROM v_new_status;

    EXCEPTION
        WHEN deadlock_detected THEN
            RAISE NOTICE 'Deadlock detected for goal %', p_goal_id;
            RAISE;

        WHEN serialization_failure THEN
            RAISE NOTICE 'Serialization failure for goal %', p_goal_id;
            RAISE;

        WHEN OTHERS THEN
            RAISE WARNING 'Unexpected error in recalc_goal(%): %', p_goal_id, SQLERRM;
            RAISE;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_goal_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM recalc_goal(NEW.goal_id);
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.goal_id IS DISTINCT FROM NEW.goal_id THEN
            PERFORM recalc_goal(OLD.goal_id);
            PERFORM recalc_goal(NEW.goal_id);
        ELSE
            PERFORM recalc_goal(NEW.goal_id);
        END IF;
        RETURN NEW;
    END IF;

    IF TG_OP = 'DELETE' THEN
        PERFORM recalc_goal(OLD.goal_id);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_goal_status_on_transaction
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_goal_status();



INSERT INTO goals (account_id, name, target_amount, deadline, status) VALUES
    ((SELECT id FROM accounts WHERE name = 'VTB card' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com')),
    'Buy food',
    500.00,
    CURRENT_DATE,
    'active'
    );

SELECT status FROM goals WHERE name = 'Buy food' AND account_id = (SELECT id FROM accounts WHERE name = 'VTB card' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com'));

INSERT INTO transactions (account_id, category_id, goal_id, amount, type, description, transaction_date)
VALUES (
    (SELECT id FROM accounts WHERE name = 'VTB card' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com')),
    (SELECT id FROM categories WHERE name = 'Freelance' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com')),
    (SELECT id FROM goals WHERE name = 'Buy food' AND account_id = (SELECT id FROM accounts WHERE name = 'VTB card' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com'))),
    1000.00, 'income', 'Freelance', CURRENT_DATE);

SELECT status FROM goals WHERE name = 'Buy food' AND account_id = (SELECT id FROM accounts WHERE name = 'VTB card' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com'));



CREATE OR REPLACE FUNCTION validate_transaction_ownership()
RETURNS TRIGGER AS $$
DECLARE
    v_account_user UUID;
    v_category_user UUID;
BEGIN
    IF NEW.category_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT a.user_id, c.user_id
    INTO v_account_user, v_category_user
    FROM accounts a JOIN categories c ON c.id = NEW.category_id
    WHERE a.id = NEW.account_id;

    IF v_account_user IS DISTINCT FROM v_category_user THEN
        RAISE EXCEPTION 'Account and category belong to different users' USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'validate_transaction_ownership error: %', SQLERRM;
            RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_transaction_ownership
    BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION validate_transaction_ownership();

INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
VALUES (
           (SELECT id FROM accounts WHERE name = 'Cash' AND user_id = (SELECT id FROM users WHERE email = 'maria@example.com')),
           (SELECT id FROM categories WHERE name = 'Salary' AND user_id = (SELECT id FROM users WHERE email = 'maria@example.com')),
           120000.00, 'income', 'Third job', CURRENT_DATE
       );

/*INSERT INTO transactions (account_id, category_id, amount, type, description, transaction_date)
VALUES (
           (SELECT id FROM accounts WHERE name = 'Cash' AND user_id = (SELECT id FROM users WHERE email = 'maria@example.com')),
           (SELECT id FROM categories WHERE name = 'Transport' AND user_id = (SELECT id FROM users WHERE email = 'alex@example.com')),
           120000.00, 'income', 'Third job', CURRENT_DATE
       );*/
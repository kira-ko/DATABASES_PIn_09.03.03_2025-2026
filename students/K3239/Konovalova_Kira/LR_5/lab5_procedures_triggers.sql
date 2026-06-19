-- Лабораторная работа №5
-- Процедуры, функции, триггеры в PostgreSQL
-- База данных: library_db
-- Схема: library

SET search_path TO library;


-- 1. ПРОЦЕДУРЫ

-- Процедура 1. Добавление нового читателя


DROP PROCEDURE IF EXISTS add_reader(
    varchar,
    varchar,
    varchar,
    varchar,
    varchar,
    varchar,
    varchar
);

CREATE OR REPLACE PROCEDURE add_reader(
    p_library_card_number varchar,
    p_full_name varchar,
    p_passport_data varchar,
    p_address varchar,
    p_phone varchar,
    p_email varchar,
    p_education_level varchar
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM reader
        WHERE library_card_number = p_library_card_number
    ) THEN
        RAISE EXCEPTION 'Reader with library card number % already exists.',
            p_library_card_number;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reader
        WHERE passport_data = p_passport_data
    ) THEN
        RAISE EXCEPTION 'Reader with passport data % already exists.',
            p_passport_data;
    END IF;

    INSERT INTO reader (
        library_card_number,
        full_name,
        passport_data,
        address,
        phone,
        email,
        education_level
    )
    VALUES (
        p_library_card_number,
        p_full_name,
        p_passport_data,
        p_address,
        p_phone,
        p_email,
        p_education_level
    );
END;
$$;


-- Процедура 2. Оформление выдачи экземпляра книги

DROP PROCEDURE IF EXISTS issue_book_copy(
    varchar,
    varchar,
    date,
    date
);

CREATE OR REPLACE PROCEDURE issue_book_copy(
    p_library_card_number varchar,
    p_inventory_number varchar,
    p_issue_date date,
    p_planned_return_date date
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_copy_status varchar;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM reader
        WHERE library_card_number = p_library_card_number
    ) THEN
        RAISE EXCEPTION 'Reader with library card number % does not exist.',
            p_library_card_number;
    END IF;

    SELECT copy_status
    INTO v_copy_status
    FROM book_copy
    WHERE inventory_number = p_inventory_number;

    IF v_copy_status IS NULL THEN
        RAISE EXCEPTION 'Book copy with inventory number % does not exist.',
            p_inventory_number;
    END IF;

    IF v_copy_status <> 'available' THEN
        RAISE EXCEPTION 'Book copy % is not available. Current status: %.',
            p_inventory_number,
            v_copy_status;
    END IF;

    INSERT INTO loan (
        library_card_number,
        inventory_number,
        issue_date,
        planned_return_date,
        actual_return_date,
        fine_amount
    )
    VALUES (
        p_library_card_number,
        p_inventory_number,
        p_issue_date,
        p_planned_return_date,
        NULL,
        0
    );

    UPDATE book_copy
    SET copy_status = 'issued'
    WHERE inventory_number = p_inventory_number;
END;
$$;


-- Процедура 3. Оформление возврата экземпляра книги

DROP PROCEDURE IF EXISTS return_book_copy(
    integer,
    date
);

CREATE OR REPLACE PROCEDURE return_book_copy(
    p_loan_id integer,
    p_actual_return_date date
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inventory_number varchar;
    v_issue_date date;
    v_planned_return_date date;
    v_actual_return_date date;
    v_days_overdue integer;
    v_fine_amount numeric(10, 2);
BEGIN
    SELECT 
        inventory_number,
        issue_date,
        planned_return_date,
        actual_return_date
    INTO 
        v_inventory_number,
        v_issue_date,
        v_planned_return_date,
        v_actual_return_date
    FROM loan
    WHERE loan_id = p_loan_id;

    IF v_inventory_number IS NULL THEN
        RAISE EXCEPTION 'Loan with id % does not exist.', p_loan_id;
    END IF;

    IF v_actual_return_date IS NOT NULL THEN
        RAISE EXCEPTION 'Loan with id % has already been returned.', p_loan_id;
    END IF;

    IF p_actual_return_date < v_issue_date THEN
        RAISE EXCEPTION 'Actual return date cannot be earlier than issue date.';
    END IF;

    v_days_overdue := p_actual_return_date - v_planned_return_date;

    IF v_days_overdue > 0 THEN
        v_fine_amount := v_days_overdue * 50;
    ELSE
        v_fine_amount := 0;
    END IF;

    UPDATE loan
    SET 
        actual_return_date = p_actual_return_date,
        fine_amount = v_fine_amount
    WHERE loan_id = p_loan_id;

    UPDATE book_copy
    SET copy_status = 'available'
    WHERE inventory_number = v_inventory_number;
END;
$$;

-- Процедура 4. Проверка наличия экземпляров заданной книги

DROP PROCEDURE IF EXISTS get_publication_copy_count(
    varchar,
    INOUT integer
);

CREATE OR REPLACE PROCEDURE get_publication_copy_count(
    p_title varchar,
    INOUT p_copy_count integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*)
    INTO p_copy_count
    FROM publication p
    JOIN book_copy bc ON p.publication_id = bc.publication_id
    WHERE p.title = p_title
      AND bc.copy_status IN ('available', 'issued');
END;
$$;

-- Процедура 5. Ввод новой книги и первого экземпляра в базу данных

DROP PROCEDURE IF EXISTS add_new_book_with_copy(
    varchar,
    integer,
    integer,
    varchar,
    varchar,
    varchar,
    varchar,
    varchar,
    varchar,
    integer,
    integer,
    varchar,
    numeric,
    date
);

CREATE OR REPLACE PROCEDURE add_new_book_with_copy(
    p_title varchar,
    p_volume_number integer,
    p_release_year integer,
    p_author varchar,
    p_publication_type varchar,
    p_publisher varchar,
    p_knowledge_area varchar,
    p_publication_city varchar,
    p_library_code varchar,
    p_storage_place_id integer,
    p_receipt_document_id integer,
    p_inventory_number varchar,
    p_price numeric,
    p_registration_date date
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_publication_id integer;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM book_copy
        WHERE inventory_number = p_inventory_number
    ) THEN
        RAISE EXCEPTION 'Book copy with inventory number % already exists.',
            p_inventory_number;
    END IF;

    INSERT INTO publication (
        title,
        volume_number,
        release_year,
        author,
        publication_type,
        publisher,
        knowledge_area,
        publication_city,
        library_code
    )
    VALUES (
        p_title,
        p_volume_number,
        p_release_year,
        p_author,
        p_publication_type,
        p_publisher,
        p_knowledge_area,
        p_publication_city,
        p_library_code
    )
    RETURNING publication_id INTO v_publication_id;

    INSERT INTO book_copy (
        inventory_number,
        publication_id,
        storage_place_id,
        receipt_document_id,
        price,
        registration_date,
        withdrawal_date,
        copy_status
    )
    VALUES (
        p_inventory_number,
        v_publication_id,
        p_storage_place_id,
        p_receipt_document_id,
        p_price,
        p_registration_date,
        NULL,
        'available'
    );
END;
$$;

-- 2. ТРИГГЕРЫ

-- Триггер 1. Проверка доступности экземпляра перед выдачей

DROP TRIGGER IF EXISTS trg_check_book_copy_available ON loan;
DROP FUNCTION IF EXISTS fn_check_book_copy_available();

CREATE OR REPLACE FUNCTION fn_check_book_copy_available()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_copy_status varchar;
BEGIN
    SELECT copy_status
    INTO v_copy_status
    FROM book_copy
    WHERE inventory_number = NEW.inventory_number;

    IF v_copy_status IS NULL THEN
        RAISE EXCEPTION 'Book copy with inventory number % does not exist.',
            NEW.inventory_number;
    END IF;

    IF v_copy_status <> 'available' THEN
        RAISE EXCEPTION 'Book copy % is not available. Current status: %.',
            NEW.inventory_number,
            v_copy_status;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_book_copy_available
BEFORE INSERT ON loan
FOR EACH ROW
EXECUTE FUNCTION fn_check_book_copy_available();

-- Триггер 2. Автоматическое изменение статуса экземпляра на issued

DROP TRIGGER IF EXISTS trg_set_book_copy_issued ON loan;
DROP FUNCTION IF EXISTS fn_set_book_copy_issued();

CREATE OR REPLACE FUNCTION fn_set_book_copy_issued()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE book_copy
    SET copy_status = 'issued'
    WHERE inventory_number = NEW.inventory_number;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_book_copy_issued
AFTER INSERT ON loan
FOR EACH ROW
EXECUTE FUNCTION fn_set_book_copy_issued();

-- Триггер 3. Проверка корректности даты возврата

DROP TRIGGER IF EXISTS trg_check_actual_return_date ON loan;
DROP FUNCTION IF EXISTS fn_check_actual_return_date();

CREATE OR REPLACE FUNCTION fn_check_actual_return_date()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.actual_return_date IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.actual_return_date < NEW.issue_date THEN
        RAISE EXCEPTION 'Actual return date cannot be earlier than issue date.';
    END IF;

    IF OLD.actual_return_date IS NOT NULL
       AND NEW.actual_return_date <> OLD.actual_return_date THEN
        RAISE EXCEPTION 'Actual return date cannot be changed after the book has been returned.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_actual_return_date
BEFORE UPDATE OF actual_return_date ON loan
FOR EACH ROW
EXECUTE FUNCTION fn_check_actual_return_date();

-- Триггер 4. Автоматическое изменение статуса экземпляра на available после возврата

DROP TRIGGER IF EXISTS trg_set_book_copy_available ON loan;
DROP FUNCTION IF EXISTS fn_set_book_copy_available();

CREATE OR REPLACE FUNCTION fn_set_book_copy_available()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.actual_return_date IS NOT NULL
       AND OLD.actual_return_date IS NULL THEN

        UPDATE book_copy
        SET copy_status = 'available'
        WHERE inventory_number = NEW.inventory_number;

    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_book_copy_available
AFTER UPDATE OF actual_return_date ON loan
FOR EACH ROW
EXECUTE FUNCTION fn_set_book_copy_available();

-- Триггер 5. Запрет списания экземпляра, который находится на руках у читателя

DROP TRIGGER IF EXISTS trg_prevent_write_off_issued_copy ON book_copy;
DROP FUNCTION IF EXISTS fn_prevent_write_off_issued_copy();

CREATE OR REPLACE FUNCTION fn_prevent_write_off_issued_copy()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.copy_status = 'written off'
       AND EXISTS (
           SELECT 1
           FROM loan
           WHERE inventory_number = NEW.inventory_number
             AND actual_return_date IS NULL
       ) THEN
        RAISE EXCEPTION 'Book copy % cannot be written off because it is currently issued.',
            NEW.inventory_number;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prevent_write_off_issued_copy
BEFORE UPDATE OF copy_status ON book_copy
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_write_off_issued_copy();

-- Триггер 6. Автоматическое списание экземпляра после добавления в written_off_item

DROP TRIGGER IF EXISTS trg_set_book_copy_written_off ON written_off_item;
DROP FUNCTION IF EXISTS fn_set_book_copy_written_off();

CREATE OR REPLACE FUNCTION fn_set_book_copy_written_off()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_act_date date;
BEGIN
    SELECT act_date
    INTO v_act_date
    FROM write_off_act
    WHERE write_off_act_id = NEW.write_off_act_id;

    UPDATE book_copy
    SET 
        copy_status = 'written off',
        withdrawal_date = v_act_date
    WHERE inventory_number = NEW.inventory_number;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_book_copy_written_off
AFTER INSERT ON written_off_item
FOR EACH ROW
EXECUTE FUNCTION fn_set_book_copy_written_off();

-- Триггер 7. Логирование действий с таблицей loan

CREATE TABLE IF NOT EXISTS loan_log (
    log_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operation_type varchar(20) NOT NULL,
    loan_id integer,
    library_card_number varchar(20),
    inventory_number varchar(20),
    action_time timestamp NOT NULL DEFAULT now(),
    description text NOT NULL
);

DROP TRIGGER IF EXISTS trg_log_loan_changes ON loan;
DROP FUNCTION IF EXISTS fn_log_loan_changes();

CREATE OR REPLACE FUNCTION fn_log_loan_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO loan_log (
            operation_type,
            loan_id,
            library_card_number,
            inventory_number,
            description
        )
        VALUES (
            TG_OP,
            NEW.loan_id,
            NEW.library_card_number,
            NEW.inventory_number,
            'New loan was created'
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO loan_log (
            operation_type,
            loan_id,
            library_card_number,
            inventory_number,
            description
        )
        VALUES (
            TG_OP,
            NEW.loan_id,
            NEW.library_card_number,
            NEW.inventory_number,
            'Loan data was updated'
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO loan_log (
            operation_type,
            loan_id,
            library_card_number,
            inventory_number,
            description
        )
        VALUES (
            TG_OP,
            OLD.loan_id,
            OLD.library_card_number,
            OLD.inventory_number,
            'Loan was deleted'
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_log_loan_changes
AFTER INSERT OR UPDATE OR DELETE ON loan
FOR EACH ROW
EXECUTE FUNCTION fn_log_loan_changes();

-- 3. ФИНАЛЬНЫЕ ПРОВЕРКИ

-- Проверка созданных процедур

SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE specific_schema = 'library'
  AND routine_name IN (
      'add_reader',
      'issue_book_copy',
      'return_book_copy'
  )
ORDER BY routine_name;


-- Проверка созданных триггеров

SELECT 
    event_object_table AS table_name,
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing
FROM information_schema.triggers
WHERE trigger_schema = 'library'
ORDER BY event_object_table, trigger_name;


-- Проверка журнала действий

SELECT *
FROM loan_log
ORDER BY log_id;


-- Проверка состояния экземпляров и выдач

SELECT inventory_number, copy_status, withdrawal_date
FROM book_copy
ORDER BY inventory_number;

SELECT 
    loan_id,
    library_card_number,
    inventory_number,
    issue_date,
    planned_return_date,
    actual_return_date,
    fine_amount
FROM loan
ORDER BY loan_id;
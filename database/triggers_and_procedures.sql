USE cleanway_ims;

DROP TRIGGER IF EXISTS trg_products_after_insert;
DROP TRIGGER IF EXISTS trg_inventory_before_insert;
DROP TRIGGER IF EXISTS trg_inventory_before_update;
DROP TRIGGER IF EXISTS trg_stock_transactions_before_insert;
DROP TRIGGER IF EXISTS trg_stock_transactions_before_update;
DROP TRIGGER IF EXISTS trg_stock_transactions_before_delete;
DROP TRIGGER IF EXISTS trg_stock_transaction_items_before_insert;
DROP TRIGGER IF EXISTS trg_stock_transaction_items_before_update;
DROP TRIGGER IF EXISTS trg_stock_transaction_items_before_delete;

DROP PROCEDURE IF EXISTS sp_create_stock_transaction;
DROP PROCEDURE IF EXISTS sp_record_stock_in;
DROP PROCEDURE IF EXISTS sp_record_stock_out;
DROP PROCEDURE IF EXISTS sp_record_adjustment;
DROP PROCEDURE IF EXISTS sp_review_transaction;

DELIMITER $$

CREATE TRIGGER trg_products_after_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    INSERT INTO inventory (product_id, quantity_on_hand)
    VALUES (NEW.id, 0);
END$$

CREATE TRIGGER trg_inventory_before_insert
BEFORE INSERT ON inventory
FOR EACH ROW
BEGIN
    IF NEW.quantity_on_hand < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Inventory quantity cannot be negative.';
    END IF;
    IF NEW.quantity_on_hand <> 0 AND COALESCE(@allow_inventory_update, 0) <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New inventory rows must start at 0. Use stock transactions to add stock.';
    END IF;
END$$

CREATE TRIGGER trg_inventory_before_update
BEFORE UPDATE ON inventory
FOR EACH ROW
BEGIN
    DECLARE v_msg VARCHAR(255);

    IF NEW.product_id <> OLD.product_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'inventory.product_id cannot be changed.';
    END IF;

    IF NEW.quantity_on_hand <> OLD.quantity_on_hand THEN
        IF COALESCE(@allow_inventory_update, 0) <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Direct edits to inventory.quantity_on_hand are blocked. Use the stock transaction stored procedures.';
        END IF;
        IF NEW.quantity_on_hand < 0 THEN
            SET v_msg = CONCAT('Insufficient stock for product ID ', NEW.product_id, ': the operation would make inventory negative.');
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = v_msg;
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_stock_transactions_before_insert
BEFORE INSERT ON stock_transactions
FOR EACH ROW
BEGIN
    IF NEW.status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New stock transactions must start as pending.';
    END IF;
    IF NEW.reviewed_by IS NOT NULL OR NEW.reviewed_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New stock transactions cannot have a reviewer.';
    END IF;
    IF NEW.type = 'stock_in' AND NEW.supplier_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A supplier is required for stock-in transactions.';
    END IF;
    IF NEW.type = 'adjustment' AND NEW.adjustment_direction IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An adjustment direction (increase or decrease) is required for adjustments.';
    END IF;
    IF NEW.type <> 'adjustment' THEN
        SET NEW.adjustment_direction = NULL;
    END IF;
END$$

CREATE TRIGGER trg_stock_transactions_before_update
BEFORE UPDATE ON stock_transactions
FOR EACH ROW
BEGIN
    IF OLD.status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized stock transactions cannot be modified.';
    END IF;
    IF NEW.type <> OLD.type OR NOT (NEW.adjustment_direction <=> OLD.adjustment_direction) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction type and adjustment direction cannot be changed.';
    END IF;
    IF NEW.type = 'stock_in' AND NEW.supplier_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A supplier is required for stock-in transactions.';
    END IF;
    IF NEW.status = 'pending' AND (NEW.reviewed_by IS NOT NULL OR NEW.reviewed_at IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pending transactions cannot have a reviewer.';
    END IF;
    IF NEW.status <> OLD.status THEN
        IF COALESCE(@allow_inventory_update, 0) <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Transaction status can only be changed through sp_review_transaction.';
        END IF;
        IF NEW.reviewed_by IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A reviewer is required to approve or reject a transaction.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_stock_transactions_before_delete
BEFORE DELETE ON stock_transactions
FOR EACH ROW
BEGIN
    IF OLD.status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized stock transactions cannot be deleted.';
    END IF;
END$$

CREATE TRIGGER trg_stock_transaction_items_before_insert
BEFORE INSERT ON stock_transaction_items
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_type VARCHAR(20);
    DECLARE v_supplier_id INT;
    DECLARE v_is_active TINYINT(1);

    SELECT status, type, supplier_id
    INTO v_status, v_type, v_supplier_id
    FROM stock_transactions
    WHERE id = NEW.transaction_id;

    IF v_status IS NOT NULL AND v_status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items can only be added to pending transactions.';
    END IF;

    IF v_type = 'stock_in' THEN
        SELECT is_active INTO v_is_active FROM products WHERE id = NEW.product_id;
        IF v_is_active = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Inactive products cannot be received through stock-in.';
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM product_suppliers
            WHERE product_id = NEW.product_id AND supplier_id = v_supplier_id
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The selected supplier does not supply this product.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_stock_transaction_items_before_update
BEFORE UPDATE ON stock_transaction_items
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    IF NEW.transaction_id <> OLD.transaction_id OR NEW.product_id <> OLD.product_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction and product of an item cannot be changed. Delete and re-add the item instead.';
    END IF;

    SELECT status INTO v_status FROM stock_transactions WHERE id = OLD.transaction_id;
    IF v_status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items of finalized transactions cannot be modified.';
    END IF;
END$$

CREATE TRIGGER trg_stock_transaction_items_before_delete
BEFORE DELETE ON stock_transaction_items
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status FROM stock_transactions WHERE id = OLD.transaction_id;
    IF v_status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items of finalized transactions cannot be deleted.';
    END IF;
END$$

CREATE PROCEDURE sp_create_stock_transaction(
    IN p_type VARCHAR(20),
    IN p_created_by INT,
    IN p_supplier_id INT,
    IN p_reference_no VARCHAR(100),
    IN p_adjustment_direction VARCHAR(20),
    IN p_items TEXT,
    OUT p_transaction_id INT
)
BEGIN
    DECLARE v_rest TEXT;
    DECLARE v_item VARCHAR(100);
    DECLARE v_pos INT;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_unit_cost DECIMAL(10,2);
    DECLARE v_creator_status VARCHAR(20);
    DECLARE v_prefix VARCHAR(5);
    DECLARE v_code VARCHAR(50);
    DECLARE v_line_count INT DEFAULT 0;
    DECLARE v_short_count INT DEFAULT 0;
    DECLARE v_short_code VARCHAR(50);
    DECLARE v_msg VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @allow_inventory_update = 0;
        RESIGNAL;
    END;

    SET p_transaction_id = NULL;

    IF p_type NOT IN ('stock_in', 'stock_out', 'adjustment') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid transaction type.';
    END IF;

    IF p_type = 'stock_in' AND p_supplier_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A supplier is required for stock-in transactions.';
    END IF;

    IF p_type = 'adjustment' AND (p_adjustment_direction IS NULL OR p_adjustment_direction NOT IN ('increase', 'decrease')) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Adjustment direction must be increase or decrease.';
    END IF;

    SELECT status INTO v_creator_status FROM users WHERE id = p_created_by;
    IF v_creator_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Creating user does not exist.';
    END IF;
    IF v_creator_status <> 'active' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Creating user is inactive.';
    END IF;

    SET v_rest = TRIM(COALESCE(p_items, ''));
    IF v_rest = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'At least one item is required. Format: product_id:quantity:unit_cost|product_id:quantity:unit_cost';
    END IF;

    SET v_prefix = CASE p_type WHEN 'stock_in' THEN 'SIN' WHEN 'stock_out' THEN 'SOUT' ELSE 'ADJ' END;
    SET v_code = CONCAT(v_prefix, '-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', UPPER(LEFT(REPLACE(UUID(), '-', ''), 8)));

    START TRANSACTION;

    INSERT INTO stock_transactions (
        created_by, supplier_id, transaction_code, type, adjustment_direction, status, reference_no
    ) VALUES (
        p_created_by,
        p_supplier_id,
        v_code,
        p_type,
        IF(p_type = 'adjustment', p_adjustment_direction, NULL),
        'pending',
        NULLIF(TRIM(p_reference_no), '')
    );

    SET p_transaction_id = LAST_INSERT_ID();

    WHILE v_rest <> '' DO
        SET v_pos = LOCATE('|', v_rest);
        IF v_pos = 0 THEN
            SET v_item = TRIM(v_rest);
            SET v_rest = '';
        ELSE
            SET v_item = TRIM(LEFT(v_rest, v_pos - 1));
            SET v_rest = SUBSTRING(v_rest, v_pos + 1);
        END IF;

        IF NOT (v_item REGEXP '^[0-9]+:[0-9]+(:[0-9]+([.][0-9]+)?)?$') THEN
            SET v_msg = CONCAT('Invalid item "', v_item, '". Expected product_id:quantity[:unit_cost].');
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = v_msg;
        END IF;

        SET v_product_id = CAST(SUBSTRING_INDEX(v_item, ':', 1) AS UNSIGNED);
        SET v_quantity = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(v_item, ':', 2), ':', -1) AS UNSIGNED);

        IF v_quantity < 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Item quantity must be greater than 0.';
        END IF;

        IF (LENGTH(v_item) - LENGTH(REPLACE(v_item, ':', ''))) = 2 THEN
            SET v_unit_cost = CAST(SUBSTRING_INDEX(v_item, ':', -1) AS DECIMAL(10,2));
        ELSE
            SET v_unit_cost = NULL;
        END IF;

        IF v_unit_cost IS NULL THEN
            IF p_type = 'stock_in' THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'A unit cost is required for every stock-in item.';
            END IF;
            IF p_type = 'stock_out' THEN
                SELECT price INTO v_unit_cost FROM products WHERE id = v_product_id;
            END IF;
        END IF;

        INSERT INTO stock_transaction_items (transaction_id, product_id, quantity, unit_cost)
        VALUES (p_transaction_id, v_product_id, v_quantity, COALESCE(v_unit_cost, 0.00));

        SET v_line_count = v_line_count + 1;
    END WHILE;

    IF p_type = 'stock_out' OR (p_type = 'adjustment' AND p_adjustment_direction = 'decrease') THEN
        SELECT COUNT(*), MIN(p.product_code)
        INTO v_short_count, v_short_code
        FROM (
            SELECT product_id, SUM(quantity) AS qty
            FROM stock_transaction_items
            WHERE transaction_id = p_transaction_id
            GROUP BY product_id
        ) s
        JOIN inventory i ON i.product_id = s.product_id
        JOIN products p ON p.id = s.product_id
        WHERE i.quantity_on_hand < s.qty;

        IF v_short_count > 0 THEN
            SET v_msg = CONCAT('Insufficient stock for product ', v_short_code, ': requested quantity exceeds quantity on hand.');
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = v_msg;
        END IF;
    END IF;

    COMMIT;
END$$

CREATE PROCEDURE sp_record_stock_in(
    IN p_created_by INT,
    IN p_supplier_id INT,
    IN p_reference_no VARCHAR(100),
    IN p_items TEXT,
    OUT p_transaction_id INT
)
BEGIN
    CALL sp_create_stock_transaction('stock_in', p_created_by, p_supplier_id, p_reference_no, NULL, p_items, p_transaction_id);
END$$

CREATE PROCEDURE sp_record_stock_out(
    IN p_created_by INT,
    IN p_reference_no VARCHAR(100),
    IN p_items TEXT,
    OUT p_transaction_id INT
)
BEGIN
    CALL sp_create_stock_transaction('stock_out', p_created_by, NULL, p_reference_no, NULL, p_items, p_transaction_id);
END$$

CREATE PROCEDURE sp_record_adjustment(
    IN p_created_by INT,
    IN p_adjustment_direction VARCHAR(20),
    IN p_reference_no VARCHAR(100),
    IN p_items TEXT,
    OUT p_transaction_id INT
)
BEGIN
    CALL sp_create_stock_transaction('adjustment', p_created_by, NULL, p_reference_no, p_adjustment_direction, p_items, p_transaction_id);
END$$

CREATE PROCEDURE sp_review_transaction(
    IN p_transaction_id INT,
    IN p_reviewed_by INT,
    IN p_decision VARCHAR(20)
)
BEGIN
    DECLARE v_decision VARCHAR(20);
    DECLARE v_status VARCHAR(20);
    DECLARE v_type VARCHAR(20);
    DECLARE v_direction VARCHAR(20);
    DECLARE v_reviewer_status VARCHAR(20);
    DECLARE v_reviewer_role VARCHAR(50);
    DECLARE v_item_count INT DEFAULT 0;
    DECLARE v_short_count INT DEFAULT 0;
    DECLARE v_short_code VARCHAR(50);
    DECLARE v_msg VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @allow_inventory_update = 0;
        RESIGNAL;
    END;

    SET v_decision = LOWER(TRIM(COALESCE(p_decision, '')));
    IF v_decision NOT IN ('approved', 'rejected') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Decision must be approved or rejected.';
    END IF;

    SELECT u.status, r.name
    INTO v_reviewer_status, v_reviewer_role
    FROM users u
    JOIN roles r ON r.id = u.role_id
    WHERE u.id = p_reviewed_by;

    IF v_reviewer_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reviewing user does not exist.';
    END IF;
    IF v_reviewer_status <> 'active' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reviewing user is inactive.';
    END IF;
    IF v_reviewer_role NOT IN ('Administrator', 'Manager') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only Administrators and Managers can review transactions.';
    END IF;

    START TRANSACTION;

    SELECT status, type, adjustment_direction
    INTO v_status, v_type, v_direction
    FROM stock_transactions
    WHERE id = p_transaction_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction not found.';
    END IF;
    IF v_status <> 'pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only pending transactions can be reviewed.';
    END IF;

    IF v_decision = 'approved' THEN
        SELECT COUNT(*) INTO v_item_count
        FROM stock_transaction_items
        WHERE transaction_id = p_transaction_id;

        IF v_item_count = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A transaction without items cannot be approved.';
        END IF;

        IF v_type = 'stock_out' OR (v_type = 'adjustment' AND v_direction = 'decrease') THEN
            SELECT COUNT(*), MIN(p.product_code)
            INTO v_short_count, v_short_code
            FROM (
                SELECT product_id, SUM(quantity) AS qty
                FROM stock_transaction_items
                WHERE transaction_id = p_transaction_id
                GROUP BY product_id
            ) s
            JOIN inventory i ON i.product_id = s.product_id
            JOIN products p ON p.id = s.product_id
            WHERE i.quantity_on_hand < s.qty;

            IF v_short_count > 0 THEN
                SET v_msg = CONCAT('Insufficient stock for product ', v_short_code, ': cannot approve, quantity exceeds quantity on hand.');
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = v_msg;
            END IF;

            SET @allow_inventory_update = 1;

            UPDATE inventory i
            JOIN (
                SELECT product_id, SUM(quantity) AS qty
                FROM stock_transaction_items
                WHERE transaction_id = p_transaction_id
                GROUP BY product_id
            ) s ON s.product_id = i.product_id
            SET i.quantity_on_hand = i.quantity_on_hand - s.qty;
        ELSE
            SET @allow_inventory_update = 1;

            UPDATE inventory i
            JOIN (
                SELECT product_id, SUM(quantity) AS qty
                FROM stock_transaction_items
                WHERE transaction_id = p_transaction_id
                GROUP BY product_id
            ) s ON s.product_id = i.product_id
            SET i.quantity_on_hand = i.quantity_on_hand + s.qty;
        END IF;
    END IF;

    SET @allow_inventory_update = 1;

    UPDATE stock_transactions
    SET status = v_decision,
        reviewed_by = p_reviewed_by,
        reviewed_at = NOW()
    WHERE id = p_transaction_id;

    SET @allow_inventory_update = 0;

    COMMIT;
END$$

DELIMITER ;

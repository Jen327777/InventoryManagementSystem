USE cleanway_ims;

INSERT IGNORE INTO roles (name) VALUES
    ('Administrator'),
    ('Manager'),
    ('Inventory Staff');

INSERT IGNORE INTO users (role_id, full_name, username, password_hash, status)
SELECT r.id, u.full_name, u.username, u.password_hash, u.status
FROM (
    SELECT 'Administrator' AS role_name, 'Maria Santos' AS full_name, 'admin' AS username,
           '$2b$12$A2U8PAmL.8OzYKSBVacaPeHxwA6DvHCGwnJrXXMdTokqRCDRQW96u' AS password_hash, 'active' AS status
    UNION ALL SELECT 'Manager', 'Jose Reyes', 'jreyes',
           '$2b$12$A2U8PAmL.8OzYKSBVacaPeHxwA6DvHCGwnJrXXMdTokqRCDRQW96u', 'active'
    UNION ALL SELECT 'Inventory Staff', 'Ana Dela Cruz', 'adelacruz',
           '$2b$12$A2U8PAmL.8OzYKSBVacaPeHxwA6DvHCGwnJrXXMdTokqRCDRQW96u', 'active'
    UNION ALL SELECT 'Inventory Staff', 'Paolo Garcia', 'pgarcia',
           '$2b$12$A2U8PAmL.8OzYKSBVacaPeHxwA6DvHCGwnJrXXMdTokqRCDRQW96u', 'active'
    UNION ALL SELECT 'Inventory Staff', 'Rico Mendoza', 'rmendoza',
           '$2b$12$A2U8PAmL.8OzYKSBVacaPeHxwA6DvHCGwnJrXXMdTokqRCDRQW96u', 'inactive'
) u
JOIN roles r ON r.name = u.role_name;

INSERT IGNORE INTO categories (name) VALUES
    ('Floor Care'),
    ('Surface Cleaners'),
    ('Laundry'),
    ('Dishwashing'),
    ('Paper & Tissue'),
    ('Trash Bags & Liners'),
    ('Disinfectants & Sanitizers');

INSERT INTO suppliers (name, contact_person, phone, email, address)
SELECT s.name, s.contact_person, s.phone, s.email, s.address
FROM (
    SELECT 'BrightHarbor Chemicals Corp.' AS name, 'Lourdes Villanueva' AS contact_person,
           '+63 2 8555 0142' AS phone, 'sales@brightharbor.example' AS email,
           'Unit 5, Eastgate Industrial Park, Cabuyao, Laguna' AS address
    UNION ALL SELECT 'SparklePack Household Products', 'Teresa Bautista',
           '+63 917 555 0123', 'orders@sparklepack.example',
           '18 Mabini Avenue, Biñan, Laguna'
    UNION ALL SELECT 'PureFiber Paper Manufacturing Inc.', 'Ramon Aquino',
           '+63 2 8777 0188', 'accounts@purefiber.example',
           'Km 32 National Highway, Calamba City, Laguna'
    UNION ALL SELECT 'NorthStar Hygiene Supply Co.', 'Daniel Ocampo',
           '+63 2 8444 0197', 'dispatch@northstarhygiene.example',
           '77 Aguinaldo Highway, Imus, Cavite'
) s
WHERE NOT EXISTS (SELECT 1 FROM suppliers x WHERE x.name = s.name);

INSERT IGNORE INTO products (category_id, product_code, product_name, description, unit, price, minimum_stock, is_active)
SELECT c.id, p.product_code, p.product_name, p.description, 'box', p.price, p.minimum_stock, p.is_active
FROM (
    SELECT 'Floor Care' AS category_name, 'CW-FLR-001' AS product_code,
           'Floor Cleaner Lemon 1L' AS product_name,
           'Box of 12 x 1L bottles' AS description,
           540.00 AS price, 20 AS minimum_stock, 1 AS is_active
    UNION ALL SELECT 'Floor Care', 'CW-FLR-002', 'Heavy-Duty Floor Stripper 4L',
           'Box of 4 x 4L jugs', 1280.00, 10, 1
    UNION ALL SELECT 'Floor Care', 'CW-OLD-001', 'Scented Floor Wax 1L (Discontinued)',
           'Box of 12 x 1L bottles', 610.00, 5, 0
    UNION ALL SELECT 'Surface Cleaners', 'CW-SRF-001', 'Multi-Surface Spray Cleaner 500ml',
           'Box of 24 x 500ml trigger bottles', 960.00, 15, 1
    UNION ALL SELECT 'Surface Cleaners', 'CW-SRF-002', 'Glass Cleaner 500ml',
           'Box of 24 x 500ml trigger bottles', 890.00, 12, 1
    UNION ALL SELECT 'Laundry', 'CW-LND-001', 'Powder Detergent 1kg',
           'Box of 20 x 1kg packs', 1150.00, 25, 1
    UNION ALL SELECT 'Laundry', 'CW-LND-002', 'Fabric Softener 1L',
           'Box of 12 x 1L bottles', 720.00, 15, 1
    UNION ALL SELECT 'Dishwashing', 'CW-DSH-001', 'Dishwashing Liquid Lemon 500ml',
           'Box of 24 x 500ml bottles', 780.00, 20, 1
    UNION ALL SELECT 'Dishwashing', 'CW-DSH-002', 'Dishwashing Paste 400g',
           'Box of 36 x 400g tubs', 650.00, 10, 1
    UNION ALL SELECT 'Paper & Tissue', 'CW-PPR-001', 'Toilet Tissue 2-Ply 12-Roll Pack',
           'Box of 8 packs', 1020.00, 30, 1
    UNION ALL SELECT 'Paper & Tissue', 'CW-PPR-002', 'Interfolded Paper Towels',
           'Box of 20 packs', 1340.00, 18, 1
    UNION ALL SELECT 'Trash Bags & Liners', 'CW-TRB-001', 'Heavy-Duty Trash Bags XL 10pcs',
           'Box of 50 packs', 860.00, 20, 1
    UNION ALL SELECT 'Disinfectants & Sanitizers', 'CW-DIS-001', 'Hand Sanitizer 70% 500ml',
           'Box of 24 x 500ml pump bottles', 1480.00, 12, 1
    UNION ALL SELECT 'Disinfectants & Sanitizers', 'CW-DIS-002', 'Bleach 1L',
           'Box of 12 x 1L bottles', 420.00, 20, 1
) p
JOIN categories c ON c.name = p.category_name;

INSERT IGNORE INTO product_suppliers (product_id, supplier_id)
SELECT p.id, s.id
FROM (
    SELECT 'CW-FLR-001' AS product_code, 'BrightHarbor Chemicals Corp.' AS supplier_name
    UNION ALL SELECT 'CW-FLR-002', 'BrightHarbor Chemicals Corp.'
    UNION ALL SELECT 'CW-OLD-001', 'BrightHarbor Chemicals Corp.'
    UNION ALL SELECT 'CW-SRF-001', 'BrightHarbor Chemicals Corp.'
    UNION ALL SELECT 'CW-SRF-001', 'NorthStar Hygiene Supply Co.'
    UNION ALL SELECT 'CW-SRF-002', 'BrightHarbor Chemicals Corp.'
    UNION ALL SELECT 'CW-DIS-002', 'BrightHarbor Chemicals Corp.'
    UNION ALL SELECT 'CW-DIS-002', 'NorthStar Hygiene Supply Co.'
    UNION ALL SELECT 'CW-DIS-001', 'NorthStar Hygiene Supply Co.'
    UNION ALL SELECT 'CW-LND-001', 'SparklePack Household Products'
    UNION ALL SELECT 'CW-LND-002', 'SparklePack Household Products'
    UNION ALL SELECT 'CW-DSH-001', 'SparklePack Household Products'
    UNION ALL SELECT 'CW-DSH-002', 'SparklePack Household Products'
    UNION ALL SELECT 'CW-TRB-001', 'SparklePack Household Products'
    UNION ALL SELECT 'CW-TRB-001', 'PureFiber Paper Manufacturing Inc.'
    UNION ALL SELECT 'CW-PPR-001', 'PureFiber Paper Manufacturing Inc.'
    UNION ALL SELECT 'CW-PPR-002', 'PureFiber Paper Manufacturing Inc.'
) m
JOIN products p ON p.product_code = m.product_code
JOIN suppliers s ON s.name = m.supplier_name;

DROP PROCEDURE IF EXISTS sp_seed_initial_stock;

DELIMITER $$

CREATE PROCEDURE sp_seed_initial_stock()
BEGIN
    DECLARE v_manager INT;
    DECLARE v_staff INT;
    DECLARE v_brightharbor INT;
    DECLARE v_sparklepack INT;
    DECLARE v_purefiber INT;
    DECLARE v_northstar INT;
    DECLARE v_items TEXT;
    DECLARE v_tx INT;

    IF NOT EXISTS (SELECT 1 FROM stock_transactions WHERE reference_no LIKE 'SEED-%') THEN
        SELECT id INTO v_manager FROM users WHERE username = 'jreyes';
        SELECT id INTO v_staff FROM users WHERE username = 'adelacruz';
        SELECT id INTO v_brightharbor FROM suppliers WHERE name = 'BrightHarbor Chemicals Corp.' LIMIT 1;
        SELECT id INTO v_sparklepack FROM suppliers WHERE name = 'SparklePack Household Products' LIMIT 1;
        SELECT id INTO v_purefiber FROM suppliers WHERE name = 'PureFiber Paper Manufacturing Inc.' LIMIT 1;
        SELECT id INTO v_northstar FROM suppliers WHERE name = 'NorthStar Hygiene Supply Co.' LIMIT 1;

        DROP TEMPORARY TABLE IF EXISTS tmp_seed_lines;
        CREATE TEMPORARY TABLE tmp_seed_lines (
            tx_ref VARCHAR(10) NOT NULL,
            product_code VARCHAR(50) NOT NULL,
            quantity INT NOT NULL,
            unit_cost DECIMAL(10,2) NOT NULL
        );

        INSERT INTO tmp_seed_lines (tx_ref, product_code, quantity, unit_cost) VALUES
            ('PO1', 'CW-FLR-001', 150, 410.00),
            ('PO1', 'CW-FLR-002', 40, 980.00),
            ('PO1', 'CW-SRF-001', 90, 730.00),
            ('PO1', 'CW-SRF-002', 8, 680.00),
            ('PO1', 'CW-DIS-002', 100, 320.00),
            ('PO2', 'CW-LND-001', 200, 880.00),
            ('PO2', 'CW-LND-002', 60, 550.00),
            ('PO2', 'CW-DSH-001', 120, 590.00),
            ('PO2', 'CW-DSH-002', 15, 490.00),
            ('PO2', 'CW-TRB-001', 140, 660.00),
            ('PO3', 'CW-PPR-001', 220, 780.00),
            ('PO3', 'CW-PPR-002', 25, 1020.00),
            ('PO4', 'CW-DIS-001', 14, 1120.00),
            ('PO5', 'CW-PPR-001', 50, 790.00),
            ('SO1', 'CW-PPR-002', 10, 1340.00),
            ('SO1', 'CW-DIS-001', 4, 1480.00),
            ('SO1', 'CW-FLR-001', 30, 540.00),
            ('AD1', 'CW-DSH-002', 2, 0.00);

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'PO1';
        CALL sp_record_stock_in(v_staff, v_brightharbor, 'SEED-PO-0001', v_items, v_tx);
        CALL sp_review_transaction(v_tx, v_manager, 'approved');

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'PO2';
        CALL sp_record_stock_in(v_staff, v_sparklepack, 'SEED-PO-0002', v_items, v_tx);
        CALL sp_review_transaction(v_tx, v_manager, 'approved');

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'PO3';
        CALL sp_record_stock_in(v_staff, v_purefiber, 'SEED-PO-0003', v_items, v_tx);
        CALL sp_review_transaction(v_tx, v_manager, 'approved');

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'PO4';
        CALL sp_record_stock_in(v_staff, v_northstar, 'SEED-PO-0004', v_items, v_tx);
        CALL sp_review_transaction(v_tx, v_manager, 'approved');

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'SO1';
        CALL sp_record_stock_out(v_staff, 'SEED-SO-0001', v_items, v_tx);
        CALL sp_review_transaction(v_tx, v_manager, 'approved');

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'PO5';
        CALL sp_record_stock_in(v_staff, v_purefiber, 'SEED-PO-0005', v_items, v_tx);

        SELECT GROUP_CONCAT(CONCAT(p.id, ':', l.quantity, ':', l.unit_cost) SEPARATOR '|')
        INTO v_items
        FROM tmp_seed_lines l
        JOIN products p ON p.product_code = l.product_code
        WHERE l.tx_ref = 'AD1';
        CALL sp_record_adjustment(v_staff, 'decrease', 'SEED-ADJ-0001', v_items, v_tx);

        DROP TEMPORARY TABLE IF EXISTS tmp_seed_lines;
    END IF;
END$$

DELIMITER ;

CALL sp_seed_initial_stock();

DROP PROCEDURE IF EXISTS sp_seed_initial_stock;

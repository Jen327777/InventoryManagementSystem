USE cleanway_ims;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_low_stock_alerts AS
SELECT
    p.id AS product_id,
    p.product_code,
    p.product_name,
    c.name AS category_name,
    p.unit,
    i.quantity_on_hand,
    p.minimum_stock,
    (p.minimum_stock - i.quantity_on_hand) AS shortfall,
    CASE WHEN i.quantity_on_hand = 0 THEN 'Out of Stock' ELSE 'Low Stock' END AS alert_level,
    i.updated_at AS last_updated
FROM products p
JOIN inventory i ON i.product_id = p.id
JOIN categories c ON c.id = p.category_id
WHERE i.quantity_on_hand <= p.minimum_stock
  AND p.is_active = TRUE;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_inventory_summary AS
SELECT
    p.id AS product_id,
    p.product_code,
    p.product_name,
    c.name AS category_name,
    COALESCE(ps.supplier_names, '') AS supplier_names,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    p.unit,
    p.price,
    i.quantity_on_hand,
    p.minimum_stock,
    (i.quantity_on_hand * p.price) AS stock_value,
    CASE
        WHEN i.quantity_on_hand = 0 THEN 'Out of Stock'
        WHEN i.quantity_on_hand <= p.minimum_stock THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    p.is_active,
    i.updated_at AS last_updated
FROM products p
JOIN categories c ON c.id = p.category_id
JOIN inventory i ON i.product_id = p.id
LEFT JOIN (
    SELECT
        link.product_id,
        COUNT(*) AS supplier_count,
        GROUP_CONCAT(s.name ORDER BY s.name SEPARATOR ', ') AS supplier_names
    FROM product_suppliers link
    JOIN suppliers s ON s.id = link.supplier_id
    GROUP BY link.product_id
) ps ON ps.product_id = p.id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_transaction_audit_log AS
SELECT
    t.id AS transaction_id,
    t.transaction_code,
    t.type AS transaction_type,
    t.adjustment_direction,
    t.status,
    t.reference_no,
    t.transaction_date,
    sup.name AS supplier_name,
    cu.full_name AS created_by_name,
    cu.username AS created_by_username,
    cr.name AS created_by_role,
    ru.full_name AS reviewed_by_name,
    ru.username AS reviewed_by_username,
    rr.name AS reviewed_by_role,
    t.reviewed_at,
    ti.id AS item_id,
    p.product_code,
    p.product_name,
    ti.quantity,
    ti.unit_cost,
    (ti.quantity * ti.unit_cost) AS line_total,
    CASE
        WHEN t.status <> 'approved' OR ti.id IS NULL THEN 0
        WHEN t.type = 'stock_in' OR (t.type = 'adjustment' AND t.adjustment_direction = 'increase') THEN ti.quantity
        ELSE -ti.quantity
    END AS applied_quantity_change
FROM stock_transactions t
JOIN users cu ON cu.id = t.created_by
JOIN roles cr ON cr.id = cu.role_id
LEFT JOIN users ru ON ru.id = t.reviewed_by
LEFT JOIN roles rr ON rr.id = ru.role_id
LEFT JOIN suppliers sup ON sup.id = t.supplier_id
LEFT JOIN stock_transaction_items ti ON ti.transaction_id = t.id
LEFT JOIN products p ON p.id = ti.product_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_role_permissions AS
SELECT r.id AS role_id, r.name AS role_name, f.feature
FROM roles r
JOIN (
    SELECT 'dashboard' AS feature, 1 AS administrator, 1 AS manager, 1 AS inventory_staff
    UNION ALL SELECT 'user_management', 1, 0, 0
    UNION ALL SELECT 'role_management', 1, 0, 0
    UNION ALL SELECT 'product_management', 1, 1, 1
    UNION ALL SELECT 'supplier_management', 1, 1, 1
    UNION ALL SELECT 'view_inventory', 1, 1, 1
    UNION ALL SELECT 'record_stock_in', 1, 1, 1
    UNION ALL SELECT 'record_stock_out', 1, 1, 1
    UNION ALL SELECT 'review_transactions', 1, 1, 0
    UNION ALL SELECT 'approve_stock_adjustments', 1, 1, 0
    UNION ALL SELECT 'view_reports', 1, 1, 0
    UNION ALL SELECT 'view_limited_reports', 1, 1, 1
    UNION ALL SELECT 'system_settings', 1, 0, 0
) f ON (r.name = 'Administrator' AND f.administrator = 1)
    OR (r.name = 'Manager' AND f.manager = 1)
    OR (r.name = 'Inventory Staff' AND f.inventory_staff = 1);

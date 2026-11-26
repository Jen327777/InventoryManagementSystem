<?php

class ProductController
{
    public function index(array $params): never
    {
        Auth::requireLogin();
        $db = Database::connection();
        $sql = "SELECT p.id, p.category_id, c.name AS category_name, p.product_code, p.product_name, p.description, p.unit, p.price, p.minimum_stock, p.is_active, i.quantity_on_hand, p.created_at, p.updated_at
                FROM products p JOIN categories c ON c.id=p.category_id JOIN inventory i ON i.product_id=p.id WHERE 1=1";
        $values = [];
        if (isset($_GET['active'])) {
            $sql .= ' AND p.is_active = ?';
            $values[] = filter_var($_GET['active'], FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
        }
        if (!empty($_GET['search'])) {
            $sql .= ' AND (p.product_code LIKE ? OR p.product_name LIKE ?)';
            $search = '%' . trim($_GET['search']) . '%';
            $values[] = $search;
            $values[] = $search;
        }
        $sql .= ' ORDER BY p.product_name ASC';
        $stmt = $db->prepare($sql);
        $stmt->execute($values);
        Response::success('Products retrieved successfully.', $stmt->fetchAll());
    }

    public function store(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']);
        $data = Request::json();
        Request::requireFields($data, ['category_id','product_code','product_name','price','minimum_stock']);
        $categoryId = Validator::id($data['category_id'], 'category_id');
        $code = Validator::string($data['product_code'], 'product_code', 50);
        $name = Validator::string($data['product_name'], 'product_name', 150);
        $description = Validator::optionalString($data['description'] ?? null, 'description', 65535);
        $unit = Validator::string($data['unit'] ?? 'box', 'unit', 20);
        $price = Validator::nonNegativeNumber($data['price'], 'price');
        $minimum = Validator::id($data['minimum_stock'], 'minimum_stock');
        $db = Database::connection();
        $category = $db->prepare('SELECT id FROM categories WHERE id=?');
        $category->execute([$categoryId]);
        if (!$category->fetch()) Response::error('Category not found.', 404);
        try {
            $db->beginTransaction();
            $stmt = $db->prepare('INSERT INTO products (category_id, product_code, product_name, description, unit, price, minimum_stock, is_active) VALUES (?,?,?,?,?,?,?,TRUE)');
            $stmt->execute([$categoryId,$code,$name,$description,$unit,$price,$minimum]);
            $id = (int)$db->lastInsertId();
            $db->commit();
            $stmt = $db->prepare('SELECT * FROM vw_inventory_summary WHERE product_id=?');
            $stmt->execute([$id]);
            Response::success('Product created successfully.', $stmt->fetch(), 201);
        } catch (Throwable $e) {
            if ($db->inTransaction()) $db->rollBack();
            if ($e instanceof PDOException && $e->getCode() === '23000') Response::error('Product code already exists.', 409);
            throw $e;
        }
    }

    public function show(array $params): never
    {
        Auth::requireLogin();
        $id = Validator::id($params['id']);
        $stmt = Database::connection()->prepare('SELECT * FROM vw_inventory_summary WHERE product_id=?');
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        if (!$product) Response::error('Product not found.', 404);
        Response::success('Product retrieved successfully.', $product);
    }

    public function update(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']);
        $id = Validator::id($params['id']);
        $data = Request::json();
        Request::requireFields($data, ['category_id','product_code','product_name','price','minimum_stock']);
        $categoryId = Validator::id($data['category_id'], 'category_id');
        $code = Validator::string($data['product_code'], 'product_code', 50);
        $name = Validator::string($data['product_name'], 'product_name', 150);
        $description = Validator::optionalString($data['description'] ?? null, 'description', 65535);
        $unit = Validator::string($data['unit'] ?? 'box', 'unit', 20);
        $price = Validator::nonNegativeNumber($data['price'], 'price');
        $minimum = Validator::id($data['minimum_stock'], 'minimum_stock');
        $db = Database::connection();
        $stmt = $db->prepare('UPDATE products SET category_id=?, product_code=?, product_name=?, description=?, unit=?, price=?, minimum_stock=? WHERE id=?');
        try { $stmt->execute([$categoryId,$code,$name,$description,$unit,$price,$minimum,$id]); }
        catch (PDOException $e) { if ($e->getCode()==='23000') Response::error('Product code already exists or category is invalid.',409); throw $e; }
        if ($stmt->rowCount() === 0) {
            $check=$db->prepare('SELECT id FROM products WHERE id=?'); $check->execute([$id]); if(!$check->fetch()) Response::error('Product not found.',404);
        }
        $stmt=$db->prepare('SELECT * FROM vw_inventory_summary WHERE product_id=?'); $stmt->execute([$id]);
        Response::success('Product updated successfully.', $stmt->fetch());
    }

    public function archive(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']);
        $id = Validator::id($params['id']);
        $stmt = Database::connection()->prepare('UPDATE products SET is_active=FALSE WHERE id=?');
        $stmt->execute([$id]);
        if ($stmt->rowCount()===0) { $check=Database::connection()->prepare('SELECT id,is_active FROM products WHERE id=?'); $check->execute([$id]); $p=$check->fetch(); if(!$p) Response::error('Product not found.',404); if(!(bool)$p['is_active']) Response::success('Product is already archived.', $p); }
        Response::success('Product archived successfully.', ['product_id'=>$id]);
    }
}

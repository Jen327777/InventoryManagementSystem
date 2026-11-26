<?php

class InventoryController
{
    public function index(array $params): never
    {
        Auth::requireLogin();
        $stmt=Database::connection()->query('SELECT * FROM vw_inventory_summary ORDER BY product_name');
        Response::success('Inventory retrieved successfully.',$stmt->fetchAll());
    }

    public function lowStock(array $params): never
    {
        Auth::requireLogin();
        $stmt=Database::connection()->query('SELECT * FROM vw_low_stock_alerts ORDER BY shortfall DESC, product_name');
        Response::success('Low-stock products retrieved successfully.',$stmt->fetchAll());
    }

    public function show(array $params): never
    {
        Auth::requireLogin(); $id=Validator::id($params['product_id'],'product_id');
        $stmt=Database::connection()->prepare('SELECT * FROM vw_inventory_summary WHERE product_id=?'); $stmt->execute([$id]); $row=$stmt->fetch();
        if(!$row) Response::error('Inventory record not found.',404);
        Response::success('Product stock balance retrieved successfully.',$row);
    }
}

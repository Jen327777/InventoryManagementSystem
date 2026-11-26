<?php

class DashboardController
{
    public function summary(array $params): never
    {
        Auth::requireLogin();
        $db = Database::connection();
        $data = [];
        $data['products'] = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_active = TRUE")->fetchColumn();
        $data['categories'] = (int)$db->query("SELECT COUNT(*) FROM categories")->fetchColumn();
        $data['suppliers'] = (int)$db->query("SELECT COUNT(*) FROM suppliers")->fetchColumn();
        $data['inventory_items'] = (int)$db->query("SELECT COUNT(*) FROM inventory i JOIN products p ON p.id=i.product_id WHERE p.is_active=TRUE")->fetchColumn();
        $data['total_units'] = (int)$db->query("SELECT COALESCE(SUM(i.quantity_on_hand),0) FROM inventory i JOIN products p ON p.id=i.product_id WHERE p.is_active=TRUE")->fetchColumn();
        $data['low_stock'] = (int)$db->query("SELECT COUNT(*) FROM vw_low_stock_alerts")->fetchColumn();
        $data['pending_transactions'] = (int)$db->query("SELECT COUNT(*) FROM stock_transactions WHERE status='pending'")->fetchColumn();
        $data['approved_stock_in'] = (int)$db->query("SELECT COUNT(*) FROM stock_transactions WHERE type='stock_in' AND status='approved'")->fetchColumn();
        $data['approved_stock_out'] = (int)$db->query("SELECT COUNT(*) FROM stock_transactions WHERE type='stock_out' AND status='approved'")->fetchColumn();
        Response::success('Dashboard summary retrieved successfully.', $data);
    }
}

<?php

class ReportController
{
    private function reportAccess(): array { return Auth::requireRole(['Administrator','Manager','Inventory Staff']); }

    public function inventory(array $params): never
    {
        $user=$this->reportAccess(); if($user['role_name']==='Inventory Staff'){};
        $stmt=Database::connection()->query('SELECT * FROM vw_inventory_summary ORDER BY category_name, product_name'); Response::success('Inventory report generated successfully.',$stmt->fetchAll());
    }

    public function stockMovements(array $params): never
    {
        $user=$this->reportAccess(); $sql='SELECT * FROM vw_transaction_audit_log WHERE 1=1';$values=[];
        if($user['role_name']==='Inventory Staff'){$sql.=' AND status="approved"';}
        if(!empty($_GET['from'])){$sql.=' AND transaction_date>=?';$values[]=trim($_GET['from']).' 00:00:00';}
        if(!empty($_GET['to'])){$sql.=' AND transaction_date<=?';$values[]=trim($_GET['to']).' 23:59:59';}
        $sql.=' ORDER BY transaction_date DESC, transaction_id DESC';$stmt=Database::connection()->prepare($sql);$stmt->execute($values);Response::success('Stock movement report generated successfully.',$stmt->fetchAll());
    }

    public function lowStock(array $params): never
    {
        $this->reportAccess();$stmt=Database::connection()->query('SELECT * FROM vw_low_stock_alerts ORDER BY shortfall DESC, product_name');Response::success('Low-stock report generated successfully.',$stmt->fetchAll());
    }

    public function purchases(array $params): never
    {
        $this->reportAccess();$sql="SELECT t.id AS transaction_id,t.transaction_code,t.reference_no,t.transaction_date,s.name AS supplier_name,u.full_name AS created_by_name,SUM(ti.quantity*ti.unit_cost) AS total_cost,t.status
                FROM stock_transactions t JOIN stock_transaction_items ti ON ti.transaction_id=t.id LEFT JOIN suppliers s ON s.id=t.supplier_id JOIN users u ON u.id=t.created_by
                WHERE t.type='stock_in'";$values=[];
        if(!empty($_GET['from'])){$sql.=' AND t.transaction_date>=?';$values[]=trim($_GET['from']).' 00:00:00';}
        if(!empty($_GET['to'])){$sql.=' AND t.transaction_date<=?';$values[]=trim($_GET['to']).' 23:59:59';}
        $sql.=' GROUP BY t.id ORDER BY t.transaction_date DESC';$stmt=Database::connection()->prepare($sql);$stmt->execute($values);Response::success('Purchase report generated successfully.',$stmt->fetchAll());
    }
}

<?php

class CategoryController
{
    public function index(array $params): never
    {
        Auth::requireLogin();
        $stmt = Database::connection()->query('SELECT id, name, created_at, updated_at FROM categories ORDER BY name');
        Response::success('Categories retrieved successfully.', $stmt->fetchAll());
    }

    public function store(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']);
        $data=Request::json(); Request::requireFields($data,['name']);
        $name=Validator::string($data['name'],'name',100);
        try { $stmt=Database::connection()->prepare('INSERT INTO categories(name) VALUES(?)'); $stmt->execute([$name]); }
        catch(PDOException $e){ if($e->getCode()==='23000') Response::error('Category name already exists.',409); throw $e; }
        Response::success('Category created successfully.', ['id'=>(int)Database::connection()->lastInsertId(),'name'=>$name],201);
    }
}

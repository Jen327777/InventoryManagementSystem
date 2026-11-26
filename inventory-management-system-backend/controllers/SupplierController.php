<?php

class SupplierController
{
    public function index(array $params): never
    {
        Auth::requireLogin();
        $stmt=Database::connection()->query('SELECT id,name,contact_person,phone,email,address,created_at,updated_at FROM suppliers ORDER BY name');
        Response::success('Suppliers retrieved successfully.', $stmt->fetchAll());
    }

    public function store(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']);
        $data=Request::json(); Request::requireFields($data,['name']);
        $name=Validator::string($data['name'],'name',150);
        $contact=Validator::optionalString($data['contact_person']??null,'contact_person',100);
        $phone=Validator::optionalString($data['phone']??null,'phone',30);
        $email=Validator::optionalString($data['email']??null,'email',100);
        $address=Validator::optionalString($data['address']??null,'address',65535);
        $stmt=Database::connection()->prepare('INSERT INTO suppliers(name,contact_person,phone,email,address) VALUES(?,?,?,?,?)');
        $stmt->execute([$name,$contact,$phone,$email,$address]);
        $id=(int)Database::connection()->lastInsertId();
        Response::success('Supplier created successfully.', ['id'=>$id,'name'=>$name,'contact_person'=>$contact,'phone'=>$phone,'email'=>$email,'address'=>$address],201);
    }

    public function show(array $params): never
    {
        Auth::requireLogin(); $id=Validator::id($params['id']);
        $stmt=Database::connection()->prepare('SELECT id,name,contact_person,phone,email,address,created_at,updated_at FROM suppliers WHERE id=?'); $stmt->execute([$id]); $supplier=$stmt->fetch();
        if(!$supplier) Response::error('Supplier not found.',404);
        $p=Database::connection()->prepare('SELECT p.id,p.product_code,p.product_name FROM product_suppliers ps JOIN products p ON p.id=ps.product_id WHERE ps.supplier_id=? ORDER BY p.product_name'); $p->execute([$id]); $supplier['products']=$p->fetchAll();
        Response::success('Supplier retrieved successfully.',$supplier);
    }

    public function update(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']); $id=Validator::id($params['id']); $data=Request::json(); Request::requireFields($data,['name']);
        $name=Validator::string($data['name'],'name',150); $contact=Validator::optionalString($data['contact_person']??null,'contact_person',100); $phone=Validator::optionalString($data['phone']??null,'phone',30); $email=Validator::optionalString($data['email']??null,'email',100); $address=Validator::optionalString($data['address']??null,'address',65535);
        $stmt=Database::connection()->prepare('UPDATE suppliers SET name=?,contact_person=?,phone=?,email=?,address=? WHERE id=?'); $stmt->execute([$name,$contact,$phone,$email,$address,$id]);
        if($stmt->rowCount()===0){$q=Database::connection()->prepare('SELECT id FROM suppliers WHERE id=?');$q->execute([$id]);if(!$q->fetch())Response::error('Supplier not found.',404);}
        $q=Database::connection()->prepare('SELECT id,name,contact_person,phone,email,address,created_at,updated_at FROM suppliers WHERE id=?');$q->execute([$id]);Response::success('Supplier updated successfully.',$q->fetch());
    }

    public function archive(array $params): never
    {
        Auth::requireRole(['Administrator','Manager','Inventory Staff']);
        Response::error('Supplier archiving is not supported by the approved database schema because suppliers has no active/archive column.',501);
    }
}

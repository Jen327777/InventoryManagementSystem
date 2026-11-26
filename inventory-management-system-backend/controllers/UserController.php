<?php

class UserController
{
    public function index(array $params): never
    {
        Auth::requireRole(['Administrator']);
        $stmt=Database::connection()->query('SELECT u.id,u.role_id,r.name AS role_name,u.full_name,u.username,u.status,u.created_at,u.updated_at FROM users u JOIN roles r ON r.id=u.role_id ORDER BY u.full_name');
        Response::success('Users retrieved successfully.',$stmt->fetchAll());
    }

    public function store(array $params): never
    {
        Auth::requireRole(['Administrator']);$data=Request::json();Request::requireFields($data,['role_id','full_name','username','password']);
        $role=Validator::id($data['role_id'],'role_id');$name=Validator::string($data['full_name'],'full_name',100);$username=Validator::string($data['username'],'username',50);$password=(string)$data['password'];if(strlen($password)<8)Response::error('Password must be at least 8 characters.',422);
        $hash=password_hash($password,PASSWORD_BCRYPT);$status=$data['status']??'active';if(!in_array($status,['active','inactive'],true))Response::error('Invalid status.',422);
        try{$stmt=Database::connection()->prepare('INSERT INTO users(role_id,full_name,username,password_hash,status) VALUES(?,?,?,?,?)');$stmt->execute([$role,$name,$username,$hash,$status]);}catch(PDOException $e){if($e->getCode()==='23000')Response::error('Username or role is invalid/already exists.',409);throw $e;}
        Response::success('User created successfully.',['id'=>(int)Database::connection()->lastInsertId(),'full_name'=>$name,'username'=>$username,'role_id'=>$role,'status'=>$status],201);
    }

    public function update(array $params): never
    {
        Auth::requireRole(['Administrator']);$id=Validator::id($params['id']);$data=Request::json();Request::requireFields($data,['role_id','full_name','username','status']);
        $role=Validator::id($data['role_id'],'role_id');$name=Validator::string($data['full_name'],'full_name',100);$username=Validator::string($data['username'],'username',50);$status=$data['status'];if(!in_array($status,['active','inactive'],true))Response::error('Invalid status.',422);
        $db=Database::connection();if(isset($data['password'])&&$data['password']!==''){if(strlen((string)$data['password'])<8)Response::error('Password must be at least 8 characters.',422);$stmt=$db->prepare('UPDATE users SET role_id=?,full_name=?,username=?,password_hash=?,status=? WHERE id=?');$stmt->execute([$role,$name,$username,password_hash($data['password'],PASSWORD_BCRYPT),$status,$id]);}else{$stmt=$db->prepare('UPDATE users SET role_id=?,full_name=?,username=?,status=? WHERE id=?');$stmt->execute([$role,$name,$username,$status,$id]);}
        if($stmt->rowCount()===0){$q=$db->prepare('SELECT id FROM users WHERE id=?');$q->execute([$id]);if(!$q->fetch())Response::error('User not found.',404);}
        $q=$db->prepare('SELECT u.id,u.role_id,r.name AS role_name,u.full_name,u.username,u.status,u.created_at,u.updated_at FROM users u JOIN roles r ON r.id=u.role_id WHERE u.id=?');$q->execute([$id]);Response::success('User updated successfully.',$q->fetch());
    }
}

<?php

class RoleController
{
    public function index(array $params): never
    {
        Auth::requireRole(['Administrator']);
        $stmt=Database::connection()->query('SELECT role_id AS id, role_name AS name, feature FROM vw_role_permissions ORDER BY role_name, feature');
        $rows=$stmt->fetchAll();$roles=[];foreach($rows as $row){$roles[$row['id']]['id']=(int)$row['id'];$roles[$row['id']]['name']=$row['name'];$roles[$row['id']]['permissions'][]=$row['feature'];}
        Response::success('Roles retrieved successfully.',array_values($roles));
    }
}

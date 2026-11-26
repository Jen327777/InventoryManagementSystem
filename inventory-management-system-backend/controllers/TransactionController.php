<?php

class TransactionController
{
    public function index(array $params): never
    {
        Auth::requireLogin();
        $sql='SELECT * FROM vw_transaction_audit_log WHERE 1=1'; $values=[];
        if(!empty($_GET['status'])){$sql.=' AND status=?';$values[]=trim($_GET['status']);}
        if(!empty($_GET['type'])){$sql.=' AND transaction_type=?';$values[]=trim($_GET['type']);}
        if(!empty($_GET['from'])){$sql.=' AND transaction_date>=?';$values[]=trim($_GET['from']).' 00:00:00';}
        if(!empty($_GET['to'])){$sql.=' AND transaction_date<=?';$values[]=trim($_GET['to']).' 23:59:59';}
        $sql.=' ORDER BY transaction_date DESC, transaction_id DESC';
        $stmt=Database::connection()->prepare($sql);$stmt->execute($values);Response::success('Transaction history retrieved successfully.',$stmt->fetchAll());
    }

    private function buildItems(array $items, bool $requiresCost): string
    {
        if(!$items) Response::error('At least one item is required.',422);
        $parts=[];
        foreach($items as $item){
            if(!is_array($item)) Response::error('Each transaction item must be an object.',422);
            Request::requireFields($item,['product_id','quantity']);
            $pid=Validator::id($item['product_id'],'product_id'); $qty=Validator::id($item['quantity'],'quantity');
            $cost=0;
            if($requiresCost){ Request::requireFields($item,['unit_cost']); $cost=Validator::nonNegativeNumber($item['unit_cost'],'unit_cost'); }
            elseif(isset($item['unit_cost'])) $cost=Validator::nonNegativeNumber($item['unit_cost'],'unit_cost');
            $parts[]=$pid.':'.$qty.':'.number_format($cost,2,'.','');
        }
        return implode('|',$parts);
    }

    public function stockIn(array $params): never
    {
        $user=Auth::requireRole(['Administrator','Manager','Inventory Staff']); $data=Request::json(); Request::requireFields($data,['supplier_id','reference_no','items']);
        $supplier=Validator::id($data['supplier_id'],'supplier_id'); $reference=Validator::string($data['reference_no'],'reference_no',100); $items=$this->buildItems($data['items'],true);
        $out=null; $stmt=Database::connection()->prepare('CALL sp_record_stock_in(?,?,?,?,@transaction_id)'); $stmt->execute([$user['id'],$supplier,$reference,$items]); while($stmt->nextRowset()){}; $q=Database::connection()->query('SELECT @transaction_id AS transaction_id'); $out=(int)$q->fetch()['transaction_id'];
        Response::success('Stock-in recorded successfully.',['transaction_id'=>$out],201);
    }

    public function stockOut(array $params): never
    {
        $user=Auth::requireRole(['Administrator','Manager','Inventory Staff']); $data=Request::json(); Request::requireFields($data,['reference_no','items']);
        $reference=Validator::string($data['reference_no'],'reference_no',100); $items=$this->buildItems($data['items'],false);
        $stmt=Database::connection()->prepare('CALL sp_record_stock_out(?,?,?,@transaction_id)'); $stmt->execute([$user['id'],$reference,$items]); while($stmt->nextRowset()){}; $out=(int)Database::connection()->query('SELECT @transaction_id AS transaction_id')->fetch()['transaction_id'];
        Response::success('Stock-out recorded successfully.',['transaction_id'=>$out],201);
    }

    public function show(array $params): never
    {
        Auth::requireLogin(); $id=Validator::id($params['id']); $db=Database::connection();
        $stmt=$db->prepare('SELECT * FROM stock_transactions WHERE id=?');$stmt->execute([$id]);$tx=$stmt->fetch();if(!$tx)Response::error('Transaction not found.',404);
        $stmt=$db->prepare('SELECT sti.id,sti.product_id,p.product_code,p.product_name,sti.quantity,sti.unit_cost,(sti.quantity*sti.unit_cost) AS line_total FROM stock_transaction_items sti JOIN products p ON p.id=sti.product_id WHERE sti.transaction_id=? ORDER BY sti.id');$stmt->execute([$id]);$tx['items']=$stmt->fetchAll();
        Response::success('Transaction details retrieved successfully.',$tx);
    }

    public function review(array $params): never
    {
        $user=Auth::requireRole(['Administrator','Manager']); $id=Validator::id($params['id'],'id'); $data=Request::json(); Request::requireFields($data,['decision']); $decision=strtolower(Validator::string($data['decision'],'decision',20));
        if(!in_array($decision,['approved','rejected'],true)) Response::error('Decision must be approved or rejected.',422);
        $stmt=Database::connection()->prepare('CALL sp_review_transaction(?,?,?)');$stmt->execute([$id,$user['id'],$decision]);while($stmt->nextRowset()){};
        Response::success('Transaction '.$decision.' successfully.',['transaction_id'=>$id,'status'=>$decision]);
    }
}

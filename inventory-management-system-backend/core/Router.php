<?php

class Router
{
    public static function dispatch(): void
    {
        $method = Request::method();
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $base = rtrim((require __DIR__ . '/../config/app.php')['base_path'], '/');
        if (str_starts_with($path, $base)) {
            $path = substr($path, strlen($base));
        }
        $path = '/' . trim($path, '/');
        if ($path === '//') {
            $path = '/';
        }

        $routes = [
            'POST /auth/login' => ['AuthController', 'login'],
            'POST /auth/logout' => ['AuthController', 'logout'],
            'GET /auth/me' => ['AuthController', 'me'],
            'GET /dashboard/summary' => ['DashboardController', 'summary'],
            'GET /products' => ['ProductController', 'index'],
            'POST /products' => ['ProductController', 'store'],
            'GET /products/{id}' => ['ProductController', 'show'],
            'PUT /products/{id}' => ['ProductController', 'update'],
            'PATCH /products/{id}/archive' => ['ProductController', 'archive'],
            'GET /categories' => ['CategoryController', 'index'],
            'POST /categories' => ['CategoryController', 'store'],
            'GET /suppliers' => ['SupplierController', 'index'],
            'POST /suppliers' => ['SupplierController', 'store'],
            'GET /suppliers/{id}' => ['SupplierController', 'show'],
            'PUT /suppliers/{id}' => ['SupplierController', 'update'],
            'PATCH /suppliers/{id}/archive' => ['SupplierController', 'archive'],
            'GET /inventory' => ['InventoryController', 'index'],
            'GET /inventory/low-stock' => ['InventoryController', 'lowStock'],
            'GET /inventory/{product_id}' => ['InventoryController', 'show'],
            'GET /transactions' => ['TransactionController', 'index'],
            'POST /transactions/stock-in' => ['TransactionController', 'stockIn'],
            'POST /transactions/stock-out' => ['TransactionController', 'stockOut'],
            'GET /transactions/{id}' => ['TransactionController', 'show'],
            'POST /transactions/{id}/review' => ['TransactionController', 'review'],
            'GET /reports/inventory' => ['ReportController', 'inventory'],
            'GET /reports/stock-movements' => ['ReportController', 'stockMovements'],
            'GET /reports/low-stock' => ['ReportController', 'lowStock'],
            'GET /reports/purchases' => ['ReportController', 'purchases'],
            'GET /users' => ['UserController', 'index'],
            'POST /users' => ['UserController', 'store'],
            'PUT /users/{id}' => ['UserController', 'update'],
            'GET /roles' => ['RoleController', 'index'],
        ];

        foreach ($routes as $pattern => $handler) {
            [$routeMethod, $routePath] = explode(' ', $pattern, 2);
            if ($method !== $routeMethod) {
                continue;
            }
            $regex = preg_replace('/\{([a-zA-Z_]+)\}/', '(?P<$1>[0-9]+)', $routePath);
            $regex = '#^' . $regex . '$#';
            if (preg_match($regex, $path, $matches)) {
                $params = [];
                foreach ($matches as $key => $value) {
                    if (!is_int($key)) {
                        $params[$key] = (int)$value;
                    }
                }
                [$class, $methodName] = $handler;
                require_once __DIR__ . '/../controllers/' . $class . '.php';
                (new $class())->{$methodName}($params);
                return;
            }
        }

        Response::error('Endpoint not found.', 404);
    }
}

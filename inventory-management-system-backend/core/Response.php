<?php

class Response
{
    public static function json(bool $success, string $message, mixed $data = null, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => $success,
            'message' => $message,
            'data' => $data,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function success(string $message, mixed $data = null, int $status = 200): never
    {
        self::json(true, $message, $data, $status);
    }

    public static function error(string $message, int $status = 400, mixed $data = null): never
    {
        self::json(false, $message, $data, $status);
    }
}

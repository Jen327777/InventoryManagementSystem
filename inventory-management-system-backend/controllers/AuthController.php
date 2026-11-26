<?php

class AuthController
{
    public function login(array $params): never
    {
        $data = Request::json();
        Request::requireFields($data, ['username', 'password']);
        $username = Validator::string($data['username'], 'username', 50);
        $password = (string)$data['password'];

        $stmt = Database::connection()->prepare(
            'SELECT u.id, u.full_name, u.username, u.password_hash, u.status, r.id AS role_id, r.name AS role_name
             FROM users u JOIN roles r ON r.id = u.role_id WHERE u.username = ? LIMIT 1'
        );
        $stmt->execute([$username]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            Response::error('Invalid username or password.', 401);
        }
        if ($user['status'] !== 'active') {
            Response::error('User account is inactive.', 403);
        }

        unset($user['password_hash']);
        Auth::login($user);
        Response::success('Login successful.', ['user' => $user]);
    }

    public function logout(array $params): never
    {
        Auth::requireLogin();
        Auth::logout();
        Response::success('Logout successful.');
    }

    public function me(array $params): never
    {
        $user = Auth::requireLogin();
        Response::success('Logged-in user retrieved successfully.', ['user' => $user]);
    }
}

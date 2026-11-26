# Cleanway Inventory Management System API

## Base URL

`http://localhost/inventory-management-system/api`

## Requirements

- XAMPP Apache + MySQL
- PHP 8.1+ recommended
- PDO MySQL enabled
- Cleanway database installed from Gege's approved SQL scripts

## Installation

1. Put the project folder at:
   `C:\xampp\htdocs\inventory-management-system`
2. Copy the `api` folder from this package into the project folder.
3. Copy `config`, `core`, and `controllers` into the project root as shown in this package, or keep the supplied structure if the package is the whole backend.
4. Set MySQL credentials in `config/database.php`.
5. Start Apache and MySQL in XAMPP.
6. Test:
   `GET http://localhost/inventory-management-system/api/auth/me`

## API response format

Successful response:

```json
{
  "success": true,
  "message": "...",
  "data": {}
}
```

Error response:

```json
{
  "success": false,
  "message": "...",
  "data": null
}
```

## Authentication

The API uses a PHP session cookie. Call `POST /auth/login` first, then send the session cookie with protected requests.

## Additional endpoint

The agreed endpoint list did not include a transaction review endpoint, but the approved database requires pending transactions to be approved or rejected by an Administrator or Manager. Therefore this backend adds:

`POST /transactions/{id}/review`

Request:

```json
{
  "decision": "approved"
}
```

or

```json
{
  "decision": "rejected"
}
```

## Supplier archive limitation

The approved `suppliers` table has no `is_active`, `status`, or archive column. The requested `PATCH /suppliers/{id}/archive` route is present but returns HTTP 501 until the database schema provides a supported archive field. No unapproved database column was added.

## Stock transaction flow

Stock-in and stock-out endpoints create transactions as `pending`. Inventory is updated only when an Administrator or Manager approves the transaction through `/transactions/{id}/review`, matching the database procedures and triggers.

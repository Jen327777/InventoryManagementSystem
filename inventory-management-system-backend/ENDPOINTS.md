# Cleanway IMS API Contract

Base URL: `http://localhost/inventory-management-system/api`

| Method | Endpoint | Access |
|---|---|---|
| POST | `/auth/login` | Public |
| POST | `/auth/logout` | Authenticated |
| GET | `/auth/me` | Authenticated |
| GET | `/dashboard/summary` | Authenticated |
| GET | `/products` | Authenticated |
| POST | `/products` | Administrator, Manager, Inventory Staff |
| GET | `/products/{id}` | Authenticated |
| PUT | `/products/{id}` | Administrator, Manager, Inventory Staff |
| PATCH | `/products/{id}/archive` | Administrator, Manager, Inventory Staff |
| GET | `/categories` | Authenticated |
| POST | `/categories` | Administrator, Manager, Inventory Staff |
| GET | `/suppliers` | Authenticated |
| POST | `/suppliers` | Administrator, Manager, Inventory Staff |
| GET | `/suppliers/{id}` | Authenticated |
| PUT | `/suppliers/{id}` | Administrator, Manager, Inventory Staff |
| PATCH | `/suppliers/{id}/archive` | Present, but blocked by current schema |
| GET | `/inventory` | Authenticated |
| GET | `/inventory/low-stock` | Authenticated |
| GET | `/inventory/{product_id}` | Authenticated |
| GET | `/transactions` | Authenticated |
| POST | `/transactions/stock-in` | Administrator, Manager, Inventory Staff |
| POST | `/transactions/stock-out` | Administrator, Manager, Inventory Staff |
| GET | `/transactions/{id}` | Authenticated |
| POST | `/transactions/{id}/review` | Administrator, Manager |
| GET | `/reports/inventory` | Administrator, Manager, Inventory Staff |
| GET | `/reports/stock-movements` | Administrator, Manager, Inventory Staff |
| GET | `/reports/low-stock` | Administrator, Manager, Inventory Staff |
| GET | `/reports/purchases` | Administrator, Manager, Inventory Staff |
| GET | `/users` | Administrator |
| POST | `/users` | Administrator |
| PUT | `/users/{id}` | Administrator |
| GET | `/roles` | Administrator |

## Stock-in example

```json
{
  "supplier_id": 1,
  "reference_no": "PO-001",
  "items": [
    {
      "product_id": 1,
      "quantity": 100,
      "unit_cost": 150.00
    }
  ]
}
```

## Stock-out example

```json
{
  "reference_no": "SO-001",
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ]
}
```

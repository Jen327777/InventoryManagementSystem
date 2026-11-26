<?php

class Validator
{
    public static function id(mixed $value, string $field = 'id'): int
    {
        if (filter_var($value, FILTER_VALIDATE_INT) === false || (int)$value < 1) {
            Response::error("{$field} must be a positive integer.", 422);
        }
        return (int)$value;
    }

    public static function string(mixed $value, string $field, int $max): string
    {
        if (!is_string($value) || trim($value) === '' || mb_strlen(trim($value)) > $max) {
            Response::error("{$field} is invalid or exceeds {$max} characters.", 422);
        }
        return trim($value);
    }

    public static function optionalString(mixed $value, string $field, int $max): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }
        return self::string($value, $field, $max);
    }

    public static function nonNegativeNumber(mixed $value, string $field): float
    {
        if (!is_numeric($value) || (float)$value < 0) {
            Response::error("{$field} must be a non-negative number.", 422);
        }
        return (float)$value;
    }

    public static function positiveInt(mixed $value, string $field): int
    {
        $id = self::id($value, $field);
        return $id;
    }
}

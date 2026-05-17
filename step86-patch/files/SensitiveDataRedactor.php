<?php

namespace App\Support;

class SensitiveDataRedactor
{
    private const SENSITIVE_KEYS = [
        'password', 'password_confirmation', 'current_password', 'new_password',
        'token', 'access_token', 'auth_token', 'refresh_token', 'api_key', 'apikey',
        'authorization', 'cookie', 'set-cookie', 'x-api-key',
        'medical_notes', 'diagnosis', 'lab_result', 'lab_results', 'medication_notes',
        'notes', 'description', 'metadata',
    ];

    public static function redact(mixed $value): mixed
    {
        if (is_array($value)) {
            $redacted = [];

            foreach ($value as $key => $item) {
                $keyString = strtolower((string) $key);

                if (self::isSensitiveKey($keyString)) {
                    $redacted[$key] = '[REDACTED]';
                    continue;
                }

                $redacted[$key] = self::redact($item);
            }

            return $redacted;
        }

        if (is_object($value)) {
            return self::redact((array) $value);
        }

        if (is_string($value)) {
            return self::redactString($value);
        }

        return $value;
    }

    public static function redactHeaders(array $headers): array
    {
        return self::redact($headers);
    }

    public static function redactString(string $value): string
    {
        $value = preg_replace('/Bearer\s+[A-Za-z0-9_\-\.\|]+/i', 'Bearer [REDACTED]', $value) ?? $value;
        $value = preg_replace('/(password|token|api[_-]?key|authorization)(["\'\s:=]+)([^,\s"\']+)/i', '$1$2[REDACTED]', $value) ?? $value;

        return $value;
    }

    private static function isSensitiveKey(string $key): bool
    {
        foreach (self::SENSITIVE_KEYS as $sensitiveKey) {
            if ($key === $sensitiveKey || str_contains($key, $sensitiveKey)) {
                return true;
            }
        }

        return false;
    }
}

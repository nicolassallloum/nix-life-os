<?php

namespace App\Services\Monitoring;

use App\Models\AuditLog;
use App\Models\ErrorLog;
use Throwable;

class LoggingService
{
    public static function audit(
        string $action,
        ?string $module = null,
        ?string $entityType = null,
        ?string $entityId = null,
        ?array $oldValues = null,
        ?array $newValues = null,
        ?array $metadata = null
    ): void {
        try {
            AuditLog::create([
                'user_id' => auth()->id(),
                'module' => $module,
                'action' => $action,
                'entity_type' => $entityType,
                'entity_id' => $entityId,
                'old_values' => $oldValues,
                'new_values' => $newValues,
                'metadata' => $metadata,
                'ip_address' => request()?->ip(),
                'user_agent' => request()?->userAgent(),
            ]);
        } catch (Throwable $e) {
            logger()->error('Audit logging failed', [
                'message' => $e->getMessage(),
            ]);
        }
    }

    public static function error(Throwable $exception, ?string $module = null, ?array $metadata = null): void
    {
        try {
            ErrorLog::create([
                'user_id' => auth()->id(),
                'level' => 'error',
                'module' => $module,
                'exception_class' => get_class($exception),
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
                'request_method' => request()?->method(),
                'request_url' => request()?->fullUrl(),
                'request_payload' => self::safePayload(),
                'trace' => substr($exception->getTraceAsString(), 0, 8000),
                'metadata' => $metadata,
                'ip_address' => request()?->ip(),
                'user_agent' => request()?->userAgent(),
            ]);
        } catch (Throwable $e) {
            logger()->error('Error logging failed', [
                'message' => $e->getMessage(),
            ]);
        }
    }

    private static function safePayload(): array
    {
        $payload = request()?->except([
            'password',
            'password_confirmation',
            'current_password',
            'token',
            'access_token',
            'refresh_token',
        ]);

        return $payload ?? [];
    }
}

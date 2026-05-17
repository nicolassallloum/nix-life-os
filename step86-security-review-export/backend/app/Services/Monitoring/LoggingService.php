<?php

namespace App\Services\Monitoring;

use App\Models\ErrorLog;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Throwable;

class LoggingService
{
    /**
     * Store unexpected application errors without creating recursive DB failures.
     */
    public static function error(Throwable $exception, string $module = 'application', array $metadata = []): void
    {
        if (self::isDatabaseConnectionFailure($exception)) {
            Log::error('Database unavailable.', [
                'module' => $module,
                'exception_class' => $exception::class,
                'sql_state' => self::sqlState($exception),
            ]);

            return;
        }

        try {
            if (! Schema::hasTable('error_logs')) {
                Log::error($exception->getMessage(), [
                    'module' => $module,
                    'exception_class' => $exception::class,
                ]);

                return;
            }

            $request = request();
            $user = $request?->user();

            ErrorLog::create([
                'user_id' => $user?->id,
                'level' => 'error',
                'module' => $module,
                'exception_class' => $exception::class,
                'message' => mb_substr($exception->getMessage(), 0, 5000),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
                'request_method' => $request?->method(),
                'request_url' => $request?->fullUrl(),
                'request_payload' => self::safePayload($request?->all() ?? []),
                'trace' => mb_substr($exception->getTraceAsString(), 0, 10000),
                'metadata' => $metadata,
                'ip_address' => $request?->ip(),
                'user_agent' => $request?->userAgent(),
                'created_at' => now(),
            ]);
        } catch (Throwable $loggingException) {
            Log::error('Error logging failed.', [
                'original_exception_class' => $exception::class,
                'logging_exception_class' => $loggingException::class,
                'logging_message' => $loggingException->getMessage(),
            ]);
        }
    }

    private static function safePayload(array $payload): array
    {
        foreach (['password', 'password_confirmation', 'token', 'access_token', 'authorization'] as $key) {
            if (array_key_exists($key, $payload)) {
                $payload[$key] = '[redacted]';
            }
        }

        return $payload;
    }

    private static function isDatabaseConnectionFailure(Throwable $exception): bool
    {
        return $exception instanceof QueryException
            && in_array(self::sqlState($exception), ['08006', '08001', '08003', '08004', '08007'], true);
    }

    private static function sqlState(Throwable $exception): string
    {
        if ($exception instanceof QueryException) {
            return (string) ($exception->errorInfo[0] ?? $exception->getCode());
        }

        return (string) $exception->getCode();
    }
}

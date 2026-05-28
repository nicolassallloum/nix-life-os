<?php

use App\Http\Middleware\ApiAuditLogger;
use App\Http\Middleware\ApiPerformanceLogger;
use App\Http\Middleware\EnsureUserHasPermission;
use App\Http\Middleware\EnsureUserHasRole;
use App\Http\Middleware\ForceJsonResponse;
use App\Http\Middleware\SecurityHeaders;
use App\Services\Monitoring\LoggingService;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\HandleCors;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Spatie\Permission\Middleware\PermissionMiddleware;
use Spatie\Permission\Middleware\RoleMiddleware;
use Spatie\Permission\Middleware\RoleOrPermissionMiddleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        /*
        |--------------------------------------------------------------------------
        | API Middleware
        |--------------------------------------------------------------------------
        */

        $middleware->api(prepend: [
            HandleCors::class,
            ForceJsonResponse::class,
        ]);

        $middleware->api(append: [
            SecurityHeaders::class,
            ApiPerformanceLogger::class,
        ]);

        /*
        |--------------------------------------------------------------------------
        | API Redirect Handling
        |--------------------------------------------------------------------------
        */

        $middleware->redirectGuestsTo(function (Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return null;
            }

            return '/login';
        });

        /*
        |--------------------------------------------------------------------------
        | Middleware Aliases
        |--------------------------------------------------------------------------
        */

        $middleware->alias([
            'api.audit' => ApiAuditLogger::class,
            'api.performance' => ApiPerformanceLogger::class,
            'security.headers' => SecurityHeaders::class,

            'role' => RoleMiddleware::class,
            'permission' => PermissionMiddleware::class,
            'role_or_permission' => RoleOrPermissionMiddleware::class,

            'nix.role' => EnsureUserHasRole::class,
            'nix.permission' => EnsureUserHasPermission::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        /*
        |--------------------------------------------------------------------------
        | Force JSON for API Requests
        |--------------------------------------------------------------------------
        */

        $exceptions->shouldRenderJsonWhen(function (Request $request, \Throwable $e) {
            return $request->is('api/*') || $request->expectsJson();
        });

        /*
        |--------------------------------------------------------------------------
        | Exception Reporting
        |--------------------------------------------------------------------------
        |
        | Important:
        | Do not call request() here because artisan commands do not always
        | have a request object.
        |
        */

        $exceptions->report(function (\Throwable $e) {
            try {
                if (class_exists(LoggingService::class)) {
                    LoggingService::error($e, 'global_exception_handler');
                }
            } catch (\Throwable $loggingException) {
                Log::error('Global exception logging failed.', [
                    'exception_class' => $e::class,
                    'logging_exception_class' => $loggingException::class,
                    'message' => $loggingException->getMessage(),
                ]);
            }

            return false;
        });

        /*
        |--------------------------------------------------------------------------
        | API Exception Renderer
        |--------------------------------------------------------------------------
        */

        $exceptions->render(function (\Throwable $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            $requestId = $request->header('X-Request-ID');

            if (! $requestId && function_exists('str')) {
                $requestId = (string) str()->uuid();
            }

            return response()->json([
                'success' => false,
                'message' => 'Server error. Please try again later.',
                'error' => [
                    'code' => 'SERVER_ERROR',
                    'status' => 500,
                ],
                'request_id' => $requestId,
            ], 500);
        });
    })
    ->create();
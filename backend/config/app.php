<?php

use App\Http\Middleware\ApiAuditLogger;
use App\Http\Middleware\ApiPerformanceLogger;
use App\Http\Middleware\EnsureUserHasPermission;
use App\Http\Middleware\EnsureUserHasRole;
use App\Services\Monitoring\LoggingService;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\HandleCors;
use Illuminate\Http\Request;
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
        |
        | HandleCors must run before protected API routes so browser requests
        | from the Vue frontend can pass OPTIONS and POST requests.
        |
        */

        $middleware->api(prepend: [
            HandleCors::class,
        ]);

        /*
        |--------------------------------------------------------------------------
        | API Middleware Aliases
        |--------------------------------------------------------------------------
        */

        $middleware->alias([
            'api.audit' => ApiAuditLogger::class,
            'api.performance' => ApiPerformanceLogger::class,

            // Spatie Laravel Permission aliases used by API route protection.
            'role' => RoleMiddleware::class,
            'permission' => PermissionMiddleware::class,
            'role_or_permission' => RoleOrPermissionMiddleware::class,

            // Project-local aliases kept for backward compatibility.
            'nix.role' => EnsureUserHasRole::class,
            'nix.permission' => EnsureUserHasPermission::class,
        ]);

        /*
        |--------------------------------------------------------------------------
        | API Unauthenticated Redirect Handling
        |--------------------------------------------------------------------------
        |
        | API requests should return JSON 401 instead of redirecting to /login.
        |
        */

        $middleware->redirectGuestsTo(function (Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return null;
            }

            return '/login';
        });
    })
    ->withExceptions(function (Exceptions $exceptions) {
        /*
        |--------------------------------------------------------------------------
        | Exception Reporting
        |--------------------------------------------------------------------------
        */

        $exceptions->report(function (\Throwable $e) {
            try {
                LoggingService::error($e, 'global_exception_handler');
            } catch (\Throwable $loggingException) {
                logger()->error('Global exception logging failed.', [
                    'exception_class' => $e::class,
                    'logging_exception_class' => $loggingException::class,
                ]);
            }
        });
    })
    ->create();
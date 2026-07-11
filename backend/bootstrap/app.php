<?php

use App\Http\Middleware\ApiAuditLogger;
use App\Http\Middleware\AdminMiddleware;
use App\Http\Middleware\ApiPerformanceLogger;
use App\Http\Middleware\EnsureUserHasPermission;
use App\Http\Middleware\EnsureUserHasRole;
use App\Http\Middleware\ForceJsonResponse;
use App\Http\Middleware\SecurityHeaders;
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
        | HandleCors must be first so OPTIONS/POST requests from Vue work.
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
        | API Authentication Redirect
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
            'admin' => AdminMiddleware::class,
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
        | API JSON Exceptions
        |--------------------------------------------------------------------------
        | Keep this section simple and safe. Do not call request(), Log facade,
        | or database logging here during Artisan boot.
        */

        $exceptions->shouldRenderJsonWhen(function (Request $request, \Throwable $e) {
            return $request->is('api/*') || $request->expectsJson();
        });
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, \Illuminate\Http\Request $request) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated.',
                    'error' => [
                        'code' => 'UNAUTHENTICATED',
                        'status' => 401,
                    ],
                ], 401);
            }

            return null;
        });
        $exceptions->render(function (\Throwable $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            return response()->json([
                'success' => false,
                'message' => 'Server error. Please try again later.',
                'error' => [
                    'code' => 'SERVER_ERROR',
                    'status' => 500,
                ],
            ], 500);
        });
    })
    ->create();

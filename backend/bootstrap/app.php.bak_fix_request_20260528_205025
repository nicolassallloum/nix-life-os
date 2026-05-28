<?php

use App\Http\Middleware\ApiAuditLogger;
use App\Http\Middleware\ApiPerformanceLogger;
use App\Http\Middleware\EnsureUserHasPermission;
use App\Http\Middleware\EnsureUserHasRole;
use App\Http\Middleware\ForceJsonResponse;
use App\Http\Middleware\SecurityHeaders;
use App\Services\Monitoring\LoggingService;
use App\Support\SensitiveDataRedactor;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\HandleCors;
use Illuminate\Http\Request;
use Illuminate\Session\TokenMismatchException;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Exceptions\UnauthorizedException as SpatieUnauthorizedException;
use Spatie\Permission\Middleware\PermissionMiddleware;
use Spatie\Permission\Middleware\RoleMiddleware;
use Spatie\Permission\Middleware\RoleOrPermissionMiddleware;
use Symfony\Component\HttpFoundation\Response as SymfonyResponse;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;
use Symfony\Component\Routing\Exception\RouteNotFoundException as SymfonyRouteNotFoundException;
use \Throwable;

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
        | HandleCors must run before custom JSON/security/performance middleware.
        | This allows Chrome/Vite requests from:
        | http://127.0.0.1:5173
        | http://localhost:5173
        |
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
        | Unauthenticated API Redirect Handling
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

        /*
        |--------------------------------------------------------------------------
        | Middleware Aliases
        |--------------------------------------------------------------------------
        */

        $middleware->alias([
            'api.audit' => ApiAuditLogger::class,
            'api.performance' => ApiPerformanceLogger::class,
            'security.headers' => SecurityHeaders::class,

            // Spatie Laravel Permission aliases used by API route protection.
            'role' => RoleMiddleware::class,
            'permission' => PermissionMiddleware::class,
            'role_or_permission' => RoleOrPermissionMiddleware::class,

            // Project-local aliases kept for backward compatibility.
            'nix.role' => EnsureUserHasRole::class,
            'nix.permission' => EnsureUserHasPermission::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        /*
        |--------------------------------------------------------------------------
        | Force JSON for API Exceptions
        |--------------------------------------------------------------------------
        */

        $exceptions->shouldRenderJsonWhen(function (Request $request, \Throwable $e) {
            return $request->is('api/*') || $request->expectsJson();
        });

        /*
        |--------------------------------------------------------------------------
        | Exception Reporting Policy
        |--------------------------------------------------------------------------
        */

        $exceptions->report(function (\Throwable $e) {
            $ignoredExceptions = [
                AuthenticationException::class,
                AuthorizationException::class,
                SpatieUnauthorizedException::class,
                ValidationException::class,
                ModelNotFoundException::class,
                NotFoundHttpException::class,
                MethodNotAllowedHttpException::class,
                TooManyRequestsHttpException::class,
                TokenMismatchException::class,
            ];

            foreach ($ignoredExceptions as $ignoredException) {
                if ($e instanceof $ignoredException) {
                    return false;
                }
            }

            if ($e instanceof QueryException) {
                $sqlState = (string) ($e->errorInfo[0] ?? $e->getCode());

                // PostgreSQL invalid text representation, usually malformed URL ID.
                if ($sqlState === '22P02') {
                    return false;
                }

                // Database connection failures cannot be saved into the database.
                if (in_array($sqlState, ['08006', '08001', '08003', '08004', '08007'], true)) {
                    Log::error('Database unavailable.', SensitiveDataRedactor::redact([
                        'exception_class' => $e::class,
                        'sql_state' => $sqlState,
                        'request_id' => request()?->header('X-Request-ID'),
                    ]));

                    return false;
                }
            }

            try {
                if (class_exists(LoggingService::class)) {
                    LoggingService::error($e, 'global_exception_handler');
                }
            } catch (\Throwable $loggingException) {
                Log::error('Global exception logging failed.', [
                    'exception_class' => $e::class,
                    'logging_exception_class' => $loggingException::class,
                    'request_id' => request()?->header('X-Request-ID'),
                ]);
            }

            return false;
        });

        /*
        |--------------------------------------------------------------------------
        | API Exception Renderer
        |--------------------------------------------------------------------------
        */

        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            $requestId = $request->header('X-Request-ID')
                ?: (function_exists('str') ? (string) str()->uuid() : null);

            $status = SymfonyResponse::HTTP_INTERNAL_SERVER_ERROR;
            $message = 'Server error. Please try again later.';
            $errorCode = 'SERVER_ERROR';
            $extra = [];

            if ($e instanceof SymfonyRouteNotFoundException && str_contains($e->getMessage(), 'Route [login] not defined')) {
                $status = SymfonyResponse::HTTP_UNAUTHORIZED;
                $message = 'Unauthenticated. Please login again.';
                $errorCode = 'UNAUTHENTICATED';
            } elseif ($e instanceof AuthenticationException || $e instanceof TokenMismatchException) {
                $status = SymfonyResponse::HTTP_UNAUTHORIZED;
                $message = 'Unauthenticated. Please login again.';
                $errorCode = 'UNAUTHENTICATED';
            } elseif ($e instanceof AuthorizationException || $e instanceof SpatieUnauthorizedException) {
                $status = SymfonyResponse::HTTP_FORBIDDEN;
                $message = 'Forbidden. You do not have permission to perform this action.';
                $errorCode = 'FORBIDDEN';
            } elseif ($e instanceof ValidationException) {
                $status = SymfonyResponse::HTTP_UNPROCESSABLE_ENTITY;
                $message = $e->getMessage() ?: 'Validation failed.';
                $errorCode = 'VALIDATION_ERROR';
                $extra['errors'] = $e->errors();
            } elseif ($e instanceof ModelNotFoundException || $e instanceof NotFoundHttpException) {
                $status = SymfonyResponse::HTTP_NOT_FOUND;
                $message = 'The requested resource was not found.';
                $errorCode = 'NOT_FOUND';
            } elseif ($e instanceof MethodNotAllowedHttpException) {
                $status = SymfonyResponse::HTTP_METHOD_NOT_ALLOWED;
                $message = 'HTTP method is not allowed for this endpoint.';
                $errorCode = 'METHOD_NOT_ALLOWED';
            } elseif ($e instanceof TooManyRequestsHttpException) {
                $status = SymfonyResponse::HTTP_TOO_MANY_REQUESTS;
                $message = 'Too many requests. Please try again later.';
                $errorCode = 'TOO_MANY_REQUESTS';
            } elseif ($e instanceof QueryException) {
                $sqlState = (string) ($e->errorInfo[0] ?? $e->getCode());

                if ($sqlState === '22P02') {
                    $status = SymfonyResponse::HTTP_NOT_FOUND;
                    $message = 'The requested resource was not found.';
                    $errorCode = 'NOT_FOUND';
                }
            } elseif ($e instanceof HttpExceptionInterface) {
                $status = $e->getStatusCode();

                if ($status === SymfonyResponse::HTTP_NOT_FOUND) {
                    $message = 'The requested resource was not found.';
                    $errorCode = 'NOT_FOUND';
                } elseif ($status === SymfonyResponse::HTTP_METHOD_NOT_ALLOWED) {
                    $message = 'HTTP method is not allowed for this endpoint.';
                    $errorCode = 'METHOD_NOT_ALLOWED';
                } elseif ($status === SymfonyResponse::HTTP_TOO_MANY_REQUESTS) {
                    $message = 'Too many requests. Please try again later.';
                    $errorCode = 'TOO_MANY_REQUESTS';
                } elseif ($status === SymfonyResponse::HTTP_FORBIDDEN) {
                    $message = 'Forbidden. You do not have permission to perform this action.';
                    $errorCode = 'FORBIDDEN';
                } elseif ($status === SymfonyResponse::HTTP_UNAUTHORIZED) {
                    $message = 'Unauthenticated. Please login again.';
                    $errorCode = 'UNAUTHENTICATED';
                }
            }

            $payload = [
                'success' => false,
                'message' => $message,
                'error' => [
                    'code' => $errorCode,
                    'status' => $status,
                ],
            ];

            if ($requestId) {
                $payload['request_id'] = $requestId;
            }

            if (! empty($extra)) {
                $payload = array_merge($payload, $extra);
            }

            return response()->json($payload, $status);
        });
    })
    ->create();
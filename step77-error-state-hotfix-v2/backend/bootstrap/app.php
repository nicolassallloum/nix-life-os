<?php

use App\Http\Middleware\ApiAuditLogger;
use App\Http\Middleware\ApiPerformanceLogger;
use App\Http\Middleware\EnsureUserHasPermission;
use App\Http\Middleware\EnsureUserHasRole;
use App\Services\Monitoring\LoggingService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
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

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
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
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->shouldRenderJsonWhen(function (Request $request, Throwable $e) {
            return $request->is('api/*') || $request->expectsJson();
        });

        $exceptions->report(function (Throwable $e) {
            try {
                LoggingService::error($e, 'global_exception_handler');
            } catch (Throwable $loggingException) {
                Log::error('Global exception logging failed.', [
                    'exception_class' => $e::class,
                    'logging_exception_class' => $loggingException::class,
                    'request_id' => request()?->header('X-Request-ID'),
                ]);
            }
        });

        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            $requestId = $request->header('X-Request-ID') ?: (function_exists('str') ? (string) str()->uuid() : null);
            $status = SymfonyResponse::HTTP_INTERNAL_SERVER_ERROR;
            $message = 'Server error. Please try again later.';
            $errorCode = 'SERVER_ERROR';
            $extra = [];

            if ($e instanceof AuthenticationException || $e instanceof TokenMismatchException) {
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
                $message = 'Too many requests. Please wait and try again.';
                $errorCode = 'TOO_MANY_REQUESTS';
            } elseif ($e instanceof QueryException) {
                $sqlState = (string) ($e->errorInfo[0] ?? $e->getCode());

                if ($sqlState === '22P02') {
                    $status = SymfonyResponse::HTTP_NOT_FOUND;
                    $message = 'The requested resource was not found.';
                    $errorCode = 'NOT_FOUND';
                } else {
                    $status = SymfonyResponse::HTTP_SERVICE_UNAVAILABLE;
                    $message = 'Database service is temporarily unavailable. Please try again shortly.';
                    $errorCode = 'DATABASE_UNAVAILABLE';
                }
            } elseif ($e instanceof HttpExceptionInterface) {
                $status = $e->getStatusCode();
                $message = match ($status) {
                    Response::HTTP_BAD_REQUEST => 'Bad request.',
                    Response::HTTP_UNAUTHORIZED => 'Unauthenticated. Please login again.',
                    Response::HTTP_FORBIDDEN => 'Forbidden. You do not have permission to perform this action.',
                    Response::HTTP_NOT_FOUND => 'The requested resource was not found.',
                    Response::HTTP_UNPROCESSABLE_ENTITY => 'Validation failed.',
                    Response::HTTP_TOO_MANY_REQUESTS => 'Too many requests. Please wait and try again.',
                    default => $status >= 500 ? 'Server error. Please try again later.' : 'Request failed.',
                };
                $errorCode = strtoupper(str_replace(' ', '_', SymfonyResponse::$statusTexts[$status] ?? 'HTTP_ERROR'));
            }

            $payload = array_merge([
                'success' => false,
                'message' => $message,
                'error' => [
                    'code' => $errorCode,
                    'status' => $status,
                ],
                'request_id' => $requestId,
            ], $extra);

            return response()->json($payload, $status);
        });
    })->create();

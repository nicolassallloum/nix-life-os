<?php

namespace App\Http\Middleware;

use App\Services\Monitoring\LoggingService;
use App\Support\SensitiveDataRedactor;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiAuditLogger
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if ($request->user()) {
            LoggingService::audit(
                action: $request->method() . ' ' . $request->path(),
                module: $this->detectModule($request->path()),
                entityType: 'api_request',
                entityId: null,
                oldValues: null,
                newValues: null,
                metadata: [
                    'status_code' => $response->getStatusCode(),
                    'route' => $request->path(),
                    'query' => SensitiveDataRedactor::redact($request->query()),
                    'ip' => $request->ip(),
                ]
            );
        }

        return $response;
    }

    private function detectModule(string $path): string
    {
        if (str_contains($path, 'finance')) {
            return 'finance';
        }

        if (str_contains($path, 'health')) {
            return 'health';
        }

        if (str_contains($path, 'projects')) {
            return 'projects';
        }

        if (str_contains($path, 'dashboard')) {
            return 'dashboard';
        }

        if (str_contains($path, 'notifications')) {
            return 'notifications';
        }

        if (str_contains($path, 'automation')) {
            return 'automation';
        }

        if (str_contains($path, 'security')) {
            return 'security';
        }

        return 'system';
    }
}

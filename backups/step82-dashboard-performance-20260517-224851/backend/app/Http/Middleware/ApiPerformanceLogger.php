<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class ApiPerformanceLogger
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = microtime(true);
        $memoryStart = memory_get_usage(true);

        $response = $next($request);

        $durationMs = round((microtime(true) - $start) * 1000, 2);
        $memoryMb = round((memory_get_peak_usage(true) - $memoryStart) / 1024 / 1024, 2);

        if ($request->is('api/*') && $durationMs > 500) {
            Log::warning('Slow API endpoint detected', [
                'method' => $request->method(),
                'url' => $request->fullUrl(),
                'duration_ms' => $durationMs,
                'memory_mb' => $memoryMb,
                'status' => $response->getStatusCode(),
                'user_id' => optional($request->user())->id,
            ]);
        }

        return $response;
    }
}
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
        $queryStartCount = app()->bound('step82_query_count') ? (int) app('step82_query_count') : 0;
        $slowThresholdMs = (float) config('performance.slow_api_ms', env('NIX_SLOW_API_MS', 500));

        $response = $next($request);

        $durationMs = round((microtime(true) - $start) * 1000, 2);
        $memoryPeakMb = round(memory_get_peak_usage(true) / 1024 / 1024, 2);
        $memoryDeltaMb = round((memory_get_peak_usage(true) - $memoryStart) / 1024 / 1024, 2);
        $queryCount = app()->bound('step82_query_count') ? (int) app('step82_query_count') : 0;
        $routeQueryCount = max(0, $queryCount - $queryStartCount);

        if ($request->is('api/*')) {
            $response->headers->set('X-Nix-Response-Time-Ms', (string) $durationMs);
            $response->headers->set('X-Nix-Query-Count', (string) $routeQueryCount);

            if ($durationMs >= $slowThresholdMs || $routeQueryCount >= 25) {
                Log::warning('STEP82 slow API endpoint detected', [
                    'method' => $request->method(),
                    'path' => $request->path(),
                    'duration_ms' => $durationMs,
                    'memory_peak_mb' => $memoryPeakMb,
                    'memory_delta_mb' => $memoryDeltaMb,
                    'query_count' => $routeQueryCount,
                    'status' => $response->getStatusCode(),
                    'user_id' => optional($request->user())->id,
                    'request_id' => $request->header('X-Request-ID'),
                ]);
            }
        }

        return $response;
    }
}

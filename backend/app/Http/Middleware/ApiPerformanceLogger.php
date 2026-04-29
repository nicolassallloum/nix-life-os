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

        $response = $next($request);

        $durationMs = round((microtime(true) - $start) * 1000, 2);

        if ($durationMs > 500) {
            Log::warning('Slow API detected', [
                'method' => $request->method(),
                'url' => $request->fullUrl(),
                'duration_ms' => $durationMs,
                'user_id' => optional($request->user())->id,
            ]);
        }

        $response->headers->set('X-Response-Time-ms', $durationMs);

        return $response;
    }
}

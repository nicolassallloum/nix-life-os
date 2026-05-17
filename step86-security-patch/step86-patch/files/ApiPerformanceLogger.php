<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Support\SensitiveDataRedactor;
use Symfony\Component\HttpFoundation\Response;

class ApiPerformanceLogger
{
    public function handle(Request $request, Closure $next): Response
    {
        $startedAt = microtime(true);
        $memoryStart = memory_get_usage(true);
        $queryCount = 0;
        $slowQueries = [];

        DB::listen(function ($query) use (&$queryCount, &$slowQueries) {
            $queryCount++;

            if ($query->time >= 100) {
                $slowQueries[] = [
                    'sql_hash' => sha1($query->sql),
                    'time_ms' => $query->time,
                ];
            }
        });

        /** @var Response $response */
        $response = $next($request);

        $durationMs = round((microtime(true) - $startedAt) * 1000, 2);
        $memoryMb = round((memory_get_peak_usage(true) - $memoryStart) / 1024 / 1024, 2);

        if (! app()->environment('production')) {
            $response->headers->set('X-Nix-Response-Time-Ms', (string) $durationMs);
            $response->headers->set('X-Nix-Query-Count', (string) $queryCount);
        }

        if ($request->is('api/*') && ($durationMs >= 500 || $queryCount >= 25 || count($slowQueries) > 0)) {
            Log::warning('STEP 82 slow API performance signal', [
                'method' => $request->method(),
                'path' => SensitiveDataRedactor::redactString($request->path()),
                'duration_ms' => $durationMs,
                'query_count' => $queryCount,
                'memory_mb' => $memoryMb,
                'status' => $response->getStatusCode(),
                'slow_queries' => $slowQueries,
                'user_id' => optional($request->user())->id,
            ]);
        }

        return $response;
    }
}

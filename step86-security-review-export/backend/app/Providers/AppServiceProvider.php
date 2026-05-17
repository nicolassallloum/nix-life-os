<?php

namespace App\Providers;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        $this->registerStep82QueryTiming();
    }

    private function registerStep82QueryTiming(): void
    {
        if (! app()->bound('step82_query_count')) {
            app()->instance('step82_query_count', 0);
        }

        DB::listen(function ($query) {
            app()->instance('step82_query_count', ((int) app('step82_query_count')) + 1);

            $slowSqlMs = (float) config('performance.slow_sql_ms', env('NIX_SLOW_SQL_MS', 100));

            if ($query->time >= $slowSqlMs) {
                Log::warning('STEP82 slow SQL query detected', [
                    'time_ms' => round((float) $query->time, 2),
                    'sql' => $query->sql,
                    'bindings' => $query->bindings,
                    'request_path' => request()?->path(),
                    'request_id' => request()?->header('X-Request-ID'),
                ]);
            }
        });
    }
}

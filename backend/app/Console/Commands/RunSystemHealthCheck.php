<?php

namespace App\Console\Commands;

use App\Models\SystemMonitoringLog;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class RunSystemHealthCheck extends Command
{
    protected $signature = 'system:health-check';

    protected $description = 'Run NIX LIFE OS system health check';

    public function handle(): int
    {
        $startedAt = microtime(true);

        $status = 'healthy';
        $message = 'System health check completed successfully';

        try {
            DB::select('SELECT 1');
        } catch (Throwable $e) {
            $status = 'unhealthy';
            $message = $e->getMessage();
        }

        $responseTimeMs = round((microtime(true) - $startedAt) * 1000);

        SystemMonitoringLog::create([
            'service_name' => 'scheduled-health-check',
            'status' => $status,
            'response_time_ms' => $responseTimeMs,
            'metrics' => [
                'database' => $status,
                'memory_usage_mb' => round(memory_get_usage(true) / 1024 / 1024, 2),
                'memory_peak_mb' => round(memory_get_peak_usage(true) / 1024 / 1024, 2),
            ],
            'message' => $message,
        ]);

        $this->info("Health check completed: {$status}");

        return self::SUCCESS;
    }
}


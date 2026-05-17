<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ErrorLog;
use App\Models\SystemMonitoringLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Throwable;

class MonitoringController extends Controller
{
    public function summary(): JsonResponse
    {
        return response()->json([
            'audit_logs_today' => AuditLog::whereDate('created_at', today())->count(),
            'errors_today' => ErrorLog::whereDate('created_at', today())->count(),
            'critical_errors_today' => ErrorLog::whereDate('created_at', today())
                ->whereIn('level', ['critical', 'emergency'])
                ->count(),
            'latest_errors' => ErrorLog::latest('created_at')
                ->limit(5)
                ->get([
                    'id',
                    'level',
                    'module',
                    'exception_class',
                    'message',
                    'created_at',
                ]),
            'latest_audit_logs' => AuditLog::latest('created_at')
                ->limit(5)
                ->get([
                    'id',
                    'user_id',
                    'module',
                    'action',
                    'entity_type',
                    'created_at',
                ]),
        ]);
    }

    public function auditLogs(): JsonResponse
    {
        $logs = AuditLog::latest('created_at')
            ->paginate(20);

        return response()->json($logs);
    }

    public function errorLogs(): JsonResponse
    {
        $logs = ErrorLog::latest('created_at')
            ->paginate(20);

        return response()->json($logs);
    }

    public function healthCheck(): JsonResponse
    {
        $startedAt = microtime(true);

        $databaseStatus = 'healthy';
        $databaseMessage = 'Database connection is healthy';

        try {
            DB::select('SELECT 1');
        } catch (Throwable $e) {
            $databaseStatus = 'unhealthy';
            $databaseMessage = $e->getMessage();
        }

        $responseTimeMs = round((microtime(true) - $startedAt) * 1000);

        SystemMonitoringLog::create([
            'service_name' => 'nix-life-os-api',
            'status' => $databaseStatus,
            'response_time_ms' => $responseTimeMs,
            'metrics' => [
                'database' => $databaseStatus,
                'memory_usage_mb' => round(memory_get_usage(true) / 1024 / 1024, 2),
                'memory_peak_mb' => round(memory_get_peak_usage(true) / 1024 / 1024, 2),
            ],
            'message' => $databaseMessage,
        ]);

        return response()->json([
            'service' => 'nix-life-os-api',
            'status' => $databaseStatus,
            'response_time_ms' => $responseTimeMs,
            'database' => $databaseStatus,
            'message' => $databaseMessage,
            'checked_at' => now(),
        ], $databaseStatus === 'healthy' ? 200 : 500);
    }

    public function monitoringLogs(): JsonResponse
    {
        $logs = SystemMonitoringLog::latest('checked_at')
            ->paginate(20);

        return response()->json($logs);
    }
}

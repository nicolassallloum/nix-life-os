🔹 STEP 25 — Logging & Monitoring
NIX LIFE OS — Laravel + PostgreSQL + Vue

This step adds:

Audit logs: Track user actions like create/update/delete/login/API actions.
Error tracking: Store backend exceptions/errors in database.
Monitoring system: Health checks, API status, system summary, and admin UI.
✅ STEP 25.1 — Backend Database Tables

Run:

cd /u01/nix-life-os/backend

php artisan make:migration create_audit_logs_table
php artisan make:migration create_error_logs_table
php artisan make:migration create_system_monitoring_logs_table
1. Migration: audit_logs

Open:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_audit_logs_table.php

Paste:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->nullable();

            $table->string('module')->nullable();
            $table->string('action');
            $table->string('entity_type')->nullable();
            $table->uuid('entity_id')->nullable();

            $table->jsonb('old_values')->nullable();
            $table->jsonb('new_values')->nullable();
            $table->jsonb('metadata')->nullable();

            $table->string('ip_address')->nullable();
            $table->string('user_agent')->nullable();

            $table->timestamp('created_at')->useCurrent();

            $table->index('user_id');
            $table->index('module');
            $table->index('action');
            $table->index('entity_type');
            $table->index('created_at');
        });

        DB::statement('ALTER TABLE audit_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()');
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
2. Migration: error_logs

Open:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_error_logs_table.php

Paste:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('error_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->nullable();

            $table->string('level')->default('error');
            $table->string('module')->nullable();
            $table->string('exception_class')->nullable();

            $table->text('message');
            $table->text('file')->nullable();
            $table->integer('line')->nullable();

            $table->string('request_method')->nullable();
            $table->text('request_url')->nullable();
            $table->jsonb('request_payload')->nullable();

            $table->text('trace')->nullable();
            $table->jsonb('metadata')->nullable();

            $table->string('ip_address')->nullable();
            $table->string('user_agent')->nullable();

            $table->timestamp('created_at')->useCurrent();

            $table->index('user_id');
            $table->index('level');
            $table->index('module');
            $table->index('exception_class');
            $table->index('created_at');
        });

        DB::statement('ALTER TABLE error_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()');
    }

    public function down(): void
    {
        Schema::dropIfExists('error_logs');
    }
};
3. Migration: system_monitoring_logs

Open:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_system_monitoring_logs_table.php

Paste:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_monitoring_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('service_name');
            $table->string('status')->default('healthy');

            $table->integer('response_time_ms')->nullable();
            $table->jsonb('metrics')->nullable();
            $table->text('message')->nullable();

            $table->timestamp('checked_at')->useCurrent();

            $table->index('service_name');
            $table->index('status');
            $table->index('checked_at');
        });

        DB::statement('ALTER TABLE system_monitoring_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()');
    }

    public function down(): void
    {
        Schema::dropIfExists('system_monitoring_logs');
    }
};
Run migrations
php artisan migrate
✅ STEP 25.2 — Create Models

Run:

php artisan make:model AuditLog
php artisan make:model ErrorLog
php artisan make:model SystemMonitoringLog
1. app/Models/AuditLog.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AuditLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'module',
        'action',
        'entity_type',
        'entity_id',
        'old_values',
        'new_values',
        'metadata',
        'ip_address',
        'user_agent',
        'created_at',
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];
}
2. app/Models/ErrorLog.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ErrorLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'level',
        'module',
        'exception_class',
        'message',
        'file',
        'line',
        'request_method',
        'request_url',
        'request_payload',
        'trace',
        'metadata',
        'ip_address',
        'user_agent',
        'created_at',
    ];

    protected $casts = [
        'request_payload' => 'array',
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];
}
3. app/Models/SystemMonitoringLog.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class SystemMonitoringLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'service_name',
        'status',
        'response_time_ms',
        'metrics',
        'message',
        'checked_at',
    ];

    protected $casts = [
        'metrics' => 'array',
        'checked_at' => 'datetime',
    ];
}
✅ STEP 25.3 — Create Logging Service

Run:

mkdir -p app/Services/Monitoring
nano app/Services/Monitoring/LoggingService.php

Paste:

<?php

namespace App\Services\Monitoring;

use App\Models\AuditLog;
use App\Models\ErrorLog;
use Throwable;

class LoggingService
{
    public static function audit(
        string $action,
        ?string $module = null,
        ?string $entityType = null,
        ?string $entityId = null,
        ?array $oldValues = null,
        ?array $newValues = null,
        ?array $metadata = null
    ): void {
        try {
            AuditLog::create([
                'user_id' => auth()->id(),
                'module' => $module,
                'action' => $action,
                'entity_type' => $entityType,
                'entity_id' => $entityId,
                'old_values' => $oldValues,
                'new_values' => $newValues,
                'metadata' => $metadata,
                'ip_address' => request()?->ip(),
                'user_agent' => request()?->userAgent(),
            ]);
        } catch (Throwable $e) {
            logger()->error('Audit logging failed', [
                'message' => $e->getMessage(),
            ]);
        }
    }

    public static function error(Throwable $exception, ?string $module = null, ?array $metadata = null): void
    {
        try {
            ErrorLog::create([
                'user_id' => auth()->id(),
                'level' => 'error',
                'module' => $module,
                'exception_class' => get_class($exception),
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
                'request_method' => request()?->method(),
                'request_url' => request()?->fullUrl(),
                'request_payload' => self::safePayload(),
                'trace' => substr($exception->getTraceAsString(), 0, 8000),
                'metadata' => $metadata,
                'ip_address' => request()?->ip(),
                'user_agent' => request()?->userAgent(),
            ]);
        } catch (Throwable $e) {
            logger()->error('Error logging failed', [
                'message' => $e->getMessage(),
            ]);
        }
    }

    private static function safePayload(): array
    {
        $payload = request()?->except([
            'password',
            'password_confirmation',
            'current_password',
            'token',
            'access_token',
            'refresh_token',
        ]);

        return $payload ?? [];
    }
}
✅ STEP 25.4 — Add Automatic API Audit Middleware

Run:

php artisan make:middleware ApiAuditLogger

Open:

nano app/Http/Middleware/ApiAuditLogger.php

Paste:

<?php

namespace App\Http\Middleware;

use App\Services\Monitoring\LoggingService;
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
                    'query' => $request->query(),
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
✅ STEP 25.5 — Register Middleware

Open:

nano bootstrap/app.php

Find the middleware section and add alias:

use App\Http\Middleware\ApiAuditLogger;

Inside:

->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'api.audit' => ApiAuditLogger::class,
    ]);
})

Example:

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use App\Http\Middleware\ApiAuditLogger;

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
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
✅ STEP 25.6 — Add Global Error Tracking

Open:

nano bootstrap/app.php

Update the exceptions section:

use App\Services\Monitoring\LoggingService;
use Throwable;

Then:

->withExceptions(function (Exceptions $exceptions) {
    $exceptions->report(function (Throwable $e) {
        LoggingService::error($e, 'global_exception_handler');
    });
})

Full important part:

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use App\Http\Middleware\ApiAuditLogger;
use App\Services\Monitoring\LoggingService;
use Throwable;

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
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->report(function (Throwable $e) {
            LoggingService::error($e, 'global_exception_handler');
        });
    })->create();
✅ STEP 25.7 — Create Monitoring Controller

Run:

php artisan make:controller Api/V1/MonitoringController

Open:

nano app/Http/Controllers/Api/V1/MonitoringController.php

Paste:

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
✅ STEP 25.8 — Update routes/api.php

Open:

nano routes/api.php

Add this import:

use App\Http\Controllers\Api\V1\MonitoringController;

Inside your authenticated API group, add:

Route::prefix('v1')->middleware(['auth:sanctum', 'api.audit'])->group(function () {

    Route::prefix('monitoring')->group(function () {
        Route::get('/summary', [MonitoringController::class, 'summary']);
        Route::get('/audit-logs', [MonitoringController::class, 'auditLogs']);
        Route::get('/error-logs', [MonitoringController::class, 'errorLogs']);
        Route::get('/health-check', [MonitoringController::class, 'healthCheck']);
        Route::get('/system-logs', [MonitoringController::class, 'monitoringLogs']);
    });

});

If you already have this:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {

Change it to:

Route::prefix('v1')->middleware(['auth:sanctum', 'api.audit'])->group(function () {
✅ STEP 25.9 — Test Backend APIs

Use your token:

TOKEN="YOUR_TOKEN_HERE"
1. Health check
curl http://127.0.0.1:8000/api/v1/monitoring/health-check \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

Expected result:

{
  "service": "nix-life-os-api",
  "status": "healthy",
  "response_time_ms": 12,
  "database": "healthy",
  "message": "Database connection is healthy",
  "checked_at": "2026-04-30T..."
}
2. Monitoring summary
curl http://127.0.0.1:8000/api/v1/monitoring/summary \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
3. Audit logs
curl http://127.0.0.1:8000/api/v1/monitoring/audit-logs \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
4. Error logs
curl http://127.0.0.1:8000/api/v1/monitoring/error-logs \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
✅ STEP 25.10 — Add Manual Audit Logging Example

Example inside any controller, such as creating a project:

use App\Services\Monitoring\LoggingService;

LoggingService::audit(
    action: 'project_created',
    module: 'projects',
    entityType: 'project',
    entityId: $project->id,
    oldValues: null,
    newValues: $project->toArray(),
    metadata: [
        'source' => 'project_controller',
    ]
);

Example for update:

$oldValues = $project->toArray();

$project->update($validated);

LoggingService::audit(
    action: 'project_updated',
    module: 'projects',
    entityType: 'project',
    entityId: $project->id,
    oldValues: $oldValues,
    newValues: $project->fresh()->toArray()
);
✅ STEP 25.11 — Frontend Monitoring Page

Go to frontend:

cd /u01/nix-life-os/frontend

Create page:

mkdir -p src/views/monitoring
nano src/views/monitoring/MonitoringDashboardView.vue

Paste:

<script setup>
import { ref, onMounted } from "vue";

const API_BASE_URL = "http://127.0.0.1:8000/api/v1";

const token = localStorage.getItem("token");

const summary = ref(null);
const health = ref(null);
const auditLogs = ref([]);
const errorLogs = ref([]);
const loading = ref(true);
const error = ref(null);

async function apiGet(endpoint) {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }

  return await response.json();
}

async function loadMonitoringData() {
  loading.value = true;
  error.value = null;

  try {
    health.value = await apiGet("/monitoring/health-check");
    summary.value = await apiGet("/monitoring/summary");

    const auditResponse = await apiGet("/monitoring/audit-logs");
    auditLogs.value = auditResponse.data || [];

    const errorResponse = await apiGet("/monitoring/error-logs");
    errorLogs.value = errorResponse.data || [];
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadMonitoringData();
});
</script>

<template>
  <div class="p-8 space-y-8">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          Logging & Monitoring
        </h1>
        <p class="text-gray-500 mt-1">
          Audit logs, error tracking, and system health monitoring.
        </p>
      </div>

      <button
        @click="loadMonitoringData"
        class="px-5 py-2 rounded-xl bg-gray-900 text-white hover:bg-gray-700"
      >
        Refresh
      </button>
    </div>

    <div v-if="loading" class="text-gray-500">
      Loading monitoring data...
    </div>

    <div v-if="error" class="p-4 bg-red-50 text-red-700 rounded-xl">
      {{ error }}
    </div>

    <div v-if="!loading && !error" class="space-y-8">
      <!-- KPI Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-5">
        <div class="bg-white rounded-2xl shadow p-5 border">
          <p class="text-sm text-gray-500">System Status</p>
          <h2
            class="text-2xl font-bold mt-2"
            :class="health?.status === 'healthy' ? 'text-green-600' : 'text-red-600'"
          >
            {{ health?.status }}
          </h2>
        </div>

        <div class="bg-white rounded-2xl shadow p-5 border">
          <p class="text-sm text-gray-500">Response Time</p>
          <h2 class="text-2xl font-bold mt-2">
            {{ health?.response_time_ms }} ms
          </h2>
        </div>

        <div class="bg-white rounded-2xl shadow p-5 border">
          <p class="text-sm text-gray-500">Audit Logs Today</p>
          <h2 class="text-2xl font-bold mt-2">
            {{ summary?.audit_logs_today }}
          </h2>
        </div>

        <div class="bg-white rounded-2xl shadow p-5 border">
          <p class="text-sm text-gray-500">Errors Today</p>
          <h2 class="text-2xl font-bold mt-2 text-red-600">
            {{ summary?.errors_today }}
          </h2>
        </div>
      </div>

      <!-- Latest Errors -->
      <div class="bg-white rounded-2xl shadow border">
        <div class="p-5 border-b">
          <h2 class="text-xl font-bold text-gray-900">
            Latest Error Logs
          </h2>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead class="bg-gray-50 text-gray-600">
              <tr>
                <th class="text-left p-4">Date</th>
                <th class="text-left p-4">Module</th>
                <th class="text-left p-4">Exception</th>
                <th class="text-left p-4">Message</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="log in errorLogs"
                :key="log.id"
                class="border-t hover:bg-gray-50"
              >
                <td class="p-4">{{ log.created_at }}</td>
                <td class="p-4">{{ log.module || "-" }}</td>
                <td class="p-4">{{ log.exception_class || "-" }}</td>
                <td class="p-4 text-red-600">{{ log.message }}</td>
              </tr>

              <tr v-if="errorLogs.length === 0">
                <td colspan="4" class="p-4 text-center text-gray-500">
                  No errors found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Audit Logs -->
      <div class="bg-white rounded-2xl shadow border">
        <div class="p-5 border-b">
          <h2 class="text-xl font-bold text-gray-900">
            Latest Audit Logs
          </h2>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead class="bg-gray-50 text-gray-600">
              <tr>
                <th class="text-left p-4">Date</th>
                <th class="text-left p-4">Module</th>
                <th class="text-left p-4">Action</th>
                <th class="text-left p-4">Entity</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="log in auditLogs"
                :key="log.id"
                class="border-t hover:bg-gray-50"
              >
                <td class="p-4">{{ log.created_at }}</td>
                <td class="p-4">{{ log.module || "-" }}</td>
                <td class="p-4">{{ log.action }}</td>
                <td class="p-4">{{ log.entity_type || "-" }}</td>
              </tr>

              <tr v-if="auditLogs.length === 0">
                <td colspan="4" class="p-4 text-center text-gray-500">
                  No audit logs found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
✅ STEP 25.12 — Add Frontend Route

Open:

nano src/router/index.js

Add import:

import MonitoringDashboardView from "../views/monitoring/MonitoringDashboardView.vue";

Add route:

{
  path: "/monitoring",
  name: "monitoring",
  component: MonitoringDashboardView,
}

Example:

import { createRouter, createWebHistory } from "vue-router";
import MonitoringDashboardView from "../views/monitoring/MonitoringDashboardView.vue";

const routes = [
  {
    path: "/monitoring",
    name: "monitoring",
    component: MonitoringDashboardView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

If your file already has routes, only add the import and route item.

✅ STEP 25.13 — Add Sidebar Menu Link

Open your main layout file, probably:

nano src/App.vue

Add this inside your sidebar navigation:

<RouterLink
  to="/monitoring"
  class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
>
  Logging & Monitoring
</RouterLink>

Recommended sidebar section:

<div class="mt-6">
  <p class="text-xs font-semibold text-gray-400 uppercase mb-2">
    System
  </p>

  <RouterLink
    to="/monitoring"
    class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
  >
    Logging & Monitoring
  </RouterLink>
</div>
✅ STEP 25.14 — Start Servers

Backend:

cd /u01/nix-life-os/backend
php artisan serve

Frontend:

cd /u01/nix-life-os/frontend
npm run dev -- --host 0.0.0.0

Open:

http://127.0.0.1:5173/monitoring
✅ STEP 25.15 — Useful PostgreSQL Checks

Connect to database:

psql -U postgres -d nixlifeos_db

Check tables:

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'audit_logs',
    'error_logs',
    'system_monitoring_logs'
);

Check audit logs:

SELECT id, user_id, module, action, entity_type, created_at
FROM audit_logs
ORDER BY created_at DESC
LIMIT 10;

Check error logs:

SELECT id, level, module, exception_class, message, created_at
FROM error_logs
ORDER BY created_at DESC
LIMIT 10;

Check monitoring logs:

SELECT id, service_name, status, response_time_ms, checked_at
FROM system_monitoring_logs
ORDER BY checked_at DESC
LIMIT 10;
✅ STEP 25.16 — Optional Scheduled Health Monitoring

Create command:

php artisan make:command RunSystemHealthCheck

Open:

nano app/Console/Commands/RunSystemHealthCheck.php

Paste:

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

Test:

php artisan system:health-check

Add to scheduler in routes/console.php:

use Illuminate\Support\Facades\Schedule;

Schedule::command('system:health-check')->everyFifteenMinutes();

Check schedule:

php artisan schedule:list
✅ STEP 25.17 — Recommended Permissions

Since this is sensitive system data, later you should protect it with roles.

Example permission names:

monitoring.view
audit_logs.view
error_logs.view
system_logs.view

Recommended access:

Role	Access
admin	Full access
manager	Summary only
user	No access

Later you can add this in your Spatie permission seeder.

✅ Final Result

After Step 25, your system now has:

Feature	Status
Audit log table	✅ Done
Error log table	✅ Done
Monitoring log table	✅ Done
Global error tracking	✅ Done
API audit middleware	✅ Done
Health check endpoint	✅ Done
Monitoring summary endpoint	✅ Done
Audit log API	✅ Done
Error log API	✅ Done
Vue monitoring dashboard	✅ Done
Scheduled health check	✅ Optional done

Step 25 is now your enterprise observability layer for NIX LIFE OS.
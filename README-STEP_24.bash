🔹 STEP 24 — API Optimization
NIX LIFE OS — Laravel + PostgreSQL + Redis Performance Optimization
1. Goal of Step 24

In this step, we optimize the backend APIs for better speed, scalability, and production readiness.

We will improve:

1. API response speed
2. Database query performance
3. Dashboard loading time
4. Expensive analytics endpoints
5. Repeated API calls
6. PostgreSQL indexes
7. Laravel cache usage
8. Redis integration
9. API pagination
10. Performance monitoring
2. Install Redis Support in Laravel

From your backend folder:

cd /u01/nix-life-os/backend

Install PHP Redis package:

composer require predis/predis

Then update your .env file.

3. Update .env

Open:

nano .env

Add or update these values:

CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=database

REDIS_CLIENT=predis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

API_CACHE_TTL=300

API_CACHE_TTL=300 means cached API results expire after 5 minutes.

Then clear config:

php artisan config:clear
php artisan cache:clear
php artisan optimize:clear
4. Install Redis Server

On Ubuntu / WSL:

sudo apt update
sudo apt install redis-server -y

Start Redis:

sudo service redis-server start

Test Redis:

redis-cli ping

Expected result:

PONG
5. Create API Cache Helper Service

Create this file:

mkdir -p app/Services/Performance
nano app/Services/Performance/ApiCacheService.php

Paste:

<?php

namespace App\Services\Performance;

use Illuminate\Support\Facades\Cache;

class ApiCacheService
{
    public static function remember(string $key, callable $callback, ?int $ttl = null)
    {
        $ttl = $ttl ?? (int) env('API_CACHE_TTL', 300);

        return Cache::remember($key, $ttl, $callback);
    }

    public static function forget(string $key): void
    {
        Cache::forget($key);
    }

    public static function forgetByUser(string $prefix, string $userId): void
    {
        Cache::forget($prefix . ':' . $userId);
    }

    public static function userKey(string $module, string $userId, array $params = []): string
    {
        ksort($params);

        return $module . ':' . $userId . ':' . md5(json_encode($params));
    }
}
6. Optimize Unified Dashboard Summary API

Your dashboard summary endpoint is a perfect place for caching because it combines Finance + Health + Projects data.

Example controller update:

nano app/Http/Controllers/Api/V1/Dashboard/DashboardController.php

Use this structure:

<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use App\Services\Performance\ApiCacheService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();

        $cacheKey = ApiCacheService::userKey('dashboard_summary', $user->id, [
            'date' => now()->toDateString(),
        ]);

        $data = ApiCacheService::remember($cacheKey, function () use ($user) {
            return [
                'finance' => $this->financeSummary($user->id),
                'health' => $this->healthSummary($user->id),
                'projects' => $this->projectSummary($user->id),
                'generated_at' => now()->toDateTimeString(),
            ];
        }, 300);

        return response()->json([
            'status' => true,
            'message' => 'Dashboard summary loaded successfully.',
            'data' => $data,
        ]);
    }

    private function financeSummary(string $userId): array
    {
        return [
            'accounts_count' => DB::table('finance_accounts')
                ->where('user_id', $userId)
                ->count(),

            'total_balance' => DB::table('finance_accounts')
                ->where('user_id', $userId)
                ->sum('current_balance'),

            'monthly_income' => DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'income')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount'),

            'monthly_expense' => DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'expense')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount'),
        ];
    }

    private function healthSummary(string $userId): array
    {
        return [
            'latest_weight' => DB::table('health_weight_logs')
                ->where('user_id', $userId)
                ->orderByDesc('log_date')
                ->value('weight_kg'),

            'today_steps' => DB::table('health_step_logs')
                ->where('user_id', $userId)
                ->whereDate('log_date', now()->toDateString())
                ->sum('steps'),

            'today_water_ml' => DB::table('health_hydration_logs')
                ->where('user_id', $userId)
                ->whereDate('drink_date', now()->toDateString())
                ->sum('amount_ml'),
        ];
    }

    private function projectSummary(string $userId): array
    {
        return [
            'active_projects' => DB::table('projects')
                ->where('user_id', $userId)
                ->where('status', 'in_progress')
                ->count(),

            'completed_tasks' => DB::table('project_tasks')
                ->where('user_id', $userId)
                ->where('status', 'completed')
                ->count(),

            'pending_tasks' => DB::table('project_tasks')
                ->where('user_id', $userId)
                ->whereIn('status', ['pending', 'todo', 'in_progress'])
                ->count(),
        ];
    }
}
7. Important Note About Your Table Names

If your real tables use schema-qualified names like:

nix_life_os.finance_accounts
nix_life_os.finance_transactions
nix_life_os.health_weight_logs

Then update queries like this:

DB::table('nix_life_os.finance_accounts')

instead of:

DB::table('finance_accounts')

Use your actual table names from PostgreSQL.

8. Add Cache Clearing After Create / Update / Delete

Whenever you create, update, or delete Finance, Health, or Project data, clear the related dashboard cache.

Example inside a controller after storing a transaction:

use App\Services\Performance\ApiCacheService;

ApiCacheService::forget(
    ApiCacheService::userKey('dashboard_summary', auth()->id(), [
        'date' => now()->toDateString(),
    ])
);

Example:

public function store(Request $request)
{
    $transaction = FinanceTransaction::create([
        'user_id' => $request->user()->id,
        'amount' => $request->amount,
        'transaction_type' => $request->transaction_type,
        'transaction_date' => $request->transaction_date,
        'description' => $request->description,
    ]);

    ApiCacheService::forget(
        ApiCacheService::userKey('dashboard_summary', $request->user()->id, [
            'date' => now()->toDateString(),
        ])
    );

    return response()->json([
        'status' => true,
        'message' => 'Transaction created successfully.',
        'data' => $transaction,
    ], 201);
}
9. Add Pagination to Heavy APIs

For large APIs, never return all records.

Bad:

FinanceTransaction::where('user_id', auth()->id())->get();

Good:

FinanceTransaction::where('user_id', auth()->id())
    ->orderByDesc('transaction_date')
    ->paginate(25);

Example response:

return response()->json([
    'status' => true,
    'message' => 'Transactions loaded successfully.',
    'data' => $transactions,
]);
10. Optimized Finance Transaction Query

Example:

public function index(Request $request)
{
    $user = $request->user();

    $query = DB::table('finance_transactions')
        ->where('user_id', $user->id);

    if ($request->filled('transaction_type')) {
        $query->where('transaction_type', $request->transaction_type);
    }

    if ($request->filled('category_id')) {
        $query->where('category_id', $request->category_id);
    }

    if ($request->filled('date_from')) {
        $query->whereDate('transaction_date', '>=', $request->date_from);
    }

    if ($request->filled('date_to')) {
        $query->whereDate('transaction_date', '<=', $request->date_to);
    }

    $transactions = $query
        ->orderByDesc('transaction_date')
        ->paginate($request->get('per_page', 25));

    return response()->json([
        'status' => true,
        'message' => 'Finance transactions loaded successfully.',
        'data' => $transactions,
    ]);
}
11. PostgreSQL Index Optimization

Create migration:

php artisan make:migration add_performance_indexes_to_nix_life_os_tables

Open the migration:

nano database/migrations/xxxx_xx_xx_xxxxxx_add_performance_indexes_to_nix_life_os_tables.php

Paste:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Finance Indexes
        |--------------------------------------------------------------------------
        */

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_date
            ON finance_transactions (user_id, transaction_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_type_date
            ON finance_transactions (user_id, transaction_type, transaction_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_category
            ON finance_transactions (user_id, category_id)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_accounts_user
            ON finance_accounts (user_id)
        ");

        /*
        |--------------------------------------------------------------------------
        | Health Indexes
        |--------------------------------------------------------------------------
        */

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_weight_logs_user_date
            ON health_weight_logs (user_id, log_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_step_logs_user_date
            ON health_step_logs (user_id, log_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_user_date
            ON health_hydration_logs (user_id, drink_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_meal_logs_user_date
            ON health_meal_logs (user_id, meal_date DESC)
        ");

        /*
        |--------------------------------------------------------------------------
        | Project Indexes
        |--------------------------------------------------------------------------
        */

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_projects_user_status
            ON projects (user_id, status)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_project_tasks_user_status
            ON project_tasks (user_id, status)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_project_tasks_project_status
            ON project_tasks (project_id, status)
        ");

        /*
        |--------------------------------------------------------------------------
        | Notification Indexes
        |--------------------------------------------------------------------------
        */

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_notifications_user_read_created
            ON notifications (user_id, is_read, created_at DESC)
        ");

        /*
        |--------------------------------------------------------------------------
        | Automation Indexes
        |--------------------------------------------------------------------------
        */

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_automation_rules_user_active
            ON automation_rules (user_id, is_active)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_automation_logs_user_created
            ON automation_logs (user_id, created_at DESC)
        ");
    }

    public function down(): void
    {
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_type_date");
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_category");
        DB::statement("DROP INDEX IF EXISTS idx_finance_accounts_user");

        DB::statement("DROP INDEX IF EXISTS idx_health_weight_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_step_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_hydration_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_meal_logs_user_date");

        DB::statement("DROP INDEX IF EXISTS idx_projects_user_status");
        DB::statement("DROP INDEX IF EXISTS idx_project_tasks_user_status");
        DB::statement("DROP INDEX IF EXISTS idx_project_tasks_project_status");

        DB::statement("DROP INDEX IF EXISTS idx_notifications_user_read_created");

        DB::statement("DROP INDEX IF EXISTS idx_automation_rules_user_active");
        DB::statement("DROP INDEX IF EXISTS idx_automation_logs_user_created");
    }
};

Run migration:

php artisan migrate
12. If You Use Schema nix_life_os

If your tables are inside the nix_life_os schema, use this version instead:

DB::statement("
    CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_date
    ON nix_life_os.finance_transactions (user_id, transaction_date DESC)
");

So the table name becomes:

nix_life_os.table_name

Example:

nix_life_os.finance_transactions
nix_life_os.health_step_logs
nix_life_os.projects
13. Add API Performance Middleware

Create middleware:

php artisan make:middleware ApiPerformanceLogger

Open:

nano app/Http/Middleware/ApiPerformanceLogger.php

Paste:

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
14. Register Middleware in Laravel 11 / 12

Open:

nano bootstrap/app.php

Find:

->withMiddleware(function (Middleware $middleware) {
    //
})

Update it like this:

use App\Http\Middleware\ApiPerformanceLogger;

->withMiddleware(function (Middleware $middleware) {
    $middleware->api(append: [
        ApiPerformanceLogger::class,
    ]);
})

Full example section:

use App\Http\Middleware\ApiPerformanceLogger;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->api(append: [
            ApiPerformanceLogger::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
15. Add Optimized Dashboard Route

Open:

nano routes/api.php

Add inside your authenticated API group:

use App\Http\Controllers\Api\V1\Dashboard\DashboardController;

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/dashboard/summary', [DashboardController::class, 'summary']);
});
16. Full Example routes/api.php Section

Use this structure if needed:

<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\Dashboard\DashboardController;

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Dashboard
    |--------------------------------------------------------------------------
    */

    Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

    /*
    |--------------------------------------------------------------------------
    | Other Existing Routes
    |--------------------------------------------------------------------------
    */

    // Finance routes
    // Health routes
    // Project routes
    // Notification routes
    // Automation routes
});
17. Test the Optimized API

Use your token:

TOKEN="YOUR_TOKEN_HERE"

Then test:

curl -i http://127.0.0.1:8000/api/v1/dashboard/summary \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

You should see a header like:

X-Response-Time-ms: 120.34

Call the same API again.

The second call should be faster because Redis cache is used.

18. Check Redis Keys

Run:

redis-cli

Then:

KEYS *

You should see Laravel cache keys.

Exit:

exit
19. Clear Redis Cache Manually
php artisan cache:clear

Or:

redis-cli FLUSHDB

Use FLUSHDB carefully because it clears the selected Redis database.

20. Query Optimization Rules for NIX LIFE OS

Use these rules in all controllers:

Rule 1 — Always filter by user_id
->where('user_id', $request->user()->id)
Rule 2 — Use pagination
->paginate(25)
Rule 3 — Avoid SELECT * for heavy APIs

Instead of:

DB::table('finance_transactions')->get();

Use:

DB::table('finance_transactions')
    ->select('id', 'amount', 'transaction_type', 'transaction_date', 'description')
    ->get();
Rule 4 — Avoid loading relationships unnecessarily

Bad:

Project::with('tasks')->get();

Better:

Project::withCount('tasks')->get();
Rule 5 — Use aggregate SQL for dashboards

Bad:

$transactions = FinanceTransaction::where('user_id', $userId)->get();
$total = $transactions->sum('amount');

Good:

$total = FinanceTransaction::where('user_id', $userId)->sum('amount');
21. Optimized Project Dashboard Query

Example:

$projects = DB::table('projects')
    ->select(
        'projects.id',
        'projects.project_name',
        'projects.status',
        'projects.priority',
        'projects.progress_percentage',
        DB::raw('COUNT(project_tasks.id) as tasks_count'),
        DB::raw("SUM(CASE WHEN project_tasks.status = 'completed' THEN 1 ELSE 0 END) as completed_tasks")
    )
    ->leftJoin('project_tasks', 'project_tasks.project_id', '=', 'projects.id')
    ->where('projects.user_id', $userId)
    ->groupBy(
        'projects.id',
        'projects.project_name',
        'projects.status',
        'projects.priority',
        'projects.progress_percentage'
    )
    ->orderByDesc('projects.created_at')
    ->paginate(20);
22. Optimized Health Analytics Query

Example:

$healthDaily = DB::table('health_step_logs')
    ->select(
        'log_date',
        DB::raw('SUM(steps) as total_steps'),
        DB::raw('SUM(calories_burned) as total_calories_burned')
    )
    ->where('user_id', $userId)
    ->whereBetween('log_date', [$startDate, $endDate])
    ->groupBy('log_date')
    ->orderBy('log_date')
    ->get();
23. Add Response Compression on Web Server

If using Nginx later, enable gzip:

gzip on;
gzip_types text/plain application/json application/javascript text/css;
gzip_min_length 1024;

This reduces API response size.

24. Add Laravel Production Optimization Commands

For production or stable testing:

php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

To clear:

php artisan optimize:clear

During development, use:

php artisan optimize:clear
25. Add Performance Test Commands

Install Apache benchmark:

sudo apt install apache2-utils -y

Test dashboard API:

ab -n 100 -c 10 \
-H "Authorization: Bearer $TOKEN" \
-H "Accept: application/json" \
http://127.0.0.1:8000/api/v1/dashboard/summary

Meaning:

-n 100 = total 100 requests
-c 10  = 10 concurrent users

Look for:

Requests per second
Time per request
Failed requests
26. Add Laravel Query Debug for Development

Temporarily add this to a controller when debugging:

DB::enableQueryLog();

// Your query here

dd(DB::getQueryLog());

Do not keep this in production.

27. Recommended API Cache Strategy
API	Cache?	TTL
Dashboard Summary	Yes	5 minutes
Life Balance Index	Yes	5–10 minutes
AI Insights	Yes	10–30 minutes
Finance Transactions List	Optional	1–3 minutes
Health Daily Analytics	Yes	5 minutes
Project Dashboard	Yes	5 minutes
Notifications Unread Count	Yes	1 minute
Automation Logs	Optional	1–3 minutes
Create / Update / Delete APIs	No	Clear related cache
28. Final Step 24 Checklist
✅ Redis installed
✅ Laravel Redis configured
✅ API cache service created
✅ Dashboard summary cached
✅ Heavy APIs paginated
✅ PostgreSQL indexes added
✅ Slow API logger middleware added
✅ X-Response-Time-ms header added
✅ Cache cleared after data changes
✅ API tested with curl
✅ Redis keys verified
✅ Performance benchmark tested
29. Recommended Next Step

After Step 24, continue with:

🔹 STEP 25 — Security Hardening
- API rate limiting
- Role-based access protection
- Audit logs
- Input validation
- Secure headers
- Sensitive data protection
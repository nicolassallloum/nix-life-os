🔹 STEP 22 — Automation Engine
Behavior-Based Triggers + Smart Reminders
Stack: Laravel + PostgreSQL
Depends on: Step 21 Notification System
This step builds an Automation Engine that watches user behavior and automatically creates notifications/reminders.
Examples:
BehaviorAutomation ResultNo weight log todayReminder to log weightNo water logged by eveningHydration reminderExpenses exceed budget warningFinance alertProject task due todayProductivity reminderNo meal loggedMeal reminderDaily review time reachedSmart daily summary reminder

1. Create Automation Tables
Run:
cd /u01/nix-life-os/backendphp artisan make:migration create_automation_rules_tablephp artisan make:migration create_automation_trigger_logs_table

1.1 Migration: automation_rules
Open the migration file:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_automation_rules_table.php
Paste:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('automation_rules', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->foreignUuid('user_id')                ->constrained('users')                ->cascadeOnDelete();            $table->string('rule_name');            $table->string('module');             // health, finance, projects, productivity, system            $table->string('trigger_type');            // missing_log, threshold_exceeded, due_today, inactive_period, scheduled_time            $table->jsonb('conditions')->nullable();            /*                Example:                {                    "metric": "water_ml",                    "operator": "<",                    "value": 1500,                    "time": "18:00"                }            */            $table->string('action_type')->default('create_notification');            // create_notification, create_alert, create_reminder            $table->jsonb('action_payload')->nullable();            /*                Example:                {                    "title": "Hydration Reminder",                    "message": "You have not reached your water goal today.",                    "notification_type": "reminder",                    "priority": "medium"                }            */            $table->boolean('is_active')->default(true);            $table->timestamp('last_triggered_at')->nullable();            $table->timestamps();            $table->index(['user_id', 'module']);            $table->index(['user_id', 'trigger_type']);            $table->index(['user_id', 'is_active']);        });    }    public function down(): void    {        Schema::dropIfExists('automation_rules');    }};

1.2 Migration: automation_trigger_logs
Open:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_automation_trigger_logs_table.php
Paste:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('automation_trigger_logs', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->foreignUuid('automation_rule_id')                ->constrained('automation_rules')                ->cascadeOnDelete();            $table->foreignUuid('user_id')                ->constrained('users')                ->cascadeOnDelete();            $table->string('status')->default('triggered');            // triggered, skipped, failed            $table->jsonb('evaluated_data')->nullable();            $table->text('message')->nullable();            $table->timestamps();            $table->index(['automation_rule_id']);            $table->index(['user_id']);            $table->index(['status']);        });    }    public function down(): void    {        Schema::dropIfExists('automation_trigger_logs');    }};
Run:
php artisan migrate

2. Create Models
Run:
php artisan make:model AutomationRulephp artisan make:model AutomationTriggerLog

2.1 app/Models/AutomationRule.php
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Concerns\HasUuids;use Illuminate\Database\Eloquent\Model;class AutomationRule extends Model{    use HasUuids;    protected $fillable = [        'user_id',        'rule_name',        'module',        'trigger_type',        'conditions',        'action_type',        'action_payload',        'is_active',        'last_triggered_at',    ];    protected $casts = [        'conditions' => 'array',        'action_payload' => 'array',        'is_active' => 'boolean',        'last_triggered_at' => 'datetime',    ];    public function logs()    {        return $this->hasMany(AutomationTriggerLog::class);    }}

2.2 app/Models/AutomationTriggerLog.php
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Concerns\HasUuids;use Illuminate\Database\Eloquent\Model;class AutomationTriggerLog extends Model{    use HasUuids;    protected $fillable = [        'automation_rule_id',        'user_id',        'status',        'evaluated_data',        'message',    ];    protected $casts = [        'evaluated_data' => 'array',    ];    public function rule()    {        return $this->belongsTo(AutomationRule::class, 'automation_rule_id');    }}

3. Create Automation Service
Run:
mkdir -p app/Servicesnano app/Services/AutomationEngineService.php
Paste:
<?phpnamespace App\Services;use App\Models\AutomationRule;use App\Models\AutomationTriggerLog;use App\Models\Notification;use Illuminate\Support\Facades\DB;use Illuminate\Support\Facades\Log;class AutomationEngineService{    public function runForUser(string $userId): array    {        $rules = AutomationRule::query()            ->where('user_id', $userId)            ->where('is_active', true)            ->get();        $results = [];        foreach ($rules as $rule) {            try {                $result = $this->evaluateRule($rule);                $results[] = $result;            } catch (\Throwable $e) {                Log::error('Automation rule failed', [                    'rule_id' => $rule->id,                    'error' => $e->getMessage(),                ]);                AutomationTriggerLog::create([                    'automation_rule_id' => $rule->id,                    'user_id' => $rule->user_id,                    'status' => 'failed',                    'evaluated_data' => [                        'error' => $e->getMessage(),                    ],                    'message' => 'Automation failed.',                ]);                $results[] = [                    'rule_id' => $rule->id,                    'status' => 'failed',                    'message' => $e->getMessage(),                ];            }        }        return $results;    }    public function evaluateRule(AutomationRule $rule): array    {        $shouldTrigger = false;        $evaluatedData = [];        switch ($rule->trigger_type) {            case 'missing_log':                [$shouldTrigger, $evaluatedData] = $this->evaluateMissingLog($rule);                break;            case 'threshold_exceeded':                [$shouldTrigger, $evaluatedData] = $this->evaluateThresholdExceeded($rule);                break;            case 'due_today':                [$shouldTrigger, $evaluatedData] = $this->evaluateDueToday($rule);                break;            case 'scheduled_time':                [$shouldTrigger, $evaluatedData] = $this->evaluateScheduledTime($rule);                break;            default:                $shouldTrigger = false;                $evaluatedData = [                    'reason' => 'Unsupported trigger type.',                    'trigger_type' => $rule->trigger_type,                ];        }        if (!$shouldTrigger) {            AutomationTriggerLog::create([                'automation_rule_id' => $rule->id,                'user_id' => $rule->user_id,                'status' => 'skipped',                'evaluated_data' => $evaluatedData,                'message' => 'Rule conditions not met.',            ]);            return [                'rule_id' => $rule->id,                'rule_name' => $rule->rule_name,                'status' => 'skipped',                'evaluated_data' => $evaluatedData,            ];        }        $this->performAction($rule, $evaluatedData);        $rule->update([            'last_triggered_at' => now(),        ]);        AutomationTriggerLog::create([            'automation_rule_id' => $rule->id,            'user_id' => $rule->user_id,            'status' => 'triggered',            'evaluated_data' => $evaluatedData,            'message' => 'Automation triggered successfully.',        ]);        return [            'rule_id' => $rule->id,            'rule_name' => $rule->rule_name,            'status' => 'triggered',            'evaluated_data' => $evaluatedData,        ];    }    private function evaluateMissingLog(AutomationRule $rule): array    {        $conditions = $rule->conditions ?? [];        $table = $conditions['table'] ?? null;        $dateColumn = $conditions['date_column'] ?? 'log_date';        $targetDate = $conditions['target_date'] ?? now()->toDateString();        if (!$table) {            return [                false,                [                    'reason' => 'Missing table in conditions.',                ],            ];        }        $count = DB::table($table)            ->where('user_id', $rule->user_id)            ->whereDate($dateColumn, $targetDate)            ->count();        return [            $count === 0,            [                'table' => $table,                'date_column' => $dateColumn,                'target_date' => $targetDate,                'records_found' => $count,            ],        ];    }    private function evaluateThresholdExceeded(AutomationRule $rule): array    {        $conditions = $rule->conditions ?? [];        $table = $conditions['table'] ?? null;        $metricColumn = $conditions['metric_column'] ?? null;        $operator = $conditions['operator'] ?? '>';        $value = $conditions['value'] ?? null;        $dateColumn = $conditions['date_column'] ?? null;        $targetDate = $conditions['target_date'] ?? now()->toDateString();        if (!$table || !$metricColumn || $value === null) {            return [                false,                [                    'reason' => 'Missing threshold configuration.',                ],            ];        }        $query = DB::table($table)            ->where('user_id', $rule->user_id);        if ($dateColumn) {            $query->whereDate($dateColumn, $targetDate);        }        $actualValue = (float) $query->sum($metricColumn);        $triggered = match ($operator) {            '>' => $actualValue > $value,            '>=' => $actualValue >= $value,            '<' => $actualValue < $value,            '<=' => $actualValue <= $value,            '=' => $actualValue == $value,            default => false,        };        return [            $triggered,            [                'table' => $table,                'metric_column' => $metricColumn,                'operator' => $operator,                'expected_value' => $value,                'actual_value' => $actualValue,                'target_date' => $targetDate,            ],        ];    }    private function evaluateDueToday(AutomationRule $rule): array    {        $conditions = $rule->conditions ?? [];        $table = $conditions['table'] ?? null;        $dueColumn = $conditions['due_column'] ?? 'due_date';        $statusColumn = $conditions['status_column'] ?? 'status';        $completedStatuses = $conditions['completed_statuses'] ?? ['done', 'completed'];        if (!$table) {            return [                false,                [                    'reason' => 'Missing table in due_today rule.',                ],            ];        }        $items = DB::table($table)            ->where('user_id', $rule->user_id)            ->whereDate($dueColumn, now()->toDateString())            ->whereNotIn($statusColumn, $completedStatuses)            ->get();        return [            $items->count() > 0,            [                'table' => $table,                'due_column' => $dueColumn,                'items_due_today' => $items->count(),                'items' => $items->take(5)->toArray(),            ],        ];    }    private function evaluateScheduledTime(AutomationRule $rule): array    {        $conditions = $rule->conditions ?? [];        $scheduledTime = $conditions['time'] ?? null;        $cooldownMinutes = $conditions['cooldown_minutes'] ?? 1440;        if (!$scheduledTime) {            return [                false,                [                    'reason' => 'Missing scheduled time.',                ],            ];        }        $nowTime = now()->format('H:i');        $alreadyTriggeredRecently = $rule->last_triggered_at            && $rule->last_triggered_at->greaterThan(now()->subMinutes($cooldownMinutes));        $shouldTrigger = $nowTime >= $scheduledTime && !$alreadyTriggeredRecently;        return [            $shouldTrigger,            [                'scheduled_time' => $scheduledTime,                'current_time' => $nowTime,                'cooldown_minutes' => $cooldownMinutes,                'already_triggered_recently' => $alreadyTriggeredRecently,            ],        ];    }    private function performAction(AutomationRule $rule, array $evaluatedData): void    {        $payload = $rule->action_payload ?? [];        if ($rule->action_type === 'create_notification') {            Notification::create([                'user_id' => $rule->user_id,                'title' => $payload['title'] ?? $rule->rule_name,                'message' => $payload['message'] ?? 'Smart automation reminder.',                'notification_type' => $payload['notification_type'] ?? 'reminder',                'priority' => $payload['priority'] ?? 'medium',                'data' => [                    'automation_rule_id' => $rule->id,                    'module' => $rule->module,                    'trigger_type' => $rule->trigger_type,                    'evaluated_data' => $evaluatedData,                ],                'is_read' => false,            ]);        }    }}

4. Important: Match Your Notification Model
From Step 21, your Notification model/table should support something like:
Notification::create([    'user_id' => ...,    'title' => ...,    'message' => ...,    'notification_type' => ...,    'priority' => ...,    'data' => ...,    'is_read' => false,]);
If your notification table uses different columns, tell me your Step 21 migration and I will adjust the service exactly.

5. Create Controller
Run:
php artisan make:controller Api/V1/AutomationRuleController
Open:
nano app/Http/Controllers/Api/V1/AutomationRuleController.php
Paste:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Models\AutomationRule;use App\Models\AutomationTriggerLog;use App\Services\AutomationEngineService;use Illuminate\Http\Request;class AutomationRuleController extends Controller{    public function index(Request $request)    {        $rules = AutomationRule::query()            ->where('user_id', $request->user()->id)            ->latest()            ->get();        return response()->json([            'status' => true,            'data' => $rules,        ]);    }    public function store(Request $request)    {        $validated = $request->validate([            'rule_name' => ['required', 'string', 'max:255'],            'module' => ['required', 'string', 'max:100'],            'trigger_type' => ['required', 'string', 'max:100'],            'conditions' => ['nullable', 'array'],            'action_type' => ['nullable', 'string', 'max:100'],            'action_payload' => ['nullable', 'array'],            'is_active' => ['nullable', 'boolean'],        ]);        $rule = AutomationRule::create([            'user_id' => $request->user()->id,            'rule_name' => $validated['rule_name'],            'module' => $validated['module'],            'trigger_type' => $validated['trigger_type'],            'conditions' => $validated['conditions'] ?? [],            'action_type' => $validated['action_type'] ?? 'create_notification',            'action_payload' => $validated['action_payload'] ?? [],            'is_active' => $validated['is_active'] ?? true,        ]);        return response()->json([            'status' => true,            'message' => 'Automation rule created successfully.',            'data' => $rule,        ], 201);    }    public function show(Request $request, string $id)    {        $rule = AutomationRule::query()            ->where('user_id', $request->user()->id)            ->findOrFail($id);        return response()->json([            'status' => true,            'data' => $rule,        ]);    }    public function update(Request $request, string $id)    {        $rule = AutomationRule::query()            ->where('user_id', $request->user()->id)            ->findOrFail($id);        $validated = $request->validate([            'rule_name' => ['sometimes', 'string', 'max:255'],            'module' => ['sometimes', 'string', 'max:100'],            'trigger_type' => ['sometimes', 'string', 'max:100'],            'conditions' => ['sometimes', 'nullable', 'array'],            'action_type' => ['sometimes', 'string', 'max:100'],            'action_payload' => ['sometimes', 'nullable', 'array'],            'is_active' => ['sometimes', 'boolean'],        ]);        $rule->update($validated);        return response()->json([            'status' => true,            'message' => 'Automation rule updated successfully.',            'data' => $rule,        ]);    }    public function destroy(Request $request, string $id)    {        $rule = AutomationRule::query()            ->where('user_id', $request->user()->id)            ->findOrFail($id);        $rule->delete();        return response()->json([            'status' => true,            'message' => 'Automation rule deleted successfully.',        ]);    }    public function run(Request $request, AutomationEngineService $service)    {        $results = $service->runForUser($request->user()->id);        return response()->json([            'status' => true,            'message' => 'Automation engine executed.',            'data' => $results,        ]);    }    public function logs(Request $request)    {        $logs = AutomationTriggerLog::query()            ->where('user_id', $request->user()->id)            ->with('rule')            ->latest()            ->limit(100)            ->get();        return response()->json([            'status' => true,            'data' => $logs,        ]);    }    public function toggle(Request $request, string $id)    {        $rule = AutomationRule::query()            ->where('user_id', $request->user()->id)            ->findOrFail($id);        $rule->update([            'is_active' => !$rule->is_active,        ]);        return response()->json([            'status' => true,            'message' => 'Automation rule status updated.',            'data' => $rule,        ]);    }}

6. Add Routes to routes/api.php
Open:
nano routes/api.php
Inside your authenticated API v1 group, add:
use App\Http\Controllers\Api\V1\AutomationRuleController;
Then add:
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {    Route::prefix('automation')->group(function () {        Route::get('/rules', [AutomationRuleController::class, 'index']);        Route::post('/rules', [AutomationRuleController::class, 'store']);        Route::get('/rules/{id}', [AutomationRuleController::class, 'show']);        Route::put('/rules/{id}', [AutomationRuleController::class, 'update']);        Route::delete('/rules/{id}', [AutomationRuleController::class, 'destroy']);        Route::post('/run', [AutomationRuleController::class, 'run']);        Route::get('/logs', [AutomationRuleController::class, 'logs']);        Route::patch('/rules/{id}/toggle', [AutomationRuleController::class, 'toggle']);    });});
If your api.php already has:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {    ...});
Then only add the inner automation routes.

7. Create Artisan Command for Automatic Execution
Run:
php artisan make:command RunAutomationEngine
Open:
nano app/Console/Commands/RunAutomationEngine.php
Paste:
<?phpnamespace App\Console\Commands;use App\Models\User;use App\Services\AutomationEngineService;use Illuminate\Console\Command;class RunAutomationEngine extends Command{    protected $signature = 'automation:run {--user_id=}';    protected $description = 'Run automation engine for all users or a specific user';    public function handle(AutomationEngineService $service): int    {        $userId = $this->option('user_id');        if ($userId) {            $results = $service->runForUser($userId);            $this->info('Automation engine executed for user: ' . $userId);            $this->line(json_encode($results, JSON_PRETTY_PRINT));            return self::SUCCESS;        }        User::query()            ->select('id')            ->chunk(100, function ($users) use ($service) {                foreach ($users as $user) {                    $service->runForUser($user->id);                    $this->info('Executed automation for user: ' . $user->id);                }            });        $this->info('Automation engine executed for all users.');        return self::SUCCESS;    }}

8. Schedule the Automation Engine
Open:
nano routes/console.php
Add:
use Illuminate\Support\Facades\Schedule;Schedule::command('automation:run')    ->everyFifteenMinutes()    ->withoutOverlapping();
Check:
php artisan schedule:list
You should see something like:
*/15 * * * * php artisan automation:run

9. Test API Routes
Check routes:
php artisan route:list | grep automation
Expected routes:
GET       api/v1/automation/rulesPOST      api/v1/automation/rulesGET       api/v1/automation/rules/{id}PUT       api/v1/automation/rules/{id}DELETE    api/v1/automation/rules/{id}POST      api/v1/automation/runGET       api/v1/automation/logsPATCH     api/v1/automation/rules/{id}/toggle

10. Example Automation Rules
Use your token:
TOKEN="YOUR_TOKEN_HERE"

10.1 Meal Reminder: No Meal Logged Today
curl -X POST http://127.0.0.1:8000/api/v1/automation/rules \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "rule_name": "Meal Log Reminder",    "module": "health",    "trigger_type": "missing_log",    "conditions": {      "table": "health_meal_logs",      "date_column": "meal_date",      "target_date": "2026-04-27"    },    "action_type": "create_notification",    "action_payload": {      "title": "Meal Reminder",      "message": "You have not logged any meals today.",      "notification_type": "reminder",      "priority": "medium"    },    "is_active": true  }'

10.2 Weight Reminder: No Weight Logged Today
curl -X POST http://127.0.0.1:8000/api/v1/automation/rules \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "rule_name": "Daily Weight Reminder",    "module": "health",    "trigger_type": "missing_log",    "conditions": {      "table": "health_weight_logs",      "date_column": "log_date",      "target_date": "2026-04-27"    },    "action_type": "create_notification",    "action_payload": {      "title": "Weight Reminder",      "message": "You have not logged your weight today.",      "notification_type": "reminder",      "priority": "low"    },    "is_active": true  }'

10.3 Hydration Alert: Water Less Than 1500ml
Adjust table/column names if your hydration table is different.
curl -X POST http://127.0.0.1:8000/api/v1/automation/rules \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "rule_name": "Hydration Goal Reminder",    "module": "health",    "trigger_type": "threshold_exceeded",    "conditions": {      "table": "health_hydration_logs",      "metric_column": "amount_ml",      "operator": "<",      "value": 1500,      "date_column": "drink_date",      "target_date": "2026-04-27"    },    "action_type": "create_notification",    "action_payload": {      "title": "Hydration Reminder",      "message": "Your water intake is still below your daily target.",      "notification_type": "reminder",      "priority": "medium"    },    "is_active": true  }'

10.4 Expense Alert: Daily Spending Over 50 USD
Adjust your finance transactions table/columns if needed.
curl -X POST http://127.0.0.1:8000/api/v1/automation/rules \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "rule_name": "Daily Expense Alert",    "module": "finance",    "trigger_type": "threshold_exceeded",    "conditions": {      "table": "finance_transactions",      "metric_column": "amount",      "operator": ">",      "value": 50,      "date_column": "transaction_date",      "target_date": "2026-04-27"    },    "action_type": "create_notification",    "action_payload": {      "title": "Expense Alert",      "message": "Your spending today is higher than your daily limit.",      "notification_type": "alert",      "priority": "high"    },    "is_active": true  }'

10.5 Project Task Due Today Reminder
curl -X POST http://127.0.0.1:8000/api/v1/automation/rules \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "rule_name": "Project Tasks Due Today",    "module": "projects",    "trigger_type": "due_today",    "conditions": {      "table": "project_tasks",      "due_column": "due_date",      "status_column": "status",      "completed_statuses": ["done", "completed"]    },    "action_type": "create_notification",    "action_payload": {      "title": "Tasks Due Today",      "message": "You have project tasks due today.",      "notification_type": "reminder",      "priority": "high"    },    "is_active": true  }'

10.6 Daily Review Reminder at 23:00
curl -X POST http://127.0.0.1:8000/api/v1/automation/rules \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "rule_name": "Daily Review Reminder",    "module": "system",    "trigger_type": "scheduled_time",    "conditions": {      "time": "23:00",      "cooldown_minutes": 1440    },    "action_type": "create_notification",    "action_payload": {      "title": "Daily Review",      "message": "Review your health, finance, and productivity summary for today.",      "notification_type": "reminder",      "priority": "medium"    },    "is_active": true  }'

11. Run Automation Manually
curl -X POST http://127.0.0.1:8000/api/v1/automation/run \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Expected response:
{  "status": true,  "message": "Automation engine executed.",  "data": [    {      "rule_id": "019xxxx",      "rule_name": "Daily Weight Reminder",      "status": "triggered",      "evaluated_data": {        "table": "health_weight_logs",        "records_found": 0      }    }  ]}

12. View Automation Logs
curl http://127.0.0.1:8000/api/v1/automation/logs \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

13. Run from Terminal
For all users:
php artisan automation:run
For one user:
php artisan automation:run --user_id=019d7c17-adcf-713f-b853-328a2fb65e57

14. Important Fix for Schema-Based Tables
If your tables are inside a PostgreSQL schema, for example:
nix_life_os.health_weight_logs
Then your condition should use:
"table": "nix_life_os.health_weight_logs"
Example:
"conditions": {  "table": "nix_life_os.health_weight_logs",  "date_column": "log_date"}

15. Step 22 API Summary
MethodEndpointPurposeGET/api/v1/automation/rulesList rulesPOST/api/v1/automation/rulesCreate ruleGET/api/v1/automation/rules/{id}Show rulePUT/api/v1/automation/rules/{id}Update ruleDELETE/api/v1/automation/rules/{id}Delete rulePATCH/api/v1/automation/rules/{id}/toggleEnable/disable rulePOST/api/v1/automation/runRun engine manuallyGET/api/v1/automation/logsView automation logs

16. Final Architecture
User Behavior    ↓Automation Rules    ↓Automation Engine Service    ↓Condition Evaluation    ↓Trigger Logs    ↓Notification Created    ↓Frontend Notification Center

17. Recommended Commit
git add .git commit -m "Step 22: add automation engine with behavior triggers and smart reminders"

✅ Step 22 Completed
You now have:
✅ Automation rules table✅ Trigger logs table✅ Behavior-based triggers✅ Missing log detection✅ Threshold alerts✅ Due today reminders✅ Scheduled smart reminders✅ Notification integration✅ API endpoints✅ Manual run endpoint✅ Scheduled Laravel command
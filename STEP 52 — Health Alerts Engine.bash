🔹 STEP 52 — Health Alerts Engine
Nix Life OS — Professional Implementation Design

You are now adding a Health Alerts Engine to Nix Life OS.

This engine will analyze user health data from nutrition, hydration, weight, medications, lab tests, steps, and sleep modules, then generate clear alerts such as:

“High sodium intake detected today.”
“Medication dose missed.”
“Potassium is above CKD-safe daily limit.”
“Rapid weight increase detected in 3 days.”
“Abnormal creatinine lab result detected.”

This should be treated as a health tracking and awareness feature, not a medical diagnosis system.

1. Health Alerts Engine Goals

The Health Alerts Engine must:

Detect unhealthy health patterns.
Generate alerts automatically.
Store alerts in database.
Display alerts on Health Dashboard.
Allow user to mark alerts as read/resolved.
Support different alert severities.
Support CKD-focused warning rules.
Detect daily, weekly, and repeated trends.
Be extendable for future AI/ML health insights.
Be safe, clear, and medically responsible.
2. Alert Categories

Use these alert categories:

nutrition
hydration
weight
medication
lab_test
activity
sleep
pattern
system

Use these severities:

info
warning
critical

Use these statuses:

active
read
resolved
dismissed
3. Core Alert Rules
3.1 High Sodium Intake
Rule

Trigger alert when daily sodium intake exceeds the user’s daily limit.

For CKD-friendly defaults:

Sodium warning threshold: >= 1,800 mg/day
Sodium critical threshold: >= 2,300 mg/day
Example Alert
High sodium intake detected today.
You consumed 2,450 mg sodium, which exceeds your recommended daily limit.
Logic
if ($dailySodiumMg >= 2300) {
    severity = 'critical';
} elseif ($dailySodiumMg >= 1800) {
    severity = 'warning';
}
3.2 High Potassium Intake
Rule

Trigger alert when daily potassium intake exceeds CKD-safe limit.

Default CKD-sensitive thresholds:

Potassium warning threshold: >= 2,000 mg/day
Potassium critical threshold: >= 2,500 mg/day
Example Alert
High potassium intake detected.
Your potassium intake reached 2,650 mg today.
Logic
if ($dailyPotassiumMg >= 2500) {
    severity = 'critical';
} elseif ($dailyPotassiumMg >= 2000) {
    severity = 'warning';
}
3.3 High Phosphorus Intake
Rule

Trigger alert when daily phosphorus exceeds recommended CKD control level.

Default thresholds:

Phosphorus warning threshold: >= 800 mg/day
Phosphorus critical threshold: >= 1,000 mg/day
Example Alert
High phosphorus intake detected.
Today’s phosphorus intake is above your recommended limit.
3.4 Low Hydration
Rule

Trigger alert when daily water intake is below goal.

Default rule:

Warning: below 70% of goal
Critical: below 40% of goal

Example:

Daily goal: 2,000 ml
Warning if below 1,400 ml
Critical if below 800 ml
Example Alert
Low hydration detected.
You consumed only 650 ml of water today.
3.5 Rapid Weight Change
Rule

Trigger alert when weight changes too quickly.

Recommended initial rules:

Warning: +/- 1.5 kg in 3 days
Critical: +/- 2.5 kg in 7 days

For CKD users, rapid weight gain can be important because it may indicate fluid retention.

Example Alert
Rapid weight increase detected.
Your weight increased by 2.1 kg within 3 days.
Logic

Compare latest weight with weight from:

3 days ago
7 days ago
3.6 Missed Medication
Rule

Trigger alert when a scheduled medication dose is not marked as taken.

Recommended rules:

Warning: missed 1 dose
Critical: missed 2 or more doses in same day
Repeated pattern: missed same medication 3 times in 7 days
Example Alert
Medication dose missed.
You missed your scheduled medication dose for today.
3.7 Abnormal Lab Results
Rule

Trigger alert when a lab result is outside configured normal range.

Examples:

Creatinine above max range
Urea above max range
Potassium above max range
Hemoglobin below min range
eGFR below target range
Phosphorus above max range
Vitamin D below min range
Example Alert
Abnormal creatinine result detected.
Your latest creatinine result is above the configured safe range.
Logic

Each lab test should have:

test_name
result_value
unit
normal_min
normal_max

Then:

if ($value < $normalMin || $value > $normalMax) {
    create alert;
}
3.8 Low Step Activity
Rule

Trigger alert when daily steps are below goal.

Recommended rules:

Warning: below 50% of daily goal
Critical: below 25% of daily goal
Repeated pattern: below 50% goal for 3 days in a row

Example:

Daily goal: 6,000 steps
Warning: below 3,000
Critical: below 1,500
3.9 Poor Sleep Trend
Rule

Trigger alert when sleep duration or quality is poor.

Recommended rules:

Warning: less than 6 hours sleep
Critical: less than 4 hours sleep
Repeated pattern: less than 6 hours for 3 days in a row

Optional future rules:

Late sleep time
Frequent wake-ups
Low sleep quality score
Irregular sleep schedule
3.10 Repeated Unhealthy Patterns
Rule

Detect recurring issues over 7 days.

Examples:

High sodium 3 times in 7 days
Low hydration 3 times in 7 days
Missed medication 3 times in 7 days
Low steps 4 times in 7 days
Poor sleep 3 times in 7 days
High potassium 2 times in 7 days
Example Alert
Repeated unhealthy pattern detected.
High sodium intake occurred 3 times during the last 7 days.
4. Database Schema Design
4.1 Main Table: health_alerts

Create a table to store generated alerts.

php artisan make:migration create_health_alerts_table
Migration
Schema::create('health_alerts', function (Blueprint $table) {
    $table->uuid('id')->primary();

    $table->foreignUuid('user_id')
        ->constrained('users')
        ->cascadeOnDelete();

    $table->string('alert_type', 100);
    $table->string('category', 100);

    $table->string('severity', 50)->default('warning');
    $table->string('status', 50)->default('active');

    $table->string('title');
    $table->text('message')->nullable();

    $table->date('alert_date')->nullable();

    $table->string('source_table')->nullable();
    $table->uuid('source_id')->nullable();

    $table->json('metadata')->nullable();

    $table->timestamp('read_at')->nullable();
    $table->timestamp('resolved_at')->nullable();
    $table->timestamp('dismissed_at')->nullable();

    $table->timestamps();

    $table->index(['user_id', 'status']);
    $table->index(['user_id', 'category']);
    $table->index(['user_id', 'severity']);
    $table->index(['user_id', 'alert_date']);
    $table->index(['alert_type']);
});
4.2 Optional Table: health_alert_rules

This table allows rules to be configurable later from admin/settings screen.

php artisan make:migration create_health_alert_rules_table
Migration
Schema::create('health_alert_rules', function (Blueprint $table) {
    $table->uuid('id')->primary();

    $table->string('code')->unique();
    $table->string('name');

    $table->string('category', 100);
    $table->string('severity', 50)->default('warning');

    $table->decimal('warning_threshold', 12, 2)->nullable();
    $table->decimal('critical_threshold', 12, 2)->nullable();

    $table->string('operator', 20)->nullable();
    $table->string('unit', 50)->nullable();

    $table->boolean('is_active')->default(true);

    $table->json('metadata')->nullable();

    $table->timestamps();

    $table->index(['category', 'is_active']);
});
5. Laravel Model Design
5.1 HealthAlert.php

Path:

backend/app/Models/HealthAlert.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthAlert extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'alert_type',
        'category',
        'severity',
        'status',
        'title',
        'message',
        'alert_date',
        'source_table',
        'source_id',
        'metadata',
        'read_at',
        'resolved_at',
        'dismissed_at',
    ];

    protected $casts = [
        'alert_date' => 'date',
        'metadata' => 'array',
        'read_at' => 'datetime',
        'resolved_at' => 'datetime',
        'dismissed_at' => 'datetime',
    ];

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }

    public function scopeCritical($query)
    {
        return $query->where('severity', 'critical');
    }
}
5.2 HealthAlertRule.php

Path:

backend/app/Models/HealthAlertRule.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthAlertRule extends Model
{
    use HasUuids;

    protected $fillable = [
        'code',
        'name',
        'category',
        'severity',
        'warning_threshold',
        'critical_threshold',
        'operator',
        'unit',
        'is_active',
        'metadata',
    ];

    protected $casts = [
        'warning_threshold' => 'decimal:2',
        'critical_threshold' => 'decimal:2',
        'is_active' => 'boolean',
        'metadata' => 'array',
    ];
}
6. Alert Type Codes

Use consistent alert codes.

HIGH_SODIUM
HIGH_POTASSIUM
HIGH_PHOSPHORUS
LOW_HYDRATION
RAPID_WEIGHT_GAIN
RAPID_WEIGHT_LOSS
MISSED_MEDICATION
ABNORMAL_LAB_RESULT
LOW_STEP_ACTIVITY
POOR_SLEEP_TREND
REPEATED_UNHEALTHY_PATTERN
7. Laravel Service Design

Create service:

mkdir -p app/Services/Health
nano app/Services/Health/HealthAlertEngineService.php

Path:

backend/app/Services/Health/HealthAlertEngineService.php
Main Service Structure
<?php

namespace App\Services\Health;

use App\Models\HealthAlert;
use App\Models\HealthNutritionLog;
use App\Models\HealthHydrationLog;
use App\Models\HealthWeightLog;
use App\Models\HealthMedicationDose;
use App\Models\HealthLabTest;
use App\Models\HealthStepLog;
use App\Models\HealthSleepLog;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class HealthAlertEngineService
{
    public function runForUser(string $userId, ?string $date = null): array
    {
        $date = $date ? Carbon::parse($date)->toDateString() : now()->toDateString();

        $created = [];

        $created[] = $this->checkHighSodium($userId, $date);
        $created[] = $this->checkHighPotassium($userId, $date);
        $created[] = $this->checkHighPhosphorus($userId, $date);
        $created[] = $this->checkLowHydration($userId, $date);
        $created[] = $this->checkRapidWeightChange($userId, $date);
        $created[] = $this->checkMissedMedication($userId, $date);
        $created[] = $this->checkAbnormalLabResults($userId, $date);
        $created[] = $this->checkLowStepActivity($userId, $date);
        $created[] = $this->checkPoorSleepTrend($userId, $date);
        $created[] = $this->checkRepeatedPatterns($userId, $date);

        return array_filter($created);
    }

    private function createAlertOnce(array $data): ?HealthAlert
    {
        $exists = HealthAlert::where('user_id', $data['user_id'])
            ->where('alert_type', $data['alert_type'])
            ->where('alert_date', $data['alert_date'])
            ->where('source_id', $data['source_id'] ?? null)
            ->whereIn('status', ['active', 'read'])
            ->exists();

        if ($exists) {
            return null;
        }

        return HealthAlert::create($data);
    }
}
8. Rule Implementation Examples
8.1 High Sodium Rule
private function checkHighSodium(string $userId, string $date): ?HealthAlert
{
    $total = HealthNutritionLog::where('user_id', $userId)
        ->whereDate('meal_date', $date)
        ->sum('sodium_mg');

    if ($total < 1800) {
        return null;
    }

    $severity = $total >= 2300 ? 'critical' : 'warning';

    return $this->createAlertOnce([
        'user_id' => $userId,
        'alert_type' => 'HIGH_SODIUM',
        'category' => 'nutrition',
        'severity' => $severity,
        'status' => 'active',
        'title' => 'High sodium intake detected',
        'message' => "Your sodium intake reached {$total} mg today.",
        'alert_date' => $date,
        'source_table' => 'health_nutrition_logs',
        'metadata' => [
            'total_sodium_mg' => $total,
            'warning_threshold_mg' => 1800,
            'critical_threshold_mg' => 2300,
        ],
    ]);
}
8.2 High Potassium Rule
private function checkHighPotassium(string $userId, string $date): ?HealthAlert
{
    $total = HealthNutritionLog::where('user_id', $userId)
        ->whereDate('meal_date', $date)
        ->sum('potassium_mg');

    if ($total < 2000) {
        return null;
    }

    $severity = $total >= 2500 ? 'critical' : 'warning';

    return $this->createAlertOnce([
        'user_id' => $userId,
        'alert_type' => 'HIGH_POTASSIUM',
        'category' => 'nutrition',
        'severity' => $severity,
        'status' => 'active',
        'title' => 'High potassium intake detected',
        'message' => "Your potassium intake reached {$total} mg today.",
        'alert_date' => $date,
        'source_table' => 'health_nutrition_logs',
        'metadata' => [
            'total_potassium_mg' => $total,
            'warning_threshold_mg' => 2000,
            'critical_threshold_mg' => 2500,
        ],
    ]);
}
8.3 High Phosphorus Rule
private function checkHighPhosphorus(string $userId, string $date): ?HealthAlert
{
    $total = HealthNutritionLog::where('user_id', $userId)
        ->whereDate('meal_date', $date)
        ->sum('phosphorus_mg');

    if ($total < 800) {
        return null;
    }

    $severity = $total >= 1000 ? 'critical' : 'warning';

    return $this->createAlertOnce([
        'user_id' => $userId,
        'alert_type' => 'HIGH_PHOSPHORUS',
        'category' => 'nutrition',
        'severity' => $severity,
        'status' => 'active',
        'title' => 'High phosphorus intake detected',
        'message' => "Your phosphorus intake reached {$total} mg today.",
        'alert_date' => $date,
        'source_table' => 'health_nutrition_logs',
        'metadata' => [
            'total_phosphorus_mg' => $total,
            'warning_threshold_mg' => 800,
            'critical_threshold_mg' => 1000,
        ],
    ]);
}
8.4 Low Hydration Rule
private function checkLowHydration(string $userId, string $date): ?HealthAlert
{
    $goalMl = 2000;

    $total = HealthHydrationLog::where('user_id', $userId)
        ->whereDate('log_date', $date)
        ->sum('amount_ml');

    $percent = $goalMl > 0 ? ($total / $goalMl) * 100 : 0;

    if ($percent >= 70) {
        return null;
    }

    $severity = $percent < 40 ? 'critical' : 'warning';

    return $this->createAlertOnce([
        'user_id' => $userId,
        'alert_type' => 'LOW_HYDRATION',
        'category' => 'hydration',
        'severity' => $severity,
        'status' => 'active',
        'title' => 'Low hydration detected',
        'message' => "You consumed {$total} ml of water today.",
        'alert_date' => $date,
        'source_table' => 'health_hydration_logs',
        'metadata' => [
            'total_water_ml' => $total,
            'goal_ml' => $goalMl,
            'goal_percent' => round($percent, 2),
        ],
    ]);
}
8.5 Missed Medication Rule
private function checkMissedMedication(string $userId, string $date): ?HealthAlert
{
    $missedCount = HealthMedicationDose::where('user_id', $userId)
        ->whereDate('scheduled_at', $date)
        ->whereIn('status', ['missed', 'pending'])
        ->where('scheduled_at', '<', now())
        ->count();

    if ($missedCount === 0) {
        return null;
    }

    $severity = $missedCount >= 2 ? 'critical' : 'warning';

    return $this->createAlertOnce([
        'user_id' => $userId,
        'alert_type' => 'MISSED_MEDICATION',
        'category' => 'medication',
        'severity' => $severity,
        'status' => 'active',
        'title' => 'Missed medication dose detected',
        'message' => "You have {$missedCount} missed medication dose(s) today.",
        'alert_date' => $date,
        'source_table' => 'health_medication_doses',
        'metadata' => [
            'missed_count' => $missedCount,
        ],
    ]);
}
8.6 Abnormal Lab Results Rule
private function checkAbnormalLabResults(string $userId, string $date): ?HealthAlert
{
    $abnormalResults = HealthLabTest::where('user_id', $userId)
        ->whereDate('test_date', $date)
        ->where(function ($query) {
            $query->whereColumn('result_value', '<', 'normal_min')
                ->orWhereColumn('result_value', '>', 'normal_max');
        })
        ->get();

    if ($abnormalResults->isEmpty()) {
        return null;
    }

    $first = $abnormalResults->first();

    return $this->createAlertOnce([
        'user_id' => $userId,
        'alert_type' => 'ABNORMAL_LAB_RESULT',
        'category' => 'lab_test',
        'severity' => 'critical',
        'status' => 'active',
        'title' => 'Abnormal lab result detected',
        'message' => "{$first->test_name} result is outside the configured normal range.",
        'alert_date' => $date,
        'source_table' => 'health_lab_tests',
        'source_id' => $first->id,
        'metadata' => [
            'abnormal_count' => $abnormalResults->count(),
            'test_name' => $first->test_name,
            'result_value' => $first->result_value,
            'unit' => $first->unit,
            'normal_min' => $first->normal_min,
            'normal_max' => $first->normal_max,
        ],
    ]);
}
9. Artisan Command

Create command:

php artisan make:command RunHealthAlertsEngine

Path:

backend/app/Console/Commands/RunHealthAlertsEngine.php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Services\Health\HealthAlertEngineService;

class RunHealthAlertsEngine extends Command
{
    protected $signature = 'health:generate-alerts {--user_id=} {--date=}';

    protected $description = 'Generate health alerts for users';

    public function handle(HealthAlertEngineService $engine): int
    {
        $userId = $this->option('user_id');
        $date = $this->option('date') ?? now()->toDateString();

        $users = $userId
            ? User::where('id', $userId)->get()
            : User::query()->get();

        foreach ($users as $user) {
            $alerts = $engine->runForUser($user->id, $date);

            $this->info("User {$user->id}: " . count($alerts) . " alert(s) generated.");
        }

        return self::SUCCESS;
    }
}

Run manually:

php artisan health:generate-alerts

Run for one user:

php artisan health:generate-alerts --user_id=USER_UUID

Run for specific date:

php artisan health:generate-alerts --user_id=USER_UUID --date=2026-05-11
10. Scheduler Setup

In Laravel scheduler:

Path:

backend/routes/console.php

Add:

use Illuminate\Support\Facades\Schedule;

Schedule::command('health:generate-alerts')->hourly();

Recommended schedule:

Hourly for medication/hydration alerts
Daily at night for nutrition, sleep, steps, repeated patterns

Later you can split commands:

health:generate-daily-alerts
health:generate-medication-alerts
health:generate-trend-alerts
11. API Endpoints

Add controller:

php artisan make:controller Api/V1/HealthAlertController

Path:

backend/app/Http/Controllers/Api/V1/HealthAlertController.php
Required Endpoints
GET    /api/v1/health/alerts
GET    /api/v1/health/alerts/summary
POST   /api/v1/health/alerts/run
PATCH  /api/v1/health/alerts/{id}/read
PATCH  /api/v1/health/alerts/{id}/resolve
PATCH  /api/v1/health/alerts/{id}/dismiss
DELETE /api/v1/health/alerts/{id}
Controller Example
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthAlert;
use App\Services\Health\HealthAlertEngineService;
use Illuminate\Http\Request;

class HealthAlertController extends Controller
{
    public function index(Request $request)
    {
        $query = HealthAlert::where('user_id', $request->user()->id)
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('severity')) {
            $query->where('severity', $request->severity);
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        return response()->json([
            'success' => true,
            'message' => 'Health alerts loaded successfully.',
            'data' => $query->paginate(20),
        ]);
    }

    public function summary(Request $request)
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Health alerts summary loaded successfully.',
            'data' => [
                'active_count' => HealthAlert::where('user_id', $userId)->where('status', 'active')->count(),
                'critical_count' => HealthAlert::where('user_id', $userId)->where('status', 'active')->where('severity', 'critical')->count(),
                'warning_count' => HealthAlert::where('user_id', $userId)->where('status', 'active')->where('severity', 'warning')->count(),
                'unread_count' => HealthAlert::where('user_id', $userId)->whereNull('read_at')->count(),
                'latest' => HealthAlert::where('user_id', $userId)->latest()->limit(5)->get(),
            ],
        ]);
    }

    public function run(Request $request, HealthAlertEngineService $engine)
    {
        $alerts = $engine->runForUser(
            $request->user()->id,
            $request->input('date')
        );

        return response()->json([
            'success' => true,
            'message' => 'Health alerts engine executed successfully.',
            'data' => [
                'generated_count' => count($alerts),
                'alerts' => array_values($alerts),
            ],
        ]);
    }

    public function markAsRead(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->update([
            'status' => $alert->status === 'active' ? 'read' : $alert->status,
            'read_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert marked as read.',
            'data' => $alert,
        ]);
    }

    public function resolve(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->update([
            'status' => 'resolved',
            'resolved_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert resolved successfully.',
            'data' => $alert,
        ]);
    }

    public function dismiss(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->update([
            'status' => 'dismissed',
            'dismissed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert dismissed successfully.',
            'data' => $alert,
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->delete();

        return response()->json([
            'success' => true,
            'message' => 'Alert deleted successfully.',
        ]);
    }
}
12. API Routes

Path:

backend/routes/api.php

Inside:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    Route::prefix('health')->group(function () {
        Route::get('/alerts', [HealthAlertController::class, 'index']);
        Route::get('/alerts/summary', [HealthAlertController::class, 'summary']);
        Route::post('/alerts/run', [HealthAlertController::class, 'run']);

        Route::patch('/alerts/{id}/read', [HealthAlertController::class, 'markAsRead']);
        Route::patch('/alerts/{id}/resolve', [HealthAlertController::class, 'resolve']);
        Route::patch('/alerts/{id}/dismiss', [HealthAlertController::class, 'dismiss']);

        Route::delete('/alerts/{id}', [HealthAlertController::class, 'destroy']);
    });
});

Add import:

use App\Http\Controllers\Api\V1\HealthAlertController;
13. Vue Service Design

Create:

frontend/src/services/healthAlertService.js
import api from "./api";

export const healthAlertService = {
  async getAlerts(params = {}) {
    const response = await api.get("/health/alerts", { params });
    return response.data;
  },

  async getSummary() {
    const response = await api.get("/health/alerts/summary");
    return response.data;
  },

  async runEngine(date = null) {
    const response = await api.post("/health/alerts/run", { date });
    return response.data;
  },

  async markAsRead(id) {
    const response = await api.patch(`/health/alerts/${id}/read`);
    return response.data;
  },

  async resolve(id) {
    const response = await api.patch(`/health/alerts/${id}/resolve`);
    return response.data;
  },

  async dismiss(id) {
    const response = await api.patch(`/health/alerts/${id}/dismiss`);
    return response.data;
  },

  async deleteAlert(id) {
    const response = await api.delete(`/health/alerts/${id}`);
    return response.data;
  },
};
14. Vue Alert Display Component

Create:

frontend/src/components/health/HealthAlertsPanel.vue
<template>
  <section class="alerts-panel">
    <div class="alerts-header">
      <div>
        <h2>Health Alerts</h2>
        <p>Important warnings and health trends detected by Nix Life OS.</p>
      </div>

      <button class="run-btn" @click="runAlertsEngine" :disabled="loading">
        {{ loading ? "Checking..." : "Run Check" }}
      </button>
    </div>

    <div v-if="summary" class="alert-summary">
      <div class="summary-card critical">
        <strong>{{ summary.critical_count }}</strong>
        <span>Critical</span>
      </div>

      <div class="summary-card warning">
        <strong>{{ summary.warning_count }}</strong>
        <span>Warnings</span>
      </div>

      <div class="summary-card active">
        <strong>{{ summary.active_count }}</strong>
        <span>Active</span>
      </div>

      <div class="summary-card unread">
        <strong>{{ summary.unread_count }}</strong>
        <span>Unread</span>
      </div>
    </div>

    <div class="filters">
      <select v-model="filters.status" @change="loadAlerts">
        <option value="">All Status</option>
        <option value="active">Active</option>
        <option value="read">Read</option>
        <option value="resolved">Resolved</option>
        <option value="dismissed">Dismissed</option>
      </select>

      <select v-model="filters.severity" @change="loadAlerts">
        <option value="">All Severity</option>
        <option value="critical">Critical</option>
        <option value="warning">Warning</option>
        <option value="info">Info</option>
      </select>

      <select v-model="filters.category" @change="loadAlerts">
        <option value="">All Categories</option>
        <option value="nutrition">Nutrition</option>
        <option value="hydration">Hydration</option>
        <option value="weight">Weight</option>
        <option value="medication">Medication</option>
        <option value="lab_test">Lab Test</option>
        <option value="activity">Activity</option>
        <option value="sleep">Sleep</option>
        <option value="pattern">Pattern</option>
      </select>
    </div>

    <div v-if="loading" class="state-box">
      Loading health alerts...
    </div>

    <div v-else-if="error" class="state-box error">
      {{ error }}
    </div>

    <div v-else-if="alerts.length === 0" class="state-box empty">
      No health alerts found.
    </div>

    <div v-else class="alerts-list">
      <article
        v-for="alert in alerts"
        :key="alert.id"
        class="alert-card"
        :class="alert.severity"
      >
        <div class="alert-top">
          <div>
            <span class="badge" :class="alert.severity">
              {{ alert.severity }}
            </span>

            <span class="category">
              {{ formatCategory(alert.category) }}
            </span>
          </div>

          <span class="date">
            {{ formatDate(alert.alert_date || alert.created_at) }}
          </span>
        </div>

        <h3>{{ alert.title }}</h3>
        <p>{{ alert.message }}</p>

        <div class="alert-actions">
          <button @click="markAsRead(alert.id)">Read</button>
          <button @click="resolveAlert(alert.id)">Resolve</button>
          <button @click="dismissAlert(alert.id)">Dismiss</button>
        </div>
      </article>
    </div>
  </section>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { healthAlertService } from "@/services/healthAlertService";

const loading = ref(false);
const error = ref("");
const alerts = ref([]);
const summary = ref(null);

const filters = ref({
  status: "active",
  severity: "",
  category: "",
});

const loadSummary = async () => {
  const response = await healthAlertService.getSummary();
  summary.value = response.data;
};

const loadAlerts = async () => {
  loading.value = true;
  error.value = "";

  try {
    const response = await healthAlertService.getAlerts(filters.value);
    alerts.value = response.data.data || response.data || [];
  } catch (err) {
    error.value = "Failed to load health alerts.";
  } finally {
    loading.value = false;
  }
};

const runAlertsEngine = async () => {
  loading.value = true;
  error.value = "";

  try {
    await healthAlertService.runEngine();
    await loadSummary();
    await loadAlerts();
  } catch (err) {
    error.value = "Failed to run health alerts engine.";
  } finally {
    loading.value = false;
  }
};

const markAsRead = async (id) => {
  await healthAlertService.markAsRead(id);
  await loadSummary();
  await loadAlerts();
};

const resolveAlert = async (id) => {
  await healthAlertService.resolve(id);
  await loadSummary();
  await loadAlerts();
};

const dismissAlert = async (id) => {
  await healthAlertService.dismiss(id);
  await loadSummary();
  await loadAlerts();
};

const formatCategory = (category) => {
  return String(category || "")
    .replace("_", " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
};

const formatDate = (value) => {
  if (!value) return "-";
  return new Date(value).toLocaleDateString();
};

onMounted(async () => {
  await loadSummary();
  await loadAlerts();
});
</script>

<style scoped>
.alerts-panel {
  background: #ffffff;
  border-radius: 18px;
  padding: 24px;
  border: 1px solid #e5e7eb;
}

.alerts-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 20px;
}

.alerts-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
}

.alerts-header p {
  color: #6b7280;
  margin-top: 4px;
}

.run-btn {
  background: #2563eb;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 10px;
  cursor: pointer;
}

.run-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.alert-summary {
  display: grid;
  grid-template-columns: repeat(4, minmax(120px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}

.summary-card {
  padding: 16px;
  border-radius: 14px;
  border: 1px solid #e5e7eb;
  background: #f9fafb;
}

.summary-card strong {
  display: block;
  font-size: 26px;
  color: #111827;
}

.summary-card span {
  color: #6b7280;
}

.filters {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filters select {
  padding: 10px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
}

.state-box {
  padding: 18px;
  border-radius: 12px;
  background: #f3f4f6;
  color: #374151;
}

.state-box.error {
  background: #fee2e2;
  color: #991b1b;
}

.state-box.empty {
  background: #ecfdf5;
  color: #065f46;
}

.alerts-list {
  display: grid;
  gap: 14px;
}

.alert-card {
  padding: 18px;
  border-radius: 16px;
  border: 1px solid #e5e7eb;
  background: #ffffff;
}

.alert-card.critical {
  border-left: 6px solid #dc2626;
}

.alert-card.warning {
  border-left: 6px solid #f59e0b;
}

.alert-card.info {
  border-left: 6px solid #2563eb;
}

.alert-top {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.badge {
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  text-transform: uppercase;
  font-weight: 700;
}

.badge.critical {
  background: #fee2e2;
  color: #991b1b;
}

.badge.warning {
  background: #fef3c7;
  color: #92400e;
}

.badge.info {
  background: #dbeafe;
  color: #1d4ed8;
}

.category {
  margin-left: 8px;
  color: #6b7280;
  font-size: 13px;
}

.date {
  color: #6b7280;
  font-size: 13px;
}

.alert-card h3 {
  font-size: 18px;
  color: #111827;
  margin-bottom: 6px;
}

.alert-card p {
  color: #4b5563;
}

.alert-actions {
  display: flex;
  gap: 8px;
  margin-top: 14px;
}

.alert-actions button {
  border: 1px solid #d1d5db;
  background: #ffffff;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
}
</style>
15. Health Alerts Page

Create page:

frontend/src/views/health/HealthAlertsView.vue
<template>
  <main class="health-alerts-page">
    <HealthAlertsPanel />
  </main>
</template>

<script setup>
import HealthAlertsPanel from "@/components/health/HealthAlertsPanel.vue";
</script>

<style scoped>
.health-alerts-page {
  padding: 24px;
}
</style>
16. Vue Router Route

Path:

frontend/src/router/index.js

Add import:

import HealthAlertsView from "@/views/health/HealthAlertsView.vue";

Add route:

{
  path: "/health/alerts",
  name: "health-alerts",
  component: HealthAlertsView,
  meta: {
    requiresAuth: true,
    title: "Health Alerts",
  },
}
17. Sidebar Menu Item

Add inside Health menu:

<RouterLink to="/health/alerts" class="sidebar-link">
  <span>Health Alerts</span>
</RouterLink>

Recommended Health menu order:

Health Dashboard
Steps Tracking
Weight Tracking
Nutrition Tracking
Hydration Tracking
Sleep Tracking
Medication Tracking
Lab Tests
Health Alerts
18. API Testing Commands

Set token:

export TOKEN="YOUR_TOKEN_HERE"
18.1 Check Routes
cd /u01/nix-life-os/backend

php artisan route:list | grep health
php artisan route:list | grep alerts

Expected routes:

GET     api/v1/health/alerts
GET     api/v1/health/alerts/summary
POST    api/v1/health/alerts/run
PATCH   api/v1/health/alerts/{id}/read
PATCH   api/v1/health/alerts/{id}/resolve
PATCH   api/v1/health/alerts/{id}/dismiss
DELETE  api/v1/health/alerts/{id}
18.2 Run Alerts Engine
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/alerts/run" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Health alerts engine executed successfully.",
  "data": {
    "generated_count": 1,
    "alerts": []
  }
}
18.3 Get Alerts
curl -i "http://127.0.0.1:8000/api/v1/health/alerts" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
18.4 Get Active Alerts
curl -i "http://127.0.0.1:8000/api/v1/health/alerts?status=active" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
18.5 Get Critical Alerts
curl -i "http://127.0.0.1:8000/api/v1/health/alerts?severity=critical" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
18.6 Get Alerts Summary
curl -i "http://127.0.0.1:8000/api/v1/health/alerts/summary" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Health alerts summary loaded successfully.",
  "data": {
    "active_count": 3,
    "critical_count": 1,
    "warning_count": 2,
    "unread_count": 3,
    "latest": []
  }
}
18.7 Mark Alert As Read
curl -i -X PATCH "http://127.0.0.1:8000/api/v1/health/alerts/ALERT_ID/read" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
18.8 Resolve Alert
curl -i -X PATCH "http://127.0.0.1:8000/api/v1/health/alerts/ALERT_ID/resolve" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
18.9 Dismiss Alert
curl -i -X PATCH "http://127.0.0.1:8000/api/v1/health/alerts/ALERT_ID/dismiss" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
19. SQL Validation Queries

Connect to PostgreSQL:

docker exec -it nixlifeos-postgres psql -U postgres -d nix_life_os

Or use your actual DB name.

19.1 Check Alerts Table
SELECT *
FROM health_alerts
ORDER BY created_at DESC
LIMIT 20;
19.2 Count Alerts By Severity
SELECT severity, COUNT(*) AS total
FROM health_alerts
GROUP BY severity
ORDER BY total DESC;
19.3 Count Alerts By Category
SELECT category, COUNT(*) AS total
FROM health_alerts
GROUP BY category
ORDER BY total DESC;
19.4 Active Alerts
SELECT id, alert_type, category, severity, status, title, alert_date
FROM health_alerts
WHERE status = 'active'
ORDER BY created_at DESC;
19.5 Nutrition Alert Check
SELECT 
    user_id,
    meal_date,
    SUM(sodium_mg) AS sodium_mg,
    SUM(potassium_mg) AS potassium_mg,
    SUM(phosphorus_mg) AS phosphorus_mg
FROM health_nutrition_logs
GROUP BY user_id, meal_date
ORDER BY meal_date DESC;
19.6 Hydration Alert Check
SELECT 
    user_id,
    log_date,
    SUM(amount_ml) AS total_water_ml
FROM health_hydration_logs
GROUP BY user_id, log_date
ORDER BY log_date DESC;
19.7 Medication Missed Dose Check
SELECT 
    user_id,
    status,
    COUNT(*) AS total
FROM health_medication_doses
GROUP BY user_id, status
ORDER BY total DESC;
19.8 Lab Abnormal Check
SELECT 
    id,
    user_id,
    test_name,
    result_value,
    unit,
    normal_min,
    normal_max,
    test_date
FROM health_lab_tests
WHERE result_value < normal_min
   OR result_value > normal_max
ORDER BY test_date DESC;
20. Testing Checklist
Backend Checklist
[ ] Migration health_alerts created.
[ ] Migration health_alert_rules created if needed.
[ ] HealthAlert model created.
[ ] HealthAlertRule model created if needed.
[ ] HealthAlertEngineService created.
[ ] Alert duplicate prevention works.
[ ] Artisan command health:generate-alerts works.
[ ] API controller created.
[ ] API routes registered.
[ ] Routes protected by Sanctum.
[ ] Alerts return only authenticated user data.
[ ] Summary endpoint returns correct counts.
[ ] Read endpoint updates read_at.
[ ] Resolve endpoint updates resolved_at.
[ ] Dismiss endpoint updates dismissed_at.
[ ] Delete endpoint removes alert.
Rule Testing Checklist
[ ] High sodium alert generated when sodium >= 1,800 mg.
[ ] Critical sodium alert generated when sodium >= 2,300 mg.
[ ] High potassium alert generated when potassium >= 2,000 mg.
[ ] Critical potassium alert generated when potassium >= 2,500 mg.
[ ] High phosphorus alert generated when phosphorus >= 800 mg.
[ ] Low hydration alert generated when hydration below 70%.
[ ] Critical hydration alert generated when hydration below 40%.
[ ] Rapid weight gain alert generated.
[ ] Rapid weight loss alert generated.
[ ] Missed medication alert generated.
[ ] Critical medication alert generated for multiple missed doses.
[ ] Abnormal lab result alert generated.
[ ] Low step alert generated.
[ ] Poor sleep trend alert generated.
[ ] Repeated unhealthy pattern alert generated.
[ ] Same alert is not duplicated for same day.
Frontend Checklist
[ ] Health Alerts route opens.
[ ] Sidebar link opens /health/alerts.
[ ] Alerts summary cards display.
[ ] Critical alert count displays.
[ ] Warning alert count displays.
[ ] Active alert count displays.
[ ] Unread alert count displays.
[ ] Filters work by status.
[ ] Filters work by severity.
[ ] Filters work by category.
[ ] Run Check button calls alerts engine.
[ ] Empty state displays when no alerts exist.
[ ] Error state displays when API fails.
[ ] Alert cards show title, message, category, severity, and date.
[ ] Mark as read works.
[ ] Resolve works.
[ ] Dismiss works.
21. Recommended Files To Create Or Update
backend/database/migrations/create_health_alerts_table.php
backend/database/migrations/create_health_alert_rules_table.php

backend/app/Models/HealthAlert.php
backend/app/Models/HealthAlertRule.php

backend/app/Services/Health/HealthAlertEngineService.php

backend/app/Console/Commands/RunHealthAlertsEngine.php

backend/app/Http/Controllers/Api/V1/HealthAlertController.php

backend/routes/api.php
backend/routes/console.php

frontend/src/services/healthAlertService.js

frontend/src/components/health/HealthAlertsPanel.vue
frontend/src/views/health/HealthAlertsView.vue

frontend/src/router/index.js
frontend/src/layouts/AppLayout.vue
22. Final Step 52 Acceptance Criteria

Step 52 is complete when:

[ ] User can run Health Alerts Engine from API.
[ ] Alerts are generated based on nutrition, hydration, medication, lab, steps, sleep, and weight data.
[ ] Alerts are stored in health_alerts table.
[ ] Alerts are visible in Vue Health Alerts page.
[ ] Alerts summary appears correctly.
[ ] Alerts can be marked as read.
[ ] Alerts can be resolved.
[ ] Alerts can be dismissed.
[ ] No duplicate alerts are generated for same user/date/type/source.
[ ] System is ready to connect Health Dashboard with active alerts.
23. Recommended Next Step

After Step 52, the next logical step is:

🔹 STEP 53 — Health Dashboard Alerts Integration

Step 53 should connect the Health Alerts Engine to the main Health Dashboard and display:

Critical alerts
Today’s warnings
Medication alerts
Lab alerts
Nutrition risk alerts
Repeated unhealthy patterns
Health score impact
#!/usr/bin/env bash

set -e

cd /u01/nix-life-os

echo "============================================================"
echo "STEP 54 — APPLY HEALTH MODULE REGRESSION FIXES"
echo "============================================================"

BACKUP_DIR="backups/step54_health_regression_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backups in: $BACKUP_DIR"

cp backend/routes/api.php "$BACKUP_DIR/api.php"
cp backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php "$BACKUP_DIR/HealthDashboardController.php"
cp backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php "$BACKUP_DIR/HealthHydrationLogController.php"
cp frontend/src/services/healthReportsService.js "$BACKUP_DIR/healthReportsService.js"
cp frontend/src/services/healthWeightApi.js "$BACKUP_DIR/healthWeightApi.js"
cp frontend/src/services/healthService.js "$BACKUP_DIR/healthService.js"

echo "============================================================"
echo "1) PATCH ROUTES"
echo "============================================================"

python3 <<'PY'
from pathlib import Path

path = Path("backend/routes/api.php")
text = path.read_text()

# Add steps summary route before /steps/{id}
if "Route::get('/steps/summary'" not in text:
    text = text.replace(
"""            Route::get('/steps', [HealthStepLogController::class, 'index']);
            Route::post('/steps', [HealthStepLogController::class, 'store']);
            Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);""",
"""            Route::get('/steps', [HealthStepLogController::class, 'index']);
            Route::post('/steps', [HealthStepLogController::class, 'store']);
            Route::get('/steps/summary', [HealthStepLogController::class, 'summary']);
            Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);"""
    )

# Add weight summary route before /weight/{id}
if "Route::get('/weight/summary'" not in text:
    text = text.replace(
"""            Route::get('/weight', [HealthWeightLogController::class, 'index']);
            Route::post('/weight', [HealthWeightLogController::class, 'store']);
            Route::get('/weight/{id}', [HealthWeightLogController::class, 'show']);""",
"""            Route::get('/weight', [HealthWeightLogController::class, 'index']);
            Route::post('/weight', [HealthWeightLogController::class, 'store']);
            Route::get('/weight/summary', [HealthWeightLogController::class, 'summary']);
            Route::get('/weight/{id}', [HealthWeightLogController::class, 'show']);"""
    )

# Add hydration summary / quick add routes before /hydration/{id}
if "Route::get('/hydration/summary/daily'" not in text:
    text = text.replace(
"""            Route::get('/hydration', [HealthHydrationLogController::class, 'index']);
            Route::post('/hydration', [HealthHydrationLogController::class, 'store']);
            Route::get('/hydration/{id}', [HealthHydrationLogController::class, 'show']);""",
"""            Route::get('/hydration', [HealthHydrationLogController::class, 'index']);
            Route::post('/hydration', [HealthHydrationLogController::class, 'store']);
            Route::get('/hydration/summary/daily', [HealthHydrationLogController::class, 'dailySummary']);
            Route::get('/hydration/summary/weekly', [HealthHydrationLogController::class, 'weeklySummary']);
            Route::post('/hydration/quick-add', [HealthHydrationLogController::class, 'quickAdd']);
            Route::get('/hydration/{id}', [HealthHydrationLogController::class, 'show']);"""
    )

path.write_text(text)
PY

echo "============================================================"
echo "2) UPDATE HEALTH DASHBOARD CONTROLLER"
echo "============================================================"

cat > backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HealthDashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();
        $userId = $user->id;
        $today = now()->toDateString();

        $steps = $this->buildStepsSummary($userId, $today);
        $weight = $this->buildWeightSummary($userId);
        $nutrition = $this->buildNutritionSummary($userId, $today);
        $hydration = $this->buildHydrationSummary($userId, $today);
        $sleep = $this->buildSleepSummary($userId);
        $mood = $this->buildMoodSummary($userId);
        $medications = $this->buildMedicationSummary($userId);
        $labTests = $this->buildLabTestSummary($userId);
        $alerts = $this->buildAlertSummary($userId);

        return response()->json([
            'success' => true,
            'message' => 'Health dashboard loaded successfully.',
            'data' => [
                'date' => $today,
                'steps' => $steps,
                'weight' => $weight,
                'nutrition' => $nutrition,
                'hydration' => $hydration,
                'sleep' => $sleep,
                'mood' => $mood,
                'medications' => $medications,
                'lab_tests' => $labTests,
                'alerts' => $alerts,
            ],
        ]);
    }

    private function buildStepsSummary(string $userId, string $today): array
    {
        $default = [
            'today_steps' => 0,
            'goal_steps' => 10000,
            'progress_percent' => 0,
            'goal_completed' => false,
            'latest_log_date' => null,
        ];

        if (! Schema::hasTable('health_step_log')) {
            return $default;
        }

        $profileGoal = 10000;

        if (Schema::hasTable('health_profile')) {
            $profile = DB::table('health_profile')
                ->where('user_id', $userId)
                ->first();

            if ($profile && isset($profile->daily_steps_goal)) {
                $profileGoal = (int) $profile->daily_steps_goal;
            }
        }

        $todayLog = DB::table('health_step_log')
            ->where('user_id', $userId)
            ->whereDate('log_date', $today)
            ->first();

        $latestLog = DB::table('health_step_log')
            ->where('user_id', $userId)
            ->orderByDesc('log_date')
            ->first();

        $steps = (int) ($todayLog->steps_count ?? 0);
        $goal = (int) ($todayLog->goal_steps ?? $profileGoal);

        return [
            'today_steps' => $steps,
            'goal_steps' => $goal,
            'progress_percent' => $goal > 0 ? round(($steps / $goal) * 100, 2) : 0,
            'goal_completed' => $goal > 0 && $steps >= $goal,
            'latest_log_date' => $latestLog?->log_date,
        ];
    }

    private function buildWeightSummary(string $userId): array
    {
        $default = [
            'latest_weight_kg' => null,
            'target_weight_kg' => null,
            'latest_date' => null,
            'bmi' => null,
            'trend_direction' => 'no_data',
        ];

        if (! Schema::hasTable('health_weight_logs')) {
            return $default;
        }

        $logs = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->orderBy('log_date')
            ->get();

        if ($logs->isEmpty()) {
            return $default;
        }

        $first = $logs->first();
        $latest = $logs->last();
        $change = ((float) $latest->weight_kg) - ((float) $first->weight_kg);

        return [
            'latest_weight_kg' => (float) $latest->weight_kg,
            'target_weight_kg' => null,
            'latest_date' => $latest->log_date,
            'bmi' => $latest->bmi !== null ? (float) $latest->bmi : null,
            'trend_direction' => match (true) {
                $change > 0 => 'increasing',
                $change < 0 => 'decreasing',
                default => 'stable',
            },
        ];
    }

    private function buildNutritionSummary(string $userId, string $today): array
    {
        $summary = [
            'calories' => 0,
            'protein_g' => 0,
            'sodium_mg' => 0,
            'potassium_mg' => 0,
            'phosphorus_mg' => 0,
            'warnings' => [],
        ];

        if (Schema::hasTable('health_nutrition_logs')) {
            $row = DB::table('health_nutrition_logs')
                ->where('user_id', $userId)
                ->whereDate('meal_date', $today)
                ->selectRaw('
                    COALESCE(SUM(calories), 0) as calories,
                    COALESCE(SUM(protein), 0) as protein_g,
                    COALESCE(SUM(sodium), 0) as sodium_mg,
                    COALESCE(SUM(potassium), 0) as potassium_mg,
                    COALESCE(SUM(phosphorus), 0) as phosphorus_mg
                ')
                ->first();

            if ($row) {
                $summary['calories'] += (float) $row->calories;
                $summary['protein_g'] += (float) $row->protein_g;
                $summary['sodium_mg'] += (float) $row->sodium_mg;
                $summary['potassium_mg'] += (float) $row->potassium_mg;
                $summary['phosphorus_mg'] += (float) $row->phosphorus_mg;
            }
        }

        if (Schema::hasTable('health_meal_logs')) {
            $row = DB::table('health_meal_logs')
                ->where('user_id', $userId)
                ->whereDate('meal_date', $today)
                ->selectRaw('
                    COALESCE(SUM(total_calories), 0) as calories,
                    COALESCE(SUM(total_protein_g), 0) as protein_g,
                    COALESCE(SUM(total_sodium_mg), 0) as sodium_mg,
                    COALESCE(SUM(total_potassium_mg), 0) as potassium_mg,
                    COALESCE(SUM(total_phosphorus_mg), 0) as phosphorus_mg
                ')
                ->first();

            if ($row) {
                $summary['calories'] += (float) $row->calories;
                $summary['protein_g'] += (float) $row->protein_g;
                $summary['sodium_mg'] += (float) $row->sodium_mg;
                $summary['potassium_mg'] += (float) $row->potassium_mg;
                $summary['phosphorus_mg'] += (float) $row->phosphorus_mg;
            }
        }

        $summary['warnings'] = $this->buildNutritionWarnings($summary);

        return $summary;
    }

    private function buildHydrationSummary(string $userId, string $today): array
    {
        $goalMl = 1500;

        if (! Schema::hasTable('health_hydration_logs')) {
            return [
                'today_ml' => 0,
                'goal_ml' => $goalMl,
                'progress_percent' => 0,
                'entries_count' => 0,
            ];
        }

        $row = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', $today)
            ->selectRaw('COALESCE(SUM(amount_ml), 0) as total_ml, COUNT(*) as entries_count')
            ->first();

        $totalMl = (float) ($row->total_ml ?? 0);

        return [
            'today_ml' => $totalMl,
            'goal_ml' => $goalMl,
            'progress_percent' => $goalMl > 0 ? round(($totalMl / $goalMl) * 100, 2) : 0,
            'entries_count' => (int) ($row->entries_count ?? 0),
        ];
    }

    private function buildSleepSummary(string $userId): array
    {
        $default = [
            'latest_sleep_hours' => null,
            'sleep_quality' => null,
            'latest_date' => null,
            'weekly_average_hours' => 0,
        ];

        if (! Schema::hasTable('health_sleep_logs')) {
            return $default;
        }

        $latest = DB::table('health_sleep_logs')
            ->where('user_id', $userId)
            ->orderByDesc('sleep_date')
            ->first();

        $weekStart = now()->subDays(6)->toDateString();

        $weeklyAverageMinutes = DB::table('health_sleep_logs')
            ->where('user_id', $userId)
            ->whereDate('sleep_date', '>=', $weekStart)
            ->avg('duration_minutes');

        return [
            'latest_sleep_hours' => $latest ? round(((float) $latest->duration_minutes) / 60, 2) : null,
            'sleep_quality' => $latest?->quality_score,
            'latest_date' => $latest?->sleep_date,
            'weekly_average_hours' => $weeklyAverageMinutes ? round(((float) $weeklyAverageMinutes) / 60, 2) : 0,
        ];
    }

    private function buildMoodSummary(string $userId): array
    {
        $default = [
            'latest_mood' => null,
            'mood_score' => null,
            'latest_date' => null,
        ];

        if (! Schema::hasTable('health_mood_logs')) {
            return $default;
        }

        $latest = DB::table('health_mood_logs')
            ->where('user_id', $userId)
            ->orderByDesc('mood_date')
            ->first();

        if (! $latest) {
            return $default;
        }

        return [
            'latest_mood' => $latest->mood_label,
            'mood_score' => (int) $latest->mood_score,
            'latest_date' => $latest->mood_date,
        ];
    }

    private function buildMedicationSummary(string $userId): array
    {
        $summary = [
            'active_count' => 0,
            'today_pending_count' => 0,
            'today_taken_count' => 0,
            'today_skipped_count' => 0,
        ];

        if (Schema::hasTable('health_medications')) {
            $summary['active_count'] = DB::table('health_medications')
                ->where('user_id', $userId)
                ->where('status', 'active')
                ->whereNull('deleted_at')
                ->count();
        }

        if (Schema::hasTable('health_medication_dose_logs')) {
            $today = now()->toDateString();

            $logs = DB::table('health_medication_dose_logs')
                ->where('user_id', $userId)
                ->whereDate('scheduled_for', $today)
                ->selectRaw("
                    COALESCE(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END), 0) as pending_count,
                    COALESCE(SUM(CASE WHEN status IN ('taken', 'late') THEN 1 ELSE 0 END), 0) as taken_count,
                    COALESCE(SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END), 0) as skipped_count
                ")
                ->first();

            $summary['today_pending_count'] = (int) ($logs->pending_count ?? 0);
            $summary['today_taken_count'] = (int) ($logs->taken_count ?? 0);
            $summary['today_skipped_count'] = (int) ($logs->skipped_count ?? 0);
        }

        return $summary;
    }

    private function buildLabTestSummary(string $userId): array
    {
        if (! Schema::hasTable('health_lab_tests')) {
            return [
                'latest' => [],
                'abnormal_count' => 0,
            ];
        }

        $latest = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->orderByDesc('test_date')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $abnormalCount = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->where('is_abnormal', true)
            ->count();

        return [
            'latest' => $latest,
            'abnormal_count' => $abnormalCount,
        ];
    }

    private function buildAlertSummary(string $userId): array
    {
        if (! Schema::hasTable('health_alerts')) {
            return [
                'active_count' => 0,
                'critical_count' => 0,
                'warning_count' => 0,
                'unread_count' => 0,
            ];
        }

        return [
            'active_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->count(),
            'critical_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->where('severity', 'critical')->count(),
            'warning_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->where('severity', 'warning')->count(),
            'unread_count' => DB::table('health_alerts')->where('user_id', $userId)->whereNull('read_at')->count(),
        ];
    }

    private function buildNutritionWarnings(array $summary): array
    {
        $limits = [
            'protein_g' => ['label' => 'Protein', 'limit' => 45],
            'sodium_mg' => ['label' => 'Sodium', 'limit' => 2000],
            'potassium_mg' => ['label' => 'Potassium', 'limit' => 2000],
            'phosphorus_mg' => ['label' => 'Phosphorus', 'limit' => 800],
        ];

        $warnings = [];

        foreach ($limits as $key => $config) {
            $value = (float) ($summary[$key] ?? 0);
            $limit = (float) $config['limit'];

            if ($limit <= 0) {
                continue;
            }

            $percent = ($value / $limit) * 100;

            if ($percent >= 100) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $config['label'],
                    'status' => 'exceeded',
                    'message' => "{$config['label']} limit exceeded.",
                    'percentage' => round($percent, 2),
                ];
            } elseif ($percent >= 80) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $config['label'],
                    'status' => 'warning',
                    'message' => "{$config['label']} is close to daily limit.",
                    'percentage' => round($percent, 2),
                ];
            }
        }

        return $warnings;
    }
}
PHP

echo "============================================================"
echo "3) UPDATE HYDRATION CONTROLLER"
echo "============================================================"

cat > backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreHealthHydrationLogRequest;
use App\Http\Requests\UpdateHealthHydrationLogRequest;
use App\Http\Resources\HealthHydrationLogResource;
use App\Models\HealthHydrationLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HealthHydrationLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = HealthHydrationLog::query()
            ->where('user_id', $request->user()->id);

        if ($request->filled('date')) {
            $query->whereDate('log_date', $request->date);
        }

        if ($request->filled('from_date')) {
            $query->whereDate('log_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('log_date', '<=', $request->to_date);
        }

        if ($request->filled('drink_type')) {
            $query->where('drink_type', $request->drink_type);
        }

        $logs = $query
            ->orderByDesc('log_date')
            ->orderByDesc('log_time')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'message' => 'Hydration logs retrieved successfully.',
            'data' => HealthHydrationLogResource::collection($logs)->response()->getData(true),
        ]);
    }

    public function store(StoreHealthHydrationLogRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $log = HealthHydrationLog::create([
            'user_id' => $request->user()->id,
            'log_date' => $validated['log_date'],
            'log_time' => $validated['log_time'] ?? now()->format('H:i:s'),
            'drink_type' => $validated['drink_type'],
            'amount_ml' => $validated['amount_ml'],
            'is_ckd_safe' => $validated['is_ckd_safe'] ?? true,
            'source' => $validated['source'] ?? 'manual',
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Hydration log created successfully.',
            'data' => new HealthHydrationLogResource($log),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log retrieved successfully.',
            'data' => new HealthHydrationLogResource($log),
        ]);
    }

    public function update(UpdateHealthHydrationLogRequest $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->update($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Hydration log updated successfully.',
            'data' => new HealthHydrationLogResource($log->fresh()),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log deleted successfully.',
        ]);
    }

    public function dailySummary(Request $request): JsonResponse
    {
        $user = $request->user();
        $date = $request->get('date', now()->toDateString());
        $goalMl = (int) $request->get('goal_ml', 1500);

        $totalMl = HealthHydrationLog::where('user_id', $user->id)
            ->whereDate('log_date', $date)
            ->sum('amount_ml');

        $breakdown = HealthHydrationLog::select(
                'drink_type',
                DB::raw('SUM(amount_ml) as total_ml'),
                DB::raw('COUNT(*) as entries_count')
            )
            ->where('user_id', $user->id)
            ->whereDate('log_date', $date)
            ->groupBy('drink_type')
            ->orderByDesc('total_ml')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daily hydration summary retrieved successfully.',
            'data' => [
                'date' => $date,
                'total_ml' => (float) $totalMl,
                'total_liters' => round(((float) $totalMl) / 1000, 2),
                'goal_ml' => $goalMl,
                'progress_percent' => $goalMl > 0 ? round(((float) $totalMl / $goalMl) * 100, 2) : 0,
                'breakdown' => $breakdown->map(function ($item) {
                    return [
                        'drink_type' => $item->drink_type,
                        'total_ml' => (float) $item->total_ml,
                        'entries_count' => (int) $item->entries_count,
                    ];
                })->values(),
            ],
        ]);
    }

    public function weeklySummary(Request $request): JsonResponse
    {
        $user = $request->user();

        $startDate = $request->get('start_date', now()->startOfWeek()->toDateString());
        $endDate = $request->get('end_date', now()->endOfWeek()->toDateString());

        $rows = HealthHydrationLog::select(
                'log_date',
                DB::raw('SUM(amount_ml) as total_ml'),
                DB::raw('COUNT(*) as entries_count')
            )
            ->where('user_id', $user->id)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->groupBy('log_date')
            ->orderBy('log_date')
            ->get();

        $totalMl = $rows->sum('total_ml');
        $daysCount = max(1, Carbon::parse($startDate)->diffInDays(Carbon::parse($endDate)) + 1);

        return response()->json([
            'success' => true,
            'message' => 'Weekly hydration summary retrieved successfully.',
            'data' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'total_ml' => (float) $totalMl,
                'average_daily_ml' => round(((float) $totalMl) / $daysCount, 2),
                'days' => $rows->map(function ($item) {
                    return [
                        'log_date' => Carbon::parse($item->log_date)->format('Y-m-d'),
                        'total_ml' => (float) $item->total_ml,
                        'total_liters' => round(((float) $item->total_ml) / 1000, 2),
                        'entries_count' => (int) $item->entries_count,
                    ];
                })->values(),
            ],
        ]);
    }

    public function quickAdd(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount_ml' => ['required', 'numeric', 'min:1', 'max:5000'],
            'drink_type' => ['nullable', 'string', 'max:50', 'in:water,tea,coffee,juice,soup,milk,other'],
            'log_date' => ['nullable', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
        ]);

        $log = HealthHydrationLog::create([
            'user_id' => $request->user()->id,
            'log_date' => $validated['log_date'] ?? now()->toDateString(),
            'log_time' => $validated['log_time'] ?? now()->format('H:i:s'),
            'drink_type' => $validated['drink_type'] ?? 'water',
            'amount_ml' => $validated['amount_ml'],
            'is_ckd_safe' => true,
            'source' => 'quick_add',
            'notes' => 'Quick add hydration entry',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Quick hydration entry added successfully.',
            'data' => new HealthHydrationLogResource($log),
        ], 201);
    }
}
PHP

echo "============================================================"
echo "4) UPDATE FRONTEND REPORTS SERVICE"
echo "============================================================"

cat > frontend/src/services/healthReportsService.js <<'JS'
import api from './api'

export const healthReportsService = {
  getDailyReport(date) {
    return api.get('/health/reports/daily', {
      params: { date }
    })
  },

  getWeeklyReport(startDate, endDate) {
    return api.get('/health/reports/weekly', {
      params: {
        start_date: startDate,
        end_date: endDate
      }
    })
  },

  getMonthlyReport(month) {
    return api.get('/health/reports/monthly', {
      params: { month }
    })
  },

  getExportPreview(period, date, month) {
    return api.get('/health/reports/export-preview', {
      params: {
        period,
        date,
        month
      }
    })
  }
}

export default healthReportsService
JS

echo "============================================================"
echo "5) UPDATE FRONTEND WEIGHT API"
echo "============================================================"

cat > frontend/src/services/healthWeightApi.js <<'JS'
const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  "http://127.0.0.1:8000/api/v1";

function getToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token")
  );
}

async function request(path, options = {}) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw data;
  }

  return data;
}

export const healthWeightApi = {
  getLogs(params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/health/weight${query ? `?${query}` : ""}`);
  },

  getSummary(params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/health/weight/summary${query ? `?${query}` : ""}`);
  },

  createLog(payload) {
    return request("/health/weight", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  updateLog(id, payload) {
    return request(`/health/weight/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },

  deleteLog(id) {
    return request(`/health/weight/${id}`, {
      method: "DELETE",
    });
  },
};

export default healthWeightApi;
JS

echo "============================================================"
echo "6) UPDATE FRONTEND HEALTH SERVICE"
echo "============================================================"

cat > frontend/src/services/healthService.js <<'JS'
import api from "./api";

const healthService = {
  dashboard() {
    return api.get("/health/dashboard");
  },

  steps: {
    list(params = {}) {
      return api.get("/health/steps", { params });
    },
    summary(params = {}) {
      return api.get("/health/steps/summary", { params });
    },
    create(payload) {
      return api.post("/health/steps", payload);
    },
    update(id, payload) {
      return api.put(`/health/steps/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/steps/${id}`);
    },
  },

  weight: {
    list(params = {}) {
      return api.get("/health/weight", { params });
    },
    summary(params = {}) {
      return api.get("/health/weight/summary", { params });
    },
    create(payload) {
      return api.post("/health/weight", payload);
    },
    update(id, payload) {
      return api.put(`/health/weight/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/weight/${id}`);
    },
  },

  nutrition: {
    list(params = {}) {
      return api.get("/health/nutrition", { params });
    },
    summary(params = {}) {
      return api.get("/health/nutrition/summary", { params });
    },
    create(payload) {
      return api.post("/health/nutrition", payload);
    },
    update(id, payload) {
      return api.put(`/health/nutrition/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/nutrition/${id}`);
    },
  },

  hydration: {
    list(params = {}) {
      return api.get("/health/hydration", { params });
    },
    dailySummary(params = {}) {
      return api.get("/health/hydration/summary/daily", { params });
    },
    weeklySummary(params = {}) {
      return api.get("/health/hydration/summary/weekly", { params });
    },
    quickAdd(payload) {
      return api.post("/health/hydration/quick-add", payload);
    },
    create(payload) {
      return api.post("/health/hydration", payload);
    },
    update(id, payload) {
      return api.put(`/health/hydration/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/hydration/${id}`);
    },
  },

  sleep: {
    list(params = {}) {
      return api.get("/health/sleep", { params });
    },
    create(payload) {
      return api.post("/health/sleep", payload);
    },
    update(id, payload) {
      return api.put(`/health/sleep/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/sleep/${id}`);
    },
  },

  mood: {
    list(params = {}) {
      return api.get("/health/mood", { params });
    },
    create(payload) {
      return api.post("/health/mood", payload);
    },
    update(id, payload) {
      return api.put(`/health/mood/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/mood/${id}`);
    },
  },

  medications: {
    list(params = {}) {
      return api.get("/health/medications", { params });
    },
    create(payload) {
      return api.post("/health/medications", payload);
    },
    update(id, payload) {
      return api.put(`/health/medications/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/medications/${id}`);
    },
  },

  medicationReminders: {
    list(params = {}) {
      return api.get("/health/medication-reminders", { params });
    },
    today(params = {}) {
      return api.get("/health/medication-reminders/today", { params });
    },
    create(payload) {
      return api.post("/health/medication-reminders", payload);
    },
    update(id, payload) {
      return api.put(`/health/medication-reminders/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/medication-reminders/${id}`);
    },
  },

  medicationDoses: {
    history(params = {}) {
      return api.get("/health/medication-doses/history", { params });
    },
    markTaken(id) {
      return api.post(`/health/medication-doses/${id}/taken`);
    },
    markSkipped(id, payload = {}) {
      return api.post(`/health/medication-doses/${id}/skipped`, payload);
    },
  },

  labTests: {
    categories() {
      return api.get("/health/lab-tests/categories");
    },
    list(params = {}) {
      return api.get("/health/lab-tests", { params });
    },
    show(id) {
      return api.get(`/health/lab-tests/${id}`);
    },
    create(payload) {
      return api.post("/health/lab-tests", payload);
    },
    update(id, payload) {
      return api.put(`/health/lab-tests/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/lab-tests/${id}`);
    },
    trends(params = {}) {
      return api.get("/health/lab-tests/trends", { params });
    },
  },

  alerts: {
    list(params = {}) {
      return api.get("/health/alerts", { params });
    },
    summary(params = {}) {
      return api.get("/health/alerts/summary", { params });
    },
    run(payload = {}) {
      return api.post("/health/alerts/run", payload);
    },
    markRead(id) {
      return api.patch(`/health/alerts/${id}/read`);
    },
    resolve(id) {
      return api.patch(`/health/alerts/${id}/resolve`);
    },
    dismiss(id) {
      return api.patch(`/health/alerts/${id}/dismiss`);
    },
    delete(id) {
      return api.delete(`/health/alerts/${id}`);
    },
  },

  reports: {
    daily(params = {}) {
      return api.get("/health/reports/daily", { params });
    },
    weekly(params = {}) {
      return api.get("/health/reports/weekly", { params });
    },
    monthly(params = {}) {
      return api.get("/health/reports/monthly", { params });
    },
    exportPreview(params = {}) {
      return api.get("/health/reports/export-preview", { params });
    },
  },

  nutritionFacts: {
    categories() {
      return api.get("/nutrition/categories");
    },
    foods(params = {}) {
      return api.get("/nutrition/foods", { params });
    },
    search(params = {}) {
      return api.get("/nutrition/foods/search", { params });
    },
    show(id) {
      return api.get(`/nutrition/foods/${id}`);
    },
    servings(id) {
      return api.get(`/nutrition/foods/${id}/servings`);
    },
    autofill(payload) {
      return api.post("/nutrition/foods/autofill", payload);
    },
    customFoods(params = {}) {
      return api.get("/nutrition/custom-foods", { params });
    },
    createCustomFood(payload) {
      return api.post("/nutrition/custom-foods", payload);
    },
    updateCustomFood(id, payload) {
      return api.put(`/nutrition/custom-foods/${id}`, payload);
    },
    deleteCustomFood(id) {
      return api.delete(`/nutrition/custom-foods/${id}`);
    },
  },
};

export default healthService;
JS

echo "============================================================"
echo "7) VALIDATE PHP SYNTAX"
echo "============================================================"

cd backend

php -l routes/api.php
php -l app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
php -l app/Http/Controllers/Api/V1/HealthHydrationLogController.php

echo "============================================================"
echo "8) CLEAR LARAVEL CACHE"
echo "============================================================"

php artisan optimize:clear

echo "============================================================"
echo "9) SHOW NEW HEALTH ROUTES"
echo "============================================================"

php artisan route:list | grep -Ei "health/steps/summary|health/weight/summary|health/hydration/summary|health/hydration/quick-add|health/dashboard|health/reports"

cd ..

echo "============================================================"
echo "10) FRONTEND BUILD CHECK"
echo "============================================================"

cd frontend
npm run build
cd ..

echo "============================================================"
echo "STEP 54 FIXES APPLIED SUCCESSFULLY"
echo "Backup folder: $BACKUP_DIR"
echo "============================================================"

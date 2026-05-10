🔹 STEP 53 — Health Reports Screen
Nix Life OS — Daily / Weekly / Monthly Health Reports

You are now building a Health Reports screen that aggregates all health data into one reporting page.

This screen should summarize:

Daily health summary
Weekly health summary
Monthly health summary
Nutrition totals
Hydration totals
Weight trend
Steps trend
Lab results trend
Medication adherence
Export-ready structure for future PDF reports
1. Goal of Step 53

The Health Reports screen will become the central health analytics screen in Nix Life OS.

It should answer questions like:

How was my health today?
How was my week?
How was my month?
Am I drinking enough water?
Am I following my medication schedule?
Is my weight improving?
Are my lab results improving or worsening?
Are my nutrition totals safe for CKD limits?
2. Recommended Backend Route Structure

Add these API endpoints:

GET /api/v1/health/reports/daily
GET /api/v1/health/reports/weekly
GET /api/v1/health/reports/monthly
GET /api/v1/health/reports/export-preview

Recommended query filters:

/api/v1/health/reports/daily?date=2026-05-11
/api/v1/health/reports/weekly?start_date=2026-05-05&end_date=2026-05-11
/api/v1/health/reports/monthly?month=2026-05
3. Backend Files to Create

Create these files:

backend/app/Http/Controllers/Api/V1/HealthReportController.php
backend/app/Services/Health/HealthReportService.php

Optional but recommended later:

backend/app/Http/Resources/HealthReportResource.php
backend/app/Exports/HealthReportExport.php
4. Add Routes in routes/api.php

Inside your authenticated v1 health route group, add:

use App\Http\Controllers\Api\V1\HealthReportController;

Route::prefix('health')->middleware('auth:sanctum')->group(function () {
    Route::get('/reports/daily', [HealthReportController::class, 'daily']);
    Route::get('/reports/weekly', [HealthReportController::class, 'weekly']);
    Route::get('/reports/monthly', [HealthReportController::class, 'monthly']);
    Route::get('/reports/export-preview', [HealthReportController::class, 'exportPreview']);
});

If your api.php already has:

Route::prefix('v1')->group(function () {
    Route::middleware('auth:sanctum')->group(function () {
        Route::prefix('health')->group(function () {

Then add only this inside the existing health group:

Route::get('/reports/daily', [HealthReportController::class, 'daily']);
Route::get('/reports/weekly', [HealthReportController::class, 'weekly']);
Route::get('/reports/monthly', [HealthReportController::class, 'monthly']);
Route::get('/reports/export-preview', [HealthReportController::class, 'exportPreview']);
5. HealthReportController.php

Create:

nano app/Http/Controllers/Api/V1/HealthReportController.php

Paste:

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Health\HealthReportService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HealthReportController extends Controller
{
    public function __construct(
        private readonly HealthReportService $healthReportService
    ) {
    }

    public function daily(Request $request)
    {
        $userId = Auth::id();

        $date = $request->query('date', now()->toDateString());

        $data = $this->healthReportService->dailyReport($userId, $date);

        return response()->json([
            'success' => true,
            'message' => 'Daily health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function weekly(Request $request)
    {
        $userId = Auth::id();

        $startDate = $request->query('start_date', now()->startOfWeek()->toDateString());
        $endDate = $request->query('end_date', now()->endOfWeek()->toDateString());

        $data = $this->healthReportService->weeklyReport($userId, $startDate, $endDate);

        return response()->json([
            'success' => true,
            'message' => 'Weekly health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function monthly(Request $request)
    {
        $userId = Auth::id();

        $month = $request->query('month', now()->format('Y-m'));

        $data = $this->healthReportService->monthlyReport($userId, $month);

        return response()->json([
            'success' => true,
            'message' => 'Monthly health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function exportPreview(Request $request)
    {
        $userId = Auth::id();

        $period = $request->query('period', 'monthly');
        $date = $request->query('date', now()->toDateString());
        $month = $request->query('month', now()->format('Y-m'));

        $data = $this->healthReportService->exportPreview($userId, $period, $date, $month);

        return response()->json([
            'success' => true,
            'message' => 'Export-ready health report preview loaded successfully.',
            'data' => $data,
        ]);
    }
}
6. HealthReportService.php

Create folder if needed:

mkdir -p app/Services/Health
nano app/Services/Health/HealthReportService.php

Paste:

<?php

namespace App\Services\Health;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class HealthReportService
{
    public function dailyReport(string $userId, string $date): array
    {
        return [
            'period' => [
                'type' => 'daily',
                'date' => $date,
            ],
            'summary' => $this->summary($userId, $date, $date),
            'nutrition' => $this->nutritionTotals($userId, $date, $date),
            'hydration' => $this->hydrationTotals($userId, $date, $date),
            'weight' => $this->weightTrend($userId, $date, $date),
            'steps' => $this->stepsTrend($userId, $date, $date),
            'lab_results' => $this->labResultsTrend($userId, $date, $date),
            'medication_adherence' => $this->medicationAdherence($userId, $date, $date),
            'export_ready' => true,
        ];
    }

    public function weeklyReport(string $userId, string $startDate, string $endDate): array
    {
        return [
            'period' => [
                'type' => 'weekly',
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'summary' => $this->summary($userId, $startDate, $endDate),
            'nutrition' => $this->nutritionTotals($userId, $startDate, $endDate),
            'hydration' => $this->hydrationTotals($userId, $startDate, $endDate),
            'weight' => $this->weightTrend($userId, $startDate, $endDate),
            'steps' => $this->stepsTrend($userId, $startDate, $endDate),
            'lab_results' => $this->labResultsTrend($userId, $startDate, $endDate),
            'medication_adherence' => $this->medicationAdherence($userId, $startDate, $endDate),
            'export_ready' => true,
        ];
    }

    public function monthlyReport(string $userId, string $month): array
    {
        $startDate = Carbon::parse($month . '-01')->startOfMonth()->toDateString();
        $endDate = Carbon::parse($month . '-01')->endOfMonth()->toDateString();

        return [
            'period' => [
                'type' => 'monthly',
                'month' => $month,
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'summary' => $this->summary($userId, $startDate, $endDate),
            'nutrition' => $this->nutritionTotals($userId, $startDate, $endDate),
            'hydration' => $this->hydrationTotals($userId, $startDate, $endDate),
            'weight' => $this->weightTrend($userId, $startDate, $endDate),
            'steps' => $this->stepsTrend($userId, $startDate, $endDate),
            'lab_results' => $this->labResultsTrend($userId, $startDate, $endDate),
            'medication_adherence' => $this->medicationAdherence($userId, $startDate, $endDate),
            'export_ready' => true,
        ];
    }

    public function exportPreview(string $userId, string $period, string $date, string $month): array
    {
        if ($period === 'daily') {
            $report = $this->dailyReport($userId, $date);
        } elseif ($period === 'weekly') {
            $startDate = Carbon::parse($date)->startOfWeek()->toDateString();
            $endDate = Carbon::parse($date)->endOfWeek()->toDateString();
            $report = $this->weeklyReport($userId, $startDate, $endDate);
        } else {
            $report = $this->monthlyReport($userId, $month);
        }

        return [
            'report_title' => 'Nix Life OS Health Report',
            'generated_at' => now()->toDateTimeString(),
            'prepared_for_user_id' => $userId,
            'report' => $report,
            'pdf_sections' => [
                'cover',
                'health_summary',
                'nutrition_summary',
                'hydration_summary',
                'weight_trend',
                'steps_trend',
                'lab_results_trend',
                'medication_adherence',
                'doctor_notes_placeholder',
            ],
        ];
    }

    private function summary(string $userId, string $startDate, string $endDate): array
    {
        $nutrition = $this->nutritionTotals($userId, $startDate, $endDate);
        $hydration = $this->hydrationTotals($userId, $startDate, $endDate);
        $medication = $this->medicationAdherence($userId, $startDate, $endDate);

        return [
            'total_calories' => $nutrition['totals']['calories'],
            'total_water_ml' => $hydration['total_water_ml'],
            'medication_adherence_percent' => $medication['adherence_percent'],
            'health_status' => $this->calculateHealthStatus(
                $nutrition['totals']['sodium_mg'],
                $hydration['total_water_ml'],
                $medication['adherence_percent']
            ),
        ];
    }

    private function nutritionTotals(string $userId, string $startDate, string $endDate): array
    {
        $row = DB::table('health_nutrition_logs')
            ->where('user_id', $userId)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->selectRaw('
                COALESCE(SUM(calories), 0) as calories,
                COALESCE(SUM(protein_g), 0) as protein_g,
                COALESCE(SUM(carbs_g), 0) as carbs_g,
                COALESCE(SUM(fat_g), 0) as fat_g,
                COALESCE(SUM(sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(phosphorus_mg), 0) as phosphorus_mg
            ')
            ->first();

        return [
            'totals' => [
                'calories' => (float) $row->calories,
                'protein_g' => (float) $row->protein_g,
                'carbs_g' => (float) $row->carbs_g,
                'fat_g' => (float) $row->fat_g,
                'sodium_mg' => (float) $row->sodium_mg,
                'potassium_mg' => (float) $row->potassium_mg,
                'phosphorus_mg' => (float) $row->phosphorus_mg,
            ],
            'ckd_warnings' => [
                'high_sodium' => (float) $row->sodium_mg > 2000,
                'high_potassium' => (float) $row->potassium_mg > 2500,
                'high_phosphorus' => (float) $row->phosphorus_mg > 1000,
                'high_protein' => (float) $row->protein_g > 60,
            ],
        ];
    }

    private function hydrationTotals(string $userId, string $startDate, string $endDate): array
    {
        $total = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->sum('amount_ml');

        return [
            'total_water_ml' => (int) $total,
            'total_water_liters' => round($total / 1000, 2),
        ];
    }

    private function weightTrend(string $userId, string $startDate, string $endDate): array
    {
        $items = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->orderBy('log_date')
            ->get([
                'log_date',
                'weight_kg',
            ]);

        return [
            'items' => $items,
            'start_weight' => $items->first()->weight_kg ?? null,
            'latest_weight' => $items->last()->weight_kg ?? null,
            'change_kg' => $items->count() >= 2
                ? round($items->last()->weight_kg - $items->first()->weight_kg, 2)
                : null,
        ];
    }

    private function stepsTrend(string $userId, string $startDate, string $endDate): array
    {
        $items = DB::table('health_step_logs')
            ->where('user_id', $userId)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->orderBy('log_date')
            ->get([
                'log_date',
                'steps',
            ]);

        return [
            'items' => $items,
            'total_steps' => (int) $items->sum('steps'),
            'average_steps' => $items->count() > 0 ? round($items->avg('steps')) : 0,
        ];
    }

    private function labResultsTrend(string $userId, string $startDate, string $endDate): array
    {
        $items = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->whereBetween('test_date', [$startDate, $endDate])
            ->orderBy('test_date')
            ->get([
                'test_date',
                'test_name',
                'result_value',
                'unit',
                'reference_range',
                'status',
            ]);

        return [
            'items' => $items,
            'total_tests' => $items->count(),
            'abnormal_tests' => $items->where('status', 'abnormal')->count(),
        ];
    }

    private function medicationAdherence(string $userId, string $startDate, string $endDate): array
    {
        $totalDoses = DB::table('health_medication_dose_logs')
            ->where('user_id', $userId)
            ->whereBetween('dose_date', [$startDate, $endDate])
            ->count();

        $takenDoses = DB::table('health_medication_dose_logs')
            ->where('user_id', $userId)
            ->whereBetween('dose_date', [$startDate, $endDate])
            ->where('status', 'taken')
            ->count();

        $missedDoses = DB::table('health_medication_dose_logs')
            ->where('user_id', $userId)
            ->whereBetween('dose_date', [$startDate, $endDate])
            ->where('status', 'missed')
            ->count();

        $adherencePercent = $totalDoses > 0
            ? round(($takenDoses / $totalDoses) * 100, 2)
            : 0;

        return [
            'total_doses' => $totalDoses,
            'taken_doses' => $takenDoses,
            'missed_doses' => $missedDoses,
            'adherence_percent' => $adherencePercent,
        ];
    }

    private function calculateHealthStatus(float $sodiumMg, int $waterMl, float $medicationAdherence): string
    {
        if ($sodiumMg > 2500 || $medicationAdherence < 60) {
            return 'Needs Attention';
        }

        if ($sodiumMg > 2000 || $waterMl < 1000 || $medicationAdherence < 80) {
            return 'Moderate';
        }

        return 'Good';
    }
}
7. Important Table Name Check

Before using the service, verify your real table names:

cd /u01/nix-life-os/backend

php artisan tinker

Then run:

Schema::hasTable('health_nutrition_logs');
Schema::hasTable('health_hydration_logs');
Schema::hasTable('health_weight_logs');
Schema::hasTable('health_step_logs');
Schema::hasTable('health_lab_tests');
Schema::hasTable('health_medication_dose_logs');

If one returns false, check actual tables:

docker exec -it nixlifeos-postgres psql -U postgres -d nix_life_os

Then:

\dt

Or:

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE 'health%';
8. Expected API Response Example

Daily report:

{
  "success": true,
  "message": "Daily health report loaded successfully.",
  "data": {
    "period": {
      "type": "daily",
      "date": "2026-05-11"
    },
    "summary": {
      "total_calories": 1450,
      "total_water_ml": 1600,
      "medication_adherence_percent": 100,
      "health_status": "Good"
    },
    "nutrition": {
      "totals": {
        "calories": 1450,
        "protein_g": 45,
        "carbs_g": 180,
        "fat_g": 50,
        "sodium_mg": 1500,
        "potassium_mg": 2100,
        "phosphorus_mg": 850
      },
      "ckd_warnings": {
        "high_sodium": false,
        "high_potassium": false,
        "high_phosphorus": false,
        "high_protein": false
      }
    },
    "hydration": {
      "total_water_ml": 1600,
      "total_water_liters": 1.6
    },
    "weight": {
      "items": [],
      "start_weight": null,
      "latest_weight": null,
      "change_kg": null
    },
    "steps": {
      "items": [],
      "total_steps": 0,
      "average_steps": 0
    },
    "lab_results": {
      "items": [],
      "total_tests": 0,
      "abnormal_tests": 0
    },
    "medication_adherence": {
      "total_doses": 3,
      "taken_doses": 3,
      "missed_doses": 0,
      "adherence_percent": 100
    },
    "export_ready": true
  }
}
9. Backend Testing Commands

Run:

cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan route:list | grep reports

Expected routes:

GET api/v1/health/reports/daily
GET api/v1/health/reports/weekly
GET api/v1/health/reports/monthly
GET api/v1/health/reports/export-preview

Test daily report:

curl -i "http://127.0.0.1:8000/api/v1/health/reports/daily?date=2026-05-11" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Test weekly report:

curl -i "http://127.0.0.1:8000/api/v1/health/reports/weekly?start_date=2026-05-05&end_date=2026-05-11" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Test monthly report:

curl -i "http://127.0.0.1:8000/api/v1/health/reports/monthly?month=2026-05" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Test export preview:

curl -i "http://127.0.0.1:8000/api/v1/health/reports/export-preview?period=monthly&month=2026-05" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
10. SQL Validation Queries

Replace the user ID with your real authenticated user UUID.

SELECT id, name, email
FROM users;
Nutrition totals
SELECT
    SUM(calories) AS total_calories,
    SUM(protein_g) AS total_protein_g,
    SUM(carbs_g) AS total_carbs_g,
    SUM(fat_g) AS total_fat_g,
    SUM(sodium_mg) AS total_sodium_mg,
    SUM(potassium_mg) AS total_potassium_mg,
    SUM(phosphorus_mg) AS total_phosphorus_mg
FROM health_nutrition_logs
WHERE user_id = 'USER_ID_HERE'
AND log_date BETWEEN '2026-05-01' AND '2026-05-31';
Hydration totals
SELECT
    SUM(amount_ml) AS total_water_ml,
    ROUND(SUM(amount_ml) / 1000.0, 2) AS total_water_liters
FROM health_hydration_logs
WHERE user_id = 'USER_ID_HERE'
AND log_date BETWEEN '2026-05-01' AND '2026-05-31';
Weight trend
SELECT log_date, weight_kg
FROM health_weight_logs
WHERE user_id = 'USER_ID_HERE'
AND log_date BETWEEN '2026-05-01' AND '2026-05-31'
ORDER BY log_date;
Steps trend
SELECT
    log_date,
    steps
FROM health_step_logs
WHERE user_id = 'USER_ID_HERE'
AND log_date BETWEEN '2026-05-01' AND '2026-05-31'
ORDER BY log_date;
Lab results trend
SELECT
    test_date,
    test_name,
    result_value,
    unit,
    reference_range,
    status
FROM health_lab_tests
WHERE user_id = 'USER_ID_HERE'
AND test_date BETWEEN '2026-05-01' AND '2026-05-31'
ORDER BY test_date;
Medication adherence
SELECT
    COUNT(*) AS total_doses,
    COUNT(*) FILTER (WHERE status = 'taken') AS taken_doses,
    COUNT(*) FILTER (WHERE status = 'missed') AS missed_doses,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'taken') * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS adherence_percent
FROM health_medication_dose_logs
WHERE user_id = 'USER_ID_HERE'
AND dose_date BETWEEN '2026-05-01' AND '2026-05-31';
11. Frontend Files to Create

Create:

frontend/src/views/health/HealthReportsView.vue
frontend/src/services/healthReportsService.js

Update:

frontend/src/router/index.js
frontend/src/layouts/AppLayout.vue
12. healthReportsService.js

Create:

cd /u01/nix-life-os/frontend
nano src/services/healthReportsService.js

Paste:

import api from './api'

export const healthReportsService = {
  getDailyReport(date) {
    return api.get('/v1/health/reports/daily', {
      params: { date }
    })
  },

  getWeeklyReport(startDate, endDate) {
    return api.get('/v1/health/reports/weekly', {
      params: {
        start_date: startDate,
        end_date: endDate
      }
    })
  },

  getMonthlyReport(month) {
    return api.get('/v1/health/reports/monthly', {
      params: { month }
    })
  },

  getExportPreview(period, date, month) {
    return api.get('/v1/health/reports/export-preview', {
      params: {
        period,
        date,
        month
      }
    })
  }
}

If your api.js already includes /api as base URL, use:

'/v1/health/reports/daily'

If your api.js base URL does not include /api, use:

'/api/v1/health/reports/daily'
13. HealthReportsView.vue

Create:

nano src/views/health/HealthReportsView.vue

Paste:

<template>
  <div class="health-reports-page">
    <div class="page-header">
      <div>
        <h1>Health Reports</h1>
        <p>Daily, weekly, and monthly health summaries with nutrition, hydration, weight, steps, labs, and medication adherence.</p>
      </div>

      <button class="export-button" @click="loadExportPreview">
        Export Preview
      </button>
    </div>

    <div class="filters-card">
      <div class="filter-group">
        <label>Report Type</label>
        <select v-model="reportType" @change="loadReport">
          <option value="daily">Daily</option>
          <option value="weekly">Weekly</option>
          <option value="monthly">Monthly</option>
        </select>
      </div>

      <div class="filter-group" v-if="reportType === 'daily'">
        <label>Date</label>
        <input type="date" v-model="selectedDate" @change="loadReport" />
      </div>

      <div class="filter-group" v-if="reportType === 'weekly'">
        <label>Start Date</label>
        <input type="date" v-model="startDate" @change="loadReport" />
      </div>

      <div class="filter-group" v-if="reportType === 'weekly'">
        <label>End Date</label>
        <input type="date" v-model="endDate" @change="loadReport" />
      </div>

      <div class="filter-group" v-if="reportType === 'monthly'">
        <label>Month</label>
        <input type="month" v-model="selectedMonth" @change="loadReport" />
      </div>
    </div>

    <div v-if="loading" class="state-card">
      Loading health report...
    </div>

    <div v-else-if="error" class="state-card error">
      {{ error }}
    </div>

    <div v-else-if="!report" class="state-card">
      No report data available.
    </div>

    <template v-else>
      <div class="summary-grid">
        <div class="summary-card">
          <span class="label">Health Status</span>
          <strong>{{ report.summary?.health_status || 'N/A' }}</strong>
        </div>

        <div class="summary-card">
          <span class="label">Calories</span>
          <strong>{{ report.summary?.total_calories || 0 }}</strong>
        </div>

        <div class="summary-card">
          <span class="label">Water</span>
          <strong>{{ report.hydration?.total_water_liters || 0 }} L</strong>
        </div>

        <div class="summary-card">
          <span class="label">Medication Adherence</span>
          <strong>{{ report.medication_adherence?.adherence_percent || 0 }}%</strong>
        </div>
      </div>

      <div class="reports-grid">
        <section class="report-card">
          <h2>Nutrition Totals</h2>

          <div class="metric-list">
            <div>
              <span>Protein</span>
              <strong>{{ report.nutrition?.totals?.protein_g || 0 }} g</strong>
            </div>
            <div>
              <span>Carbs</span>
              <strong>{{ report.nutrition?.totals?.carbs_g || 0 }} g</strong>
            </div>
            <div>
              <span>Fat</span>
              <strong>{{ report.nutrition?.totals?.fat_g || 0 }} g</strong>
            </div>
            <div>
              <span>Sodium</span>
              <strong>{{ report.nutrition?.totals?.sodium_mg || 0 }} mg</strong>
            </div>
            <div>
              <span>Potassium</span>
              <strong>{{ report.nutrition?.totals?.potassium_mg || 0 }} mg</strong>
            </div>
            <div>
              <span>Phosphorus</span>
              <strong>{{ report.nutrition?.totals?.phosphorus_mg || 0 }} mg</strong>
            </div>
          </div>

          <div class="warning-box" v-if="hasCkdWarnings">
            CKD warning: One or more nutrient limits are high.
          </div>
        </section>

        <section class="report-card">
          <h2>Hydration Totals</h2>
          <div class="big-number">{{ report.hydration?.total_water_ml || 0 }} ml</div>
          <p>Total water intake for selected period.</p>
        </section>

        <section class="report-card">
          <h2>Weight Trend</h2>
          <div class="metric-list">
            <div>
              <span>Start Weight</span>
              <strong>{{ report.weight?.start_weight || 'N/A' }} kg</strong>
            </div>
            <div>
              <span>Latest Weight</span>
              <strong>{{ report.weight?.latest_weight || 'N/A' }} kg</strong>
            </div>
            <div>
              <span>Change</span>
              <strong>{{ report.weight?.change_kg ?? 'N/A' }} kg</strong>
            </div>
          </div>
        </section>

        <section class="report-card">
          <h2>Steps Trend</h2>
          <div class="metric-list">
            <div>
              <span>Total Steps</span>
              <strong>{{ report.steps?.total_steps || 0 }}</strong>
            </div>
            <div>
              <span>Average Steps</span>
              <strong>{{ report.steps?.average_steps || 0 }}</strong>
            </div>
          </div>
        </section>

        <section class="report-card">
          <h2>Lab Results Trend</h2>
          <div class="metric-list">
            <div>
              <span>Total Tests</span>
              <strong>{{ report.lab_results?.total_tests || 0 }}</strong>
            </div>
            <div>
              <span>Abnormal Tests</span>
              <strong>{{ report.lab_results?.abnormal_tests || 0 }}</strong>
            </div>
          </div>

          <table v-if="report.lab_results?.items?.length">
            <thead>
              <tr>
                <th>Date</th>
                <th>Test</th>
                <th>Result</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(lab, index) in report.lab_results.items" :key="index">
                <td>{{ lab.test_date }}</td>
                <td>{{ lab.test_name }}</td>
                <td>{{ lab.result_value }} {{ lab.unit }}</td>
                <td>{{ lab.status }}</td>
              </tr>
            </tbody>
          </table>

          <p v-else>No lab results found for this period.</p>
        </section>

        <section class="report-card">
          <h2>Medication Adherence</h2>
          <div class="big-number">
            {{ report.medication_adherence?.adherence_percent || 0 }}%
          </div>

          <div class="metric-list">
            <div>
              <span>Total Doses</span>
              <strong>{{ report.medication_adherence?.total_doses || 0 }}</strong>
            </div>
            <div>
              <span>Taken</span>
              <strong>{{ report.medication_adherence?.taken_doses || 0 }}</strong>
            </div>
            <div>
              <span>Missed</span>
              <strong>{{ report.medication_adherence?.missed_doses || 0 }}</strong>
            </div>
          </div>
        </section>
      </div>

      <section class="export-card">
        <h2>Export-Ready PDF Structure</h2>
        <p>This screen is structured for future PDF export.</p>

        <ul>
          <li>Cover Page</li>
          <li>Health Summary</li>
          <li>Nutrition Summary</li>
          <li>Hydration Summary</li>
          <li>Weight Trend</li>
          <li>Steps Trend</li>
          <li>Lab Results Trend</li>
          <li>Medication Adherence</li>
          <li>Doctor Notes Placeholder</li>
        </ul>
      </section>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { healthReportsService } from '@/services/healthReportsService'

const reportType = ref('daily')
const selectedDate = ref(new Date().toISOString().slice(0, 10))
const selectedMonth = ref(new Date().toISOString().slice(0, 7))

const startDate = ref(getStartOfWeek())
const endDate = ref(new Date().toISOString().slice(0, 10))

const report = ref(null)
const loading = ref(false)
const error = ref(null)
const exportPreview = ref(null)

const hasCkdWarnings = computed(() => {
  const warnings = report.value?.nutrition?.ckd_warnings

  if (!warnings) {
    return false
  }

  return Object.values(warnings).some(Boolean)
})

onMounted(() => {
  loadReport()
})

async function loadReport() {
  loading.value = true
  error.value = null

  try {
    let response

    if (reportType.value === 'daily') {
      response = await healthReportsService.getDailyReport(selectedDate.value)
    } else if (reportType.value === 'weekly') {
      response = await healthReportsService.getWeeklyReport(startDate.value, endDate.value)
    } else {
      response = await healthReportsService.getMonthlyReport(selectedMonth.value)
    }

    report.value = response.data.data
  } catch (err) {
    console.error(err)
    error.value = 'Failed to load health report.'
  } finally {
    loading.value = false
  }
}

async function loadExportPreview() {
  try {
    const response = await healthReportsService.getExportPreview(
      reportType.value,
      selectedDate.value,
      selectedMonth.value
    )

    exportPreview.value = response.data.data
    alert('Export preview loaded successfully. PDF generation can be added in the next step.')
  } catch (err) {
    console.error(err)
    alert('Failed to load export preview.')
  }
}

function getStartOfWeek() {
  const date = new Date()
  const day = date.getDay()
  const diff = date.getDate() - day + (day === 0 ? -6 : 1)
  const monday = new Date(date.setDate(diff))

  return monday.toISOString().slice(0, 10)
}
</script>

<style scoped>
.health-reports-page {
  padding: 24px;
  background: #f8fafc;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 8px;
}

.page-header p {
  color: #64748b;
  margin: 0;
}

.export-button {
  background: #0f172a;
  color: white;
  border: none;
  border-radius: 10px;
  padding: 10px 16px;
  cursor: pointer;
  font-weight: 700;
}

.filters-card,
.state-card,
.report-card,
.export-card,
.summary-card {
  background: white;
  border-radius: 16px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.04);
}

.filters-card {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  padding: 18px;
  margin-bottom: 24px;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.filter-group label {
  font-size: 13px;
  font-weight: 700;
  color: #475569;
}

.filter-group input,
.filter-group select {
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 10px;
  min-width: 180px;
}

.state-card {
  padding: 24px;
  color: #475569;
}

.state-card.error {
  color: #b91c1c;
  background: #fef2f2;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card {
  padding: 18px;
}

.summary-card .label {
  display: block;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 8px;
}

.summary-card strong {
  font-size: 24px;
  color: #0f172a;
}

.reports-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(280px, 1fr));
  gap: 20px;
}

.report-card {
  padding: 20px;
}

.report-card h2,
.export-card h2 {
  margin: 0 0 16px;
  font-size: 20px;
  color: #0f172a;
}

.metric-list {
  display: grid;
  gap: 12px;
}

.metric-list div {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 8px;
}

.metric-list span {
  color: #64748b;
}

.metric-list strong {
  color: #0f172a;
}

.big-number {
  font-size: 36px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 8px;
}

.warning-box {
  margin-top: 16px;
  padding: 12px;
  border-radius: 10px;
  background: #fff7ed;
  color: #c2410c;
  font-weight: 700;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 12px;
}

th,
td {
  text-align: left;
  padding: 10px;
  border-bottom: 1px solid #e2e8f0;
  font-size: 14px;
}

th {
  color: #475569;
  background: #f8fafc;
}

.export-card {
  margin-top: 24px;
  padding: 20px;
}

.export-card ul {
  margin: 12px 0 0;
  padding-left: 20px;
  color: #475569;
}

@media (max-width: 900px) {
  .summary-grid,
  .reports-grid {
    grid-template-columns: 1fr;
  }

  .page-header {
    flex-direction: column;
  }
}
</style>
14. Add Route in Vue Router

Open:

nano src/router/index.js

Add import:

import HealthReportsView from '@/views/health/HealthReportsView.vue'

Add route:

{
  path: '/health/reports',
  name: 'HealthReports',
  component: HealthReportsView,
  meta: {
    requiresAuth: true,
    title: 'Health Reports'
  }
}

Recommended location: beside the other health routes, for example after:

/health/medications
/health/lab-tests
15. Add Sidebar Link

Open:

nano src/layouts/AppLayout.vue

Add under Health menu:

<router-link
  to="/health/reports"
  class="sidebar-link"
  active-class="active"
>
  Health Reports
</router-link>

If your sidebar uses the existing structure like:

<RouterLink to="/health/medications">

Then use the same style and class as your current sidebar links.

16. Frontend Test Commands

From frontend:

cd /u01/nix-life-os/frontend

npm run build

If using Docker:

cd /u01/nix-life-os

docker compose -f docker-compose.prod.yml build nixlifeos-frontend
docker compose -f docker-compose.prod.yml up -d nixlifeos-frontend nixlifeos-nginx

Then open:

http://127.0.0.1/health/reports

Or if routed through Vite/dev server:

http://127.0.0.1:5173/health/reports
17. Common Problems and Fixes
Problem 1: Route not found

Error:

{
  "message": "The route api/v1/health/reports/daily could not be found."
}

Fix:

cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan route:list | grep reports

Check that the routes are inside the correct v1 and auth:sanctum group.

Problem 2: Table does not exist

Error:

SQLSTATE[42P01]: Undefined table

Fix:

Check actual table name:

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE '%health%';

Then update the table names in:

app/Services/Health/HealthReportService.php
Problem 3: Wrong date column

Possible differences:

log_date
date
recorded_at
created_at
test_date
dose_date

Fix:

Check columns:

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'health_nutrition_logs'
ORDER BY ordinal_position;

Repeat for each table.

Problem 4: Frontend API 404

Check src/services/api.js.

If base URL is:

baseURL: 'http://127.0.0.1:8000/api'

Use:

api.get('/v1/health/reports/daily')

If base URL is:

baseURL: 'http://127.0.0.1:8000'

Use:

api.get('/api/v1/health/reports/daily')
18. Final Testing Checklist
Backend
[ ] HealthReportController created.
[ ] HealthReportService created.
[ ] Routes added correctly.
[ ] php artisan route:list shows health reports routes.
[ ] Daily report API returns 200.
[ ] Weekly report API returns 200.
[ ] Monthly report API returns 200.
[ ] Export preview API returns 200.
[ ] Empty data returns zero values, not errors.
[ ] Nutrition totals match SQL.
[ ] Hydration totals match SQL.
[ ] Weight trend matches SQL.
[ ] Steps trend matches SQL.
[ ] Lab results match SQL.
[ ] Medication adherence matches SQL.
Frontend
[ ] HealthReportsView.vue created.
[ ] healthReportsService.js created.
[ ] Vue route /health/reports added.
[ ] Sidebar link added.
[ ] Page opens correctly.
[ ] Daily filter works.
[ ] Weekly filter works.
[ ] Monthly filter works.
[ ] Summary cards display correctly.
[ ] Nutrition section displays totals.
[ ] CKD warnings display correctly.
[ ] Hydration section displays total.
[ ] Weight trend section displays start/latest/change.
[ ] Steps section displays total/average.
[ ] Lab results table displays.
[ ] Medication adherence displays.
[ ] Export Preview button works.
[ ] npm run build passes.
19. Recommended Next Step

After finishing Step 53, continue with:

🔹 STEP 54 — Health Report PDF Export Engine

This should include:

1. Generate PDF from daily report.
2. Generate PDF from weekly report.
3. Generate PDF from monthly report.
4. Add doctor-friendly report layout.
5. Add CKD warning section.
6. Add lab result trend table.
7. Add medication adherence summary.
8. Download PDF from Vue.
9. Store exported report history.
10. Add future email/export support.
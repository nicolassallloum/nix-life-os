🔹 STEP 8 — Health Steps Tracking Module

Build Steps Tracking: Daily Logs + Distance + 30-Day History + Goal Tracking

This step adds a Health / Steps Tracking module to NIX LIFE OS.

You will build:

Daily step logs
Automatic distance calculation
Last 30 days history
Daily goal tracking
Laravel backend APIs
Vue + Tailwind frontend page
1. Backend Structure

Create these files:

php artisan make:model HealthProfile -m
php artisan make:model HealthStepLog -m
php artisan make:controller Api/V1/Health/HealthProfileController
php artisan make:controller Api/V1/Health/HealthStepLogController
php artisan make:resource HealthProfileResource
php artisan make:resource HealthStepLogResource
2. Database Migration — Health Profile

Open the generated migration for health_profiles.

Example file:

database/migrations/xxxx_xx_xx_xxxxxx_create_health_profiles_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_profiles', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->unsignedInteger('daily_steps_goal')->default(8000);

            /*
             |--------------------------------------------------------------------------
             | Stride Length
             |--------------------------------------------------------------------------
             | Average stride length in centimeters.
             | Example:
             | 75 cm = 0.75 meter per step
             */
            $table->decimal('stride_length_cm', 6, 2)->default(75.00);

            $table->string('distance_unit', 10)->default('km');

            $table->timestamps();

            $table->unique('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_profiles');
    }
};
3. Database Migration — Daily Step Logs

Open the generated migration for health_step_logs.

database/migrations/xxxx_xx_xx_xxxxxx_create_health_step_logs_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_step_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('log_date');

            $table->unsignedInteger('steps_count')->default(0);

            /*
             |--------------------------------------------------------------------------
             | Calculated Distance
             |--------------------------------------------------------------------------
             | Stored in kilometers.
             | Formula:
             | distance_km = steps_count * stride_length_cm / 100000
             */
            $table->decimal('distance_km', 10, 3)->default(0);

            $table->unsignedInteger('goal_steps')->default(8000);

            $table->decimal('goal_percentage', 6, 2)->default(0);

            $table->boolean('goal_completed')->default(false);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'log_date']);

            $table->index(['user_id', 'log_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_step_logs');
    }
};

Run migration:

php artisan migrate
4. HealthProfile Model

Create/update:

app/Models/HealthProfile.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthProfile extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'daily_steps_goal',
        'stride_length_cm',
        'distance_unit',
    ];

    protected $casts = [
        'daily_steps_goal' => 'integer',
        'stride_length_cm' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
5. HealthStepLog Model

Create/update:

app/Models/HealthStepLog.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthStepLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'log_date',
        'steps_count',
        'distance_km',
        'goal_steps',
        'goal_percentage',
        'goal_completed',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'steps_count' => 'integer',
        'distance_km' => 'decimal:3',
        'goal_steps' => 'integer',
        'goal_percentage' => 'decimal:2',
        'goal_completed' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
6. HealthProfileResource

Create/update:

app/Http/Resources/HealthProfileResource.php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'daily_steps_goal' => $this->daily_steps_goal,
            'stride_length_cm' => $this->stride_length_cm,
            'distance_unit' => $this->distance_unit,
            'created_at' => $this->created_at?->toDateTimeString(),
            'updated_at' => $this->updated_at?->toDateTimeString(),
        ];
    }
}
7. HealthStepLogResource

Create/update:

app/Http/Resources/HealthStepLogResource.php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthStepLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'log_date' => $this->log_date?->format('Y-m-d'),
            'steps_count' => $this->steps_count,
            'distance_km' => $this->distance_km,
            'goal_steps' => $this->goal_steps,
            'goal_percentage' => $this->goal_percentage,
            'goal_completed' => $this->goal_completed,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toDateTimeString(),
            'updated_at' => $this->updated_at?->toDateTimeString(),
        ];
    }
}
8. HealthProfileController

Create/update:

app/Http/Controllers/Api/V1/Health/HealthProfileController.php
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthProfileResource;
use App\Models\HealthProfile;
use Illuminate\Http\Request;

class HealthProfileController extends Controller
{
    public function show(Request $request)
    {
        $profile = HealthProfile::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'daily_steps_goal' => 8000,
                'stride_length_cm' => 75.00,
                'distance_unit' => 'km',
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Health profile loaded successfully.',
            'data' => new HealthProfileResource($profile),
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'daily_steps_goal' => ['required', 'integer', 'min:500', 'max:100000'],
            'stride_length_cm' => ['required', 'numeric', 'min:30', 'max:150'],
            'distance_unit' => ['nullable', 'string', 'in:km'],
        ]);

        $profile = HealthProfile::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'daily_steps_goal' => 8000,
                'stride_length_cm' => 75.00,
                'distance_unit' => 'km',
            ]
        );

        $profile->update([
            'daily_steps_goal' => $validated['daily_steps_goal'],
            'stride_length_cm' => $validated['stride_length_cm'],
            'distance_unit' => $validated['distance_unit'] ?? 'km',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Health profile updated successfully.',
            'data' => new HealthProfileResource($profile),
        ]);
    }
}
9. HealthStepLogController

Create/update:

app/Http/Controllers/Api/V1/Health/HealthStepLogController.php
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthStepLogResource;
use App\Models\HealthProfile;
use App\Models\HealthStepLog;
use Carbon\Carbon;
use Illuminate\Http\Request;

class HealthStepLogController extends Controller
{
    public function index(Request $request)
    {
        $days = (int) $request->query('days', 30);

        if ($days < 1 || $days > 365) {
            $days = 30;
        }

        $logs = HealthStepLog::where('user_id', $request->user()->id)
            ->whereDate('log_date', '>=', now()->subDays($days - 1)->toDateString())
            ->orderBy('log_date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => "Last {$days} days step logs loaded successfully.",
            'data' => HealthStepLogResource::collection($logs),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'log_date' => ['required', 'date'],
            'steps_count' => ['required', 'integer', 'min:0', 'max:200000'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $profile = HealthProfile::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'daily_steps_goal' => 8000,
                'stride_length_cm' => 75.00,
                'distance_unit' => 'km',
            ]
        );

        $steps = $validated['steps_count'];
        $goalSteps = $profile->daily_steps_goal;

        $distanceKm = $this->calculateDistanceKm(
            $steps,
            (float) $profile->stride_length_cm
        );

        $goalPercentage = $this->calculateGoalPercentage($steps, $goalSteps);

        $log = HealthStepLog::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'log_date' => Carbon::parse($validated['log_date'])->toDateString(),
            ],
            [
                'steps_count' => $steps,
                'distance_km' => $distanceKm,
                'goal_steps' => $goalSteps,
                'goal_percentage' => $goalPercentage,
                'goal_completed' => $steps >= $goalSteps,
                'notes' => $validated['notes'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Step log saved successfully.',
            'data' => new HealthStepLogResource($log),
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $log = HealthStepLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Step log loaded successfully.',
            'data' => new HealthStepLogResource($log),
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $log = HealthStepLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Step log deleted successfully.',
        ]);
    }

    public function summary(Request $request)
    {
        $days = (int) $request->query('days', 30);

        if ($days < 1 || $days > 365) {
            $days = 30;
        }

        $logs = HealthStepLog::where('user_id', $request->user()->id)
            ->whereDate('log_date', '>=', now()->subDays($days - 1)->toDateString())
            ->get();

        $totalSteps = $logs->sum('steps_count');
        $totalDistance = $logs->sum('distance_km');
        $completedDays = $logs->where('goal_completed', true)->count();
        $loggedDays = $logs->count();

        return response()->json([
            'success' => true,
            'message' => 'Steps summary loaded successfully.',
            'data' => [
                'days_range' => $days,
                'logged_days' => $loggedDays,
                'total_steps' => $totalSteps,
                'average_steps' => $loggedDays > 0 ? round($totalSteps / $loggedDays) : 0,
                'total_distance_km' => round($totalDistance, 3),
                'average_distance_km' => $loggedDays > 0 ? round($totalDistance / $loggedDays, 3) : 0,
                'goal_completed_days' => $completedDays,
                'goal_completion_rate' => $loggedDays > 0
                    ? round(($completedDays / $loggedDays) * 100, 2)
                    : 0,
            ],
        ]);
    }

    private function calculateDistanceKm(int $steps, float $strideLengthCm): float
    {
        return round(($steps * $strideLengthCm) / 100000, 3);
    }

    private function calculateGoalPercentage(int $steps, int $goalSteps): float
    {
        if ($goalSteps <= 0) {
            return 0;
        }

        return round(($steps / $goalSteps) * 100, 2);
    }
}
10. Add API Routes

Open:

routes/api.php

Add this inside your authenticated API group:

use App\Http\Controllers\Api\V1\Health\HealthProfileController;
use App\Http\Controllers\Api\V1\Health\HealthStepLogController;

Then add routes:

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {

    Route::prefix('health')->group(function () {

        Route::get('/profile', [HealthProfileController::class, 'show']);
        Route::put('/profile', [HealthProfileController::class, 'update']);

        Route::get('/steps', [HealthStepLogController::class, 'index']);
        Route::post('/steps', [HealthStepLogController::class, 'store']);
        Route::get('/steps/summary', [HealthStepLogController::class, 'summary']);
        Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);
        Route::delete('/steps/{id}', [HealthStepLogController::class, 'destroy']);
    });

});

If you already have this:

Route::prefix('api/v1')

Do not duplicate /v1.

Your final endpoints should be:

GET    /api/v1/health/profile
PUT    /api/v1/health/profile

GET    /api/v1/health/steps?days=30
POST   /api/v1/health/steps
GET    /api/v1/health/steps/summary?days=30
GET    /api/v1/health/steps/{id}
DELETE /api/v1/health/steps/{id}
11. Clear Laravel Cache

Run:

php artisan optimize:clear
composer dump-autoload
12. Backend Test Using CURL

curl -X POST http://127.0.0.1:8000/api/v1/auth/register \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nix",
    "email": "nix@test.com",
    "password": "Valoores@bring11",
    "password_confirmation": "Valoores@bring11"
  }'

10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108

curl -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nix@test.com",
    "password": "Valoores@bring11"
  }'

Get Health Profile
curl http://127.0.0.1:8000/api/v1/health/profile \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"
Update Health Profile
curl -X PUT http://127.0.0.1:8000/api/v1/health/profile \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "daily_steps_goal": 8000,
    "stride_length_cm": 75,
    "distance_unit": "km"
  }'
Add Daily Steps
curl -X POST http://127.0.0.1:8000/api/v1/health/steps \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "log_date": "2026-04-24",
    "steps_count": 6500,
    "notes": "Normal walking day"
  }'
Get 30-Day History
curl http://127.0.0.1:8000/api/v1/health/steps?days=30 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"
Get Summary
curl http://127.0.0.1:8000/api/v1/health/steps/summary?days=30 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"
13. Frontend Structure

Inside your Vue frontend, create:

src/views/health/HealthStepsView.vue
src/services/healthService.js

If you do not have health folder:

mkdir -p src/views/health
mkdir -p src/services
14. Frontend API Service

Create:

src/services/healthService.js
import axios from "axios";

const API_BASE_URL = "http://127.0.0.1:8000/api/v1";

function getAuthHeaders() {
  const token = localStorage.getItem("token");

  return {
    Accept: "application/json",
    Authorization: `Bearer ${token}`,
  };
}

export async function getHealthProfile() {
  const response = await axios.get(`${API_BASE_URL}/health/profile`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function updateHealthProfile(payload) {
  const response = await axios.put(`${API_BASE_URL}/health/profile`, payload, {
    headers: {
      ...getAuthHeaders(),
      "Content-Type": "application/json",
    },
  });

  return response.data;
}

export async function getStepsHistory(days = 30) {
  const response = await axios.get(`${API_BASE_URL}/health/steps?days=${days}`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function getStepsSummary(days = 30) {
  const response = await axios.get(
    `${API_BASE_URL}/health/steps/summary?days=${days}`,
    {
      headers: getAuthHeaders(),
    }
  );

  return response.data;
}

export async function saveStepLog(payload) {
  const response = await axios.post(`${API_BASE_URL}/health/steps`, payload, {
    headers: {
      ...getAuthHeaders(),
      "Content-Type": "application/json",
    },
  });

  return response.data;
}

export async function deleteStepLog(id) {
  const response = await axios.delete(`${API_BASE_URL}/health/steps/${id}`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}
15. HealthStepsView.vue

Create:

src/views/health/HealthStepsView.vue
<script setup>
import { onMounted, ref } from "vue";
import {
  getHealthProfile,
  updateHealthProfile,
  getStepsHistory,
  getStepsSummary,
  saveStepLog,
  deleteStepLog,
} from "../../services/healthService";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const profile = ref({
  daily_steps_goal: 8000,
  stride_length_cm: 75,
  distance_unit: "km",
});

const stepForm = ref({
  log_date: new Date().toISOString().slice(0, 10),
  steps_count: 0,
  notes: "",
});

const summary = ref({
  days_range: 30,
  logged_days: 0,
  total_steps: 0,
  average_steps: 0,
  total_distance_km: 0,
  average_distance_km: 0,
  goal_completed_days: 0,
  goal_completion_rate: 0,
});

const logs = ref([]);

async function loadDashboard() {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const [profileResponse, summaryResponse, historyResponse] =
      await Promise.all([
        getHealthProfile(),
        getStepsSummary(30),
        getStepsHistory(30),
      ]);

    profile.value = profileResponse.data;
    summary.value = summaryResponse.data;
    logs.value = historyResponse.data;
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to load steps dashboard.";
  } finally {
    loading.value = false;
  }
}

async function submitProfile() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const response = await updateHealthProfile({
      daily_steps_goal: Number(profile.value.daily_steps_goal),
      stride_length_cm: Number(profile.value.stride_length_cm),
      distance_unit: "km",
    });

    profile.value = response.data;
    successMessage.value = "Health profile updated successfully.";
    await loadDashboard();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to update health profile.";
  } finally {
    saving.value = false;
  }
}

async function submitStepLog() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await saveStepLog({
      log_date: stepForm.value.log_date,
      steps_count: Number(stepForm.value.steps_count),
      notes: stepForm.value.notes,
    });

    successMessage.value = "Step log saved successfully.";

    stepForm.value.steps_count = 0;
    stepForm.value.notes = "";

    await loadDashboard();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to save step log.";
  } finally {
    saving.value = false;
  }
}

async function removeLog(id) {
  if (!confirm("Are you sure you want to delete this step log?")) {
    return;
  }

  try {
    await deleteStepLog(id);
    successMessage.value = "Step log deleted successfully.";
    await loadDashboard();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to delete step log.";
  }
}

function formatNumber(value) {
  return new Intl.NumberFormat().format(value || 0);
}

function progressBarWidth(value) {
  const percentage = Number(value || 0);

  if (percentage > 100) {
    return "100%";
  }

  return `${percentage}%`;
}

onMounted(() => {
  loadDashboard();
});
</script>

<template>
  <div class="min-h-screen bg-slate-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <!-- Header -->
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-3xl font-bold text-slate-900">
            Steps Tracking
          </h1>
          <p class="text-slate-500">
            Track daily walking activity, distance, and 30-day goal progress.
          </p>
        </div>

        <button
          @click="loadDashboard"
          class="rounded-xl bg-slate-900 px-5 py-2 text-sm font-semibold text-white hover:bg-slate-700"
        >
          Refresh
        </button>
      </div>

      <!-- Alerts -->
      <div
        v-if="errorMessage"
        class="rounded-xl border border-red-200 bg-red-50 p-4 text-red-700"
      >
        {{ errorMessage }}
      </div>

      <div
        v-if="successMessage"
        class="rounded-xl border border-green-200 bg-green-50 p-4 text-green-700"
      >
        {{ successMessage }}
      </div>

      <!-- Loading -->
      <div
        v-if="loading"
        class="rounded-xl bg-white p-6 text-center text-slate-500 shadow-sm"
      >
        Loading steps dashboard...
      </div>

      <template v-else>
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Total Steps</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ formatNumber(summary.total_steps) }}
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              Last {{ summary.days_range }} days
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Total Distance</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ summary.total_distance_km }} km
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              Average {{ summary.average_distance_km }} km/day
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Average Steps</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ formatNumber(summary.average_steps) }}
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              Based on {{ summary.logged_days }} logged days
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Goal Completion</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ summary.goal_completion_rate }}%
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              {{ summary.goal_completed_days }} completed days
            </p>
          </div>
        </div>

        <!-- Forms -->
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <!-- Add Daily Steps -->
          <div class="rounded-2xl bg-white p-6 shadow-sm">
            <h2 class="text-xl font-bold text-slate-900">
              Add Daily Steps
            </h2>

            <form @submit.prevent="submitStepLog" class="mt-5 space-y-4">
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Date
                </label>
                <input
                  v-model="stepForm.log_date"
                  type="date"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Steps Count
                </label>
                <input
                  v-model="stepForm.steps_count"
                  type="number"
                  min="0"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                  placeholder="Example: 6500"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Notes
                </label>
                <textarea
                  v-model="stepForm.notes"
                  rows="3"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                  placeholder="Optional notes"
                ></textarea>
              </div>

              <button
                type="submit"
                :disabled="saving"
                class="w-full rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
              >
                {{ saving ? "Saving..." : "Save Steps" }}
              </button>
            </form>
          </div>

          <!-- Health Profile -->
          <div class="rounded-2xl bg-white p-6 shadow-sm">
            <h2 class="text-xl font-bold text-slate-900">
              Steps Settings
            </h2>

            <form @submit.prevent="submitProfile" class="mt-5 space-y-4">
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Daily Steps Goal
                </label>
                <input
                  v-model="profile.daily_steps_goal"
                  type="number"
                  min="500"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Stride Length CM
                </label>
                <input
                  v-model="profile.stride_length_cm"
                  type="number"
                  min="30"
                  step="0.01"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                />
                <p class="mt-1 text-xs text-slate-400">
                  Default: 75 cm. Used to calculate distance.
                </p>
              </div>

              <button
                type="submit"
                :disabled="saving"
                class="w-full rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white hover:bg-slate-700 disabled:opacity-60"
              >
                {{ saving ? "Saving..." : "Update Settings" }}
              </button>
            </form>
          </div>
        </div>

        <!-- History Table -->
        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="mb-5 flex items-center justify-between">
            <div>
              <h2 class="text-xl font-bold text-slate-900">
                30-Day Steps History
              </h2>
              <p class="text-sm text-slate-500">
                Daily logs ordered from newest to oldest.
              </p>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full border-collapse text-left">
              <thead>
                <tr class="border-b bg-slate-50 text-sm text-slate-600">
                  <th class="px-4 py-3">Date</th>
                  <th class="px-4 py-3">Steps</th>
                  <th class="px-4 py-3">Distance</th>
                  <th class="px-4 py-3">Goal</th>
                  <th class="px-4 py-3">Progress</th>
                  <th class="px-4 py-3">Status</th>
                  <th class="px-4 py-3">Notes</th>
                  <th class="px-4 py-3 text-right">Action</th>
                </tr>
              </thead>

              <tbody>
                <tr
                  v-for="log in logs"
                  :key="log.id"
                  class="border-b text-sm hover:bg-slate-50"
                >
                  <td class="px-4 py-3 font-medium text-slate-900">
                    {{ log.log_date }}
                  </td>

                  <td class="px-4 py-3">
                    {{ formatNumber(log.steps_count) }}
                  </td>

                  <td class="px-4 py-3">
                    {{ log.distance_km }} km
                  </td>

                  <td class="px-4 py-3">
                    {{ formatNumber(log.goal_steps) }}
                  </td>

                  <td class="px-4 py-3">
                    <div class="w-32 rounded-full bg-slate-200">
                      <div
                        class="h-2 rounded-full bg-blue-600"
                        :style="{ width: progressBarWidth(log.goal_percentage) }"
                      ></div>
                    </div>
                    <p class="mt-1 text-xs text-slate-500">
                      {{ log.goal_percentage }}%
                    </p>
                  </td>

                  <td class="px-4 py-3">
                    <span
                      v-if="log.goal_completed"
                      class="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700"
                    >
                      Completed
                    </span>

                    <span
                      v-else
                      class="rounded-full bg-yellow-100 px-3 py-1 text-xs font-semibold text-yellow-700"
                    >
                      In Progress
                    </span>
                  </td>

                  <td class="px-4 py-3 text-slate-500">
                    {{ log.notes || "-" }}
                  </td>

                  <td class="px-4 py-3 text-right">
                    <button
                      @click="removeLog(log.id)"
                      class="rounded-lg bg-red-50 px-3 py-1 text-xs font-semibold text-red-600 hover:bg-red-100"
                    >
                      Delete
                    </button>
                  </td>
                </tr>

                <tr v-if="logs.length === 0">
                  <td colspan="8" class="px-4 py-8 text-center text-slate-400">
                    No step logs found.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
16. Add Route in Vue Router

Open:

src/router/index.js

Add import:

import HealthStepsView from "../views/health/HealthStepsView.vue";

Add route:

{
  path: "/health/steps",
  name: "HealthSteps",
  component: HealthStepsView,
}

Example:

import { createRouter, createWebHistory } from "vue-router";
import HealthStepsView from "../views/health/HealthStepsView.vue";

const routes = [
  {
    path: "/health/steps",
    name: "HealthSteps",
    component: HealthStepsView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

If you already have routes, only add the new one.

17. Add Link in App.vue or Sidebar

Open:

src/App.vue

Add this link where your navigation/sidebar exists:

<RouterLink
  to="/health/steps"
  class="rounded-xl px-4 py-2 text-slate-700 hover:bg-slate-100"
>
  Steps Tracking
</RouterLink>

If you are using sidebar style:

<RouterLink
  to="/health/steps"
  class="block rounded-xl px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
>
  🏃 Steps Tracking
</RouterLink>
18. Distance Calculation Formula

The backend calculates distance like this:

distance_km = steps_count × stride_length_cm / 100000

Example:

6500 steps × 75 cm = 487500 cm
487500 cm / 100000 = 4.875 km

So:

6500 steps ≈ 4.875 km
19. Goal Tracking Formula

The backend calculates goal progress like this:

goal_percentage = steps_count / daily_steps_goal × 100

Example:

6500 / 8000 × 100 = 81.25%

Goal completed:

goal_completed = true if steps_count >= daily_steps_goal
20. Final Module Result

After this step, your app will support:

Health Profile
- Daily steps goal
- Stride length
- Distance unit

Daily Steps Logs
- Log date
- Steps count
- Auto distance calculation
- Auto goal percentage
- Goal completed status
- Notes

Dashboard
- Total steps
- Total distance
- Average steps
- Average distance
- Goal completion rate
- 30-day history
21. Recommended Project Step Name

Use this as your project note title:

STEP 8 — Health Steps Tracking Module

Professional prompt version:

Build the Health Steps Tracking Module for NIX LIFE OS.

Include:
- Laravel backend migrations, models, controllers, resources, and API routes
- Daily steps logging
- Automatic distance calculation based on stride length
- 30-day history endpoint
- Goal tracking and completion percentage
- Vue 3 + Tailwind frontend page
- Dashboard summary cards
- Add daily step form
- Settings form for daily goal and stride length
- 30-day history table

The module must integrate with Laravel Sanctum authentication and the existing Vue fro
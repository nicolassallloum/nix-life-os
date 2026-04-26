STEP 9 — Health Weight Tracking Module

Build Weight module for NIX LIFE OS with:

Weight logs
Trend analysis
Min / Max / Average
Charts
Laravel API
Vue + Tailwind UI
1. Backend — Create Weight Logs Migration

Run:

cd /u01/nix-life-os/backend

php artisan make:migration create_health_weight_logs_table

Open the generated file:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_weight_logs_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_weight_logs', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('log_date');

            $table->decimal('weight_kg', 6, 2);

            $table->decimal('body_fat_percentage', 5, 2)->nullable();
            $table->decimal('muscle_mass_kg', 6, 2)->nullable();
            $table->decimal('bmi', 5, 2)->nullable();

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'log_date']);

            $table->index(['user_id', 'log_date']);
            $table->index(['user_id', 'weight_kg']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_weight_logs');
    }
};

Run migration:

php artisan migrate
2. Backend — Create Model

Run:

php artisan make:model HealthWeightLog

Open:

nano app/Models/HealthWeightLog.php

Add:

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthWeightLog extends Model
{
    use HasFactory;

    protected $table = 'health_weight_logs';

    protected $fillable = [
        'user_id',
        'log_date',
        'weight_kg',
        'body_fat_percentage',
        'muscle_mass_kg',
        'bmi',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'weight_kg' => 'decimal:2',
        'body_fat_percentage' => 'decimal:2',
        'muscle_mass_kg' => 'decimal:2',
        'bmi' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
3. Backend — Create Resource

Run:

php artisan make:resource HealthWeightLogResource

Open:

nano app/Http/Resources/HealthWeightLogResource.php

Replace with:

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthWeightLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'log_date' => optional($this->log_date)->format('Y-m-d'),
            'weight_kg' => (float) $this->weight_kg,
            'body_fat_percentage' => $this->body_fat_percentage !== null ? (float) $this->body_fat_percentage : null,
            'muscle_mass_kg' => $this->muscle_mass_kg !== null ? (float) $this->muscle_mass_kg : null,
            'bmi' => $this->bmi !== null ? (float) $this->bmi : null,
            'notes' => $this->notes,
            'created_at' => optional($this->created_at)->toISOString(),
            'updated_at' => optional($this->updated_at)->toISOString(),
        ];
    }
}
4. Backend — Create Controller

Run:

php artisan make:controller Api/V1/HealthWeightLogController

Open:

nano app/Http/Controllers/Api/V1/HealthWeightLogController.php

Replace with:

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthWeightLogResource;
use App\Models\HealthWeightLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HealthWeightLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = HealthWeightLog::query()
            ->where('user_id', $user->id)
            ->orderByDesc('log_date');

        if ($request->filled('from_date')) {
            $query->whereDate('log_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('log_date', '<=', $request->to_date);
        }

        $logs = $query->paginate($request->integer('per_page', 30));

        return response()->json([
            'success' => true,
            'message' => 'Weight logs retrieved successfully.',
            'data' => HealthWeightLogResource::collection($logs)->response()->getData(true),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'log_date' => ['required', 'date'],
            'weight_kg' => ['required', 'numeric', 'min:20', 'max:400'],
            'body_fat_percentage' => ['nullable', 'numeric', 'min:1', 'max:80'],
            'muscle_mass_kg' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'bmi' => ['nullable', 'numeric', 'min:5', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        $log = HealthWeightLog::updateOrCreate(
            [
                'user_id' => $user->id,
                'log_date' => $request->log_date,
            ],
            [
                'weight_kg' => $request->weight_kg,
                'body_fat_percentage' => $request->body_fat_percentage,
                'muscle_mass_kg' => $request->muscle_mass_kg,
                'bmi' => $request->bmi,
                'notes' => $request->notes,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Weight log saved successfully.',
            'data' => new HealthWeightLogResource($log),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $log = HealthWeightLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Weight log not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Weight log retrieved successfully.',
            'data' => new HealthWeightLogResource($log),
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $log = HealthWeightLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Weight log not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'log_date' => ['sometimes', 'date'],
            'weight_kg' => ['sometimes', 'numeric', 'min:20', 'max:400'],
            'body_fat_percentage' => ['nullable', 'numeric', 'min:1', 'max:80'],
            'muscle_mass_kg' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'bmi' => ['nullable', 'numeric', 'min:5', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $log->update($validator->validated());

        return response()->json([
            'success' => true,
            'message' => 'Weight log updated successfully.',
            'data' => new HealthWeightLogResource($log),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $log = HealthWeightLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Weight log not found.',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Weight log deleted successfully.',
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = HealthWeightLog::query()
            ->where('user_id', $user->id);

        if ($request->filled('from_date')) {
            $query->whereDate('log_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('log_date', '<=', $request->to_date);
        }

        $logs = $query->orderBy('log_date')->get();

        if ($logs->isEmpty()) {
            return response()->json([
                'success' => true,
                'message' => 'Weight summary retrieved successfully.',
                'data' => [
                    'total_logs' => 0,
                    'min_weight' => null,
                    'max_weight' => null,
                    'average_weight' => null,
                    'latest_weight' => null,
                    'first_weight' => null,
                    'weight_change' => null,
                    'trend_direction' => 'no_data',
                    'chart' => [],
                ],
            ]);
        }

        $first = $logs->first();
        $latest = $logs->last();

        $minWeight = $logs->min('weight_kg');
        $maxWeight = $logs->max('weight_kg');
        $avgWeight = round($logs->avg('weight_kg'), 2);

        $weightChange = round(((float) $latest->weight_kg) - ((float) $first->weight_kg), 2);

        $trendDirection = match (true) {
            $weightChange > 0 => 'increasing',
            $weightChange < 0 => 'decreasing',
            default => 'stable',
        };

        $chart = $logs->map(function ($log) {
            return [
                'date' => $log->log_date->format('Y-m-d'),
                'weight_kg' => (float) $log->weight_kg,
                'bmi' => $log->bmi !== null ? (float) $log->bmi : null,
                'body_fat_percentage' => $log->body_fat_percentage !== null ? (float) $log->body_fat_percentage : null,
                'muscle_mass_kg' => $log->muscle_mass_kg !== null ? (float) $log->muscle_mass_kg : null,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Weight summary retrieved successfully.',
            'data' => [
                'total_logs' => $logs->count(),
                'min_weight' => (float) $minWeight,
                'max_weight' => (float) $maxWeight,
                'average_weight' => $avgWeight,
                'latest_weight' => (float) $latest->weight_kg,
                'first_weight' => (float) $first->weight_kg,
                'weight_change' => $weightChange,
                'trend_direction' => $trendDirection,
                'latest_date' => $latest->log_date->format('Y-m-d'),
                'first_date' => $first->log_date->format('Y-m-d'),
                'chart' => $chart,
            ],
        ]);
    }
}
5. Backend — Add API Routes

Open:

nano routes/api.php

Add this import at the top:

use App\Http\Controllers\Api\V1\HealthWeightLogController;

Inside your existing authenticated API group, add:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    Route::get('/health/weight/summary', [HealthWeightLogController::class, 'summary']);

    Route::apiResource('/health/weight', HealthWeightLogController::class);
});

If you already have this:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    // existing routes
});

Then only add this inside it:

Route::get('/health/weight/summary', [HealthWeightLogController::class, 'summary']);
Route::apiResource('/health/weight', HealthWeightLogController::class);

Then run:

php artisan optimize:clear
composer dump-autoload
6. Backend — Test With CURL

Replace token with your current Sanctum token.

Create weight log
curl -X POST http://127.0.0.1:8000/api/v1/health/weight \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "log_date": "2026-04-26",
    "weight_kg": 64.00,
    "body_fat_percentage": 22.5,
    "muscle_mass_kg": 42.0,
    "bmi": 26.6,
    "notes": "Morning weight before breakfast"
  }'


curl http://127.0.0.1:8000/api/v1/health/weight/summary \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"
Add more test logs
curl -X POST http://127.0.0.1:8000/api/v1/health/weight \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "log_date": "2026-04-20",
    "weight_kg": 65.20,
    "bmi": 27.1,
    "notes": "Weekly check"
  }'
curl -X POST http://127.0.0.1:8000/api/v1/health/weight \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "log_date": "2026-04-23",
    "weight_kg": 64.70,
    "bmi": 26.9,
    "notes": "Good progress"
  }'
Get logs
curl http://127.0.0.1:8000/api/v1/health/weight \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"
Get summary and trend analysis
curl http://127.0.0.1:8000/api/v1/health/weight/summary \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"

Expected response:

{
  "success": true,
  "message": "Weight summary retrieved successfully.",
  "data": {
    "total_logs": 3,
    "min_weight": 64,
    "max_weight": 65.2,
    "average_weight": 64.63,
    "latest_weight": 64,
    "first_weight": 65.2,
    "weight_change": -1.2,
    "trend_direction": "decreasing",
    "latest_date": "2026-04-26",
    "first_date": "2026-04-20",
    "chart": [
      {
        "date": "2026-04-20",
        "weight_kg": 65.2,
        "bmi": 27.1,
        "body_fat_percentage": null,
        "muscle_mass_kg": null
      }
    ]
  }
}
7. Frontend — Install Chart Library

Go to frontend:

cd /u01/nix-life-os/frontend

Install Recharts:

npm install recharts
8. Frontend — Create API Service

Create folder if missing:

mkdir -p src/services

Create file:

nano src/services/healthWeightApi.js

Add:

const API_BASE_URL = "http://127.0.0.1:8000/api/v1";

function getToken() {
  return localStorage.getItem("token");
}

async function request(path, options = {}) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
  });

  const data = await response.json();

  if (!response.ok) {
    throw data;
  }

  return data;
}

export const healthWeightApi = {
  getLogs() {
    return request("/health/weight");
  },

  getSummary() {
    return request("/health/weight/summary");
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

Important: if your token key is not token, use the same key you used in login. For example:

localStorage.getItem("auth_token")
9. Frontend — Create Weight View

Create:

mkdir -p src/views/health
nano src/views/health/HealthWeightView.vue

Add:

<script setup>
import { onMounted, reactive, ref } from "vue";
import {
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { healthWeightApi } from "@/services/healthWeightApi";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const logs = ref([]);
const summary = ref({
  total_logs: 0,
  min_weight: null,
  max_weight: null,
  average_weight: null,
  latest_weight: null,
  first_weight: null,
  weight_change: null,
  trend_direction: "no_data",
  chart: [],
});

const form = reactive({
  id: null,
  log_date: new Date().toISOString().slice(0, 10),
  weight_kg: "",
  body_fat_percentage: "",
  muscle_mass_kg: "",
  bmi: "",
  notes: "",
});

function resetForm() {
  form.id = null;
  form.log_date = new Date().toISOString().slice(0, 10);
  form.weight_kg = "";
  form.body_fat_percentage = "";
  form.muscle_mass_kg = "";
  form.bmi = "";
  form.notes = "";
}

function normalizePayload() {
  return {
    log_date: form.log_date,
    weight_kg: Number(form.weight_kg),
    body_fat_percentage: form.body_fat_percentage
      ? Number(form.body_fat_percentage)
      : null,
    muscle_mass_kg: form.muscle_mass_kg ? Number(form.muscle_mass_kg) : null,
    bmi: form.bmi ? Number(form.bmi) : null,
    notes: form.notes || null,
  };
}

async function loadData() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const [logsResponse, summaryResponse] = await Promise.all([
      healthWeightApi.getLogs(),
      healthWeightApi.getSummary(),
    ]);

    logs.value = logsResponse.data.data || [];
    summary.value = summaryResponse.data;
  } catch (error) {
    errorMessage.value =
      error?.message || "Failed to load weight module data.";
  } finally {
    loading.value = false;
  }
}

async function saveLog() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const payload = normalizePayload();

    if (form.id) {
      await healthWeightApi.updateLog(form.id, payload);
      successMessage.value = "Weight log updated successfully.";
    } else {
      await healthWeightApi.createLog(payload);
      successMessage.value = "Weight log added successfully.";
    }

    resetForm();
    await loadData();
  } catch (error) {
    if (error?.errors) {
      errorMessage.value = Object.values(error.errors).flat().join(" ");
    } else {
      errorMessage.value = error?.message || "Failed to save weight log.";
    }
  } finally {
    saving.value = false;
  }
}

function editLog(log) {
  form.id = log.id;
  form.log_date = log.log_date;
  form.weight_kg = log.weight_kg;
  form.body_fat_percentage = log.body_fat_percentage || "";
  form.muscle_mass_kg = log.muscle_mass_kg || "";
  form.bmi = log.bmi || "";
  form.notes = log.notes || "";
}

async function deleteLog(id) {
  if (!confirm("Are you sure you want to delete this weight log?")) {
    return;
  }

  errorMessage.value = "";
  successMessage.value = "";

  try {
    await healthWeightApi.deleteLog(id);
    successMessage.value = "Weight log deleted successfully.";
    await loadData();
  } catch (error) {
    errorMessage.value = error?.message || "Failed to delete weight log.";
  }
}

function trendBadgeClass(direction) {
  if (direction === "decreasing") {
    return "bg-green-100 text-green-700";
  }

  if (direction === "increasing") {
    return "bg-orange-100 text-orange-700";
  }

  if (direction === "stable") {
    return "bg-blue-100 text-blue-700";
  }

  return "bg-gray-100 text-gray-700";
}

onMounted(loadData);
</script>

<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          Weight Tracking
        </h1>
        <p class="mt-1 text-gray-500">
          Track your weight logs, analyze trends, and monitor progress.
        </p>
      </div>

      <div v-if="errorMessage" class="rounded-xl bg-red-50 p-4 text-red-700">
        {{ errorMessage }}
      </div>

      <div
        v-if="successMessage"
        class="rounded-xl bg-green-50 p-4 text-green-700"
      >
        {{ successMessage }}
      </div>

      <div class="grid grid-cols-1 gap-4 md:grid-cols-5">
        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Latest Weight</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.latest_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Average</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.average_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Minimum</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.min_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Maximum</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.max_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Trend</p>
          <div class="mt-2 flex items-center gap-2">
            <span
              class="rounded-full px-3 py-1 text-sm font-semibold"
              :class="trendBadgeClass(summary.trend_direction)"
            >
              {{ summary.trend_direction }}
            </span>
          </div>
          <p class="mt-2 text-sm text-gray-500">
            Change: {{ summary.weight_change ?? "-" }} kg
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="rounded-2xl bg-white p-6 shadow-sm lg:col-span-2">
          <div class="mb-4 flex items-center justify-between">
            <div>
              <h2 class="text-xl font-bold text-gray-900">
                Weight Trend Chart
              </h2>
              <p class="text-sm text-gray-500">
                Your weight movement over time.
              </p>
            </div>
          </div>

          <div v-if="summary.chart?.length" class="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart :data="summary.chart">
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="weight_kg"
                  strokeWidth="3"
                  dot
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          <div
            v-else
            class="flex h-80 items-center justify-center rounded-xl border border-dashed text-gray-400"
          >
            No weight chart data yet.
          </div>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <h2 class="text-xl font-bold text-gray-900">
            {{ form.id ? "Edit Weight Log" : "Add Weight Log" }}
          </h2>

          <form class="mt-5 space-y-4" @submit.prevent="saveLog">
            <div>
              <label class="block text-sm font-medium text-gray-700">
                Date
              </label>
              <input
                v-model="form.log_date"
                type="date"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Weight KG
              </label>
              <input
                v-model="form.weight_kg"
                type="number"
                step="0.01"
                min="20"
                max="400"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Body Fat %
              </label>
              <input
                v-model="form.body_fat_percentage"
                type="number"
                step="0.01"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Muscle Mass KG
              </label>
              <input
                v-model="form.muscle_mass_kg"
                type="number"
                step="0.01"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                BMI
              </label>
              <input
                v-model="form.bmi"
                type="number"
                step="0.01"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Notes
              </label>
              <textarea
                v-model="form.notes"
                rows="3"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              ></textarea>
            </div>

            <div class="flex gap-3">
              <button
                type="submit"
                :disabled="saving"
                class="w-full rounded-xl bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {{ saving ? "Saving..." : form.id ? "Update" : "Save" }}
              </button>

              <button
                v-if="form.id"
                type="button"
                @click="resetForm"
                class="rounded-xl border border-gray-300 px-4 py-2 font-semibold text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 shadow-sm">
        <div class="mb-4 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">
              Weight Logs
            </h2>
            <p class="text-sm text-gray-500">
              Complete history of your weight records.
            </p>
          </div>
        </div>

        <div v-if="loading" class="py-10 text-center text-gray-500">
          Loading weight logs...
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b bg-gray-50 text-sm text-gray-600">
                <th class="px-4 py-3">Date</th>
                <th class="px-4 py-3">Weight</th>
                <th class="px-4 py-3">BMI</th>
                <th class="px-4 py-3">Body Fat</th>
                <th class="px-4 py-3">Muscle Mass</th>
                <th class="px-4 py-3">Notes</th>
                <th class="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="log in logs"
                :key="log.id"
                class="border-b text-sm hover:bg-gray-50"
              >
                <td class="px-4 py-3 font-medium text-gray-900">
                  {{ log.log_date }}
                </td>
                <td class="px-4 py-3">
                  {{ log.weight_kg }} kg
                </td>
                <td class="px-4 py-3">
                  {{ log.bmi ?? "-" }}
                </td>
                <td class="px-4 py-3">
                  {{ log.body_fat_percentage ?? "-" }}
                </td>
                <td class="px-4 py-3">
                  {{ log.muscle_mass_kg ?? "-" }}
                </td>
                <td class="px-4 py-3 text-gray-500">
                  {{ log.notes ?? "-" }}
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    class="mr-3 font-semibold text-blue-600 hover:text-blue-800"
                    @click="editLog(log)"
                  >
                    Edit
                  </button>
                  <button
                    class="font-semibold text-red-600 hover:text-red-800"
                    @click="deleteLog(log.id)"
                  >
                    Delete
                  </button>
                </td>
              </tr>

              <tr v-if="logs.length === 0">
                <td colspan="7" class="px-4 py-10 text-center text-gray-400">
                  No weight logs yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
10. Frontend — Add Route

Open your router file:

nano src/router/index.js

Add import:

import HealthWeightView from "@/views/health/HealthWeightView.vue";

Add route:

{
  path: "/health/weight",
  name: "health-weight",
  component: HealthWeightView,
}

Example:

import { createRouter, createWebHistory } from "vue-router";
import HealthWeightView from "@/views/health/HealthWeightView.vue";

const routes = [
  {
    path: "/health/weight",
    name: "health-weight",
    component: HealthWeightView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

Do not delete your existing routes. Only add the new import and route.

11. Optional — Add Link in Sidebar/Menu

Wherever your menu is located, add:

<RouterLink
  to="/health/weight"
  class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
>
  Weight Tracking
</RouterLink>
12. Start Servers

Backend:

cd /u01/nix-life-os/backend
php artisan serve

Frontend:

cd /u01/nix-life-os/frontend
npm run dev

Open:

http://localhost:5173/health/weight
13. Common Fixes
If controller not found

Run:

composer dump-autoload
php artisan optimize:clear
If API returns unauthenticated

Check browser localStorage:

localStorage.getItem("token")

If your login stores another name, update this in:

src/services/healthWeightApi.js

Example:

return localStorage.getItem("auth_token");
If Recharts import fails

Restart frontend:

npm run dev

If still failing:

rm -rf node_modules package-lock.json
npm install
npm install recharts
npm run dev
STEP 9 Completed

You now have:

Feature	Status
Weight logs table	Done
Add weight log	Done
Update weight log	Done
Delete weight log	Done
List logs	Done
Min weight	Done
Max weight	Done
Average weight	Done
Latest weight	Done
Weight change	Done
Trend direction	Done
Chart API data	Done
Vue dashboard cards	Done
Vue chart	Done
Vue table	Done
Vue form	Done
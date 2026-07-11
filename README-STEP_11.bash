STEP 11 — Health Hydration Tracking Module

This module will cover:

Backend

Water / fluid intake tracking
Drink types: water, tea, coffee, juice, soup, milk, other
CKD-safe hydration notes
Daily totals
Daily breakdown by drink type
API endpoints

Frontend

Hydration dashboard
Quick add buttons
Add hydration form
Daily breakdown chart
Hydration logs table

Important: do not share your Bearer token publicly. Use it only locally for testing.

1. Backend — Create Migration

Run:

cd /u01/nix-life-os/backend

php artisan make:model HealthHydrationLog -m

Open the migration file:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_hydration_logs_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_hydration_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            /*
            |--------------------------------------------------------------------------
            | User Relation
            |--------------------------------------------------------------------------
            | IMPORTANT:
            | Your users.id is UUID, so user_id must be UUID also.
            */
            $table->uuid('user_id');

            /*
            |--------------------------------------------------------------------------
            | Hydration Data
            |--------------------------------------------------------------------------
            */
            $table->date('log_date');
            $table->time('log_time')->nullable();

            $table->string('drink_type', 50)->default('water');
            $table->decimal('amount_ml', 8, 2);

            /*
            |--------------------------------------------------------------------------
            | Optional Health Fields
            |--------------------------------------------------------------------------
            */
            $table->boolean('is_ckd_safe')->default(true);
            $table->string('source', 50)->default('manual'); 
            // manual, quick_add, import, wearable

            $table->text('notes')->nullable();

            $table->timestamps();

            /*
            |--------------------------------------------------------------------------
            | Constraints / Indexes
            |--------------------------------------------------------------------------
            */
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'log_date']);
            $table->index(['user_id', 'drink_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_hydration_logs');
    }
};

Run migration:

php artisan migrate
2. Backend — Model

Open:

nano app/Models/HealthHydrationLog.php

Replace with:

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthHydrationLog extends Model
{
    use HasUuids;

    protected $table = 'health_hydration_logs';

    protected $fillable = [
        'user_id',
        'log_date',
        'log_time',
        'drink_type',
        'amount_ml',
        'is_ckd_safe',
        'source',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'amount_ml' => 'decimal:2',
        'is_ckd_safe' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
3. Backend — Request Validation

Run:

php artisan make:request StoreHealthHydrationLogRequest
php artisan make:request UpdateHealthHydrationLogRequest

Open:

nano app/Http/Requests/StoreHealthHydrationLogRequest.php

Replace with:

<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreHealthHydrationLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'log_date' => ['required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'drink_type' => ['required', 'string', 'max:50', 'in:water,tea,coffee,juice,soup,milk,other'],
            'amount_ml' => ['required', 'numeric', 'min:1', 'max:5000'],
            'is_ckd_safe' => ['nullable', 'boolean'],
            'source' => ['nullable', 'string', 'max:50', 'in:manual,quick_add,import,wearable'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}

Open:

nano app/Http/Requests/UpdateHealthHydrationLogRequest.php

Replace with:

<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateHealthHydrationLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'log_date' => ['sometimes', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'drink_type' => ['sometimes', 'string', 'max:50', 'in:water,tea,coffee,juice,soup,milk,other'],
            'amount_ml' => ['sometimes', 'numeric', 'min:1', 'max:5000'],
            'is_ckd_safe' => ['nullable', 'boolean'],
            'source' => ['nullable', 'string', 'max:50', 'in:manual,quick_add,import,wearable'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
4. Backend — API Resource

Run:

php artisan make:resource HealthHydrationLogResource

Open:

nano app/Http/Resources/HealthHydrationLogResource.php

Replace with:

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthHydrationLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'log_date' => optional($this->log_date)->format('Y-m-d'),
            'log_time' => $this->log_time,
            'drink_type' => $this->drink_type,
            'amount_ml' => (float) $this->amount_ml,
            'is_ckd_safe' => (bool) $this->is_ckd_safe,
            'source' => $this->source,
            'notes' => $this->notes,
            'created_at' => optional($this->created_at)->toISOString(),
            'updated_at' => optional($this->updated_at)->toISOString(),
        ];
    }
}
5. Backend — Controller

Run:

php artisan make:controller Api/V1/HealthHydrationLogController

Open:

nano app/Http/Controllers/Api/V1/HealthHydrationLogController.php

Replace with:

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
        $user = $request->user();

        $query = HealthHydrationLog::query()
            ->where('user_id', $user->id);

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
            ->paginate($request->integer('per_page', 15));

        return response()->json([
            'success' => true,
            'message' => 'Hydration logs retrieved successfully.',
            'data' => HealthHydrationLogResource::collection($logs),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
                'last_page' => $logs->lastPage(),
            ],
        ]);
    }

    public function store(StoreHealthHydrationLogRequest $request): JsonResponse
    {
        $user = $request->user();

        $log = HealthHydrationLog::create([
            'user_id' => $user->id,
            'log_date' => $request->log_date,
            'log_time' => $request->log_time ?? now()->format('H:i'),
            'drink_type' => $request->drink_type,
            'amount_ml' => $request->amount_ml,
            'is_ckd_safe' => $request->boolean('is_ckd_safe', true),
            'source' => $request->source ?? 'manual',
            'notes' => $request->notes,
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
            'data' => new HealthHydrationLogResource($log),
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
                'total_liters' => round($totalMl / 1000, 2),
                'breakdown' => $breakdown->map(function ($item) {
                    return [
                        'drink_type' => $item->drink_type,
                        'total_ml' => (float) $item->total_ml,
                        'entries_count' => (int) $item->entries_count,
                    ];
                }),
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

        return response()->json([
            'success' => true,
            'message' => 'Weekly hydration summary retrieved successfully.',
            'data' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'days' => $rows->map(function ($item) {
                    return [
                        'log_date' => Carbon::parse($item->log_date)->format('Y-m-d'),
                        'total_ml' => (float) $item->total_ml,
                        'total_liters' => round($item->total_ml / 1000, 2),
                        'entries_count' => (int) $item->entries_count,
                    ];
                }),
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
            'log_time' => $validated['log_time'] ?? now()->format('H:i'),
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
6. Backend — Routes

Open:

nano routes/api.php

Add the controller import at the top:

use App\Http\Controllers\Api\V1\HealthHydrationLogController;

Inside your authenticated /api/v1 group, add:

Route::prefix('health/hydration')->group(function () {
    Route::get('/', [HealthHydrationLogController::class, 'index']);
    Route::post('/', [HealthHydrationLogController::class, 'store']);

    Route::get('/daily-summary', [HealthHydrationLogController::class, 'dailySummary']);
    Route::get('/weekly-summary', [HealthHydrationLogController::class, 'weeklySummary']);
    Route::post('/quick-add', [HealthHydrationLogController::class, 'quickAdd']);

    Route::get('/{id}', [HealthHydrationLogController::class, 'show']);
    Route::put('/{id}', [HealthHydrationLogController::class, 'update']);
    Route::delete('/{id}', [HealthHydrationLogController::class, 'destroy']);
});

Your structure should look like this:

Route::prefix('v1')->group(function () {

    // Public auth routes here...

    Route::middleware('auth:sanctum')->group(function () {

        Route::prefix('health/hydration')->group(function () {
            Route::get('/', [HealthHydrationLogController::class, 'index']);
            Route::post('/', [HealthHydrationLogController::class, 'store']);

            Route::get('/daily-summary', [HealthHydrationLogController::class, 'dailySummary']);
            Route::get('/weekly-summary', [HealthHydrationLogController::class, 'weeklySummary']);
            Route::post('/quick-add', [HealthHydrationLogController::class, 'quickAdd']);

            Route::get('/{id}', [HealthHydrationLogController::class, 'show']);
            Route::put('/{id}', [HealthHydrationLogController::class, 'update']);
            Route::delete('/{id}', [HealthHydrationLogController::class, 'destroy']);
        });

    });
});

Then run:

php artisan optimize:clear
composer dump-autoload
7. Backend — Test With Curl
7.1 Create Hydration Log
curl -X POST http://127.0.0.1:8000/api/v1/health/hydration \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer REDACTED_TOKEN" \
  -d '{
    "log_date": "2026-04-26",
    "log_time": "09:30",
    "drink_type": "water",
    "amount_ml": 250,
    "is_ckd_safe": true,
    "source": "manual",
    "notes": "Morning water"
  }'

Expected result:

{
  "success": true,
  "message": "Hydration log created successfully.",
  "data": {
    "id": "...",
    "user_id": "...",
    "log_date": "2026-04-26",
    "log_time": "09:30",
    "drink_type": "water",
    "amount_ml": 250,
    "is_ckd_safe": true,
    "source": "manual",
    "notes": "Morning water"
  }
}
7.2 Quick Add 250ml
curl -X POST http://127.0.0.1:8000/api/v1/health/hydration/quick-add \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer REDACTED_TOKEN" \
  -d '{
    "amount_ml": 250,
    "drink_type": "water"
  }'
7.3 Get Hydration Logs
curl -X GET "http://127.0.0.1:8000/api/v1/health/hydration?date=2026-04-26" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer REDACTED_TOKEN"
7.4 Get Daily Summary
curl -X GET "http://127.0.0.1:8000/api/v1/health/hydration/daily-summary?date=2026-04-26" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer REDACTED_TOKEN"
7.5 Get Weekly Summary
curl -X GET "http://127.0.0.1:8000/api/v1/health/hydration/weekly-summary?start_date=2026-04-20&end_date=2026-04-26" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer REDACTED_TOKEN"
8. Frontend — Create View

Go to frontend:

cd /u01/nix-life-os/frontend

Create file:

nano src/views/HealthHydrationView.vue

Add:

<script setup>
import { computed, onMounted, ref } from "vue";

const API_BASE_URL = "http://127.0.0.1:8000/api/v1";

const token = localStorage.getItem("token");

const logs = ref([]);
const dailySummary = ref(null);
const weeklySummary = ref([]);
const loading = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const today = new Date().toISOString().slice(0, 10);

const selectedDate = ref(today);

const form = ref({
  log_date: today,
  log_time: "",
  drink_type: "water",
  amount_ml: 250,
  is_ckd_safe: true,
  source: "manual",
  notes: "",
});

const drinkTypes = [
  { value: "water", label: "Water" },
  { value: "tea", label: "Tea" },
  { value: "coffee", label: "Coffee" },
  { value: "juice", label: "Juice" },
  { value: "soup", label: "Soup" },
  { value: "milk", label: "Milk" },
  { value: "other", label: "Other" },
];

const quickAmounts = [100, 150, 200, 250, 300, 500];

const totalMl = computed(() => {
  return dailySummary.value?.total_ml || 0;
});

const totalLiters = computed(() => {
  return dailySummary.value?.total_liters || 0;
});

const hydrationGoalMl = 2000;

const progressPercentage = computed(() => {
  const percentage = (totalMl.value / hydrationGoalMl) * 100;
  return Math.min(Math.round(percentage), 100);
});

async function apiRequest(endpoint, options = {}) {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
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
    throw new Error(data.message || "API request failed");
  }

  return data;
}

async function fetchLogs() {
  const data = await apiRequest(
    `/health/hydration?date=${selectedDate.value}&per_page=50`
  );

  logs.value = data.data?.data || data.data || [];
}

async function fetchDailySummary() {
  const data = await apiRequest(
    `/health/hydration/daily-summary?date=${selectedDate.value}`
  );

  dailySummary.value = data.data;
}

async function fetchWeeklySummary() {
  const currentDate = new Date(selectedDate.value);
  const day = currentDate.getDay();

  const diffToMonday = day === 0 ? -6 : 1 - day;

  const monday = new Date(currentDate);
  monday.setDate(currentDate.getDate() + diffToMonday);

  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);

  const startDate = monday.toISOString().slice(0, 10);
  const endDate = sunday.toISOString().slice(0, 10);

  const data = await apiRequest(
    `/health/hydration/weekly-summary?start_date=${startDate}&end_date=${endDate}`
  );

  weeklySummary.value = data.data?.days || [];
}

async function loadDashboard() {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await Promise.all([
      fetchLogs(),
      fetchDailySummary(),
      fetchWeeklySummary(),
    ]);
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function submitForm() {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await apiRequest("/health/hydration", {
      method: "POST",
      body: JSON.stringify({
        ...form.value,
        amount_ml: Number(form.value.amount_ml),
      }),
    });

    successMessage.value = "Hydration log added successfully.";

    form.value.amount_ml = 250;
    form.value.drink_type = "water";
    form.value.notes = "";

    await loadDashboard();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function quickAdd(amount) {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await apiRequest("/health/hydration/quick-add", {
      method: "POST",
      body: JSON.stringify({
        amount_ml: amount,
        drink_type: "water",
        log_date: selectedDate.value,
      }),
    });

    successMessage.value = `${amount}ml water added successfully.`;

    await loadDashboard();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function deleteLog(id) {
  if (!confirm("Are you sure you want to delete this hydration log?")) {
    return;
  }

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await apiRequest(`/health/hydration/${id}`, {
      method: "DELETE",
    });

    successMessage.value = "Hydration log deleted successfully.";

    await loadDashboard();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

function getDrinkLabel(value) {
  return drinkTypes.find((item) => item.value === value)?.label || value;
}

function getMaxChartValue() {
  const values = weeklySummary.value.map((item) => Number(item.total_ml));
  return Math.max(...values, hydrationGoalMl);
}

onMounted(() => {
  loadDashboard();
});
</script>

<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <!-- Header -->
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">
            Hydration Tracking
          </h1>
          <p class="mt-1 text-gray-600">
            Track daily water and fluid intake with quick add and drink breakdown.
          </p>
        </div>

        <div class="flex items-center gap-3">
          <input
            v-model="selectedDate"
            type="date"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 shadow-sm focus:border-blue-500 focus:outline-none"
            @change="loadDashboard"
          />

          <button
            class="rounded-xl bg-blue-600 px-5 py-2 font-semibold text-white shadow hover:bg-blue-700 disabled:opacity-50"
            :disabled="loading"
            @click="loadDashboard"
          >
            Refresh
          </button>
        </div>
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

      <!-- Dashboard Cards -->
      <div class="grid gap-6 md:grid-cols-4">
        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Today Intake</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ totalMl }} ml
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            {{ totalLiters }} liters
          </p>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Daily Goal</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ hydrationGoalMl }} ml
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            CKD users should follow doctor limits.
          </p>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Progress</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ progressPercentage }}%
          </h2>

          <div class="mt-4 h-3 rounded-full bg-gray-200">
            <div
              class="h-3 rounded-full bg-blue-600"
              :style="{ width: progressPercentage + '%' }"
            ></div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Entries</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ logs.length }}
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Total logs for selected date
          </p>
        </div>
      </div>

      <!-- Quick Add -->
      <div class="rounded-2xl bg-white p-6 shadow">
        <div class="mb-4 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">Quick Add Water</h2>
            <p class="text-sm text-gray-500">
              Add common water amounts with one click.
            </p>
          </div>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            v-for="amount in quickAmounts"
            :key="amount"
            class="rounded-xl bg-blue-50 px-5 py-3 font-semibold text-blue-700 hover:bg-blue-100 disabled:opacity-50"
            :disabled="loading"
            @click="quickAdd(amount)"
          >
            + {{ amount }} ml
          </button>
        </div>
      </div>

      <div class="grid gap-6 lg:grid-cols-3">
        <!-- Form -->
        <div class="rounded-2xl bg-white p-6 shadow lg:col-span-1">
          <h2 class="text-xl font-bold text-gray-900">Add Drink</h2>

          <form class="mt-5 space-y-4" @submit.prevent="submitForm">
            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Date
              </label>
              <input
                v-model="form.log_date"
                type="date"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Time
              </label>
              <input
                v-model="form.log_time"
                type="time"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Drink Type
              </label>
              <select
                v-model="form.drink_type"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              >
                <option
                  v-for="drink in drinkTypes"
                  :key="drink.value"
                  :value="drink.value"
                >
                  {{ drink.label }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Amount ML
              </label>
              <input
                v-model="form.amount_ml"
                type="number"
                min="1"
                max="5000"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Notes
              </label>
              <textarea
                v-model="form.notes"
                rows="3"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
                placeholder="Optional notes..."
              ></textarea>
            </div>

            <button
              type="submit"
              class="w-full rounded-xl bg-blue-600 px-5 py-3 font-semibold text-white shadow hover:bg-blue-700 disabled:opacity-50"
              :disabled="loading"
            >
              Add Hydration Log
            </button>
          </form>
        </div>

        <!-- Daily Breakdown -->
        <div class="rounded-2xl bg-white p-6 shadow lg:col-span-2">
          <h2 class="text-xl font-bold text-gray-900">Daily Drink Breakdown</h2>
          <p class="mt-1 text-sm text-gray-500">
            Breakdown by drink type for {{ selectedDate }}.
          </p>

          <div class="mt-6 space-y-4">
            <div
              v-if="!dailySummary?.breakdown?.length"
              class="rounded-xl bg-gray-50 p-5 text-center text-gray-500"
            >
              No hydration data for this date.
            </div>

            <div
              v-for="item in dailySummary?.breakdown || []"
              :key="item.drink_type"
              class="space-y-2"
            >
              <div class="flex items-center justify-between">
                <span class="font-medium text-gray-700">
                  {{ getDrinkLabel(item.drink_type) }}
                </span>
                <span class="text-sm font-semibold text-gray-900">
                  {{ item.total_ml }} ml
                </span>
              </div>

              <div class="h-3 rounded-full bg-gray-200">
                <div
                  class="h-3 rounded-full bg-blue-600"
                  :style="{
                    width:
                      totalMl > 0
                        ? Math.round((item.total_ml / totalMl) * 100) + '%'
                        : '0%',
                  }"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Weekly Chart -->
      <div class="rounded-2xl bg-white p-6 shadow">
        <h2 class="text-xl font-bold text-gray-900">Weekly Hydration Chart</h2>
        <p class="mt-1 text-sm text-gray-500">
          Daily totals for the selected week.
        </p>

        <div class="mt-6 flex h-72 items-end gap-4 border-b border-gray-200 pb-4">
          <div
            v-for="day in weeklySummary"
            :key="day.log_date"
            class="flex flex-1 flex-col items-center justify-end gap-2"
          >
            <div
              class="w-full rounded-t-xl bg-blue-500"
              :style="{
                height:
                  getMaxChartValue() > 0
                    ? Math.max((day.total_ml / getMaxChartValue()) * 220, 8) + 'px'
                    : '8px',
              }"
            ></div>

            <div class="text-center">
              <p class="text-xs font-semibold text-gray-700">
                {{ day.total_ml }}ml
              </p>
              <p class="text-xs text-gray-500">
                {{ day.log_date.slice(5) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Logs Table -->
      <div class="rounded-2xl bg-white p-6 shadow">
        <h2 class="text-xl font-bold text-gray-900">Hydration Logs</h2>

        <div class="mt-5 overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead>
              <tr class="bg-gray-50">
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Date
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Time
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Drink
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Amount
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Source
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Notes
                </th>
                <th class="px-4 py-3 text-right text-sm font-semibold text-gray-600">
                  Action
                </th>
              </tr>
            </thead>

            <tbody class="divide-y divide-gray-100">
              <tr v-if="!logs.length">
                <td colspan="7" class="px-4 py-6 text-center text-gray-500">
                  No hydration logs found.
                </td>
              </tr>

              <tr v-for="log in logs" :key="log.id">
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.log_date }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.log_time || "-" }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ getDrinkLabel(log.drink_type) }}
                </td>
                <td class="px-4 py-3 text-sm font-semibold text-gray-900">
                  {{ log.amount_ml }} ml
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.source }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.notes || "-" }}
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    class="rounded-lg bg-red-50 px-3 py-1 text-sm font-semibold text-red-600 hover:bg-red-100"
                    @click="deleteLog(log.id)"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </div>
  </div>
</template>
9. Frontend — Add Route

Open:

nano src/router/index.js

Add import:

import HealthHydrationView from "../views/HealthHydrationView.vue";

Add route:

{
  path: "/health/hydration",
  name: "health-hydration",
  component: HealthHydrationView,
}

Example:

import { createRouter, createWebHistory } from "vue-router";
import HealthHydrationView from "../views/HealthHydrationView.vue";

const routes = [
  {
    path: "/health/hydration",
    name: "health-hydration",
    component: HealthHydrationView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

If you already have many routes, only add the new import and route object.

10. Frontend — Update App.vue Navigation

Open:

nano src/App.vue

Use this clean version:

<script setup>
import { RouterLink, RouterView } from "vue-router";
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <div class="flex">
      <!-- Sidebar -->
      <aside class="min-h-screen w-72 bg-white p-6 shadow">
        <h1 class="mb-8 text-2xl font-bold text-gray-900">
          NIX LIFE OS
        </h1>

        <nav class="space-y-2">
          <RouterLink
            to="/finance/accounts"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Finance Accounts
          </RouterLink>

          <RouterLink
            to="/finance/transactions"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Finance Transactions
          </RouterLink>

          <RouterLink
            to="/finance/budgets"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Finance Budgets
          </RouterLink>

          <RouterLink
            to="/health/steps"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Steps Tracking
          </RouterLink>

          <RouterLink
            to="/health/weight"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Weight Tracking
          </RouterLink>

          <RouterLink
            to="/health/nutrition"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Nutrition Tracking
          </RouterLink>

          <RouterLink
            to="/health/hydration"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Hydration Tracking
          </RouterLink>
        </nav>
      </aside>

      <!-- Main Content -->
      <main class="flex-1">
        <RouterView />
      </main>
    </div>
  </div>
</template>
11. Frontend — Store Token Temporarily

Since the frontend reads:

const token = localStorage.getItem("token");

Open browser console and run:

localStorage.setItem("token", "REDACTED_TOKEN");

Then open:

http://localhost:5173/health/hydration
12. Fix Common Errors
Error: Class HealthHydrationLogResource does not exist

Run:

composer dump-autoload
php artisan optimize:clear

Then check:

php artisan tinker

Inside tinker:

class_exists(\App\Http\Resources\HealthHydrationLogResource::class);

Expected:

= true
Error: foreign key incompatible type

This means your users.id is UUID but your migration used bigint.

Correct version:

$table->uuid('user_id');

Not:

$table->foreignId('user_id');
Error: route not found

Run:

php artisan route:list | grep hydration

Expected routes:

GET|HEAD  api/v1/health/hydration
POST      api/v1/health/hydration
GET|HEAD  api/v1/health/hydration/daily-summary
GET|HEAD  api/v1/health/hydration/weekly-summary
POST      api/v1/health/hydration/quick-add
GET|HEAD  api/v1/health/hydration/{id}
PUT       api/v1/health/hydration/{id}
DELETE    api/v1/health/hydration/{id}

If missing:

php artisan optimize:clear
composer dump-autoload
13. Final Test Order

Run these in order:

php artisan migrate
php artisan optimize:clear
composer dump-autoload
php artisan route:list | grep hydration

Then test:

curl -X POST http://127.0.0.1:8000/api/v1/health/hydration/quick-add \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer REDACTED_TOKEN" \
  -d '{
    "amount_ml": 250,
    "drink_type": "water"
  }'

Then open frontend:

http://localhost:5173/health/hydration
Step 11 Completed

After this, your Health module includes:

Steps tracking
Weight tracking
Nutrition profile
Nutrition tracking foundation
Hydration tracking
Daily hydration summaries
Weekly hydration analytics
Quick add buttons
Frontend dashboard with chart and table
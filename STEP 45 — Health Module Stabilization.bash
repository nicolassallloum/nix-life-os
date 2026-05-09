🔹 STEP 45 — Health Module Stabilization
Senior Laravel + Vue.js Engineering Guide for Nix Life OS

This step is for stabilizing the full Health module after completing the individual screens:

Steps Tracking
Weight Tracking
Nutrition Tracking
Hydration Tracking
Sleep Tracking
Mood Tracking
Medication Tracking
Health Dashboard
Shared API service structure
Shared loading and error handling
1. Health Module Route Checks
1.1 Frontend Route Check

Run this:

cd /u01/nix-life-os/frontend

grep -n "health" src/router/index.js

You should confirm these routes exist:

/health
/health/steps
/health/weight
/health/nutrition
/health/hydration
/health/sleep
/health/mood
/health/medications
/health/lab-tests

Recommended route structure:

{
  path: "/health",
  name: "health-dashboard",
  component: HealthView,
  meta: {
    requiresAuth: true,
    title: "Health Dashboard",
  },
},
{
  path: "/health/steps",
  name: "health-steps",
  component: StepsTrackingView,
  meta: {
    requiresAuth: true,
    title: "Steps Tracking",
  },
},
{
  path: "/health/weight",
  name: "health-weight",
  component: WeightTrackingView,
  meta: {
    requiresAuth: true,
    title: "Weight Tracking",
  },
},
{
  path: "/health/nutrition",
  name: "health-nutrition",
  component: NutritionTrackingView,
  meta: {
    requiresAuth: true,
    title: "Nutrition Tracking",
  },
},
{
  path: "/health/hydration",
  name: "health-hydration",
  component: HydrationTrackingView,
  meta: {
    requiresAuth: true,
    title: "Hydration Tracking",
  },
},
{
  path: "/health/sleep",
  name: "health-sleep",
  component: SleepTrackingView,
  meta: {
    requiresAuth: true,
    title: "Sleep Tracking",
  },
},
{
  path: "/health/mood",
  name: "health-mood",
  component: MoodTrackingView,
  meta: {
    requiresAuth: true,
    title: "Mood Tracking",
  },
},
{
  path: "/health/medications",
  name: "health-medications",
  component: MedicationTrackingView,
  meta: {
    requiresAuth: true,
    title: "Medication Tracking",
  },
},
{
  path: "/health/lab-tests",
  name: "health-lab-tests",
  component: LabTestsView,
  meta: {
    requiresAuth: true,
    title: "Lab Tests",
  },
}
1.2 Sidebar / Menu Check

Run:

cd /u01/nix-life-os/frontend

grep -R "Health" -n src/layouts src/App.vue
grep -R "Medication Tracking" -n src/layouts src/App.vue
grep -R "Lab Tests" -n src/layouts src/App.vue

Your Health menu should include:

Health Dashboard
Steps Tracking
Weight Tracking
Nutrition Tracking
Hydration Tracking
Sleep Tracking
Mood Tracking
Medication Tracking
Lab Tests

Recommended menu order:

Health Dashboard
Steps Tracking
Weight Tracking
Nutrition Tracking
Hydration Tracking
Sleep Tracking
Mood Tracking
Medication Tracking
Lab Tests
2. Laravel Backend Route Checks

Run:

cd /u01/nix-life-os/backend

php artisan route:list | grep health

You should have API routes similar to:

GET       api/v1/health/dashboard
GET       api/v1/health/steps
POST      api/v1/health/steps
PUT       api/v1/health/steps/{id}
DELETE    api/v1/health/steps/{id}

GET       api/v1/health/weight
POST      api/v1/health/weight
PUT       api/v1/health/weight/{id}
DELETE    api/v1/health/weight/{id}

GET       api/v1/health/nutrition
POST      api/v1/health/nutrition
PUT       api/v1/health/nutrition/{id}
DELETE    api/v1/health/nutrition/{id}

GET       api/v1/health/hydration
POST      api/v1/health/hydration
PUT       api/v1/health/hydration/{id}
DELETE    api/v1/health/hydration/{id}

GET       api/v1/health/sleep
POST      api/v1/health/sleep
PUT       api/v1/health/sleep/{id}
DELETE    api/v1/health/sleep/{id}

GET       api/v1/health/mood
POST      api/v1/health/mood
PUT       api/v1/health/mood/{id}
DELETE    api/v1/health/mood/{id}

GET       api/v1/health/medications
POST      api/v1/health/medications
PUT       api/v1/health/medications/{id}
DELETE    api/v1/health/medications/{id}

GET       api/v1/health/lab-tests
POST      api/v1/health/lab-tests
PUT       api/v1/health/lab-tests/{id}
DELETE    api/v1/health/lab-tests/{id}

If routes are missing, check:

nano routes/api.php

Recommended structure:

Route::middleware('auth:sanctum')->prefix('v1/health')->group(function () {
    Route::get('/dashboard', [HealthDashboardController::class, 'summary']);

    Route::apiResource('steps', HealthStepController::class);
    Route::apiResource('weight', HealthWeightController::class);
    Route::apiResource('nutrition', HealthNutritionController::class);
    Route::apiResource('hydration', HealthHydrationController::class);
    Route::apiResource('sleep', HealthSleepController::class);
    Route::apiResource('mood', HealthMoodController::class);
    Route::apiResource('medications', HealthMedicationController::class);
    Route::apiResource('lab-tests', HealthLabTestController::class);
});
3. Shared API Service Stabilization

You should avoid having every screen use different API logic.

Current files:

cd /u01/nix-life-os/frontend

find src/services -type f

You already have files like:

src/services/api.js
src/services/healthService.js
src/services/healthWeightApi.js
src/services/dashboardApi.js

Recommended final structure:

src/services/api.js
src/services/healthService.js
src/services/dashboardApi.js
src/services/projectService.js

Avoid too many health-specific API files unless necessary.

3.1 Recommended src/services/api.js
import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1",
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
});

api.interceptors.request.use(
  (config) => {
    const token =
      localStorage.getItem("token") ||
      localStorage.getItem("auth_token") ||
      localStorage.getItem("access_token");

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;

    if (status === 401) {
      console.warn("Unauthorized request. Token may be missing or expired.");
    }

    if (status === 422) {
      console.warn("Validation error:", error.response?.data?.errors);
    }

    if (status >= 500) {
      console.error("Server error:", error.response?.data || error.message);
    }

    return Promise.reject(error);
  }
);

export default api;
3.2 Recommended src/services/healthService.js
import api from "./api";

const healthService = {
  dashboard() {
    return api.get("/health/dashboard");
  },

  steps: {
    list(params = {}) {
      return api.get("/health/steps", { params });
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

  labTests: {
    list(params = {}) {
      return api.get("/health/lab-tests", { params });
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
  },
};

export default healthService;
4. Shared Loading and Error Handling Pattern

Every Health screen should use the same state pattern:

const loading = ref(false);
const saving = ref(false);
const error = ref("");
const successMessage = ref("");

Recommended reusable function inside each component:

const getErrorMessage = (err) => {
  if (err.response?.data?.message) {
    return err.response.data.message;
  }

  if (err.response?.data?.errors) {
    return Object.values(err.response.data.errors).flat().join(" ");
  }

  return "Something went wrong. Please try again.";
};

Recommended fetch pattern:

const fetchLogs = async () => {
  loading.value = true;
  error.value = "";

  try {
    const response = await healthService.steps.list();
    logs.value = response.data.data || response.data || [];
  } catch (err) {
    error.value = getErrorMessage(err);
  } finally {
    loading.value = false;
  }
};

Recommended save pattern:

const saveLog = async () => {
  saving.value = true;
  error.value = "";
  successMessage.value = "";

  try {
    if (form.value.id) {
      await healthService.steps.update(form.value.id, form.value);
      successMessage.value = "Log updated successfully.";
    } else {
      await healthService.steps.create(form.value);
      successMessage.value = "Log created successfully.";
    }

    resetForm();
    await fetchLogs();
  } catch (err) {
    error.value = getErrorMessage(err);
  } finally {
    saving.value = false;
  }
};

Recommended delete pattern:

const deleteLog = async (id) => {
  if (!confirm("Are you sure you want to delete this log?")) return;

  loading.value = true;
  error.value = "";

  try {
    await healthService.steps.delete(id);
    successMessage.value = "Log deleted successfully.";
    await fetchLogs();
  } catch (err) {
    error.value = getErrorMessage(err);
  } finally {
    loading.value = false;
  }
};
5. API Checks with CURL

First login and export token:

cd /u01/nix-life-os/backend

curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{
  "email": "test@nixlifeos.com",
  "password": "password"
}' | jq

Export token:

export TOKEN="PASTE_TOKEN_HERE"

Test authenticated user:

curl -s "http://127.0.0.1:8000/api/v1/auth/me" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN" | jq
5.1 Health Dashboard API
curl -s "http://127.0.0.1:8000/api/v1/health/dashboard" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN" | jq

Expected response:

{
  "success": true,
  "data": {
    "steps": {},
    "weight": {},
    "nutrition": {},
    "hydration": {},
    "sleep": {},
    "mood": {},
    "medications": {},
    "lab_tests": {}
  }
}
5.2 Steps API
curl -s "http://127.0.0.1:8000/api/v1/health/steps" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN" | jq

Create:

curl -s -X POST "http://127.0.0.1:8000/api/v1/health/steps" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "log_date": "2026-05-09",
  "steps": 7500,
  "goal_steps": 10000,
  "distance_km": 5.2,
  "calories_burned": 230,
  "notes": "Stabilization test"
}' | jq

Expected:

{
  "success": true,
  "message": "Step log created successfully.",
  "data": {
    "id": "...",
    "log_date": "2026-05-09",
    "steps": 7500
  }
}
5.3 Weight API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/weight" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "log_date": "2026-05-09",
  "weight_kg": 64.5,
  "target_weight_kg": 60,
  "notes": "Morning weight"
}' | jq
5.4 Nutrition API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/nutrition" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "log_date": "2026-05-09",
  "meal_type": "lunch",
  "food_name": "Grilled chicken with rice",
  "quantity": "1 plate",
  "calories": 520,
  "protein_g": 28,
  "sodium_mg": 450,
  "potassium_mg": 350,
  "phosphorus_mg": 240,
  "notes": "Kidney-friendly portion"
}' | jq
5.5 Hydration API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "log_date": "2026-05-09",
  "amount_ml": 250,
  "goal_ml": 1500,
  "drink_type": "water",
  "notes": "Morning glass"
}' | jq
5.6 Sleep API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/sleep" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "sleep_date": "2026-05-09",
  "bed_time": "23:30",
  "wake_time": "07:00",
  "sleep_hours": 7.5,
  "sleep_quality": "good",
  "notes": "Good sleep"
}' | jq
5.7 Mood API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/mood" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "mood_date": "2026-05-09",
  "mood": "calm",
  "mood_score": 8,
  "energy_level": 7,
  "stress_level": 3,
  "notes": "Stable mood"
}' | jq
5.8 Medication API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/medications" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "medication_name": "Medication Test",
  "dose": "1 tablet",
  "daily_dose": "1 tablet daily",
  "time_of_day": "08:00",
  "start_date": "2026-05-09",
  "end_date": null,
  "status": "active",
  "notes": "Test medication"
}' | jq
5.9 Lab Tests API
curl -s -X POST "http://127.0.0.1:8000/api/v1/health/lab-tests" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "test_date": "2026-05-09",
  "test_name": "Creatinine",
  "result_value": "2.1",
  "unit": "mg/dL",
  "reference_range": "0.7 - 1.3",
  "lab_name": "Test Lab",
  "notes": "Kidney monitoring"
}' | jq
6. Laravel Controller Stabilization

Every Health controller should follow this pattern:

public function index(Request $request)
{
    $logs = ModelName::where('user_id', $request->user()->id)
        ->latest()
        ->paginate($request->get('per_page', 20));

    return response()->json([
        'success' => true,
        'data' => $logs,
    ]);
}

Create pattern:

public function store(Request $request)
{
    $validated = $request->validate([
        'log_date' => ['required', 'date'],
        // other fields
    ]);

    $validated['user_id'] = $request->user()->id;

    $record = ModelName::create($validated);

    return response()->json([
        'success' => true,
        'message' => 'Record created successfully.',
        'data' => $record,
    ], 201);
}

Update pattern:

public function update(Request $request, string $id)
{
    $record = ModelName::where('user_id', $request->user()->id)
        ->where('id', $id)
        ->firstOrFail();

    $validated = $request->validate([
        'log_date' => ['sometimes', 'date'],
        // other fields
    ]);

    $record->update($validated);

    return response()->json([
        'success' => true,
        'message' => 'Record updated successfully.',
        'data' => $record,
    ]);
}

Delete pattern:

public function destroy(Request $request, string $id)
{
    $record = ModelName::where('user_id', $request->user()->id)
        ->where('id', $id)
        ->firstOrFail();

    $record->delete();

    return response()->json([
        'success' => true,
        'message' => 'Record deleted successfully.',
    ]);
}

Important rule:

where('user_id', $request->user()->id)

must be used in every index, update, show, and delete method to prevent users from accessing each other’s health data.

7. Laravel Model Checks

Run:

cd /u01/nix-life-os/backend

find app/Models -iname "*Health*"

Each model should have:

protected $fillable = [
    'user_id',
    // module fields
];

protected $casts = [
    'log_date' => 'date',
    'created_at' => 'datetime',
    'updated_at' => 'datetime',
];

For UUID tables, also check:

use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthStepLog extends Model
{
    use HasUuids;
}
8. Database Validation Queries

Connect to PostgreSQL:

cd /u01/nix-life-os/backend

php artisan tinker

Or use psql:

docker exec -it nixlifeos-postgres psql -U postgres -d nix_life_os
8.1 Check Health Tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name ILIKE '%health%'
ORDER BY table_name;

Expected tables:

health_step_logs
health_weight_logs
health_nutrition_logs
health_hydration_logs
health_sleep_logs
health_mood_logs
health_medications
health_lab_tests
8.2 Check User ID Column Types
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name ILIKE 'health%'
AND column_name = 'user_id'
ORDER BY table_name;

Important:

If users.id is UUID, then all health_*.user_id must also be UUID.

Check users table:

SELECT 
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name = 'id';
8.3 Check Row Counts
SELECT 'health_step_logs' AS table_name, COUNT(*) FROM health_step_logs
UNION ALL
SELECT 'health_weight_logs', COUNT(*) FROM health_weight_logs
UNION ALL
SELECT 'health_nutrition_logs', COUNT(*) FROM health_nutrition_logs
UNION ALL
SELECT 'health_hydration_logs', COUNT(*) FROM health_hydration_logs
UNION ALL
SELECT 'health_sleep_logs', COUNT(*) FROM health_sleep_logs
UNION ALL
SELECT 'health_mood_logs', COUNT(*) FROM health_mood_logs
UNION ALL
SELECT 'health_medications', COUNT(*) FROM health_medications
UNION ALL
SELECT 'health_lab_tests', COUNT(*) FROM health_lab_tests;
8.4 Check Latest Health Data
SELECT * FROM health_step_logs ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_weight_logs ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_nutrition_logs ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_hydration_logs ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_sleep_logs ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_mood_logs ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_medications ORDER BY created_at DESC LIMIT 5;
SELECT * FROM health_lab_tests ORDER BY created_at DESC LIMIT 5;
8.5 Check Duplicate Logs by Date
SELECT user_id, log_date, COUNT(*)
FROM health_step_logs
GROUP BY user_id, log_date
HAVING COUNT(*) > 1;

For weight:

SELECT user_id, log_date, COUNT(*)
FROM health_weight_logs
GROUP BY user_id, log_date
HAVING COUNT(*) > 1;

For hydration:

SELECT user_id, log_date, COUNT(*), SUM(amount_ml) AS total_ml
FROM health_hydration_logs
GROUP BY user_id, log_date
ORDER BY log_date DESC;

For nutrition:

SELECT 
    user_id,
    log_date,
    SUM(calories) AS total_calories,
    SUM(protein_g) AS total_protein,
    SUM(sodium_mg) AS total_sodium,
    SUM(potassium_mg) AS total_potassium,
    SUM(phosphorus_mg) AS total_phosphorus
FROM health_nutrition_logs
GROUP BY user_id, log_date
ORDER BY log_date DESC;
9. Health Dashboard Stabilization

The dashboard should not use static data.

It should calculate data from real tables.

Recommended dashboard fields:

{
  "success": true,
  "data": {
    "today": {
      "steps": 7500,
      "hydration_ml": 1250,
      "calories": 1450,
      "protein_g": 45,
      "sleep_hours": 7.5,
      "mood_score": 8
    },
    "latest_weight": {
      "weight_kg": 64.5,
      "log_date": "2026-05-09"
    },
    "active_medications": 3,
    "latest_lab_tests": [],
    "goals": {
      "steps_goal": 10000,
      "hydration_goal_ml": 1500
    }
  }
}

Dashboard backend should calculate:

$today = now()->toDateString();

$stepsToday = HealthStepLog::where('user_id', $userId)
    ->whereDate('log_date', $today)
    ->sum('steps');

$hydrationToday = HealthHydrationLog::where('user_id', $userId)
    ->whereDate('log_date', $today)
    ->sum('amount_ml');

$nutritionToday = HealthNutritionLog::where('user_id', $userId)
    ->whereDate('log_date', $today)
    ->selectRaw('
        COALESCE(SUM(calories), 0) as calories,
        COALESCE(SUM(protein_g), 0) as protein_g,
        COALESCE(SUM(sodium_mg), 0) as sodium_mg,
        COALESCE(SUM(potassium_mg), 0) as potassium_mg,
        COALESCE(SUM(phosphorus_mg), 0) as phosphorus_mg
    ')
    ->first();
10. Vue Component Improvements

Each Health page should have the same UI structure:

Page Header
Description
Summary Cards
Error Alert
Success Alert
Form Section
Table Section
Empty State
Loading State

Recommended UI state order:

<div v-if="loading">Loading...</div>

<div v-else-if="error" class="error-box">
  {{ error }}
</div>

<div v-else-if="logs.length === 0" class="empty-box">
  No records found.
</div>

<div v-else>
  <!-- table -->
</div>

Every form button should have disabled saving state:

<button :disabled="saving">
  {{ saving ? "Saving..." : "Save" }}
</button>

Every delete button should have confirmation:

<button @click="deleteLog(item.id)">
  Delete
</button>
11. Validation Rules by Module
11.1 Steps

Laravel validation:

'log_date' => ['required', 'date'],
'steps' => ['required', 'integer', 'min:0', 'max:100000'],
'goal_steps' => ['nullable', 'integer', 'min:0', 'max:100000'],
'distance_km' => ['nullable', 'numeric', 'min:0', 'max:200'],
'calories_burned' => ['nullable', 'numeric', 'min:0', 'max:10000'],
'notes' => ['nullable', 'string', 'max:1000'],
11.2 Weight
'log_date' => ['required', 'date'],
'weight_kg' => ['required', 'numeric', 'min:20', 'max:300'],
'target_weight_kg' => ['nullable', 'numeric', 'min:20', 'max:300'],
'notes' => ['nullable', 'string', 'max:1000'],
11.3 Nutrition
'log_date' => ['required', 'date'],
'meal_type' => ['required', 'string', 'max:50'],
'food_name' => ['required', 'string', 'max:255'],
'quantity' => ['nullable', 'string', 'max:100'],
'calories' => ['nullable', 'numeric', 'min:0', 'max:10000'],
'protein_g' => ['nullable', 'numeric', 'min:0', 'max:300'],
'sodium_mg' => ['nullable', 'numeric', 'min:0', 'max:10000'],
'potassium_mg' => ['nullable', 'numeric', 'min:0', 'max:10000'],
'phosphorus_mg' => ['nullable', 'numeric', 'min:0', 'max:10000'],
'notes' => ['nullable', 'string', 'max:1000'],
11.4 Hydration
'log_date' => ['required', 'date'],
'amount_ml' => ['required', 'integer', 'min:1', 'max:10000'],
'goal_ml' => ['nullable', 'integer', 'min:1', 'max:10000'],
'drink_type' => ['nullable', 'string', 'max:100'],
'notes' => ['nullable', 'string', 'max:1000'],
11.5 Sleep
'sleep_date' => ['required', 'date'],
'bed_time' => ['required', 'date_format:H:i'],
'wake_time' => ['required', 'date_format:H:i'],
'sleep_hours' => ['required', 'numeric', 'min:0', 'max:24'],
'sleep_quality' => ['nullable', 'string', 'max:50'],
'notes' => ['nullable', 'string', 'max:1000'],
11.6 Mood
'mood_date' => ['required', 'date'],
'mood' => ['required', 'string', 'max:100'],
'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
'energy_level' => ['nullable', 'integer', 'min:1', 'max:10'],
'stress_level' => ['nullable', 'integer', 'min:1', 'max:10'],
'notes' => ['nullable', 'string', 'max:1000'],
11.7 Medication
'medication_name' => ['required', 'string', 'max:255'],
'dose' => ['required', 'string', 'max:100'],
'daily_dose' => ['nullable', 'string', 'max:100'],
'time_of_day' => ['nullable', 'date_format:H:i'],
'start_date' => ['required', 'date'],
'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
'status' => ['required', 'in:active,paused,completed,stopped'],
'notes' => ['nullable', 'string', 'max:1000'],
11.8 Lab Tests
'test_date' => ['required', 'date'],
'test_name' => ['required', 'string', 'max:255'],
'result_value' => ['required', 'string', 'max:100'],
'unit' => ['nullable', 'string', 'max:50'],
'reference_range' => ['nullable', 'string', 'max:100'],
'lab_name' => ['nullable', 'string', 'max:255'],
'notes' => ['nullable', 'string', 'max:1000'],
12. Common Problems and Fixes
Problem 1: Page opens but no data loads

Check browser console.

Check API URL:

cat src/services/api.js

Make sure base URL is:

http://127.0.0.1:8000/api/v1

Check token exists:

localStorage.getItem("token")
Problem 2: 401 Unauthorized

Fix:

curl -s "http://127.0.0.1:8000/api/v1/auth/me" \
-H "Authorization: Bearer $TOKEN" | jq

If invalid, login again.

Problem 3: 404 Not Found

Check route:

php artisan route:list | grep health

Then clear cache:

php artisan optimize:clear
Problem 4: 422 Validation Error

Check response:

curl -i -X POST ...

Laravel will return:

{
  "message": "The given data was invalid.",
  "errors": {
    "field_name": [
      "The field name field is required."
    ]
  }
}

Fix frontend field names to match backend.

Problem 5: Frontend expects response.data.data, but API returns pagination

Paginated Laravel response looks like:

{
  "success": true,
  "data": {
    "current_page": 1,
    "data": []
  }
}

Frontend should support both:

const payload = response.data.data;

logs.value = Array.isArray(payload)
  ? payload
  : payload.data || [];
Problem 6: Health Dashboard still shows static data

Search for hardcoded values:

cd /u01/nix-life-os/frontend

grep -R "7500\|10000\|static\|mock\|sample" -n src/views src/components src/services

Replace static values with API response.

13. Final Stabilization Test Order

Use this order:

1. Confirm backend containers are running.
2. Confirm Laravel routes exist.
3. Confirm database tables exist.
4. Login and get token.
5. Test every Health API with CURL.
6. Validate inserted records in PostgreSQL.
7. Open every Health frontend route.
8. Confirm each page loads without console errors.
9. Add record from UI.
10. Edit record from UI.
11. Delete record from UI.
12. Confirm Health Dashboard reads real data.
13. Confirm empty states work.
14. Confirm validation errors display clearly.
15. Confirm loading state appears during API calls.
16. Confirm sidebar links open correct routes.
17. Confirm data belongs only to authenticated user.
18. Run frontend build.
19. Clear Laravel cache.
20. Final QA pass.
14. Build and Cache Validation
Backend
cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan route:list | grep health
php artisan test
Frontend
cd /u01/nix-life-os/frontend

npm run build

If frontend build fails, check the exact component error and fix missing imports, route names, or invalid template syntax.

15. Final Pass / Fail Checklist
Area	Check	Status
Backend Routes	All Health API routes exist	☐
Auth	All APIs require Bearer token	☐
Steps	Add/Edit/Delete/List works	☐
Weight	Add/Edit/Delete/List works	☐
Nutrition	Add/Edit/Delete/List works	☐
Hydration	Add/Edit/Delete/List works	☐
Sleep	Add/Edit/Delete/List works	☐
Mood	Add/Edit/Delete/List works	☐
Medication	Medication name, times, daily dose work	☐
Lab Tests	All lab test fields work	☐
Dashboard	Reads real database data	☐
Frontend Routes	All Health routes open correctly	☐
Sidebar	All menu links work	☐
Loading State	Appears on API calls	☐
Error State	Displays validation/server errors	☐
Empty State	No records message works	☐
Delete Confirmation	Exists before delete	☐
User Isolation	Users only see their own data	☐
PostgreSQL	Data saved correctly	☐
Build	npm run build passes	☐
Laravel Cache	php artisan optimize:clear done	☐
Recommended Next Step

After STEP 45, continue with:

🔹 STEP 46 — Health Medication + Lab Tests Full Implementation

This should focus only on:

Medication name
Medication dose
Daily dose
Medication time schedule
Lab test name
Lab result
Lab unit
Reference range
Lab history
Health dashboard integration
Kidney health indicators
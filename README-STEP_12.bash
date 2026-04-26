Nix, STEP 12 — Health Analytics Engine (Python) will be added as a FastAPI analytics microservice connected to Laravel.
It will analyze data from:


Step 9: Weight tracking


Step 10: Nutrition tracking


Step 11: Hydration tracking


Step 8: Steps tracking


It will provide:


Calorie burn estimation


Weight prediction


Health score calculation


CKD alerts for sodium and hydration


Laravel API integration


Important: your token is exposed in the chat. For safety, later run:
php artisan sanctum:prune-expired --hours=0
or create a fresh token after testing.

STEP 12 Folder Structure
Inside your project:
/u01/nix-life-os├── backend├── frontend└── analytics
Create the Python analytics service:
cd /u01/nix-life-osmkdir -p analytics/app/servicesmkdir -p analytics/app/schemasmkdir -p analytics/app/utilsmkdir -p analytics/testscd analytics

1. Create Python Virtual Environment
cd /u01/nix-life-os/analyticspython3 -m venv venvsource venv/bin/activate
Create requirements.txt:
nano requirements.txt
Add:
fastapi==0.115.6uvicorn==0.34.0pydantic==2.10.4python-dotenv==1.0.1numpy==2.2.1pandas==2.2.3scikit-learn==1.6.0
Install:
pip install -r requirements.txt

2. Create Environment File
nano .env
Add:
APP_NAME=NIX LIFE OS Health Analytics EngineAPP_ENV=localAPP_PORT=9000DEFAULT_WEIGHT_KG=64DEFAULT_HEIGHT_CM=155DEFAULT_AGE=29DEFAULT_GENDER=maleCKD_SODIUM_MAX_MG=2000CKD_DAILY_FLUID_MIN_ML=1500CKD_DAILY_FLUID_MAX_ML=2500CKD_LOW_HYDRATION_WARNING_ML=1200

3. Create Main FastAPI App
Create:
nano app/main.py
Add:
from fastapi import FastAPIfrom app.schemas.health_analytics_schema import (    HealthAnalyticsRequest,    HealthAnalyticsResponse,)from app.services.health_analytics_service import HealthAnalyticsServiceapp = FastAPI(    title="NIX LIFE OS - Health Analytics Engine",    version="1.0.0",    description="Python analytics service for health, nutrition, hydration, weight, steps, CKD alerts, and health scoring.",)analytics_service = HealthAnalyticsService()@app.get("/")def root():    return {        "success": True,        "message": "NIX LIFE OS Health Analytics Engine is running",    }@app.get("/health")def health_check():    return {        "success": True,        "service": "health-analytics-engine",        "status": "healthy",    }@app.post("/api/v1/analytics/health/daily", response_model=HealthAnalyticsResponse)def calculate_daily_health_analytics(payload: HealthAnalyticsRequest):    return analytics_service.calculate_daily_analytics(payload)

4. Create Schema File
Create:
nano app/schemas/health_analytics_schema.py
Add:
from typing import List, Optionalfrom pydantic import BaseModel, Fieldclass WeightLog(BaseModel):    log_date: str    weight_kg: floatclass NutritionSummary(BaseModel):    log_date: str    calories: float = 0    protein_g: float = 0    carbs_g: float = 0    fat_g: float = 0    sodium_mg: float = 0    potassium_mg: float = 0    phosphorus_mg: float = 0    sugar_g: float = 0    fiber_g: float = 0class HydrationSummary(BaseModel):    log_date: str    total_fluids_ml: float = 0    water_ml: float = 0    other_drinks_ml: float = 0class StepsSummary(BaseModel):    log_date: str    steps: int = 0    distance_km: Optional[float] = 0    active_minutes: Optional[int] = 0class UserHealthProfile(BaseModel):    weight_kg: float = Field(default=64)    height_cm: float = Field(default=155)    age: int = Field(default=29)    gender: str = Field(default="male")    activity_level: str = Field(default="light")    ckd_safe_mode: bool = Field(default=True)    sodium_limit_mg: float = Field(default=2000)    fluid_min_ml: float = Field(default=1500)    fluid_max_ml: float = Field(default=2500)class HealthAnalyticsRequest(BaseModel):    user_id: str    target_date: str    profile: UserHealthProfile    weight_logs: List[WeightLog] = []    nutrition: Optional[NutritionSummary] = None    hydration: Optional[HydrationSummary] = None    steps: Optional[StepsSummary] = Noneclass AlertItem(BaseModel):    type: str    level: str    message: str    value: Optional[float] = None    limit: Optional[float] = Noneclass HealthAnalyticsResponse(BaseModel):    success: bool    message: str    user_id: str    target_date: str    estimated_bmr: float    estimated_tdee: float    estimated_steps_burn: float    estimated_total_burn: float    calorie_balance: float    weight_prediction_7_days_kg: Optional[float]    weight_prediction_30_days_kg: Optional[float]    health_score: int    health_score_label: str    alerts: List[AlertItem]    recommendations: List[str]

5. Create Analytics Service
Create:
nano app/services/health_analytics_service.py
Add:
from statistics import meanfrom app.schemas.health_analytics_schema import (    HealthAnalyticsRequest,    HealthAnalyticsResponse,    AlertItem,)class HealthAnalyticsService:    def calculate_daily_analytics(self, payload: HealthAnalyticsRequest) -> HealthAnalyticsResponse:        profile = payload.profile        nutrition = payload.nutrition        hydration = payload.hydration        steps = payload.steps        current_weight = self._resolve_current_weight(payload)        bmr = self._calculate_bmr(            weight_kg=current_weight,            height_cm=profile.height_cm,            age=profile.age,            gender=profile.gender,        )        tdee = self._calculate_tdee(bmr, profile.activity_level)        steps_count = steps.steps if steps else 0        estimated_steps_burn = self._estimate_steps_calorie_burn(            steps=steps_count,            weight_kg=current_weight,        )        estimated_total_burn = tdee + estimated_steps_burn        calories_in = nutrition.calories if nutrition else 0        calorie_balance = calories_in - estimated_total_burn        weight_prediction_7 = self._predict_weight_change(            current_weight=current_weight,            daily_calorie_balance=calorie_balance,            days=7,        )        weight_prediction_30 = self._predict_weight_change(            current_weight=current_weight,            daily_calorie_balance=calorie_balance,            days=30,        )        alerts = self._generate_ckd_alerts(payload)        health_score = self._calculate_health_score(payload, calorie_balance, alerts)        health_score_label = self._score_label(health_score)        recommendations = self._generate_recommendations(payload, calorie_balance, alerts)        return HealthAnalyticsResponse(            success=True,            message="Daily health analytics calculated successfully",            user_id=payload.user_id,            target_date=payload.target_date,            estimated_bmr=round(bmr, 2),            estimated_tdee=round(tdee, 2),            estimated_steps_burn=round(estimated_steps_burn, 2),            estimated_total_burn=round(estimated_total_burn, 2),            calorie_balance=round(calorie_balance, 2),            weight_prediction_7_days_kg=round(weight_prediction_7, 2),            weight_prediction_30_days_kg=round(weight_prediction_30, 2),            health_score=health_score,            health_score_label=health_score_label,            alerts=alerts,            recommendations=recommendations,        )    def _resolve_current_weight(self, payload: HealthAnalyticsRequest) -> float:        if payload.weight_logs:            sorted_logs = sorted(payload.weight_logs, key=lambda x: x.log_date)            return sorted_logs[-1].weight_kg        return payload.profile.weight_kg    def _calculate_bmr(self, weight_kg: float, height_cm: float, age: int, gender: str) -> float:        """        Mifflin-St Jeor equation.        Male:   10W + 6.25H - 5A + 5        Female: 10W + 6.25H - 5A - 161        """        gender_normalized = gender.lower().strip()        if gender_normalized == "female":            return (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161        return (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5    def _calculate_tdee(self, bmr: float, activity_level: str) -> float:        factors = {            "sedentary": 1.2,            "light": 1.375,            "moderate": 1.55,            "active": 1.725,            "very_active": 1.9,        }        factor = factors.get(activity_level.lower().strip(), 1.375)        return bmr * factor    def _estimate_steps_calorie_burn(self, steps: int, weight_kg: float) -> float:        """        Simple estimation:        Average burn ≈ 0.04 kcal per step for average adult.        Adjust slightly by weight.        """        base_kcal_per_step = 0.04        weight_factor = weight_kg / 70        return steps * base_kcal_per_step * weight_factor    def _predict_weight_change(self, current_weight: float, daily_calorie_balance: float, days: int) -> float:        """        Approximation:        7700 kcal ≈ 1 kg body weight.        Negative balance predicts loss.        Positive balance predicts gain.        """        expected_change_kg = (daily_calorie_balance * days) / 7700        return current_weight + expected_change_kg    def _generate_ckd_alerts(self, payload: HealthAnalyticsRequest) -> list[AlertItem]:        alerts = []        profile = payload.profile        nutrition = payload.nutrition        hydration = payload.hydration        if not profile.ckd_safe_mode:            return alerts        if nutrition:            if nutrition.sodium_mg > profile.sodium_limit_mg:                alerts.append(                    AlertItem(                        type="CKD_SODIUM_LIMIT",                        level="high",                        message="Sodium intake is above your configured CKD-safe daily limit.",                        value=nutrition.sodium_mg,                        limit=profile.sodium_limit_mg,                    )                )            if nutrition.sodium_mg >= profile.sodium_limit_mg * 0.85 and nutrition.sodium_mg <= profile.sodium_limit_mg:                alerts.append(                    AlertItem(                        type="CKD_SODIUM_WARNING",                        level="medium",                        message="Sodium intake is close to your configured CKD-safe daily limit.",                        value=nutrition.sodium_mg,                        limit=profile.sodium_limit_mg,                    )                )        if hydration:            if hydration.total_fluids_ml < profile.fluid_min_ml:                alerts.append(                    AlertItem(                        type="CKD_LOW_HYDRATION",                        level="medium",                        message="Fluid intake is below your configured daily minimum.",                        value=hydration.total_fluids_ml,                        limit=profile.fluid_min_ml,                    )                )            if hydration.total_fluids_ml > profile.fluid_max_ml:                alerts.append(                    AlertItem(                        type="CKD_HIGH_HYDRATION",                        level="high",                        message="Fluid intake is above your configured daily maximum. Review this with your doctor if you have fluid restriction.",                        value=hydration.total_fluids_ml,                        limit=profile.fluid_max_ml,                    )                )        return alerts    def _calculate_health_score(        self,        payload: HealthAnalyticsRequest,        calorie_balance: float,        alerts: list[AlertItem],    ) -> int:        score = 100        nutrition = payload.nutrition        hydration = payload.hydration        steps = payload.steps        for alert in alerts:            if alert.level == "high":                score -= 20            elif alert.level == "medium":                score -= 10            else:                score -= 5        if nutrition:            if nutrition.calories <= 0:                score -= 10            if nutrition.protein_g > 60:                score -= 5        else:            score -= 15        if hydration:            if hydration.total_fluids_ml <= 0:                score -= 10        else:            score -= 10        if steps:            if steps.steps < 3000:                score -= 10            elif steps.steps >= 6000:                score += 5        else:            score -= 5        if calorie_balance > 800:            score -= 10        elif calorie_balance < -1000:            score -= 10        return max(0, min(100, score))    def _score_label(self, score: int) -> str:        if score >= 85:            return "Excellent"        if score >= 70:            return "Good"        if score >= 50:            return "Needs Attention"        return "High Risk"    def _generate_recommendations(        self,        payload: HealthAnalyticsRequest,        calorie_balance: float,        alerts: list[AlertItem],    ) -> list[str]:        recommendations = []        alert_types = {alert.type for alert in alerts}        if "CKD_SODIUM_LIMIT" in alert_types:            recommendations.append("Reduce high-sodium foods today and review packaged/restaurant food intake.")        if "CKD_SODIUM_WARNING" in alert_types:            recommendations.append("You are close to the sodium limit. Keep the next meals low in salt.")        if "CKD_LOW_HYDRATION" in alert_types:            recommendations.append("Hydration is below your configured target. Add fluids only if allowed by your doctor.")        if "CKD_HIGH_HYDRATION" in alert_types:            recommendations.append("Hydration is above your configured limit. This may be important if you have fluid restriction.")        if payload.steps and payload.steps.steps < 3000:            recommendations.append("Light walking can improve daily activity score if medically safe.")        if calorie_balance > 500:            recommendations.append("Calories are above estimated burn. Consider a lighter next meal.")        if calorie_balance < -900:            recommendations.append("Calories are much lower than estimated burn. Avoid aggressive restriction unless supervised.")        if not recommendations:            recommendations.append("Your daily health indicators look balanced based on the available data.")        return recommendations

6. Create __init__.py Files
touch app/__init__.pytouch app/services/__init__.pytouch app/schemas/__init__.pytouch app/utils/__init__.py

7. Run Python Analytics Service
From:
cd /u01/nix-life-os/analyticssource venv/bin/activate
Run:
uvicorn app.main:app --host 127.0.0.1 --port 9000 --reload
Test:
curl http://127.0.0.1:9000/health
Expected:
{  "success": true,  "service": "health-analytics-engine",  "status": "healthy"}

8. Test Python Analytics Directly
curl -X POST http://127.0.0.1:9000/api/v1/analytics/health/daily \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -d '{    "user_id": "test-user",    "target_date": "2026-04-26",    "profile": {      "weight_kg": 64,      "height_cm": 155,      "age": 29,      "gender": "male",      "activity_level": "light",      "ckd_safe_mode": true,      "sodium_limit_mg": 2000,      "fluid_min_ml": 1500,      "fluid_max_ml": 2500    },    "weight_logs": [      {        "log_date": "2026-04-25",        "weight_kg": 64.5      },      {        "log_date": "2026-04-26",        "weight_kg": 64      }    ],    "nutrition": {      "log_date": "2026-04-26",      "calories": 1750,      "protein_g": 42,      "carbs_g": 210,      "fat_g": 55,      "sodium_mg": 2300,      "potassium_mg": 1800,      "phosphorus_mg": 700,      "sugar_g": 35,      "fiber_g": 20    },    "hydration": {      "log_date": "2026-04-26",      "total_fluids_ml": 1100,      "water_ml": 900,      "other_drinks_ml": 200    },    "steps": {      "log_date": "2026-04-26",      "steps": 4500,      "distance_km": 3.1,      "active_minutes": 35    }  }'
You should see:
{  "success": true,  "message": "Daily health analytics calculated successfully",  "estimated_bmr": "...",  "estimated_tdee": "...",  "estimated_steps_burn": "...",  "calorie_balance": "...",  "health_score": "...",  "alerts": [...]}

9. Laravel Integration
Now connect Laravel to the Python service.
Go to backend:
cd /u01/nix-life-os/backend

9.1 Add Python Analytics URL to Laravel .env
nano .env
Add:
HEALTH_ANALYTICS_URL=http://127.0.0.1:9000

9.2 Update config/services.php
Open:
nano config/services.php
Add this inside the returned array:
'health_analytics' => [    'url' => env('HEALTH_ANALYTICS_URL', 'http://127.0.0.1:9000'),],
Example:
return [    // existing services...    'health_analytics' => [        'url' => env('HEALTH_ANALYTICS_URL', 'http://127.0.0.1:9000'),    ],];
Then run:
php artisan optimize:clear

10. Create Laravel Controller
Create:
php artisan make:controller Api/V1/Health/HealthAnalyticsController
Open:
nano app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php
Replace with:
<?phpnamespace App\Http\Controllers\Api\V1\Health;use App\Http\Controllers\Controller;use Illuminate\Http\Request;use Illuminate\Support\Facades\Http;use Illuminate\Support\Facades\DB;use Illuminate\Support\Facades\Log;class HealthAnalyticsController extends Controller{    public function daily(Request $request)    {        $user = $request->user();        $validated = $request->validate([            'target_date' => ['required', 'date'],        ]);        $targetDate = $validated['target_date'];        $payload = [            'user_id' => (string) $user->id,            'target_date' => $targetDate,            'profile' => $this->buildProfile($user),            'weight_logs' => $this->getRecentWeightLogs($user->id, $targetDate),            'nutrition' => $this->getNutritionSummary($user->id, $targetDate),            'hydration' => $this->getHydrationSummary($user->id, $targetDate),            'steps' => $this->getStepsSummary($user->id, $targetDate),        ];        try {            $baseUrl = rtrim(config('services.health_analytics.url'), '/');            $response = Http::timeout(15)                ->acceptJson()                ->post($baseUrl . '/api/v1/analytics/health/daily', $payload);            if (!$response->successful()) {                Log::error('Health analytics service failed', [                    'status' => $response->status(),                    'body' => $response->body(),                ]);                return response()->json([                    'success' => false,                    'message' => 'Health analytics service returned an error.',                    'details' => $response->json(),                ], 502);            }            return response()->json([                'success' => true,                'message' => 'Health analytics generated successfully.',                'data' => $response->json(),            ]);        } catch (\Throwable $e) {            Log::error('Health analytics service unavailable', [                'error' => $e->getMessage(),            ]);            return response()->json([                'success' => false,                'message' => 'Health analytics service is unavailable.',                'error' => $e->getMessage(),            ], 503);        }    }    private function buildProfile($user): array    {        /*         | You can later replace this with a real health_profiles table.         | For now, these values match your known Step 10 CKD profile.         */        return [            'weight_kg' => 64,            'height_cm' => 155,            'age' => 29,            'gender' => 'male',            'activity_level' => 'light',            'ckd_safe_mode' => true,            'sodium_limit_mg' => 2000,            'fluid_min_ml' => 1500,            'fluid_max_ml' => 2500,        ];    }    private function getRecentWeightLogs(string $userId, string $targetDate): array    {        if (!DB::getSchemaBuilder()->hasTable('health_weight_logs')) {            return [];        }        return DB::table('health_weight_logs')            ->where('user_id', $userId)            ->whereDate('log_date', '<=', $targetDate)            ->orderByDesc('log_date')            ->limit(14)            ->get()            ->reverse()            ->values()            ->map(function ($row) {                return [                    'log_date' => (string) $row->log_date,                    'weight_kg' => (float) $row->weight_kg,                ];            })            ->toArray();    }    private function getNutritionSummary(string $userId, string $targetDate): ?array    {        if (!DB::getSchemaBuilder()->hasTable('health_nutrition_logs')) {            return null;        }        $row = DB::table('health_nutrition_logs')            ->where('user_id', $userId)            ->whereDate('log_date', $targetDate)            ->selectRaw('                ? as log_date,                COALESCE(SUM(calories), 0) as calories,                COALESCE(SUM(protein_g), 0) as protein_g,                COALESCE(SUM(carbs_g), 0) as carbs_g,                COALESCE(SUM(fat_g), 0) as fat_g,                COALESCE(SUM(sodium_mg), 0) as sodium_mg,                COALESCE(SUM(potassium_mg), 0) as potassium_mg,                COALESCE(SUM(phosphorus_mg), 0) as phosphorus_mg,                COALESCE(SUM(sugar_g), 0) as sugar_g,                COALESCE(SUM(fiber_g), 0) as fiber_g            ', [$targetDate])            ->first();        if (!$row) {            return null;        }        return [            'log_date' => $targetDate,            'calories' => (float) $row->calories,            'protein_g' => (float) $row->protein_g,            'carbs_g' => (float) $row->carbs_g,            'fat_g' => (float) $row->fat_g,            'sodium_mg' => (float) $row->sodium_mg,            'potassium_mg' => (float) $row->potassium_mg,            'phosphorus_mg' => (float) $row->phosphorus_mg,            'sugar_g' => (float) $row->sugar_g,            'fiber_g' => (float) $row->fiber_g,        ];    }    private function getHydrationSummary(string $userId, string $targetDate): ?array    {        if (!DB::getSchemaBuilder()->hasTable('health_hydration_logs')) {            return null;        }        $row = DB::table('health_hydration_logs')            ->where('user_id', $userId)            ->whereDate('log_date', $targetDate)            ->selectRaw('                ? as log_date,                COALESCE(SUM(amount_ml), 0) as total_fluids_ml,                COALESCE(SUM(CASE WHEN LOWER(drink_type) = \'water\' THEN amount_ml ELSE 0 END), 0) as water_ml,                COALESCE(SUM(CASE WHEN LOWER(drink_type) <> \'water\' THEN amount_ml ELSE 0 END), 0) as other_drinks_ml            ', [$targetDate])            ->first();        if (!$row) {            return null;        }        return [            'log_date' => $targetDate,            'total_fluids_ml' => (float) $row->total_fluids_ml,            'water_ml' => (float) $row->water_ml,            'other_drinks_ml' => (float) $row->other_drinks_ml,        ];    }    private function getStepsSummary(string $userId, string $targetDate): ?array    {        if (!DB::getSchemaBuilder()->hasTable('health_step_logs')) {            return null;        }        $row = DB::table('health_step_logs')            ->where('user_id', $userId)            ->whereDate('log_date', $targetDate)            ->selectRaw('                ? as log_date,                COALESCE(SUM(steps), 0) as steps,                COALESCE(SUM(distance_km), 0) as distance_km,                COALESCE(SUM(active_minutes), 0) as active_minutes            ', [$targetDate])            ->first();        if (!$row) {            return null;        }        return [            'log_date' => $targetDate,            'steps' => (int) $row->steps,            'distance_km' => (float) $row->distance_km,            'active_minutes' => (int) $row->active_minutes,        ];    }}

11. Important Table Name Check
Your previous modules may use slightly different table names.
Check your real tables:
php artisan tinker
Then:
Schema::hasTable('health_weight_logs');Schema::hasTable('health_nutrition_logs');Schema::hasTable('health_hydration_logs');Schema::hasTable('health_step_logs');
If one returns false, list health tables:
DB::select("select table_name from information_schema.tables where table_schema = 'public' and table_name like 'health_%'");
If your hydration table has another name, update this part:
health_hydration_logs
If your steps table has another name, update:
health_step_logs

12. Add API Route
Open:
nano routes/api.php
Inside your protected Sanctum route group, add:
use App\Http\Controllers\Api\V1\Health\HealthAnalyticsController;
Then add the route:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {    Route::post('/health/analytics/daily', [HealthAnalyticsController::class, 'daily']);});
If you already have this group:
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {    // existing routes here});
Then only add this inside it:
Route::post('/health/analytics/daily', [HealthAnalyticsController::class, 'daily']);

13. Clear Laravel Cache
cd /u01/nix-life-os/backendphp artisan optimize:clearcomposer dump-autoload
Check route:
php artisan route:list | grep health/analytics
Expected:
POST api/v1/health/analytics/daily

14. Test Laravel → Python Integration
Make sure Python service is running:
cd /u01/nix-life-os/analyticssource venv/bin/activateuvicorn app.main:app --host 127.0.0.1 --port 9000 --reload
In another terminal:
cd /u01/nix-life-os/backend
Run:
curl -X POST http://127.0.0.1:8000/api/v1/health/analytics/daily \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \  -d '{    "target_date": "2026-04-26"  }'
Expected response:
{  "success": true,  "message": "Health analytics generated successfully.",  "data": {    "success": true,    "message": "Daily health analytics calculated successfully",    "health_score": 70,    "health_score_label": "Good",    "alerts": [],    "recommendations": []  }}

15. Add Optional Database Table to Store Analytics Results
This is optional but recommended.
Create migration:
php artisan make:migration create_health_analytics_daily_results_table
Open the migration file:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_analytics_daily_results_table.php
Use:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('health_analytics_daily_results', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('user_id');            $table->date('result_date');            $table->decimal('estimated_bmr', 10, 2)->default(0);            $table->decimal('estimated_tdee', 10, 2)->default(0);            $table->decimal('estimated_steps_burn', 10, 2)->default(0);            $table->decimal('estimated_total_burn', 10, 2)->default(0);            $table->decimal('calorie_balance', 10, 2)->default(0);            $table->decimal('weight_prediction_7_days_kg', 8, 2)->nullable();            $table->decimal('weight_prediction_30_days_kg', 8, 2)->nullable();            $table->unsignedSmallInteger('health_score')->default(0);            $table->string('health_score_label', 50)->nullable();            $table->jsonb('alerts')->nullable();            $table->jsonb('recommendations')->nullable();            $table->jsonb('raw_result')->nullable();            $table->timestamps();            $table->unique(['user_id', 'result_date']);            $table->index(['user_id', 'result_date']);        });    }    public function down(): void    {        Schema::dropIfExists('health_analytics_daily_results');    }};
Run:
php artisan migrate

16. Update Controller to Save Analytics Result
Inside HealthAnalyticsController.php, after:
$data = $response->json();
You can save it.
Replace this part:
return response()->json([    'success' => true,    'message' => 'Health analytics generated successfully.',    'data' => $response->json(),]);
With:
$data = $response->json();$this->storeAnalyticsResult($user->id, $targetDate, $data);return response()->json([    'success' => true,    'message' => 'Health analytics generated successfully.',    'data' => $data,]);
Then add this method inside the controller:
private function storeAnalyticsResult(string $userId, string $targetDate, array $data): void{    if (!DB::getSchemaBuilder()->hasTable('health_analytics_daily_results')) {        return;    }    DB::table('health_analytics_daily_results')->updateOrInsert(        [            'user_id' => $userId,            'result_date' => $targetDate,        ],        [            'id' => (string) \Illuminate\Support\Str::uuid(),            'estimated_bmr' => $data['estimated_bmr'] ?? 0,            'estimated_tdee' => $data['estimated_tdee'] ?? 0,            'estimated_steps_burn' => $data['estimated_steps_burn'] ?? 0,            'estimated_total_burn' => $data['estimated_total_burn'] ?? 0,            'calorie_balance' => $data['calorie_balance'] ?? 0,            'weight_prediction_7_days_kg' => $data['weight_prediction_7_days_kg'] ?? null,            'weight_prediction_30_days_kg' => $data['weight_prediction_30_days_kg'] ?? null,            'health_score' => $data['health_score'] ?? 0,            'health_score_label' => $data['health_score_label'] ?? null,            'alerts' => json_encode($data['alerts'] ?? []),            'recommendations' => json_encode($data['recommendations'] ?? []),            'raw_result' => json_encode($data),            'updated_at' => now(),            'created_at' => now(),        ]    );}
Also add this import at the top:
use Illuminate\Support\Str;
Then replace:
'id' => (string) \Illuminate\Support\Str::uuid(),
With:
'id' => (string) Str::uuid(),

17. Final API Endpoint
Your final endpoint is:
POST /api/v1/health/analytics/daily
Body:
{  "target_date": "2026-04-26"}
This endpoint will:


Authenticate the user using Sanctum.


Collect health data from PostgreSQL.


Send the data to Python FastAPI.


Calculate health analytics.


Return the analytics result.


Optionally store the result in PostgreSQL.



18. STEP 12 Completion Checklist
STEP 12 is complete when all of these work:
curl http://127.0.0.1:9000/health
Returns healthy.
php artisan route:list | grep health/analytics
Shows:
POST api/v1/health/analytics/daily
This works:
curl -X POST http://127.0.0.1:8000/api/v1/health/analytics/daily \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \  -d '{    "target_date": "2026-04-26"  }'
And returns:
{  "success": true,  "message": "Health analytics generated successfully."}

19. Notes About CKD Alerts
The CKD alerts in this module are application safety alerts, not medical diagnosis.
Current alert rules:
Sodium > 2000 mg        => high alertSodium >= 85% of limit  => medium warningFluids < 1500 ml        => low hydration warningFluids > 2500 ml        => high hydration warning
You can later make these limits dynamic from your health_nutrition_profile table instead of hardcoding them in the Laravel controller.
🔹 STEP 20 — Life Balance Index
Build a Life Balance System that combines:


Finance


Health


Productivity / Projects


Overall score


Radar chart frontend



1. Backend Goal
The backend will calculate a daily Life Balance Index like this:
Life Balance Index = average(  Finance Score,  Health Score,  Productivity Score)
Example:
{  "target_date": "2026-04-27",  "overall_score": 76,  "finance_score": 82,  "health_score": 70,  "productivity_score": 76,  "status": "balanced"}

2. Create Migration
Run:
cd /u01/nix-life-os/backendphp artisan make:migration create_life_balance_scores_table
Open the generated migration file:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_life_balance_scores_table.php
Paste:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('life_balance_scores', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('user_id');            $table->date('target_date');            $table->unsignedTinyInteger('finance_score')->default(0);            $table->unsignedTinyInteger('health_score')->default(0);            $table->unsignedTinyInteger('productivity_score')->default(0);            $table->unsignedTinyInteger('overall_score')->default(0);            $table->string('status')->default('unknown');            $table->jsonb('finance_breakdown')->nullable();            $table->jsonb('health_breakdown')->nullable();            $table->jsonb('productivity_breakdown')->nullable();            $table->jsonb('recommendations')->nullable();            $table->timestamps();            $table->unique(['user_id', 'target_date']);            $table->index(['user_id', 'target_date']);            $table->index(['user_id', 'overall_score']);            $table->index(['status']);        });    }    public function down(): void    {        Schema::dropIfExists('life_balance_scores');    }};
Run:
php artisan migrate

3. Create Model
Run:
php artisan make:model LifeBalanceScore
Open:
nano app/Models/LifeBalanceScore.php
Paste:
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\Concerns\HasUuids;class LifeBalanceScore extends Model{    use HasUuids;    protected $fillable = [        'user_id',        'target_date',        'finance_score',        'health_score',        'productivity_score',        'overall_score',        'status',        'finance_breakdown',        'health_breakdown',        'productivity_breakdown',        'recommendations',    ];    protected $casts = [        'target_date' => 'date',        'finance_breakdown' => 'array',        'health_breakdown' => 'array',        'productivity_breakdown' => 'array',        'recommendations' => 'array',    ];}

4. Create Service
Create folder if missing:
mkdir -p app/Services/LifeBalance
Create service file:
nano app/Services/LifeBalance/LifeBalanceService.php
Paste:
<?phpnamespace App\Services\LifeBalance;use App\Models\LifeBalanceScore;use Carbon\Carbon;use Illuminate\Support\Facades\DB;use Illuminate\Support\Facades\Schema;class LifeBalanceService{    public function calculate(string $userId, ?string $date = null): LifeBalanceScore    {        $targetDate = $date            ? Carbon::parse($date)->toDateString()            : now()->toDateString();        $finance = $this->calculateFinanceScore($userId, $targetDate);        $health = $this->calculateHealthScore($userId, $targetDate);        $productivity = $this->calculateProductivityScore($userId, $targetDate);        $overallScore = (int) round(            (                $finance['score'] +                $health['score'] +                $productivity['score']            ) / 3        );        $status = $this->resolveStatus($overallScore);        $recommendations = $this->buildRecommendations(            $finance,            $health,            $productivity,            $overallScore        );        return LifeBalanceScore::updateOrCreate(            [                'user_id' => $userId,                'target_date' => $targetDate,            ],            [                'finance_score' => $finance['score'],                'health_score' => $health['score'],                'productivity_score' => $productivity['score'],                'overall_score' => $overallScore,                'status' => $status,                'finance_breakdown' => $finance,                'health_breakdown' => $health,                'productivity_breakdown' => $productivity,                'recommendations' => $recommendations,            ]        );    }    private function calculateFinanceScore(string $userId, string $date): array    {        $income = 0;        $expenses = 0;        if (Schema::hasTable('finance_transactions')) {            $income = (float) DB::table('finance_transactions')                ->where('user_id', $userId)                ->whereDate('transaction_date', $date)                ->where('transaction_type', 'income')                ->sum('amount');            $expenses = (float) DB::table('finance_transactions')                ->where('user_id', $userId)                ->whereDate('transaction_date', $date)                ->where('transaction_type', 'expense')                ->sum('amount');        }        $netCashflow = $income - $expenses;        $score = 50;        if ($income > 0) {            $expenseRatio = $expenses / max($income, 1);            if ($expenseRatio <= 0.5) {                $score = 95;            } elseif ($expenseRatio <= 0.7) {                $score = 85;            } elseif ($expenseRatio <= 0.9) {                $score = 70;            } elseif ($expenseRatio <= 1) {                $score = 55;            } else {                $score = 35;            }        } elseif ($expenses > 0) {            $score = 40;        }        return [            'score' => $this->clamp($score),            'income' => round($income, 2),            'expenses' => round($expenses, 2),            'net_cashflow' => round($netCashflow, 2),            'logic' => 'Finance score is based on income, expenses, and daily cashflow.',        ];    }    private function calculateHealthScore(string $userId, string $date): array    {        $steps = 0;        $waterMl = 0;        $calories = 0;        if (Schema::hasTable('health_step_logs')) {            $steps = (int) DB::table('health_step_logs')                ->where('user_id', $userId)                ->whereDate('log_date', $date)                ->sum('steps_count');        }        if (Schema::hasTable('health_hydration_logs')) {            $waterMl = (int) DB::table('health_hydration_logs')                ->where('user_id', $userId)                ->whereDate('log_date', $date)                ->sum('amount_ml');        }        if (Schema::hasTable('health_meal_logs')) {            $calories = (float) DB::table('health_meal_logs')                ->where('user_id', $userId)                ->whereDate('meal_date', $date)                ->sum('total_calories');        }        $stepsScore = min(100, ($steps / 7000) * 100);        $hydrationScore = min(100, ($waterMl / 2000) * 100);        $calorieScore = 50;        if ($calories >= 1400 && $calories <= 1900) {            $calorieScore = 100;        } elseif ($calories >= 1000 && $calories < 1400) {            $calorieScore = 75;        } elseif ($calories > 1900 && $calories <= 2300) {            $calorieScore = 70;        } elseif ($calories > 0) {            $calorieScore = 45;        }        $score = (int) round(            ($stepsScore * 0.35) +            ($hydrationScore * 0.35) +            ($calorieScore * 0.30)        );        return [            'score' => $this->clamp($score),            'steps' => $steps,            'water_ml' => $waterMl,            'calories' => round($calories, 2),            'steps_score' => round($stepsScore, 2),            'hydration_score' => round($hydrationScore, 2),            'calorie_score' => round($calorieScore, 2),            'logic' => 'Health score is based on steps, hydration, and nutrition consistency.',        ];    }    private function calculateProductivityScore(string $userId, string $date): array    {        $totalTasks = 0;        $completedTasks = 0;        $activeProjects = 0;        if (Schema::hasTable('project_tasks')) {            $totalTasks = (int) DB::table('project_tasks')                ->where('user_id', $userId)                ->whereDate('created_at', '<=', $date)                ->count();            $completedTasks = (int) DB::table('project_tasks')                ->where('user_id', $userId)                ->whereDate('created_at', '<=', $date)                ->whereIn('status', ['done', 'completed'])                ->count();        }        if (Schema::hasTable('projects')) {            $activeProjects = (int) DB::table('projects')                ->where('user_id', $userId)                ->whereIn('status', ['active', 'in_progress'])                ->count();        }        if ($totalTasks === 0) {            $taskCompletionScore = 50;        } else {            $taskCompletionScore = ($completedTasks / max($totalTasks, 1)) * 100;        }        $projectFocusScore = match (true) {            $activeProjects === 0 => 45,            $activeProjects <= 3 => 100,            $activeProjects <= 5 => 75,            default => 55,        };        $score = (int) round(            ($taskCompletionScore * 0.75) +            ($projectFocusScore * 0.25)        );        return [            'score' => $this->clamp($score),            'total_tasks' => $totalTasks,            'completed_tasks' => $completedTasks,            'active_projects' => $activeProjects,            'task_completion_score' => round($taskCompletionScore, 2),            'project_focus_score' => round($projectFocusScore, 2),            'logic' => 'Productivity score is based on task completion and active project focus.',        ];    }    private function buildRecommendations(        array $finance,        array $health,        array $productivity,        int $overallScore    ): array {        $items = [];        if ($finance['score'] < 70) {            $items[] = [                'module' => 'Finance',                'message' => 'Reduce daily expenses or review high-spending categories.',                'priority' => 'high',            ];        }        if ($health['score'] < 70) {            $items[] = [                'module' => 'Health',                'message' => 'Improve hydration, steps, or nutrition consistency today.',                'priority' => 'high',            ];        }        if ($productivity['score'] < 70) {            $items[] = [                'module' => 'Productivity',                'message' => 'Complete at least one important task or reduce active task overload.',                'priority' => 'medium',            ];        }        if ($overallScore >= 85) {            $items[] = [                'module' => 'Life Balance',                'message' => 'Excellent balance. Maintain the same daily rhythm.',                'priority' => 'low',            ];        }        return $items;    }    private function resolveStatus(int $score): string    {        return match (true) {            $score >= 85 => 'excellent',            $score >= 70 => 'balanced',            $score >= 55 => 'needs_attention',            default => 'critical',        };    }    private function clamp(float|int $value): int    {        return max(0, min(100, (int) round($value)));    }}

5. Create Controller
Run:
php artisan make:controller Api/V1/LifeBalanceController
Open:
nano app/Http/Controllers/Api/V1/LifeBalanceController.php
Paste:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Services\LifeBalance\LifeBalanceService;use Illuminate\Http\Request;class LifeBalanceController extends Controller{    public function today(Request $request, LifeBalanceService $service)    {        $score = $service->calculate(            userId: $request->user()->id,            date: now()->toDateString()        );        return response()->json([            'success' => true,            'data' => $score,        ]);    }    public function calculate(Request $request, LifeBalanceService $service)    {        $validated = $request->validate([            'target_date' => ['nullable', 'date'],        ]);        $score = $service->calculate(            userId: $request->user()->id,            date: $validated['target_date'] ?? now()->toDateString()        );        return response()->json([            'success' => true,            'data' => $score,        ]);    }    public function history(Request $request)    {        $days = (int) $request->query('days', 30);        $scores = $request->user()            ->lifeBalanceScores()            ->orderByDesc('target_date')            ->limit($days)            ->get();        return response()->json([            'success' => true,            'data' => $scores,        ]);    }}

6. Update User Model
Open:
nano app/Models/User.php
Add this method inside the User class:
public function lifeBalanceScores(){    return $this->hasMany(\App\Models\LifeBalanceScore::class, 'user_id');}

7. Update api.php
Open:
nano routes/api.php
Add the controller import at the top:
use App\Http\Controllers\Api\V1\LifeBalanceController;
Inside your authenticated /api/v1 group, add:
Route::prefix('life-balance')->group(function () {    Route::get('/today', [LifeBalanceController::class, 'today']);    Route::post('/calculate', [LifeBalanceController::class, 'calculate']);    Route::get('/history', [LifeBalanceController::class, 'history']);});
Example full section:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {    Route::prefix('life-balance')->group(function () {        Route::get('/today', [LifeBalanceController::class, 'today']);        Route::post('/calculate', [LifeBalanceController::class, 'calculate']);        Route::get('/history', [LifeBalanceController::class, 'history']);    });});
Then clear cache:
php artisan optimize:clearcomposer dump-autoload

8. Test Backend API
Use your token:
TOKEN="YOUR_TOKEN_HERE"
Test today:
curl http://127.0.0.1:8000/api/v1/life-balance/today \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Calculate specific date:
curl -X POST http://127.0.0.1:8000/api/v1/life-balance/calculate \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "target_date": "2026-04-27"  }'
History:
curl "http://127.0.0.1:8000/api/v1/life-balance/history?days=30" \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

9. Frontend Install Chart Library
In frontend:
cd /u01/nix-life-os/frontendnpm install chart.js vue-chartjs

10. Create Life Balance View
Create:
mkdir -p src/views/life-balancenano src/views/life-balance/LifeBalanceView.vue
Paste:
<script setup>import { onMounted, ref, computed } from "vue";import { Radar } from "vue-chartjs";import {  Chart as ChartJS,  RadialLinearScale,  PointElement,  LineElement,  Filler,  Tooltip,  Legend,} from "chart.js";ChartJS.register(  RadialLinearScale,  PointElement,  LineElement,  Filler,  Tooltip,  Legend);const loading = ref(false);const error = ref("");const score = ref(null);const token = localStorage.getItem("token");const fetchLifeBalance = async () => {  loading.value = true;  error.value = "";  try {    const response = await fetch(      "http://127.0.0.1:8000/api/v1/life-balance/today",      {        headers: {          Accept: "application/json",          Authorization: `Bearer ${token}`,        },      }    );    const result = await response.json();    if (!response.ok) {      throw new Error(result.message || "Failed to load Life Balance score");    }    score.value = result.data;  } catch (err) {    error.value = err.message;  } finally {    loading.value = false;  }};const radarData = computed(() => {  if (!score.value) {    return {      labels: ["Finance", "Health", "Productivity"],      datasets: [],    };  }  return {    labels: ["Finance", "Health", "Productivity"],    datasets: [      {        label: "Life Balance Score",        data: [          score.value.finance_score,          score.value.health_score,          score.value.productivity_score,        ],        fill: true,      },    ],  };});const radarOptions = {  responsive: true,  maintainAspectRatio: false,  scales: {    r: {      suggestedMin: 0,      suggestedMax: 100,      ticks: {        stepSize: 20,      },    },  },};const statusClass = computed(() => {  if (!score.value) return "bg-gray-100 text-gray-700";  switch (score.value.status) {    case "excellent":      return "bg-green-100 text-green-700";    case "balanced":      return "bg-blue-100 text-blue-700";    case "needs_attention":      return "bg-yellow-100 text-yellow-700";    case "critical":      return "bg-red-100 text-red-700";    default:      return "bg-gray-100 text-gray-700";  }});const statusLabel = computed(() => {  if (!score.value) return "Unknown";  return score.value.status    .replace("_", " ")    .replace(/\b\w/g, (char) => char.toUpperCase());});onMounted(fetchLifeBalance);</script><template>  <div class="min-h-screen bg-gray-50 p-8">    <div class="max-w-7xl mx-auto space-y-8">      <div class="flex items-center justify-between">        <div>          <h1 class="text-3xl font-bold text-gray-900">            Life Balance Index          </h1>          <p class="text-gray-500 mt-1">            Combined score from Finance, Health, and Productivity.          </p>        </div>        <button          @click="fetchLifeBalance"          class="px-5 py-2 rounded-xl bg-gray-900 text-white hover:bg-gray-800"        >          Refresh        </button>      </div>      <div        v-if="loading"        class="bg-white rounded-2xl shadow-sm border p-8 text-gray-500"      >        Loading Life Balance score...      </div>      <div        v-if="error"        class="bg-red-50 border border-red-200 text-red-700 rounded-2xl p-5"      >        {{ error }}      </div>      <template v-if="score && !loading">        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">          <div class="bg-white rounded-2xl shadow-sm border p-6">            <p class="text-sm text-gray-500">Overall Score</p>            <h2 class="text-4xl font-bold text-gray-900 mt-2">              {{ score.overall_score }}            </h2>            <span              class="inline-flex mt-4 px-3 py-1 rounded-full text-sm font-medium"              :class="statusClass"            >              {{ statusLabel }}            </span>          </div>          <div class="bg-white rounded-2xl shadow-sm border p-6">            <p class="text-sm text-gray-500">Finance</p>            <h2 class="text-4xl font-bold text-gray-900 mt-2">              {{ score.finance_score }}            </h2>            <p class="text-sm text-gray-500 mt-3">              Income, expenses, and cashflow.            </p>          </div>          <div class="bg-white rounded-2xl shadow-sm border p-6">            <p class="text-sm text-gray-500">Health</p>            <h2 class="text-4xl font-bold text-gray-900 mt-2">              {{ score.health_score }}            </h2>            <p class="text-sm text-gray-500 mt-3">              Steps, hydration, and nutrition.            </p>          </div>          <div class="bg-white rounded-2xl shadow-sm border p-6">            <p class="text-sm text-gray-500">Productivity</p>            <h2 class="text-4xl font-bold text-gray-900 mt-2">              {{ score.productivity_score }}            </h2>            <p class="text-sm text-gray-500 mt-3">              Tasks and project focus.            </p>          </div>        </div>        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">          <div class="bg-white rounded-2xl shadow-sm border p-6">            <h3 class="text-xl font-semibold text-gray-900 mb-4">              Life Balance Radar            </h3>            <div class="h-[420px]">              <Radar :data="radarData" :options="radarOptions" />            </div>          </div>          <div class="bg-white rounded-2xl shadow-sm border p-6">            <h3 class="text-xl font-semibold text-gray-900 mb-4">              Recommendations            </h3>            <div              v-if="score.recommendations && score.recommendations.length"              class="space-y-4"            >              <div                v-for="(item, index) in score.recommendations"                :key="index"                class="border rounded-xl p-4"              >                <div class="flex items-center justify-between">                  <h4 class="font-semibold text-gray-900">                    {{ item.module }}                  </h4>                  <span class="text-xs px-2 py-1 rounded-full bg-gray-100 text-gray-600">                    {{ item.priority }}                  </span>                </div>                <p class="text-gray-600 mt-2">                  {{ item.message }}                </p>              </div>            </div>            <div v-else class="text-gray-500">              No recommendations available.            </div>          </div>        </div>        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">          <div class="bg-white rounded-2xl shadow-sm border p-6">            <h3 class="font-semibold text-gray-900 mb-4">              Finance Breakdown            </h3>            <div class="space-y-3 text-sm">              <div class="flex justify-between">                <span class="text-gray-500">Income</span>                <span class="font-medium">                  {{ score.finance_breakdown?.income ?? 0 }}                </span>              </div>              <div class="flex justify-between">                <span class="text-gray-500">Expenses</span>                <span class="font-medium">                  {{ score.finance_breakdown?.expenses ?? 0 }}                </span>              </div>              <div class="flex justify-between">                <span class="text-gray-500">Net Cashflow</span>                <span class="font-medium">                  {{ score.finance_breakdown?.net_cashflow ?? 0 }}                </span>              </div>            </div>          </div>          <div class="bg-white rounded-2xl shadow-sm border p-6">            <h3 class="font-semibold text-gray-900 mb-4">              Health Breakdown            </h3>            <div class="space-y-3 text-sm">              <div class="flex justify-between">                <span class="text-gray-500">Steps</span>                <span class="font-medium">                  {{ score.health_breakdown?.steps ?? 0 }}                </span>              </div>              <div class="flex justify-between">                <span class="text-gray-500">Water ML</span>                <span class="font-medium">                  {{ score.health_breakdown?.water_ml ?? 0 }}                </span>              </div>              <div class="flex justify-between">                <span class="text-gray-500">Calories</span>                <span class="font-medium">                  {{ score.health_breakdown?.calories ?? 0 }}                </span>              </div>            </div>          </div>          <div class="bg-white rounded-2xl shadow-sm border p-6">            <h3 class="font-semibold text-gray-900 mb-4">              Productivity Breakdown            </h3>            <div class="space-y-3 text-sm">              <div class="flex justify-between">                <span class="text-gray-500">Total Tasks</span>                <span class="font-medium">                  {{ score.productivity_breakdown?.total_tasks ?? 0 }}                </span>              </div>              <div class="flex justify-between">                <span class="text-gray-500">Completed Tasks</span>                <span class="font-medium">                  {{ score.productivity_breakdown?.completed_tasks ?? 0 }}                </span>              </div>              <div class="flex justify-between">                <span class="text-gray-500">Active Projects</span>                <span class="font-medium">                  {{ score.productivity_breakdown?.active_projects ?? 0 }}                </span>              </div>            </div>          </div>        </div>      </template>    </div>  </div></template>

11. Add Route in Vue Router
Open your router file, usually:
nano src/router/index.js
Add import:
import LifeBalanceView from "../views/life-balance/LifeBalanceView.vue";
Add route:
{  path: "/life-balance",  name: "LifeBalance",  component: LifeBalanceView,}
Example:
import { createRouter, createWebHistory } from "vue-router";import LifeBalanceView from "../views/life-balance/LifeBalanceView.vue";const routes = [  {    path: "/life-balance",    name: "LifeBalance",    component: LifeBalanceView,  },];const router = createRouter({  history: createWebHistory(),  routes,});export default router;

12. Update App.vue Sidebar
Open:
nano src/App.vue
Add this link inside your sidebar navigation:
<RouterLink  to="/life-balance"  class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100">  Life Balance</RouterLink>
Example sidebar section:
<nav class="space-y-2">  <RouterLink    to="/dashboard"    class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"  >    Dashboard  </RouterLink>  <RouterLink    to="/finance"    class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"  >    Finance  </RouterLink>  <RouterLink    to="/health"    class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"  >    Health  </RouterLink>  <RouterLink    to="/projects"    class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"  >    Projects  </RouterLink>  <RouterLink    to="/life-balance"    class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"  >    Life Balance  </RouterLink></nav>

13. Run Backend and Frontend
Backend:
cd /u01/nix-life-os/backendphp artisan serve
Frontend:
cd /u01/nix-life-os/frontendnpm run dev
Open:
http://localhost:5173/life-balance

14. Important Table Name Check
This service expects these tables if available:
finance_transactionshealth_step_logshealth_hydration_logshealth_meal_logsprojectsproject_tasks
If one table does not exist, the service will not crash because it uses:
Schema::hasTable(...)
So Step 20 can run even if one module is incomplete.

15. Final Step 20 API Summary
MethodEndpointPurposeGET/api/v1/life-balance/todayCalculate today’s Life Balance scorePOST/api/v1/life-balance/calculateCalculate score for selected dateGET/api/v1/life-balance/history?days=30Get previous Life Balance scores

16. Score Logic Summary
Finance Score
Based on:
IncomeExpensesNet cashflowExpense ratio
Health Score
Based on:
StepsHydrationCalories
Productivity Score
Based on:
Completed tasksTotal tasksActive projects
Overall Score
Overall = Finance + Health + Productivity / 3
Status:
85 - 100 = excellent70 - 84  = balanced55 - 69  = needs_attention0 - 54   = critical

Step 20 is now complete.
Next step should be:
STEP 21 — AI Life Coach EngineUse the Life Balance Index + AI insights to generate daily personal recommendations.
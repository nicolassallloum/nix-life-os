 STEP 30 — Full System Stabilization, Broken Actions Fixes & Auth Pages.
Your current status is:
ModuleStatusUnified DashboardGoodLife BalanceGoodFinance DashboardAdd Transaction not workingFinance AccountsAdd / Edit / View Account neededFinance TransactionsSearch / Add Transaction neededFinance BudgetAdd / Edit Budget neededSteps TrackingAdd Marathons Finished neededWeight TrackingChart + Logs not workingNutrition TrackingServer Error + Add Meal not workingHydration TrackingGoodProjects Dashboard / Tasks / Milestones / Progress / Status UpdatesGoodNotificationsGoodNotification SettingsSave Settings not workingLogging & MonitoringGoodProjectsCannot add new projectsAuthNeed Registration Page + Login Page

1. First Run These Backend Checks
Go to backend:
cd /u01/nix-life-os/backend
Run:
php artisan route:list --path=api/v1
Also run:
php artisan optimize:clearphp artisan config:clearphp artisan route:clearphp artisan cache:clear
Then check Laravel error log:
tail -n 100 storage/logs/laravel.log
Inside Docker:
docker exec -it nixlifeos-backend bashcd /var/www/htmlphp artisan route:list --path=api/v1tail -n 100 storage/logs/laravel.log

2. Most Likely Main Problem
Many of your pages are visible but actions do not work because one of these is missing:


API route not registered.


Controller method missing.


Frontend URL does not match Laravel route.


Form field names do not match backend validation.


Auth token not sent in request.


Missing model $fillable.


Missing relationship or bad UUID foreign key.


Backend returns 500 but frontend only shows “server error”.


So we should fix by standardizing all broken APIs.

3. Add / Verify These API Routes
Open:
nano /u01/nix-life-os/backend/routes/api.php
Make sure you have this structure:
<?phpuse Illuminate\Support\Facades\Route;use App\Http\Controllers\Api\AuthController;use App\Http\Controllers\Api\FinanceAccountController;use App\Http\Controllers\Api\FinanceTransactionController;use App\Http\Controllers\Api\FinanceBudgetController;use App\Http\Controllers\Api\HealthStepLogController;use App\Http\Controllers\Api\HealthWeightLogController;use App\Http\Controllers\Api\HealthMealController;use App\Http\Controllers\Api\NotificationPreferenceController;use App\Http\Controllers\Api\ProjectController;Route::prefix('v1')->group(function () {    /*    |--------------------------------------------------------------------------    | Public Auth Routes    |--------------------------------------------------------------------------    */    Route::post('/auth/register', [AuthController::class, 'register']);    Route::post('/auth/login', [AuthController::class, 'login']);    /*    |--------------------------------------------------------------------------    | Protected Routes    |--------------------------------------------------------------------------    */    Route::middleware('auth:sanctum')->group(function () {        Route::post('/auth/logout', [AuthController::class, 'logout']);        Route::get('/auth/me', [AuthController::class, 'me']);        /*        |--------------------------------------------------------------------------        | Finance        |--------------------------------------------------------------------------        */        Route::apiResource('/finance/accounts', FinanceAccountController::class);        Route::apiResource('/finance/transactions', FinanceTransactionController::class);        Route::apiResource('/finance/budgets', FinanceBudgetController::class);        /*        |--------------------------------------------------------------------------        | Health        |--------------------------------------------------------------------------        */        Route::apiResource('/health/steps', HealthStepLogController::class);        Route::apiResource('/health/weights', HealthWeightLogController::class);        Route::apiResource('/health/meals', HealthMealController::class);        /*        |--------------------------------------------------------------------------        | Notifications        |--------------------------------------------------------------------------        */        Route::get('/notifications/preferences', [NotificationPreferenceController::class, 'show']);        Route::post('/notifications/preferences', [NotificationPreferenceController::class, 'storeOrUpdate']);        Route::put('/notifications/preferences', [NotificationPreferenceController::class, 'storeOrUpdate']);        /*        |--------------------------------------------------------------------------        | Projects        |--------------------------------------------------------------------------        */        Route::apiResource('/projects', ProjectController::class);    });});
Then run:
php artisan optimize:clearphp artisan route:list --path=api/v1

4. Fix Login / Register Backend
Open:
nano /u01/nix-life-os/backend/app/Http/Controllers/Api/AuthController.php
Use this clean version:
<?phpnamespace App\Http\Controllers\Api;use App\Http\Controllers\Controller;use App\Models\User;use Illuminate\Http\Request;use Illuminate\Support\Facades\Hash;use Illuminate\Validation\ValidationException;use Illuminate\Support\Str;class AuthController extends Controller{    public function register(Request $request)    {        $data = $request->validate([            'name' => ['required', 'string', 'max:255'],            'email' => ['required', 'email', 'max:255', 'unique:users,email'],            'password' => ['required', 'string', 'min:6', 'confirmed'],        ]);        $user = User::create([            'id' => (string) Str::uuid(),            'name' => $data['name'],            'email' => $data['email'],            'password' => Hash::make($data['password']),        ]);        $token = $user->createToken('nix-life-os-token')->plainTextToken;        return response()->json([            'message' => 'Registration successful',            'user' => $user,            'token' => $token,        ], 201);    }    public function login(Request $request)    {        $data = $request->validate([            'email' => ['required', 'email'],            'password' => ['required', 'string'],        ]);        $user = User::where('email', $data['email'])->first();        if (! $user || ! Hash::check($data['password'], $user->password)) {            throw ValidationException::withMessages([                'email' => ['Invalid email or password.'],            ]);        }        $token = $user->createToken('nix-life-os-token')->plainTextToken;        return response()->json([            'message' => 'Login successful',            'user' => $user,            'token' => $token,        ]);    }    public function me(Request $request)    {        return response()->json([            'user' => $request->user(),        ]);    }    public function logout(Request $request)    {        $request->user()->currentAccessToken()?->delete();        return response()->json([            'message' => 'Logout successful',        ]);    }}
Important: your users table must use password, not password_hash.

5. Fix User Model
Open:
nano /u01/nix-life-os/backend/app/Models/User.php
Make sure it has:
<?phpnamespace App\Models;use Illuminate\Foundation\Auth\User as Authenticatable;use Laravel\Sanctum\HasApiTokens;use Illuminate\Notifications\Notifiable;use Illuminate\Database\Eloquent\Concerns\HasUuids;class User extends Authenticatable{    use HasApiTokens, Notifiable, HasUuids;    protected $fillable = [        'id',        'name',        'email',        'password',    ];    protected $hidden = [        'password',        'remember_token',    ];    protected $casts = [        'email_verified_at' => 'datetime',        'password' => 'hashed',    ];}

6. Test Auth Backend
Run:
curl -i -X POST http://127.0.0.1:8001/api/v1/auth/register \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "name": "Nix",  "email": "nix@test.com",  "password": "password",  "password_confirmation": "password"}'
Then login:
curl -i -X POST http://127.0.0.1:8001/api/v1/auth/login \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@test.com",  "password": "password"}'
Save token:
TOKEN="PASTE_TOKEN_HERE"
Test protected route:
curl http://127.0.0.1:8001/api/v1/auth/me \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"

7. Add Frontend Auth Pages
Go to frontend:
cd /u01/nix-life-os/frontendmkdir -p src/views/auth

Login Page
Create:
nano src/views/auth/LoginView.vue
Paste:
<template>  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">    <div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">      <h1 class="text-3xl font-bold text-slate-900 mb-2">NIX LIFE OS</h1>      <p class="text-slate-500 mb-6">Login to your personal operating system</p>      <form @submit.prevent="login" class="space-y-4">        <div>          <label class="block text-sm font-medium text-slate-700 mb-1">Email</label>          <input            v-model="form.email"            type="email"            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"            placeholder="nix@example.com"          />        </div>        <div>          <label class="block text-sm font-medium text-slate-700 mb-1">Password</label>          <input            v-model="form.password"            type="password"            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"            placeholder="********"          />        </div>        <p v-if="error" class="text-red-600 text-sm">          {{ error }}        </p>        <button          type="submit"          :disabled="loading"          class="w-full bg-slate-900 text-white rounded-xl py-3 font-semibold hover:bg-slate-800 disabled:opacity-60"        >          {{ loading ? "Logging in..." : "Login" }}        </button>      </form>      <p class="text-sm text-slate-600 mt-6 text-center">        Don't have an account?        <RouterLink to="/register" class="text-slate-900 font-semibold">          Register        </RouterLink>      </p>    </div>  </div></template><script setup>import { reactive, ref } from "vue";import { useRouter, RouterLink } from "vue-router";const router = useRouter();const form = reactive({  email: "",  password: "",});const loading = ref(false);const error = ref("");const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8001/api/v1";async function login() {  loading.value = true;  error.value = "";  try {    const response = await fetch(`${API_BASE_URL}/auth/login`, {      method: "POST",      headers: {        Accept: "application/json",        "Content-Type": "application/json",      },      body: JSON.stringify(form),    });    const data = await response.json();    if (!response.ok) {      throw new Error(data.message || "Login failed");    }    localStorage.setItem("nix_token", data.token);    localStorage.setItem("nix_user", JSON.stringify(data.user));    router.push("/");  } catch (err) {    error.value = err.message;  } finally {    loading.value = false;  }}</script>

Register Page
Create:
nano src/views/auth/RegisterView.vue
Paste:
<template>  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">    <div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">      <h1 class="text-3xl font-bold text-slate-900 mb-2">Create Account</h1>      <p class="text-slate-500 mb-6">Start using NIX LIFE OS</p>      <form @submit.prevent="register" class="space-y-4">        <div>          <label class="block text-sm font-medium text-slate-700 mb-1">Name</label>          <input            v-model="form.name"            type="text"            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"            placeholder="Nix"          />        </div>        <div>          <label class="block text-sm font-medium text-slate-700 mb-1">Email</label>          <input            v-model="form.email"            type="email"            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"            placeholder="nix@example.com"          />        </div>        <div>          <label class="block text-sm font-medium text-slate-700 mb-1">Password</label>          <input            v-model="form.password"            type="password"            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"            placeholder="********"          />        </div>        <div>          <label class="block text-sm font-medium text-slate-700 mb-1">Confirm Password</label>          <input            v-model="form.password_confirmation"            type="password"            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"            placeholder="********"          />        </div>        <p v-if="error" class="text-red-600 text-sm">          {{ error }}        </p>        <button          type="submit"          :disabled="loading"          class="w-full bg-slate-900 text-white rounded-xl py-3 font-semibold hover:bg-slate-800 disabled:opacity-60"        >          {{ loading ? "Creating account..." : "Register" }}        </button>      </form>      <p class="text-sm text-slate-600 mt-6 text-center">        Already have an account?        <RouterLink to="/login" class="text-slate-900 font-semibold">          Login        </RouterLink>      </p>    </div>  </div></template><script setup>import { reactive, ref } from "vue";import { useRouter, RouterLink } from "vue-router";const router = useRouter();const form = reactive({  name: "",  email: "",  password: "",  password_confirmation: "",});const loading = ref(false);const error = ref("");const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8001/api/v1";async function register() {  loading.value = true;  error.value = "";  try {    const response = await fetch(`${API_BASE_URL}/auth/register`, {      method: "POST",      headers: {        Accept: "application/json",        "Content-Type": "application/json",      },      body: JSON.stringify(form),    });    const data = await response.json();    if (!response.ok) {      throw new Error(data.message || "Registration failed");    }    localStorage.setItem("nix_token", data.token);    localStorage.setItem("nix_user", JSON.stringify(data.user));    router.push("/");  } catch (err) {    error.value = err.message;  } finally {    loading.value = false;  }}</script>

8. Update Frontend Router
Open:
nano src/router/index.js
Add these imports:
import LoginView from "../views/auth/LoginView.vue";import RegisterView from "../views/auth/RegisterView.vue";
Add routes:
{  path: "/login",  name: "login",  component: LoginView,},{  path: "/register",  name: "register",  component: RegisterView,},
Add this auth guard at the bottom before export or after router creation:
router.beforeEach((to, from, next) => {  const publicPages = ["/login", "/register"];  const authRequired = !publicPages.includes(to.path);  const token = localStorage.getItem("nix_token");  if (authRequired && !token) {    return next("/login");  }  if ((to.path === "/login" || to.path === "/register") && token) {    return next("/");  }  next();});
Example structure:
import { createRouter, createWebHistory } from "vue-router";import LoginView from "../views/auth/LoginView.vue";import RegisterView from "../views/auth/RegisterView.vue";const routes = [  {    path: "/login",    name: "login",    component: LoginView,  },  {    path: "/register",    name: "register",    component: RegisterView,  },  // keep your existing routes here];const router = createRouter({  history: createWebHistory(),  routes,});router.beforeEach((to, from, next) => {  const publicPages = ["/login", "/register"];  const authRequired = !publicPages.includes(to.path);  const token = localStorage.getItem("nix_token");  if (authRequired && !token) {    return next("/login");  }  if ((to.path === "/login" || to.path === "/register") && token) {    return next("/");  }  next();});export default router;

9. Add Frontend API Helper
Create:
mkdir -p src/servicesnano src/services/api.js
Paste:
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8001/api/v1";export async function apiRequest(endpoint, options = {}) {  const token = localStorage.getItem("nix_token");  const headers = {    Accept: "application/json",    "Content-Type": "application/json",    ...(options.headers || {}),  };  if (token) {    headers.Authorization = `Bearer ${token}`;  }  const response = await fetch(`${API_BASE_URL}${endpoint}`, {    ...options,    headers,  });  const data = await response.json().catch(() => null);  if (!response.ok) {    const message =      data?.message ||      data?.error ||      "Server request failed";    throw new Error(message);  }  return data;}
Use this helper in broken pages instead of raw fetch.
Example:
import { apiRequest } from "../services/api";await apiRequest("/finance/accounts", {  method: "POST",  body: JSON.stringify(form),});

10. Fix Broken Pages by Priority
Priority 1 — Auth
Add:


Login page.


Register page.


Auth guard.


Token storage.


Authorization header.


Without this, many POST/PUT actions will fail.

Priority 2 — Finance
Fix these APIs first:
GET    /api/v1/finance/accountsPOST   /api/v1/finance/accountsGET    /api/v1/finance/accounts/{id}PUT    /api/v1/finance/accounts/{id}DELETE /api/v1/finance/accounts/{id}GET    /api/v1/finance/transactionsPOST   /api/v1/finance/transactionsGET    /api/v1/finance/budgetsPOST   /api/v1/finance/budgetsPUT    /api/v1/finance/budgets/{id}
Test:
curl http://127.0.0.1:8001/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Add account test:
curl -X POST http://127.0.0.1:8001/api/v1/finance/accounts \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "Cash Wallet",  "type": "cash",  "currency": "USD",  "balance": 500}'

Priority 3 — Weight Tracking
Most likely issue:


frontend expects chart labels but API returns different field names.


weight_logs API returns empty or server error.


chart library data is not being updated after fetch.


Expected API:
GET /api/v1/health/weightsPOST /api/v1/health/weights
Expected response should include:
[  {    "id": "uuid",    "weight": 64,    "logged_at": "2026-05-04"  }]
Frontend chart should map:
chartLabels.value = logs.map((item) => item.logged_at);chartValues.value = logs.map((item) => Number(item.weight));

Priority 4 — Nutrition Tracking
Nutrition has Server Error, so check log first:
tail -n 100 /u01/nix-life-os/backend/storage/logs/laravel.log
Most likely previous problem:
HealthMealResource not found
or:
Class App\Http\Resources\HealthMealResource does not exist
Create resource:
php artisan make:resource HealthMealResource
Open:
nano app/Http/Resources/HealthMealResource.php
Paste:
<?phpnamespace App\Http\Resources;use Illuminate\Http\Request;use Illuminate\Http\Resources\Json\JsonResource;class HealthMealResource extends JsonResource{    public function toArray(Request $request): array    {        return [            'id' => $this->id,            'user_id' => $this->user_id,            'meal_type' => $this->meal_type,            'meal_name' => $this->meal_name,            'calories' => $this->calories,            'protein' => $this->protein,            'carbs' => $this->carbs,            'fat' => $this->fat,            'sodium' => $this->sodium,            'potassium' => $this->potassium,            'phosphorus' => $this->phosphorus,            'logged_at' => $this->logged_at,            'notes' => $this->notes,            'created_at' => $this->created_at,            'updated_at' => $this->updated_at,        ];    }}

Priority 5 — Notification Settings
Expected API:
GET  /api/v1/notifications/preferencesPOST /api/v1/notifications/preferencesPUT  /api/v1/notifications/preferences
Test:
curl -X PUT http://127.0.0.1:8001/api/v1/notifications/preferences \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "meal_reminders_enabled": true,  "weight_reminders_enabled": true,  "expense_reminders_enabled": true,  "finance_alerts_enabled": true,  "health_alerts_enabled": true,  "life_balance_alerts_enabled": true,  "daily_expense_warning_limit": 100,  "life_balance_warning_score": 60}'
If this fails, the issue is backend route/controller.

Priority 6 — Cannot Add New Projects
Expected API:
GET  /api/v1/projectsPOST /api/v1/projects
Test:
curl -X POST http://127.0.0.1:8001/api/v1/projects \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "New Nix Life OS Module",  "description": "Test project creation",  "status": "active",  "priority": "high",  "start_date": "2026-05-04",  "end_date": "2026-06-04"}'
If you get 422, field names are wrong.
If you get 500, check Laravel log.
If you get 404, route missing.
If you get 401, token missing.

11. Frontend .env
Open:
nano /u01/nix-life-os/frontend/.env
Add:
VITE_API_BASE_URL=http://127.0.0.1:8001/api/v1
If frontend is inside Docker and calling backend through Docker network, use:
VITE_API_BASE_URL=http://127.0.0.1:8001/api/v1
Then restart frontend:
npm run dev -- --host 0.0.0.0
Or Docker:
docker compose -f docker-compose.prod.yml restart nixlifeos-frontend

12. Final Testing Order
Use this exact order:
1. Register new user2. Login3. Open Unified Dashboard4. Add finance account5. Add finance transaction6. Search finance transaction7. Add budget8. Edit budget9. Add weight log10. Check weight chart11. Add meal12. Save notification settings13. Add new project14. Retest all good pages

13. Important Fix Rule
For every broken button, open browser console and check:
Network tab → request URL → status code
Then classify:
StatusMeaning404API route missing or wrong URL401token missing / not logged in403permission / role issue422validation fields mismatch500Laravel backend errorCORS errorfrontend/backend origin issue

Next Best Step
Start with this command and send me the output:
php artisan route:list --path=api/v1
Then I can give you the full updated index.js router, plus the exact fixed pages one by one: Finance, Weight, Nutrition, Notification Settings, Projects, Login, and Register.
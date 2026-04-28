🔹 STEP 23 — Security & Roles
NIX LIFE OS — Enterprise Security Layer
You already have:
Laravel BackendPostgreSQL DatabaseVue 3 FrontendSanctum AuthenticationFinance ModuleHealth ModuleProject ModuleDashboardAI InsightsNotificationsAutomation Engine
Now Step 23 adds:
Roles & PermissionsProtected APIsUser-based data accessAdmin / User / Viewer rolesFrontend menu securityEnterprise data protection rules

1. Step 23 Goal
The goal of this step is to make NIX LIFE OS secure at enterprise level.
We will add:
Admin roleUser roleViewer rolePermission-based API accessProtected Laravel routesSecure Vue menu visibilityUser-owned data protectionAudit-ready security structure

2. Install Permission Package
From backend folder:
cd /u01/nix-life-os/backend
Run:
composer require spatie/laravel-permission
Publish config and migrations:
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
Run migrations:
php artisan migrate
This creates tables like:
rolespermissionsmodel_has_rolesmodel_has_permissionsrole_has_permissions

3. Update User Model
Open:
nano app/Models/User.php
Use this full version or merge carefully:
<?phpnamespace App\Models;use Illuminate\Foundation\Auth\User as Authenticatable;use Illuminate\Notifications\Notifiable;use Laravel\Sanctum\HasApiTokens;use Spatie\Permission\Traits\HasRoles;use Illuminate\Database\Eloquent\Concerns\HasUuids;class User extends Authenticatable{    use HasApiTokens, Notifiable, HasRoles, HasUuids;    protected $fillable = [        'name',        'email',        'password',    ];    protected $hidden = [        'password',        'remember_token',    ];    protected function casts(): array    {        return [            'email_verified_at' => 'datetime',            'password' => 'hashed',        ];    }}
Important: because your project uses UUID users, keep:
use HasUuids;

4. Create Security Seeder
Create seeder:
php artisan make:seeder SecurityRolePermissionSeeder
Open:
nano database/seeders/SecurityRolePermissionSeeder.php
Paste:
<?phpnamespace Database\Seeders;use Illuminate\Database\Seeder;use Spatie\Permission\Models\Role;use Spatie\Permission\Models\Permission;use App\Models\User;class SecurityRolePermissionSeeder extends Seeder{    public function run(): void    {        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();        $permissions = [            // Dashboard            'dashboard.view',            // Finance            'finance.view',            'finance.create',            'finance.update',            'finance.delete',            // Health            'health.view',            'health.create',            'health.update',            'health.delete',            // Projects            'projects.view',            'projects.create',            'projects.update',            'projects.delete',            // AI            'ai.view',            'ai.generate',            // Notifications            'notifications.view',            'notifications.manage',            // Automation            'automation.view',            'automation.create',            'automation.update',            'automation.delete',            // Security            'security.view',            'security.manage',            // Admin            'users.view',            'users.manage',            'roles.manage',        ];        foreach ($permissions as $permission) {            Permission::firstOrCreate([                'name' => $permission,                'guard_name' => 'web',            ]);        }        $admin = Role::firstOrCreate([            'name' => 'admin',            'guard_name' => 'web',        ]);        $user = Role::firstOrCreate([            'name' => 'user',            'guard_name' => 'web',        ]);        $viewer = Role::firstOrCreate([            'name' => 'viewer',            'guard_name' => 'web',        ]);        $admin->syncPermissions($permissions);        $user->syncPermissions([            'dashboard.view',            'finance.view',            'finance.create',            'finance.update',            'health.view',            'health.create',            'health.update',            'projects.view',            'projects.create',            'projects.update',            'ai.view',            'ai.generate',            'notifications.view',            'automation.view',            'automation.create',            'automation.update',        ]);        $viewer->syncPermissions([            'dashboard.view',            'finance.view',            'health.view',            'projects.view',            'ai.view',            'notifications.view',            'automation.view',        ]);        $firstUser = User::query()->first();        if ($firstUser && ! $firstUser->hasRole('admin')) {            $firstUser->assignRole('admin');        }    }}

5. Register Seeder
Open:
nano database/seeders/DatabaseSeeder.php
Update:
<?phpnamespace Database\Seeders;use Illuminate\Database\Seeder;class DatabaseSeeder extends Seeder{    public function run(): void    {        $this->call([            SecurityRolePermissionSeeder::class,        ]);    }}
Run:
php artisan db:seed --class=SecurityRolePermissionSeeder
Clear cache:
php artisan permission:cache-resetphp artisan optimize:clear

6. Add Role and Permission Response in Login
Open your auth controller.
Usually:
nano app/Http/Controllers/Api/AuthController.php
In the login response, return roles and permissions.
Example:
return response()->json([    'success' => true,    'message' => 'Login successful',    'data' => [        'user' => [            'id' => $user->id,            'name' => $user->name,            'email' => $user->email,            'roles' => $user->getRoleNames(),            'permissions' => $user->getAllPermissions()->pluck('name'),        ],        'token' => $token,        'token_type' => 'Bearer',    ],]);
Also update your /me endpoint if you have one:
public function me(Request $request){    $user = $request->user();    return response()->json([        'success' => true,        'data' => [            'user' => [                'id' => $user->id,                'name' => $user->name,                'email' => $user->email,                'roles' => $user->getRoleNames(),                'permissions' => $user->getAllPermissions()->pluck('name'),            ],        ],    ]);}

7. Protect API Routes
Open:
nano routes/api.php
Use permission middleware around your routes.
Example structure:
<?phpuse Illuminate\Support\Facades\Route;use App\Http\Controllers\Api\AuthController;use App\Http\Controllers\Api\FinanceAccountController;use App\Http\Controllers\Api\FinanceTransactionController;use App\Http\Controllers\Api\FinanceBudgetController;use App\Http\Controllers\Api\HealthWeightLogController;use App\Http\Controllers\Api\HealthStepLogController;use App\Http\Controllers\Api\HealthNutritionController;use App\Http\Controllers\Api\HealthHydrationController;use App\Http\Controllers\Api\ProjectController;use App\Http\Controllers\Api\ProjectTaskController;use App\Http\Controllers\Api\DashboardController;use App\Http\Controllers\Api\NotificationController;use App\Http\Controllers\Api\AutomationController;use App\Http\Controllers\Api\SecurityController;Route::prefix('v1')->group(function () {    Route::post('/auth/register', [AuthController::class, 'register']);    Route::post('/auth/login', [AuthController::class, 'login']);    Route::middleware(['auth:sanctum'])->group(function () {        Route::post('/auth/logout', [AuthController::class, 'logout']);        Route::get('/auth/me', [AuthController::class, 'me']);        /*        |--------------------------------------------------------------------------        | Dashboard        |--------------------------------------------------------------------------        */        Route::middleware('permission:dashboard.view')->group(function () {            Route::get('/dashboard/summary', [DashboardController::class, 'summary']);        });        /*        |--------------------------------------------------------------------------        | Finance        |--------------------------------------------------------------------------        */        Route::middleware('permission:finance.view')->group(function () {            Route::get('/finance/accounts', [FinanceAccountController::class, 'index']);            Route::get('/finance/transactions', [FinanceTransactionController::class, 'index']);            Route::get('/finance/budgets', [FinanceBudgetController::class, 'index']);        });        Route::middleware('permission:finance.create')->group(function () {            Route::post('/finance/accounts', [FinanceAccountController::class, 'store']);            Route::post('/finance/transactions', [FinanceTransactionController::class, 'store']);            Route::post('/finance/budgets', [FinanceBudgetController::class, 'store']);        });        Route::middleware('permission:finance.update')->group(function () {            Route::put('/finance/accounts/{account}', [FinanceAccountController::class, 'update']);            Route::put('/finance/transactions/{transaction}', [FinanceTransactionController::class, 'update']);            Route::put('/finance/budgets/{budget}', [FinanceBudgetController::class, 'update']);        });        Route::middleware('permission:finance.delete')->group(function () {            Route::delete('/finance/accounts/{account}', [FinanceAccountController::class, 'destroy']);            Route::delete('/finance/transactions/{transaction}', [FinanceTransactionController::class, 'destroy']);            Route::delete('/finance/budgets/{budget}', [FinanceBudgetController::class, 'destroy']);        });        /*        |--------------------------------------------------------------------------        | Health        |--------------------------------------------------------------------------        */        Route::middleware('permission:health.view')->group(function () {            Route::get('/health/weight', [HealthWeightLogController::class, 'index']);            Route::get('/health/steps', [HealthStepLogController::class, 'index']);            Route::get('/health/nutrition', [HealthNutritionController::class, 'index']);            Route::get('/health/hydration', [HealthHydrationController::class, 'index']);        });        Route::middleware('permission:health.create')->group(function () {            Route::post('/health/weight', [HealthWeightLogController::class, 'store']);            Route::post('/health/steps', [HealthStepLogController::class, 'store']);            Route::post('/health/nutrition', [HealthNutritionController::class, 'store']);            Route::post('/health/hydration', [HealthHydrationController::class, 'store']);        });        /*        |--------------------------------------------------------------------------        | Projects        |--------------------------------------------------------------------------        */        Route::middleware('permission:projects.view')->group(function () {            Route::get('/projects', [ProjectController::class, 'index']);            Route::get('/projects/{project}', [ProjectController::class, 'show']);            Route::get('/projects/{project}/tasks', [ProjectTaskController::class, 'index']);        });        Route::middleware('permission:projects.create')->group(function () {            Route::post('/projects', [ProjectController::class, 'store']);            Route::post('/projects/{project}/tasks', [ProjectTaskController::class, 'store']);        });        Route::middleware('permission:projects.update')->group(function () {            Route::put('/projects/{project}', [ProjectController::class, 'update']);            Route::put('/projects/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);        });        Route::middleware('permission:projects.delete')->group(function () {            Route::delete('/projects/{project}', [ProjectController::class, 'destroy']);            Route::delete('/projects/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);        });        /*        |--------------------------------------------------------------------------        | Notifications        |--------------------------------------------------------------------------        */        Route::middleware('permission:notifications.view')->group(function () {            Route::get('/notifications', [NotificationController::class, 'index']);            Route::post('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);        });        Route::middleware('permission:notifications.manage')->group(function () {            Route::post('/notifications', [NotificationController::class, 'store']);        });        /*        |--------------------------------------------------------------------------        | Automation        |--------------------------------------------------------------------------        */        Route::middleware('permission:automation.view')->group(function () {            Route::get('/automation/rules', [AutomationController::class, 'index']);        });        Route::middleware('permission:automation.create')->group(function () {            Route::post('/automation/rules', [AutomationController::class, 'store']);        });        Route::middleware('permission:automation.update')->group(function () {            Route::put('/automation/rules/{rule}', [AutomationController::class, 'update']);        });        Route::middleware('permission:automation.delete')->group(function () {            Route::delete('/automation/rules/{rule}', [AutomationController::class, 'destroy']);        });        /*        |--------------------------------------------------------------------------        | Security Admin        |--------------------------------------------------------------------------        */        Route::middleware('permission:security.manage')->group(function () {            Route::get('/security/roles', [SecurityController::class, 'roles']);            Route::get('/security/permissions', [SecurityController::class, 'permissions']);            Route::post('/security/users/{user}/roles', [SecurityController::class, 'assignRole']);        });    });});

8. Create Security Controller
Run:
php artisan make:controller Api/SecurityController
Open:
nano app/Http/Controllers/Api/SecurityController.php
Paste:
<?phpnamespace App\Http\Controllers\Api;use App\Http\Controllers\Controller;use App\Models\User;use Illuminate\Http\Request;use Spatie\Permission\Models\Role;use Spatie\Permission\Models\Permission;class SecurityController extends Controller{    public function roles()    {        return response()->json([            'success' => true,            'data' => Role::query()                ->with('permissions')                ->orderBy('name')                ->get(),        ]);    }    public function permissions()    {        return response()->json([            'success' => true,            'data' => Permission::query()                ->orderBy('name')                ->get(),        ]);    }    public function assignRole(Request $request, User $user)    {        $validated = $request->validate([            'role' => ['required', 'string', 'exists:roles,name'],        ]);        $user->syncRoles([$validated['role']]);        return response()->json([            'success' => true,            'message' => 'User role updated successfully',            'data' => [                'user_id' => $user->id,                'roles' => $user->getRoleNames(),                'permissions' => $user->getAllPermissions()->pluck('name'),            ],        ]);    }}

9. Add User-Owned Data Protection
This is very important.
Every personal record should only return data for the logged-in user.
Example for finance accounts:
public function index(Request $request){    $accounts = FinanceAccount::query()        ->where('user_id', $request->user()->id)        ->latest()        ->get();    return FinanceAccountResource::collection($accounts);}
Example for store:
public function store(Request $request){    $validated = $request->validate([        'account_name' => ['required', 'string', 'max:255'],        'account_type' => ['required', 'string', 'max:100'],        'currency_code' => ['required', 'string', 'size:3'],        'current_balance' => ['nullable', 'numeric'],    ]);    $validated['user_id'] = $request->user()->id;    $account = FinanceAccount::create($validated);    return response()->json([        'success' => true,        'message' => 'Finance account created successfully',        'data' => $account,    ], 201);}
Do the same for:
finance_accountsfinance_transactionsfinance_budgetshealth_weight_logshealth_step_logshealth_nutrition_logshealth_hydration_logsprojectsproject_tasksnotificationsautomation_rulesai_insights
Rule:
Never trust user_id from frontend.Always take user_id from authenticated token.
Correct:
$validated['user_id'] = $request->user()->id;
Wrong:
$validated['user_id'] = $request->input('user_id');

10. Secure Update and Delete Actions
For update/delete, always check ownership.
Example:
public function update(Request $request, FinanceAccount $account){    if ($account->user_id !== $request->user()->id && ! $request->user()->hasRole('admin')) {        abort(403, 'Unauthorized action.');    }    $validated = $request->validate([        'account_name' => ['sometimes', 'string', 'max:255'],        'account_type' => ['sometimes', 'string', 'max:100'],        'currency_code' => ['sometimes', 'string', 'size:3'],        'current_balance' => ['sometimes', 'numeric'],    ]);    $account->update($validated);    return response()->json([        'success' => true,        'message' => 'Account updated successfully',        'data' => $account,    ]);}
Delete:
public function destroy(Request $request, FinanceAccount $account){    if ($account->user_id !== $request->user()->id && ! $request->user()->hasRole('admin')) {        abort(403, 'Unauthorized action.');    }    $account->delete();    return response()->json([        'success' => true,        'message' => 'Account deleted successfully',    ]);}

11. Add Security Helper Function
Create a helper trait:
mkdir -p app/Traitsnano app/Traits/EnsuresUserOwnsResource.php
Paste:
<?phpnamespace App\Traits;use Illuminate\Database\Eloquent\Model;use Illuminate\Http\Request;trait EnsuresUserOwnsResource{    protected function ensureUserOwnsResource(Request $request, Model $model): void    {        if ($request->user()->hasRole('admin')) {            return;        }        if (! isset($model->user_id)) {            abort(403, 'Resource ownership cannot be verified.');        }        if ((string) $model->user_id !== (string) $request->user()->id) {            abort(403, 'Unauthorized action.');        }    }}
Use it in controllers:
use App\Traits\EnsuresUserOwnsResource;class FinanceAccountController extends Controller{    use EnsuresUserOwnsResource;    public function destroy(Request $request, FinanceAccount $account)    {        $this->ensureUserOwnsResource($request, $account);        $account->delete();        return response()->json([            'success' => true,            'message' => 'Deleted successfully',        ]);    }}

12. Create Frontend Permission Helper
In frontend:
cd /u01/nix-life-os/frontendmkdir -p src/utilsnano src/utils/permissions.js
Paste:
export function getCurrentUser() {  const rawUser = localStorage.getItem("nix_user");  if (!rawUser) {    return null;  }  try {    return JSON.parse(rawUser);  } catch {    return null;  }}export function hasRole(role) {  const user = getCurrentUser();  if (!user || !Array.isArray(user.roles)) {    return false;  }  return user.roles.includes(role);}export function hasPermission(permission) {  const user = getCurrentUser();  if (!user || !Array.isArray(user.permissions)) {    return false;  }  return user.permissions.includes(permission);}export function hasAnyPermission(permissions = []) {  return permissions.some((permission) => hasPermission(permission));}export function isAdmin() {  return hasRole("admin");}

13. Store User Permissions After Login
In your login function, after successful login:
localStorage.setItem("token", response.data.data.token);localStorage.setItem(  "nix_user",  JSON.stringify(response.data.data.user));
Expected user object:
{  "id": "019d7c17-adcf-713f-b853-328a2fb65e57",  "name": "Nix",  "email": "nix@example.com",  "roles": ["admin"],  "permissions": [    "dashboard.view",    "finance.view",    "health.view",    "projects.view",    "security.manage"  ]}

14. Secure Vue Router
Open:
nano src/router/index.js
Example:
import { createRouter, createWebHistory } from "vue-router";import { hasPermission } from "@/utils/permissions";import DashboardView from "@/views/DashboardView.vue";import FinanceDashboardView from "@/views/FinanceDashboardView.vue";import HealthDashboardView from "@/views/HealthDashboardView.vue";import ProjectDashboardView from "@/views/ProjectDashboardView.vue";import SecurityRolesView from "@/views/SecurityRolesView.vue";import LoginView from "@/views/LoginView.vue";const routes = [  {    path: "/login",    name: "login",    component: LoginView,  },  {    path: "/",    name: "dashboard",    component: DashboardView,    meta: {      requiresAuth: true,      permission: "dashboard.view",    },  },  {    path: "/finance",    name: "finance",    component: FinanceDashboardView,    meta: {      requiresAuth: true,      permission: "finance.view",    },  },  {    path: "/health",    name: "health",    component: HealthDashboardView,    meta: {      requiresAuth: true,      permission: "health.view",    },  },  {    path: "/projects",    name: "projects",    component: ProjectDashboardView,    meta: {      requiresAuth: true,      permission: "projects.view",    },  },  {    path: "/security/roles",    name: "security.roles",    component: SecurityRolesView,    meta: {      requiresAuth: true,      permission: "security.manage",    },  },];const router = createRouter({  history: createWebHistory(),  routes,});router.beforeEach((to, from, next) => {  const token = localStorage.getItem("token");  if (to.meta.requiresAuth && !token) {    return next("/login");  }  if (to.meta.permission && !hasPermission(to.meta.permission)) {    return next("/");  }  next();});export default router;

15. Secure App.vue Sidebar Menus
Open:
nano src/App.vue
Example menu logic:
<script setup>import { RouterLink, RouterView } from "vue-router";import { hasPermission } from "@/utils/permissions";</script><template>  <div class="min-h-screen bg-gray-50 flex">    <aside class="w-72 bg-white border-r border-gray-200 min-h-screen p-6">      <h1 class="text-3xl font-bold text-gray-900 mb-10">        NIX LIFE OS      </h1>      <nav class="space-y-2">        <RouterLink          v-if="hasPermission('dashboard.view')"          to="/"          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"        >          Dashboard        </RouterLink>        <RouterLink          v-if="hasPermission('finance.view')"          to="/finance"          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"        >          Finance        </RouterLink>        <RouterLink          v-if="hasPermission('health.view')"          to="/health"          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"        >          Health        </RouterLink>        <RouterLink          v-if="hasPermission('projects.view')"          to="/projects"          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"        >          Projects        </RouterLink>        <RouterLink          v-if="hasPermission('automation.view')"          to="/automation"          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"        >          Automation        </RouterLink>        <RouterLink          v-if="hasPermission('security.manage')"          to="/security/roles"          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"        >          Security & Roles        </RouterLink>      </nav>    </aside>    <main class="flex-1 p-8">      <RouterView />    </main>  </div></template>

16. Create Security Roles View
Create:
nano src/views/SecurityRolesView.vue
Paste:
<script setup>import { ref, onMounted } from "vue";const roles = ref([]);const permissions = ref([]);const loading = ref(false);const error = ref(null);const token = localStorage.getItem("token");async function fetchSecurityData() {  loading.value = true;  error.value = null;  try {    const [rolesResponse, permissionsResponse] = await Promise.all([      fetch("http://127.0.0.1:8000/api/v1/security/roles", {        headers: {          Accept: "application/json",          Authorization: `Bearer ${token}`,        },      }),      fetch("http://127.0.0.1:8000/api/v1/security/permissions", {        headers: {          Accept: "application/json",          Authorization: `Bearer ${token}`,        },      }),    ]);    const rolesJson = await rolesResponse.json();    const permissionsJson = await permissionsResponse.json();    roles.value = rolesJson.data || [];    permissions.value = permissionsJson.data || [];  } catch (e) {    error.value = "Failed to load security data.";  } finally {    loading.value = false;  }}onMounted(fetchSecurityData);</script><template>  <div class="space-y-8">    <div>      <h1 class="text-3xl font-bold text-gray-900">        Security & Roles      </h1>      <p class="text-gray-500 mt-2">        Manage enterprise roles, permissions, and API access rules.      </p>    </div>    <div v-if="loading" class="text-gray-500">      Loading security configuration...    </div>    <div v-if="error" class="bg-red-50 text-red-700 p-4 rounded-xl">      {{ error }}    </div>    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">      <div        v-for="role in roles"        :key="role.id"        class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6"      >        <h2 class="text-xl font-bold text-gray-900 capitalize">          {{ role.name }}        </h2>        <p class="text-sm text-gray-500 mt-1">          {{ role.permissions?.length || 0 }} permissions assigned        </p>        <div class="mt-4 flex flex-wrap gap-2">          <span            v-for="permission in role.permissions"            :key="permission.id"            class="text-xs bg-gray-100 text-gray-700 px-3 py-1 rounded-full"          >            {{ permission.name }}          </span>        </div>      </div>    </div>    <div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">      <h2 class="text-xl font-bold text-gray-900 mb-4">        All Permissions      </h2>      <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-3">        <div          v-for="permission in permissions"          :key="permission.id"          class="bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700"        >          {{ permission.name }}        </div>      </div>    </div>  </div></template>

17. API Testing Commands
Check logged-in user permissions
curl http://127.0.0.1:8000/api/v1/auth/me \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "data": {    "user": {      "id": "...",      "name": "Nix",      "email": "...",      "roles": ["admin"],      "permissions": [        "dashboard.view",        "finance.view",        "security.manage"      ]    }  }}

Check roles
curl http://127.0.0.1:8000/api/v1/security/roles \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

Check permissions
curl http://127.0.0.1:8000/api/v1/security/permissions \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

Assign role to user
Replace user ID:
curl -X POST http://127.0.0.1:8000/api/v1/security/users/USER_ID_HERE/roles \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "role": "user"  }'


curl -X POST http://127.0.0.1:8000/api/v1/security/users/019dbf32-f6d4-70c5-93ef-66ea278ca67b/roles \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "role": "user"
  }'



18. Enterprise Security Rules
Use these rules across the full project.
Rule 1 — Every API must require authentication
All protected routes must use:
auth:sanctum

Rule 2 — Every module must require permissions
Example:
permission:finance.viewpermission:health.createpermission:projects.updatepermission:automation.delete

Rule 3 — Never accept user_id from frontend
Bad:
'user_id' => $request->user_id
Good:
'user_id' => $request->user()->id

Rule 4 — Users can only access their own data
Every query should include:
where('user_id', $request->user()->id)
Except admin dashboards.

Rule 5 — Admin can manage everything
Use:
$request->user()->hasRole('admin')

Rule 6 — Viewer is read-only
Viewer permissions:
dashboard.viewfinance.viewhealth.viewprojects.viewai.viewnotifications.viewautomation.view
No create, update, or delete.

Rule 7 — Tokens must be protected
Never expose Sanctum tokens in:
GitHublogsscreenshotsemailsfrontend source code

19. Recommended Permissions Matrix
ModuleAdminUserViewerDashboard ViewYesYesYesFinance ViewYesYesYesFinance CreateYesYesNoFinance UpdateYesYesNoFinance DeleteYesNo / OptionalNoHealth ViewYesYesYesHealth CreateYesYesNoHealth UpdateYesYesNoHealth DeleteYesNo / OptionalNoProjects ViewYesYesYesProjects CreateYesYesNoProjects UpdateYesYesNoProjects DeleteYesNo / OptionalNoAI ViewYesYesYesAI GenerateYesYesNoNotifications ViewYesYesYesNotifications ManageYesNoNoAutomation ViewYesYesYesAutomation CreateYesYesNoAutomation UpdateYesYesNoAutomation DeleteYesNo / OptionalNoSecurity ManageYesNoNoUsers ManageYesNoNoRoles ManageYesNoNo

20. Step 23 Completion Checklist
Step 23 is complete when:
Spatie permission package installedPermission tables migratedUser model uses HasRolesAdmin/User/Viewer roles createdPermissions seededFirst user assigned as adminLogin returns roles and permissions/me endpoint returns roles and permissionsAPI routes protected by auth:sanctumAPI routes protected by permission middlewareControllers filter data by authenticated userUpdate/delete actions check ownershipVue router checks permissionsVue sidebar hides unauthorized modulesSecurity Roles page worksViewer role cannot create/update/deleteUser role cannot access security managementAdmin role can access everything

21. Recommended Git Commit
git add .git commit -m "Step 23: add enterprise security roles and permissions"

22. Next Step
After Step 23, the best next step is:
🔹 STEP 24 — Audit Logs & Activity Tracking
Because after adding roles and permissions, the system should record:
who logged inwho created recordswho updated recordswho deleted recordswho triggered automationwho generated AI insightswho changed roles
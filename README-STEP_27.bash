🔹 STEP 27 — SaaS Transformation
Upgrade NIX LIFE OS to a Cloud-Ready SaaS Platform
1. Step 27 Goal

Upgrade NIX LIFE OS from a personal single-user system into a multi-user SaaS-ready platform.

The SaaS upgrade adds:

Multi-user support
User-owned data
Subscription plans
Usage limits
Feature access control
Cloud-ready architecture
Future billing integration
Future tenant/team support

Current stack:

Laravel Backend
Vue Frontend
PostgreSQL Database
Python AI Engine
Docker Deployment
Monitoring
Logging
Security Roles

Target SaaS stack:

NIX LIFE OS SaaS Platform
├── Multi-user accounts
├── User-isolated finance data
├── User-isolated health data
├── User-isolated project data
├── Subscription plans
├── Plan limits
├── Usage tracking
├── SaaS API endpoints
├── Billing-ready structure
└── Cloud-ready deployment model
2. SaaS Architecture
Current Architecture
User
 ↓
Vue Frontend
 ↓
Laravel API
 ↓
PostgreSQL
 ↓
Python AI Engine
New SaaS Architecture
Multiple Users
 ↓
Vue Frontend
 ↓
Laravel API + Sanctum Auth
 ↓
User Ownership Layer
 ↓
Subscription & Plan Control
 ↓
PostgreSQL Multi-User SaaS Database
 ↓
Python AI Engine Per User
 ↓
Docker / Cloud Deployment
3. SaaS Model Used

For your current NIX LIFE OS project, use:

Single database
Multiple users
Every business table has user_id
Every query is filtered by authenticated user

Example:

finance_accounts.user_id
finance_transactions.user_id
health_meals.user_id
health_hydration_logs.user_id
projects.user_id
notifications.user_id
ai_insights.user_id
subscriptions.user_id
subscription_usage.user_id

This is the best model for your current stage because it is simple, scalable, and cloud-ready.

4. SaaS Tables Added

Step 27 adds:

plans
subscriptions
subscription_usage

Future tables:

organizations
organization_users
tenant_settings
invoices
payment_webhooks
5. Important Project-Specific Note

Your users.id column is UUID.

So this is wrong:

$table->foreignId('user_id');

Because it creates a BIGINT.

Use this instead:

$table->uuid('user_id');

This fixes the error:

foreign key constraint "subscriptions_user_id_foreign" cannot be implemented
Key columns "user_id" and "id" are incompatible types: bigint and uuid
6. Create Plans Migration

Run:

cd /u01/nix-life-os/backend

php artisan make:migration create_plans_table

Update the generated migration:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('code')->unique();
            $table->string('name');

            $table->decimal('monthly_price', 10, 2)->default(0);
            $table->decimal('yearly_price', 10, 2)->default(0);

            $table->integer('max_finance_accounts')->default(3);
            $table->integer('max_projects')->default(3);
            $table->integer('max_ai_insights_per_month')->default(30);
            $table->integer('max_notifications_per_month')->default(100);

            $table->boolean('finance_module_enabled')->default(true);
            $table->boolean('health_module_enabled')->default(true);
            $table->boolean('projects_module_enabled')->default(true);
            $table->boolean('ai_module_enabled')->default(false);
            $table->boolean('automation_module_enabled')->default(false);
            $table->boolean('monitoring_module_enabled')->default(false);

            $table->jsonb('features')->nullable();

            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('code');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};
7. Create Subscriptions Migration

Run:

php artisan make:migration create_subscriptions_table

Update the migration:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');
            $table->uuid('plan_id');

            $table->string('status')->default('active');
            $table->string('billing_cycle')->default('monthly');

            $table->timestamp('started_at')->nullable();
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('current_period_starts_at')->nullable();
            $table->timestamp('current_period_ends_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();

            $table->string('payment_provider')->nullable();
            $table->string('payment_customer_id')->nullable();
            $table->string('payment_subscription_id')->nullable();

            $table->jsonb('metadata')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->foreign('plan_id')
                ->references('id')
                ->on('plans')
                ->cascadeOnDelete();

            $table->index('user_id');
            $table->index('plan_id');
            $table->index('status');
            $table->index('billing_cycle');

            $table->unique(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
8. Create Subscription Usage Migration

Run:

php artisan make:migration create_subscription_usage_table

Update the migration:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_usage', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');
            $table->uuid('subscription_id');

            $table->integer('finance_accounts_count')->default(0);
            $table->integer('projects_count')->default(0);
            $table->integer('ai_insights_used')->default(0);
            $table->integer('notifications_sent')->default(0);

            $table->date('period_start');
            $table->date('period_end');

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->foreign('subscription_id')
                ->references('id')
                ->on('subscriptions')
                ->cascadeOnDelete();

            $table->index('user_id');
            $table->index('subscription_id');
            $table->index(['period_start', 'period_end']);

            $table->unique(['user_id', 'subscription_id', 'period_start', 'period_end']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_usage');
    }
};
9. UUID Trait

Create:

mkdir -p app/Models/Concerns
nano app/Models/Concerns/UsesUuid.php

Add:

<?php

namespace App\Models\Concerns;

use Illuminate\Support\Str;

trait UsesUuid
{
    protected static function bootUsesUuid(): void
    {
        static::creating(function ($model) {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }
        });
    }

    public function getIncrementing(): bool
    {
        return false;
    }

    public function getKeyType(): string
    {
        return 'string';
    }
}
10. Plan Model

Create:

php artisan make:model Plan

Update:

<?php

namespace App\Models;

use App\Models\Concerns\UsesUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model
{
    use UsesUuid;

    protected $fillable = [
        'code',
        'name',
        'monthly_price',
        'yearly_price',
        'max_finance_accounts',
        'max_projects',
        'max_ai_insights_per_month',
        'max_notifications_per_month',
        'finance_module_enabled',
        'health_module_enabled',
        'projects_module_enabled',
        'ai_module_enabled',
        'automation_module_enabled',
        'monitoring_module_enabled',
        'features',
        'is_active',
    ];

    protected $casts = [
        'monthly_price' => 'decimal:2',
        'yearly_price' => 'decimal:2',
        'features' => 'array',
        'is_active' => 'boolean',
        'finance_module_enabled' => 'boolean',
        'health_module_enabled' => 'boolean',
        'projects_module_enabled' => 'boolean',
        'ai_module_enabled' => 'boolean',
        'automation_module_enabled' => 'boolean',
        'monitoring_module_enabled' => 'boolean',
    ];

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }
}
11. Subscription Model

Create:

php artisan make:model Subscription

Update:

<?php

namespace App\Models;

use App\Models\Concerns\UsesUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subscription extends Model
{
    use UsesUuid;

    protected $fillable = [
        'user_id',
        'plan_id',
        'status',
        'billing_cycle',
        'started_at',
        'trial_ends_at',
        'current_period_starts_at',
        'current_period_ends_at',
        'cancelled_at',
        'payment_provider',
        'payment_customer_id',
        'payment_subscription_id',
        'metadata',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'trial_ends_at' => 'datetime',
        'current_period_starts_at' => 'datetime',
        'current_period_ends_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }

    public function usage(): HasMany
    {
        return $this->hasMany(SubscriptionUsage::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }
}
12. SubscriptionUsage Model

Create:

php artisan make:model SubscriptionUsage

Update:

<?php

namespace App\Models;

use App\Models\Concerns\UsesUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionUsage extends Model
{
    use UsesUuid;

    protected $table = 'subscription_usage';

    protected $fillable = [
        'user_id',
        'subscription_id',
        'finance_accounts_count',
        'projects_count',
        'ai_insights_used',
        'notifications_sent',
        'period_start',
        'period_end',
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class);
    }
}
13. Update User Model

Open:

nano app/Models/User.php

Add imports:

use App\Models\Plan;
use App\Models\Subscription;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

Inside the User class, add:

public function subscriptions(): HasMany
{
    return $this->hasMany(Subscription::class);
}

public function activeSubscription(): HasOne
{
    return $this->hasOne(Subscription::class)->where('status', 'active');
}

public function currentPlan(): ?Plan
{
    return $this->activeSubscription?->plan;
}
14. PlanSeeder

Create:

php artisan make:seeder PlanSeeder

Update:

<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'code' => 'free',
                'name' => 'Free',
                'monthly_price' => 0,
                'yearly_price' => 0,
                'max_finance_accounts' => 2,
                'max_projects' => 2,
                'max_ai_insights_per_month' => 5,
                'max_notifications_per_month' => 20,
                'finance_module_enabled' => true,
                'health_module_enabled' => true,
                'projects_module_enabled' => true,
                'ai_module_enabled' => false,
                'automation_module_enabled' => false,
                'monitoring_module_enabled' => false,
                'features' => [
                    'Basic finance tracking',
                    'Basic health tracking',
                    'Basic project tracking',
                ],
                'is_active' => true,
            ],
            [
                'code' => 'pro',
                'name' => 'Pro',
                'monthly_price' => 9.99,
                'yearly_price' => 99.99,
                'max_finance_accounts' => 20,
                'max_projects' => 50,
                'max_ai_insights_per_month' => 300,
                'max_notifications_per_month' => 1000,
                'finance_module_enabled' => true,
                'health_module_enabled' => true,
                'projects_module_enabled' => true,
                'ai_module_enabled' => true,
                'automation_module_enabled' => true,
                'monitoring_module_enabled' => true,
                'features' => [
                    'Advanced finance analytics',
                    'AI insights',
                    'Automation engine',
                    'Monitoring dashboard',
                    'Unlimited dashboards',
                ],
                'is_active' => true,
            ],
            [
                'code' => 'enterprise',
                'name' => 'Enterprise',
                'monthly_price' => 49.99,
                'yearly_price' => 499.99,
                'max_finance_accounts' => 999999,
                'max_projects' => 999999,
                'max_ai_insights_per_month' => 999999,
                'max_notifications_per_month' => 999999,
                'finance_module_enabled' => true,
                'health_module_enabled' => true,
                'projects_module_enabled' => true,
                'ai_module_enabled' => true,
                'automation_module_enabled' => true,
                'monitoring_module_enabled' => true,
                'features' => [
                    'Enterprise usage',
                    'Team support ready',
                    'Advanced monitoring',
                    'Priority support',
                    'Custom integrations',
                ],
                'is_active' => true,
            ],
        ];

        foreach ($plans as $plan) {
            Plan::updateOrCreate(
                ['code' => $plan['code']],
                $plan
            );
        }
    }
}
15. Run Migration and Seeder

Run:

cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan migrate --force
php artisan db:seed --class=PlanSeeder --force

Verify:

php artisan tinker

Inside Tinker:

App\Models\Plan::count();
App\Models\Plan::pluck('code', 'name');
Schema::hasTable('subscriptions');
Schema::hasTable('subscription_usage');
exit

Expected:

3

Free => free
Pro => pro
Enterprise => enterprise

true
true
16. Subscription Service

Create:

mkdir -p app/Services/SaaS
nano app/Services/SaaS/SubscriptionService.php

Add:

<?php

namespace App\Services\SaaS;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\SubscriptionUsage;
use App\Models\User;
use Carbon\Carbon;

class SubscriptionService
{
    public function createDefaultFreeSubscription(User $user): Subscription
    {
        $plan = Plan::where('code', 'free')->firstOrFail();

        $existingSubscription = Subscription::where('user_id', $user->id)
            ->where('status', 'active')
            ->first();

        if ($existingSubscription) {
            return $existingSubscription;
        }

        $subscription = Subscription::create([
            'user_id' => $user->id,
            'plan_id' => $plan->id,
            'status' => 'active',
            'billing_cycle' => 'monthly',
            'started_at' => now(),
            'trial_ends_at' => null,
            'current_period_starts_at' => now()->startOfMonth(),
            'current_period_ends_at' => now()->endOfMonth(),
            'metadata' => [
                'source' => 'manual_or_default_registration',
            ],
        ]);

        SubscriptionUsage::create([
            'user_id' => $user->id,
            'subscription_id' => $subscription->id,
            'finance_accounts_count' => 0,
            'projects_count' => 0,
            'ai_insights_used' => 0,
            'notifications_sent' => 0,
            'period_start' => Carbon::now()->startOfMonth()->toDateString(),
            'period_end' => Carbon::now()->endOfMonth()->toDateString(),
        ]);

        return $subscription;
    }

    public function getActiveSubscription(User $user): ?Subscription
    {
        return Subscription::with('plan')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->first();
    }

    public function userHasFeature(User $user, string $feature): bool
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription || !$subscription->plan) {
            return false;
        }

        return match ($feature) {
            'finance' => $subscription->plan->finance_module_enabled,
            'health' => $subscription->plan->health_module_enabled,
            'projects' => $subscription->plan->projects_module_enabled,
            'ai' => $subscription->plan->ai_module_enabled,
            'automation' => $subscription->plan->automation_module_enabled,
            'monitoring' => $subscription->plan->monitoring_module_enabled,
            default => false,
        };
    }

    public function canCreateFinanceAccount(User $user): bool
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription || !$subscription->plan) {
            return false;
        }

        $usage = SubscriptionUsage::where('user_id', $user->id)
            ->where('subscription_id', $subscription->id)
            ->latest()
            ->first();

        if (!$usage) {
            return false;
        }

        return $usage->finance_accounts_count < $subscription->plan->max_finance_accounts;
    }

    public function canCreateProject(User $user): bool
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription || !$subscription->plan) {
            return false;
        }

        $usage = SubscriptionUsage::where('user_id', $user->id)
            ->where('subscription_id', $subscription->id)
            ->latest()
            ->first();

        if (!$usage) {
            return false;
        }

        return $usage->projects_count < $subscription->plan->max_projects;
    }

    public function canUseAiInsight(User $user): bool
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription || !$subscription->plan) {
            return false;
        }

        $usage = SubscriptionUsage::where('user_id', $user->id)
            ->where('subscription_id', $subscription->id)
            ->latest()
            ->first();

        if (!$usage) {
            return false;
        }

        return $usage->ai_insights_used < $subscription->plan->max_ai_insights_per_month;
    }
}

Then run:

composer dump-autoload
php artisan optimize:clear
17. SaaS Controller

Create:

php artisan make:controller Api/SaaSController
nano app/Http/Controllers/Api/SaaSController.php

Add:

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Models\SubscriptionUsage;
use App\Services\SaaS\SubscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SaaSController extends Controller
{
    public function plans(): JsonResponse
    {
        return response()->json([
            'data' => Plan::where('is_active', true)
                ->orderBy('monthly_price')
                ->get(),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        $subscription = app(SubscriptionService::class)
            ->getActiveSubscription($user);

        $usage = null;

        if ($subscription) {
            $usage = SubscriptionUsage::where('user_id', $user->id)
                ->where('subscription_id', $subscription->id)
                ->latest()
                ->first();
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'subscription' => $subscription,
            'plan' => $subscription?->plan,
            'usage' => $usage,
        ]);
    }
}
18. Register SaaS Routes

Open:

nano routes/api.php

Add at the top:

use App\Http\Controllers\Api\SaaSController;

Inside your existing authenticated v1 route group, add:

Route::get('/saas/plans', [SaaSController::class, 'plans']);
Route::get('/saas/me', [SaaSController::class, 'me']);

Example:

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/saas/plans', [SaaSController::class, 'plans']);
    Route::get('/saas/me', [SaaSController::class, 'me']);

    // Existing routes here...
});

Then run:

php artisan optimize:clear
php artisan route:list | grep saas

Expected:

GET|HEAD api/v1/saas/me
GET|HEAD api/v1/saas/plans
19. Restart Docker Backend

Because your API is served through Docker on port 8000, restart the backend containers:

cd /u01/nix-life-os

docker restart nixlifeos-backend nixlifeos-backend-nginx
20. Create Test User and Free Subscription

If your users table is empty, create a local test user:

cd /u01/nix-life-os/backend

php artisan tinker

Inside Tinker:

$user = App\Models\User::create([
    'name' => 'Nix',
    'email' => 'nix@example.com',
    'password' => Illuminate\Support\Facades\Hash::make('password123'),
]);

app(App\Services\SaaS\SubscriptionService::class)->createDefaultFreeSubscription($user);

$token = $user->createToken('local-dev-token')->plainTextToken;

$token;

Copy the token.

Exit:

exit

Then set the token in terminal:

export TOKEN="PASTE_TOKEN_HERE"

Verify:

echo $TOKEN
21. Test SaaS Plans Endpoint

Run:

curl http://127.0.0.1:8000/api/v1/saas/plans \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected result:

{
  "data": [
    {
      "code": "free",
      "name": "Free"
    },
    {
      "code": "pro",
      "name": "Pro"
    },
    {
      "code": "enterprise",
      "name": "Enterprise"
    }
  ]
}

Your test already confirmed this endpoint is working.

22. Test Current Subscription Endpoint

Run:

curl http://127.0.0.1:8000/api/v1/saas/me \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected result:

{
  "user": {
    "name": "Nix",
    "email": "nix@example.com"
  },
  "subscription": {
    "status": "active",
    "billing_cycle": "monthly"
  },
  "plan": {
    "code": "free",
    "name": "Free"
  },
  "usage": {
    "finance_accounts_count": 0,
    "projects_count": 0,
    "ai_insights_used": 0,
    "notifications_sent": 0
  }
}

Your test already confirmed this endpoint is working.

23. SaaS Middleware

Create:

php artisan make:middleware EnsureFeatureEnabled

Open:

nano app/Http/Middleware/EnsureFeatureEnabled.php

Add:

<?php

namespace App\Http\Middleware;

use App\Services\SaaS\SubscriptionService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureFeatureEnabled
{
    public function handle(Request $request, Closure $next, string $feature): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $allowed = app(SubscriptionService::class)
            ->userHasFeature($user, $feature);

        if (!$allowed) {
            return response()->json([
                'message' => 'Your current subscription plan does not include this feature.',
                'feature' => $feature,
                'upgrade_required' => true,
            ], 403);
        }

        return $next($request);
    }
}
24. Register Middleware

If you are using Laravel 11 or newer, open:

nano bootstrap/app.php

Register the alias:

$middleware->alias([
    'feature' => \App\Http\Middleware\EnsureFeatureEnabled::class,
]);

If your project still has app/Http/Kernel.php, add:

'feature' => \App\Http\Middleware\EnsureFeatureEnabled::class,

inside:

protected $middlewareAliases = [
    // ...
];

Then run:

php artisan optimize:clear
25. Protect Feature Routes

Example:

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/saas/plans', [SaaSController::class, 'plans']);
    Route::get('/saas/me', [SaaSController::class, 'me']);

    Route::middleware('feature:finance')->group(function () {
        // Finance routes here
    });

    Route::middleware('feature:health')->group(function () {
        // Health routes here
    });

    Route::middleware('feature:projects')->group(function () {
        // Project routes here
    });

    Route::middleware('feature:ai')->group(function () {
        // AI routes here
    });

    Route::middleware('feature:automation')->group(function () {
        // Automation routes here
    });

    Route::middleware('feature:monitoring')->group(function () {
        // Monitoring routes here
    });
});
26. Add Usage Limit Check — Finance Accounts

In FinanceAccountController@store, add before create:

if (!app(\App\Services\SaaS\SubscriptionService::class)->canCreateFinanceAccount($request->user())) {
    return response()->json([
        'message' => 'Finance account limit reached for your current plan.',
        'upgrade_required' => true,
    ], 403);
}

After successful create:

$subscription = app(\App\Services\SaaS\SubscriptionService::class)
    ->getActiveSubscription($request->user());

if ($subscription) {
    \App\Models\SubscriptionUsage::where('user_id', $request->user()->id)
        ->where('subscription_id', $subscription->id)
        ->latest()
        ->first()
        ?->increment('finance_accounts_count');
}
27. Add Usage Limit Check — Projects

In ProjectController@store, add before create:

if (!app(\App\Services\SaaS\SubscriptionService::class)->canCreateProject($request->user())) {
    return response()->json([
        'message' => 'Project limit reached for your current plan.',
        'upgrade_required' => true,
    ], 403);
}

After successful create:

$subscription = app(\App\Services\SaaS\SubscriptionService::class)
    ->getActiveSubscription($request->user());

if ($subscription) {
    \App\Models\SubscriptionUsage::where('user_id', $request->user()->id)
        ->where('subscription_id', $subscription->id)
        ->latest()
        ->first()
        ?->increment('projects_count');
}
28. Multi-User Data Isolation Rule

Every SaaS query must filter by the authenticated user.

Correct:

FinanceAccount::where('user_id', $request->user()->id)->get();

Wrong:

FinanceAccount::all();

Correct create example:

FinanceAccount::create([
    'user_id' => $request->user()->id,
    'account_name' => $request->account_name,
]);

This is the most important SaaS security rule.

29. Frontend SaaS Pages

Create:

frontend/src/views/SaaSPlansView.vue
frontend/src/views/SaaSSubscriptionView.vue
SaaSPlansView.vue
<script setup>
import { ref, onMounted } from "vue";

const plans = ref([]);
const loading = ref(true);
const error = ref(null);

const token = localStorage.getItem("token");

async function loadPlans() {
  loading.value = true;
  error.value = null;

  try {
    const response = await fetch("http://127.0.0.1:8000/api/v1/saas/plans", {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || "Failed to load plans");
    }

    plans.value = data.data || [];
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
}

onMounted(loadPlans);
</script>

<template>
  <div class="p-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900">Subscription Plans</h1>
      <p class="text-gray-500 mt-2">
        Choose the best plan for your NIX LIFE OS usage.
      </p>
    </div>

    <div v-if="loading" class="text-gray-500">
      Loading plans...
    </div>

    <div v-else-if="error" class="bg-red-50 text-red-700 border border-red-200 rounded-xl p-4">
      {{ error }}
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div
        v-for="plan in plans"
        :key="plan.id"
        class="bg-white border border-gray-200 rounded-2xl shadow-sm p-6"
      >
        <h2 class="text-2xl font-bold text-gray-900">
          {{ plan.name }}
        </h2>

        <p class="text-4xl font-bold text-gray-900 mt-4">
          ${{ plan.monthly_price }}
          <span class="text-sm text-gray-500">/ month</span>
        </p>

        <div class="mt-6 space-y-2 text-sm text-gray-600">
          <p>Finance accounts: {{ plan.max_finance_accounts }}</p>
          <p>Projects: {{ plan.max_projects }}</p>
          <p>AI insights/month: {{ plan.max_ai_insights_per_month }}</p>
          <p>Notifications/month: {{ plan.max_notifications_per_month }}</p>
        </div>

        <div class="mt-6">
          <h3 class="font-semibold text-gray-800 mb-2">Features</h3>
          <ul class="space-y-1 text-sm text-gray-600">
            <li v-for="feature in plan.features" :key="feature">
              ✓ {{ feature }}
            </li>
          </ul>
        </div>

        <button
          class="w-full mt-6 bg-gray-900 text-white rounded-xl py-3 font-semibold hover:bg-gray-800"
        >
          Choose Plan
        </button>
      </div>
    </div>
  </div>
</template>
SaaSSubscriptionView.vue
<script setup>
import { ref, onMounted, computed } from "vue";

const data = ref(null);
const loading = ref(true);
const error = ref(null);

const token = localStorage.getItem("token");

function usagePercent(used, max) {
  if (!max || max <= 0) return 0;
  return Math.min(100, (used / max) * 100);
}

const planName = computed(() => data.value?.plan?.name || "No Plan");

async function loadSubscription() {
  loading.value = true;
  error.value = null;

  try {
    const response = await fetch("http://127.0.0.1:8000/api/v1/saas/me", {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.message || "Failed to load subscription");
    }

    data.value = result;
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
}

onMounted(loadSubscription);
</script>

<template>
  <div class="p-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900">My Subscription</h1>
      <p class="text-gray-500 mt-2">
        View your current plan, limits, and usage.
      </p>
    </div>

    <div v-if="loading" class="text-gray-500">
      Loading subscription...
    </div>

    <div v-else-if="error" class="bg-red-50 text-red-700 border border-red-200 rounded-xl p-4">
      {{ error }}
    </div>

    <div v-else-if="data" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white border border-gray-200 rounded-2xl shadow-sm p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">
          Current Plan
        </h2>

        <p class="text-3xl font-bold text-gray-900">
          {{ planName }}
        </p>

        <p class="text-gray-500 mt-2">
          Status: {{ data.subscription?.status }}
        </p>

        <p class="text-gray-500">
          Billing: {{ data.subscription?.billing_cycle }}
        </p>

        <p class="text-gray-500">
          Period Ends:
          {{ data.subscription?.current_period_ends_at }}
        </p>
      </div>

      <div class="bg-white border border-gray-200 rounded-2xl shadow-sm p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">
          Usage
        </h2>

        <div class="space-y-4">
          <div>
            <div class="flex justify-between text-sm mb-1">
              <span>Finance Accounts</span>
              <span>
                {{ data.usage?.finance_accounts_count }}
                /
                {{ data.plan?.max_finance_accounts }}
              </span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3">
              <div
                class="bg-gray-900 h-3 rounded-full"
                :style="{
                  width: usagePercent(
                    data.usage?.finance_accounts_count,
                    data.plan?.max_finance_accounts
                  ) + '%'
                }"
              ></div>
            </div>
          </div>

          <div>
            <div class="flex justify-between text-sm mb-1">
              <span>Projects</span>
              <span>
                {{ data.usage?.projects_count }}
                /
                {{ data.plan?.max_projects }}
              </span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3">
              <div
                class="bg-gray-900 h-3 rounded-full"
                :style="{
                  width: usagePercent(
                    data.usage?.projects_count,
                    data.plan?.max_projects
                  ) + '%'
                }"
              ></div>
            </div>
          </div>

          <div>
            <div class="flex justify-between text-sm mb-1">
              <span>AI Insights</span>
              <span>
                {{ data.usage?.ai_insights_used }}
                /
                {{ data.plan?.max_ai_insights_per_month }}
              </span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3">
              <div
                class="bg-gray-900 h-3 rounded-full"
                :style="{
                  width: usagePercent(
                    data.usage?.ai_insights_used,
                    data.plan?.max_ai_insights_per_month
                  ) + '%'
                }"
              ></div>
            </div>
          </div>

          <div>
            <div class="flex justify-between text-sm mb-1">
              <span>Notifications</span>
              <span>
                {{ data.usage?.notifications_sent }}
                /
                {{ data.plan?.max_notifications_per_month }}
              </span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3">
              <div
                class="bg-gray-900 h-3 rounded-full"
                :style="{
                  width: usagePercent(
                    data.usage?.notifications_sent,
                    data.plan?.max_notifications_per_month
                  ) + '%'
                }"
              ></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
30. Add Frontend Routes

Open:

nano frontend/src/router/index.js

Add imports:

import SaaSPlansView from "../views/SaaSPlansView.vue";
import SaaSSubscriptionView from "../views/SaaSSubscriptionView.vue";

Add routes:

{
  path: "/saas/plans",
  name: "saas-plans",
  component: SaaSPlansView,
},
{
  path: "/saas/subscription",
  name: "saas-subscription",
  component: SaaSSubscriptionView,
},
31. Add Sidebar Menu Items

In App.vue, add:

<div class="mt-6">
  <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
    SaaS
  </p>

  <RouterLink
    to="/saas/subscription"
    class="block px-4 py-2 rounded-lg hover:bg-gray-100"
  >
    My Subscription
  </RouterLink>

  <RouterLink
    to="/saas/plans"
    class="block px-4 py-2 rounded-lg hover:bg-gray-100"
  >
    Plans
  </RouterLink>
</div>
32. SaaS Environment Variables

Add to backend .env:

SAAS_MODE=true
DEFAULT_PLAN_CODE=free

BILLING_ENABLED=false
BILLING_PROVIDER=manual

SUBSCRIPTION_GRACE_DAYS=7
FREE_TRIAL_DAYS=0

AI_USAGE_LIMIT_ENABLED=true
PLAN_LIMITS_ENABLED=true
33. Cloud-Ready SaaS Deployment Requirements

Your future cloud SaaS structure should include:

Load Balancer
Nginx Reverse Proxy
Frontend Container
Backend Nginx Container
Backend PHP-FPM Container
Queue Worker Container
Scheduler Container
Python AI Engine Container
Managed PostgreSQL
Redis
Object Storage
Centralized Logs
Monitoring Stack
Backup System
34. SaaS Security Rules

Apply these rules across the project:

1. Every user only sees their own data.
2. Every query must filter by user_id.
3. Every SaaS feature checks subscription access.
4. Every expensive AI action checks usage limits.
5. Admin routes are protected by admin role.
6. Logs include user_id.
7. Subscription changes are audit logged.
8. API responses never expose another user's data.
9. Background jobs process data per user.
10. Billing routes are protected.
35. Final Verification Commands

Run:

cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan route:list | grep saas

Expected:

GET|HEAD api/v1/saas/me
GET|HEAD api/v1/saas/plans

Restart Docker:

cd /u01/nix-life-os

docker restart nixlifeos-backend nixlifeos-backend-nginx

Test:

curl http://127.0.0.1:8000/api/v1/saas/plans \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

And:

curl http://127.0.0.1:8000/api/v1/saas/me \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
36. Step 27 Completion Criteria

Step 27 is complete when:

✅ plans table exists
✅ subscriptions table exists
✅ subscription_usage table exists
✅ Free, Pro, Enterprise plans seeded
✅ UUID foreign keys fixed
✅ SubscriptionService exists
✅ SaaSController exists
✅ SaaS routes registered
✅ /api/v1/saas/plans works
✅ /api/v1/saas/me works
✅ User has active subscription
✅ User has usage tracking record
✅ Docker backend restarted
✅ Frontend SaaS pages added
✅ Sidebar SaaS menu added
37. Current Status in Your Project

Based on your latest terminal output:

✅ Routes registered
✅ /api/v1/saas/plans working
✅ /api/v1/saas/me working
✅ Free plan returned
✅ Pro plan returned
✅ Enterprise plan returned
✅ User Nix returned
✅ Active subscription returned
✅ Usage record returned

So the backend side of Step 27 is successfully completed.

Remaining frontend work:

SaaSPlansView.vue
SaaSSubscriptionView.vue
router/index.js update
App.vue sidebar update
38. Recommended Next Step

After finishing frontend pages, move to:

🔹 STEP 28 — Production Billing & Payment Integration

Step 28 should include:

Stripe or manual billing
Payment webhooks
Subscription upgrade/downgrade
Invoice history
Trial logic
Failed payment handling
Grace period
Billing dashboard
Admin SaaS dashboard
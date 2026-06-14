<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Models\User as NixUser;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Http\Controllers\Api\V1\TaskController;
use App\Http\Controllers\Api\V1\ProjectController;
use App\Http\Controllers\Api\V1\ProjectDashboardController;
use App\Http\Controllers\Api\V1\ProjectTaskController;
use App\Http\Controllers\Api\V1\ProjectTaskStepController;
use App\Http\Controllers\Api\V1\ProjectGoalController;
use App\Http\Controllers\Api\V1\ProjectMilestoneController;
use App\Http\Controllers\Api\V1\ProjectStatusUpdateController;
use App\Http\Controllers\Api\V1\ProjectProgressController;
use App\Http\Controllers\Api\V1\ProductivityDashboardController;
use App\Http\Controllers\Api\V1\ProductivityCalendarEventController;
use App\Http\Controllers\Api\V1\ProductivityHabitController;
use App\Http\Controllers\Api\V1\ProductivityGoalController;
use App\Http\Controllers\Api\V1\ProductivityHappyWinController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\V1\AIRecommendationController;
use App\Http\Controllers\Api\V1\NotificationController as LegacyNotificationController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\LifeBalanceAiRecommendationController;
use App\Http\Controllers\Api\LifeBalanceController;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\V1\PushSubscriptionController as LegacyPushSubscriptionController;
use App\Http\Controllers\Api\V1\Notifications\NotificationController as PushNotificationController;
use App\Http\Controllers\Api\V1\Notifications\PushSubscriptionController as NotificationPushSubscriptionController;
use App\Http\Controllers\Api\V1\Notifications\NotificationPreferenceController as PushNotificationPreferenceController;
use App\Http\Controllers\Api\V1\Notifications\NotificationTestController as PushNotificationTestController;
use App\Http\Controllers\Api\FinanceTransactionController;
use App\Http\Controllers\Api\HealthNutritionLogController;
use App\Http\Controllers\Api\V1\HealthAlertController;
use App\Http\Controllers\Api\V1\HealthReportController;
use App\Http\Controllers\Api\V1\NutritionFoodController;
use App\Http\Controllers\Api\V1\NutritionCustomFoodController;
use App\Http\Controllers\Api\V1\ProductivityAIInsightController;
use App\Http\Controllers\Api\V1\Dashboard\DashboardController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;
use App\Http\Controllers\Api\V1\Finance\FinanceAIInsightController;
use App\Http\Controllers\Api\V1\Finance\BudgetAlertRuleController;
use App\Http\Controllers\Api\V1\Health\HydrationReminderController;
use App\Http\Controllers\Api\V1\Productivity\TaskReminderController;
use App\Http\Controllers\Api\V1\HealthDashboardController;
use App\Http\Controllers\Api\V1\HealthGoalController;
// use App\Http\Controllers\Api\V1\FinanceCategoryController;
// use App\Http\Controllers\Api\V1\Health\HealthDashboardController;
use App\Http\Controllers\Api\V1\Health\HealthAIInsightController;
use App\Http\Controllers\Api\V1\Health\HealthLabTestController;
use App\Http\Controllers\Api\V1\Health\MedicationController;
use App\Http\Controllers\Api\V1\Health\MedicationReminderController;
use App\Http\Controllers\Api\V1\Health\MedicationDoseController;
use App\Http\Controllers\Api\V1\Health\SleepLogController;
use App\Http\Controllers\Api\V1\Health\HealthStepLogController;
use App\Http\Controllers\Api\V1\Health\HealthMoodLogController;
use App\Http\Controllers\Api\V1\HealthWeightLogController;
use App\Http\Controllers\Api\V1\HealthHydrationLogController;
use App\Http\Controllers\Api\V1\FinanceCategoryController;
use App\Http\Controllers\Api\V1\HealthWeightController;
use App\Http\Controllers\Api\V1\HealthWaterController;
use App\Http\Controllers\Api\V1\HealthSleepController;
use App\Http\Controllers\Api\V1\HealthMoodController;
use App\Http\Controllers\Api\V1\HealthMedicationController;
use App\Http\Controllers\Api\V1\HealthLabTestController as Phase9HealthLabTestController;
// use App\Http\Controllers\Api\V1\FinanceCategoryController;
// // use App\Http\Controllers\Api\V1\HealthWeightController;
// use App\Http\Controllers\Api\V1\HealthWaterController;
// use App\Http\Controllers\Api\V1\HealthSleepController;
// use App\Http\Controllers\Api\V1\HealthMoodController;
// use App\Http\Controllers\Api\V1\HealthMedicationController;
// use App\Http\Controllers\Api\V1\ProjectTaskController;
// use App\Http\Controllers\Api\V1\ProjectTaskController;

// Phase 6 - Health Hydration explicit routes
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/health/hydration/summary', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'summary']);
    Route::get('/health/hydration/charts', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'charts']);
    Route::get('/health/hydration', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'index']);
    Route::post('/health/hydration', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'store']);
    Route::put('/health/hydration/{id}', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'update']);
    Route::delete('/health/hydration/{id}', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'destroy']);
});

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Profile Level & Points
    |--------------------------------------------------------------------------
    */
    Route::get('/profile', [\App\Http\Controllers\Api\V1\ProfileController::class, 'show']);
    Route::put('/profile', [\App\Http\Controllers\Api\V1\ProfileController::class, 'update']);
    Route::get('/profile/points', [\App\Http\Controllers\Api\V1\ProfileController::class, 'points']);
    Route::get('/profile/point-logs', [\App\Http\Controllers\Api\V1\ProfileController::class, 'pointLogs']);

    /*
    |--------------------------------------------------------------------------
    | Application Visit Tracking / Online Users
    |--------------------------------------------------------------------------
    */
    Route::post('/track-visit', function (Request $request) {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'last_seen_at')) {
            DB::table('users')
                ->where('id', $request->user()->id)
                ->update(['last_seen_at' => now()]);
        }

        if (Schema::hasTable('application_visits')) {
            DB::table('application_visits')->insert([
                'user_id' => $request->user()->id,
                'ip_address' => $request->ip(),
                'user_agent' => (string) $request->userAgent(),
                'page_url' => $request->input('page_url'),
                'page_name' => $request->input('page_name'),
                'referrer' => $request->input('referrer'),
                'visited_at' => now(),
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Visit tracked successfully.',
        ]);
    });

    /*
    |--------------------------------------------------------------------------
    | Finance Categories
    |--------------------------------------------------------------------------
    */
    Route::apiResource('finance/categories', FinanceCategoryController::class);
    // Route::apiResource('finance/categories', FinanceCategoryController::class);
    /*
    |--------------------------------------------------------------------------
    | Health Tracking
    |--------------------------------------------------------------------------
    */
    Route::get('health/dashboard-summary', [HealthDashboardController::class, 'summary']);
    Route::apiResource('health/water', HealthWaterController::class);
    Route::apiResource('health/sleep', HealthSleepController::class);
    Route::apiResource('health/mood', HealthMoodController::class);

    /*
    |--------------------------------------------------------------------------
    | Project Tasks
    |--------------------------------------------------------------------------
    */
    Route::apiResource('projects/tasks', ProjectTaskController::class);
    Route::get('projects/{project}/tasks', [ProjectTaskController::class, 'byProject']);
});
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Main API prefix generated by Laravel: /api
| Version prefix in this file: /v1
| Final API prefix: /api/v1
|
*/

/*
|--------------------------------------------------------------------------
| Public API Health Check
|--------------------------------------------------------------------------
*/

Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'Nix Life OS API is running.',
        'timestamp' => now()->toISOString(),
    ]);
});

Route::get('/v1/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'Nix Life OS API v1 is running.',
        'timestamp' => now()->toISOString(),
    ]);
});

/*
|--------------------------------------------------------------------------
| API Version 1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {
    /*
    |--------------------------------------------------------------------------
    | Admin Management Routes
    |--------------------------------------------------------------------------
    |
    | Final prefix: /api/v1/admin
    | Routes are loaded from: routes/api/admin.php
    |
    */

    require __DIR__.'/api/admin.php';

    /*
    |--------------------------------------------------------------------------
    | Public Route Loading Test
    |--------------------------------------------------------------------------
    */

    Route::get('/sleep-route-test', function () {
        return response()->json([
            'success' => true,
            'message' => 'API v1 route file is loading correctly.',
        ]);
    });

    /*
    |--------------------------------------------------------------------------
    | Public Auth Routes
    |--------------------------------------------------------------------------
    */

    Route::prefix('auth')->group(function () {
        Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:20,1');
        Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
        Route::post('/push/subscriptions', [LegacyPushSubscriptionController::class, 'store']);

        Route::middleware(['auth:sanctum', 'api.performance'])->group(function () {
            Route::get('/me', [AuthController::class, 'me']);
            Route::post('/logout', [AuthController::class, 'logout']);
        });
    });

    /*
    |--------------------------------------------------------------------------
    | Public Auth Compatibility Aliases
    |--------------------------------------------------------------------------
    |
    | These aliases keep old frontend builds working if they call /api/v1/login
    | or /api/v1/register directly instead of /api/v1/auth/login/register.
    |
    */

    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:20,1');
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');

    /*
    |--------------------------------------------------------------------------
    | Protected Routes
    |--------------------------------------------------------------------------
    */

    Route::middleware(['auth:sanctum', \App\Http\Middleware\ApiPerformanceLogger::class])->group(function () {
        /*
        |--------------------------------------------------------------------------
        | Tasks Module
        |--------------------------------------------------------------------------
        */

        Route::get('/productivity/ai-insights', [ProductivityAIInsightController::class, 'index']);

        Route::prefix('tasks')->group(function () {
            Route::get('/', [TaskController::class, 'index']);
            Route::post('/', [TaskController::class, 'store']);

            Route::match(['GET', 'PUT', 'PATCH', 'DELETE'], '/{task}', function () {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested resource was not found.',
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'status' => 404,
                    ],
                ], 404);
            })->where('task', '[^0-9]+');

            Route::match(['PATCH'], '/{task}/complete', function () {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested resource was not found.',
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'status' => 404,
                    ],
                ], 404);
            })->where('task', '[^0-9]+');

            Route::match(['PATCH'], '/{task}/reopen', function () {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested resource was not found.',
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'status' => 404,
                    ],
                ], 404);
            })->where('task', '[^0-9]+');

            Route::get('/{task}', [TaskController::class, 'show'])->whereNumber('task');
            Route::put('/{task}', [TaskController::class, 'update'])->whereNumber('task');
            Route::patch('/{task}', [TaskController::class, 'update'])->whereNumber('task');
            Route::delete('/{task}', [TaskController::class, 'destroy'])->whereNumber('task');

            Route::patch('/{task}/complete', [TaskController::class, 'complete'])->whereNumber('task');
            Route::patch('/{task}/reopen', [TaskController::class, 'reopen'])->whereNumber('task');
        });

        /*
        |--------------------------------------------------------------------------
        | Projects Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('projects')->group(function () {
            Route::get('/dashboard', [ProjectDashboardController::class, 'summary']);

            Route::get('/', [ProjectController::class, 'index']);
            Route::post('/', [ProjectController::class, 'store']);
            Route::get('/{project}', [ProjectController::class, 'show']);
            Route::put('/{project}', [ProjectController::class, 'update']);
            Route::patch('/{project}', [ProjectController::class, 'update']);
            Route::delete('/{project}', [ProjectController::class, 'destroy']);

            Route::get('/{project}/progress', [ProjectProgressController::class, 'show']);
            Route::post('/{project}/progress/recalculate', [ProjectProgressController::class, 'recalculate']);
            Route::get('/{project}/goals', [ProjectGoalController::class, 'index']);
            Route::post('/{project}/goals', [ProjectGoalController::class, 'store']);
            Route::put('/{project}/goals/{goal}', [ProjectGoalController::class, 'update']);
            Route::patch('/{project}/goals/{goal}', [ProjectGoalController::class, 'update']);
            Route::delete('/{project}/goals/{goal}', [ProjectGoalController::class, 'destroy']);

            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);

            Route::get('/{project}/tasks/{task}/steps', [ProjectTaskStepController::class, 'index']);
            Route::post('/{project}/tasks/{task}/steps', [ProjectTaskStepController::class, 'store']);
            Route::put('/{project}/tasks/{task}/steps/{step}', [ProjectTaskStepController::class, 'update']);
            Route::patch('/{project}/tasks/{task}/steps/{step}', [ProjectTaskStepController::class, 'update']);
            Route::delete('/{project}/tasks/{task}/steps/{step}', [ProjectTaskStepController::class, 'destroy']);


            Route::patch('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);
            Route::put('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);

            Route::get('/{project}/tasks/{task}', [ProjectTaskController::class, 'show']);
            Route::put('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::patch('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::delete('/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);

            Route::get('/{project}/milestones', [ProjectMilestoneController::class, 'index']);
            Route::post('/{project}/milestones', [ProjectMilestoneController::class, 'store']);
            Route::put('/{project}/milestones/{milestone}', [ProjectMilestoneController::class, 'update']);
            Route::patch('/{project}/milestones/{milestone}', [ProjectMilestoneController::class, 'update']);
            Route::delete('/{project}/milestones/{milestone}', [ProjectMilestoneController::class, 'destroy']);

            Route::get('/{project}/status-updates', [ProjectStatusUpdateController::class, 'index']);
            Route::post('/{project}/status-updates', [ProjectStatusUpdateController::class, 'store']);
        });

        /*
        |--------------------------------------------------------------------------
        | Authenticated User
        |--------------------------------------------------------------------------
        */

        Route::get('/user', function (Request $request) {
            return response()->json([
                'success' => true,
                'message' => 'Authenticated user loaded successfully.',
                'data' => $request->user(),
            ]);
        });

        /*
        |--------------------------------------------------------------------------
        | Dashboard
        |--------------------------------------------------------------------------
        */

        Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

        /*
        |--------------------------------------------------------------------------
        | AI Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('ai')->group(function () {
            Route::get('/recommendations', [AIRecommendationController::class, 'index']);
            Route::post('/recommendations/generate', [AIRecommendationController::class, 'generate']);

            Route::patch('/recommendations/{recommendation}/viewed', [AIRecommendationController::class, 'markViewed']);
            Route::patch('/recommendations/{recommendation}/accept', [AIRecommendationController::class, 'accept']);
            Route::patch('/recommendations/{recommendation}/dismiss', [AIRecommendationController::class, 'dismiss']);
            Route::patch('/recommendations/{recommendation}/complete', [AIRecommendationController::class, 'complete']);

            Route::post('/recommendations/{recommendation}/feedback', [AIRecommendationController::class, 'feedback']);

            Route::get('/scores/daily', [AIRecommendationController::class, 'dailyScores']);
        });

        /*
        |--------------------------------------------------------------------------
        | Productivity Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('productivity')->group(function () {
            Route::get('/calendar/events', [ProductivityCalendarEventController::class, 'index']);
            Route::post('/calendar/events', [ProductivityCalendarEventController::class, 'store']);
            Route::get('/calendar/events/{event}', [ProductivityCalendarEventController::class, 'show']);
            Route::put('/calendar/events/{event}', [ProductivityCalendarEventController::class, 'update']);
            Route::delete('/calendar/events/{event}', [ProductivityCalendarEventController::class, 'destroy']);

            Route::get('/dashboard', [ProductivityDashboardController::class, 'summary']);

            Route::get('/happy-wins', [ProductivityHappyWinController::class, 'index']);
            Route::post('/happy-wins', [ProductivityHappyWinController::class, 'store']);
            Route::get('/happy-wins/{happyWin}', [ProductivityHappyWinController::class, 'show']);
            Route::put('/happy-wins/{happyWin}', [ProductivityHappyWinController::class, 'update']);
            Route::patch('/happy-wins/{happyWin}', [ProductivityHappyWinController::class, 'update']);
            Route::delete('/happy-wins/{happyWin}', [ProductivityHappyWinController::class, 'destroy']);

            Route::apiResource('task-reminders', TaskReminderController::class);

            Route::get('/tasks', [TaskController::class, 'index']);
            Route::post('/tasks', [TaskController::class, 'store']);

            Route::match(['GET', 'PUT', 'PATCH', 'DELETE'], '/tasks/{task}', function () {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested resource was not found.',
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'status' => 404,
                    ],
                ], 404);
            })->where('task', '[^0-9]+');

            Route::match(['PATCH'], '/tasks/{task}/complete', function () {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested resource was not found.',
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'status' => 404,
                    ],
                ], 404);
            })->where('task', '[^0-9]+');

            Route::match(['PATCH'], '/tasks/{task}/reopen', function () {
                return response()->json([
                    'success' => false,
                    'message' => 'The requested resource was not found.',
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'status' => 404,
                    ],
                ], 404);
            })->where('task', '[^0-9]+');

            Route::get('/tasks/{task}', [TaskController::class, 'show'])->whereNumber('task');
            Route::put('/tasks/{task}', [TaskController::class, 'update'])->whereNumber('task');
            Route::patch('/tasks/{task}', [TaskController::class, 'update'])->whereNumber('task');
            Route::delete('/tasks/{task}', [TaskController::class, 'destroy'])->whereNumber('task');
            Route::patch('/tasks/{task}/complete', [TaskController::class, 'complete'])->whereNumber('task');
            Route::patch('/tasks/{task}/reopen', [TaskController::class, 'reopen'])->whereNumber('task');

            Route::get('/calendar', [ProductivityCalendarEventController::class, 'index']);

            Route::get('/goals', [ProductivityGoalController::class, 'index']);
            Route::post('/goals', [ProductivityGoalController::class, 'store']);
            Route::get('/goals/{goal}', [ProductivityGoalController::class, 'show']);
            Route::put('/goals/{goal}', [ProductivityGoalController::class, 'update']);
            Route::patch('/goals/{goal}', [ProductivityGoalController::class, 'update']);
            Route::delete('/goals/{goal}', [ProductivityGoalController::class, 'destroy']);

            Route::patch('/goals/{goal}/progress', [ProductivityGoalController::class, 'updateProgress']);
            Route::patch('/goals/{goal}/complete', [ProductivityGoalController::class, 'complete']);
            Route::patch('/goals/{goal}/reopen', [ProductivityGoalController::class, 'reopen']);
            Route::post('/goals/{goal}/recalculate-progress', [ProductivityGoalController::class, 'recalculateProgress']);

            Route::post('/goals/{goal}/tasks', [ProductivityGoalController::class, 'linkTask']);
            Route::delete('/goals/{goal}/tasks/{taskId}', [ProductivityGoalController::class, 'unlinkTask']);

            Route::post('/goals/{goal}/habits', [ProductivityGoalController::class, 'linkHabit']);
            Route::delete('/goals/{goal}/habits/{habitId}', [ProductivityGoalController::class, 'unlinkHabit']);

            Route::get('/habits', [ProductivityHabitController::class, 'index']);
            Route::post('/habits', [ProductivityHabitController::class, 'store']);
            Route::get('/habits/summary/weekly', [ProductivityHabitController::class, 'weeklySummary']);
            Route::get('/habits/{habit}', [ProductivityHabitController::class, 'show']);
            Route::put('/habits/{habit}', [ProductivityHabitController::class, 'update']);
            Route::patch('/habits/{habit}', [ProductivityHabitController::class, 'update']);
            Route::delete('/habits/{habit}', [ProductivityHabitController::class, 'destroy']);
            Route::post('/habits/{habit}/check-in', [ProductivityHabitController::class, 'checkIn']);
        });

        /*
        |--------------------------------------------------------------------------
        | Life Balance
        |--------------------------------------------------------------------------
        */

        Route::get('/life-balance/summary', [LifeBalanceController::class, 'summary']);
        Route::get('/life-balance/ai-recommendations', [LifeBalanceAiRecommendationController::class, 'index']);
        Route::get('/life-balance/recommendations', [LifeBalanceAiRecommendationController::class, 'index']);
        Route::get('/ai/life-balance/recommendations', [LifeBalanceAiRecommendationController::class, 'index']);

        /*
        |--------------------------------------------------------------------------
        | Finance Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('finance')->group(function () {
            Route::get('/ai-insights', [FinanceAIInsightController::class, 'index']);

            Route::get('/accounts', [FinanceAccountController::class, 'index']);
            Route::post('/accounts', [FinanceAccountController::class, 'store']);
            Route::get('/accounts/{id}', [FinanceAccountController::class, 'show']);
            Route::put('/accounts/{id}', [FinanceAccountController::class, 'update']);
            Route::patch('/accounts/{id}', [FinanceAccountController::class, 'update']);
            Route::delete('/accounts/{id}', [FinanceAccountController::class, 'destroy']);

            Route::get('/transactions', [FinanceTransactionController::class, 'index']);
            Route::post('/transactions', [FinanceTransactionController::class, 'store']);
            Route::get('/transactions/{id}', [FinanceTransactionController::class, 'show']);
            Route::put('/transactions/{id}', [FinanceTransactionController::class, 'update']);
            Route::patch('/transactions/{id}', [FinanceTransactionController::class, 'update']);
            Route::delete('/transactions/{id}', [FinanceTransactionController::class, 'destroy']);

            Route::get('/budgets', [FinanceBudgetController::class, 'index']);
            Route::post('/budgets', [FinanceBudgetController::class, 'store']);
            Route::get('/budgets/{id}', [FinanceBudgetController::class, 'show']);
            Route::put('/budgets/{id}', [FinanceBudgetController::class, 'update']);
            Route::patch('/budgets/{id}', [FinanceBudgetController::class, 'update']);
            Route::delete('/budgets/{id}', [FinanceBudgetController::class, 'destroy']);

            Route::apiResource('budget-alert-rules', BudgetAlertRuleController::class);
        });

        /*
        |--------------------------------------------------------------------------
        | Nutrition Facts Database Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('nutrition')->group(function () {
            Route::get('/categories', [NutritionFoodController::class, 'categories']);

            Route::get('/foods/search', [NutritionFoodController::class, 'search']);
            Route::get('/foods/{id}/servings', [NutritionFoodController::class, 'servings']);
            Route::get('/foods/{id}', [NutritionFoodController::class, 'show']);
            Route::get('/foods', [NutritionFoodController::class, 'index']);
            Route::post('/foods/autofill', [NutritionFoodController::class, 'autofill']);

            Route::get('/custom-foods', [NutritionCustomFoodController::class, 'index']);
            Route::post('/custom-foods', [NutritionCustomFoodController::class, 'store']);
            Route::get('/custom-foods/{id}', [NutritionCustomFoodController::class, 'show']);
            Route::put('/custom-foods/{id}', [NutritionCustomFoodController::class, 'update']);
            Route::patch('/custom-foods/{id}', [NutritionCustomFoodController::class, 'update']);
            Route::delete('/custom-foods/{id}', [NutritionCustomFoodController::class, 'destroy']);
        });

        /*
        |--------------------------------------------------------------------------
        | Health Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('health')->group(function () {
            Route::get('/reports', [HealthReportController::class, 'daily']);
            Route::get('/reports/preview', [HealthReportController::class, 'exportPreview']);
            Route::get('/reports/daily', [HealthReportController::class, 'daily']);
            Route::get('/reports/weekly', [HealthReportController::class, 'weekly']);
            Route::get('/reports/monthly', [HealthReportController::class, 'monthly']);
            Route::get('/reports/export-preview', [HealthReportController::class, 'exportPreview']);
            Route::get('/reports/pdf', [HealthReportController::class, 'pdf']);

            Route::get('/alerts', [HealthAlertController::class, 'index']);
            Route::get('/alerts/summary', [HealthAlertController::class, 'summary']);
            Route::post('/alerts/run', [HealthAlertController::class, 'run']);

            Route::patch('/alerts/{id}/read', [HealthAlertController::class, 'markAsRead']);
            Route::patch('/alerts/{id}/resolve', [HealthAlertController::class, 'resolve']);
            Route::patch('/alerts/{id}/dismiss', [HealthAlertController::class, 'dismiss']);
            Route::delete('/alerts/{id}', [HealthAlertController::class, 'destroy']);

            Route::get('/dashboard', [HealthDashboardController::class, 'summary']);
            Route::get('/goals', [HealthGoalController::class, 'show']);
            Route::put('/goals', [HealthGoalController::class, 'update']);
            Route::patch('/goals', [HealthGoalController::class, 'update']);

            Route::get('/ai-insights', [HealthAIInsightController::class, 'index']);

            Route::get('/medications', [MedicationController::class, 'index']);
            Route::post('/medications', [MedicationController::class, 'store']);
            Route::get('/medications/today', [MedicationController::class, 'today']);
            Route::get('/medications/{id}', [MedicationController::class, 'show']);
            Route::put('/medications/{id}', [MedicationController::class, 'update']);
            Route::patch('/medications/{id}', [MedicationController::class, 'update']);
            Route::delete('/medications/{id}', [MedicationController::class, 'destroy']);

            Route::get('/medication-reminders', [MedicationReminderController::class, 'index']);
            Route::get('/medication-reminders/today', [MedicationReminderController::class, 'today']);
            Route::post('/medication-reminders', [MedicationReminderController::class, 'store']);
            Route::put('/medication-reminders/{id}', [MedicationReminderController::class, 'update']);
            Route::patch('/medication-reminders/{id}', [MedicationReminderController::class, 'update']);
            Route::delete('/medication-reminders/{id}', [MedicationReminderController::class, 'destroy']);

            Route::apiResource('hydration-reminders', HydrationReminderController::class);

            Route::get('/medication-doses/history', [MedicationDoseController::class, 'history']);
            Route::post('/medication-doses/{id}/taken', [MedicationDoseController::class, 'markTaken']);
            Route::post('/medication-doses/{id}/skipped', [MedicationDoseController::class, 'markSkipped']);

            Route::get('/lab-tests/categories', [HealthLabTestController::class, 'categories']);
            Route::get('/lab-tests/trends', [HealthLabTestController::class, 'trends']);
            Route::get('/lab-tests', [HealthLabTestController::class, 'index']);
            Route::post('/lab-tests', [HealthLabTestController::class, 'store']);
            Route::get('/lab-tests/{id}', [HealthLabTestController::class, 'show']);
            Route::put('/lab-tests/{id}', [HealthLabTestController::class, 'update']);
            Route::patch('/lab-tests/{id}', [HealthLabTestController::class, 'update']);
            Route::delete('/lab-tests/{id}', [HealthLabTestController::class, 'destroy']);

            Route::get('/mood', [HealthMoodLogController::class, 'index']);
            Route::post('/mood', [HealthMoodLogController::class, 'store']);
            Route::get('/mood/{id}', [HealthMoodLogController::class, 'show']);
            Route::put('/mood/{id}', [HealthMoodLogController::class, 'update']);
            Route::patch('/mood/{id}', [HealthMoodLogController::class, 'update']);
            Route::delete('/mood/{id}', [HealthMoodLogController::class, 'destroy']);

            Route::get('/sleep', [SleepLogController::class, 'index']);
            Route::post('/sleep', [SleepLogController::class, 'store']);
            Route::get('/sleep/{id}', [SleepLogController::class, 'show']);
            Route::put('/sleep/{id}', [SleepLogController::class, 'update']);
            Route::patch('/sleep/{id}', [SleepLogController::class, 'update']);
            Route::delete('/sleep/{id}', [SleepLogController::class, 'destroy']);

            Route::get('/sleep-test', function () {
                return response()->json([
                    'success' => true,
                    'message' => 'Sleep test route works.',
                ]);
            });

            Route::get('/steps', [HealthStepLogController::class, 'index']);
            Route::post('/steps', [HealthStepLogController::class, 'store']);
            Route::get('/steps/summary', [HealthStepLogController::class, 'summary']);
            Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);
            Route::put('/steps/{id}', [HealthStepLogController::class, 'update']);
            Route::patch('/steps/{id}', [HealthStepLogController::class, 'update']);
            Route::delete('/steps/{id}', [HealthStepLogController::class, 'destroy']);

            Route::get('/weight', [HealthWeightLogController::class, 'index']);
            Route::post('/weight', [HealthWeightLogController::class, 'store']);
            Route::get('/weight/summary', [HealthWeightLogController::class, 'summary']);
            Route::get('/weight/{id}', [HealthWeightLogController::class, 'show'])->whereNumber('id');
            Route::put('/weight/{id}', [HealthWeightLogController::class, 'update'])->whereNumber('id');
            Route::patch('/weight/{id}', [HealthWeightLogController::class, 'update'])->whereNumber('id');
            Route::delete('/weight/{id}', [HealthWeightLogController::class, 'destroy'])->whereNumber('id');

            Route::get('/nutrition/profile', [\App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController::class, 'index']);
            Route::post('/nutrition/profile', [\App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController::class, 'store']);

            Route::get('/nutrition/foods', [\App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class, 'index']);
            Route::post('/nutrition/foods', [\App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class, 'store']);
            Route::get('/food-items', [\App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class, 'index']);
            Route::post('/food-items', [\App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class, 'store']);
            Route::get('/foods', [\App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class, 'index']);

            Route::get('/nutrition/summary', [HealthNutritionLogController::class, 'summary']);
            Route::get('/nutrition', [HealthNutritionLogController::class, 'index']);
            Route::post('/nutrition', [HealthNutritionLogController::class, 'store']);
            Route::get('/nutrition/{id}', [HealthNutritionLogController::class, 'show']);
            Route::put('/nutrition/{id}', [HealthNutritionLogController::class, 'update']);
            Route::patch('/nutrition/{id}', [HealthNutritionLogController::class, 'update']);
            Route::delete('/nutrition/{id}', [HealthNutritionLogController::class, 'destroy']);
// Phase 6 disabled old duplicate nested hydration route: 
// Phase 6 disabled old duplicate nested hydration route: Route::get('/hydration', [HealthHydrationLogController::class, 'index']);
// Phase 6 disabled old duplicate nested hydration route: // Phase 6 disabled old duplicate nested hydration route: Route::post('/hydration', [HealthHydrationLogController::class, 'store']);
            // Phase 6 explicit hydration analytics routes - must stay before any /hydration/{id} route
            Route::get('/hydration/summary', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'summary']);
            Route::get('/hydration/charts', [\App\Http\Controllers\Api\V1\HealthHydrationController::class, 'charts']);
            Route::get('/hydration/summary/daily', [HealthHydrationLogController::class, 'dailySummary']);
            Route::get('/hydration/summary/weekly', [HealthHydrationLogController::class, 'weeklySummary']);
            Route::post('/hydration/quick-add', [HealthHydrationLogController::class, 'quickAdd']);
// Phase 6 disabled old duplicate nested hydration route: // Phase 6 disabled old duplicate nested hydration route: Route::get('/hydration/{id}', [HealthHydrationLogController::class, 'show']);
// Phase 6 disabled old duplicate nested hydration route: // Phase 6 disabled old duplicate nested hydration route: Route::put('/hydration/{id}', [HealthHydrationLogController::class, 'update']);
// Phase 6 disabled old duplicate nested hydration route: // Phase 6 disabled old duplicate nested hydration route: Route::patch('/hydration/{id}', [HealthHydrationLogController::class, 'update']);
// Phase 6 disabled old duplicate nested hydration route: // Phase 6 disabled old duplicate nested hydration route: Route::delete('/hydration/{id}', [HealthHydrationLogController::class, 'destroy']);
        });

        /*
        |--------------------------------------------------------------------------
        | Notifications Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('notifications')->middleware('role:user|admin')->group(function () {
            Route::get('/', [PushNotificationController::class, 'index']);
            Route::patch('/read-all', [PushNotificationController::class, 'markAllAsRead']);

            Route::get('/unread-count', [LegacyNotificationController::class, 'unreadCount']);

            Route::get('/preferences', [PushNotificationPreferenceController::class, 'index']);
            Route::put('/preferences', [PushNotificationPreferenceController::class, 'update']);
            Route::patch('/preferences', [PushNotificationPreferenceController::class, 'update']);

            Route::post('/push-subscriptions', [NotificationPushSubscriptionController::class, 'store']);
            Route::delete('/push-subscriptions', [NotificationPushSubscriptionController::class, 'destroy']);

            Route::post('/test', [PushNotificationTestController::class, 'sendTest']);

            Route::get('/{notification}', [PushNotificationController::class, 'show']);
            Route::patch('/{notification}/read', [PushNotificationController::class, 'markAsRead']);
            Route::delete('/{notification}', [PushNotificationController::class, 'destroy']);
        });

        /*
        |--------------------------------------------------------------------------
        | Legacy Notification Settings Alias
        |--------------------------------------------------------------------------
        */

        Route::prefix('notification-settings')->middleware('role:user|admin')->group(function () {
            Route::get('/', function (Request $request) {
                if (! Schema::hasTable('notification_preferences')) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Notification preferences table is not available yet.',
                        'data' => null,
                    ]);
                }

                $preferences = DB::table('notification_preferences')
                    ->where('user_id', $request->user()->id)
                    ->first();

                return response()->json([
                    'success' => true,
                    'data' => $preferences,
                ]);
            });
        });

        /*
        |--------------------------------------------------------------------------
        | Reports Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('reports')->middleware('role:user|admin')->group(function () {
            Route::get('/', [ReportController::class, 'index']);
            Route::get('/finance', [ReportController::class, 'finance']);
            Route::get('/health', [ReportController::class, 'health']);
            Route::get('/productivity', [ReportController::class, 'productivity']);
        });

        /*
        |--------------------------------------------------------------------------
        | Automation Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('automation')->middleware('role:user|admin')->group(function () {
            Route::get('/', function (Request $request) {
                if (! Schema::hasTable('automation_rules')) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Automation rules table is not available yet.',
                        'data' => [],
                    ]);
                }

                $rules = DB::table('automation_rules')
                    ->where('user_id', $request->user()->id)
                    ->orderByDesc('created_at')
                    ->limit(50)
                    ->get();

                return response()->json([
                    'success' => true,
                    'data' => $rules,
                ]);
            });

            Route::get('/logs', function (Request $request) {
                if (! Schema::hasTable('automation_trigger_logs')) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Automation logs table is not available yet.',
                        'data' => [],
                    ]);
                }

                $logs = DB::table('automation_trigger_logs')
                    ->where('user_id', $request->user()->id)
                    ->orderByDesc('created_at')
                    ->limit(50)
                    ->get();

                return response()->json([
                    'success' => true,
                    'data' => $logs,
                ]);
            });
        });

        /*
        |--------------------------------------------------------------------------
        | Admin Area Root Check
        |--------------------------------------------------------------------------
        |
        | Important:
        | /api/v1/admin/users, /api/v1/admin/dashboard/summary, and other admin
        | management routes are handled in routes/api/admin.php.
        |
        */

        Route::prefix('admin')->middleware('role:admin')->group(function () {
            Route::get('/', function () {
                return response()->json([
                    'success' => true,
                    'message' => 'Admin area access granted.',
                    'data' => [
                        'users_count' => NixUser::count(),
                        'roles_count' => Role::count(),
                        'permissions_count' => Permission::count(),
                    ],
                ]);
            });
        });

        /*
        |--------------------------------------------------------------------------
        | Security Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('security')->middleware('role:admin')->group(function () {
            Route::get('/', function () {
                return response()->json([
                    'success' => true,
                    'message' => 'Security area access granted.',
                ]);
            });

            Route::get('/roles', function () {
                return response()->json([
                    'success' => true,
                    'data' => Role::with('permissions:id,name')->orderBy('name')->get(),
                ]);
            });

            Route::get('/permissions', function () {
                return response()->json([
                    'success' => true,
                    'data' => Permission::orderBy('name')->get(['id', 'name', 'guard_name']),
                ]);
            });

            Route::get('/audit-logs', function () {
                if (! Schema::hasTable('audit_logs')) {
                    return response()->json([
                        'success' => true,
                        'data' => [],
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'data' => DB::table('audit_logs')->orderByDesc('created_at')->limit(100)->get(),
                ]);
            });

            Route::get('/login-history', function () {
                return response()->json([
                    'success' => true,
                    'message' => 'Login history endpoint is protected. Add a login-history table later if required.',
                    'data' => [],
                ]);
            });
        });

        /*
        |--------------------------------------------------------------------------
        | User Management Legacy Aliases
        |--------------------------------------------------------------------------
        */

        Route::prefix('user-management')->middleware('role:admin')->group(function () {
            Route::get('/users', function () {
                return response()->json([
                    'success' => true,
                    'data' => NixUser::query()
                        ->select(['id', 'name', 'email', 'created_at'])
                        ->latest()
                        ->limit(100)
                        ->get(),
                ]);
            });

            Route::get('/roles', function () {
                return response()->json([
                    'success' => true,
                    'data' => Role::with('permissions:id,name')->orderBy('name')->get(),
                ]);
            });
        });

        /*
        |--------------------------------------------------------------------------
        | Monitoring Module
        |--------------------------------------------------------------------------
        |
        | Temporarily disabled because MonitoringController may not exist.
        |
        */

        /*
        Route::prefix('monitoring')->group(function () {
            Route::get('/summary', [MonitoringController::class, 'summary']);
            Route::get('/logs', [MonitoringController::class, 'logs']);
            Route::get('/errors', [MonitoringController::class, 'errors']);
            Route::get('/audit-logs', [MonitoringController::class, 'auditLogs']);
        });
        */
    });
});


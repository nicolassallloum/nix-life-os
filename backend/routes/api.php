<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Controller Resolvers
|--------------------------------------------------------------------------
| This api.php is safe: it only registers optional module routes when the
| controller class exists, so route:list will not crash if a module is missing.
|--------------------------------------------------------------------------
*/

/*
|--------------------------------------------------------------------------
| Required Controllers
|--------------------------------------------------------------------------
*/
$authController = \App\Http\Controllers\Api\AuthController::class;

$financeAccountController = \App\Http\Controllers\Api\FinanceAccountController::class;
$financeTransactionController = \App\Http\Controllers\Api\FinanceTransactionController::class;

/*
|--------------------------------------------------------------------------
| Finance Budget Controller
|--------------------------------------------------------------------------
*/
$financeBudgetController = class_exists(\App\Http\Controllers\Api\V1\Finance\FinanceBudgetController::class)
    ? \App\Http\Controllers\Api\V1\Finance\FinanceBudgetController::class
    : (
        class_exists(\App\Http\Controllers\Api\FinanceBudgetController::class)
            ? \App\Http\Controllers\Api\FinanceBudgetController::class
            : null
    );

/*
|--------------------------------------------------------------------------
| Health Controllers
|--------------------------------------------------------------------------
| Real controllers found in your project:
| Weight      App\Http\Controllers\Api\V1\HealthWeightLogController
| Hydration   App\Http\Controllers\Api\V1\HealthHydrationLogController
| Steps       App\Http\Controllers\Api\V1\Health\HealthStepLogController
| Meals       App\Http\Controllers\Api\V1\Health\HealthMealLogController
| Food Items  App\Http\Controllers\Api\V1\Health\HealthFoodItemController
|--------------------------------------------------------------------------
*/
$healthStepController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthStepLogController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthStepLogController::class
    : null;

$healthWeightController = class_exists(\App\Http\Controllers\Api\V1\HealthWeightLogController::class)
    ? \App\Http\Controllers\Api\V1\HealthWeightLogController::class
    : null;

$healthMealController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthMealLogController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthMealLogController::class
    : null;

$healthFoodItemController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthFoodItemController::class
    : null;

$healthHydrationController = class_exists(\App\Http\Controllers\Api\V1\HealthHydrationLogController::class)
    ? \App\Http\Controllers\Api\V1\HealthHydrationLogController::class
    : null;

/*
|--------------------------------------------------------------------------
| Optional Health Extra Controllers
|--------------------------------------------------------------------------
*/
$healthProfileController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthProfileController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthProfileController::class
    : null;

$healthAnalyticsController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthAnalyticsController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthAnalyticsController::class
    : null;

$healthNutritionProfileController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController::class
    : null;

$healthNutritionSummaryController = class_exists(\App\Http\Controllers\Api\V1\Health\HealthNutritionSummaryController::class)
    ? \App\Http\Controllers\Api\V1\Health\HealthNutritionSummaryController::class
    : null;

/*
|--------------------------------------------------------------------------
| Project Controllers
|--------------------------------------------------------------------------
| Real project paths:
| - App\Http\Controllers\Api\V1\ProjectController
| - App\Http\Controllers\Api\V1\ProjectTaskController
| - App\Http\Controllers\Api\V1\ProjectMilestoneController
| - App\Http\Controllers\Api\V1\ProjectProgressController
| - App\Http\Controllers\Api\V1\ProjectStatusUpdateController
|--------------------------------------------------------------------------
*/

$projectController = class_exists(\App\Http\Controllers\Api\V1\ProjectController::class)
    ? \App\Http\Controllers\Api\V1\ProjectController::class
    : null;

$projectTaskController = class_exists(\App\Http\Controllers\Api\V1\ProjectTaskController::class)
    ? \App\Http\Controllers\Api\V1\ProjectTaskController::class
    : null;

$projectMilestoneController = class_exists(\App\Http\Controllers\Api\V1\ProjectMilestoneController::class)
    ? \App\Http\Controllers\Api\V1\ProjectMilestoneController::class
    : null;

$projectProgressController = class_exists(\App\Http\Controllers\Api\V1\ProjectProgressController::class)
    ? \App\Http\Controllers\Api\V1\ProjectProgressController::class
    : null;

$projectStatusUpdateController = class_exists(\App\Http\Controllers\Api\V1\ProjectStatusUpdateController::class)
    ? \App\Http\Controllers\Api\V1\ProjectStatusUpdateController::class
    : null;$notificationPreferenceController = class_exists(\App\Http\Controllers\Api\NotificationPreferenceController::class)
    ? \App\Http\Controllers\Api\NotificationPreferenceController::class
    : null;
/*
|--------------------------------------------------------------------------
| Notification Controllers
|--------------------------------------------------------------------------
*/
$notificationController = class_exists(\App\Http\Controllers\Api\NotificationController::class)
    ? \App\Http\Controllers\Api\NotificationController::class
    : null;

$notificationPreferenceController = class_exists(\App\Http\Controllers\Api\NotificationPreferenceController::class)
    ? \App\Http\Controllers\Api\NotificationPreferenceController::class
    : null;

/*
|--------------------------------------------------------------------------
| Monitoring Controller
|--------------------------------------------------------------------------
*/
$monitoringController = class_exists(\App\Http\Controllers\Api\MonitoringController::class)
    ? \App\Http\Controllers\Api\MonitoringController::class
    : null;

/*
|--------------------------------------------------------------------------
| API V1 Routes
|--------------------------------------------------------------------------
*/
Route::prefix('v1')->group(function () use (
    $authController,
    $financeAccountController,
    $financeTransactionController,
    $financeBudgetController,
    $healthStepController,
    $healthWeightController,
    $healthMealController,
    $healthFoodItemController,
    $healthHydrationController,
    $healthProfileController,
    $healthAnalyticsController,
    $healthNutritionProfileController,
    $healthNutritionSummaryController,
    $projectController,
    $projectTaskController,
    $projectMilestoneController,
    $projectProgressController,
    $projectStatusUpdateController,
    $notificationController,
    $notificationPreferenceController,
    $monitoringController
) {

    /*
    |--------------------------------------------------------------------------
    | Public Authentication Routes
    |--------------------------------------------------------------------------
    */
    Route::post('/auth/register', [$authController, 'register']);
    Route::post('/auth/login', [$authController, 'login']);

    /*
    |--------------------------------------------------------------------------
    | Protected Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () use (
        $authController,
        $financeAccountController,
        $financeTransactionController,
        $financeBudgetController,
        $healthStepController,
        $healthWeightController,
        $healthMealController,
        $healthFoodItemController,
        $healthHydrationController,
        $healthProfileController,
        $healthAnalyticsController,
        $healthNutritionProfileController,
        $healthNutritionSummaryController,
        $projectController,
        $projectTaskController,
        $projectMilestoneController,
        $projectProgressController,
        $projectStatusUpdateController,
        $notificationController,
        $notificationPreferenceController,
        $monitoringController
    ) {

        /*
        |--------------------------------------------------------------------------
        | Auth
        |--------------------------------------------------------------------------
        */
        Route::get('/auth/me', [$authController, 'me']);
        Route::post('/auth/logout', [$authController, 'logout']);
        /*
        |--------------------------------------------------------------------------
        | Unified Dashboard Fallback Routes
        |--------------------------------------------------------------------------
        */
        Route::get('/dashboard/summary', function (\Illuminate\Http\Request $request) {
            $userId = $request->user()->id;

            $totalBalance = \Illuminate\Support\Facades\DB::table('finance_accounts')
                ->where('user_id', $userId)
                ->sum('current_balance');

            $monthlyExpense = \Illuminate\Support\Facades\DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'expense')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount');

            $income = \Illuminate\Support\Facades\DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'income')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount');

            $todaySteps = 0;
            if (\Illuminate\Support\Facades\Schema::hasTable('health_step_logs')) {
                $todaySteps = \Illuminate\Support\Facades\DB::table('health_step_logs')
                    ->where('user_id', $userId)
                    ->whereDate('log_date', today())
                    ->sum('steps');
            }

            $todayCalories = 0;
            if (\Illuminate\Support\Facades\Schema::hasTable('health_meal_logs')) {
                $todayCalories = \Illuminate\Support\Facades\DB::table('health_meal_logs')
                    ->where('user_id', $userId)
                    ->whereDate('meal_date', today())
                    ->sum('total_calories');
            }

            $waterIntake = 0;
            if (\Illuminate\Support\Facades\Schema::hasTable('health_hydration_logs')) {
                $waterIntake = \Illuminate\Support\Facades\DB::table('health_hydration_logs')
                    ->where('user_id', $userId)
                    ->whereDate('log_date', today())
                    ->sum('amount_ml');
            }

            $currentWeight = 0;
            if (\Illuminate\Support\Facades\Schema::hasTable('health_weight_logs')) {
                $latestWeight = \Illuminate\Support\Facades\DB::table('health_weight_logs')
                    ->where('user_id', $userId)
                    ->orderByDesc('log_date')
                    ->first();

                $currentWeight = $latestWeight?->weight_kg ?? 0;
            }

            $activeProjects = 0;
            $totalProjects = 0;
            if (\Illuminate\Support\Facades\Schema::hasTable('projects')) {
                $activeProjects = \Illuminate\Support\Facades\DB::table('projects')
                    ->where('user_id', $userId)
                    ->whereIn('status', ['active', 'in_progress'])
                    ->count();

                $totalProjects = \Illuminate\Support\Facades\DB::table('projects')
                    ->where('user_id', $userId)
                    ->count();
            }

            $savingsRate = $income > 0
                ? round((($income - $monthlyExpense) / $income) * 100, 2)
                : 0;

            return response()->json([
                'success' => true,
                'message' => 'Dashboard summary loaded successfully.',
                'data' => [
                    'total_balance' => (float) $totalBalance,
                    'income' => (float) $income,
                    'monthly_expense' => (float) $monthlyExpense,
                    'savings_rate' => $savingsRate,
                    'today_steps' => (int) $todaySteps,
                    'today_calories' => (int) $todayCalories,
                    'water_intake_ml' => (int) $waterIntake,
                    'current_weight_kg' => (float) $currentWeight,
                    'active_projects' => (int) $activeProjects,
                    'total_projects' => (int) $totalProjects,
                ],
            ]);
        });

        Route::get('/dashboard/kpis', function (\Illuminate\Http\Request $request) {
            return redirect('/api/v1/dashboard/summary');
        });

        Route::get('/dashboard/recent-activity', function () {
            return response()->json([
                'success' => true,
                'message' => 'Recent activity loaded successfully.',
                'data' => [],
            ]);
        });
        /*
        |--------------------------------------------------------------------------
        | Finance Accounts
        |--------------------------------------------------------------------------
        */
        Route::get('/finance/accounts', [$financeAccountController, 'index']);
        Route::post('/finance/accounts', [$financeAccountController, 'store']);
        Route::get('/finance/accounts/{account}', [$financeAccountController, 'show']);
        Route::put('/finance/accounts/{account}', [$financeAccountController, 'update']);
        Route::patch('/finance/accounts/{account}', [$financeAccountController, 'update']);
        Route::delete('/finance/accounts/{account}', [$financeAccountController, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Finance Transactions
        |--------------------------------------------------------------------------
        */
        Route::get('/finance/transactions', [$financeTransactionController, 'index']);
        Route::post('/finance/transactions', [$financeTransactionController, 'store']);
        Route::get('/finance/transactions/{transaction}', [$financeTransactionController, 'show']);
        Route::put('/finance/transactions/{transaction}', [$financeTransactionController, 'update']);
        Route::patch('/finance/transactions/{transaction}', [$financeTransactionController, 'update']);
        Route::delete('/finance/transactions/{transaction}', [$financeTransactionController, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Finance Budgets
        |--------------------------------------------------------------------------
        */
        if ($financeBudgetController) {
            Route::get('/finance/budgets', [$financeBudgetController, 'index']);
            Route::post('/finance/budgets', [$financeBudgetController, 'store']);
            Route::get('/finance/budgets/{budget}', [$financeBudgetController, 'show']);
            Route::put('/finance/budgets/{budget}', [$financeBudgetController, 'update']);
            Route::patch('/finance/budgets/{budget}', [$financeBudgetController, 'update']);
            Route::delete('/finance/budgets/{budget}', [$financeBudgetController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Profile
        |--------------------------------------------------------------------------
        */
        if ($healthProfileController) {
            Route::get('/health/profile', [$healthProfileController, 'show']);
            Route::post('/health/profile', [$healthProfileController, 'store']);
            Route::put('/health/profile', [$healthProfileController, 'update']);
            Route::patch('/health/profile', [$healthProfileController, 'update']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Steps
        |--------------------------------------------------------------------------
        */
        if ($healthStepController) {
            Route::get('/health/steps', [$healthStepController, 'index']);
            Route::post('/health/steps', [$healthStepController, 'store']);
            Route::get('/health/steps/{step}', [$healthStepController, 'show']);
            Route::put('/health/steps/{step}', [$healthStepController, 'update']);
            Route::patch('/health/steps/{step}', [$healthStepController, 'update']);
            Route::delete('/health/steps/{step}', [$healthStepController, 'destroy']);

            Route::get('/health/step-logs', [$healthStepController, 'index']);
            Route::post('/health/step-logs', [$healthStepController, 'store']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Weight
        |--------------------------------------------------------------------------
        */
        if ($healthWeightController) {
            Route::get('/health/weights', [$healthWeightController, 'index']);
            Route::post('/health/weights', [$healthWeightController, 'store']);
            Route::get('/health/weights/{weight}', [$healthWeightController, 'show']);
            Route::put('/health/weights/{weight}', [$healthWeightController, 'update']);
            Route::patch('/health/weights/{weight}', [$healthWeightController, 'update']);
            Route::delete('/health/weights/{weight}', [$healthWeightController, 'destroy']);

            Route::get('/health/weight-logs', [$healthWeightController, 'index']);
            Route::post('/health/weight-logs', [$healthWeightController, 'store']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Food Items
        |--------------------------------------------------------------------------
        */
        if ($healthFoodItemController) {
            Route::get('/health/food-items', [$healthFoodItemController, 'index']);
            Route::post('/health/food-items', [$healthFoodItemController, 'store']);
            Route::get('/health/food-items/{foodItem}', [$healthFoodItemController, 'show']);
            Route::put('/health/food-items/{foodItem}', [$healthFoodItemController, 'update']);
            Route::patch('/health/food-items/{foodItem}', [$healthFoodItemController, 'update']);
            Route::delete('/health/food-items/{foodItem}', [$healthFoodItemController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Meals / Nutrition
        |--------------------------------------------------------------------------
        */
        if ($healthMealController) {
            Route::get('/health/meals', [$healthMealController, 'index']);
            Route::post('/health/meals', [$healthMealController, 'store']);
            Route::get('/health/meals/{meal}', [$healthMealController, 'show']);
            Route::put('/health/meals/{meal}', [$healthMealController, 'update']);
            Route::patch('/health/meals/{meal}', [$healthMealController, 'update']);
            Route::delete('/health/meals/{meal}', [$healthMealController, 'destroy']);

            Route::get('/health/nutrition', [$healthMealController, 'index']);
            Route::post('/health/nutrition', [$healthMealController, 'store']);
            Route::get('/health/nutrition/{meal}', [$healthMealController, 'show']);
            Route::put('/health/nutrition/{meal}', [$healthMealController, 'update']);
            Route::patch('/health/nutrition/{meal}', [$healthMealController, 'update']);
            Route::delete('/health/nutrition/{meal}', [$healthMealController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Nutrition Profile / Summary
        |--------------------------------------------------------------------------
        */
        if ($healthNutritionProfileController) {
            Route::get('/health/nutrition-profile', [$healthNutritionProfileController, 'show']);
            Route::post('/health/nutrition-profile', [$healthNutritionProfileController, 'store']);
            Route::put('/health/nutrition-profile', [$healthNutritionProfileController, 'update']);
            Route::patch('/health/nutrition-profile', [$healthNutritionProfileController, 'update']);
        }

        if ($healthNutritionSummaryController) {
            Route::get('/health/nutrition-summary', [$healthNutritionSummaryController, 'index']);
            Route::get('/health/nutrition/summary', [$healthNutritionSummaryController, 'index']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Hydration
        |--------------------------------------------------------------------------
        */
        if ($healthHydrationController) {
            Route::get('/health/hydration', [$healthHydrationController, 'index']);
            Route::post('/health/hydration', [$healthHydrationController, 'store']);
            Route::get('/health/hydration/{hydration}', [$healthHydrationController, 'show']);
            Route::put('/health/hydration/{hydration}', [$healthHydrationController, 'update']);
            Route::patch('/health/hydration/{hydration}', [$healthHydrationController, 'update']);
            Route::delete('/health/hydration/{hydration}', [$healthHydrationController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Health Analytics
        |--------------------------------------------------------------------------
        */
        if ($healthAnalyticsController) {
            Route::get('/health/analytics', [$healthAnalyticsController, 'index']);
            Route::get('/health/analytics/summary', [$healthAnalyticsController, 'summary']);
        }

        /*
        |--------------------------------------------------------------------------
        | Projects
        |--------------------------------------------------------------------------
        */
        if ($projectController) {
            Route::get('/projects', [$projectController, 'index']);
            Route::post('/projects', [$projectController, 'store']);
            Route::get('/projects/{project}', [$projectController, 'show']);
            Route::put('/projects/{project}', [$projectController, 'update']);
            Route::patch('/projects/{project}', [$projectController, 'update']);
            Route::delete('/projects/{project}', [$projectController, 'destroy']);

            Route::get('/projects-dashboard/summary', [$projectController, 'summary']);
        }

        /*
        |--------------------------------------------------------------------------
        | Project Tasks
        |--------------------------------------------------------------------------
        */
        if ($projectTaskController) {
            Route::get('/project-tasks', [$projectTaskController, 'index']);
            Route::post('/project-tasks', [$projectTaskController, 'store']);
            Route::get('/project-tasks/{task}', [$projectTaskController, 'show']);
            Route::put('/project-tasks/{task}', [$projectTaskController, 'update']);
            Route::patch('/project-tasks/{task}', [$projectTaskController, 'update']);
            Route::delete('/project-tasks/{task}', [$projectTaskController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Project Milestones
        |--------------------------------------------------------------------------
        */
        if ($projectMilestoneController) {
            Route::get('/project-milestones', [$projectMilestoneController, 'index']);
            Route::post('/project-milestones', [$projectMilestoneController, 'store']);
            Route::get('/project-milestones/{milestone}', [$projectMilestoneController, 'show']);
            Route::put('/project-milestones/{milestone}', [$projectMilestoneController, 'update']);
            Route::patch('/project-milestones/{milestone}', [$projectMilestoneController, 'update']);
            Route::delete('/project-milestones/{milestone}', [$projectMilestoneController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Project Progress
        |--------------------------------------------------------------------------
        */
        if ($projectProgressController) {
            Route::get('/project-progress', [$projectProgressController, 'index']);
            Route::post('/project-progress', [$projectProgressController, 'store']);
            Route::get('/project-progress/{progress}', [$projectProgressController, 'show']);
            Route::put('/project-progress/{progress}', [$projectProgressController, 'update']);
            Route::patch('/project-progress/{progress}', [$projectProgressController, 'update']);
            Route::delete('/project-progress/{progress}', [$projectProgressController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Project Status Updates
        |--------------------------------------------------------------------------
        */
        if ($projectStatusUpdateController) {
            Route::get('/status-updates', [$projectStatusUpdateController, 'index']);
            Route::post('/status-updates', [$projectStatusUpdateController, 'store']);
            Route::get('/status-updates/{statusUpdate}', [$projectStatusUpdateController, 'show']);
            Route::put('/status-updates/{statusUpdate}', [$projectStatusUpdateController, 'update']);
            Route::patch('/status-updates/{statusUpdate}', [$projectStatusUpdateController, 'update']);
            Route::delete('/status-updates/{statusUpdate}', [$projectStatusUpdateController, 'destroy']);
        }

        /*
        |--------------------------------------------------------------------------
        | Notification Preferences
        |--------------------------------------------------------------------------
        | Must be before /notifications/{notification}
        |--------------------------------------------------------------------------
        */
        if ($notificationPreferenceController) {
            Route::get('/notifications/preferences', [$notificationPreferenceController, 'show']);
            Route::post('/notifications/preferences', [$notificationPreferenceController, 'storeOrUpdate']);
            Route::put('/notifications/preferences', [$notificationPreferenceController, 'storeOrUpdate']);
            Route::patch('/notifications/preferences', [$notificationPreferenceController, 'storeOrUpdate']);
        }

        /*
        |--------------------------------------------------------------------------
        | Notifications
        |--------------------------------------------------------------------------
        */
        if ($notificationPreferenceController) {
            Route::get('/notifications/preferences', [$notificationPreferenceController, 'show']);
            Route::post('/notifications/preferences', [$notificationPreferenceController, 'storeOrUpdate']);
            Route::put('/notifications/preferences', [$notificationPreferenceController, 'storeOrUpdate']);
            Route::patch('/notifications/preferences', [$notificationPreferenceController, 'storeOrUpdate']);
        }
        if ($notificationController) {
            Route::get('/notifications', [$notificationController, 'index']);
            Route::post('/notifications', [$notificationController, 'store']);
            Route::post('/notifications/read-all', [$notificationController, 'markAllAsRead']);

            Route::get('/notifications/{notification}', [$notificationController, 'show']);
            Route::put('/notifications/{notification}', [$notificationController, 'update']);
            Route::patch('/notifications/{notification}', [$notificationController, 'update']);
            Route::delete('/notifications/{notification}', [$notificationController, 'destroy']);
            Route::post('/notifications/{notification}/read', [$notificationController, 'markAsRead']);
        }

        /*
        |--------------------------------------------------------------------------
        | Monitoring
        |--------------------------------------------------------------------------
        */
        if ($monitoringController) {
            Route::get('/monitoring', [$monitoringController, 'index']);
            Route::get('/monitoring/summary', [$monitoringController, 'summary']);
            Route::get('/monitoring/audit-logs', [$monitoringController, 'auditLogs']);
            Route::get('/monitoring/error-logs', [$monitoringController, 'errorLogs']);
            Route::get('/monitoring/system-health', [$monitoringController, 'systemHealth']);
        }
    });
});
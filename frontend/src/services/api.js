<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UnifiedDashboardController;
use App\Http\Controllers\Api\LifeBalanceController;

use App\Http\Controllers\Api\FinanceDashboardController;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\FinanceTransactionController;
use App\Http\Controllers\Api\FinanceBudgetController;

use App\Http\Controllers\Api\V1\Health\HealthStepLogController;
use App\Http\Controllers\Api\HealthWeightLogController;
use App\Http\Controllers\Api\HealthMealController;
use App\Http\Controllers\Api\HealthHydrationLogController;

use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\ProjectTaskController;
use App\Http\Controllers\Api\ProjectMilestoneController;
use App\Http\Controllers\Api\ProjectProgressController;
use App\Http\Controllers\Api\ProjectStatusUpdateController;

use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\NotificationPreferenceController;

use App\Http\Controllers\Api\MonitoringController;

Route::prefix('v1')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Public Auth Routes
    |--------------------------------------------------------------------------
    */
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    /*
    |--------------------------------------------------------------------------
    | Protected Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {

        /*
        |--------------------------------------------------------------------------
        | Auth
        |--------------------------------------------------------------------------
        */
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        /*
        |--------------------------------------------------------------------------
        | Unified Dashboard
        |--------------------------------------------------------------------------
        */
        Route::get('/dashboard/summary', [UnifiedDashboardController::class, 'summary']);
        Route::get('/dashboard/kpis', [UnifiedDashboardController::class, 'kpis']);
        Route::get('/dashboard/recent-activity', [UnifiedDashboardController::class, 'recentActivity']);

        /*
        |--------------------------------------------------------------------------
        | Life Balance
        |--------------------------------------------------------------------------
        */
        Route::get('/life-balance', [LifeBalanceController::class, 'index']);
        Route::get('/life-balance/summary', [LifeBalanceController::class, 'summary']);
        Route::get('/life-balance/score', [LifeBalanceController::class, 'score']);
        Route::get('/life-balance/radar', [LifeBalanceController::class, 'radar']);
        Route::post('/life-balance/recalculate', [LifeBalanceController::class, 'recalculate']);

        /*
        |--------------------------------------------------------------------------
        | Finance Dashboard
        |--------------------------------------------------------------------------
        */
        Route::get('/finance/dashboard', [FinanceDashboardController::class, 'index']);
        Route::get('/finance/dashboard/summary', [FinanceDashboardController::class, 'summary']);
        Route::get('/finance/dashboard/monthly', [FinanceDashboardController::class, 'monthly']);
        Route::get('/finance/dashboard/categories', [FinanceDashboardController::class, 'categories']);

        /*
        |--------------------------------------------------------------------------
        | Finance Accounts
        |--------------------------------------------------------------------------
        */
        Route::get('/finance/accounts', [FinanceAccountController::class, 'index']);
        Route::post('/finance/accounts', [FinanceAccountController::class, 'store']);
        Route::get('/finance/accounts/{account}', [FinanceAccountController::class, 'show']);
        Route::put('/finance/accounts/{account}', [FinanceAccountController::class, 'update']);
        Route::patch('/finance/accounts/{account}', [FinanceAccountController::class, 'update']);
        Route::delete('/finance/accounts/{account}', [FinanceAccountController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Finance Transactions
        |--------------------------------------------------------------------------
        */
        Route::get('/finance/transactions', [FinanceTransactionController::class, 'index']);
        Route::post('/finance/transactions', [FinanceTransactionController::class, 'store']);
        Route::get('/finance/transactions/{transaction}', [FinanceTransactionController::class, 'show']);
        Route::put('/finance/transactions/{transaction}', [FinanceTransactionController::class, 'update']);
        Route::patch('/finance/transactions/{transaction}', [FinanceTransactionController::class, 'update']);
        Route::delete('/finance/transactions/{transaction}', [FinanceTransactionController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Finance Budgets
        |--------------------------------------------------------------------------
        */
        Route::get('/finance/budgets', [FinanceBudgetController::class, 'index']);
        Route::post('/finance/budgets', [FinanceBudgetController::class, 'store']);
        Route::get('/finance/budgets/{budget}', [FinanceBudgetController::class, 'show']);
        Route::put('/finance/budgets/{budget}', [FinanceBudgetController::class, 'update']);
        Route::patch('/finance/budgets/{budget}', [FinanceBudgetController::class, 'update']);
        Route::delete('/finance/budgets/{budget}', [FinanceBudgetController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Health - Steps
        |--------------------------------------------------------------------------
        */
        Route::get('/health/steps', [HealthStepLogController::class, 'index']);
        Route::post('/health/steps', [HealthStepLogController::class, 'store']);
        Route::get('/health/steps/{step}', [HealthStepLogController::class, 'show']);
        Route::put('/health/steps/{step}', [HealthStepLogController::class, 'update']);
        Route::patch('/health/steps/{step}', [HealthStepLogController::class, 'update']);
        Route::delete('/health/steps/{step}', [HealthStepLogController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Health - Weight
        |--------------------------------------------------------------------------
        | Main routes + aliases for frontend compatibility.
        |--------------------------------------------------------------------------
        */
        Route::get('/health/weights', [HealthWeightLogController::class, 'index']);
        Route::post('/health/weights', [HealthWeightLogController::class, 'store']);
        Route::get('/health/weights/{weight}', [HealthWeightLogController::class, 'show']);
        Route::put('/health/weights/{weight}', [HealthWeightLogController::class, 'update']);
        Route::patch('/health/weights/{weight}', [HealthWeightLogController::class, 'update']);
        Route::delete('/health/weights/{weight}', [HealthWeightLogController::class, 'destroy']);

        Route::get('/health/weight-logs', [HealthWeightLogController::class, 'index']);
        Route::post('/health/weight-logs', [HealthWeightLogController::class, 'store']);
        Route::get('/health/weight-logs/{weight}', [HealthWeightLogController::class, 'show']);
        Route::put('/health/weight-logs/{weight}', [HealthWeightLogController::class, 'update']);
        Route::patch('/health/weight-logs/{weight}', [HealthWeightLogController::class, 'update']);
        Route::delete('/health/weight-logs/{weight}', [HealthWeightLogController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Health - Nutrition / Meals
        |--------------------------------------------------------------------------
        | Main routes + aliases for frontend compatibility.
        |--------------------------------------------------------------------------
        */
        Route::get('/health/meals', [HealthMealController::class, 'index']);
        Route::post('/health/meals', [HealthMealController::class, 'store']);
        Route::get('/health/meals/{meal}', [HealthMealController::class, 'show']);
        Route::put('/health/meals/{meal}', [HealthMealController::class, 'update']);
        Route::patch('/health/meals/{meal}', [HealthMealController::class, 'update']);
        Route::delete('/health/meals/{meal}', [HealthMealController::class, 'destroy']);

        Route::get('/health/nutrition', [HealthMealController::class, 'index']);
        Route::post('/health/nutrition', [HealthMealController::class, 'store']);
        Route::get('/health/nutrition/{meal}', [HealthMealController::class, 'show']);
        Route::put('/health/nutrition/{meal}', [HealthMealController::class, 'update']);
        Route::patch('/health/nutrition/{meal}', [HealthMealController::class, 'update']);
        Route::delete('/health/nutrition/{meal}', [HealthMealController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Health - Hydration
        |--------------------------------------------------------------------------
        */
        Route::get('/health/hydration', [HealthHydrationLogController::class, 'index']);
        Route::post('/health/hydration', [HealthHydrationLogController::class, 'store']);
        Route::get('/health/hydration/{hydration}', [HealthHydrationLogController::class, 'show']);
        Route::put('/health/hydration/{hydration}', [HealthHydrationLogController::class, 'update']);
        Route::patch('/health/hydration/{hydration}', [HealthHydrationLogController::class, 'update']);
        Route::delete('/health/hydration/{hydration}', [HealthHydrationLogController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Projects
        |--------------------------------------------------------------------------
        */
        Route::get('/projects', [ProjectController::class, 'index']);
        Route::post('/projects', [ProjectController::class, 'store']);
        Route::get('/projects/{project}', [ProjectController::class, 'show']);
        Route::put('/projects/{project}', [ProjectController::class, 'update']);
        Route::patch('/projects/{project}', [ProjectController::class, 'update']);
        Route::delete('/projects/{project}', [ProjectController::class, 'destroy']);

        Route::get('/projects-dashboard/summary', [ProjectController::class, 'summary']);

        /*
        |--------------------------------------------------------------------------
        | Project Tasks
        |--------------------------------------------------------------------------
        */
        Route::get('/project-tasks', [ProjectTaskController::class, 'index']);
        Route::post('/project-tasks', [ProjectTaskController::class, 'store']);
        Route::get('/project-tasks/{task}', [ProjectTaskController::class, 'show']);
        Route::put('/project-tasks/{task}', [ProjectTaskController::class, 'update']);
        Route::patch('/project-tasks/{task}', [ProjectTaskController::class, 'update']);
        Route::delete('/project-tasks/{task}', [ProjectTaskController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Project Milestones
        |--------------------------------------------------------------------------
        */
        Route::get('/project-milestones', [ProjectMilestoneController::class, 'index']);
        Route::post('/project-milestones', [ProjectMilestoneController::class, 'store']);
        Route::get('/project-milestones/{milestone}', [ProjectMilestoneController::class, 'show']);
        Route::put('/project-milestones/{milestone}', [ProjectMilestoneController::class, 'update']);
        Route::patch('/project-milestones/{milestone}', [ProjectMilestoneController::class, 'update']);
        Route::delete('/project-milestones/{milestone}', [ProjectMilestoneController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Project Progress
        |--------------------------------------------------------------------------
        */
        Route::get('/project-progress', [ProjectProgressController::class, 'index']);
        Route::post('/project-progress', [ProjectProgressController::class, 'store']);
        Route::get('/project-progress/{progress}', [ProjectProgressController::class, 'show']);
        Route::put('/project-progress/{progress}', [ProjectProgressController::class, 'update']);
        Route::patch('/project-progress/{progress}', [ProjectProgressController::class, 'update']);
        Route::delete('/project-progress/{progress}', [ProjectProgressController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Status Updates
        |--------------------------------------------------------------------------
        */
        Route::get('/status-updates', [ProjectStatusUpdateController::class, 'index']);
        Route::post('/status-updates', [ProjectStatusUpdateController::class, 'store']);
        Route::get('/status-updates/{statusUpdate}', [ProjectStatusUpdateController::class, 'show']);
        Route::put('/status-updates/{statusUpdate}', [ProjectStatusUpdateController::class, 'update']);
        Route::patch('/status-updates/{statusUpdate}', [ProjectStatusUpdateController::class, 'update']);
        Route::delete('/status-updates/{statusUpdate}', [ProjectStatusUpdateController::class, 'destroy']);

        /*
        |--------------------------------------------------------------------------
        | Notification Preferences
        |--------------------------------------------------------------------------
        | Must be BEFORE /notifications/{notification}
        |--------------------------------------------------------------------------
        */
        Route::get('/notifications/preferences', [NotificationPreferenceController::class, 'show']);
        Route::post('/notifications/preferences', [NotificationPreferenceController::class, 'storeOrUpdate']);
        Route::put('/notifications/preferences', [NotificationPreferenceController::class, 'storeOrUpdate']);
        Route::patch('/notifications/preferences', [NotificationPreferenceController::class, 'storeOrUpdate']);

        /*
        |--------------------------------------------------------------------------
        | Notifications
        |--------------------------------------------------------------------------
        */
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications', [NotificationController::class, 'store']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

        Route::get('/notifications/{notification}', [NotificationController::class, 'show']);
        Route::put('/notifications/{notification}', [NotificationController::class, 'update']);
        Route::patch('/notifications/{notification}', [NotificationController::class, 'update']);
        Route::delete('/notifications/{notification}', [NotificationController::class, 'destroy']);
        Route::post('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);

        /*
        |--------------------------------------------------------------------------
        | Logging & Monitoring
        |--------------------------------------------------------------------------
        */
        Route::get('/monitoring', [MonitoringController::class, 'index']);
        Route::get('/monitoring/summary', [MonitoringController::class, 'summary']);
        Route::get('/monitoring/audit-logs', [MonitoringController::class, 'auditLogs']);
        Route::get('/monitoring/error-logs', [MonitoringController::class, 'errorLogs']);
        Route::get('/monitoring/system-health', [MonitoringController::class, 'systemHealth']);
    });
});
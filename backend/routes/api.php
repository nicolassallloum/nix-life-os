<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\Dashboard\UnifiedDashboardController;
use App\Http\Controllers\Api\V1\AiInsightController;
use App\Http\Controllers\Api\V1\AiPredictionController;
use App\Http\Controllers\Api\V1\AutomationRuleController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\V1\LifeBalanceController;
use App\Http\Controllers\Api\FinanceCategoryController;
use App\Http\Controllers\Api\FinanceTransactionController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\NotificationPreferenceController;
use App\Http\Controllers\Api\V1\HealthHydrationLogController;
use App\Http\Controllers\Api\V1\Finance\FinanceAnomalyController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetSummaryController;
use App\Http\Controllers\Api\V1\Finance\FinanceForecastController;
use App\Http\Controllers\Api\V1\Finance\FinanceIntelligenceSettingController;
use App\Http\Controllers\Api\V1\Health\HealthAnalyticsController;
use App\Http\Controllers\Api\V1\HealthWeightLogController;
use App\Http\Controllers\Api\V1\Health\HealthProfileController;
use App\Http\Controllers\Api\V1\Health\HealthStepLogController;
use App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController;
use App\Http\Controllers\Api\V1\Health\HealthFoodItemController;
use App\Http\Controllers\Api\V1\Health\HealthMealLogController;
use App\Http\Controllers\Api\V1\Health\HealthNutritionSummaryController;
use App\Http\Controllers\Api\V1\ProjectController;
use App\Http\Controllers\Api\V1\ProjectTaskController;
use App\Http\Controllers\Api\V1\ProjectProgressController;
use App\Http\Controllers\Api\V1\ProjectMilestoneController;
use App\Http\Controllers\Api\V1\ProjectStatusUpdateController;


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
        Route::prefix('dashboard')->group(function () {
            Route::get('/overview', [UnifiedDashboardController::class, 'overview']);
            Route::get('/summary', [UnifiedDashboardController::class, 'summary']);
            Route::get('/kpis', [UnifiedDashboardController::class, 'kpis']);
            Route::get('/recent-activity', [UnifiedDashboardController::class, 'recentActivity']);

            Route::get('/finance', [UnifiedDashboardController::class, 'finance']);
            Route::get('/health', [UnifiedDashboardController::class, 'health']);
            Route::get('/projects', [UnifiedDashboardController::class, 'projects']);
            Route::get('/trends', [UnifiedDashboardController::class, 'trends']);
        });
        Route::prefix('automation')->group(function () {
            Route::get('/rules', [AutomationRuleController::class, 'index']);
            Route::post('/rules', [AutomationRuleController::class, 'store']);
            Route::get('/rules/{id}', [AutomationRuleController::class, 'show']);
            Route::put('/rules/{id}', [AutomationRuleController::class, 'update']);
            Route::delete('/rules/{id}', [AutomationRuleController::class, 'destroy']);

            Route::post('/run', [AutomationRuleController::class, 'run']);
            Route::get('/logs', [AutomationRuleController::class, 'logs']);
            Route::patch('/rules/{id}/toggle', [AutomationRuleController::class, 'toggle']);
        });
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
        Route::get('/notifications/{id}', [NotificationController::class, 'show']);
        Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::patch('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);

        Route::get('/notification-preferences', [NotificationPreferenceController::class, 'show']);
        Route::put('/notification-preferences', [NotificationPreferenceController::class, 'update']);
        Route::prefix('ai')->group(function () {
            Route::get('/insights/daily', [AiInsightController::class, 'daily']);
            Route::get('/alerts', [AiInsightController::class, 'alerts']);
            Route::get('/reports', [AiInsightController::class, 'reports']);
            Route::get('/reports/weekly', [AiInsightController::class, 'weeklyReport']);

            Route::patch('/insights/{id}/read', [AiInsightController::class, 'markInsightRead']);
            Route::patch('/alerts/{id}/resolve', [AiInsightController::class, 'resolveAlert']);

            Route::post('/engine/daily/run', [AiInsightController::class, 'runDailyEngine']);
            Route::post('/engine/weekly/run', [AiInsightController::class, 'runWeeklyEngine']);
            Route::get('/predictions/', [AiPredictionController::class, 'index']);
            Route::get('/predictions/latest', [AiPredictionController::class, 'latest']);
            Route::post('/predictions/run', [AiPredictionController::class, 'run']);
        });
        Route::prefix('life-balance')->group(function () {
            Route::get('/today', [LifeBalanceController::class, 'today']);
            Route::post('/calculate', [LifeBalanceController::class, 'calculate']);
            Route::get('/history', [LifeBalanceController::class, 'history']);
        });
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
        /*
        |--------------------------------------------------------------------------
        | Auth
        |--------------------------------------------------------------------------
        */
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);
            /*
    |--------------------------------------------------------------------------
    | STEP 14 — Project Progress Engine
    |--------------------------------------------------------------------------
    */

        Route::get('/projects/{project}/progress', [ProjectProgressController::class, 'show']);

        Route::post('/projects/{project}/recalculate-progress', [ProjectProgressController::class, 'recalculate']);

        Route::patch('/projects/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);

        Route::get('/projects/{project}/milestones', [ProjectMilestoneController::class, 'index']);

        Route::post('/projects/{project}/milestones', [ProjectMilestoneController::class, 'store']);

        Route::patch('/projects/milestones/{milestone}', [ProjectMilestoneController::class, 'update']);

        Route::delete('/projects/milestones/{milestone}', [ProjectMilestoneController::class, 'destroy']);

        Route::get('/projects/{project}/status-updates', [ProjectStatusUpdateController::class, 'index']);

        Route::post('/projects/{project}/status-updates', [ProjectStatusUpdateController::class, 'store']);
        /*
        |--------------------------------------------------------------------------
        | STEP 5 — Finance Core
        |--------------------------------------------------------------------------
        */
        Route::apiResource('finance/accounts', FinanceAccountController::class);
        Route::apiResource('finance/categories', FinanceCategoryController::class);
        Route::apiResource('finance/transactions', FinanceTransactionController::class);
        /*
        |--------------------------------------------------------------------------
        | STEP 13 — Project Management Module
        |--------------------------------------------------------------------------
        */        
        Route::apiResource('projects', ProjectController::class);
        Route::apiResource('project-tasks', ProjectTaskController::class);
        /*
        |--------------------------------------------------------------------------
        | STEP 6 — Financial Intelligence Engine
        |--------------------------------------------------------------------------
        */
        Route::get('finance/budgets', [FinanceBudgetController::class, 'index']);
        Route::post('finance/budgets', [FinanceBudgetController::class, 'store']);
        Route::get('finance/budgets/{budget}', [FinanceBudgetController::class, 'show']);
        Route::put('finance/budgets/{budget}', [FinanceBudgetController::class, 'update']);
        Route::delete('finance/budgets/{budget}', [FinanceBudgetController::class, 'destroy']);

        Route::get('finance/budgets/{budget}/summary', [FinanceBudgetSummaryController::class, 'show']);
        Route::get('finance/budgets-summary/monthly', [FinanceBudgetSummaryController::class, 'monthlySummary']);

        Route::get('finance/forecast/summary', [FinanceForecastController::class, 'summary']);
        Route::post('finance/forecast/snapshots', [FinanceForecastController::class, 'storeSnapshot']);

        Route::get('finance/intelligence-settings', [FinanceIntelligenceSettingController::class, 'show']);
        Route::put('finance/intelligence-settings', [FinanceIntelligenceSettingController::class, 'upsert']);

        Route::get('finance/anomalies', [FinanceAnomalyController::class, 'index']);
        Route::get('finance/anomalies/{anomalyLog}', [FinanceAnomalyController::class, 'show']);
        Route::post('finance/anomalies/run/{transactionId}', [FinanceAnomalyController::class, 'runForTransaction']);

        /*
        |--------------------------------------------------------------------------
        | STEP 8 — Health Steps Tracking Module
        |--------------------------------------------------------------------------
        */
        Route::prefix('health')->group(function () {
            Route::get('/profile', [HealthProfileController::class, 'show']);
            Route::put('/profile', [HealthProfileController::class, 'update']);
            
            Route::get('/steps', [HealthStepLogController::class, 'index']);
            Route::post('/steps', [HealthStepLogController::class, 'store']);
            Route::get('/steps/summary', [HealthStepLogController::class, 'summary']);
            Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);
            Route::delete('/steps/{id}', [HealthStepLogController::class, 'destroy']);
        });

        /*
        |--------------------------------------------------------------------------
        | STEP 9 — Health Weight Tracking Module
        |--------------------------------------------------------------------------
        */
        Route::get('/health/weight/summary', [HealthWeightLogController::class, 'summary']);
        Route::apiResource('/health/weight', HealthWeightLogController::class);
        Route::post('/health/analytics/daily', [HealthAnalyticsController::class, 'daily']);
        /*
        |--------------------------------------------------------------------------
        | STEP 10 — Health Nutrition Tracking Module
        |--------------------------------------------------------------------------
        */
        Route::prefix('health/nutrition')->group(function () {
            Route::get('/profile', [HealthNutritionProfileController::class, 'index']);
            Route::post('/profile', [HealthNutritionProfileController::class, 'store']);

            Route::get('/foods', [HealthFoodItemController::class, 'index']);
            Route::post('/foods', [HealthFoodItemController::class, 'store']);
            Route::get('/foods/{healthFoodItem}', [HealthFoodItemController::class, 'show']);

            Route::get('/meals', [HealthMealLogController::class, 'index']);
            Route::post('/meals', [HealthMealLogController::class, 'store']);
            Route::delete('/meals/{healthMealLog}', [HealthMealLogController::class, 'destroy']);

            Route::get('/summary/daily', [HealthNutritionSummaryController::class, 'daily']);
        });

    });

});
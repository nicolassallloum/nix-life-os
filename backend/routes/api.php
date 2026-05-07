<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\V1\Dashboard\DashboardController;
use App\Http\Controllers\Api\V1\Dashboard\UnifiedDashboardController;
use App\Http\Controllers\Api\LifeBalanceController;
use App\Http\Controllers\Api\FinanceDashboardController;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\FinanceTransactionController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;

use App\Http\Controllers\Api\V1\Health\HealthStepLogController;
use App\Http\Controllers\Api\V1\HealthWeightLogController;
use App\Http\Controllers\Api\HealthNutritionLogController;
use App\Http\Controllers\Api\HealthHydrationLogController;

use App\Http\Controllers\Api\ProjectDashboardController;
use App\Http\Controllers\Api\ProjectTaskController;
use App\Http\Controllers\Api\ProjectMilestoneController;
use App\Http\Controllers\Api\ProjectProgressController;
use App\Http\Controllers\Api\ProjectStatusUpdateController;

use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\NotificationSettingController;

use App\Http\Controllers\Api\MonitoringController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Nix Life OS API routes.
| Main API prefix: /api/v1
|
*/

/*
|--------------------------------------------------------------------------
| Public Health Check
|--------------------------------------------------------------------------
*/

Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'Nix Life OS API is running.',
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
    | Public Auth Routes
    |--------------------------------------------------------------------------
    */

    Route::prefix('auth')->group(function () {
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/register', [AuthController::class, 'register']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::get('/me', [AuthController::class, 'me']);
            Route::post('/logout', [AuthController::class, 'logout']);
        });
    });

    /*
    |--------------------------------------------------------------------------
    | Protected Routes
    |--------------------------------------------------------------------------
    */

    Route::middleware('auth:sanctum')->group(function () {
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
        | Unified Dashboard
        |--------------------------------------------------------------------------
        */

        Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

        /*
        |--------------------------------------------------------------------------
        | Life Balance
        |--------------------------------------------------------------------------
        */

        Route::get('/life-balance/summary', [LifeBalanceController::class, 'summary']);

        /*
        |--------------------------------------------------------------------------
        | Finance Module
        |--------------------------------------------------------------------------
        |
        | Main frontend pages:
        | /finance/dashboard
        | /finance/accounts
        | /finance/transactions
        | /finance/budgets
        |
        | Main APIs:
        | GET    /api/v1/finance/summary
        | GET    /api/v1/finance/accounts
        | POST   /api/v1/finance/accounts
        | GET    /api/v1/finance/transactions
        | POST   /api/v1/finance/transactions
        | GET    /api/v1/finance/budgets
        | POST   /api/v1/finance/budgets
        |
        */

        Route::prefix('finance')->group(function () {
            Route::get('/summary', [FinanceDashboardController::class, 'summary']);

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
        });

        /*
        |--------------------------------------------------------------------------
        | Health Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('health')->group(function () {
            Route::get('/steps', [HealthStepLogController::class, 'index']);
            Route::post('/steps', [HealthStepLogController::class, 'store']);
            Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);
            Route::put('/steps/{id}', [HealthStepLogController::class, 'update']);
            Route::patch('/steps/{id}', [HealthStepLogController::class, 'update']);
            Route::delete('/steps/{id}', [HealthStepLogController::class, 'destroy']);

            Route::get('/weight', [HealthWeightLogController::class, 'index']);
            Route::post('/weight', [HealthWeightLogController::class, 'store']);
            Route::get('/weight/{id}', [HealthWeightLogController::class, 'show']);
            Route::put('/weight/{id}', [HealthWeightLogController::class, 'update']);
            Route::patch('/weight/{id}', [HealthWeightLogController::class, 'update']);
            Route::delete('/weight/{id}', [HealthWeightLogController::class, 'destroy']);
            Route::get('/nutrition/summary', [HealthNutritionLogController::class, 'summary']);
            Route::get('/nutrition', [HealthNutritionLogController::class, 'index']);
            Route::post('/nutrition', [HealthNutritionLogController::class, 'store']);
            Route::get('/nutrition/{id}', [HealthNutritionLogController::class, 'show']);
            Route::put('/nutrition/{id}', [HealthNutritionLogController::class, 'update']);
            Route::patch('/nutrition/{id}', [HealthNutritionLogController::class, 'update']);
            Route::delete('/nutrition/{id}', [HealthNutritionLogController::class, 'destroy']);

            Route::get('/hydration', [HealthHydrationLogController::class, 'index']);
            Route::post('/hydration', [HealthHydrationLogController::class, 'store']);
            Route::get('/hydration/{id}', [HealthHydrationLogController::class, 'show']);
            Route::put('/hydration/{id}', [HealthHydrationLogController::class, 'update']);
            Route::patch('/hydration/{id}', [HealthHydrationLogController::class, 'update']);
            Route::delete('/hydration/{id}', [HealthHydrationLogController::class, 'destroy']);
        });

        /*
        |--------------------------------------------------------------------------
        | Projects Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('projects')->group(function () {
            Route::get('/dashboard', [ProjectDashboardController::class, 'summary']);

            Route::get('/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/tasks', [ProjectTaskController::class, 'store']);
            Route::get('/tasks/{id}', [ProjectTaskController::class, 'show']);
            Route::put('/tasks/{id}', [ProjectTaskController::class, 'update']);
            Route::patch('/tasks/{id}', [ProjectTaskController::class, 'update']);
            Route::delete('/tasks/{id}', [ProjectTaskController::class, 'destroy']);

            Route::get('/milestones', [ProjectMilestoneController::class, 'index']);
            Route::post('/milestones', [ProjectMilestoneController::class, 'store']);
            Route::get('/milestones/{id}', [ProjectMilestoneController::class, 'show']);
            Route::put('/milestones/{id}', [ProjectMilestoneController::class, 'update']);
            Route::patch('/milestones/{id}', [ProjectMilestoneController::class, 'update']);
            Route::delete('/milestones/{id}', [ProjectMilestoneController::class, 'destroy']);

            Route::get('/progress', [ProjectProgressController::class, 'index']);
            Route::post('/progress', [ProjectProgressController::class, 'store']);
            Route::get('/progress/{id}', [ProjectProgressController::class, 'show']);
            Route::put('/progress/{id}', [ProjectProgressController::class, 'update']);
            Route::patch('/progress/{id}', [ProjectProgressController::class, 'update']);
            Route::delete('/progress/{id}', [ProjectProgressController::class, 'destroy']);

            Route::get('/status-updates', [ProjectStatusUpdateController::class, 'index']);
            Route::post('/status-updates', [ProjectStatusUpdateController::class, 'store']);
            Route::get('/status-updates/{id}', [ProjectStatusUpdateController::class, 'show']);
            Route::put('/status-updates/{id}', [ProjectStatusUpdateController::class, 'update']);
            Route::patch('/status-updates/{id}', [ProjectStatusUpdateController::class, 'update']);
            Route::delete('/status-updates/{id}', [ProjectStatusUpdateController::class, 'destroy']);
        });

        /*
        |--------------------------------------------------------------------------
        | Notifications Module
        |--------------------------------------------------------------------------
        */

        Route::prefix('notifications')->group(function () {
            Route::get('/', [NotificationController::class, 'index']);
            Route::post('/', [NotificationController::class, 'store']);
            Route::get('/{id}', [NotificationController::class, 'show']);
            Route::patch('/{id}/read', [NotificationController::class, 'markAsRead']);
            Route::patch('/read-all', [NotificationController::class, 'markAllAsRead']);
            Route::delete('/{id}', [NotificationController::class, 'destroy']);
        });

        Route::prefix('notification-settings')->group(function () {
            Route::get('/', [NotificationSettingController::class, 'index']);
            Route::put('/', [NotificationSettingController::class, 'update']);
            Route::patch('/', [NotificationSettingController::class, 'update']);
        });

        /*
        |--------------------------------------------------------------------------
        | Logging & Monitoring
        |--------------------------------------------------------------------------
        */

        Route::prefix('monitoring')->group(function () {
            Route::get('/summary', [MonitoringController::class, 'summary']);
            Route::get('/logs', [MonitoringController::class, 'logs']);
            Route::get('/errors', [MonitoringController::class, 'errors']);
            Route::get('/audit-logs', [MonitoringController::class, 'auditLogs']);
        });
    });
});
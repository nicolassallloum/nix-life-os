<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\FinanceCategoryController;
use App\Http\Controllers\Api\FinanceTransactionController;

use App\Http\Controllers\Api\V1\Finance\FinanceAnomalyController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetSummaryController;
use App\Http\Controllers\Api\V1\Finance\FinanceForecastController;
use App\Http\Controllers\Api\V1\Finance\FinanceIntelligenceSettingController;

use App\Http\Controllers\Api\V1\HealthWeightLogController;
use App\Http\Controllers\Api\V1\Health\HealthProfileController;
use App\Http\Controllers\Api\V1\Health\HealthStepLogController;
use App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController;
use App\Http\Controllers\Api\V1\Health\HealthFoodItemController;
use App\Http\Controllers\Api\V1\Health\HealthMealLogController;
use App\Http\Controllers\Api\V1\Health\HealthNutritionSummaryController;

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
        Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);

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
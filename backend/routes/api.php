<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\FinanceCategoryController;
use App\Http\Controllers\Api\FinanceTransactionController;
use App\Http\Controllers\Api\V1\Finance\FinanceAnomalyController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetSummaryController;
use App\Http\Controllers\Api\V1\Finance\FinanceForecastController;
use App\Http\Controllers\Api\V1\Finance\FinanceIntelligenceSettingController;
use Illuminate\Support\Facades\Route;

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
    });
});
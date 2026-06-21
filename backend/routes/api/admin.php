<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\AdminUserController;
use App\Http\Controllers\Api\Admin\AdminPointIdeaController;

/*
|--------------------------------------------------------------------------
| Admin Management Routes
|--------------------------------------------------------------------------
|
| Loaded inside /api/v1 from routes/api.php.
| Final prefix: /api/v1/admin
|
| Protected by:
| - auth:sanctum
| - admin middleware
|
*/

Route::middleware(['auth:sanctum', 'admin'])
    ->prefix('admin')
    ->group(function () {
        Route::get('/dashboard', [AdminDashboardController::class, 'summary']);
        Route::get('/dashboard/summary', [AdminDashboardController::class, 'summary']);

        Route::get('/users', [AdminUserController::class, 'index']);
        Route::post('/users', [AdminUserController::class, 'store']);
        Route::get('/users/{id}/dashboard', [AdminUserController::class, 'dashboard']);
        Route::get('/users/{id}', [AdminUserController::class, 'show']);
        Route::put('/users/{id}', [AdminUserController::class, 'update']);
        Route::patch('/users/{id}', [AdminUserController::class, 'update']);

        Route::put('/users/{id}/hold', [AdminUserController::class, 'hold']);
        Route::put('/users/{id}/activate', [AdminUserController::class, 'activate']);

        /*
         | Compatibility aliases for older frontend/API calls.
         */
        Route::post('/users/{id}/activate', [AdminUserController::class, 'activate']);
        Route::post('/users/{id}/deactivate', [AdminUserController::class, 'hold']);
        Route::post('/users/{id}/change-password', [AdminUserController::class, 'changePassword']);
        Route::delete('/users/{id}', [AdminUserController::class, 'destroy']);

        Route::get('/point-levels', [AdminPointIdeaController::class, 'levels']);
        Route::get('/point-ideas', [AdminPointIdeaController::class, 'index']);
        Route::post('/point-ideas', [AdminPointIdeaController::class, 'store']);
        Route::put('/point-ideas/{id}', [AdminPointIdeaController::class, 'update']);
        Route::patch('/point-ideas/{id}', [AdminPointIdeaController::class, 'update']);
        Route::delete('/point-ideas/{id}', [AdminPointIdeaController::class, 'destroy']);
    });

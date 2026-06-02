<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\AdminUserController;

Route::middleware(['auth:sanctum'])
    ->prefix('admin')
    ->group(function () {
        Route::get('/dashboard/summary', [AdminDashboardController::class, 'summary']);

        Route::middleware('role:admin')->group(function () {
            Route::get('/users', [AdminUserController::class, 'index']);
            Route::post('/users', [AdminUserController::class, 'store']);
            Route::get('/users/{id}', [AdminUserController::class, 'show']);
            Route::put('/users/{id}', [AdminUserController::class, 'update']);
            Route::patch('/users/{id}', [AdminUserController::class, 'update']);
            Route::delete('/users/{id}', [AdminUserController::class, 'destroy']);

            Route::post('/users/{id}/activate', [AdminUserController::class, 'activate']);
            Route::post('/users/{id}/deactivate', [AdminUserController::class, 'deactivate']);
            Route::post('/users/{id}/change-password', [AdminUserController::class, 'changePassword']);
        });
    });

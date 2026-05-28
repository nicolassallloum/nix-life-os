<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\AdminUserController;

Route::middleware(['auth:sanctum', 'role:admin'])
    ->prefix('admin')
    ->group(function () {
        Route::get('/dashboard/summary', [AdminDashboardController::class, 'summary']);

        Route::get('/users', [AdminUserController::class, 'index']);
        Route::post('/users', [AdminUserController::class, 'store']);
        Route::get('/users/{id}', [AdminUserController::class, 'show']);
        Route::put('/users/{id}', [AdminUserController::class, 'update']);
        Route::patch('/users/{id}', [AdminUserController::class, 'update']);

        Route::post('/users/{id}/change-password', [AdminUserController::class, 'changePassword']);
        Route::post('/users/{id}/activate', [AdminUserController::class, 'activate']);
        Route::post('/users/{id}/deactivate', [AdminUserController::class, 'deactivate']);
    });
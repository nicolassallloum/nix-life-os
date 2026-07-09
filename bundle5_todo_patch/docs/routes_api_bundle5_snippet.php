<?php

use App\Http\Controllers\Api\TodoDashboardSummaryController;
use App\Http\Controllers\Api\TodoProjectDetailsController;
use App\Http\Controllers\Api\TodoTaskOrganizationController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Bundle 5 To-Do Organization Routes
|--------------------------------------------------------------------------
| Add these routes to routes/api.php.
| If your project already has /api/todo/dashboard or /api/todo/projects/{project},
| merge the returned points fields into the existing controllers instead of
| registering duplicate routes.
*/
Route::prefix('todo')->middleware('auth:sanctum')->group(function () {
    Route::get('/dashboard', [TodoDashboardSummaryController::class, 'index']);
    Route::get('/tasks/grouped', [TodoTaskOrganizationController::class, 'grouped']);
    Route::patch('/tasks/{task}/move', [TodoTaskOrganizationController::class, 'move']);
    Route::patch('/tasks/reorder', [TodoTaskOrganizationController::class, 'reorder']);
    Route::patch('/tasks/{task}/status', [TodoTaskOrganizationController::class, 'updateStatus']);
    Route::patch('/tasks/{task}', [TodoTaskOrganizationController::class, 'update']);
    Route::get('/projects/{project}', [TodoProjectDetailsController::class, 'show']);
});

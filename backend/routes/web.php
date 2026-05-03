<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'service' => 'NIX LIFE OS Backend',
        'status' => 'running',
        'message' => 'Backend API is healthy. Use /api/v1 routes.',
    ]);
});
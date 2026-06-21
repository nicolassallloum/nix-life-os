<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminPointSummaryController extends Controller
{
    public function show(): JsonResponse
    {
        $totalPoints = (int) DB::table('admin_point_ideas')
            ->where('status', 'active')
            ->sum('points');

        $levels = DB::table('admin_point_levels')
            ->orderBy('level')
            ->get();

        $currentLevel = $levels
            ->filter(fn ($level) => (int) $level->required_points <= $totalPoints)
            ->last();

        $nextLevel = $levels
            ->filter(fn ($level) => (int) $level->required_points > $totalPoints)
            ->first();

        $summary = [
            'total_points' => $totalPoints,
            'level' => $currentLevel ? (int) $currentLevel->level : 1,
            'level_label' => $currentLevel->label ?? 'Level 1',
            'current_level_required_points' => $currentLevel ? (int) $currentLevel->required_points : 0,
            'next_level' => $nextLevel ? (int) $nextLevel->level : null,
            'next_level_label' => $nextLevel->label ?? null,
            'next_level_required_points' => $nextLevel ? (int) $nextLevel->required_points : null,
            'points_to_next_level' => $nextLevel
                ? max(0, (int) $nextLevel->required_points - $totalPoints)
                : 0,
        ];

        return response()->json([
            'success' => true,
            'message' => 'Point summary loaded successfully.',
            'data' => $summary,
        ]);
    }
}

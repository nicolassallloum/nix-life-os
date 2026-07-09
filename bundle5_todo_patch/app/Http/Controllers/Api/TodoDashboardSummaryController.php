<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TodoPointsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TodoDashboardSummaryController extends Controller
{
    public function __construct(protected TodoPointsService $pointsService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $userId = (int) $request->user()->id;

        $statusCounts = DB::table('todo_tasks')
            ->select('status', DB::raw('COUNT(*) AS total'))
            ->where('user_id', $userId)
            ->groupBy('status')
            ->pluck('total', 'status');

        $totalTasks = (int) $statusCounts->sum();
        $finishedTasks = (int) ($statusCounts[TodoPointsService::FINISHED_STATUS] ?? 0);

        $typeCounts = DB::table('todo_tasks')
            ->select('task_type', DB::raw('COUNT(*) AS total'))
            ->where('user_id', $userId)
            ->whereIn('task_type', TodoPointsService::TASK_TYPES)
            ->groupBy('task_type')
            ->pluck('total', 'task_type');

        return response()->json([
            'task_counts' => [
                'total' => $totalTasks,
                'pending' => (int) ($statusCounts['pending'] ?? 0),
                'in_progress' => (int) ($statusCounts['in_progress'] ?? 0),
                'finished' => $finishedTasks,
                'by_type' => [
                    'general' => (int) ($typeCounts['general'] ?? 0),
                    'monthly' => (int) ($typeCounts['monthly'] ?? 0),
                    'weekly' => (int) ($typeCounts['weekly'] ?? 0),
                    'daily' => (int) ($typeCounts['daily'] ?? 0),
                ],
            ],
            'completion_percentage' => $totalTasks > 0 ? round(($finishedTasks / $totalTasks) * 100, 2) : 0,
            'points_summary' => $this->pointsService->summary($userId),
        ]);
    }
}

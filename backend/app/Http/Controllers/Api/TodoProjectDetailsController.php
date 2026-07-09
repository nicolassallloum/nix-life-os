<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TodoPointsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TodoProjectDetailsController extends Controller
{
    public function __construct(protected TodoPointsService $pointsService)
    {
    }

    public function show(Request $request, int $project): JsonResponse
    {
        $userId = (int) $request->user()->id;

        $projectQuery = DB::table('todo_projects')->where('id', $project);

        if (Schema::hasColumn('todo_projects', 'user_id')) {
            $projectQuery->where('user_id', $userId);
        }

        $projectRow = $projectQuery->first();
        abort_if(! $projectRow, 404);

        $tasks = DB::table('todo_tasks')
            ->where('user_id', $userId)
            ->where('project_id', $project)
            ->orderBy('sort_order')
            ->orderByRaw('due_date ASC NULLS LAST')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'project' => $projectRow,
            'tasks' => $tasks,
            'points' => $this->pointsService->projectSummary($userId, $project),
        ]);
    }
}

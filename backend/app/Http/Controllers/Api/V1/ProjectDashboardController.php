<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProjectTask;
use Illuminate\Http\Request;

class ProjectDashboardController extends Controller
{
    public function summary(Request $request)
    {
        $userId = $request->user()->id;
        $today = now()->toDateString();

        return response()->json([
            'success' => true,
            'data' => [
                'total_tasks' => ProjectTask::where('user_id', $userId)->count(),

                'open_tasks' => ProjectTask::where('user_id', $userId)
                    ->where('status', '!=', 'done')
                    ->count(),

                'completed_tasks' => ProjectTask::where('user_id', $userId)
                    ->where('status', 'done')
                    ->count(),

                'overdue_tasks' => ProjectTask::where('user_id', $userId)
                    ->whereNotNull('due_date')
                    ->where('due_date', '<', $today)
                    ->where('status', '!=', 'done')
                    ->count(),
            ],
        ]);
    }
}
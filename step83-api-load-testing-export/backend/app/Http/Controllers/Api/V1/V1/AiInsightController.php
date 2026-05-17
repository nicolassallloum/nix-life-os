<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiAlert;
use App\Models\AiInsight;
use App\Models\AiReport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Process;

class AiInsightController extends Controller
{
    public function daily(Request $request)
    {
        $user = $request->user();

        $date = $request->query('date', now()->toDateString());

        $insights = AiInsight::query()
            ->where('user_id', $user->id)
            ->whereDate('insight_date', $date)
            ->where('is_archived', false)
            ->orderByRaw("
                CASE severity
                    WHEN 'critical' THEN 1
                    WHEN 'warning' THEN 2
                    WHEN 'success' THEN 3
                    ELSE 4
                END
            ")
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daily AI insights retrieved successfully.',
            'data' => $insights,
        ]);
    }

    public function alerts(Request $request)
    {
        $user = $request->user();

        $alerts = AiAlert::query()
            ->where('user_id', $user->id)
            ->when(!$request->boolean('include_resolved'), function ($query) {
                $query->where('is_resolved', false);
            })
            ->orderByRaw("
                CASE severity
                    WHEN 'critical' THEN 1
                    WHEN 'warning' THEN 2
                    ELSE 3
                END
            ")
            ->latest()
            ->limit(50)
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'AI alerts retrieved successfully.',
            'data' => $alerts,
        ]);
    }

    public function weeklyReport(Request $request)
    {
        $user = $request->user();

        $report = AiReport::query()
            ->where('user_id', $user->id)
            ->where('report_type', 'weekly')
            ->latest('period_end')
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Weekly AI report retrieved successfully.',
            'data' => $report,
        ]);
    }

    public function reports(Request $request)
    {
        $user = $request->user();

        $reports = AiReport::query()
            ->where('user_id', $user->id)
            ->when($request->query('type'), function ($query, $type) {
                $query->where('report_type', $type);
            })
            ->latest('period_end')
            ->paginate(10);

        return response()->json([
            'success' => true,
            'message' => 'AI reports retrieved successfully.',
            'data' => $reports,
        ]);
    }

    public function markInsightRead(Request $request, string $id)
    {
        $user = $request->user();

        $insight = AiInsight::where('user_id', $user->id)->findOrFail($id);

        $insight->update([
            'is_read' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Insight marked as read.',
            'data' => $insight,
        ]);
    }

    public function resolveAlert(Request $request, string $id)
    {
        $user = $request->user();

        $alert = AiAlert::where('user_id', $user->id)->findOrFail($id);

        $alert->update([
            'is_resolved' => true,
            'resolved_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert resolved successfully.',
            'data' => $alert,
        ]);
    }

    public function runDailyEngine(Request $request)
    {
        $user = $request->user();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_daily_insights.py');

        $result = Process::timeout(120)->run([
            $pythonPath,
            $scriptPath,
            '--user-id=' . $user->id,
            '--date=' . now()->toDateString(),
        ]);

        if (!$result->successful()) {
            return response()->json([
                'success' => false,
                'message' => 'AI engine failed.',
                'error' => $result->errorOutput(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Daily AI engine executed successfully.',
            'output' => $result->output(),
        ]);
    }

    public function runWeeklyEngine(Request $request)
    {
        $user = $request->user();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_weekly_report.py');

        $result = Process::timeout(180)->run([
            $pythonPath,
            $scriptPath,
            '--user-id=' . $user->id,
        ]);

        if (!$result->successful()) {
            return response()->json([
                'success' => false,
                'message' => 'Weekly AI engine failed.',
                'error' => $result->errorOutput(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Weekly AI report generated successfully.',
            'output' => $result->output(),
        ]);
    }
}
<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use App\Services\Performance\ApiCacheService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();

        $cacheKey = ApiCacheService::userKey('dashboard_summary', $user->id, [
            'date' => now()->toDateString(),
        ]);

        $data = ApiCacheService::remember($cacheKey, function () use ($user) {
            return [
                'finance' => $this->financeSummary($user->id),
                'health' => $this->healthSummary($user->id),
                'projects' => $this->projectSummary($user->id),
                'generated_at' => now()->toDateTimeString(),
            ];
        }, 300);

        return response()->json([
            'status' => true,
            'message' => 'Dashboard summary loaded successfully.',
            'data' => $data,
        ]);
    }

    private function financeSummary(string $userId): array
    {
        return [
            'accounts_count' => DB::table('nix_life_os.finance_account')
                ->where('user_id', $userId)
                ->count(),

            'total_balance' => DB::table('nix_life_os.finance_account')
                ->where('user_id', $userId)
                ->sum('current_balance'),

            'monthly_income' => DB::table('nix_life_os.finance_transaction')
                ->where('user_id', $userId)
                ->where('transaction_type', 'income')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount'),

            'monthly_expense' => DB::table('nix_life_os.finance_transaction')
                ->where('user_id', $userId)
                ->where('transaction_type', 'expense')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount'),
        ];
    }

    private function healthSummary(string $userId): array
    {
        return [
            'latest_weight' => DB::table('health_weight_logs')
                ->where('user_id', $userId)
                ->orderByDesc('log_date')
                ->value('weight_kg'),

            'today_steps' => DB::table('health_step_log')
                ->where('user_id', $userId)
                ->whereDate('log_date', now()->toDateString())
                ->sum('steps_count'),

            'today_water_ml' => DB::table('health_hydration_logs')
                ->where('user_id', $userId)
                ->whereDate('log_date', now()->toDateString())
                ->sum('amount_ml'),
        ];
    }

    private function projectSummary(string $userId): array
    {
        return [
            'active_projects' => DB::table('projects')
                ->where('user_id', $userId)
                ->where('status', 'in_progress')
                ->count(),

            'completed_tasks' => DB::table('project_tasks')
                ->where('user_id', $userId)
                ->where('status', 'completed')
                ->count(),

            'pending_tasks' => DB::table('project_tasks')
                ->where('user_id', $userId)
                ->whereIn('status', ['pending', 'todo', 'in_progress'])
                ->count(),
        ];
    }
}
